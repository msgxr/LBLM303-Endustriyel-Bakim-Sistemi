USE EndustriyelBakimDB;
GO

/* Sensörün tarih aralığındaki ölçümlerini hızlandırır. */

IF NOT EXISTS
(
    SELECT 1 FROM sys.indexes
    WHERE name = N'IX_Olcumler_SensorNo_OlcumZamani'
      AND object_id = OBJECT_ID(N'dbo.Olcumler')
)
CREATE INDEX IX_Olcumler_SensorNo_OlcumZamani
ON dbo.Olcumler (SensorNo, OlcumZamani DESC)
INCLUDE (OlcumDegeri);
GO

/* Ekipmana bağlı sensör sorgularını hızlandırır. */

IF NOT EXISTS
(
    SELECT 1 FROM sys.indexes
    WHERE name = N'IX_Sensorler_EkipmanNo'
      AND object_id = OBJECT_ID(N'dbo.Sensorler')
)
CREATE INDEX IX_Sensorler_EkipmanNo
ON dbo.Sensorler (EkipmanNo)
INCLUDE (SensorKodu, SensorTuru, Durum);
GO

/* Açık alarm sorgularını hızlandırır. */

IF NOT EXISTS
(
    SELECT 1 FROM sys.indexes
    WHERE name = N'IX_Alarmlar_Durum_AcilisZamani'
      AND object_id = OBJECT_ID(N'dbo.Alarmlar')
)
CREATE INDEX IX_Alarmlar_Durum_AcilisZamani
ON dbo.Alarmlar (Durum, AcilisZamani DESC)
INCLUDE (OlcumNo, Seviye);
GO

/* Ekipmanın arıza geçmişini hızlandırır. */

IF NOT EXISTS
(
    SELECT 1 FROM sys.indexes
    WHERE name = N'IX_Arizalar_EkipmanNo_AcilisZamani'
      AND object_id = OBJECT_ID(N'dbo.Arizalar')
)
CREATE INDEX IX_Arizalar_EkipmanNo_AcilisZamani
ON dbo.Arizalar (EkipmanNo, AcilisZamani DESC)
INCLUDE (AlarmNo, Oncelik, Durum, KapanisZamani);
GO

/* Ekipmanın bakım emri sorgularını hızlandırır. */

IF NOT EXISTS
(
    SELECT 1 FROM sys.indexes
    WHERE name = N'IX_BakimEmirleri_EkipmanNo_Durum'
      AND object_id = OBJECT_ID(N'dbo.BakimEmirleri')
)
CREATE INDEX IX_BakimEmirleri_EkipmanNo_Durum
ON dbo.BakimEmirleri (EkipmanNo, Durum)
INCLUDE
(
    ArizaNo,
    BakimTuru,
    Oncelik,
    OlusturmaZamani,
    TamamlanmaZamani
);
GO

/* Arızaya bağlı bakım emri aramalarını hızlandırır. */

IF NOT EXISTS
(
    SELECT 1 FROM sys.indexes
    WHERE name = N'IX_BakimEmirleri_ArizaNo'
      AND object_id = OBJECT_ID(N'dbo.BakimEmirleri')
)
CREATE INDEX IX_BakimEmirleri_ArizaNo
ON dbo.BakimEmirleri (ArizaNo)
INCLUDE (BakimTuru, Durum)
WHERE ArizaNo IS NOT NULL;
GO

/* Teknisyen görevlendirme sorgularını hızlandırır. */

IF NOT EXISTS
(
    SELECT 1 FROM sys.indexes
    WHERE name = N'IX_Gorevlendirmeler_BakimEmriNo'
      AND object_id = OBJECT_ID(N'dbo.BakimGorevlendirmeleri')
)
CREATE INDEX IX_Gorevlendirmeler_BakimEmriNo
ON dbo.BakimGorevlendirmeleri (BakimEmriNo)
INCLUDE
(
    TeknisyenNo,
    AtamaZamani,
    CalismaBaslangici,
    CalismaBitisi
);
GO

/* Bakımlarda kullanılan parçaların sorgularını hızlandırır. */

IF NOT EXISTS
(
    SELECT 1 FROM sys.indexes
    WHERE name = N'IX_BakimParcalari_BakimEmriNo'
      AND object_id = OBJECT_ID(N'dbo.BakimParcalari')
)
CREATE INDEX IX_BakimParcalari_BakimEmriNo
ON dbo.BakimParcalari (BakimEmriNo)
INCLUDE
(
    ParcaNo,
    IslemTuru,
    Miktar,
    IslemAnindakiBirimMaliyet
);
GO

/* Parçanın stok hareketlerini hızlandırır. */

IF NOT EXISTS
(
    SELECT 1 FROM sys.indexes
    WHERE name = N'IX_StokHareketleri_ParcaNo_Zaman'
      AND object_id = OBJECT_ID(N'dbo.StokHareketleri')
)
CREATE INDEX IX_StokHareketleri_ParcaNo_Zaman
ON dbo.StokHareketleri (ParcaNo, HareketZamani DESC)
INCLUDE (HareketTuru, Miktar, BirimMaliyet);
GO

/* Ekipman duruş raporlarını hızlandırır. */

IF NOT EXISTS
(
    SELECT 1 FROM sys.indexes
    WHERE name = N'IX_DurusKayitlari_EkipmanNo_Baslangic'
      AND object_id = OBJECT_ID(N'dbo.DurusKayitlari')
)
CREATE INDEX IX_DurusKayitlari_EkipmanNo_Baslangic
ON dbo.DurusKayitlari (EkipmanNo, BaslangicZamani DESC)
INCLUDE (ArizaNo, BitisZamani);
GO

/* Denetim kayıtlarında tarih ve tablo aramasını hızlandırır. */

IF NOT EXISTS
(
    SELECT 1 FROM sys.indexes
    WHERE name = N'IX_DenetimKayitlari_Tablo_Zaman'
      AND object_id = OBJECT_ID(N'dbo.DenetimKayitlari')
)
CREATE INDEX IX_DenetimKayitlari_Tablo_Zaman
ON dbo.DenetimKayitlari (TabloAdi, IslemZamani DESC)
INCLUDE
(
    KullaniciNo,
    OturumKullaniciAdi,
    KayitAnahtari,
    IslemTuru
);
GO

PRINT N'Performans indeksleri başarıyla oluşturuldu.';
GO