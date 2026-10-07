USE EndustriyelBakimDB;
GO

SET NOCOUNT ON;

/* ROLLER */

INSERT INTO dbo.Roller (RolAdi, SqlRolAdi, Aciklama)
SELECT v.RolAdi, v.SqlRolAdi, v.Aciklama
FROM
(
    VALUES
    (N'Yönetici', N'rol_yonetici', N'Sistem yönetimi'),
    (N'Bakım Yöneticisi', N'rol_bakim_yoneticisi', N'Bakım süreçleri yönetimi'),
    (N'Teknisyen', N'rol_teknisyen', N'Bakım işlemleri'),
    (N'Denetçi', N'rol_denetci', N'Denetim kayıtlarını görüntüleme')
) v(RolAdi, SqlRolAdi, Aciklama)
WHERE NOT EXISTS
(
    SELECT 1 FROM dbo.Roller r WHERE r.RolAdi = v.RolAdi
);

/* 20 TEKNİSYEN */

WITH Sayilar AS
(
    SELECT TOP (20)
        ROW_NUMBER() OVER (ORDER BY (SELECT NULL)) AS Sira
    FROM sys.all_objects
)
INSERT INTO dbo.Teknisyenler
(
    SicilNo,
    AdSoyad,
    Uzmanlik,
    SaatlikUcret,
    Durum
)
SELECT
    CONCAT(N'TKN-', RIGHT(N'000' + CAST(Sira AS NVARCHAR(3)), 3)),
    CONCAT(N'Teknisyen ', Sira),
    CASE Sira % 4
        WHEN 0 THEN N'Elektrik'
        WHEN 1 THEN N'Mekanik'
        WHEN 2 THEN N'Otomasyon'
        ELSE N'Elektronik'
    END,
    250 + (Sira * 10),
    N'Aktif'
FROM Sayilar
WHERE NOT EXISTS
(
    SELECT 1
    FROM dbo.Teknisyenler t
    WHERE t.SicilNo =
        CONCAT(N'TKN-', RIGHT(N'000' + CAST(Sira AS NVARCHAR(3)), 3))
);

/* KULLANICILAR */

INSERT INTO dbo.Kullanicilar
(
    TeknisyenNo,
    SqlKullaniciAdi,
    AdSoyad
)
SELECT
    t.TeknisyenNo,
    CONCAT(N'teknisyen_', t.SicilNo),
    t.AdSoyad
FROM dbo.Teknisyenler t
WHERE NOT EXISTS
(
    SELECT 1
    FROM dbo.Kullanicilar k
    WHERE k.TeknisyenNo = t.TeknisyenNo
);

INSERT INTO dbo.Kullanicilar
(
    SqlKullaniciAdi,
    AdSoyad
)
SELECT N'sistem_yoneticisi', N'Sistem Yöneticisi'
WHERE NOT EXISTS
(
    SELECT 1 FROM dbo.Kullanicilar
    WHERE SqlKullaniciAdi = N'sistem_yoneticisi'
);

INSERT INTO dbo.Kullanicilar
(
    SqlKullaniciAdi,
    AdSoyad
)
SELECT N'bakim_yoneticisi', N'Bakım Yöneticisi'
WHERE NOT EXISTS
(
    SELECT 1 FROM dbo.Kullanicilar
    WHERE SqlKullaniciAdi = N'bakim_yoneticisi'
);

INSERT INTO dbo.Kullanicilar
(
    SqlKullaniciAdi,
    AdSoyad
)
SELECT N'denetci', N'Sistem Denetçisi'
WHERE NOT EXISTS
(
    SELECT 1 FROM dbo.Kullanicilar
    WHERE SqlKullaniciAdi = N'denetci'
);

/* KULLANICI ROLLERİ */

INSERT INTO dbo.KullaniciRolleri (KullaniciNo, RolNo)
SELECT
    k.KullaniciNo,
    r.RolNo
FROM dbo.Kullanicilar k
INNER JOIN dbo.Roller r
    ON r.RolAdi =
        CASE
            WHEN k.SqlKullaniciAdi = N'sistem_yoneticisi'
                THEN N'Yönetici'
            WHEN k.SqlKullaniciAdi = N'bakim_yoneticisi'
                THEN N'Bakım Yöneticisi'
            WHEN k.SqlKullaniciAdi = N'denetci'
                THEN N'Denetçi'
            ELSE N'Teknisyen'
        END
WHERE NOT EXISTS
(
    SELECT 1
    FROM dbo.KullaniciRolleri kr
    WHERE kr.KullaniciNo = k.KullaniciNo
      AND kr.RolNo = r.RolNo
);

/* 50 YEDEK PARÇA */

WITH Sayilar AS
(
    SELECT TOP (50)
        ROW_NUMBER() OVER (ORDER BY (SELECT NULL)) AS Sira
    FROM sys.all_objects
)
INSERT INTO dbo.YedekParcalar
(
    ParcaKodu,
    ParcaAdi,
    OlcuBirimi,
    AsgariStok,
    GuncelBirimMaliyet
)
SELECT
    CONCAT(N'PRC-', RIGHT(N'000' + CAST(Sira AS NVARCHAR(3)), 3)),
    CONCAT(N'Yedek Parça ', Sira),
    N'Adet',
    10,
    100 + (Sira * 25)
FROM Sayilar
WHERE NOT EXISTS
(
    SELECT 1
    FROM dbo.YedekParcalar p
    WHERE p.ParcaKodu =
        CONCAT(N'PRC-', RIGHT(N'000' + CAST(Sira AS NVARCHAR(3)), 3))
);

/* 90.000 ÖLÇÜM */

DECLARE @EksikOlcum INT;

SELECT @EksikOlcum =
    CASE
        WHEN COUNT_BIG(*) >= 90000 THEN 0
        ELSE 90000 - CONVERT(INT, COUNT_BIG(*))
    END
FROM dbo.Olcumler;

IF @EksikOlcum > 0
BEGIN
    WITH SensorListesi AS
    (
        SELECT TOP (300)
            SensorNo,
            AltEsik,
            UstEsik,
            ROW_NUMBER() OVER (ORDER BY SensorNo) AS SensorSirasi
        FROM dbo.Sensorler
        ORDER BY SensorNo
    ),
    Sayilar AS
    (
        SELECT TOP (300)
            ROW_NUMBER() OVER (ORDER BY (SELECT NULL)) AS Sira
        FROM sys.all_objects
    )
    INSERT INTO dbo.Olcumler
    (
        SensorNo,
        OlcumDegeri,
        OlcumZamani
    )
    SELECT TOP (@EksikOlcum)
        s.SensorNo,
        CAST
        (
            CASE
                WHEN n.Sira % 45 = 0
                    THEN s.UstEsik + 5 + (n.Sira % 10)
                ELSE
                    s.AltEsik +
                    ((s.UstEsik - s.AltEsik) *
                    (20 + (n.Sira % 60)) / 100.0)
            END
            AS DECIMAL(18,4)
        ),
        DATEADD
        (
            MINUTE,
            -CONVERT(INT, ((300 - n.Sira) * 432) + s.SensorSirasi),
            SYSDATETIME()
        )
    FROM SensorListesi s
    CROSS JOIN Sayilar n
    ORDER BY s.SensorNo, n.Sira;
END;

/* 1.000 ALARM */

DECLARE @EksikAlarm INT =
    CASE
        WHEN (SELECT COUNT(*) FROM dbo.Alarmlar) >= 1000 THEN 0
        ELSE 1000 - (SELECT COUNT(*) FROM dbo.Alarmlar)
    END;

IF @EksikAlarm > 0
BEGIN
    INSERT INTO dbo.Alarmlar
    (
        OlcumNo,
        Seviye,
        Aciklama,
        Durum,
        AcilisZamani
    )
    SELECT TOP (@EksikAlarm)
        o.OlcumNo,
        N'Kritik',
        N'Sensör değeri üst eşik değerini aşmıştır.',
        N'Açık',
        o.OlcumZamani
    FROM dbo.Olcumler o
    INNER JOIN dbo.Sensorler s
        ON s.SensorNo = o.SensorNo
    WHERE o.OlcumDegeri > s.UstEsik
      AND NOT EXISTS
      (
          SELECT 1 FROM dbo.Alarmlar a
          WHERE a.OlcumNo = o.OlcumNo
      )
    ORDER BY o.OlcumZamani;
END;

/* 500 ARIZA */

DECLARE @EksikAriza INT =
    CASE
        WHEN (SELECT COUNT(*) FROM dbo.Arizalar) >= 500 THEN 0
        ELSE 500 - (SELECT COUNT(*) FROM dbo.Arizalar)
    END;

IF @EksikAriza > 0
BEGIN
    INSERT INTO dbo.Arizalar
    (
        EkipmanNo,
        AlarmNo,
        ArizaAciklamasi,
        ArizaNedeni,
        Oncelik,
        Durum,
        AcilisZamani
    )
    SELECT TOP (@EksikAriza)
        s.EkipmanNo,
        a.AlarmNo,
        N'Kritik sensör alarmı sonucunda arıza oluşturuldu.',
        N'Ölçüm değerinin güvenli çalışma sınırını aşması',
        N'Yüksek',
        N'Açık',
        a.AcilisZamani
    FROM dbo.Alarmlar a
    INNER JOIN dbo.Olcumler o
        ON o.OlcumNo = a.OlcumNo
    INNER JOIN dbo.Sensorler s
        ON s.SensorNo = o.SensorNo
    WHERE NOT EXISTS
    (
        SELECT 1 FROM dbo.Arizalar x
        WHERE x.AlarmNo = a.AlarmNo
    )
    ORDER BY a.AlarmNo;
END;

/* 500 DÜZELTİCİ BAKIM EMRİ */

INSERT INTO dbo.BakimEmirleri
(
    EkipmanNo,
    ArizaNo,
    BakimTuru,
    Aciklama,
    Oncelik,
    Durum
)
SELECT
    a.EkipmanNo,
    a.ArizaNo,
    N'Düzeltici',
    N'Arızanın giderilmesi için oluşturulan bakım emri.',
    a.Oncelik,
    N'Bekliyor'
FROM dbo.Arizalar a
WHERE NOT EXISTS
(
    SELECT 1
    FROM dbo.BakimEmirleri b
    WHERE b.ArizaNo = a.ArizaNo
);

/* 200 PLANLI BAKIM EMRİ */

WITH Sayilar AS
(
    SELECT 1 AS Sira
    UNION ALL
    SELECT 2
),
Adaylar AS
(
    SELECT
        e.EkipmanNo,
        ROW_NUMBER() OVER (ORDER BY e.EkipmanNo, s.Sira) AS Sira
    FROM
    (
        SELECT TOP (100) EkipmanNo
        FROM dbo.Ekipmanlar
        ORDER BY EkipmanNo
    ) e
    CROSS JOIN Sayilar s
)
INSERT INTO dbo.BakimEmirleri
(
    EkipmanNo,
    BakimTuru,
    Aciklama,
    Oncelik,
    Durum
)
SELECT
    EkipmanNo,
    N'Planlı',
    CONCAT(N'Planlı bakım çalışması ', Sira),
    N'Orta',
    N'Bekliyor'
FROM Adaylar a
WHERE NOT EXISTS
(
    SELECT 1
    FROM dbo.BakimEmirleri b
    WHERE b.ArizaNo IS NULL
      AND b.Aciklama = CONCAT(N'Planlı bakım çalışması ', a.Sira)
);

/* TEKNİSYEN GÖREVLENDİRMELERİ */

WITH Emirler AS
(
    SELECT TOP (700)
        BakimEmriNo,
        ROW_NUMBER() OVER (ORDER BY BakimEmriNo) AS Sira
    FROM dbo.BakimEmirleri
    ORDER BY BakimEmriNo
),
TeknisyenListesi AS
(
    SELECT
        TeknisyenNo,
        SaatlikUcret,
        ROW_NUMBER() OVER (ORDER BY TeknisyenNo) AS Sira,
        COUNT(*) OVER () AS Toplam
    FROM dbo.Teknisyenler
)
INSERT INTO dbo.BakimGorevlendirmeleri
(
    BakimEmriNo,
    TeknisyenNo,
    IslemAnindakiSaatlikUcret
)
SELECT
    e.BakimEmriNo,
    t.TeknisyenNo,
    t.SaatlikUcret
FROM Emirler e
INNER JOIN TeknisyenListesi t
    ON t.Sira = ((e.Sira - 1) % t.Toplam) + 1
WHERE NOT EXISTS
(
    SELECT 1
    FROM dbo.BakimGorevlendirmeleri g
    WHERE g.BakimEmriNo = e.BakimEmriNo
);

/* 300 DURUŞ KAYDI */

INSERT INTO dbo.DurusKayitlari
(
    EkipmanNo,
    ArizaNo,
    BaslangicZamani,
    BitisZamani,
    DurusNedeni
)
SELECT TOP (300)
    a.EkipmanNo,
    a.ArizaNo,
    a.AcilisZamani,
    DATEADD(HOUR, 2 + (a.ArizaNo % 24), a.AcilisZamani),
    N'Arıza nedeniyle ekipman duruşu'
FROM dbo.Arizalar a
WHERE NOT EXISTS
(
    SELECT 1
    FROM dbo.DurusKayitlari d
    WHERE d.ArizaNo = a.ArizaNo
)
ORDER BY a.ArizaNo;

PRINT N'Toplu örnek veri üretimi tamamlandı.';
PRINT N'Hedef: 100 ekipman, 300 sensör ve 90.000 ölçüm.';
GO
/* BAŞLANGIÇ STOKLARI */

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
    p.ParcaNo,
    N'Giriş',
    500,
    p.GuncelBirimMaliyet,
    (SELECT TOP (1) KullaniciNo
     FROM dbo.Kullanicilar
     WHERE Aktif = 1
     ORDER BY KullaniciNo),
    N'Başlangıç stok kaydı'
FROM dbo.YedekParcalar p
WHERE NOT EXISTS
(
    SELECT 1
    FROM dbo.StokHareketleri h
    WHERE h.ParcaNo = p.ParcaNo
      AND h.Aciklama = N'Başlangıç stok kaydı'
);
GO

/* 600 BAKIM PARÇASI KULLANIMI */

WITH Emirler AS
(
    SELECT TOP (600)
        BakimEmriNo,
        ROW_NUMBER() OVER (ORDER BY BakimEmriNo) AS Sira
    FROM dbo.BakimEmirleri
    ORDER BY BakimEmriNo
),
Parcalar AS
(
    SELECT
        ParcaNo,
        GuncelBirimMaliyet,
        ROW_NUMBER() OVER (ORDER BY ParcaNo) AS Sira,
        COUNT(*) OVER () AS Toplam
    FROM dbo.YedekParcalar
)
INSERT INTO dbo.BakimParcalari
(
    BakimEmriNo,
    ParcaNo,
    IslemTuru,
    Miktar,
    IslemAnindakiBirimMaliyet,
    KullaniciNo
)
SELECT
    e.BakimEmriNo,
    p.ParcaNo,
    N'Kullanım',
    1 + (e.Sira % 5),
    p.GuncelBirimMaliyet,
    (SELECT TOP (1) KullaniciNo
     FROM dbo.Kullanicilar
     WHERE Aktif = 1
     ORDER BY KullaniciNo)
FROM Emirler e
INNER JOIN Parcalar p
    ON p.Sira = ((e.Sira - 1) % p.Toplam) + 1
WHERE NOT EXISTS
(
    SELECT 1
    FROM dbo.BakimParcalari bp
    WHERE bp.BakimEmriNo = e.BakimEmriNo
);
GO

/* PARÇA KULLANIMLARINI STOK HAREKETİNE DÖNÜŞTÜRÜR */

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
SELECT
    bp.ParcaNo,
    bp.BakimParcaNo,
    N'Kullanım',
    bp.Miktar,
    bp.IslemAnindakiBirimMaliyet,
    bp.KullaniciNo,
    N'Örnek bakım parçası kullanımı'
FROM dbo.BakimParcalari bp
WHERE NOT EXISTS
(
    SELECT 1
    FROM dbo.StokHareketleri h
    WHERE h.BakimParcaNo = bp.BakimParcaNo
);
GO

/* ARIZA ALARMLARINI İNCELENMİŞ DURUMA GETİRİR */

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

/* 300 TAMAMLANMIŞ BAKIM VE ARIZA KAYDI */

WITH Tamamlanacaklar AS
(
    SELECT TOP (300) BakimEmriNo
    FROM dbo.BakimEmirleri
    WHERE ArizaNo IS NOT NULL
    ORDER BY BakimEmriNo
)
UPDATE b
SET
    Durum = N'Tamamlandı',
    GerceklesenBaslangic = DATEADD(MINUTE, 15, b.OlusturmaZamani),
    TamamlanmaZamani = DATEADD(HOUR, 2, b.OlusturmaZamani)
FROM dbo.BakimEmirleri b
INNER JOIN Tamamlanacaklar t
    ON t.BakimEmriNo = b.BakimEmriNo;
GO

UPDATE g
SET
    CalismaBaslangici = g.AtamaZamani,
    CalismaBitisi = DATEADD(HOUR, 2, g.AtamaZamani),
    YapilanIs = N'Örnek bakım işlemi tamamlandı.'
FROM dbo.BakimGorevlendirmeleri g
INNER JOIN dbo.BakimEmirleri b
    ON b.BakimEmriNo = g.BakimEmriNo
WHERE b.Durum = N'Tamamlandı';
GO

UPDATE ar
SET
    Durum = N'Kapalı',
    KapanisZamani = b.TamamlanmaZamani
FROM dbo.Arizalar ar
INNER JOIN dbo.BakimEmirleri b
    ON b.ArizaNo = ar.ArizaNo
WHERE b.Durum = N'Tamamlandı';
GO

UPDATE a
SET
    Durum = N'Kapalı',
    KapanisZamani = ar.KapanisZamani
FROM dbo.Alarmlar a
INNER JOIN dbo.Arizalar ar
    ON ar.AlarmNo = a.AlarmNo
WHERE ar.Durum = N'Kapalı';
GO

PRINT N'Yaklaşık 95.000 örnek kayıt hazırlandı.';
GO
