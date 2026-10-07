USE EndustriyelBakimDB;
GO

-- Bir bakımda kullanılan veya iade edilen parçaları kaydeder.
CREATE TABLE dbo.BakimParcalari
(
    BakimParcaNo BIGINT IDENTITY(1,1) PRIMARY KEY,
    BakimEmriNo BIGINT NOT NULL,
    ParcaNo INT NOT NULL,
    IslemTuru NVARCHAR(20) NOT NULL,
    Miktar DECIMAL(18,4) NOT NULL,
    IslemAnindakiBirimMaliyet DECIMAL(12,2) NOT NULL,
    IslemZamani DATETIME2 NOT NULL
        CONSTRAINT DF_BakimParcalari_Islem DEFAULT SYSDATETIME(),
    KullaniciNo INT NULL,
    IadeEdilenKullanimNo BIGINT NULL,

    CONSTRAINT FK_BakimParcalari_BakimEmirleri
        FOREIGN KEY (BakimEmriNo)
        REFERENCES dbo.BakimEmirleri(BakimEmriNo),

    CONSTRAINT FK_BakimParcalari_YedekParcalar
        FOREIGN KEY (ParcaNo)
        REFERENCES dbo.YedekParcalar(ParcaNo),

    CONSTRAINT FK_BakimParcalari_Iade
        FOREIGN KEY (IadeEdilenKullanimNo)
        REFERENCES dbo.BakimParcalari(BakimParcaNo)
);
GO