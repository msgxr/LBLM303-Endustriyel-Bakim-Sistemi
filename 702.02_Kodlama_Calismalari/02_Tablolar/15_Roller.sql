USE EndustriyelBakimDB;
GO

-- Yönetici, teknisyen ve denetçi gibi yetki rollerini tanımlar.
CREATE TABLE dbo.Roller
(
    RolNo INT IDENTITY(1,1) PRIMARY KEY,
    RolAdi NVARCHAR(50) NOT NULL UNIQUE,
    SqlRolAdi NVARCHAR(128) NOT NULL UNIQUE,
    Aciklama NVARCHAR(250) NULL
);
GO