USE EndustriyelBakimDB;
GO

-- Sistemi kullanan personeli ve SQL kullanıcı adlarını tutar.
CREATE TABLE dbo.Kullanicilar
(
    KullaniciNo INT IDENTITY(1,1) PRIMARY KEY,
    TeknisyenNo INT NULL,
    SqlKullaniciAdi NVARCHAR(128) NOT NULL UNIQUE,
    AdSoyad NVARCHAR(100) NOT NULL,
    Aktif BIT NOT NULL
        CONSTRAINT DF_Kullanicilar_Aktif DEFAULT 1,
    OlusturmaZamani DATETIME2 NOT NULL
        CONSTRAINT DF_Kullanicilar_Olusturma DEFAULT SYSDATETIME(),

    CONSTRAINT FK_Kullanicilar_Teknisyenler
        FOREIGN KEY (TeknisyenNo)
        REFERENCES dbo.Teknisyenler(TeknisyenNo),

    CONSTRAINT UQ_Kullanicilar_TeknisyenNo
        UNIQUE (TeknisyenNo)
);
GO