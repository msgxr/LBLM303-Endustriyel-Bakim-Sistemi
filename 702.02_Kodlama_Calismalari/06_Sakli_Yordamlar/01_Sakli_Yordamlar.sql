USE EndustriyelBakimDB;
GO

/* =========================================================
   1. ALARM İNCELEME
   Alarmı yetkili kullanıcı tarafından incelenmiş olarak işaretler.
   ========================================================= */

CREATE OR ALTER PROCEDURE dbo.sp_AlarmIncele
    @AlarmNo BIGINT,
    @KullaniciNo INT,
    @IncelemeSonucu NVARCHAR(250)
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    IF NOT EXISTS
    (
        SELECT 1 FROM dbo.Alarmlar
        WHERE AlarmNo = @AlarmNo
    )
        THROW 50001, N'Alarm bulunamadı.', 1;

    IF NOT EXISTS
    (
        SELECT 1 FROM dbo.Kullanicilar
        WHERE KullaniciNo = @KullaniciNo
          AND Aktif = 1
    )
        THROW 50002, N'Aktif kullanıcı bulunamadı.', 1;

    UPDATE dbo.Alarmlar
    SET
        Durum = N'İncelendi',
        InceleyenKullaniciNo = @KullaniciNo,
        IncelemeZamani = SYSDATETIME(),
        IncelemeSonucu = @IncelemeSonucu
    WHERE AlarmNo = @AlarmNo;
END;
GO

/* =========================================================
   2. ALARMDAN ARIZA OLUŞTURMA
   İncelenmiş alarmı arıza kaydına dönüştürür.
   ========================================================= */

CREATE OR ALTER PROCEDURE dbo.sp_AlarmdanArizaOlustur
    @AlarmNo BIGINT,
    @ArizaAciklamasi NVARCHAR(500),
    @ArizaNedeni NVARCHAR(250),
    @Oncelik NVARCHAR(20),
    @DogrulayanKullaniciNo INT,
    @YeniArizaNo BIGINT OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    BEGIN TRY
        BEGIN TRANSACTION;

        DECLARE @EkipmanNo INT;
        DECLARE @IncelemeZamani DATETIME2;

        SELECT
            @EkipmanNo = s.EkipmanNo,
            @IncelemeZamani = a.IncelemeZamani
        FROM dbo.Alarmlar a WITH (UPDLOCK, HOLDLOCK)
        INNER JOIN dbo.Olcumler o
            ON o.OlcumNo = a.OlcumNo
        INNER JOIN dbo.Sensorler s
            ON s.SensorNo = o.SensorNo
        WHERE a.AlarmNo = @AlarmNo;

        IF @EkipmanNo IS NULL
            THROW 50003, N'Alarm veya bağlı ekipman bulunamadı.', 1;

        IF @IncelemeZamani IS NULL
            THROW 50004, N'Alarm incelenmeden arıza oluşturulamaz.', 1;

        IF EXISTS
        (
            SELECT 1 FROM dbo.Arizalar
            WHERE AlarmNo = @AlarmNo
        )
            THROW 50005, N'Bu alarm için daha önce arıza oluşturulmuştur.', 1;

        INSERT INTO dbo.Arizalar
        (
            EkipmanNo,
            AlarmNo,
            ArizaAciklamasi,
            ArizaNedeni,
            Oncelik,
            Durum,
            DogrulayanKullaniciNo,
            DogrulamaZamani
        )
        VALUES
        (
            @EkipmanNo,
            @AlarmNo,
            @ArizaAciklamasi,
            @ArizaNedeni,
            @Oncelik,
            N'Doğrulandı',
            @DogrulayanKullaniciNo,
            SYSDATETIME()
        );

        SET @YeniArizaNo = SCOPE_IDENTITY();

        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0
            ROLLBACK TRANSACTION;

        THROW;
    END CATCH
END;
GO

/* =========================================================
   3. BAKIM EMRİ OLUŞTURMA
   Planlı veya arıza kaynaklı bakım emri oluşturur.
   ========================================================= */

CREATE OR ALTER PROCEDURE dbo.sp_BakimEmriOlustur
    @EkipmanNo INT,
    @ArizaNo BIGINT = NULL,
    @BakimTuru NVARCHAR(30),
    @Aciklama NVARCHAR(500),
    @Oncelik NVARCHAR(20),
    @PlanlananBaslangic DATETIME2 = NULL,
    @YeniBakimEmriNo BIGINT OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    BEGIN TRY
        BEGIN TRANSACTION;

        IF NOT EXISTS
        (
            SELECT 1 FROM dbo.Ekipmanlar
            WHERE EkipmanNo = @EkipmanNo
        )
            THROW 50006, N'Ekipman bulunamadı.', 1;

        IF @ArizaNo IS NOT NULL
        BEGIN
            IF NOT EXISTS
            (
                SELECT 1
                FROM dbo.Arizalar
                WHERE ArizaNo = @ArizaNo
                  AND EkipmanNo = @EkipmanNo
            )
                THROW 50007, N'Arıza bu ekipmana ait değildir.', 1;

            IF EXISTS
            (
                SELECT 1
                FROM dbo.BakimEmirleri WITH (UPDLOCK, HOLDLOCK)
                WHERE ArizaNo = @ArizaNo
                  AND BakimTuru = N'Düzeltici'
                  AND Durum NOT IN (N'Tamamlandı', N'İptal Edildi')
            )
                THROW 50008, N'Arıza için aktif bakım emri bulunmaktadır.', 1;
        END;

        INSERT INTO dbo.BakimEmirleri
        (
            EkipmanNo,
            ArizaNo,
            BakimTuru,
            Aciklama,
            Oncelik,
            Durum,
            PlanlananBaslangic
        )
        VALUES
        (
            @EkipmanNo,
            @ArizaNo,
            @BakimTuru,
            @Aciklama,
            @Oncelik,
            N'Bekliyor',
            @PlanlananBaslangic
        );

        SET @YeniBakimEmriNo = SCOPE_IDENTITY();

        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0
            ROLLBACK TRANSACTION;

        THROW;
    END CATCH
END;
GO

/* =========================================================
   4. TEKNİSYEN GÖREVLENDİRME
   Aktif teknisyeni bakım emrine atar.
   ========================================================= */

CREATE OR ALTER PROCEDURE dbo.sp_TeknisyenGorevlendir
    @BakimEmriNo BIGINT,
    @TeknisyenNo INT
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    DECLARE @SaatlikUcret DECIMAL(12,2);

    SELECT @SaatlikUcret = SaatlikUcret
    FROM dbo.Teknisyenler
    WHERE TeknisyenNo = @TeknisyenNo
      AND Durum = N'Aktif';

    IF @SaatlikUcret IS NULL
        THROW 50009, N'Aktif teknisyen bulunamadı.', 1;

    IF NOT EXISTS
    (
        SELECT 1
        FROM dbo.BakimEmirleri
        WHERE BakimEmriNo = @BakimEmriNo
          AND Durum NOT IN (N'Tamamlandı', N'İptal Edildi')
    )
        THROW 50010, N'Aktif bakım emri bulunamadı.', 1;

    IF EXISTS
    (
        SELECT 1
        FROM dbo.BakimGorevlendirmeleri
        WHERE BakimEmriNo = @BakimEmriNo
          AND TeknisyenNo = @TeknisyenNo
    )
        THROW 50011, N'Teknisyen bu bakım emrine zaten atanmıştır.', 1;

    INSERT INTO dbo.BakimGorevlendirmeleri
    (
        BakimEmriNo,
        TeknisyenNo,
        IslemAnindakiSaatlikUcret
    )
    VALUES
    (
        @BakimEmriNo,
        @TeknisyenNo,
        @SaatlikUcret
    );

    UPDATE dbo.BakimEmirleri
    SET Durum = N'Atandı'
    WHERE BakimEmriNo = @BakimEmriNo
      AND Durum = N'Bekliyor';
END;
GO

/* =========================================================
   5. YEDEK PARÇA KULLANIMI
   Stok kontrolü yapar ve iki kaydı tek işlemde oluşturur.
   ========================================================= */

CREATE OR ALTER PROCEDURE dbo.sp_ParcaKullan
    @BakimEmriNo BIGINT,
    @ParcaNo INT,
    @Miktar DECIMAL(18,4),
    @KullaniciNo INT
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    BEGIN TRY
        SET TRANSACTION ISOLATION LEVEL SERIALIZABLE;
        BEGIN TRANSACTION;

        DECLARE @BirimMaliyet DECIMAL(12,2);
        DECLARE @MevcutStok DECIMAL(18,4);
        DECLARE @BakimParcaNo BIGINT;

        IF @Miktar <= 0
            THROW 50012, N'Kullanım miktarı sıfırdan büyük olmalıdır.', 1;

        SELECT @BirimMaliyet = GuncelBirimMaliyet
        FROM dbo.YedekParcalar WITH (UPDLOCK, HOLDLOCK)
        WHERE ParcaNo = @ParcaNo;

        IF @BirimMaliyet IS NULL
            THROW 50013, N'Yedek parça bulunamadı.', 1;

        IF NOT EXISTS
        (
            SELECT 1
            FROM dbo.BakimEmirleri
            WHERE BakimEmriNo = @BakimEmriNo
              AND Durum NOT IN (N'Tamamlandı', N'İptal Edildi')
        )
            THROW 50014, N'Aktif bakım emri bulunamadı.', 1;

        SELECT
            @MevcutStok = COALESCE
            (
                SUM
                (
                    CASE
                        WHEN HareketTuru IN (N'Giriş', N'İade')
                            THEN Miktar
                        WHEN HareketTuru IN (N'Çıkış', N'Kullanım')
                            THEN -Miktar
                        ELSE 0
                    END
                ),
                0
            )
        FROM dbo.StokHareketleri
        WHERE ParcaNo = @ParcaNo;

        IF @MevcutStok < @Miktar
            THROW 50015, N'Yeterli stok bulunmamaktadır.', 1;

        INSERT INTO dbo.BakimParcalari
        (
            BakimEmriNo,
            ParcaNo,
            IslemTuru,
            Miktar,
            IslemAnindakiBirimMaliyet,
            KullaniciNo
        )
        VALUES
        (
            @BakimEmriNo,
            @ParcaNo,
            N'Kullanım',
            @Miktar,
            @BirimMaliyet,
            @KullaniciNo
        );

        SET @BakimParcaNo = SCOPE_IDENTITY();

        INSERT INTO dbo.StokHareketleri
        (
            ParcaNo,
            BakimParcaNo,
            HareketTuru,
            Miktar,
            BirimMaliyet,
            KullaniciNo,
            Aciklama
        )
        VALUES
        (
            @ParcaNo,
            @BakimParcaNo,
            N'Kullanım',
            @Miktar,
            @BirimMaliyet,
            @KullaniciNo,
            N'Bakım emrinde parça kullanımı'
        );

        COMMIT TRANSACTION;
        SET TRANSACTION ISOLATION LEVEL READ COMMITTED;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0
            ROLLBACK TRANSACTION;

        SET TRANSACTION ISOLATION LEVEL READ COMMITTED;
        THROW;
    END CATCH
END;
GO

/* =========================================================
   6. BAKIMI TAMAMLAMA
   Bakım emrini, arızayı, alarmı ve duruşu kapatır.
   ========================================================= */

CREATE OR ALTER PROCEDURE dbo.sp_BakimTamamla
    @BakimEmriNo BIGINT,
    @KontrolEdenKullaniciNo INT,
    @YapilanIs NVARCHAR(500)
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    BEGIN TRY
        BEGIN TRANSACTION;

        DECLARE @ArizaNo BIGINT;
        DECLARE @AlarmNo BIGINT;

        SELECT @ArizaNo = ArizaNo
        FROM dbo.BakimEmirleri WITH (UPDLOCK, HOLDLOCK)
        WHERE BakimEmriNo = @BakimEmriNo
          AND Durum NOT IN (N'Tamamlandı', N'İptal Edildi');

        IF @@ROWCOUNT = 0
            THROW 50016, N'Aktif bakım emri bulunamadı.', 1;

        UPDATE dbo.BakimGorevlendirmeleri
        SET
            CalismaBaslangici =
                COALESCE(CalismaBaslangici, AtamaZamani),
            CalismaBitisi = SYSDATETIME(),
            YapilanIs = @YapilanIs
        WHERE BakimEmriNo = @BakimEmriNo
          AND CalismaBitisi IS NULL;

        UPDATE dbo.BakimEmirleri
        SET
            Durum = N'Tamamlandı',
            GerceklesenBaslangic =
                COALESCE(GerceklesenBaslangic, OlusturmaZamani),
            TamamlanmaZamani = SYSDATETIME(),
            KontrolEdenKullaniciNo = @KontrolEdenKullaniciNo
        WHERE BakimEmriNo = @BakimEmriNo;

        IF @ArizaNo IS NOT NULL
        BEGIN
            SELECT @AlarmNo = AlarmNo
            FROM dbo.Arizalar
            WHERE ArizaNo = @ArizaNo;

            UPDATE dbo.Arizalar
            SET
                Durum = N'Kapalı',
                KapatanKullaniciNo = @KontrolEdenKullaniciNo,
                KapanisZamani = SYSDATETIME()
            WHERE ArizaNo = @ArizaNo;

            UPDATE dbo.DurusKayitlari
            SET BitisZamani = SYSDATETIME()
            WHERE ArizaNo = @ArizaNo
              AND BitisZamani IS NULL;

            IF @AlarmNo IS NOT NULL
            BEGIN
                UPDATE dbo.Alarmlar
                SET
                    Durum = N'Kapalı',
                    KapanisZamani = SYSDATETIME()
                WHERE AlarmNo = @AlarmNo;
            END;
        END;

        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0
            ROLLBACK TRANSACTION;

        THROW;
    END CATCH
END;
GO

PRINT N'Saklı yordamlar başarıyla oluşturuldu.';
GO