USE EndustriyelBakimDB;
GO

-- Ekipmanlarda oluşan arızaları ve arıza sürecini kaydeder.
CREATE TABLE dbo.Arizalar
(
    ArizaNo BIGINT IDENTITY(1,1) PRIMARY KEY,
    EkipmanNo INT NOT NULL,
    AlarmNo BIGINT NULL,
    ArizaAciklamasi NVARCHAR(500) NOT NULL,
    ArizaNedeni NVARCHAR(250) NULL,
    Oncelik NVARCHAR(20) NOT NULL,
    Durum NVARCHAR(20) NOT NULL
        CONSTRAINT DF_Arizalar_Durum DEFAULT N'Açık',
    AcilisZamani DATETIME2 NOT NULL
        CONSTRAINT DF_Arizalar_Acilis DEFAULT SYSDATETIME(),
    DogrulayanKullaniciNo INT NULL,
    DogrulamaZamani DATETIME2 NULL,
    KapatanKullaniciNo INT NULL,
    KapanisZamani DATETIME2 NULL,

    CONSTRAINT FK_Arizalar_Ekipmanlar
        FOREIGN KEY (EkipmanNo)
        REFERENCES dbo.Ekipmanlar(EkipmanNo),

    CONSTRAINT FK_Arizalar_Alarmlar
        FOREIGN KEY (AlarmNo)
        REFERENCES dbo.Alarmlar(AlarmNo)
);
GO