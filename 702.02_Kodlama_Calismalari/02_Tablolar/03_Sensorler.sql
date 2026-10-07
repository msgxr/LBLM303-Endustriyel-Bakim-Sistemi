USE EndustriyelBakimDB;
GO

CREATE TABLE dbo.Sensorler
(
    SensorNo INT IDENTITY(1,1) PRIMARY KEY,
    EkipmanNo INT NOT NULL,
    SensorKodu NVARCHAR(30) NOT NULL UNIQUE,
    SensorTuru NVARCHAR(50) NOT NULL,
    OlcumBirimi NVARCHAR(20) NOT NULL,
    AltEsik DECIMAL(18,4) NOT NULL,
    UstEsik DECIMAL(18,4) NOT NULL,
    KurulumTarihi DATE NULL,
    Durum NVARCHAR(20) NOT NULL,

    CONSTRAINT FK_Sensorler_Ekipmanlar
        FOREIGN KEY (EkipmanNo)
        REFERENCES dbo.Ekipmanlar(EkipmanNo),

    CONSTRAINT CK_Sensorler_EsikAraligi
        CHECK (AltEsik < UstEsik)
);