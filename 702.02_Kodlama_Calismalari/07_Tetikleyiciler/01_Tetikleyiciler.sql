USE EndustriyelBakimDB;
GO

/* Örnek arıza verilerinin alarm inceleme bilgilerini tamamlar. */

UPDATE a
SET
    Durum = N'İncelendi',
    InceleyenKullaniciNo =
    (
        SELECT TOP (1) KullaniciNo
        FROM dbo.Kullanicilar
        WHERE Aktif = 1
        ORDER BY KullaniciNo
    ),
    IncelemeZamani = DATEADD(MINUTE, 5, a.AcilisZamani),
    IncelemeSonucu = N'Alarm incelendi ve arıza doğrulandı.'
FROM dbo.Alarmlar a
WHERE EXISTS
(
    SELECT 1
    FROM dbo.Arizalar ar
    WHERE ar.AlarmNo = a.AlarmNo
)
AND a.IncelemeZamani IS NULL;
GO

/* =========================================================
   1. ÖLÇÜM SONUCUNDA OTOMATİK ALARM
   Eşik dışındaki ölçüm için otomatik alarm oluşturur.
   Aynı sensörde açık alarm varsa ikinci alarmı oluşturmaz.
   ========================================================= */

CREATE OR ALTER TRIGGER dbo.trg_Olcumler_AlarmOlustur
ON dbo.Olcumler
AFTER INSERT
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @SensorKilidi INT;

    SELECT @SensorKilidi = MAX(s.SensorNo)
    FROM dbo.Sensorler s WITH (UPDLOCK, HOLDLOCK)
    INNER JOIN inserted i
        ON i.SensorNo = s.SensorNo;

    ;WITH AdayOlcumler AS
    (
        SELECT
            i.OlcumNo,
            i.SensorNo,
            i.OlcumDegeri,
            i.OlcumZamani,
            s.AltEsik,
            s.UstEsik,
            ROW_NUMBER() OVER
            (
                PARTITION BY i.SensorNo
                ORDER BY i.OlcumZamani DESC, i.OlcumNo DESC
            ) AS Sira
        FROM inserted i
        INNER JOIN dbo.Sensorler s
            ON s.SensorNo = i.SensorNo
        WHERE i.OlcumDegeri < s.AltEsik
           OR i.OlcumDegeri > s.UstEsik
    )
    INSERT INTO dbo.Alarmlar
    (
        OlcumNo,
        Seviye,
        Aciklama,
        Durum,
        AcilisZamani
    )
    SELECT
        a.OlcumNo,
        CASE
            WHEN a.OlcumDegeri >
                 a.UstEsik + ((a.UstEsik - a.AltEsik) * 0.10)
              OR a.OlcumDegeri <
                 a.AltEsik - ((a.UstEsik - a.AltEsik) * 0.10)
                THEN N'Kritik'
            ELSE N'Uyarı'
        END,
        N'Sensör ölçümü belirlenen eşik değerlerinin dışına çıkmıştır.',
        N'Açık',
        a.OlcumZamani
    FROM AdayOlcumler a
    WHERE a.Sira = 1
      AND NOT EXISTS
      (
          SELECT 1
          FROM dbo.Alarmlar al WITH (UPDLOCK, HOLDLOCK)
          INNER JOIN dbo.Olcumler o
              ON o.OlcumNo = al.OlcumNo
          WHERE o.SensorNo = a.SensorNo
            AND al.Durum IN (N'Açık', N'İncelendi')
      );
END;
GO

/* =========================================================
   2. ARIZA OLUŞTURMA KONTROLÜ
   Alarm incelenmeden arıza oluşturulmasını engeller.
   ========================================================= */

CREATE OR ALTER TRIGGER dbo.trg_Arizalar_AlarmKontrol
ON dbo.Arizalar
AFTER INSERT, UPDATE
AS
BEGIN
    SET NOCOUNT ON;

    IF EXISTS
    (
        SELECT 1
        FROM inserted i
        INNER JOIN dbo.Alarmlar a
            ON a.AlarmNo = i.AlarmNo
        WHERE i.AlarmNo IS NOT NULL
          AND a.IncelemeZamani IS NULL
    )
    BEGIN
        ;;THROW 51001, N'Alarm incelenmeden arıza oluşturulamaz.', 1;
    END;
END;
GO

/* =========================================================
   3. BAKIM EMRİ KONTROLÜ
   Aynı arızaya birden fazla aktif düzeltici bakım açılmasını engeller.
   ========================================================= */

CREATE OR ALTER TRIGGER dbo.trg_BakimEmirleri_AktifEmirKontrol
ON dbo.BakimEmirleri
AFTER INSERT, UPDATE
AS
BEGIN
    SET NOCOUNT ON;

    IF EXISTS
    (
        SELECT 1
        FROM inserted i
        INNER JOIN dbo.Arizalar a
            ON a.ArizaNo = i.ArizaNo
        WHERE i.ArizaNo IS NOT NULL
          AND i.EkipmanNo <> a.EkipmanNo
    )
    BEGIN
        ;;THROW 51002, N'Arıza ve bakım emri aynı ekipmana ait olmalıdır.', 1;
    END;

    IF EXISTS
    (
        SELECT 1
        FROM inserted i
        INNER JOIN dbo.BakimEmirleri b
            ON b.ArizaNo = i.ArizaNo
           AND b.BakimEmriNo <> i.BakimEmriNo
        WHERE i.ArizaNo IS NOT NULL
          AND i.BakimTuru = N'Düzeltici'
          AND b.BakimTuru = N'Düzeltici'
          AND i.Durum NOT IN (N'Tamamlandı', N'İptal Edildi')
          AND b.Durum NOT IN (N'Tamamlandı', N'İptal Edildi')
    )
    BEGIN
        ;;THROW 51003, N'Arıza için aktif düzeltici bakım emri bulunmaktadır.', 1;
    END;
END;
GO

/* =========================================================
   4. NEGATİF STOK KONTROLÜ
   Stok miktarının sıfırın altına düşmesini engeller.
   ========================================================= */

CREATE OR ALTER TRIGGER dbo.trg_StokHareketleri_NegatifStokKontrol
ON dbo.StokHareketleri
AFTER INSERT, UPDATE, DELETE
AS
BEGIN
    SET NOCOUNT ON;

    ;WITH EtkilenenParcalar AS
    (
        SELECT ParcaNo FROM inserted
        UNION
        SELECT ParcaNo FROM deleted
    ),
    Stoklar AS
    (
        SELECT
            e.ParcaNo,
            COALESCE
            (
                SUM
                (
                    CASE
                        WHEN h.HareketTuru IN (N'Giriş', N'İade')
                            THEN h.Miktar
                        WHEN h.HareketTuru IN (N'Çıkış', N'Kullanım')
                            THEN -h.Miktar
                        ELSE 0
                    END
                ),
                0
            ) AS MevcutStok
        FROM EtkilenenParcalar e
        LEFT JOIN dbo.StokHareketleri h
            ON h.ParcaNo = e.ParcaNo
        GROUP BY e.ParcaNo
    )
    SELECT *
    INTO #NegatifStok
    FROM Stoklar
    WHERE MevcutStok < 0;

    IF EXISTS (SELECT 1 FROM #NegatifStok)
    BEGIN
        ;;THROW 51004, N'Stok miktarı sıfırın altına düşemez.', 1;
    END;
END;
GO

/* =========================================================
   5. BAKIM EMRİ DENETİM KAYDI
   Ekleme, güncelleme ve silme işlemlerini kaydeder.
   ========================================================= */

CREATE OR ALTER TRIGGER dbo.trg_BakimEmirleri_Denetim
ON dbo.BakimEmirleri
AFTER INSERT, UPDATE, DELETE
AS
BEGIN
    SET NOCOUNT ON;

    INSERT INTO dbo.DenetimKayitlari
    (
        KullaniciNo,
        OturumKullaniciAdi,
        TabloAdi,
        KayitAnahtari,
        IslemTuru,
        EskiDegerler,
        YeniDegerler
    )
    SELECT
        (
            SELECT TOP (1) KullaniciNo
            FROM dbo.Kullanicilar
            WHERE SqlKullaniciAdi IN
                  (SUSER_SNAME(), ORIGINAL_LOGIN())
        ),
        ORIGINAL_LOGIN(),
        N'BakimEmirleri',
        CAST(COALESCE(i.BakimEmriNo, d.BakimEmriNo) AS NVARCHAR(250)),
        CASE
            WHEN d.BakimEmriNo IS NULL THEN N'INSERT'
            WHEN i.BakimEmriNo IS NULL THEN N'DELETE'
            ELSE N'UPDATE'
        END,
        CASE WHEN d.BakimEmriNo IS NULL THEN NULL ELSE
        (
            SELECT
                d.BakimEmriNo,
                d.EkipmanNo,
                d.ArizaNo,
                d.BakimTuru,
                d.Oncelik,
                d.Durum
            FOR JSON PATH, WITHOUT_ARRAY_WRAPPER
        ) END,
        CASE WHEN i.BakimEmriNo IS NULL THEN NULL ELSE
        (
            SELECT
                i.BakimEmriNo,
                i.EkipmanNo,
                i.ArizaNo,
                i.BakimTuru,
                i.Oncelik,
                i.Durum
            FOR JSON PATH, WITHOUT_ARRAY_WRAPPER
        ) END
    FROM inserted i
    FULL OUTER JOIN deleted d
        ON d.BakimEmriNo = i.BakimEmriNo;
END;
GO

/* =========================================================
   6. STOK DENETİM KAYDI
   Bütün stok hareketlerini denetim tablosuna kaydeder.
   ========================================================= */

CREATE OR ALTER TRIGGER dbo.trg_StokHareketleri_Denetim
ON dbo.StokHareketleri
AFTER INSERT, UPDATE, DELETE
AS
BEGIN
    SET NOCOUNT ON;

    INSERT INTO dbo.DenetimKayitlari
    (
        KullaniciNo,
        OturumKullaniciAdi,
        TabloAdi,
        KayitAnahtari,
        IslemTuru,
        EskiDegerler,
        YeniDegerler
    )
    SELECT
        (
            SELECT TOP (1) KullaniciNo
            FROM dbo.Kullanicilar
            WHERE SqlKullaniciAdi IN
                  (SUSER_SNAME(), ORIGINAL_LOGIN())
        ),
        ORIGINAL_LOGIN(),
        N'StokHareketleri',
        CAST
        (
            COALESCE(i.StokHareketNo, d.StokHareketNo)
            AS NVARCHAR(250)
        ),
        CASE
            WHEN d.StokHareketNo IS NULL THEN N'INSERT'
            WHEN i.StokHareketNo IS NULL THEN N'DELETE'
            ELSE N'UPDATE'
        END,
        CASE WHEN d.StokHareketNo IS NULL THEN NULL ELSE
        (
            SELECT
                d.StokHareketNo,
                d.ParcaNo,
                d.HareketTuru,
                d.Miktar,
                d.BirimMaliyet
            FOR JSON PATH, WITHOUT_ARRAY_WRAPPER
        ) END,
        CASE WHEN i.StokHareketNo IS NULL THEN NULL ELSE
        (
            SELECT
                i.StokHareketNo,
                i.ParcaNo,
                i.HareketTuru,
                i.Miktar,
                i.BirimMaliyet
            FOR JSON PATH, WITHOUT_ARRAY_WRAPPER
        ) END
    FROM inserted i
    FULL OUTER JOIN deleted d
        ON d.StokHareketNo = i.StokHareketNo;
END;
GO

/* =========================================================
   7. DENETİM KAYITLARINI KORUMA
   Denetim kayıtlarının değiştirilmesini veya silinmesini engeller.
   ========================================================= */

CREATE OR ALTER TRIGGER dbo.trg_DenetimKayitlari_Koruma
ON dbo.DenetimKayitlari
INSTEAD OF UPDATE, DELETE
AS
BEGIN
    SET NOCOUNT ON;

    ;;THROW 51005, N'Denetim kayıtları değiştirilemez veya silinemez.', 1;
END;
GO

PRINT N'Tetikleyiciler başarıyla oluşturuldu.';
GO