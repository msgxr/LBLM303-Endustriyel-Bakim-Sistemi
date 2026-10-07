USE EndustriyelBakimDB;
GO

/* BAKIM EMRİ BAZINDA MALİYET */

SELECT
    BakimEmriNo,
    EkipmanKodu,
    EkipmanAdi,
    BakimTuru,
    Durum,
    IscilikMaliyeti,
    ParcaMaliyeti,
    ToplamMaliyet
FROM dbo.vw_BakimMaliyetleri
ORDER BY ToplamMaliyet DESC;
GO

/* EKİPMAN BAZINDA TOPLAM BAKIM MALİYETİ */

SELECT
    EkipmanKodu,
    EkipmanAdi,
    COUNT(BakimEmriNo) AS BakimSayisi,
    CAST(SUM(IscilikMaliyeti) AS DECIMAL(18,2))
        AS ToplamIscilikMaliyeti,
    CAST(SUM(ParcaMaliyeti) AS DECIMAL(18,2))
        AS ToplamParcaMaliyeti,
    CAST(SUM(ToplamMaliyet) AS DECIMAL(18,2))
        AS GenelToplamMaliyet
FROM dbo.vw_BakimMaliyetleri
GROUP BY
    EkipmanKodu,
    EkipmanAdi
ORDER BY GenelToplamMaliyet DESC;
GO

/* EKİPMAN BAZINDA DURUŞ SÜRELERİ */

SELECT
    e.EkipmanKodu,
    e.EkipmanAdi,
    COUNT(d.DurusNo) AS DurusSayisi,
    CAST
    (
        SUM
        (
            DATEDIFF
            (
                MINUTE,
                d.BaslangicZamani,
                COALESCE(d.BitisZamani, SYSDATETIME())
            )
        ) / 60.0
        AS DECIMAL(18,2)
    ) AS ToplamDurusSaati
FROM dbo.DurusKayitlari d
INNER JOIN dbo.Ekipmanlar e
    ON e.EkipmanNo = d.EkipmanNo
GROUP BY
    e.EkipmanKodu,
    e.EkipmanAdi
ORDER BY ToplamDurusSaati DESC;
GO

/* SON 90 GÜNDE EKİPMAN KULLANILABİLİRLİK ORANI */

WITH Durus AS
(
    SELECT
        EkipmanNo,
        SUM
        (
            DATEDIFF
            (
                MINUTE,
                CASE
                    WHEN BaslangicZamani <
                         DATEADD(DAY, -90, SYSDATETIME())
                    THEN DATEADD(DAY, -90, SYSDATETIME())
                    ELSE BaslangicZamani
                END,
                CASE
                    WHEN BitisZamani IS NULL
                      OR BitisZamani > SYSDATETIME()
                    THEN SYSDATETIME()
                    ELSE BitisZamani
                END
            )
        ) AS DurusDakikasi
    FROM dbo.DurusKayitlari
    WHERE BaslangicZamani <= SYSDATETIME()
      AND COALESCE(BitisZamani, SYSDATETIME()) >=
          DATEADD(DAY, -90, SYSDATETIME())
    GROUP BY EkipmanNo
)
SELECT
    e.EkipmanKodu,
    e.EkipmanAdi,
    COALESCE(d.DurusDakikasi, 0) / 60.0 AS DurusSaati,
    CAST
    (
        (
            1 -
            (
                COALESCE(d.DurusDakikasi, 0) /
                (90.0 * 24 * 60)
            )
        ) * 100
        AS DECIMAL(6,2)
    ) AS KullanilabilirlikYuzdesi
FROM dbo.Ekipmanlar e
LEFT JOIN Durus d
    ON d.EkipmanNo = e.EkipmanNo
ORDER BY KullanilabilirlikYuzdesi;
GO

/* KRİTİK STOK SEVİYESİNDEKİ PARÇALAR */

SELECT
    ParcaKodu,
    ParcaAdi,
    OlcuBirimi,
    MevcutStok,
    AsgariStok,
    StokDurumu
FROM dbo.vw_StokDurumu
WHERE StokDurumu = N'Kritik'
ORDER BY MevcutStok;
GO