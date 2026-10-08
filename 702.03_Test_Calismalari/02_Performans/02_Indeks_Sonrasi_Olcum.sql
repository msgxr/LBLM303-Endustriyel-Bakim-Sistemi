USE EndustriyelBakimDB;
GO

SET ANSI_NULLS ON;
SET QUOTED_IDENTIFIER ON;
SET ANSI_PADDING ON;
SET ANSI_WARNINGS ON;
SET ARITHABORT ON;
SET CONCAT_NULL_YIELDS_NULL ON;
SET NUMERIC_ROUNDABORT OFF;
GO

SET NOCOUNT OFF;

/* Dosya adları eski karşılaştırmayı korur.
   Güncel deney: aynı veri aralığında zorunlu tarama / optimize edilmiş erişim.
   İndeks silinmez; sunucu önbelleği temizlenmez. Test sırasında veri eklemeyin. */
DECLARE @SensorNo INT = (SELECT TOP (1) SensorNo FROM dbo.Sensorler ORDER BY SensorNo);
DECLARE @Bitis DATETIME2 = (SELECT MAX(OlcumZamani) FROM dbo.Olcumler WHERE SensorNo = @SensorNo);
DECLARE @Baslangic DATETIME2 = DATEADD(DAY, -30, @Bitis);

IF @SensorNo IS NULL OR @Bitis IS NULL
    THROW 52070, N'Performans testi için sensör ölçümü bulunamadı.', 1;

IF NOT EXISTS
(
    SELECT 1 FROM sys.indexes
    WHERE object_id = OBJECT_ID(N'dbo.Olcumler')
      AND name = N'IX_Olcumler_SensorNo_OlcumZamani'
      AND is_disabled = 0 AND is_hypothetical = 0
)
    THROW 52071, N'Ölçüm performans indeksi eksik veya devre dışı.', 1;
SELECT N'Optimize edilmiş erişim' AS Deney, @SensorNo AS SensorNo,
    @Baslangic AS Baslangic, @Bitis AS Bitis;

BEGIN TRY
    SET STATISTICS IO ON;
    SET STATISTICS TIME ON;

    SELECT SensorNo, OlcumDegeri, OlcumZamani
    FROM dbo.Olcumler
    WHERE SensorNo = @SensorNo
      AND OlcumZamani >= @Baslangic
      AND OlcumZamani <= @Bitis
    ORDER BY OlcumZamani DESC
    OPTION (RECOMPILE);

    SET STATISTICS IO OFF;
    SET STATISTICS TIME OFF;
END TRY
BEGIN CATCH
    SET STATISTICS IO OFF;
    SET STATISTICS TIME OFF;
    THROW;
END CATCH;
GO
