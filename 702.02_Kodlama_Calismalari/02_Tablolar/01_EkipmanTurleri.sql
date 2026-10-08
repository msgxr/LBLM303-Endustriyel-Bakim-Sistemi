USE EndustriyelBakimDB;
GO

CREATE TABLE dbo.EkipmanTurleri
(

   TurNO INT IDENTITY(1,1) PRIMARY KEY,
   TurAdi NVARCHAR(50) NOT NULL UNIQUE,
   Aciklama NVARCHAR(250) NULL
   );

