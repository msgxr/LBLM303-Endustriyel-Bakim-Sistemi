USE EndustriyelBakimDB;
GO

SET STATISTICS IO ON;
SET STATISTICS TIME ON;

DECLARE @SensorNo INT =
    (SELECT TOP (1) SensorNo FROM dbo.Sensorler ORDER BY SensorNo);

SELECT
    SensorNo,
    OlcumDegeri,
    OlcumZamani
FROM dbo.Olcumler
WHERE SensorNo = @SensorNo
  AND OlcumZamani >= DATEADD(DAY, -30, SYSDATETIME())
ORDER BY OlcumZamani DESC;

SET STATISTICS IO OFF;
SET STATISTICS TIME OFF;
GO