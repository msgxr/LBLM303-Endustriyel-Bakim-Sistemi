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

IF @@TRANCOUNT <> 0
    THROW 52040, N'İş akışı testini açık kullanıcı işlemi dışında çalıştırın.', 1;

/* Bu dosya iş akışını gerçekten çalıştırır, ara/son durumları doğrular,
   sonra ROLLBACK yapar. Canlı işlem trafiği olmayan bir test ortamında kullanın.
   ROLLBACK satırları geri alır; IDENTITY sıra numaralarının tüketimi geri alınmaz. */
DECLARE @SensorNo INT, @EkipmanNo INT, @KullaniciNo INT, @TeknisyenNo INT, @ParcaNo INT;
DECLARE @UstEsik DECIMAL(18,4);
DECLARE @OlcumNo BIGINT, @AlarmNo BIGINT, @ArizaNo BIGINT, @BakimEmriNo BIGINT;
DECLARE @GirisNo BIGINT, @BakimParcaNo BIGINT, @GorevlendirmeNo BIGINT, @DurusNo BIGINT;
DECLARE @StokOnce DECIMAL(38,4), @StokSonra DECIMAL(38,4);
DECLARE @OncekiAlarmlar TABLE (AlarmNo BIGINT PRIMARY KEY, Durum NVARCHAR(20));

BEGIN TRY
    BEGIN TRANSACTION;

    SELECT TOP (1) @SensorNo = s.SensorNo, @UstEsik = s.UstEsik, @EkipmanNo = s.EkipmanNo
    FROM dbo.Sensorler s WHERE s.Durum = N'Aktif' ORDER BY s.SensorNo;
    SELECT TOP (1) @KullaniciNo = KullaniciNo
    FROM dbo.Kullanicilar WHERE Aktif = 1 ORDER BY KullaniciNo;
    SELECT TOP (1) @TeknisyenNo = TeknisyenNo
    FROM dbo.Teknisyenler WHERE Durum = N'Aktif' ORDER BY TeknisyenNo;
    SELECT TOP (1) @ParcaNo = ParcaNo
    FROM dbo.YedekParcalar ORDER BY ParcaNo;

    IF @SensorNo IS NULL OR @UstEsik IS NULL
        THROW 52041, N'Test için eşik bilgisi olan aktif sensör bulunamadı.', 1;
    IF @KullaniciNo IS NULL THROW 52042, N'Test için aktif kullanıcı bulunamadı.', 1;
    IF @TeknisyenNo IS NULL THROW 52043, N'Test için aktif teknisyen bulunamadı.', 1;
    IF @ParcaNo IS NULL THROW 52044, N'Test için yedek parça bulunamadı.', 1;
    IF @UstEsik > 99999999999899.9999
        THROW 52045, N'Test ölçümü DECIMAL(18,4) sınırını aşacak.', 1;

    INSERT INTO @OncekiAlarmlar (AlarmNo, Durum)
    SELECT a.AlarmNo, a.Durum
    FROM dbo.Alarmlar a
    INNER JOIN dbo.Olcumler o ON o.OlcumNo = a.OlcumNo
    WHERE o.SensorNo = @SensorNo AND a.Durum IN (N'Açık', N'İncelendi');

    /* Alarm tekilleştirmesi test ölçümüne engel olmasın; bu UPDATE geri alınır. */
    UPDATE a SET Durum = N'Kapalı'
    FROM dbo.Alarmlar a
    INNER JOIN @OncekiAlarmlar x ON x.AlarmNo = a.AlarmNo;

    SELECT @StokOnce = COALESCE(SUM(CASE
        WHEN HareketTuru IN (N'Giriş', N'İade') THEN Miktar
        WHEN HareketTuru IN (N'Çıkış', N'Kullanım') THEN -Miktar ELSE 0 END), 0)
    FROM dbo.StokHareketleri WHERE ParcaNo = @ParcaNo;

    INSERT INTO dbo.Olcumler (SensorNo, OlcumDegeri, OlcumZamani)
    VALUES (@SensorNo, @UstEsik + 100, SYSDATETIME());
    SET @OlcumNo = CONVERT(BIGINT, SCOPE_IDENTITY());

    IF (SELECT COUNT(*) FROM dbo.Alarmlar WHERE OlcumNo = @OlcumNo) <> 1
        THROW 52046, N'Test ölçümü için tam bir alarm oluşturulmadı.', 1;
    SELECT @AlarmNo = AlarmNo FROM dbo.Alarmlar WHERE OlcumNo = @OlcumNo;
    IF NOT EXISTS (SELECT 1 FROM dbo.Alarmlar WHERE AlarmNo = @AlarmNo AND Durum = N'Açık')
        THROW 52047, N'Yeni alarm Açık durumunda değil.', 1;
    PRINT N'BAŞARILI 1/8: Eşik aşımı otomatik alarm oluşturdu.';

    EXEC dbo.sp_AlarmIncele
        @AlarmNo = @AlarmNo, @KullaniciNo = @KullaniciNo,
        @IncelemeSonucu = N'İş akışı test alarmı incelendi.';
    IF NOT EXISTS
    (
        SELECT 1 FROM dbo.Alarmlar WHERE AlarmNo = @AlarmNo AND Durum = N'İncelendi'
          AND InceleyenKullaniciNo = @KullaniciNo AND IncelemeZamani IS NOT NULL
    )
        THROW 52048, N'Alarm inceleme bilgileri kaydedilmedi.', 1;
    PRINT N'BAŞARILI 2/8: Alarm incelendi.';

    EXEC dbo.sp_AlarmdanArizaOlustur
        @AlarmNo = @AlarmNo, @ArizaAciklamasi = N'İş akışı test arızası',
        @ArizaNedeni = N'Eşik aşımı', @Oncelik = N'Yüksek',
        @DogrulayanKullaniciNo = @KullaniciNo, @YeniArizaNo = @ArizaNo OUTPUT;
    IF @ArizaNo IS NULL OR NOT EXISTS
    (
        SELECT 1 FROM dbo.Arizalar WHERE ArizaNo = @ArizaNo AND AlarmNo = @AlarmNo
          AND EkipmanNo = @EkipmanNo AND Durum = N'Doğrulandı'
    )
        THROW 52049, N'Arıza doğru alarm ve ekipmana bağlı olarak oluşturulmadı.', 1;
    PRINT N'BAŞARILI 3/8: Alarmdan doğrulanmış arıza oluşturuldu.';

    EXEC dbo.sp_BakimEmriOlustur
        @EkipmanNo = @EkipmanNo, @ArizaNo = @ArizaNo, @BakimTuru = N'Düzeltici',
        @Aciklama = N'İş akışı test bakım emri', @Oncelik = N'Yüksek',
        @YeniBakimEmriNo = @BakimEmriNo OUTPUT;
    IF @BakimEmriNo IS NULL OR NOT EXISTS
    (
        SELECT 1 FROM dbo.BakimEmirleri WHERE BakimEmriNo = @BakimEmriNo
          AND ArizaNo = @ArizaNo AND EkipmanNo = @EkipmanNo AND Durum = N'Bekliyor'
    )
        THROW 52050, N'Bakım emri doğru ilişkilerle oluşturulmadı.', 1;

    EXEC dbo.sp_TeknisyenGorevlendir @BakimEmriNo = @BakimEmriNo, @TeknisyenNo = @TeknisyenNo;
    SELECT @GorevlendirmeNo = GorevlendirmeNo FROM dbo.BakimGorevlendirmeleri
    WHERE BakimEmriNo = @BakimEmriNo AND TeknisyenNo = @TeknisyenNo;
    IF @GorevlendirmeNo IS NULL OR NOT EXISTS
        (SELECT 1 FROM dbo.BakimEmirleri WHERE BakimEmriNo = @BakimEmriNo AND Durum = N'Atandı')
        THROW 52051, N'Teknisyen görevlendirme veya Atandı durumu kaydedilmedi.', 1;
    PRINT N'BAŞARILI 4/8: Bakım emri açıldı ve teknisyen atandı.';

    INSERT INTO dbo.StokHareketleri
        (ParcaNo, HareketTuru, Miktar, BirimMaliyet, KullaniciNo, Aciklama)
    SELECT @ParcaNo, N'Giriş', 100, GuncelBirimMaliyet, @KullaniciNo, N'İş akışı test stok girişi'
    FROM dbo.YedekParcalar WHERE ParcaNo = @ParcaNo;
    SET @GirisNo = CONVERT(BIGINT, SCOPE_IDENTITY());

    EXEC dbo.sp_ParcaKullan
        @BakimEmriNo = @BakimEmriNo, @ParcaNo = @ParcaNo, @Miktar = 2, @KullaniciNo = @KullaniciNo;
    SELECT @BakimParcaNo = BakimParcaNo FROM dbo.BakimParcalari
    WHERE BakimEmriNo = @BakimEmriNo AND ParcaNo = @ParcaNo AND IslemTuru = N'Kullanım' AND Miktar = 2;
    IF @BakimParcaNo IS NULL OR NOT EXISTS
    (
        SELECT 1 FROM dbo.StokHareketleri WHERE BakimParcaNo = @BakimParcaNo
          AND ParcaNo = @ParcaNo AND HareketTuru = N'Kullanım' AND Miktar = 2
    )
        THROW 52052, N'Parça kullanımı ile bağlı stok hareketi birlikte oluşmadı.', 1;

    SELECT @StokSonra = COALESCE(SUM(CASE
        WHEN HareketTuru IN (N'Giriş', N'İade') THEN Miktar
        WHEN HareketTuru IN (N'Çıkış', N'Kullanım') THEN -Miktar ELSE 0 END), 0)
    FROM dbo.StokHareketleri WHERE ParcaNo = @ParcaNo;
    IF @StokSonra <> @StokOnce + 98 THROW 52053, N'Stok bakiyesi beklenen +100-2 değişimini göstermedi.', 1;
    PRINT N'BAŞARILI 5/8: Parça kullanımı ve stok bakiyesi doğrulandı.';

    /* Duruş başlangıcını test hazırlar; bitişini bakım tamamlama yordamı kaydeder. */
    INSERT INTO dbo.DurusKayitlari (EkipmanNo, ArizaNo, BaslangicZamani, DurusNedeni)
    VALUES (@EkipmanNo, @ArizaNo, SYSDATETIME(), N'İş akışı test duruşu');
    SET @DurusNo = CONVERT(BIGINT, SCOPE_IDENTITY());

    EXEC dbo.sp_BakimTamamla
        @BakimEmriNo = @BakimEmriNo, @KontrolEdenKullaniciNo = @KullaniciNo,
        @YapilanIs = N'Test bakım işlemi tamamlandı.';
    IF NOT EXISTS (SELECT 1 FROM dbo.Alarmlar WHERE AlarmNo = @AlarmNo AND Durum = N'Kapalı' AND KapanisZamani IS NOT NULL)
    OR NOT EXISTS (SELECT 1 FROM dbo.Arizalar WHERE ArizaNo = @ArizaNo AND Durum = N'Kapalı' AND KapanisZamani IS NOT NULL)
    OR NOT EXISTS (SELECT 1 FROM dbo.BakimEmirleri WHERE BakimEmriNo = @BakimEmriNo AND Durum = N'Tamamlandı' AND TamamlanmaZamani IS NOT NULL)
    OR NOT EXISTS (SELECT 1 FROM dbo.DurusKayitlari WHERE DurusNo = @DurusNo AND BitisZamani IS NOT NULL)
    OR NOT EXISTS (SELECT 1 FROM dbo.BakimGorevlendirmeleri WHERE GorevlendirmeNo = @GorevlendirmeNo AND CalismaBitisi IS NOT NULL)
        THROW 52054, N'Bakım tamamlandığında alarm, arıza, görevlendirme veya duruş kapanmadı.', 1;
    IF @@TRANCOUNT <> 1 OR XACT_STATE() <> 1
        THROW 52055, N'Yordamlar test işleminin transaction dengesini bozdu.', 1;
    PRINT N'BAŞARILI 6/8: Bakım tamamlandı; ilişkili kayıtlar kapandı.';

    IF NOT EXISTS
    (
        SELECT 1 FROM dbo.DenetimKayitlari
        WHERE TabloAdi = N'BakimEmirleri'
          AND KayitAnahtari = CONVERT(NVARCHAR(250), @BakimEmriNo) AND IslemTuru = N'INSERT'
    )
    OR NOT EXISTS
    (
        SELECT 1 FROM dbo.DenetimKayitlari
        WHERE TabloAdi = N'BakimEmirleri'
          AND KayitAnahtari = CONVERT(NVARCHAR(250), @BakimEmriNo) AND IslemTuru = N'UPDATE'
    )
    OR NOT EXISTS
    (
        SELECT 1 FROM dbo.DenetimKayitlari
        WHERE TabloAdi = N'StokHareketleri'
          AND KayitAnahtari = CONVERT(NVARCHAR(250), @GirisNo) AND IslemTuru = N'INSERT'
    )
        THROW 52056, N'Bakım emri veya stok denetim kayıtları oluşmadı.', 1;
    PRINT N'BAŞARILI 7/8: Bakım emri ve stok işlemleri denetim kayıtlarına işlendi.';

    SELECT a.AlarmNo, a.Durum AS AlarmDurumu, ar.ArizaNo, ar.Durum AS ArizaDurumu,
        b.BakimEmriNo, b.Durum AS BakimDurumu
    FROM dbo.Alarmlar a
    INNER JOIN dbo.Arizalar ar ON ar.AlarmNo = a.AlarmNo
    INNER JOIN dbo.BakimEmirleri b ON b.ArizaNo = ar.ArizaNo
    WHERE a.AlarmNo = @AlarmNo;
    SELECT @StokOnce AS TestOncesiStok, @StokSonra AS TestIcindeStok, @StokOnce + 98 AS BeklenenTestStogu;

    ROLLBACK TRANSACTION;

    IF EXISTS (SELECT 1 FROM dbo.Olcumler WHERE OlcumNo = @OlcumNo)
    OR EXISTS (SELECT 1 FROM dbo.Alarmlar WHERE AlarmNo = @AlarmNo)
    OR EXISTS (SELECT 1 FROM dbo.Arizalar WHERE ArizaNo = @ArizaNo)
    OR EXISTS (SELECT 1 FROM dbo.BakimEmirleri WHERE BakimEmriNo = @BakimEmriNo)
    OR EXISTS (SELECT 1 FROM dbo.BakimGorevlendirmeleri WHERE GorevlendirmeNo = @GorevlendirmeNo)
    OR EXISTS (SELECT 1 FROM dbo.BakimParcalari WHERE BakimParcaNo = @BakimParcaNo)
    OR EXISTS (SELECT 1 FROM dbo.DurusKayitlari WHERE DurusNo = @DurusNo)
    OR EXISTS (SELECT 1 FROM dbo.StokHareketleri WHERE StokHareketNo = @GirisNo OR BakimParcaNo = @BakimParcaNo)
    OR EXISTS
    (
        SELECT 1 FROM dbo.DenetimKayitlari
        WHERE (TabloAdi = N'BakimEmirleri' AND KayitAnahtari = CONVERT(NVARCHAR(250), @BakimEmriNo))
           OR (TabloAdi = N'StokHareketleri' AND KayitAnahtari = CONVERT(NVARCHAR(250), @GirisNo))
    )
        THROW 52057, N'ROLLBACK sonrasında test kaydı kaldı.', 1;

    IF EXISTS
    (
        SELECT 1 FROM @OncekiAlarmlar x
        LEFT JOIN dbo.Alarmlar a ON a.AlarmNo = x.AlarmNo
        WHERE a.AlarmNo IS NULL OR a.Durum <> x.Durum
    )
        THROW 52058, N'Önceki aktif alarm durumları geri yüklenmedi.', 1;

    SELECT @StokSonra = COALESCE(SUM(CASE
        WHEN HareketTuru IN (N'Giriş', N'İade') THEN Miktar
        WHEN HareketTuru IN (N'Çıkış', N'Kullanım') THEN -Miktar ELSE 0 END), 0)
    FROM dbo.StokHareketleri WHERE ParcaNo = @ParcaNo;
    IF @StokSonra <> @StokOnce OR @@TRANCOUNT <> 0
        THROW 52059, N'ROLLBACK stok bakiyesini veya transaction durumunu geri yüklemedi.', 1;
    PRINT N'BAŞARILI 8/8: ROLLBACK doğrulandı; test kayıtları kalmadı.';
    PRINT N'BAŞARILI: Uçtan uca iş akışı, denetim kaydı ve geri alma kontrolleri geçti.';
END TRY
BEGIN CATCH
    IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
    PRINT N'BAŞARISIZ: İş akışı testi durdu; aşağıdaki hata düzeltilmelidir.';
    THROW;
END CATCH;
GO
