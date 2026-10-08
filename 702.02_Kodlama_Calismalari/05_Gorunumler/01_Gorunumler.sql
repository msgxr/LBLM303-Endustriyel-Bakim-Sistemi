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

/* =========================================================
   1. GÜNCEL ALARMLAR
   Alarmın hangi sensör ve ekipmandan geldiğini gösterir.
   ========================================================= */

CREATE OR ALTER VIEW dbo.vw_GuncelAlarmlar
AS
SELECT
    a.AlarmNo,
    e.EkipmanNo,
    e.EkipmanKodu,
    e.EkipmanAdi,
    s.SensorNo,
    s.SensorKodu,
    s.SensorTuru,
    o.OlcumDegeri,
    s.OlcumBirimi,
    s.AltEsik,
    s.UstEsik,
    a.Seviye,
    a.Durum,
    a.AcilisZamani,
    a.KapanisZamani
FROM dbo.Alarmlar a
INNER JOIN dbo.Olcumler o
    ON o.OlcumNo = a.OlcumNo
INNER JOIN dbo.Sensorler s
    ON s.SensorNo = o.SensorNo
INNER JOIN dbo.Ekipmanlar e
    ON e.EkipmanNo = s.EkipmanNo;
GO

/* =========================================================
   2. AKTİF BAKIM EMİRLERİ
   Tamamlanmamış ve iptal edilmemiş işleri gösterir.
   ========================================================= */

CREATE OR ALTER VIEW dbo.vw_AktifBakimEmirleri
AS
SELECT
    b.BakimEmriNo,
    e.EkipmanKodu,
    e.EkipmanAdi,
    b.ArizaNo,
    b.BakimTuru,
    b.Aciklama,
    b.Oncelik,
    b.Durum,
    b.OlusturmaZamani,
    b.PlanlananBaslangic,
    t.TeknisyenNo,
    t.SicilNo,
    t.AdSoyad AS TeknisyenAdi
FROM dbo.BakimEmirleri b
INNER JOIN dbo.Ekipmanlar e
    ON e.EkipmanNo = b.EkipmanNo
LEFT JOIN dbo.BakimGorevlendirmeleri g
    ON g.BakimEmriNo = b.BakimEmriNo
LEFT JOIN dbo.Teknisyenler t
    ON t.TeknisyenNo = g.TeknisyenNo
WHERE b.Durum NOT IN (N'Tamamlandı', N'İptal Edildi');
GO

/* =========================================================
   3. STOK DURUMU
   Giriş ve çıkış hareketlerinden mevcut stoğu hesaplar.
   ========================================================= */

CREATE OR ALTER VIEW dbo.vw_StokDurumu
AS
SELECT
    p.ParcaNo,
    p.ParcaKodu,
    p.ParcaAdi,
    p.OlcuBirimi,
    p.AsgariStok,
    p.GuncelBirimMaliyet,
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
    ) AS MevcutStok,
    CASE
        WHEN COALESCE
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
        ) <= p.AsgariStok
            THEN N'Kritik'
        ELSE N'Yeterli'
    END AS StokDurumu
FROM dbo.YedekParcalar p
LEFT JOIN dbo.StokHareketleri h
    ON h.ParcaNo = p.ParcaNo
GROUP BY
    p.ParcaNo,
    p.ParcaKodu,
    p.ParcaAdi,
    p.OlcuBirimi,
    p.AsgariStok,
    p.GuncelBirimMaliyet;
GO

/* =========================================================
   4. BAKIM MALİYETLERİ
   İşçilik ve parça maliyetlerini ayrı hesaplayıp toplar.
   ========================================================= */

CREATE OR ALTER VIEW dbo.vw_BakimMaliyetleri
AS
WITH Iscilik AS
(
    SELECT
        BakimEmriNo,
        SUM
        (
            CASE
                WHEN CalismaBaslangici IS NOT NULL
                 AND CalismaBitisi IS NOT NULL
                THEN
                    DATEDIFF
                    (
                        MINUTE,
                        CalismaBaslangici,
                        CalismaBitisi
                    ) / 60.0 * IslemAnindakiSaatlikUcret
                ELSE 0
            END
        ) AS IscilikMaliyeti
    FROM dbo.BakimGorevlendirmeleri
    GROUP BY BakimEmriNo
),
Parca AS
(
    SELECT
        BakimEmriNo,
        SUM
        (
            CASE
                WHEN IslemTuru = N'Kullanım'
                    THEN Miktar * IslemAnindakiBirimMaliyet
                WHEN IslemTuru = N'İade'
                    THEN -(Miktar * IslemAnindakiBirimMaliyet)
                ELSE 0
            END
        ) AS ParcaMaliyeti
    FROM dbo.BakimParcalari
    GROUP BY BakimEmriNo
)
SELECT
    b.BakimEmriNo,
    e.EkipmanKodu,
    e.EkipmanAdi,
    b.BakimTuru,
    b.Durum,
    COALESCE(i.IscilikMaliyeti, 0) AS IscilikMaliyeti,
    COALESCE(p.ParcaMaliyeti, 0) AS ParcaMaliyeti,
    COALESCE(i.IscilikMaliyeti, 0) +
    COALESCE(p.ParcaMaliyeti, 0) AS ToplamMaliyet
FROM dbo.BakimEmirleri b
INNER JOIN dbo.Ekipmanlar e
    ON e.EkipmanNo = b.EkipmanNo
LEFT JOIN Iscilik i
    ON i.BakimEmriNo = b.BakimEmriNo
LEFT JOIN Parca p
    ON p.BakimEmriNo = b.BakimEmriNo;
GO

/* =========================================================
   5. EKİPMAN MTBF VE MTTR RAPORU
   Arızalar arasındaki ve onarımda geçen süreyi hesaplar.
   ========================================================= */

CREATE OR ALTER VIEW dbo.vw_EkipmanMTBF_MTTR
AS
WITH ArizaSirasi AS
(
    SELECT
        ArizaNo,
        EkipmanNo,
        AcilisZamani,
        KapanisZamani,
        LAG(AcilisZamani) OVER
        (
            PARTITION BY EkipmanNo
            ORDER BY AcilisZamani
        ) AS OncekiArizaZamani
    FROM dbo.Arizalar
)
SELECT
    e.EkipmanNo,
    e.EkipmanKodu,
    e.EkipmanAdi,
    COUNT(a.ArizaNo) AS ToplamArizaSayisi,
    CAST
    (
        AVG
        (
            CASE
                WHEN a.OncekiArizaZamani IS NOT NULL
                THEN DATEDIFF
                (
                    MINUTE,
                    a.OncekiArizaZamani,
                    a.AcilisZamani
                ) / 60.0
            END
        )
        AS DECIMAL(18,2)
    ) AS MTBF_Saat,
    CAST
    (
        AVG
        (
            CASE
                WHEN a.KapanisZamani IS NOT NULL
                THEN DATEDIFF
                (
                    MINUTE,
                    a.AcilisZamani,
                    a.KapanisZamani
                ) / 60.0
            END
        )
        AS DECIMAL(18,2)
    ) AS MTTR_Saat
FROM dbo.Ekipmanlar e
LEFT JOIN ArizaSirasi a
    ON a.EkipmanNo = e.EkipmanNo
GROUP BY
    e.EkipmanNo,
    e.EkipmanKodu,
    e.EkipmanAdi;
GO

/* =========================================================
   6. EKİPMAN ÖZETİ
   Her ekipmanın sensör, alarm, arıza ve bakım sayılarını verir.
   ========================================================= */

CREATE OR ALTER VIEW dbo.vw_EkipmanOzeti
AS
SELECT
    e.EkipmanNo,
    e.EkipmanKodu,
    e.EkipmanAdi,
    e.Konum,
    e.Durum,
    (SELECT COUNT(*)
     FROM dbo.Sensorler s
     WHERE s.EkipmanNo = e.EkipmanNo) AS SensorSayisi,

    (SELECT COUNT(*)
     FROM dbo.Alarmlar a
     INNER JOIN dbo.Olcumler o ON o.OlcumNo = a.OlcumNo
     INNER JOIN dbo.Sensorler s ON s.SensorNo = o.SensorNo
     WHERE s.EkipmanNo = e.EkipmanNo) AS AlarmSayisi,

    (SELECT COUNT(*)
     FROM dbo.Arizalar ar
     WHERE ar.EkipmanNo = e.EkipmanNo) AS ArizaSayisi,

    (SELECT COUNT(*)
     FROM dbo.BakimEmirleri b
     WHERE b.EkipmanNo = e.EkipmanNo) AS BakimEmriSayisi
FROM dbo.Ekipmanlar e;
GO

PRINT N'Görünümler başarıyla oluşturuldu.';
GO
