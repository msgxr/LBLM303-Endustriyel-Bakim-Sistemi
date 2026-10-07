USE EndustriyelBakimDB;
GO

-- Ekipmanların çalışmadığı süreleri kaydeder.
CREATE TABLE dbo.DurusKayitlari
(
    DurusNo BIGINT IDENTITY(1,1) PRIMARY KEY,
    EkipmanNo INT NOT NULL,
    ArizaNo BIGINT NULL,
    BaslangicZamani DATETIME2 NOT NULL,
    BitisZamani DATETIME2 NULL,
    DurusNedeni NVARCHAR(250) NOT NULL,

    CONSTRAINT FK_DurusKayitlari_Ekipmanlar
        FOREIGN KEY (EkipmanNo)
        REFERENCES dbo.Ekipmanlar(EkipmanNo),

    CONSTRAINT FK_DurusKayitlari_Arizalar
        FOREIGN KEY (ArizaNo)
        REFERENCES dbo.Arizalar(ArizaNo)
);
GO