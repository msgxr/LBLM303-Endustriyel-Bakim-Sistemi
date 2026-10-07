USE EndustriyelBakimDB;
GO

SET NOCOUNT ON;
SET XACT_ABORT ON;

BEGIN TRY
    BEGIN TRANSACTION;

    DECLARE @SensorNo INT;
    DECLARE @UstEsik DECIMAL(18,4);
    DECLARE @KullaniciNo INT;
    DECLARE @TeknisyenNo INT;
    DECLARE @ParcaNo INT;
    DECLARE @EkipmanNo INT;
    DECLARE @OlcumNo BIGINT;
    DECLARE @AlarmNo BIGINT;
    DECLARE @ArizaNo BIGINT;
    DECLARE @BakimEmriNo BIGINT;

    /* Testte kullanılacak sensör */
    SELECT TOP (1)
        @SensorNo = s.SensorNo,
        @UstEsik = s.UstEsik,
        @EkipmanNo = s.EkipmanNo
    FROM dbo.Sensorler s
    WHERE s.UstEsik IS NOT NULL
    ORDER BY s.SensorNo;

    /* Sensörün önceki aktif alarmlarını test süresince kapat */
    UPDATE a
    SET a.Durum = N'Kapalı'
    FROM dbo.Alarmlar a
    INNER JOIN dbo.Olcumler o ON o.OlcumNo = a.OlcumNo
    WHERE o.SensorNo = @SensorNo
      AND a.Durum IN (N'Açık', N'İncelendi');

    SELECT TOP (1)
        @KullaniciNo = KullaniciNo
    FROM dbo.Kullanicilar
    WHERE Aktif = 1
    ORDER BY KullaniciNo;

    SELECT TOP (1)
        @TeknisyenNo = TeknisyenNo
    FROM dbo.Teknisyenler
    WHERE Durum = N'Aktif'
    ORDER BY TeknisyenNo;

    SELECT TOP (1)
        @ParcaNo = ParcaNo
    FROM dbo.YedekParcalar
    ORDER BY ParcaNo;

    IF @SensorNo IS NULL
        THROW 51000, N'Test için sensör bulunamadı.', 1;

    IF @KullaniciNo IS NULL
        THROW 51001, N'Test için aktif kullanıcı bulunamadı.', 1;

    IF @TeknisyenNo IS NULL
        THROW 51002, N'Test için aktif teknisyen bulunamadı.', 1;

    IF @ParcaNo IS NULL
        THROW 51003, N'Test için yedek parça bulunamadı.', 1;

    /* Eşik üstü ölçüm eklenir ve alarm tetiklenir */
    INSERT INTO dbo.Olcumler
    (
        SensorNo,
        OlcumDegeri,
        OlcumZamani
    )
    VALUES
    (
        @SensorNo,
        @UstEsik + 100,
        SYSDATETIME()
    );

    SET @OlcumNo = SCOPE_IDENTITY();

    SELECT @AlarmNo = AlarmNo
    FROM dbo.Alarmlar
    WHERE OlcumNo = @OlcumNo;

    IF @AlarmNo IS NULL
        THROW 51004, N'Ölçüm sonrasında alarm oluşturulamadı.', 1;

    /* Alarm incelenir */
    EXEC dbo.sp_AlarmIncele
        @AlarmNo = @AlarmNo,
        @KullaniciNo = @KullaniciNo,
        @IncelemeSonucu = N'Test alarmı incelendi.';

    /* Alarmdan arıza oluşturulur */
    EXEC dbo.sp_AlarmdanArizaOlustur
        @AlarmNo = @AlarmNo,
        @ArizaAciklamasi = N'İş akışı test arızası',
        @ArizaNedeni = N'Eşik aşımı',
        @Oncelik = N'Yüksek',
        @DogrulayanKullaniciNo = @KullaniciNo,
        @YeniArizaNo = @ArizaNo OUTPUT;

    /* Arızaya bakım emri oluşturulur */
    EXEC dbo.sp_BakimEmriOlustur
        @EkipmanNo = @EkipmanNo,
        @ArizaNo = @ArizaNo,
        @BakimTuru = N'Düzeltici',
        @Aciklama = N'İş akışı test bakım emri',
        @Oncelik = N'Yüksek',
        @YeniBakimEmriNo = @BakimEmriNo OUTPUT;

    /* Teknisyen görevlendirilir */
    EXEC dbo.sp_TeknisyenGorevlendir
        @BakimEmriNo = @BakimEmriNo,
        @TeknisyenNo = @TeknisyenNo;

    /* Test için stok eklenir */
    INSERT INTO dbo.StokHareketleri
    (
        ParcaNo,
        HareketTuru,
        Miktar,
        BirimMaliyet,
        KullaniciNo,
        Aciklama
    )
    SELECT
        @ParcaNo,
        N'Giriş',
        100,
        GuncelBirimMaliyet,
        @KullaniciNo,
        N'İş akışı test stok girişi'
    FROM dbo.YedekParcalar
    WHERE ParcaNo = @ParcaNo;

    /* Bakımda parça kullanılır */
    EXEC dbo.sp_ParcaKullan
        @BakimEmriNo = @BakimEmriNo,
        @ParcaNo = @ParcaNo,
        @Miktar = 2,
        @KullaniciNo = @KullaniciNo;

    /* Bakım tamamlanır */
    EXEC dbo.sp_BakimTamamla
        @BakimEmriNo = @BakimEmriNo,
        @KontrolEdenKullaniciNo = @KullaniciNo,
        @YapilanIs = N'Test bakım işlemi tamamlandı.';

    SELECT
        a.AlarmNo,
        a.Durum AS AlarmDurumu,
        ar.ArizaNo,
        ar.Durum AS ArizaDurumu,
        b.BakimEmriNo,
        b.Durum AS BakimDurumu
    FROM dbo.Alarmlar a
    INNER JOIN dbo.Arizalar ar ON ar.AlarmNo = a.AlarmNo
    INNER JOIN dbo.BakimEmirleri b ON b.ArizaNo = ar.ArizaNo
    WHERE a.AlarmNo = @AlarmNo;

    PRINT N'BAŞARILI: Uçtan uca iş akışı tamamlandı.';

    /* Test kayıtları kalıcı olmasın */
    ROLLBACK TRANSACTION;
END TRY
BEGIN CATCH
    IF @@TRANCOUNT > 0
        ROLLBACK TRANSACTION;

    PRINT N'BAŞARISIZ: İş akışı testi hata verdi.';
    THROW;
END CATCH;
GO