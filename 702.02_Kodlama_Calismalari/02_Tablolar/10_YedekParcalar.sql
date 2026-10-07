USE EndustriyelBakimDB;
GO

-- Bakımlarda kullanılan yedek parçaların temel bilgilerini tutar.
CREATE TABLE dbo.YedekParcalar
(
    ParcaNo INT IDENTITY(1,1) PRIMARY KEY,
    ParcaKodu NVARCHAR(30) NOT NULL UNIQUE,
    ParcaAdi NVARCHAR(100) NOT NULL,
    OlcuBirimi NVARCHAR(20) NOT NULL,
    AsgariStok DECIMAL(18,4) NOT NULL,
    GuncelBirimMaliyet DECIMAL(12,2) NOT NULL
);
GO