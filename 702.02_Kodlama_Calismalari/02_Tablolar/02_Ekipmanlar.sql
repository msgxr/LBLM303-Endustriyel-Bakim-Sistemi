USE EndustriyelBakimDB;
GO

CREATE TABLE dbo.Ekipmanlar
(
    EkipmanNo INT IDENTITY(1,1) PRIMARY KEY,
    TurNo INT NOT NULL,
    EkipmanKodu NVARCHAR(30) NOT NULL UNIQUE,
    EkipmanAdi NVARCHAR(100) NOT NULL,
    Konum NVARCHAR(150) NOT NULL,
    KurulumTarihi DATE NULL,
    Durum NVARCHAR(20) NOT NULL,

    CONSTRAINT FK_Ekipmanlar_EkipmanTurleri
        FOREIGN KEY (TurNo)
        REFERENCES dbo.EkipmanTurleri(TurNO)
);
