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

-- Otomatik olarak 100 ekipman oluşturur.
WITH Sayilar AS
(
    SELECT TOP (100)
        ROW_NUMBER() OVER (ORDER BY (SELECT NULL)) AS Sira
    FROM sys.all_objects
),
Turler AS
(
    SELECT
        TurNo,
        TurAdi,
        ROW_NUMBER() OVER (ORDER BY TurNo) AS TurSirasi,
        COUNT(*) OVER () AS TurSayisi
    FROM dbo.EkipmanTurleri
)
INSERT INTO dbo.Ekipmanlar
(
    TurNo,
    EkipmanKodu,
    EkipmanAdi,
    Konum,
    KurulumTarihi,
    Durum
)
SELECT
    t.TurNo,
    CONCAT(N'EKP-', RIGHT(N'000' + CAST(s.Sira AS NVARCHAR(3)), 3)),
    CONCAT(t.TurAdi, N' ', s.Sira),
    CONCAT(N'Üretim Bölgesi ', ((s.Sira - 1) % 10) + 1),
    DATEADD(DAY, -(s.Sira * 20), CAST(GETDATE() AS DATE)),
    CASE
        WHEN s.Sira % 20 = 0 THEN N'Bakımda'
        WHEN s.Sira % 25 = 0 THEN N'Pasif'
        ELSE N'Aktif'
    END
FROM Sayilar s
INNER JOIN Turler t
    ON t.TurSirasi = ((s.Sira - 1) % t.TurSayisi) + 1
WHERE NOT EXISTS
(
    SELECT 1
    FROM dbo.Ekipmanlar e
    WHERE e.EkipmanKodu =
        CONCAT(N'EKP-', RIGHT(N'000' + CAST(s.Sira AS NVARCHAR(3)), 3))
);
GO
