USE EndustriyelBakimDB;
GO

-- Kullanıcıların hangi rollere sahip olduğunu kaydeder.
CREATE TABLE dbo.KullaniciRolleri
(
    KullaniciRolNo BIGINT IDENTITY(1,1) PRIMARY KEY,
    KullaniciNo INT NOT NULL,
    RolNo INT NOT NULL,
    AtamaZamani DATETIME2 NOT NULL
        CONSTRAINT DF_KullaniciRolleri_Atama DEFAULT SYSDATETIME(),

    CONSTRAINT FK_KullaniciRolleri_Kullanicilar
        FOREIGN KEY (KullaniciNo)
        REFERENCES dbo.Kullanicilar(KullaniciNo),

    CONSTRAINT FK_KullaniciRolleri_Roller
        FOREIGN KEY (RolNo)
        REFERENCES dbo.Roller(RolNo),

    CONSTRAINT UQ_KullaniciRolleri
        UNIQUE (KullaniciNo, RolNo)
);
GO