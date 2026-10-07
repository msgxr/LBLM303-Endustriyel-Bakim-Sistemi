USE EndustriyelBakimDB;
GO

CREATE TABLE dbo.Olcumler
(
    OlcumNo BIGINT IDENTITY(1,1) PRIMARY KEY,
    SensorNo INT NOT NULL,
    OlcumDegeri DECIMAL(18,4) NOT NULL,
    OlcumZamani DATETIME2 NOT NULL,

    CONSTRAINT FK_Olcumler_Sensorler
        FOREIGN KEY (SensorNo)
        REFERENCES dbo.Sensorler(SensorNo)
);