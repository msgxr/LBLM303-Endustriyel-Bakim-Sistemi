USE EndustriyelBakimDB;
GO

/* EKİPMAN BAZINDA MTBF VE MTTR */

SELECT
    EkipmanKodu,
    EkipmanAdi,
    ToplamArizaSayisi,
    MTBF_Saat,
    MTTR_Saat
FROM dbo.vw_EkipmanMTBF_MTTR
ORDER BY ToplamArizaSayisi DESC;
GO

/* EKİPMAN TÜRÜ BAZINDA ORTALAMA MTBF VE MTTR */

SELECT
    et.TurAdi,
    COUNT(e.EkipmanNo) AS EkipmanSayisi,
    CAST(AVG(r.MTBF_Saat) AS DECIMAL(18,2)) AS OrtalamaMTBF_Saat,
    CAST(AVG(r.MTTR_Saat) AS DECIMAL(18,2)) AS OrtalamaMTTR_Saat,
    SUM(r.ToplamArizaSayisi) AS ToplamArizaSayisi
FROM dbo.EkipmanTurleri et
INNER JOIN dbo.Ekipmanlar e
    ON e.TurNo = et.TurNo
INNER JOIN dbo.vw_EkipmanMTBF_MTTR r
    ON r.EkipmanNo = e.EkipmanNo
GROUP BY et.TurAdi
ORDER BY ToplamArizaSayisi DESC;
GO

/* EN FAZLA ARIZA YAPAN 10 EKİPMAN */

SELECT TOP (10)
    e.EkipmanKodu,
    e.EkipmanAdi,
    e.Konum,
    COUNT(a.ArizaNo) AS ArizaSayisi
FROM dbo.Ekipmanlar e
INNER JOIN dbo.Arizalar a
    ON a.EkipmanNo = e.EkipmanNo
GROUP BY
    e.EkipmanKodu,
    e.EkipmanAdi,
    e.Konum
ORDER BY ArizaSayisi DESC;
GO

/* AYLIK ARIZA DAĞILIMI */

SELECT
    YEAR(AcilisZamani) AS Yil,
    MONTH(AcilisZamani) AS Ay,
    COUNT(*) AS ArizaSayisi
FROM dbo.Arizalar
GROUP BY
    YEAR(AcilisZamani),
    MONTH(AcilisZamani)
ORDER BY Yil, Ay;
GO