USE EndustriyelBakimDB;
GO

-- Bakım emirlerine hangi teknisyenin atandığını kaydeder.
CREATE TABLE dbo.BakimGorevlendirmeleri
(
    GorevlendirmeNo BIGINT IDENTITY(1,1) PRIMARY KEY,
    BakimEmriNo BIGINT NOT NULL,
    TeknisyenNo INT NOT NULL,
    AtamaZamani DATETIME2 NOT NULL
        CONSTRAINT DF_Gorevlendirmeler_Atama DEFAULT SYSDATETIME(),
    CalismaBaslangici DATETIME2 NULL,
    CalismaBitisi DATETIME2 NULL,
    IslemAnindakiSaatlikUcret DECIMAL(12,2) NOT NULL,
    YapilanIs NVARCHAR(500) NULL,

    CONSTRAINT FK_Gorevlendirmeler_BakimEmirleri
        FOREIGN KEY (BakimEmriNo)
        REFERENCES dbo.BakimEmirleri(BakimEmriNo),

    CONSTRAINT FK_Gorevlendirmeler_Teknisyenler
        FOREIGN KEY (TeknisyenNo)
        REFERENCES dbo.Teknisyenler(TeknisyenNo)
);
GO