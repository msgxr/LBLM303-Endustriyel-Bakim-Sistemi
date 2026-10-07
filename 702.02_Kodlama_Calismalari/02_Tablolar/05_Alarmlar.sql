USE EndustriyelBakimDB;
GO

CREATE TABLE dbo.Alarmlar
(
    AlarmNo BIGINT IDENTITY(1,1) PRIMARY KEY,
    OlcumNo BIGINT NOT NULL,
    Seviye NVARCHAR(20) NOT NULL,
    Aciklama NVARCHAR(250) NOT NULL,
    Durum NVARCHAR(20) NOT NULL
        CONSTRAINT DF_Alarmlar_Durum DEFAULT N'Açık',
    AcilisZamani DATETIME2 NOT NULL
        CONSTRAINT DF_Alarmlar_AcilisZamani DEFAULT SYSDATETIME(),
    KapanisZamani DATETIME2 NULL,
    InceleyenKullaniciNo INT NULL,
    IncelemeZamani DATETIME2 NULL,
    IncelemeSonucu NVARCHAR(250) NULL,

    CONSTRAINT FK_Alarmlar_Olcumler
        FOREIGN KEY (OlcumNo)
        REFERENCES dbo.Olcumler(OlcumNo)
);
GO