USE EndustriyelBakimDB;
GO

-- Sistemde yapılan önemli işlemleri değiştirilemez denetim kaydı olarak tutar.
CREATE TABLE dbo.DenetimKayitlari
(
    DenetimNo BIGINT IDENTITY(1,1) PRIMARY KEY,
    KullaniciNo INT NULL,
    OturumKullaniciAdi NVARCHAR(128) NOT NULL,
    TabloAdi NVARCHAR(128) NOT NULL,
    KayitAnahtari NVARCHAR(250) NULL,
    IslemTuru NVARCHAR(20) NOT NULL,
    EskiDegerler NVARCHAR(MAX) NULL,
    YeniDegerler NVARCHAR(MAX) NULL,
    IslemZamani DATETIME2 NOT NULL
        CONSTRAINT DF_DenetimKayitlari_Zaman DEFAULT SYSDATETIME(),

    CONSTRAINT FK_DenetimKayitlari_Kullanicilar
        FOREIGN KEY (KullaniciNo)
        REFERENCES dbo.Kullanicilar(KullaniciNo)
);
GO