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

SET NOCOUNT ON;
SET XACT_ABORT ON;

/* Salt okunur yapısal ve örnek veri kontrolü.
   Satır sayıları COUNT_BIG ile gerçek tablolardan hesaplanır.
   80.000-100.000 aralığı örnek veri hedefidir; gerçek kullanımda aşılabilir. */
DECLARE @OrnekVeriHedefiniZorunluTut BIT = 1;

DECLARE @BeklenenNesneler TABLE
(
    NesneAdi SYSNAME NOT NULL PRIMARY KEY,
    NesneTuru VARCHAR(2) NOT NULL
);
INSERT INTO @BeklenenNesneler (NesneAdi, NesneTuru)
VALUES
    (N'EkipmanTurleri', 'U'),
    (N'Ekipmanlar', 'U'),
    (N'Sensorler', 'U'),
    (N'Olcumler', 'U'),
    (N'Alarmlar', 'U'),
    (N'BakimEmirleri', 'U'),
    (N'Arizalar', 'U'),
    (N'Teknisyenler', 'U'),
    (N'BakimGorevlendirmeleri', 'U'),
    (N'YedekParcalar', 'U'),
    (N'BakimParcalari', 'U'),
    (N'StokHareketleri', 'U'),
    (N'DurusKayitlari', 'U'),
    (N'Kullanicilar', 'U'),
    (N'Roller', 'U'),
    (N'KullaniciRolleri', 'U'),
    (N'DenetimKayitlari', 'U'),
    (N'vw_GuncelAlarmlar', 'V'),
    (N'vw_AktifBakimEmirleri', 'V'),
    (N'vw_StokDurumu', 'V'),
    (N'vw_BakimMaliyetleri', 'V'),
    (N'vw_EkipmanMTBF_MTTR', 'V'),
    (N'vw_EkipmanOzeti', 'V'),
    (N'sp_AlarmIncele', 'P'),
    (N'sp_AlarmdanArizaOlustur', 'P'),
    (N'sp_BakimEmriOlustur', 'P'),
    (N'sp_TeknisyenGorevlendir', 'P'),
    (N'sp_ParcaKullan', 'P'),
    (N'sp_BakimTamamla', 'P'),
    (N'trg_Olcumler_AlarmOlustur', 'TR'),
    (N'trg_Arizalar_AlarmKontrol', 'TR'),
    (N'trg_BakimEmirleri_AktifEmirKontrol', 'TR'),
    (N'trg_StokHareketleri_NegatifStokKontrol', 'TR'),
    (N'trg_BakimEmirleri_Denetim', 'TR'),
    (N'trg_StokHareketleri_Denetim', 'TR'),
    (N'trg_DenetimKayitlari_Koruma', 'TR'),
    (N'FK_Ekipmanlar_EkipmanTurleri', 'F'),
    (N'FK_Sensorler_Ekipmanlar', 'F'),
    (N'CK_Sensorler_EsikAraligi', 'C'),
    (N'FK_Olcumler_Sensorler', 'F'),
    (N'FK_Alarmlar_Olcumler', 'F'),
    (N'FK_BakimEmirleri_Ekipmanlar', 'F'),
    (N'FK_Arizalar_Ekipmanlar', 'F'),
    (N'FK_Arizalar_Alarmlar', 'F'),
    (N'FK_Gorevlendirmeler_BakimEmirleri', 'F'),
    (N'FK_Gorevlendirmeler_Teknisyenler', 'F'),
    (N'FK_BakimParcalari_BakimEmirleri', 'F'),
    (N'FK_BakimParcalari_YedekParcalar', 'F'),
    (N'FK_BakimParcalari_Iade', 'F'),
    (N'FK_StokHareketleri_YedekParcalar', 'F'),
    (N'FK_StokHareketleri_BakimParcalari', 'F'),
    (N'FK_DurusKayitlari_Ekipmanlar', 'F'),
    (N'FK_DurusKayitlari_Arizalar', 'F'),
    (N'FK_Kullanicilar_Teknisyenler', 'F'),
    (N'FK_KullaniciRolleri_Kullanicilar', 'F'),
    (N'FK_KullaniciRolleri_Roller', 'F'),
    (N'UQ_KullaniciRolleri', 'UQ'),
    (N'FK_DenetimKayitlari_Kullanicilar', 'F'),
    (N'FK_Alarmlar_Kullanicilar', 'F'),
    (N'FK_BakimEmirleri_Arizalar', 'F'),
    (N'FK_BakimEmirleri_KontrolKullanicisi', 'F'),
    (N'FK_BakimEmirleri_IptalKullanicisi', 'F'),
    (N'FK_Arizalar_DogrulayanKullanici', 'F'),
    (N'FK_Arizalar_KapatanKullanici', 'F'),
    (N'FK_BakimParcalari_Kullanicilar', 'F'),
    (N'FK_StokHareketleri_Kullanicilar', 'F'),
    (N'CK_Alarmlar_Seviye', 'C'),
    (N'CK_Alarmlar_Durum', 'C'),
    (N'CK_Alarmlar_Tarih', 'C'),
    (N'CK_BakimEmirleri_Tur', 'C'),
    (N'CK_BakimEmirleri_Oncelik', 'C'),
    (N'CK_BakimEmirleri_Durum', 'C'),
    (N'CK_BakimEmirleri_Tarih', 'C'),
    (N'CK_Arizalar_Oncelik', 'C'),
    (N'CK_Arizalar_Durum', 'C'),
    (N'CK_Arizalar_Tarih', 'C'),
    (N'CK_Teknisyenler_Ucret', 'C'),
    (N'CK_Teknisyenler_Durum', 'C'),
    (N'CK_Gorevlendirmeler_Ucret', 'C'),
    (N'CK_Gorevlendirmeler_Tarih', 'C'),
    (N'CK_YedekParcalar_Stok', 'C'),
    (N'CK_YedekParcalar_Maliyet', 'C'),
    (N'CK_BakimParcalari_Tur', 'C'),
    (N'CK_BakimParcalari_Miktar', 'C'),
    (N'CK_BakimParcalari_Maliyet', 'C'),
    (N'CK_StokHareketleri_Tur', 'C'),
    (N'CK_StokHareketleri_Miktar', 'C'),
    (N'CK_StokHareketleri_Maliyet', 'C'),
    (N'CK_DurusKayitlari_Tarih', 'C'),
    (N'CK_DenetimKayitlari_Islem', 'C'),
    (N'UQ_Alarmlar_OlcumNo', 'UQ');

/* Katalog metinleri farklı collation kullanabilir.
   Karşılaştırmalar mevcut veritabanının collation ayarıyla yapılır. */
IF EXISTS
(
    SELECT 1
    FROM @BeklenenNesneler b
    LEFT JOIN sys.objects o
        ON o.name COLLATE DATABASE_DEFAULT = b.NesneAdi
       AND o.schema_id = SCHEMA_ID(N'dbo')
       AND o.type COLLATE DATABASE_DEFAULT = b.NesneTuru
    WHERE o.object_id IS NULL
)
BEGIN
    SELECT b.NesneAdi AS EksikNesne, b.NesneTuru
    FROM @BeklenenNesneler b
    LEFT JOIN sys.objects o
        ON o.name COLLATE DATABASE_DEFAULT = b.NesneAdi
       AND o.schema_id = SCHEMA_ID(N'dbo')
       AND o.type COLLATE DATABASE_DEFAULT = b.NesneTuru
    WHERE o.object_id IS NULL;
    THROW 52000, N'Beklenen tablo, görünüm, yordam, tetikleyici veya kısıt eksik.', 1;
END;

IF EXISTS
(
    SELECT 1 FROM sys.foreign_keys
    WHERE is_disabled = 1 OR is_not_trusted = 1
)
OR EXISTS
(
    SELECT 1 FROM sys.check_constraints
    WHERE is_disabled = 1 OR is_not_trusted = 1
)
    THROW 52001, N'Devre dışı veya güvenilmeyen FK/CHECK kısıtı bulundu.', 1;

IF EXISTS
(
    SELECT 1
    FROM sys.triggers t
    INNER JOIN @BeklenenNesneler b ON b.NesneAdi = t.name COLLATE DATABASE_DEFAULT AND b.NesneTuru = 'TR'
    WHERE t.is_disabled = 1
)
    THROW 52002, N'Beklenen tetikleyicilerden biri devre dışı.', 1;

IF EXISTS
(
    SELECT 1
    FROM @BeklenenNesneler b
    WHERE b.NesneTuru = 'U'
      AND NOT EXISTS
      (
          SELECT 1 FROM sys.indexes i
          WHERE i.object_id = OBJECT_ID(N'dbo.' + b.NesneAdi)
            AND i.is_primary_key = 1
            AND i.is_disabled = 0
      )
)
    THROW 52003, N'Bir proje tablosunda etkin birincil anahtar bulunamadı.', 1;

DECLARE @BeklenenIndeksler TABLE (TabloAdi SYSNAME, IndeksAdi SYSNAME);
INSERT INTO @BeklenenIndeksler
VALUES
    (N'Arizalar', N'UX_Arizalar_AlarmNo'),
    (N'Kullanicilar', N'UX_Kullanicilar_TeknisyenNo'),
    (N'Olcumler', N'IX_Olcumler_SensorNo_OlcumZamani'),
    (N'Sensorler', N'IX_Sensorler_EkipmanNo'),
    (N'Alarmlar', N'IX_Alarmlar_Durum_AcilisZamani'),
    (N'Arizalar', N'IX_Arizalar_EkipmanNo_AcilisZamani'),
    (N'BakimEmirleri', N'IX_BakimEmirleri_EkipmanNo_Durum'),
    (N'BakimEmirleri', N'IX_BakimEmirleri_ArizaNo'),
    (N'BakimGorevlendirmeleri', N'IX_Gorevlendirmeler_BakimEmriNo'),
    (N'BakimParcalari', N'IX_BakimParcalari_BakimEmriNo'),
    (N'StokHareketleri', N'IX_StokHareketleri_ParcaNo_Zaman'),
    (N'DurusKayitlari', N'IX_DurusKayitlari_EkipmanNo_Baslangic'),
    (N'DenetimKayitlari', N'IX_DenetimKayitlari_Tablo_Zaman');

IF EXISTS
(
    SELECT 1 FROM @BeklenenIndeksler b
    WHERE NOT EXISTS
    (
        SELECT 1 FROM sys.indexes i
        WHERE i.object_id = OBJECT_ID(N'dbo.' + b.TabloAdi)
          AND i.name COLLATE DATABASE_DEFAULT = b.IndeksAdi
          AND i.is_disabled = 0
          AND i.is_hypothetical = 0
    )
)
    THROW 52004, N'Beklenen etkin indekslerden biri eksik.', 1;

IF EXISTS
(
    SELECT 1
    FROM (VALUES
        (N'rol_yonetici'), (N'rol_bakim_yoneticisi'),
        (N'rol_teknisyen'), (N'rol_denetci')
    ) b(RolAdi)
    WHERE NOT EXISTS
    (
        SELECT 1 FROM sys.database_principals p
        WHERE p.name COLLATE DATABASE_DEFAULT = b.RolAdi AND p.type = 'R'
    )
)
    THROW 52005, N'Beklenen SQL Server veritabanı rollerinden biri eksik.', 1;

DECLARE @KayitSayilari TABLE (TabloAdi SYSNAME PRIMARY KEY, KayitSayisi BIGINT);
INSERT INTO @KayitSayilari
SELECT N'EkipmanTurleri', COUNT_BIG(*) FROM dbo.EkipmanTurleri
UNION ALL
SELECT N'Ekipmanlar', COUNT_BIG(*) FROM dbo.Ekipmanlar
UNION ALL
SELECT N'Sensorler', COUNT_BIG(*) FROM dbo.Sensorler
UNION ALL
SELECT N'Olcumler', COUNT_BIG(*) FROM dbo.Olcumler
UNION ALL
SELECT N'Alarmlar', COUNT_BIG(*) FROM dbo.Alarmlar
UNION ALL
SELECT N'BakimEmirleri', COUNT_BIG(*) FROM dbo.BakimEmirleri
UNION ALL
SELECT N'Arizalar', COUNT_BIG(*) FROM dbo.Arizalar
UNION ALL
SELECT N'Teknisyenler', COUNT_BIG(*) FROM dbo.Teknisyenler
UNION ALL
SELECT N'BakimGorevlendirmeleri', COUNT_BIG(*) FROM dbo.BakimGorevlendirmeleri
UNION ALL
SELECT N'YedekParcalar', COUNT_BIG(*) FROM dbo.YedekParcalar
UNION ALL
SELECT N'BakimParcalari', COUNT_BIG(*) FROM dbo.BakimParcalari
UNION ALL
SELECT N'StokHareketleri', COUNT_BIG(*) FROM dbo.StokHareketleri
UNION ALL
SELECT N'DurusKayitlari', COUNT_BIG(*) FROM dbo.DurusKayitlari
UNION ALL
SELECT N'Kullanicilar', COUNT_BIG(*) FROM dbo.Kullanicilar
UNION ALL
SELECT N'Roller', COUNT_BIG(*) FROM dbo.Roller
UNION ALL
SELECT N'KullaniciRolleri', COUNT_BIG(*) FROM dbo.KullaniciRolleri
UNION ALL
SELECT N'DenetimKayitlari', COUNT_BIG(*) FROM dbo.DenetimKayitlari;

SELECT TabloAdi, KayitSayisi FROM @KayitSayilari ORDER BY TabloAdi;
DECLARE @Toplam BIGINT = (SELECT SUM(KayitSayisi) FROM @KayitSayilari);
SELECT @Toplam AS KesinToplamKayitSayisi;

IF (SELECT KayitSayisi FROM @KayitSayilari WHERE TabloAdi = N'EkipmanTurleri') < 10
OR (SELECT KayitSayisi FROM @KayitSayilari WHERE TabloAdi = N'Ekipmanlar') < 100
OR (SELECT KayitSayisi FROM @KayitSayilari WHERE TabloAdi = N'Sensorler') < 300
OR (SELECT KayitSayisi FROM @KayitSayilari WHERE TabloAdi = N'Olcumler') < 90000
    THROW 52006, N'Temel örnek veri hedefleri sağlanmıyor: 10 tür, 100 ekipman, 300 sensör, 90.000 ölçüm.', 1;

IF @OrnekVeriHedefiniZorunluTut = 1 AND @Toplam NOT BETWEEN 80000 AND 100000
    THROW 52007, N'Toplam kayıt sayısı örnek veri hedefinin (80.000-100.000) dışında.', 1;

IF EXISTS (SELECT EkipmanKodu FROM dbo.Ekipmanlar GROUP BY EkipmanKodu HAVING COUNT_BIG(*) > 1)
OR EXISTS (SELECT SensorKodu FROM dbo.Sensorler GROUP BY SensorKodu HAVING COUNT_BIG(*) > 1)
OR EXISTS (SELECT ParcaKodu FROM dbo.YedekParcalar GROUP BY ParcaKodu HAVING COUNT_BIG(*) > 1)
    THROW 52008, N'Tekrarlanan ekipman, sensör veya parça kodu bulundu.', 1;

/* DBCC mevcut satırları FK ve CHECK kurallarına göre inceler.
   Bu kontrol fiziksel CHECKDB veya bütün iş kurallarının kanıtı değildir. */
DECLARE @Ihlaller TABLE
(
    TabloAdi NVARCHAR(512),
    KisitAdi NVARCHAR(512),
    SatirKosulu NVARCHAR(MAX)
);
INSERT INTO @Ihlaller
EXEC sys.sp_executesql N'DBCC CHECKCONSTRAINTS WITH ALL_CONSTRAINTS, NO_INFOMSGS;';

IF EXISTS (SELECT 1 FROM @Ihlaller)
BEGIN
    SELECT * FROM @Ihlaller;
    THROW 52009, N'Mevcut kayıtlarda FK/CHECK ihlali bulundu.', 1;
END;

IF EXISTS
(
    SELECT ParcaNo FROM dbo.StokHareketleri
    GROUP BY ParcaNo
    HAVING SUM(CASE
        WHEN HareketTuru IN (N'Giriş', N'İade') THEN Miktar
        WHEN HareketTuru IN (N'Çıkış', N'Kullanım') THEN -Miktar
        ELSE 0
    END) < 0
)
    THROW 52010, N'Negatif stok bakiyesi bulundu.', 1;

IF EXISTS
(
    SELECT ArizaNo FROM dbo.BakimEmirleri
    WHERE ArizaNo IS NOT NULL
      AND BakimTuru = N'Düzeltici'
      AND Durum NOT IN (N'Tamamlandı', N'İptal Edildi')
    GROUP BY ArizaNo HAVING COUNT_BIG(*) > 1
)
    THROW 52011, N'Aynı arıza için birden fazla aktif düzeltici bakım emri bulundu.', 1;

IF EXISTS
(
    SELECT 1 FROM dbo.BakimEmirleri b
    INNER JOIN dbo.Arizalar a ON a.ArizaNo = b.ArizaNo
    WHERE a.EkipmanNo <> b.EkipmanNo
)
    THROW 52012, N'Bakım emri ile arızanın ekipmanları uyuşmuyor.', 1;

SELECT
    (SELECT COUNT(*) FROM @BeklenenNesneler WHERE NesneTuru = 'U') AS BeklenenTablo,
    (SELECT COUNT(*) FROM @BeklenenNesneler WHERE NesneTuru = 'V') AS BeklenenGorunum,
    (SELECT COUNT(*) FROM @BeklenenNesneler WHERE NesneTuru = 'P') AS BeklenenYordam,
    (SELECT COUNT(*) FROM @BeklenenNesneler WHERE NesneTuru = 'TR') AS BeklenenTetikleyici,
    @Toplam AS KesinToplamKayit;

PRINT N'BAŞARILI: Yapı, etkin kısıtlar, indeksler, örnek veri ve mevcut kayıt bütünlüğü kontrolleri geçti.';
GO
