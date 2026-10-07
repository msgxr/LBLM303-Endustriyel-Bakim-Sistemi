USE EndustriyelBakimDB;
GO

-- Her ekipmana üç sensör ekler: sıcaklık, titreşim ve basınç.
WITH SecilenEkipmanlar AS
(
    SELECT TOP (100)
        EkipmanNo,
        EkipmanKodu,
        KurulumTarihi
    FROM dbo.Ekipmanlar
    ORDER BY EkipmanNo
)
INSERT INTO dbo.Sensorler
(
    EkipmanNo,
    SensorKodu,
    SensorTuru,
    OlcumBirimi,
    AltEsik,
    UstEsik,
    KurulumTarihi,
    Durum
)
SELECT
    e.EkipmanNo,
    CONCAT(N'SNS-', e.EkipmanKodu, N'-', s.Sira),
    s.SensorTuru,
    s.OlcumBirimi,
    s.AltEsik,
    s.UstEsik,
    DATEADD(DAY, 30, e.KurulumTarihi),
    N'Aktif'
FROM SecilenEkipmanlar e
CROSS JOIN
(
    VALUES
    (1, N'Sıcaklık', N'°C', 0.0000, 80.0000),
    (2, N'Titreşim', N'mm/s', 0.0000, 12.0000),
    (3, N'Basınç', N'bar', 0.0000, 10.0000)
) s(Sira, SensorTuru, OlcumBirimi, AltEsik, UstEsik)
WHERE NOT EXISTS
(
    SELECT 1
    FROM dbo.Sensorler x
    WHERE x.SensorKodu =
        CONCAT(N'SNS-', e.EkipmanKodu, N'-', s.Sira)
);
GO