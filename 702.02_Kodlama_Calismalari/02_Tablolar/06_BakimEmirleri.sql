USE EndustriyelBakimDB;
GO

-- Ekipmanlar için planlı ve arıza kaynaklı bakım işlerini kaydeder.
CREATE TABLE dbo.BakimEmirleri
(
    BakimEmriNo BIGINT IDENTITY(1,1) PRIMARY KEY,
    EkipmanNo INT NOT NULL,
    ArizaNo BIGINT NULL,
    BakimTuru NVARCHAR(30) NOT NULL,
    Aciklama NVARCHAR(500) NOT NULL,
    Oncelik NVARCHAR(20) NOT NULL,
    Durum NVARCHAR(30) NOT NULL
        CONSTRAINT DF_BakimEmirleri_Durum DEFAULT N'Bekliyor',
    OlusturmaZamani DATETIME2 NOT NULL
        CONSTRAINT DF_BakimEmirleri_Olusturma DEFAULT SYSDATETIME(),
    PlanlananBaslangic DATETIME2 NULL,
    GerceklesenBaslangic DATETIME2 NULL,
    TamamlanmaZamani DATETIME2 NULL,
    KontrolEdenKullaniciNo INT NULL,
    IptalOnaylayanKullaniciNo INT NULL,

    CONSTRAINT FK_BakimEmirleri_Ekipmanlar
        FOREIGN KEY (EkipmanNo)
        REFERENCES dbo.Ekipmanlar(EkipmanNo)
);
GO