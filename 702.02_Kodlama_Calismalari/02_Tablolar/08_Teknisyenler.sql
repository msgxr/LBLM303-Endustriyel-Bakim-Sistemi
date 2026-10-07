USE EndustriyelBakimDB;
GO

-- Bakım ve arıza işlemlerini gerçekleştiren teknisyenleri tutar.
CREATE TABLE dbo.Teknisyenler
(
    TeknisyenNo INT IDENTITY(1,1) PRIMARY KEY,
    SicilNo NVARCHAR(20) NOT NULL UNIQUE,
    AdSoyad NVARCHAR(100) NOT NULL,
    Uzmanlik NVARCHAR(100) NOT NULL,
    SaatlikUcret DECIMAL(12,2) NOT NULL,
    Durum NVARCHAR(20) NOT NULL
        CONSTRAINT DF_Teknisyenler_Durum DEFAULT N'Aktif'
);
GO