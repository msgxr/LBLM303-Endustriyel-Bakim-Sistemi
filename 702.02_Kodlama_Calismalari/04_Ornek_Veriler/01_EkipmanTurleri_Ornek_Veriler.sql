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

-- Sistemde kullanılacak ekipman türlerini ekler.
INSERT INTO dbo.EkipmanTurleri (TurAdi, Aciklama)
SELECT v.TurAdi, v.Aciklama
FROM
(
    VALUES
    (N'Pompa', N'Sıvı aktarım pompaları'),
    (N'Motor', N'Elektrik motorları'),
    (N'Kompresör', N'Basınçlı hava sistemleri'),
    (N'Jeneratör', N'Elektrik üretim sistemleri'),
    (N'Konveyör', N'Malzeme taşıma sistemleri'),
    (N'Kazan', N'Endüstriyel ısıtma sistemleri'),
    (N'Fan', N'Havalandırma sistemleri'),
    (N'Torna', N'Talaşlı üretim makineleri'),
    (N'Freze', N'Endüstriyel freze makineleri'),
    (N'Robot', N'Endüstriyel üretim robotları')
) v(TurAdi, Aciklama)
WHERE NOT EXISTS
(
    SELECT 1
    FROM dbo.EkipmanTurleri e
    WHERE e.TurAdi = v.TurAdi
);
GO
