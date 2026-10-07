USE EndustriyelBakimDB;
GO

/* AYNI EKİPMAN KODU TESTİ */

BEGIN TRY
    BEGIN TRANSACTION;

    DECLARE @TurNo INT =
        (SELECT TOP (1) TurNo FROM dbo.EkipmanTurleri);

    DECLARE @EkipmanKodu NVARCHAR(30) =
        (SELECT TOP (1) EkipmanKodu FROM dbo.Ekipmanlar);

    INSERT INTO dbo.Ekipmanlar
    (
        TurNo,
        EkipmanKodu,
        EkipmanAdi,
        Konum,
        Durum
    )
    VALUES
    (
        @TurNo,
        @EkipmanKodu,
        N'Tekrar Testi',
        N'Test Alanı',
        N'Aktif'
    );

    ROLLBACK TRANSACTION;
    PRINT N'BAŞARISIZ: Tekrarlanan ekipman kodu kabul edildi.';
END TRY
BEGIN CATCH
    IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
    PRINT N'BAŞARILI: Tekrarlanan ekipman kodu engellendi.';
END CATCH;
GO

/* GEÇERSİZ SENSÖR BAĞLANTISI TESTİ */

BEGIN TRY
    BEGIN TRANSACTION;

    INSERT INTO dbo.Sensorler
    (
        EkipmanNo,
        SensorKodu,
        SensorTuru,
        OlcumBirimi,
        AltEsik,
        UstEsik,
        Durum
    )
    VALUES
    (
        -999,
        N'TEST-SENSOR',
        N'Sıcaklık',
        N'°C',
        0,
        80,
        N'Aktif'
    );

    ROLLBACK TRANSACTION;
    PRINT N'BAŞARISIZ: Geçersiz ekipman bağlantısı kabul edildi.';
END TRY
BEGIN CATCH
    IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
    PRINT N'BAŞARILI: Geçersiz ekipman bağlantısı engellendi.';
END CATCH;
GO

/* NEGATİF MALİYET TESTİ */

BEGIN TRY
    BEGIN TRANSACTION;

    INSERT INTO dbo.YedekParcalar
    (
        ParcaKodu,
        ParcaAdi,
        OlcuBirimi,
        AsgariStok,
        GuncelBirimMaliyet
    )
    VALUES
    (
        N'TEST-NEGATIF',
        N'Negatif Maliyet Testi',
        N'Adet',
        10,
        -100
    );

    ROLLBACK TRANSACTION;
    PRINT N'BAŞARISIZ: Negatif maliyet kabul edildi.';
END TRY
BEGIN CATCH
    IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
    PRINT N'BAŞARILI: Negatif maliyet engellendi.';
END CATCH;
GO

/* DENETİM KAYDI DEĞİŞTİRME TESTİ */

IF EXISTS (SELECT 1 FROM dbo.DenetimKayitlari)
BEGIN
    BEGIN TRY
        BEGIN TRANSACTION;

        UPDATE dbo.DenetimKayitlari
        SET TabloAdi = N'Değiştirildi'
        WHERE DenetimNo =
            (SELECT TOP (1) DenetimNo FROM dbo.DenetimKayitlari);

        ROLLBACK TRANSACTION;
        PRINT N'BAŞARISIZ: Denetim kaydı değiştirildi.';
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
        PRINT N'BAŞARILI: Denetim kaydı değişikliği engellendi.';
    END CATCH;
END
ELSE
    PRINT N'BİLGİ: Denetim kaydı olmadığı için test yapılmadı.';
GO