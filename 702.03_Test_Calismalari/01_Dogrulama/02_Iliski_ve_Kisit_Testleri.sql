USE EndustriyelBakimDB;
GO

SET ANSI_NULLS ON;
SET QUOTED_IDENTIFIER ON;
SET ANSI_PADDING ON;
SET ANSI_WARNINGS ON;
SET ARITHABORT ON;
SET CONCAT_NULL_YIELDS_NULL ON;
SET NUMERIC_ROUNDABORT OFF;
GO

SET NOCOUNT ON;
SET XACT_ABORT ON;

/* Testler beklenen hata kodunu doğrular; rastgele bir hata başarı sayılmaz.
   Her test kendi işlemini geri alır. Açık bir kullanıcı işlemi varsa çalışmaz.
   Yetki kontrollerinden değil tetikleyiciden gelen hataları test etmek için
   SQL Server sistem yöneticisi / veritabanı sahibi bağlantısı kullanılmalıdır. */
IF @@TRANCOUNT <> 0
    THROW 52020, N'Önce mevcut işlemi tamamlayın; test açık işlem içinde çalıştırılamaz.', 1;

DECLARE @TurNo INT, @EkipmanKodu NVARCHAR(30), @EkipmanUnique SYSNAME;
SELECT TOP (1) @TurNo = TurNo, @EkipmanKodu = EkipmanKodu
FROM dbo.Ekipmanlar ORDER BY EkipmanNo;
SELECT @EkipmanUnique = i.name
FROM sys.indexes i
INNER JOIN sys.index_columns ic ON ic.object_id = i.object_id AND ic.index_id = i.index_id
INNER JOIN sys.columns c ON c.object_id = ic.object_id AND c.column_id = ic.column_id
WHERE i.object_id = OBJECT_ID(N'dbo.Ekipmanlar')
  AND i.is_unique = 1 AND ic.key_ordinal = 1 AND c.name = N'EkipmanKodu'
  AND NOT EXISTS
  (
      SELECT 1 FROM sys.index_columns ic2
      WHERE ic2.object_id = i.object_id AND ic2.index_id = i.index_id AND ic2.key_ordinal > 1
  );
IF @TurNo IS NULL OR @EkipmanKodu IS NULL OR @EkipmanUnique IS NULL
    THROW 52021, N'Tekrarlanan kod testi için örnek ekipman ve UNIQUE kuralı bulunamadı.', 1;

/* 1. UNIQUE: mevcut ekipman kodu ikinci kez kabul edilmemeli. */
BEGIN TRY
    BEGIN TRANSACTION;
    INSERT INTO dbo.Ekipmanlar (TurNo, EkipmanKodu, EkipmanAdi, Konum, Durum)
    VALUES (@TurNo, @EkipmanKodu, N'UNIQUE testi', N'Test alanı', N'Aktif');
    THROW 52022, N'Tekrarlanan ekipman kodu kabul edildi.', 1;
END TRY
BEGIN CATCH
    IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
    IF ERROR_NUMBER() NOT IN (2601, 2627) OR CHARINDEX(@EkipmanUnique, ERROR_MESSAGE()) = 0
        THROW;
    PRINT N'BAŞARILI 1/6: Doğru UNIQUE kuralı tekrarlanan ekipman kodunu engelledi.';
END CATCH;

/* 2. FK: bulunmayan ekipmana sensör bağlanamamalı. */
IF EXISTS (SELECT 1 FROM dbo.Ekipmanlar WHERE EkipmanNo = -2147483648)
    THROW 52023, N'FK testi için ayrılan geçersiz ekipman numarası mevcut.', 1;
DECLARE @SensorKodu NVARCHAR(30) =
    N'T-S-' + LEFT(REPLACE(CONVERT(NVARCHAR(36), NEWID()), N'-', N''), 24);
BEGIN TRY
    BEGIN TRANSACTION;
    INSERT INTO dbo.Sensorler
        (EkipmanNo, SensorKodu, SensorTuru, OlcumBirimi, AltEsik, UstEsik, Durum)
    VALUES (-2147483648, @SensorKodu, N'Sıcaklık', N'°C', 0, 80, N'Aktif');
    THROW 52024, N'Geçersiz ekipman bağlantısı kabul edildi.', 1;
END TRY
BEGIN CATCH
    IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
    IF ERROR_NUMBER() <> 547 OR CHARINDEX(N'FK_Sensorler_Ekipmanlar', ERROR_MESSAGE()) = 0
        THROW;
    PRINT N'BAŞARILI 2/6: Doğru FK kuralı geçersiz ekipman bağlantısını engelledi.';
END CATCH;

/* 3. CHECK: negatif birim maliyet kabul edilmemeli. */
DECLARE @ParcaKodu NVARCHAR(30) =
    N'T-M-' + LEFT(REPLACE(CONVERT(NVARCHAR(36), NEWID()), N'-', N''), 24);
BEGIN TRY
    BEGIN TRANSACTION;
    INSERT INTO dbo.YedekParcalar (ParcaKodu, ParcaAdi, OlcuBirimi, AsgariStok, GuncelBirimMaliyet)
    VALUES (@ParcaKodu, N'Negatif maliyet testi', N'Adet', 10, -100);
    THROW 52025, N'Negatif maliyet kabul edildi.', 1;
END TRY
BEGIN CATCH
    IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
    IF ERROR_NUMBER() <> 547 OR CHARINDEX(N'CK_YedekParcalar_Maliyet', ERROR_MESSAGE()) = 0
        THROW;
    PRINT N'BAŞARILI 3/6: Doğru CHECK kuralı negatif maliyeti engelledi.';
END CATCH;

/* Denetim tablosundaki PUBLIC DENY yerine koruma tetikleyicisini test eder. */
IF COALESCE(IS_SRVROLEMEMBER(N'sysadmin'), 0) <> 1 AND USER_NAME() <> N'dbo'
    THROW 52026, N'Denetim tetikleyicisi testini sistem yöneticisi/veritabanı sahibi bağlantısıyla çalıştırın.', 1;

/* 4. Denetim kaydının UPDATE edilmesi engellenmeli. */
DECLARE @DenetimNo BIGINT;
BEGIN TRY
    BEGIN TRANSACTION;
    INSERT INTO dbo.DenetimKayitlari (OturumKullaniciAdi, TabloAdi, IslemTuru)
    VALUES (ORIGINAL_LOGIN(), N'Denetim koruma testi', N'INSERT');
    SET @DenetimNo = CONVERT(BIGINT, SCOPE_IDENTITY());
    UPDATE dbo.DenetimKayitlari SET TabloAdi = N'Değiştirildi' WHERE DenetimNo = @DenetimNo;
    THROW 52027, N'Denetim kaydı değiştirilebildi.', 1;
END TRY
BEGIN CATCH
    IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
    IF ERROR_NUMBER() <> 51005 THROW;
    PRINT N'BAŞARILI 4/6: Koruma tetikleyicisi denetim kaydının değiştirilmesini engelledi.';
END CATCH;

/* 5. Denetim kaydının DELETE edilmesi engellenmeli. */
BEGIN TRY
    BEGIN TRANSACTION;
    INSERT INTO dbo.DenetimKayitlari (OturumKullaniciAdi, TabloAdi, IslemTuru)
    VALUES (ORIGINAL_LOGIN(), N'Denetim silme testi', N'INSERT');
    SET @DenetimNo = CONVERT(BIGINT, SCOPE_IDENTITY());
    DELETE FROM dbo.DenetimKayitlari WHERE DenetimNo = @DenetimNo;
    THROW 52028, N'Denetim kaydı silinebildi.', 1;
END TRY
BEGIN CATCH
    IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
    IF ERROR_NUMBER() <> 51005 THROW;
    PRINT N'BAŞARILI 5/6: Koruma tetikleyicisi denetim kaydının silinmesini engelledi.';
END CATCH;

/* 6. Stoksuz yeni test parçasından çıkış negatif stok üretmemeli. */
DECLARE @StokParcaNo INT;
SET @ParcaKodu = N'T-N-' + LEFT(REPLACE(CONVERT(NVARCHAR(36), NEWID()), N'-', N''), 24);
BEGIN TRY
    BEGIN TRANSACTION;
    INSERT INTO dbo.YedekParcalar (ParcaKodu, ParcaAdi, OlcuBirimi, AsgariStok, GuncelBirimMaliyet)
    VALUES (@ParcaKodu, N'Negatif stok testi', N'Adet', 0, 1);
    SET @StokParcaNo = CONVERT(INT, SCOPE_IDENTITY());
    INSERT INTO dbo.StokHareketleri (ParcaNo, HareketTuru, Miktar, BirimMaliyet, Aciklama)
    VALUES (@StokParcaNo, N'Çıkış', 1, 1, N'Negatif stok testi');
    THROW 52029, N'Negatif stok çıkışı kabul edildi.', 1;
END TRY
BEGIN CATCH
    IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
    IF ERROR_NUMBER() <> 51004 THROW;
    PRINT N'BAŞARILI 6/6: Stok tetikleyicisi negatif stok oluşmasını engelledi.';
END CATCH;

IF @@TRANCOUNT <> 0 THROW 52030, N'Test sonunda açık işlem kaldı.', 1;
PRINT N'BAŞARILI: Altı olumsuz senaryo beklenen hatalarla engellendi; test işlemleri geri alındı.';
GO
