USE EndustriyelBakimDB;
GO

/* KAYIT SAYILARI */

SELECT N'Ekipman türü' AS Kontrol, COUNT(*) AS KayitSayisi
FROM dbo.EkipmanTurleri
UNION ALL
SELECT N'Ekipman', COUNT(*) FROM dbo.Ekipmanlar
UNION ALL
SELECT N'Sensör', COUNT(*) FROM dbo.Sensorler
UNION ALL
SELECT N'Ölçüm', COUNT(*) FROM dbo.Olcumler
UNION ALL
SELECT N'Alarm', COUNT(*) FROM dbo.Alarmlar
UNION ALL
SELECT N'Arıza', COUNT(*) FROM dbo.Arizalar
UNION ALL
SELECT N'Bakım emri', COUNT(*) FROM dbo.BakimEmirleri;
GO

/* HEDEF VERİ KONTROLÜ */

SELECT
    CASE
        WHEN (SELECT COUNT(*) FROM dbo.Ekipmanlar) >= 100
        THEN N'BAŞARILI'
        ELSE N'BAŞARISIZ'
    END AS EkipmanKontrolu,

    CASE
        WHEN (SELECT COUNT(*) FROM dbo.Sensorler) >= 300
        THEN N'BAŞARILI'
        ELSE N'BAŞARISIZ'
    END AS SensorKontrolu,

    CASE
        WHEN (SELECT COUNT_BIG(*) FROM dbo.Olcumler) >= 90000
        THEN N'BAŞARILI'
        ELSE N'BAŞARISIZ'
    END AS OlcumKontrolu;
GO

/* BAĞLANTISIZ KAYIT KONTROLÜ */

SELECT N'Ekipmansız sensör' AS HataTuru, COUNT(*) AS HataSayisi
FROM dbo.Sensorler s
LEFT JOIN dbo.Ekipmanlar e ON e.EkipmanNo = s.EkipmanNo
WHERE e.EkipmanNo IS NULL

UNION ALL

SELECT N'Sensörsüz ölçüm', COUNT(*)
FROM dbo.Olcumler o
LEFT JOIN dbo.Sensorler s ON s.SensorNo = o.SensorNo
WHERE s.SensorNo IS NULL

UNION ALL

SELECT N'Ölçümsüz alarm', COUNT(*)
FROM dbo.Alarmlar a
LEFT JOIN dbo.Olcumler o ON o.OlcumNo = a.OlcumNo
WHERE o.OlcumNo IS NULL

UNION ALL

SELECT N'Ekipmansız arıza', COUNT(*)
FROM dbo.Arizalar a
LEFT JOIN dbo.Ekipmanlar e ON e.EkipmanNo = a.EkipmanNo
WHERE e.EkipmanNo IS NULL;
GO

/* TEKRARLANAN KOD KONTROLÜ */

SELECT EkipmanKodu, COUNT(*) AS TekrarSayisi
FROM dbo.Ekipmanlar
GROUP BY EkipmanKodu
HAVING COUNT(*) > 1;

SELECT SensorKodu, COUNT(*) AS TekrarSayisi
FROM dbo.Sensorler
GROUP BY SensorKodu
HAVING COUNT(*) > 1;
GO