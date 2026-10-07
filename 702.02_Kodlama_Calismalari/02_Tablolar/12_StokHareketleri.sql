USE EndustriyelBakimDB;
GO

-- Parçaların stok giriş, çıkış, kullanım ve iade hareketlerini tutar.
CREATE TABLE dbo.StokHareketleri
(
    StokHareketNo BIGINT IDENTITY(1,1) PRIMARY KEY,
    ParcaNo INT NOT NULL,
    BakimParcaNo BIGINT NULL,
    HareketTuru NVARCHAR(20) NOT NULL,
    Miktar DECIMAL(18,4) NOT NULL,
    BirimMaliyet DECIMAL(12,2) NULL,
    HareketZamani DATETIME2 NOT NULL
        CONSTRAINT DF_StokHareketleri_Zaman DEFAULT SYSDATETIME(),
    KullaniciNo INT NULL,
    Aciklama NVARCHAR(250) NULL,

    CONSTRAINT FK_StokHareketleri_YedekParcalar
        FOREIGN KEY (ParcaNo)
        REFERENCES dbo.YedekParcalar(ParcaNo),

    CONSTRAINT FK_StokHareketleri_BakimParcalari
        FOREIGN KEY (BakimParcaNo)
        REFERENCES dbo.BakimParcalari(BakimParcaNo)
);
GO