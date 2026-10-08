/* Endüstriyel Bakım Yönetim Sistemi - normal T-SQL tam kurulum.
   SQLCMD modu, ROOT değişkeni veya bilgisayara özel dosya yolu gerekmez.
   01_Veritabani_Olusturma.sql ve 02_Tam_Kurulum_SQLCMD_Gerektirmez.sql
   aynı içeriği taşır; ikisinden yalnızca biri kullanılır.

   YALNIZCA İLK KURULUM:
   Var olan EndustriyelBakimDB korunur ve kurulum atlanır.
   Bu dosya var olan veritabanını yükseltme/onarım işlemi yapmaz.
   Otomatik DROP DATABASE, SINGLE_USER ve veri silme yoktur.
   Bütün dosyayı çalıştırın; seçili bölümler koruma kontrolünü atlayabilir.
   sqlcmd kullanılıyorsa -b ile ilk SQL hatasında durdurun. */

SET NOEXEC OFF;
GO
USE master;
GO
SET ANSI_NULLS ON;
SET QUOTED_IDENTIFIER ON;
SET ANSI_PADDING ON;
SET ANSI_WARNINGS ON;
SET ARITHABORT ON;
SET CONCAT_NULL_YIELDS_NULL ON;
SET NUMERIC_ROUNDABORT OFF;
GO

IF @@TRANCOUNT <> 0
BEGIN
    PRINT N'Kurulum atlandı: açık transaction bulunuyor. Yeni sorgu penceresi kullanın.';
    SET NOEXEC ON;
END;

IF DB_ID(N'EndustriyelBakimDB') IS NOT NULL
BEGIN
    PRINT N'KURULUM ATLANDI: EndustriyelBakimDB zaten var. Mevcut kayıtlar korundu.';
    PRINT N'Güncel doğrulama SQL dosyalarını çalıştırın; bu dosya yükseltme yapmaz.';
    SET NOEXEC ON;
END;
GO

CREATE DATABASE EndustriyelBakimDB;
GO

/* CREATE DATABASE başarısızsa aşağıdaki DDL master içinde çalışmasın. */
IF DB_ID(N'EndustriyelBakimDB') IS NULL
BEGIN
    PRINT N'KURULUM DURDU: Veritabanı oluşturulamadı. Önce üstteki SQL hatasını düzeltin.';
    SET NOEXEC ON;
END;
GO

USE EndustriyelBakimDB;
GO

-- BEGIN 702.02_Kodlama_Calismalari/02_Tablolar/01_EkipmanTurleri.sql
CREATE TABLE dbo.EkipmanTurleri
(

   TurNO INT IDENTITY(1,1) PRIMARY KEY,
   TurAdi NVARCHAR(50) NOT NULL UNIQUE,
   Aciklama NVARCHAR(250) NULL
   );
GO
-- END 702.02_Kodlama_Calismalari/02_Tablolar/01_EkipmanTurleri.sql
GO

-- BEGIN 702.02_Kodlama_Calismalari/02_Tablolar/02_Ekipmanlar.sql
CREATE TABLE dbo.Ekipmanlar
(
    EkipmanNo INT IDENTITY(1,1) PRIMARY KEY,
    TurNo INT NOT NULL,
    EkipmanKodu NVARCHAR(30) NOT NULL UNIQUE,
    EkipmanAdi NVARCHAR(100) NOT NULL,
    Konum NVARCHAR(150) NOT NULL,
    KurulumTarihi DATE NULL,
    Durum NVARCHAR(20) NOT NULL,

    CONSTRAINT FK_Ekipmanlar_EkipmanTurleri
        FOREIGN KEY (TurNo)
        REFERENCES dbo.EkipmanTurleri(TurNO)
);
GO
-- END 702.02_Kodlama_Calismalari/02_Tablolar/02_Ekipmanlar.sql
GO

-- BEGIN 702.02_Kodlama_Calismalari/02_Tablolar/03_Sensorler.sql
USE EndustriyelBakimDB;
GO

CREATE TABLE dbo.Sensorler
(
    SensorNo INT IDENTITY(1,1) PRIMARY KEY,
    EkipmanNo INT NOT NULL,
    SensorKodu NVARCHAR(30) NOT NULL UNIQUE,
    SensorTuru NVARCHAR(50) NOT NULL,
    OlcumBirimi NVARCHAR(20) NOT NULL,
    AltEsik DECIMAL(18,4) NOT NULL,
    UstEsik DECIMAL(18,4) NOT NULL,
    KurulumTarihi DATE NULL,
    Durum NVARCHAR(20) NOT NULL,

    CONSTRAINT FK_Sensorler_Ekipmanlar
        FOREIGN KEY (EkipmanNo)
        REFERENCES dbo.Ekipmanlar(EkipmanNo),

    CONSTRAINT CK_Sensorler_EsikAraligi
        CHECK (AltEsik < UstEsik)
);
GO
-- END 702.02_Kodlama_Calismalari/02_Tablolar/03_Sensorler.sql
GO

-- BEGIN 702.02_Kodlama_Calismalari/02_Tablolar/04_Olcumler.sql
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
GO
-- END 702.02_Kodlama_Calismalari/02_Tablolar/04_Olcumler.sql
GO

-- BEGIN 702.02_Kodlama_Calismalari/02_Tablolar/05_Alarmlar.sql
USE EndustriyelBakimDB;
GO

CREATE TABLE dbo.Alarmlar
(
    AlarmNo BIGINT IDENTITY(1,1) PRIMARY KEY,
    OlcumNo BIGINT NOT NULL,
    Seviye NVARCHAR(20) NOT NULL,
    Aciklama NVARCHAR(250) NOT NULL,
    Durum NVARCHAR(20) NOT NULL
        CONSTRAINT DF_Alarmlar_Durum DEFAULT N'Açık',
    AcilisZamani DATETIME2 NOT NULL
        CONSTRAINT DF_Alarmlar_AcilisZamani DEFAULT SYSDATETIME(),
    KapanisZamani DATETIME2 NULL,
    InceleyenKullaniciNo INT NULL,
    IncelemeZamani DATETIME2 NULL,
    IncelemeSonucu NVARCHAR(250) NULL,

    CONSTRAINT FK_Alarmlar_Olcumler
        FOREIGN KEY (OlcumNo)
        REFERENCES dbo.Olcumler(OlcumNo)
);
GO
GO
-- END 702.02_Kodlama_Calismalari/02_Tablolar/05_Alarmlar.sql
GO

-- BEGIN 702.02_Kodlama_Calismalari/02_Tablolar/06_BakimEmirleri.sql
USE EndustriyelBakimDB;
GO

-- Ekipmanlar için planlı ve arıza kaynaklı bakım işlerini kaydeder.
CREATE TABLE dbo.BakimEmirleri
(
    BakimEmriNo BIGINT IDENTITY(1,1) PRIMARY KEY,
    EkipmanNo INT NOT NULL,
    ArizaNo BIGINT NULL,
    BakimTuru NVARCHAR(30) NOT NULL,
    Aciklama NVARCHAR(500) NOT NULL,
    Oncelik NVARCHAR(20) NOT NULL,
    Durum NVARCHAR(30) NOT NULL
        CONSTRAINT DF_BakimEmirleri_Durum DEFAULT N'Bekliyor',
    OlusturmaZamani DATETIME2 NOT NULL
        CONSTRAINT DF_BakimEmirleri_Olusturma DEFAULT SYSDATETIME(),
    PlanlananBaslangic DATETIME2 NULL,
    GerceklesenBaslangic DATETIME2 NULL,
    TamamlanmaZamani DATETIME2 NULL,
    KontrolEdenKullaniciNo INT NULL,
    IptalOnaylayanKullaniciNo INT NULL,

    CONSTRAINT FK_BakimEmirleri_Ekipmanlar
        FOREIGN KEY (EkipmanNo)
        REFERENCES dbo.Ekipmanlar(EkipmanNo)
);
GO
GO
-- END 702.02_Kodlama_Calismalari/02_Tablolar/06_BakimEmirleri.sql
GO

-- BEGIN 702.02_Kodlama_Calismalari/02_Tablolar/07_Arizalar.sql
USE EndustriyelBakimDB;
GO

-- Ekipmanlarda oluşan arızaları ve arıza sürecini kaydeder.
CREATE TABLE dbo.Arizalar
(
    ArizaNo BIGINT IDENTITY(1,1) PRIMARY KEY,
    EkipmanNo INT NOT NULL,
    AlarmNo BIGINT NULL,
    ArizaAciklamasi NVARCHAR(500) NOT NULL,
    ArizaNedeni NVARCHAR(250) NULL,
    Oncelik NVARCHAR(20) NOT NULL,
    Durum NVARCHAR(20) NOT NULL
        CONSTRAINT DF_Arizalar_Durum DEFAULT N'Açık',
    AcilisZamani DATETIME2 NOT NULL
        CONSTRAINT DF_Arizalar_Acilis DEFAULT SYSDATETIME(),
    DogrulayanKullaniciNo INT NULL,
    DogrulamaZamani DATETIME2 NULL,
    KapatanKullaniciNo INT NULL,
    KapanisZamani DATETIME2 NULL,

    CONSTRAINT FK_Arizalar_Ekipmanlar
        FOREIGN KEY (EkipmanNo)
        REFERENCES dbo.Ekipmanlar(EkipmanNo),

    CONSTRAINT FK_Arizalar_Alarmlar
        FOREIGN KEY (AlarmNo)
        REFERENCES dbo.Alarmlar(AlarmNo)
);
GO
GO
-- END 702.02_Kodlama_Calismalari/02_Tablolar/07_Arizalar.sql
GO

-- BEGIN 702.02_Kodlama_Calismalari/02_Tablolar/08_Teknisyenler.sql
USE EndustriyelBakimDB;
GO

-- Bakım ve arıza işlemlerini gerçekleştiren teknisyenleri tutar.
CREATE TABLE dbo.Teknisyenler
(
    TeknisyenNo INT IDENTITY(1,1) PRIMARY KEY,
    SicilNo NVARCHAR(20) NOT NULL UNIQUE,
    AdSoyad NVARCHAR(100) NOT NULL,
    Uzmanlik NVARCHAR(100) NOT NULL,
    SaatlikUcret DECIMAL(12,2) NOT NULL,
    Durum NVARCHAR(20) NOT NULL
        CONSTRAINT DF_Teknisyenler_Durum DEFAULT N'Aktif'
);
GO
GO
-- END 702.02_Kodlama_Calismalari/02_Tablolar/08_Teknisyenler.sql
GO

-- BEGIN 702.02_Kodlama_Calismalari/02_Tablolar/09_BakimGorevlendirmeleri.sql
USE EndustriyelBakimDB;
GO

-- Bakım emirlerine hangi teknisyenin atandığını kaydeder.
CREATE TABLE dbo.BakimGorevlendirmeleri
(
    GorevlendirmeNo BIGINT IDENTITY(1,1) PRIMARY KEY,
    BakimEmriNo BIGINT NOT NULL,
    TeknisyenNo INT NOT NULL,
    AtamaZamani DATETIME2 NOT NULL
        CONSTRAINT DF_Gorevlendirmeler_Atama DEFAULT SYSDATETIME(),
    CalismaBaslangici DATETIME2 NULL,
    CalismaBitisi DATETIME2 NULL,
    IslemAnindakiSaatlikUcret DECIMAL(12,2) NOT NULL,
    YapilanIs NVARCHAR(500) NULL,

    CONSTRAINT FK_Gorevlendirmeler_BakimEmirleri
        FOREIGN KEY (BakimEmriNo)
        REFERENCES dbo.BakimEmirleri(BakimEmriNo),

    CONSTRAINT FK_Gorevlendirmeler_Teknisyenler
        FOREIGN KEY (TeknisyenNo)
        REFERENCES dbo.Teknisyenler(TeknisyenNo)
);
GO
GO
-- END 702.02_Kodlama_Calismalari/02_Tablolar/09_BakimGorevlendirmeleri.sql
GO

-- BEGIN 702.02_Kodlama_Calismalari/02_Tablolar/10_YedekParcalar.sql
USE EndustriyelBakimDB;
GO

-- Bakımlarda kullanılan yedek parçaların temel bilgilerini tutar.
CREATE TABLE dbo.YedekParcalar
(
    ParcaNo INT IDENTITY(1,1) PRIMARY KEY,
    ParcaKodu NVARCHAR(30) NOT NULL UNIQUE,
    ParcaAdi NVARCHAR(100) NOT NULL,
    OlcuBirimi NVARCHAR(20) NOT NULL,
    AsgariStok DECIMAL(18,4) NOT NULL,
    GuncelBirimMaliyet DECIMAL(12,2) NOT NULL
);
GO
GO
-- END 702.02_Kodlama_Calismalari/02_Tablolar/10_YedekParcalar.sql
GO

-- BEGIN 702.02_Kodlama_Calismalari/02_Tablolar/11_BakimParcalari.sql
USE EndustriyelBakimDB;
GO

-- Bir bakımda kullanılan veya iade edilen parçaları kaydeder.
CREATE TABLE dbo.BakimParcalari
(
    BakimParcaNo BIGINT IDENTITY(1,1) PRIMARY KEY,
    BakimEmriNo BIGINT NOT NULL,
    ParcaNo INT NOT NULL,
    IslemTuru NVARCHAR(20) NOT NULL,
    Miktar DECIMAL(18,4) NOT NULL,
    IslemAnindakiBirimMaliyet DECIMAL(12,2) NOT NULL,
    IslemZamani DATETIME2 NOT NULL
        CONSTRAINT DF_BakimParcalari_Islem DEFAULT SYSDATETIME(),
    KullaniciNo INT NULL,
    IadeEdilenKullanimNo BIGINT NULL,

    CONSTRAINT FK_BakimParcalari_BakimEmirleri
        FOREIGN KEY (BakimEmriNo)
        REFERENCES dbo.BakimEmirleri(BakimEmriNo),

    CONSTRAINT FK_BakimParcalari_YedekParcalar
        FOREIGN KEY (ParcaNo)
        REFERENCES dbo.YedekParcalar(ParcaNo),

    CONSTRAINT FK_BakimParcalari_Iade
        FOREIGN KEY (IadeEdilenKullanimNo)
        REFERENCES dbo.BakimParcalari(BakimParcaNo)
);
GO
GO
-- END 702.02_Kodlama_Calismalari/02_Tablolar/11_BakimParcalari.sql
GO

-- BEGIN 702.02_Kodlama_Calismalari/02_Tablolar/12_StokHareketleri.sql
USE EndustriyelBakimDB;
GO

-- Parçaların stok giriş, çıkış, kullanım ve iade hareketlerini tutar.
CREATE TABLE dbo.StokHareketleri
(
    StokHareketNo BIGINT IDENTITY(1,1) PRIMARY KEY,
    ParcaNo INT NOT NULL,
    BakimParcaNo BIGINT NULL,
    HareketTuru NVARCHAR(20) NOT NULL,
    Miktar DECIMAL(18,4) NOT NULL,
    BirimMaliyet DECIMAL(12,2) NULL,
    HareketZamani DATETIME2 NOT NULL
        CONSTRAINT DF_StokHareketleri_Zaman DEFAULT SYSDATETIME(),
    KullaniciNo INT NULL,
    Aciklama NVARCHAR(250) NULL,

    CONSTRAINT FK_StokHareketleri_YedekParcalar
        FOREIGN KEY (ParcaNo)
        REFERENCES dbo.YedekParcalar(ParcaNo),

    CONSTRAINT FK_StokHareketleri_BakimParcalari
        FOREIGN KEY (BakimParcaNo)
        REFERENCES dbo.BakimParcalari(BakimParcaNo)
);
GO
GO
-- END 702.02_Kodlama_Calismalari/02_Tablolar/12_StokHareketleri.sql
GO

-- BEGIN 702.02_Kodlama_Calismalari/02_Tablolar/13_DurusKayitlari.sql
USE EndustriyelBakimDB;
GO

-- Ekipmanların çalışmadığı süreleri kaydeder.
CREATE TABLE dbo.DurusKayitlari
(
    DurusNo BIGINT IDENTITY(1,1) PRIMARY KEY,
    EkipmanNo INT NOT NULL,
    ArizaNo BIGINT NULL,
    BaslangicZamani DATETIME2 NOT NULL,
    BitisZamani DATETIME2 NULL,
    DurusNedeni NVARCHAR(250) NOT NULL,

    CONSTRAINT FK_DurusKayitlari_Ekipmanlar
        FOREIGN KEY (EkipmanNo)
        REFERENCES dbo.Ekipmanlar(EkipmanNo),

    CONSTRAINT FK_DurusKayitlari_Arizalar
        FOREIGN KEY (ArizaNo)
        REFERENCES dbo.Arizalar(ArizaNo)
);
GO
GO
-- END 702.02_Kodlama_Calismalari/02_Tablolar/13_DurusKayitlari.sql
GO

-- BEGIN 702.02_Kodlama_Calismalari/02_Tablolar/14_Kullanicilar.sql
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
GO
-- END 702.02_Kodlama_Calismalari/02_Tablolar/14_Kullanicilar.sql
GO

-- BEGIN 702.02_Kodlama_Calismalari/02_Tablolar/15_Roller.sql
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
GO
-- END 702.02_Kodlama_Calismalari/02_Tablolar/15_Roller.sql
GO

-- BEGIN 702.02_Kodlama_Calismalari/02_Tablolar/16_KullaniciRolleri.sql
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
GO
-- END 702.02_Kodlama_Calismalari/02_Tablolar/16_KullaniciRolleri.sql
GO

-- BEGIN 702.02_Kodlama_Calismalari/02_Tablolar/17_DenetimKayitlari.sql
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
GO
-- END 702.02_Kodlama_Calismalari/02_Tablolar/17_DenetimKayitlari.sql
GO

-- BEGIN 702.02_Kodlama_Calismalari/03_Kisitlar/01_Veri_Butunlugu_Kisitlari.sql
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

/* EKSİK TABLO BAĞLANTILARI */

ALTER TABLE dbo.Alarmlar
ADD CONSTRAINT FK_Alarmlar_Kullanicilar
FOREIGN KEY (InceleyenKullaniciNo)
REFERENCES dbo.Kullanicilar(KullaniciNo);
GO

ALTER TABLE dbo.BakimEmirleri
ADD CONSTRAINT FK_BakimEmirleri_Arizalar
FOREIGN KEY (ArizaNo)
REFERENCES dbo.Arizalar(ArizaNo);
GO

ALTER TABLE dbo.BakimEmirleri
ADD CONSTRAINT FK_BakimEmirleri_KontrolKullanicisi
FOREIGN KEY (KontrolEdenKullaniciNo)
REFERENCES dbo.Kullanicilar(KullaniciNo);
GO

ALTER TABLE dbo.BakimEmirleri
ADD CONSTRAINT FK_BakimEmirleri_IptalKullanicisi
FOREIGN KEY (IptalOnaylayanKullaniciNo)
REFERENCES dbo.Kullanicilar(KullaniciNo);
GO

ALTER TABLE dbo.Arizalar
ADD CONSTRAINT FK_Arizalar_DogrulayanKullanici
FOREIGN KEY (DogrulayanKullaniciNo)
REFERENCES dbo.Kullanicilar(KullaniciNo);
GO

ALTER TABLE dbo.Arizalar
ADD CONSTRAINT FK_Arizalar_KapatanKullanici
FOREIGN KEY (KapatanKullaniciNo)
REFERENCES dbo.Kullanicilar(KullaniciNo);
GO

ALTER TABLE dbo.BakimParcalari
ADD CONSTRAINT FK_BakimParcalari_Kullanicilar
FOREIGN KEY (KullaniciNo)
REFERENCES dbo.Kullanicilar(KullaniciNo);
GO

ALTER TABLE dbo.StokHareketleri
ADD CONSTRAINT FK_StokHareketleri_Kullanicilar
FOREIGN KEY (KullaniciNo)
REFERENCES dbo.Kullanicilar(KullaniciNo);
GO

/* HATALI VERİLERİ ENGELLEYEN KURALLAR */

ALTER TABLE dbo.Alarmlar
ADD CONSTRAINT CK_Alarmlar_Seviye
CHECK (Seviye IN (N'Bilgi', N'Uyarı', N'Kritik'));
GO

ALTER TABLE dbo.Alarmlar
ADD CONSTRAINT CK_Alarmlar_Durum
CHECK (Durum IN (N'Açık', N'İncelendi', N'Kapalı'));
GO

ALTER TABLE dbo.Alarmlar
ADD CONSTRAINT CK_Alarmlar_Tarih
CHECK (KapanisZamani IS NULL OR KapanisZamani >= AcilisZamani);
GO

ALTER TABLE dbo.BakimEmirleri
ADD CONSTRAINT CK_BakimEmirleri_Tur
CHECK (BakimTuru IN (N'Planlı', N'Düzeltici', N'Önleyici'));
GO

ALTER TABLE dbo.BakimEmirleri
ADD CONSTRAINT CK_BakimEmirleri_Oncelik
CHECK (Oncelik IN (N'Düşük', N'Orta', N'Yüksek', N'Kritik'));
GO

ALTER TABLE dbo.BakimEmirleri
ADD CONSTRAINT CK_BakimEmirleri_Durum
CHECK
(
    Durum IN
    (
        N'Bekliyor',
        N'Atandı',
        N'Devam Ediyor',
        N'Tamamlandı',
        N'İptal Edildi'
    )
);
GO

ALTER TABLE dbo.BakimEmirleri
ADD CONSTRAINT CK_BakimEmirleri_Tarih
CHECK
(
    GerceklesenBaslangic IS NULL
    OR TamamlanmaZamani IS NULL
    OR TamamlanmaZamani >= GerceklesenBaslangic
);
GO

ALTER TABLE dbo.Arizalar
ADD CONSTRAINT CK_Arizalar_Oncelik
CHECK (Oncelik IN (N'Düşük', N'Orta', N'Yüksek', N'Kritik'));
GO

ALTER TABLE dbo.Arizalar
ADD CONSTRAINT CK_Arizalar_Durum
CHECK (Durum IN (N'Açık', N'Doğrulandı', N'Çözüldü', N'Kapalı'));
GO

ALTER TABLE dbo.Arizalar
ADD CONSTRAINT CK_Arizalar_Tarih
CHECK (KapanisZamani IS NULL OR KapanisZamani >= AcilisZamani);
GO

ALTER TABLE dbo.Teknisyenler
ADD CONSTRAINT CK_Teknisyenler_Ucret
CHECK (SaatlikUcret >= 0);
GO

ALTER TABLE dbo.Teknisyenler
ADD CONSTRAINT CK_Teknisyenler_Durum
CHECK (Durum IN (N'Aktif', N'Pasif', N'İzinli'));
GO

ALTER TABLE dbo.BakimGorevlendirmeleri
ADD CONSTRAINT CK_Gorevlendirmeler_Ucret
CHECK (IslemAnindakiSaatlikUcret >= 0);
GO

ALTER TABLE dbo.BakimGorevlendirmeleri
ADD CONSTRAINT CK_Gorevlendirmeler_Tarih
CHECK
(
    CalismaBaslangici IS NULL
    OR CalismaBitisi IS NULL
    OR CalismaBitisi >= CalismaBaslangici
);
GO

ALTER TABLE dbo.YedekParcalar
ADD CONSTRAINT CK_YedekParcalar_Stok
CHECK (AsgariStok >= 0);
GO

ALTER TABLE dbo.YedekParcalar
ADD CONSTRAINT CK_YedekParcalar_Maliyet
CHECK (GuncelBirimMaliyet >= 0);
GO

ALTER TABLE dbo.BakimParcalari
ADD CONSTRAINT CK_BakimParcalari_Tur
CHECK (IslemTuru IN (N'Kullanım', N'İade'));
GO

ALTER TABLE dbo.BakimParcalari
ADD CONSTRAINT CK_BakimParcalari_Miktar
CHECK (Miktar > 0);
GO

ALTER TABLE dbo.BakimParcalari
ADD CONSTRAINT CK_BakimParcalari_Maliyet
CHECK (IslemAnindakiBirimMaliyet >= 0);
GO

ALTER TABLE dbo.StokHareketleri
ADD CONSTRAINT CK_StokHareketleri_Tur
CHECK
(
    HareketTuru IN
    (
        N'Giriş',
        N'Çıkış',
        N'Kullanım',
        N'İade',
        N'Düzeltme'
    )
);
GO

ALTER TABLE dbo.StokHareketleri
ADD CONSTRAINT CK_StokHareketleri_Miktar
CHECK (Miktar > 0);
GO

ALTER TABLE dbo.StokHareketleri
ADD CONSTRAINT CK_StokHareketleri_Maliyet
CHECK (BirimMaliyet IS NULL OR BirimMaliyet >= 0);
GO

ALTER TABLE dbo.DurusKayitlari
ADD CONSTRAINT CK_DurusKayitlari_Tarih
CHECK (BitisZamani IS NULL OR BitisZamani >= BaslangicZamani);
GO

ALTER TABLE dbo.DenetimKayitlari
ADD CONSTRAINT CK_DenetimKayitlari_Islem
CHECK (IslemTuru IN (N'INSERT', N'UPDATE', N'DELETE'));
GO

/* TEKRARLANAN KAYITLARI ENGELLEYEN KURALLAR */

ALTER TABLE dbo.Alarmlar
ADD CONSTRAINT UQ_Alarmlar_OlcumNo
UNIQUE (OlcumNo);
GO

CREATE UNIQUE INDEX UX_Arizalar_AlarmNo
ON dbo.Arizalar(AlarmNo)
WHERE AlarmNo IS NOT NULL;
GO

ALTER TABLE dbo.Kullanicilar
DROP CONSTRAINT UQ_Kullanicilar_TeknisyenNo;
GO

CREATE UNIQUE INDEX UX_Kullanicilar_TeknisyenNo
ON dbo.Kullanicilar(TeknisyenNo)
WHERE TeknisyenNo IS NOT NULL;
GO
GO
-- END 702.02_Kodlama_Calismalari/03_Kisitlar/01_Veri_Butunlugu_Kisitlari.sql
GO

-- BEGIN 702.02_Kodlama_Calismalari/04_Ornek_Veriler/01_EkipmanTurleri_Ornek_Veriler.sql
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

-- Sistemde kullanılacak ekipman türlerini ekler.
INSERT INTO dbo.EkipmanTurleri (TurAdi, Aciklama)
SELECT v.TurAdi, v.Aciklama
FROM
(
    VALUES
    (N'Pompa', N'Sıvı aktarım pompaları'),
    (N'Motor', N'Elektrik motorları'),
    (N'Kompresör', N'Basınçlı hava sistemleri'),
    (N'Jeneratör', N'Elektrik üretim sistemleri'),
    (N'Konveyör', N'Malzeme taşıma sistemleri'),
    (N'Kazan', N'Endüstriyel ısıtma sistemleri'),
    (N'Fan', N'Havalandırma sistemleri'),
    (N'Torna', N'Talaşlı üretim makineleri'),
    (N'Freze', N'Endüstriyel freze makineleri'),
    (N'Robot', N'Endüstriyel üretim robotları')
) v(TurAdi, Aciklama)
WHERE NOT EXISTS
(
    SELECT 1
    FROM dbo.EkipmanTurleri e
    WHERE e.TurAdi = v.TurAdi
);
GO
GO
-- END 702.02_Kodlama_Calismalari/04_Ornek_Veriler/01_EkipmanTurleri_Ornek_Veriler.sql
GO

-- BEGIN 702.02_Kodlama_Calismalari/04_Ornek_Veriler/02_Ekipmanlar_Ornek_Veriler.sql
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

-- Otomatik olarak 100 ekipman oluşturur.
WITH Sayilar AS
(
    SELECT TOP (100)
        ROW_NUMBER() OVER (ORDER BY (SELECT NULL)) AS Sira
    FROM sys.all_objects
),
Turler AS
(
    SELECT
        TurNo,
        TurAdi,
        ROW_NUMBER() OVER (ORDER BY TurNo) AS TurSirasi,
        COUNT(*) OVER () AS TurSayisi
    FROM dbo.EkipmanTurleri
)
INSERT INTO dbo.Ekipmanlar
(
    TurNo,
    EkipmanKodu,
    EkipmanAdi,
    Konum,
    KurulumTarihi,
    Durum
)
SELECT
    t.TurNo,
    CONCAT(N'EKP-', RIGHT(N'000' + CAST(s.Sira AS NVARCHAR(3)), 3)),
    CONCAT(t.TurAdi, N' ', s.Sira),
    CONCAT(N'Üretim Bölgesi ', ((s.Sira - 1) % 10) + 1),
    DATEADD(DAY, -(s.Sira * 20), CAST(GETDATE() AS DATE)),
    CASE
        WHEN s.Sira % 20 = 0 THEN N'Bakımda'
        WHEN s.Sira % 25 = 0 THEN N'Pasif'
        ELSE N'Aktif'
    END
FROM Sayilar s
INNER JOIN Turler t
    ON t.TurSirasi = ((s.Sira - 1) % t.TurSayisi) + 1
WHERE NOT EXISTS
(
    SELECT 1
    FROM dbo.Ekipmanlar e
    WHERE e.EkipmanKodu =
        CONCAT(N'EKP-', RIGHT(N'000' + CAST(s.Sira AS NVARCHAR(3)), 3))
);
GO
GO
-- END 702.02_Kodlama_Calismalari/04_Ornek_Veriler/02_Ekipmanlar_Ornek_Veriler.sql
GO

-- BEGIN 702.02_Kodlama_Calismalari/04_Ornek_Veriler/03_Sensorler_Ornek_Veriler.sql
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

-- Her ekipmana üç sensör ekler: sıcaklık, titreşim ve basınç.
WITH SecilenEkipmanlar AS
(
    SELECT TOP (100)
        EkipmanNo,
        EkipmanKodu,
        KurulumTarihi
    FROM dbo.Ekipmanlar
    ORDER BY EkipmanNo
)
INSERT INTO dbo.Sensorler
(
    EkipmanNo,
    SensorKodu,
    SensorTuru,
    OlcumBirimi,
    AltEsik,
    UstEsik,
    KurulumTarihi,
    Durum
)
SELECT
    e.EkipmanNo,
    CONCAT(N'SNS-', e.EkipmanKodu, N'-', s.Sira),
    s.SensorTuru,
    s.OlcumBirimi,
    s.AltEsik,
    s.UstEsik,
    DATEADD(DAY, 30, e.KurulumTarihi),
    N'Aktif'
FROM SecilenEkipmanlar e
CROSS JOIN
(
    VALUES
    (1, N'Sıcaklık', N'°C', 0.0000, 80.0000),
    (2, N'Titreşim', N'mm/s', 0.0000, 12.0000),
    (3, N'Basınç', N'bar', 0.0000, 10.0000)
) s(Sira, SensorTuru, OlcumBirimi, AltEsik, UstEsik)
WHERE NOT EXISTS
(
    SELECT 1
    FROM dbo.Sensorler x
    WHERE x.SensorKodu =
        CONCAT(N'SNS-', e.EkipmanKodu, N'-', s.Sira)
);
GO
GO
-- END 702.02_Kodlama_Calismalari/04_Ornek_Veriler/03_Sensorler_Ornek_Veriler.sql
GO

-- BEGIN 702.02_Kodlama_Calismalari/04_Ornek_Veriler/04_Toplu_Veri_Uretimi.sql
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

/* ROLLER */

INSERT INTO dbo.Roller (RolAdi, SqlRolAdi, Aciklama)
SELECT v.RolAdi, v.SqlRolAdi, v.Aciklama
FROM
(
    VALUES
    (N'Yönetici', N'rol_yonetici', N'Sistem yönetimi'),
    (N'Bakım Yöneticisi', N'rol_bakim_yoneticisi', N'Bakım süreçleri yönetimi'),
    (N'Teknisyen', N'rol_teknisyen', N'Bakım işlemleri'),
    (N'Denetçi', N'rol_denetci', N'Denetim kayıtlarını görüntüleme')
) v(RolAdi, SqlRolAdi, Aciklama)
WHERE NOT EXISTS
(
    SELECT 1 FROM dbo.Roller r WHERE r.RolAdi = v.RolAdi
);

/* 20 TEKNİSYEN */

WITH Sayilar AS
(
    SELECT TOP (20)
        ROW_NUMBER() OVER (ORDER BY (SELECT NULL)) AS Sira
    FROM sys.all_objects
)
INSERT INTO dbo.Teknisyenler
(
    SicilNo,
    AdSoyad,
    Uzmanlik,
    SaatlikUcret,
    Durum
)
SELECT
    CONCAT(N'TKN-', RIGHT(N'000' + CAST(Sira AS NVARCHAR(3)), 3)),
    CONCAT(N'Teknisyen ', Sira),
    CASE Sira % 4
        WHEN 0 THEN N'Elektrik'
        WHEN 1 THEN N'Mekanik'
        WHEN 2 THEN N'Otomasyon'
        ELSE N'Elektronik'
    END,
    250 + (Sira * 10),
    N'Aktif'
FROM Sayilar
WHERE NOT EXISTS
(
    SELECT 1
    FROM dbo.Teknisyenler t
    WHERE t.SicilNo =
        CONCAT(N'TKN-', RIGHT(N'000' + CAST(Sira AS NVARCHAR(3)), 3))
);

/* KULLANICILAR */

INSERT INTO dbo.Kullanicilar
(
    TeknisyenNo,
    SqlKullaniciAdi,
    AdSoyad
)
SELECT
    t.TeknisyenNo,
    CONCAT(N'teknisyen_', t.SicilNo),
    t.AdSoyad
FROM dbo.Teknisyenler t
WHERE NOT EXISTS
(
    SELECT 1
    FROM dbo.Kullanicilar k
    WHERE k.TeknisyenNo = t.TeknisyenNo
);

INSERT INTO dbo.Kullanicilar
(
    SqlKullaniciAdi,
    AdSoyad
)
SELECT N'sistem_yoneticisi', N'Sistem Yöneticisi'
WHERE NOT EXISTS
(
    SELECT 1 FROM dbo.Kullanicilar
    WHERE SqlKullaniciAdi = N'sistem_yoneticisi'
);

INSERT INTO dbo.Kullanicilar
(
    SqlKullaniciAdi,
    AdSoyad
)
SELECT N'bakim_yoneticisi', N'Bakım Yöneticisi'
WHERE NOT EXISTS
(
    SELECT 1 FROM dbo.Kullanicilar
    WHERE SqlKullaniciAdi = N'bakim_yoneticisi'
);

INSERT INTO dbo.Kullanicilar
(
    SqlKullaniciAdi,
    AdSoyad
)
SELECT N'denetci', N'Sistem Denetçisi'
WHERE NOT EXISTS
(
    SELECT 1 FROM dbo.Kullanicilar
    WHERE SqlKullaniciAdi = N'denetci'
);

/* KULLANICI ROLLERİ */

INSERT INTO dbo.KullaniciRolleri (KullaniciNo, RolNo)
SELECT
    k.KullaniciNo,
    r.RolNo
FROM dbo.Kullanicilar k
INNER JOIN dbo.Roller r
    ON r.RolAdi =
        CASE
            WHEN k.SqlKullaniciAdi = N'sistem_yoneticisi'
                THEN N'Yönetici'
            WHEN k.SqlKullaniciAdi = N'bakim_yoneticisi'
                THEN N'Bakım Yöneticisi'
            WHEN k.SqlKullaniciAdi = N'denetci'
                THEN N'Denetçi'
            ELSE N'Teknisyen'
        END
WHERE NOT EXISTS
(
    SELECT 1
    FROM dbo.KullaniciRolleri kr
    WHERE kr.KullaniciNo = k.KullaniciNo
      AND kr.RolNo = r.RolNo
);

/* 50 YEDEK PARÇA */

WITH Sayilar AS
(
    SELECT TOP (50)
        ROW_NUMBER() OVER (ORDER BY (SELECT NULL)) AS Sira
    FROM sys.all_objects
)
INSERT INTO dbo.YedekParcalar
(
    ParcaKodu,
    ParcaAdi,
    OlcuBirimi,
    AsgariStok,
    GuncelBirimMaliyet
)
SELECT
    CONCAT(N'PRC-', RIGHT(N'000' + CAST(Sira AS NVARCHAR(3)), 3)),
    CONCAT(N'Yedek Parça ', Sira),
    N'Adet',
    10,
    100 + (Sira * 25)
FROM Sayilar
WHERE NOT EXISTS
(
    SELECT 1
    FROM dbo.YedekParcalar p
    WHERE p.ParcaKodu =
        CONCAT(N'PRC-', RIGHT(N'000' + CAST(Sira AS NVARCHAR(3)), 3))
);

/* 90.000 ÖLÇÜM */

DECLARE @EksikOlcum INT;

SELECT @EksikOlcum =
    CASE
        WHEN COUNT_BIG(*) >= 90000 THEN 0
        ELSE 90000 - CONVERT(INT, COUNT_BIG(*))
    END
FROM dbo.Olcumler;

IF @EksikOlcum > 0
BEGIN
    WITH SensorListesi AS
    (
        SELECT TOP (300)
            SensorNo,
            AltEsik,
            UstEsik,
            ROW_NUMBER() OVER (ORDER BY SensorNo) AS SensorSirasi
        FROM dbo.Sensorler
        ORDER BY SensorNo
    ),
    Sayilar AS
    (
        SELECT TOP (300)
            ROW_NUMBER() OVER (ORDER BY (SELECT NULL)) AS Sira
        FROM sys.all_objects
    )
    INSERT INTO dbo.Olcumler
    (
        SensorNo,
        OlcumDegeri,
        OlcumZamani
    )
    SELECT TOP (@EksikOlcum)
        s.SensorNo,
        CAST
        (
            CASE
                WHEN n.Sira % 45 = 0
                    THEN s.UstEsik + 5 + (n.Sira % 10)
                ELSE
                    s.AltEsik +
                    ((s.UstEsik - s.AltEsik) *
                    (20 + (n.Sira % 60)) / 100.0)
            END
            AS DECIMAL(18,4)
        ),
        DATEADD
        (
            MINUTE,
            -CONVERT(INT, ((300 - n.Sira) * 432) + s.SensorSirasi),
            SYSDATETIME()
        )
    FROM SensorListesi s
    CROSS JOIN Sayilar n
    ORDER BY s.SensorNo, n.Sira;
END;

/* 1.000 ALARM */

DECLARE @EksikAlarm INT =
    CASE
        WHEN (SELECT COUNT(*) FROM dbo.Alarmlar) >= 1000 THEN 0
        ELSE 1000 - (SELECT COUNT(*) FROM dbo.Alarmlar)
    END;

IF @EksikAlarm > 0
BEGIN
    INSERT INTO dbo.Alarmlar
    (
        OlcumNo,
        Seviye,
        Aciklama,
        Durum,
        AcilisZamani
    )
    SELECT TOP (@EksikAlarm)
        o.OlcumNo,
        N'Kritik',
        N'Sensör değeri üst eşik değerini aşmıştır.',
        N'Açık',
        o.OlcumZamani
    FROM dbo.Olcumler o
    INNER JOIN dbo.Sensorler s
        ON s.SensorNo = o.SensorNo
    WHERE o.OlcumDegeri > s.UstEsik
      AND NOT EXISTS
      (
          SELECT 1 FROM dbo.Alarmlar a
          WHERE a.OlcumNo = o.OlcumNo
      )
    ORDER BY o.OlcumZamani;
END;

/* 500 ARIZA */

DECLARE @EksikAriza INT =
    CASE
        WHEN (SELECT COUNT(*) FROM dbo.Arizalar) >= 500 THEN 0
        ELSE 500 - (SELECT COUNT(*) FROM dbo.Arizalar)
    END;

IF @EksikAriza > 0
BEGIN
    INSERT INTO dbo.Arizalar
    (
        EkipmanNo,
        AlarmNo,
        ArizaAciklamasi,
        ArizaNedeni,
        Oncelik,
        Durum,
        AcilisZamani
    )
    SELECT TOP (@EksikAriza)
        s.EkipmanNo,
        a.AlarmNo,
        N'Kritik sensör alarmı sonucunda arıza oluşturuldu.',
        N'Ölçüm değerinin güvenli çalışma sınırını aşması',
        N'Yüksek',
        N'Açık',
        a.AcilisZamani
    FROM dbo.Alarmlar a
    INNER JOIN dbo.Olcumler o
        ON o.OlcumNo = a.OlcumNo
    INNER JOIN dbo.Sensorler s
        ON s.SensorNo = o.SensorNo
    WHERE NOT EXISTS
    (
        SELECT 1 FROM dbo.Arizalar x
        WHERE x.AlarmNo = a.AlarmNo
    )
    ORDER BY a.AlarmNo;
END;

/* 500 DÜZELTİCİ BAKIM EMRİ */

INSERT INTO dbo.BakimEmirleri
(
    EkipmanNo,
    ArizaNo,
    BakimTuru,
    Aciklama,
    Oncelik,
    Durum
)
SELECT
    a.EkipmanNo,
    a.ArizaNo,
    N'Düzeltici',
    N'Arızanın giderilmesi için oluşturulan bakım emri.',
    a.Oncelik,
    N'Bekliyor'
FROM dbo.Arizalar a
WHERE NOT EXISTS
(
    SELECT 1
    FROM dbo.BakimEmirleri b
    WHERE b.ArizaNo = a.ArizaNo
);

/* 200 PLANLI BAKIM EMRİ */

WITH Sayilar AS
(
    SELECT 1 AS Sira
    UNION ALL
    SELECT 2
),
Adaylar AS
(
    SELECT
        e.EkipmanNo,
        ROW_NUMBER() OVER (ORDER BY e.EkipmanNo, s.Sira) AS Sira
    FROM
    (
        SELECT TOP (100) EkipmanNo
        FROM dbo.Ekipmanlar
        ORDER BY EkipmanNo
    ) e
    CROSS JOIN Sayilar s
)
INSERT INTO dbo.BakimEmirleri
(
    EkipmanNo,
    BakimTuru,
    Aciklama,
    Oncelik,
    Durum
)
SELECT
    EkipmanNo,
    N'Planlı',
    CONCAT(N'Planlı bakım çalışması ', Sira),
    N'Orta',
    N'Bekliyor'
FROM Adaylar a
WHERE NOT EXISTS
(
    SELECT 1
    FROM dbo.BakimEmirleri b
    WHERE b.ArizaNo IS NULL
      AND b.Aciklama = CONCAT(N'Planlı bakım çalışması ', a.Sira)
);

/* TEKNİSYEN GÖREVLENDİRMELERİ */

WITH Emirler AS
(
    SELECT TOP (700)
        BakimEmriNo,
        ROW_NUMBER() OVER (ORDER BY BakimEmriNo) AS Sira
    FROM dbo.BakimEmirleri
    ORDER BY BakimEmriNo
),
TeknisyenListesi AS
(
    SELECT
        TeknisyenNo,
        SaatlikUcret,
        ROW_NUMBER() OVER (ORDER BY TeknisyenNo) AS Sira,
        COUNT(*) OVER () AS Toplam
    FROM dbo.Teknisyenler
)
INSERT INTO dbo.BakimGorevlendirmeleri
(
    BakimEmriNo,
    TeknisyenNo,
    IslemAnindakiSaatlikUcret
)
SELECT
    e.BakimEmriNo,
    t.TeknisyenNo,
    t.SaatlikUcret
FROM Emirler e
INNER JOIN TeknisyenListesi t
    ON t.Sira = ((e.Sira - 1) % t.Toplam) + 1
WHERE NOT EXISTS
(
    SELECT 1
    FROM dbo.BakimGorevlendirmeleri g
    WHERE g.BakimEmriNo = e.BakimEmriNo
);

/* 300 DURUŞ KAYDI */

INSERT INTO dbo.DurusKayitlari
(
    EkipmanNo,
    ArizaNo,
    BaslangicZamani,
    BitisZamani,
    DurusNedeni
)
SELECT TOP (300)
    a.EkipmanNo,
    a.ArizaNo,
    a.AcilisZamani,
    DATEADD(HOUR, 2 + (a.ArizaNo % 24), a.AcilisZamani),
    N'Arıza nedeniyle ekipman duruşu'
FROM dbo.Arizalar a
WHERE NOT EXISTS
(
    SELECT 1
    FROM dbo.DurusKayitlari d
    WHERE d.ArizaNo = a.ArizaNo
)
ORDER BY a.ArizaNo;

PRINT N'Toplu örnek veri üretimi tamamlandı.';
PRINT N'Hedef: 100 ekipman, 300 sensör ve 90.000 ölçüm.';
GO
/* BAŞLANGIÇ STOKLARI */

INSERT INTO dbo.StokHareketleri
(
    ParcaNo,
    HareketTuru,
    Miktar,
    BirimMaliyet,
    KullaniciNo,
    Aciklama
)
SELECT
    p.ParcaNo,
    N'Giriş',
    500,
    p.GuncelBirimMaliyet,
    (SELECT TOP (1) KullaniciNo
     FROM dbo.Kullanicilar
     WHERE Aktif = 1
     ORDER BY KullaniciNo),
    N'Başlangıç stok kaydı'
FROM dbo.YedekParcalar p
WHERE NOT EXISTS
(
    SELECT 1
    FROM dbo.StokHareketleri h
    WHERE h.ParcaNo = p.ParcaNo
      AND h.Aciklama = N'Başlangıç stok kaydı'
);
GO

/* 600 BAKIM PARÇASI KULLANIMI */

WITH Emirler AS
(
    SELECT TOP (600)
        BakimEmriNo,
        ROW_NUMBER() OVER (ORDER BY BakimEmriNo) AS Sira
    FROM dbo.BakimEmirleri
    ORDER BY BakimEmriNo
),
Parcalar AS
(
    SELECT
        ParcaNo,
        GuncelBirimMaliyet,
        ROW_NUMBER() OVER (ORDER BY ParcaNo) AS Sira,
        COUNT(*) OVER () AS Toplam
    FROM dbo.YedekParcalar
)
INSERT INTO dbo.BakimParcalari
(
    BakimEmriNo,
    ParcaNo,
    IslemTuru,
    Miktar,
    IslemAnindakiBirimMaliyet,
    KullaniciNo
)
SELECT
    e.BakimEmriNo,
    p.ParcaNo,
    N'Kullanım',
    1 + (e.Sira % 5),
    p.GuncelBirimMaliyet,
    (SELECT TOP (1) KullaniciNo
     FROM dbo.Kullanicilar
     WHERE Aktif = 1
     ORDER BY KullaniciNo)
FROM Emirler e
INNER JOIN Parcalar p
    ON p.Sira = ((e.Sira - 1) % p.Toplam) + 1
WHERE NOT EXISTS
(
    SELECT 1
    FROM dbo.BakimParcalari bp
    WHERE bp.BakimEmriNo = e.BakimEmriNo
);
GO

/* PARÇA KULLANIMLARINI STOK HAREKETİNE DÖNÜŞTÜRÜR */

INSERT INTO dbo.StokHareketleri
(
    ParcaNo,
    BakimParcaNo,
    HareketTuru,
    Miktar,
    BirimMaliyet,
    KullaniciNo,
    Aciklama
)
SELECT
    bp.ParcaNo,
    bp.BakimParcaNo,
    N'Kullanım',
    bp.Miktar,
    bp.IslemAnindakiBirimMaliyet,
    bp.KullaniciNo,
    N'Örnek bakım parçası kullanımı'
FROM dbo.BakimParcalari bp
WHERE NOT EXISTS
(
    SELECT 1
    FROM dbo.StokHareketleri h
    WHERE h.BakimParcaNo = bp.BakimParcaNo
);
GO

/* ARIZA ALARMLARINI İNCELENMİŞ DURUMA GETİRİR */

UPDATE a
SET
    Durum = N'İncelendi',
    InceleyenKullaniciNo =
    (
        SELECT TOP (1) KullaniciNo
        FROM dbo.Kullanicilar
        WHERE Aktif = 1
        ORDER BY KullaniciNo
    ),
    IncelemeZamani = DATEADD(MINUTE, 5, a.AcilisZamani),
    IncelemeSonucu = N'Alarm incelendi ve arıza doğrulandı.'
FROM dbo.Alarmlar a
WHERE EXISTS
(
    SELECT 1
    FROM dbo.Arizalar ar
    WHERE ar.AlarmNo = a.AlarmNo
)
AND a.IncelemeZamani IS NULL;
GO

/* 300 TAMAMLANMIŞ BAKIM VE ARIZA KAYDI */

WITH Tamamlanacaklar AS
(
    SELECT TOP (300) BakimEmriNo
    FROM dbo.BakimEmirleri
    WHERE ArizaNo IS NOT NULL
    ORDER BY BakimEmriNo
)
UPDATE b
SET
    Durum = N'Tamamlandı',
    GerceklesenBaslangic = DATEADD(MINUTE, 15, b.OlusturmaZamani),
    TamamlanmaZamani = DATEADD(HOUR, 2, b.OlusturmaZamani)
FROM dbo.BakimEmirleri b
INNER JOIN Tamamlanacaklar t
    ON t.BakimEmriNo = b.BakimEmriNo;
GO

UPDATE g
SET
    CalismaBaslangici = g.AtamaZamani,
    CalismaBitisi = DATEADD(HOUR, 2, g.AtamaZamani),
    YapilanIs = N'Örnek bakım işlemi tamamlandı.'
FROM dbo.BakimGorevlendirmeleri g
INNER JOIN dbo.BakimEmirleri b
    ON b.BakimEmriNo = g.BakimEmriNo
WHERE b.Durum = N'Tamamlandı';
GO

UPDATE ar
SET
    Durum = N'Kapalı',
    KapanisZamani = b.TamamlanmaZamani
FROM dbo.Arizalar ar
INNER JOIN dbo.BakimEmirleri b
    ON b.ArizaNo = ar.ArizaNo
WHERE b.Durum = N'Tamamlandı';
GO

UPDATE a
SET
    Durum = N'Kapalı',
    KapanisZamani = ar.KapanisZamani
FROM dbo.Alarmlar a
INNER JOIN dbo.Arizalar ar
    ON ar.AlarmNo = a.AlarmNo
WHERE ar.Durum = N'Kapalı';
GO

PRINT N'Yaklaşık 95.000 örnek kayıt hazırlandı.';
GO
GO
-- END 702.02_Kodlama_Calismalari/04_Ornek_Veriler/04_Toplu_Veri_Uretimi.sql
GO

-- BEGIN 702.02_Kodlama_Calismalari/05_Gorunumler/01_Gorunumler.sql
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

/* =========================================================
   1. GÜNCEL ALARMLAR
   Alarmın hangi sensör ve ekipmandan geldiğini gösterir.
   ========================================================= */

CREATE OR ALTER VIEW dbo.vw_GuncelAlarmlar
AS
SELECT
    a.AlarmNo,
    e.EkipmanNo,
    e.EkipmanKodu,
    e.EkipmanAdi,
    s.SensorNo,
    s.SensorKodu,
    s.SensorTuru,
    o.OlcumDegeri,
    s.OlcumBirimi,
    s.AltEsik,
    s.UstEsik,
    a.Seviye,
    a.Durum,
    a.AcilisZamani,
    a.KapanisZamani
FROM dbo.Alarmlar a
INNER JOIN dbo.Olcumler o
    ON o.OlcumNo = a.OlcumNo
INNER JOIN dbo.Sensorler s
    ON s.SensorNo = o.SensorNo
INNER JOIN dbo.Ekipmanlar e
    ON e.EkipmanNo = s.EkipmanNo;
GO

/* =========================================================
   2. AKTİF BAKIM EMİRLERİ
   Tamamlanmamış ve iptal edilmemiş işleri gösterir.
   ========================================================= */

CREATE OR ALTER VIEW dbo.vw_AktifBakimEmirleri
AS
SELECT
    b.BakimEmriNo,
    e.EkipmanKodu,
    e.EkipmanAdi,
    b.ArizaNo,
    b.BakimTuru,
    b.Aciklama,
    b.Oncelik,
    b.Durum,
    b.OlusturmaZamani,
    b.PlanlananBaslangic,
    t.TeknisyenNo,
    t.SicilNo,
    t.AdSoyad AS TeknisyenAdi
FROM dbo.BakimEmirleri b
INNER JOIN dbo.Ekipmanlar e
    ON e.EkipmanNo = b.EkipmanNo
LEFT JOIN dbo.BakimGorevlendirmeleri g
    ON g.BakimEmriNo = b.BakimEmriNo
LEFT JOIN dbo.Teknisyenler t
    ON t.TeknisyenNo = g.TeknisyenNo
WHERE b.Durum NOT IN (N'Tamamlandı', N'İptal Edildi');
GO

/* =========================================================
   3. STOK DURUMU
   Giriş ve çıkış hareketlerinden mevcut stoğu hesaplar.
   ========================================================= */

CREATE OR ALTER VIEW dbo.vw_StokDurumu
AS
SELECT
    p.ParcaNo,
    p.ParcaKodu,
    p.ParcaAdi,
    p.OlcuBirimi,
    p.AsgariStok,
    p.GuncelBirimMaliyet,
    COALESCE
    (
        SUM
        (
            CASE
                WHEN h.HareketTuru IN (N'Giriş', N'İade')
                    THEN h.Miktar
                WHEN h.HareketTuru IN (N'Çıkış', N'Kullanım')
                    THEN -h.Miktar
                ELSE 0
            END
        ),
        0
    ) AS MevcutStok,
    CASE
        WHEN COALESCE
        (
            SUM
            (
                CASE
                    WHEN h.HareketTuru IN (N'Giriş', N'İade')
                        THEN h.Miktar
                    WHEN h.HareketTuru IN (N'Çıkış', N'Kullanım')
                        THEN -h.Miktar
                    ELSE 0
                END
            ),
            0
        ) <= p.AsgariStok
            THEN N'Kritik'
        ELSE N'Yeterli'
    END AS StokDurumu
FROM dbo.YedekParcalar p
LEFT JOIN dbo.StokHareketleri h
    ON h.ParcaNo = p.ParcaNo
GROUP BY
    p.ParcaNo,
    p.ParcaKodu,
    p.ParcaAdi,
    p.OlcuBirimi,
    p.AsgariStok,
    p.GuncelBirimMaliyet;
GO

/* =========================================================
   4. BAKIM MALİYETLERİ
   İşçilik ve parça maliyetlerini ayrı hesaplayıp toplar.
   ========================================================= */

CREATE OR ALTER VIEW dbo.vw_BakimMaliyetleri
AS
WITH Iscilik AS
(
    SELECT
        BakimEmriNo,
        SUM
        (
            CASE
                WHEN CalismaBaslangici IS NOT NULL
                 AND CalismaBitisi IS NOT NULL
                THEN
                    DATEDIFF
                    (
                        MINUTE,
                        CalismaBaslangici,
                        CalismaBitisi
                    ) / 60.0 * IslemAnindakiSaatlikUcret
                ELSE 0
            END
        ) AS IscilikMaliyeti
    FROM dbo.BakimGorevlendirmeleri
    GROUP BY BakimEmriNo
),
Parca AS
(
    SELECT
        BakimEmriNo,
        SUM
        (
            CASE
                WHEN IslemTuru = N'Kullanım'
                    THEN Miktar * IslemAnindakiBirimMaliyet
                WHEN IslemTuru = N'İade'
                    THEN -(Miktar * IslemAnindakiBirimMaliyet)
                ELSE 0
            END
        ) AS ParcaMaliyeti
    FROM dbo.BakimParcalari
    GROUP BY BakimEmriNo
)
SELECT
    b.BakimEmriNo,
    e.EkipmanKodu,
    e.EkipmanAdi,
    b.BakimTuru,
    b.Durum,
    COALESCE(i.IscilikMaliyeti, 0) AS IscilikMaliyeti,
    COALESCE(p.ParcaMaliyeti, 0) AS ParcaMaliyeti,
    COALESCE(i.IscilikMaliyeti, 0) +
    COALESCE(p.ParcaMaliyeti, 0) AS ToplamMaliyet
FROM dbo.BakimEmirleri b
INNER JOIN dbo.Ekipmanlar e
    ON e.EkipmanNo = b.EkipmanNo
LEFT JOIN Iscilik i
    ON i.BakimEmriNo = b.BakimEmriNo
LEFT JOIN Parca p
    ON p.BakimEmriNo = b.BakimEmriNo;
GO

/* =========================================================
   5. EKİPMAN MTBF VE MTTR RAPORU
   Arızalar arasındaki ve onarımda geçen süreyi hesaplar.
   ========================================================= */

CREATE OR ALTER VIEW dbo.vw_EkipmanMTBF_MTTR
AS
WITH ArizaSirasi AS
(
    SELECT
        ArizaNo,
        EkipmanNo,
        AcilisZamani,
        KapanisZamani,
        LAG(AcilisZamani) OVER
        (
            PARTITION BY EkipmanNo
            ORDER BY AcilisZamani
        ) AS OncekiArizaZamani
    FROM dbo.Arizalar
)
SELECT
    e.EkipmanNo,
    e.EkipmanKodu,
    e.EkipmanAdi,
    COUNT(a.ArizaNo) AS ToplamArizaSayisi,
    CAST
    (
        AVG
        (
            CASE
                WHEN a.OncekiArizaZamani IS NOT NULL
                THEN DATEDIFF
                (
                    MINUTE,
                    a.OncekiArizaZamani,
                    a.AcilisZamani
                ) / 60.0
            END
        )
        AS DECIMAL(18,2)
    ) AS MTBF_Saat,
    CAST
    (
        AVG
        (
            CASE
                WHEN a.KapanisZamani IS NOT NULL
                THEN DATEDIFF
                (
                    MINUTE,
                    a.AcilisZamani,
                    a.KapanisZamani
                ) / 60.0
            END
        )
        AS DECIMAL(18,2)
    ) AS MTTR_Saat
FROM dbo.Ekipmanlar e
LEFT JOIN ArizaSirasi a
    ON a.EkipmanNo = e.EkipmanNo
GROUP BY
    e.EkipmanNo,
    e.EkipmanKodu,
    e.EkipmanAdi;
GO

/* =========================================================
   6. EKİPMAN ÖZETİ
   Her ekipmanın sensör, alarm, arıza ve bakım sayılarını verir.
   ========================================================= */

CREATE OR ALTER VIEW dbo.vw_EkipmanOzeti
AS
SELECT
    e.EkipmanNo,
    e.EkipmanKodu,
    e.EkipmanAdi,
    e.Konum,
    e.Durum,
    (SELECT COUNT(*)
     FROM dbo.Sensorler s
     WHERE s.EkipmanNo = e.EkipmanNo) AS SensorSayisi,

    (SELECT COUNT(*)
     FROM dbo.Alarmlar a
     INNER JOIN dbo.Olcumler o ON o.OlcumNo = a.OlcumNo
     INNER JOIN dbo.Sensorler s ON s.SensorNo = o.SensorNo
     WHERE s.EkipmanNo = e.EkipmanNo) AS AlarmSayisi,

    (SELECT COUNT(*)
     FROM dbo.Arizalar ar
     WHERE ar.EkipmanNo = e.EkipmanNo) AS ArizaSayisi,

    (SELECT COUNT(*)
     FROM dbo.BakimEmirleri b
     WHERE b.EkipmanNo = e.EkipmanNo) AS BakimEmriSayisi
FROM dbo.Ekipmanlar e;
GO

PRINT N'Görünümler başarıyla oluşturuldu.';
GO
GO
-- END 702.02_Kodlama_Calismalari/05_Gorunumler/01_Gorunumler.sql
GO

-- BEGIN 702.02_Kodlama_Calismalari/06_Sakli_Yordamlar/01_Sakli_Yordamlar.sql
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

/* =========================================================
   1. ALARM İNCELEME
   Alarmı yetkili kullanıcı tarafından incelenmiş olarak işaretler.
   ========================================================= */

CREATE OR ALTER PROCEDURE dbo.sp_AlarmIncele
    @AlarmNo BIGINT,
    @KullaniciNo INT,
    @IncelemeSonucu NVARCHAR(250)
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    IF NOT EXISTS
    (
        SELECT 1 FROM dbo.Alarmlar
        WHERE AlarmNo = @AlarmNo
    )
        THROW 50001, N'Alarm bulunamadı.', 1;

    IF NOT EXISTS
    (
        SELECT 1 FROM dbo.Kullanicilar
        WHERE KullaniciNo = @KullaniciNo
          AND Aktif = 1
    )
        THROW 50002, N'Aktif kullanıcı bulunamadı.', 1;

    UPDATE dbo.Alarmlar
    SET
        Durum = N'İncelendi',
        InceleyenKullaniciNo = @KullaniciNo,
        IncelemeZamani = SYSDATETIME(),
        IncelemeSonucu = @IncelemeSonucu
    WHERE AlarmNo = @AlarmNo;
END;
GO

/* =========================================================
   2. ALARMDAN ARIZA OLUŞTURMA
   İncelenmiş alarmı arıza kaydına dönüştürür.
   ========================================================= */

CREATE OR ALTER PROCEDURE dbo.sp_AlarmdanArizaOlustur
    @AlarmNo BIGINT,
    @ArizaAciklamasi NVARCHAR(500),
    @ArizaNedeni NVARCHAR(250),
    @Oncelik NVARCHAR(20),
    @DogrulayanKullaniciNo INT,
    @YeniArizaNo BIGINT OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    BEGIN TRY
        BEGIN TRANSACTION;

        DECLARE @EkipmanNo INT;
        DECLARE @IncelemeZamani DATETIME2;

        SELECT
            @EkipmanNo = s.EkipmanNo,
            @IncelemeZamani = a.IncelemeZamani
        FROM dbo.Alarmlar a WITH (UPDLOCK, HOLDLOCK)
        INNER JOIN dbo.Olcumler o
            ON o.OlcumNo = a.OlcumNo
        INNER JOIN dbo.Sensorler s
            ON s.SensorNo = o.SensorNo
        WHERE a.AlarmNo = @AlarmNo;

        IF @EkipmanNo IS NULL
            THROW 50003, N'Alarm veya bağlı ekipman bulunamadı.', 1;

        IF @IncelemeZamani IS NULL
            THROW 50004, N'Alarm incelenmeden arıza oluşturulamaz.', 1;

        IF EXISTS
        (
            SELECT 1 FROM dbo.Arizalar
            WHERE AlarmNo = @AlarmNo
        )
            THROW 50005, N'Bu alarm için daha önce arıza oluşturulmuştur.', 1;

        INSERT INTO dbo.Arizalar
        (
            EkipmanNo,
            AlarmNo,
            ArizaAciklamasi,
            ArizaNedeni,
            Oncelik,
            Durum,
            DogrulayanKullaniciNo,
            DogrulamaZamani
        )
        VALUES
        (
            @EkipmanNo,
            @AlarmNo,
            @ArizaAciklamasi,
            @ArizaNedeni,
            @Oncelik,
            N'Doğrulandı',
            @DogrulayanKullaniciNo,
            SYSDATETIME()
        );

        SET @YeniArizaNo = SCOPE_IDENTITY();

        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0
            ROLLBACK TRANSACTION;

        THROW;
    END CATCH
END;
GO

/* =========================================================
   3. BAKIM EMRİ OLUŞTURMA
   Planlı veya arıza kaynaklı bakım emri oluşturur.
   ========================================================= */

CREATE OR ALTER PROCEDURE dbo.sp_BakimEmriOlustur
    @EkipmanNo INT,
    @ArizaNo BIGINT = NULL,
    @BakimTuru NVARCHAR(30),
    @Aciklama NVARCHAR(500),
    @Oncelik NVARCHAR(20),
    @PlanlananBaslangic DATETIME2 = NULL,
    @YeniBakimEmriNo BIGINT OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    BEGIN TRY
        BEGIN TRANSACTION;

        IF NOT EXISTS
        (
            SELECT 1 FROM dbo.Ekipmanlar
            WHERE EkipmanNo = @EkipmanNo
        )
            THROW 50006, N'Ekipman bulunamadı.', 1;

        IF @ArizaNo IS NOT NULL
        BEGIN
            IF NOT EXISTS
            (
                SELECT 1
                FROM dbo.Arizalar
                WHERE ArizaNo = @ArizaNo
                  AND EkipmanNo = @EkipmanNo
            )
                THROW 50007, N'Arıza bu ekipmana ait değildir.', 1;

            IF EXISTS
            (
                SELECT 1
                FROM dbo.BakimEmirleri WITH (UPDLOCK, HOLDLOCK)
                WHERE ArizaNo = @ArizaNo
                  AND BakimTuru = N'Düzeltici'
                  AND Durum NOT IN (N'Tamamlandı', N'İptal Edildi')
            )
                THROW 50008, N'Arıza için aktif bakım emri bulunmaktadır.', 1;
        END;

        INSERT INTO dbo.BakimEmirleri
        (
            EkipmanNo,
            ArizaNo,
            BakimTuru,
            Aciklama,
            Oncelik,
            Durum,
            PlanlananBaslangic
        )
        VALUES
        (
            @EkipmanNo,
            @ArizaNo,
            @BakimTuru,
            @Aciklama,
            @Oncelik,
            N'Bekliyor',
            @PlanlananBaslangic
        );

        SET @YeniBakimEmriNo = SCOPE_IDENTITY();

        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0
            ROLLBACK TRANSACTION;

        THROW;
    END CATCH
END;
GO

/* =========================================================
   4. TEKNİSYEN GÖREVLENDİRME
   Aktif teknisyeni bakım emrine atar.
   ========================================================= */

CREATE OR ALTER PROCEDURE dbo.sp_TeknisyenGorevlendir
    @BakimEmriNo BIGINT,
    @TeknisyenNo INT
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    DECLARE @SaatlikUcret DECIMAL(12,2);

    SELECT @SaatlikUcret = SaatlikUcret
    FROM dbo.Teknisyenler
    WHERE TeknisyenNo = @TeknisyenNo
      AND Durum = N'Aktif';

    IF @SaatlikUcret IS NULL
        THROW 50009, N'Aktif teknisyen bulunamadı.', 1;

    IF NOT EXISTS
    (
        SELECT 1
        FROM dbo.BakimEmirleri
        WHERE BakimEmriNo = @BakimEmriNo
          AND Durum NOT IN (N'Tamamlandı', N'İptal Edildi')
    )
        THROW 50010, N'Aktif bakım emri bulunamadı.', 1;

    IF EXISTS
    (
        SELECT 1
        FROM dbo.BakimGorevlendirmeleri
        WHERE BakimEmriNo = @BakimEmriNo
          AND TeknisyenNo = @TeknisyenNo
    )
        THROW 50011, N'Teknisyen bu bakım emrine zaten atanmıştır.', 1;

    INSERT INTO dbo.BakimGorevlendirmeleri
    (
        BakimEmriNo,
        TeknisyenNo,
        IslemAnindakiSaatlikUcret
    )
    VALUES
    (
        @BakimEmriNo,
        @TeknisyenNo,
        @SaatlikUcret
    );

    UPDATE dbo.BakimEmirleri
    SET Durum = N'Atandı'
    WHERE BakimEmriNo = @BakimEmriNo
      AND Durum = N'Bekliyor';
END;
GO

/* =========================================================
   5. YEDEK PARÇA KULLANIMI
   Stok kontrolü yapar ve iki kaydı tek işlemde oluşturur.
   ========================================================= */

CREATE OR ALTER PROCEDURE dbo.sp_ParcaKullan
    @BakimEmriNo BIGINT,
    @ParcaNo INT,
    @Miktar DECIMAL(18,4),
    @KullaniciNo INT
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    BEGIN TRY
        SET TRANSACTION ISOLATION LEVEL SERIALIZABLE;
        BEGIN TRANSACTION;

        DECLARE @BirimMaliyet DECIMAL(12,2);
        DECLARE @MevcutStok DECIMAL(18,4);
        DECLARE @BakimParcaNo BIGINT;

        IF @Miktar <= 0
            THROW 50012, N'Kullanım miktarı sıfırdan büyük olmalıdır.', 1;

        SELECT @BirimMaliyet = GuncelBirimMaliyet
        FROM dbo.YedekParcalar WITH (UPDLOCK, HOLDLOCK)
        WHERE ParcaNo = @ParcaNo;

        IF @BirimMaliyet IS NULL
            THROW 50013, N'Yedek parça bulunamadı.', 1;

        IF NOT EXISTS
        (
            SELECT 1
            FROM dbo.BakimEmirleri
            WHERE BakimEmriNo = @BakimEmriNo
              AND Durum NOT IN (N'Tamamlandı', N'İptal Edildi')
        )
            THROW 50014, N'Aktif bakım emri bulunamadı.', 1;

        SELECT
            @MevcutStok = COALESCE
            (
                SUM
                (
                    CASE
                        WHEN HareketTuru IN (N'Giriş', N'İade')
                            THEN Miktar
                        WHEN HareketTuru IN (N'Çıkış', N'Kullanım')
                            THEN -Miktar
                        ELSE 0
                    END
                ),
                0
            )
        FROM dbo.StokHareketleri
        WHERE ParcaNo = @ParcaNo;

        IF @MevcutStok < @Miktar
            THROW 50015, N'Yeterli stok bulunmamaktadır.', 1;

        INSERT INTO dbo.BakimParcalari
        (
            BakimEmriNo,
            ParcaNo,
            IslemTuru,
            Miktar,
            IslemAnindakiBirimMaliyet,
            KullaniciNo
        )
        VALUES
        (
            @BakimEmriNo,
            @ParcaNo,
            N'Kullanım',
            @Miktar,
            @BirimMaliyet,
            @KullaniciNo
        );

        SET @BakimParcaNo = SCOPE_IDENTITY();

        INSERT INTO dbo.StokHareketleri
        (
            ParcaNo,
            BakimParcaNo,
            HareketTuru,
            Miktar,
            BirimMaliyet,
            KullaniciNo,
            Aciklama
        )
        VALUES
        (
            @ParcaNo,
            @BakimParcaNo,
            N'Kullanım',
            @Miktar,
            @BirimMaliyet,
            @KullaniciNo,
            N'Bakım emrinde parça kullanımı'
        );

        COMMIT TRANSACTION;
        SET TRANSACTION ISOLATION LEVEL READ COMMITTED;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0
            ROLLBACK TRANSACTION;

        SET TRANSACTION ISOLATION LEVEL READ COMMITTED;
        THROW;
    END CATCH
END;
GO

/* =========================================================
   6. BAKIMI TAMAMLAMA
   Bakım emrini, arızayı, alarmı ve duruşu kapatır.
   ========================================================= */

CREATE OR ALTER PROCEDURE dbo.sp_BakimTamamla
    @BakimEmriNo BIGINT,
    @KontrolEdenKullaniciNo INT,
    @YapilanIs NVARCHAR(500)
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    BEGIN TRY
        BEGIN TRANSACTION;

        DECLARE @ArizaNo BIGINT;
        DECLARE @AlarmNo BIGINT;

        SELECT @ArizaNo = ArizaNo
        FROM dbo.BakimEmirleri WITH (UPDLOCK, HOLDLOCK)
        WHERE BakimEmriNo = @BakimEmriNo
          AND Durum NOT IN (N'Tamamlandı', N'İptal Edildi');

        IF @@ROWCOUNT = 0
            THROW 50016, N'Aktif bakım emri bulunamadı.', 1;

        UPDATE dbo.BakimGorevlendirmeleri
        SET
            CalismaBaslangici =
                COALESCE(CalismaBaslangici, AtamaZamani),
            CalismaBitisi = SYSDATETIME(),
            YapilanIs = @YapilanIs
        WHERE BakimEmriNo = @BakimEmriNo
          AND CalismaBitisi IS NULL;

        UPDATE dbo.BakimEmirleri
        SET
            Durum = N'Tamamlandı',
            GerceklesenBaslangic =
                COALESCE(GerceklesenBaslangic, OlusturmaZamani),
            TamamlanmaZamani = SYSDATETIME(),
            KontrolEdenKullaniciNo = @KontrolEdenKullaniciNo
        WHERE BakimEmriNo = @BakimEmriNo;

        IF @ArizaNo IS NOT NULL
        BEGIN
            SELECT @AlarmNo = AlarmNo
            FROM dbo.Arizalar
            WHERE ArizaNo = @ArizaNo;

            UPDATE dbo.Arizalar
            SET
                Durum = N'Kapalı',
                KapatanKullaniciNo = @KontrolEdenKullaniciNo,
                KapanisZamani = SYSDATETIME()
            WHERE ArizaNo = @ArizaNo;

            UPDATE dbo.DurusKayitlari
            SET BitisZamani = SYSDATETIME()
            WHERE ArizaNo = @ArizaNo
              AND BitisZamani IS NULL;

            IF @AlarmNo IS NOT NULL
            BEGIN
                UPDATE dbo.Alarmlar
                SET
                    Durum = N'Kapalı',
                    KapanisZamani = SYSDATETIME()
                WHERE AlarmNo = @AlarmNo;
            END;
        END;

        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0
            ROLLBACK TRANSACTION;

        THROW;
    END CATCH
END;
GO

PRINT N'Saklı yordamlar başarıyla oluşturuldu.';
GO
GO
-- END 702.02_Kodlama_Calismalari/06_Sakli_Yordamlar/01_Sakli_Yordamlar.sql
GO

-- BEGIN 702.02_Kodlama_Calismalari/07_Tetikleyiciler/01_Tetikleyiciler.sql
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

/* Bu dosya yalnız tetikleyici tanımlarını günceller; örnek veriyi değiştirmez. */

/* =========================================================
   1. ÖLÇÜM SONUCUNDA OTOMATİK ALARM
   Eşik dışındaki ölçüm için otomatik alarm oluşturur.
   Aynı sensörde açık alarm varsa ikinci alarmı oluşturmaz.
   ========================================================= */

CREATE OR ALTER TRIGGER dbo.trg_Olcumler_AlarmOlustur
ON dbo.Olcumler
AFTER INSERT
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @SensorKilidi INT;

    SELECT @SensorKilidi = MAX(s.SensorNo)
    FROM dbo.Sensorler s WITH (UPDLOCK, HOLDLOCK)
    INNER JOIN inserted i
        ON i.SensorNo = s.SensorNo;

    ;WITH AdayOlcumler AS
    (
        SELECT
            i.OlcumNo,
            i.SensorNo,
            i.OlcumDegeri,
            i.OlcumZamani,
            s.AltEsik,
            s.UstEsik,
            ROW_NUMBER() OVER
            (
                PARTITION BY i.SensorNo
                ORDER BY i.OlcumZamani DESC, i.OlcumNo DESC
            ) AS Sira
        FROM inserted i
        INNER JOIN dbo.Sensorler s
            ON s.SensorNo = i.SensorNo
        WHERE i.OlcumDegeri < s.AltEsik
           OR i.OlcumDegeri > s.UstEsik
    )
    INSERT INTO dbo.Alarmlar
    (
        OlcumNo,
        Seviye,
        Aciklama,
        Durum,
        AcilisZamani
    )
    SELECT
        a.OlcumNo,
        CASE
            WHEN a.OlcumDegeri >
                 a.UstEsik + ((a.UstEsik - a.AltEsik) * 0.10)
              OR a.OlcumDegeri <
                 a.AltEsik - ((a.UstEsik - a.AltEsik) * 0.10)
                THEN N'Kritik'
            ELSE N'Uyarı'
        END,
        N'Sensör ölçümü belirlenen eşik değerlerinin dışına çıkmıştır.',
        N'Açık',
        a.OlcumZamani
    FROM AdayOlcumler a
    WHERE a.Sira = 1
      AND NOT EXISTS
      (
          SELECT 1
          FROM dbo.Alarmlar al WITH (UPDLOCK, HOLDLOCK)
          INNER JOIN dbo.Olcumler o
              ON o.OlcumNo = al.OlcumNo
          WHERE o.SensorNo = a.SensorNo
            AND al.Durum IN (N'Açık', N'İncelendi')
      );
END;
GO

/* =========================================================
   2. ARIZA OLUŞTURMA KONTROLÜ
   Alarm incelenmeden arıza oluşturulmasını engeller.
   ========================================================= */

CREATE OR ALTER TRIGGER dbo.trg_Arizalar_AlarmKontrol
ON dbo.Arizalar
AFTER INSERT, UPDATE
AS
BEGIN
    SET NOCOUNT ON;

    IF EXISTS
    (
        SELECT 1
        FROM inserted i
        INNER JOIN dbo.Alarmlar a
            ON a.AlarmNo = i.AlarmNo
        WHERE i.AlarmNo IS NOT NULL
          AND a.IncelemeZamani IS NULL
    )
    BEGIN
        ;THROW 51001, N'Alarm incelenmeden arıza oluşturulamaz.', 1;
    END;
END;
GO

/* =========================================================
   3. BAKIM EMRİ KONTROLÜ
   Aynı arızaya birden fazla aktif düzeltici bakım açılmasını engeller.
   ========================================================= */

CREATE OR ALTER TRIGGER dbo.trg_BakimEmirleri_AktifEmirKontrol
ON dbo.BakimEmirleri
AFTER INSERT, UPDATE
AS
BEGIN
    SET NOCOUNT ON;

    IF EXISTS
    (
        SELECT 1
        FROM inserted i
        INNER JOIN dbo.Arizalar a
            ON a.ArizaNo = i.ArizaNo
        WHERE i.ArizaNo IS NOT NULL
          AND i.EkipmanNo <> a.EkipmanNo
    )
    BEGIN
        ;THROW 51002, N'Arıza ve bakım emri aynı ekipmana ait olmalıdır.', 1;
    END;

    IF EXISTS
    (
        SELECT 1
        FROM inserted i
        INNER JOIN dbo.BakimEmirleri b
            ON b.ArizaNo = i.ArizaNo
           AND b.BakimEmriNo <> i.BakimEmriNo
        WHERE i.ArizaNo IS NOT NULL
          AND i.BakimTuru = N'Düzeltici'
          AND b.BakimTuru = N'Düzeltici'
          AND i.Durum NOT IN (N'Tamamlandı', N'İptal Edildi')
          AND b.Durum NOT IN (N'Tamamlandı', N'İptal Edildi')
    )
    BEGIN
        ;THROW 51003, N'Arıza için aktif düzeltici bakım emri bulunmaktadır.', 1;
    END;
END;
GO

/* =========================================================
   4. NEGATİF STOK KONTROLÜ
   Stok miktarının sıfırın altına düşmesini engeller.
   ========================================================= */

CREATE OR ALTER TRIGGER dbo.trg_StokHareketleri_NegatifStokKontrol
ON dbo.StokHareketleri
AFTER INSERT, UPDATE, DELETE
AS
BEGIN
    SET NOCOUNT ON;

    ;WITH EtkilenenParcalar AS
    (
        SELECT ParcaNo FROM inserted
        UNION
        SELECT ParcaNo FROM deleted
    ),
    Stoklar AS
    (
        SELECT
            e.ParcaNo,
            COALESCE
            (
                SUM
                (
                    CASE
                        WHEN h.HareketTuru IN (N'Giriş', N'İade')
                            THEN h.Miktar
                        WHEN h.HareketTuru IN (N'Çıkış', N'Kullanım')
                            THEN -h.Miktar
                        ELSE 0
                    END
                ),
                0
            ) AS MevcutStok
        FROM EtkilenenParcalar e
        LEFT JOIN dbo.StokHareketleri h
            ON h.ParcaNo = e.ParcaNo
        GROUP BY e.ParcaNo
    )
    SELECT *
    INTO #NegatifStok
    FROM Stoklar
    WHERE MevcutStok < 0;

    IF EXISTS (SELECT 1 FROM #NegatifStok)
    BEGIN
        ;THROW 51004, N'Stok miktarı sıfırın altına düşemez.', 1;
    END;
END;
GO

/* =========================================================
   5. BAKIM EMRİ DENETİM KAYDI
   Ekleme, güncelleme ve silme işlemlerini kaydeder.
   ========================================================= */

CREATE OR ALTER TRIGGER dbo.trg_BakimEmirleri_Denetim
ON dbo.BakimEmirleri
AFTER INSERT, UPDATE, DELETE
AS
BEGIN
    SET NOCOUNT ON;

    INSERT INTO dbo.DenetimKayitlari
    (
        KullaniciNo,
        OturumKullaniciAdi,
        TabloAdi,
        KayitAnahtari,
        IslemTuru,
        EskiDegerler,
        YeniDegerler
    )
    SELECT
        (
            SELECT TOP (1) KullaniciNo
            FROM dbo.Kullanicilar
            WHERE SqlKullaniciAdi IN
                  (SUSER_SNAME(), ORIGINAL_LOGIN())
        ),
        ORIGINAL_LOGIN(),
        N'BakimEmirleri',
        CAST(COALESCE(i.BakimEmriNo, d.BakimEmriNo) AS NVARCHAR(250)),
        CASE
            WHEN d.BakimEmriNo IS NULL THEN N'INSERT'
            WHEN i.BakimEmriNo IS NULL THEN N'DELETE'
            ELSE N'UPDATE'
        END,
        CASE WHEN d.BakimEmriNo IS NULL THEN NULL ELSE
        (
            SELECT
                d.BakimEmriNo,
                d.EkipmanNo,
                d.ArizaNo,
                d.BakimTuru,
                d.Oncelik,
                d.Durum
            FOR JSON PATH, WITHOUT_ARRAY_WRAPPER
        ) END,
        CASE WHEN i.BakimEmriNo IS NULL THEN NULL ELSE
        (
            SELECT
                i.BakimEmriNo,
                i.EkipmanNo,
                i.ArizaNo,
                i.BakimTuru,
                i.Oncelik,
                i.Durum
            FOR JSON PATH, WITHOUT_ARRAY_WRAPPER
        ) END
    FROM inserted i
    FULL OUTER JOIN deleted d
        ON d.BakimEmriNo = i.BakimEmriNo;
END;
GO

/* =========================================================
   6. STOK DENETİM KAYDI
   Bütün stok hareketlerini denetim tablosuna kaydeder.
   ========================================================= */

CREATE OR ALTER TRIGGER dbo.trg_StokHareketleri_Denetim
ON dbo.StokHareketleri
AFTER INSERT, UPDATE, DELETE
AS
BEGIN
    SET NOCOUNT ON;

    INSERT INTO dbo.DenetimKayitlari
    (
        KullaniciNo,
        OturumKullaniciAdi,
        TabloAdi,
        KayitAnahtari,
        IslemTuru,
        EskiDegerler,
        YeniDegerler
    )
    SELECT
        (
            SELECT TOP (1) KullaniciNo
            FROM dbo.Kullanicilar
            WHERE SqlKullaniciAdi IN
                  (SUSER_SNAME(), ORIGINAL_LOGIN())
        ),
        ORIGINAL_LOGIN(),
        N'StokHareketleri',
        CAST
        (
            COALESCE(i.StokHareketNo, d.StokHareketNo)
            AS NVARCHAR(250)
        ),
        CASE
            WHEN d.StokHareketNo IS NULL THEN N'INSERT'
            WHEN i.StokHareketNo IS NULL THEN N'DELETE'
            ELSE N'UPDATE'
        END,
        CASE WHEN d.StokHareketNo IS NULL THEN NULL ELSE
        (
            SELECT
                d.StokHareketNo,
                d.ParcaNo,
                d.HareketTuru,
                d.Miktar,
                d.BirimMaliyet
            FOR JSON PATH, WITHOUT_ARRAY_WRAPPER
        ) END,
        CASE WHEN i.StokHareketNo IS NULL THEN NULL ELSE
        (
            SELECT
                i.StokHareketNo,
                i.ParcaNo,
                i.HareketTuru,
                i.Miktar,
                i.BirimMaliyet
            FOR JSON PATH, WITHOUT_ARRAY_WRAPPER
        ) END
    FROM inserted i
    FULL OUTER JOIN deleted d
        ON d.StokHareketNo = i.StokHareketNo;
END;
GO

/* =========================================================
   7. DENETİM KAYITLARINI KORUMA
   Denetim kayıtlarının değiştirilmesini veya silinmesini engeller.
   ========================================================= */

CREATE OR ALTER TRIGGER dbo.trg_DenetimKayitlari_Koruma
ON dbo.DenetimKayitlari
INSTEAD OF UPDATE, DELETE
AS
BEGIN
    SET NOCOUNT ON;

    ;THROW 51005, N'Denetim kayıtları değiştirilemez veya silinemez.', 1;
END;
GO

PRINT N'Tetikleyiciler başarıyla oluşturuldu.';
GO
GO
-- END 702.02_Kodlama_Calismalari/07_Tetikleyiciler/01_Tetikleyiciler.sql
GO

-- BEGIN 702.02_Kodlama_Calismalari/08_Yetkilendirme/01_Roller_ve_Izinler.sql
USE EndustriyelBakimDB;
GO

/* SQL SERVER VERİTABANI ROLLERİ */

IF DATABASE_PRINCIPAL_ID(N'rol_yonetici') IS NULL
    EXEC(N'CREATE ROLE rol_yonetici');
GO

IF DATABASE_PRINCIPAL_ID(N'rol_bakim_yoneticisi') IS NULL
    EXEC(N'CREATE ROLE rol_bakim_yoneticisi');
GO

IF DATABASE_PRINCIPAL_ID(N'rol_teknisyen') IS NULL
    EXEC(N'CREATE ROLE rol_teknisyen');
GO

IF DATABASE_PRINCIPAL_ID(N'rol_denetci') IS NULL
    EXEC(N'CREATE ROLE rol_denetci');
GO

/* =========================================================
   YÖNETİCİ
   Veritabanındaki bütün işlemleri yönetebilir.
   ========================================================= */

GRANT CONTROL ON DATABASE::EndustriyelBakimDB
TO rol_yonetici;
GO

/* =========================================================
   BAKIM YÖNETİCİSİ
   Tabloları okuyabilir ve bakım yordamlarını çalıştırabilir.
   ========================================================= */

GRANT SELECT ON SCHEMA::dbo
TO rol_bakim_yoneticisi;
GO

GRANT EXECUTE ON OBJECT::dbo.sp_AlarmIncele
TO rol_bakim_yoneticisi;

GRANT EXECUTE ON OBJECT::dbo.sp_AlarmdanArizaOlustur
TO rol_bakim_yoneticisi;

GRANT EXECUTE ON OBJECT::dbo.sp_BakimEmriOlustur
TO rol_bakim_yoneticisi;

GRANT EXECUTE ON OBJECT::dbo.sp_TeknisyenGorevlendir
TO rol_bakim_yoneticisi;

GRANT EXECUTE ON OBJECT::dbo.sp_BakimTamamla
TO rol_bakim_yoneticisi;
GO

/* =========================================================
   TEKNİSYEN
   Parça kullanım ve bakım tamamlama yordamlarını çalıştırabilir.
   Bu rol tanımı satır bazlı 'yalnız kendi işi' denetimi uygulamaz.
   ========================================================= */

GRANT SELECT ON OBJECT::dbo.vw_GuncelAlarmlar
TO rol_teknisyen;

GRANT SELECT ON OBJECT::dbo.vw_AktifBakimEmirleri
TO rol_teknisyen;

GRANT SELECT ON OBJECT::dbo.vw_StokDurumu
TO rol_teknisyen;

GRANT SELECT ON OBJECT::dbo.vw_BakimMaliyetleri
TO rol_teknisyen;
GO

GRANT EXECUTE ON OBJECT::dbo.sp_ParcaKullan
TO rol_teknisyen;

GRANT EXECUTE ON OBJECT::dbo.sp_BakimTamamla
TO rol_teknisyen;
GO

DENY INSERT, UPDATE, DELETE ON OBJECT::dbo.Alarmlar
TO rol_teknisyen;

DENY INSERT, UPDATE, DELETE ON OBJECT::dbo.Arizalar
TO rol_teknisyen;

DENY INSERT, UPDATE, DELETE ON OBJECT::dbo.BakimEmirleri
TO rol_teknisyen;

DENY INSERT, UPDATE, DELETE ON OBJECT::dbo.Kullanicilar
TO rol_teknisyen;

DENY INSERT, UPDATE, DELETE ON OBJECT::dbo.Roller
TO rol_teknisyen;
GO

/* =========================================================
   DENETÇİ
   Raporları ve denetim kayıtlarını yalnızca okuyabilir.
   ========================================================= */

GRANT SELECT ON OBJECT::dbo.DenetimKayitlari
TO rol_denetci;

GRANT SELECT ON OBJECT::dbo.vw_GuncelAlarmlar
TO rol_denetci;

GRANT SELECT ON OBJECT::dbo.vw_AktifBakimEmirleri
TO rol_denetci;

GRANT SELECT ON OBJECT::dbo.vw_StokDurumu
TO rol_denetci;

GRANT SELECT ON OBJECT::dbo.vw_BakimMaliyetleri
TO rol_denetci;

GRANT SELECT ON OBJECT::dbo.vw_EkipmanMTBF_MTTR
TO rol_denetci;

GRANT SELECT ON OBJECT::dbo.vw_EkipmanOzeti
TO rol_denetci;
GO

DENY INSERT, UPDATE, DELETE ON SCHEMA::dbo
TO rol_denetci;
GO

/* DENETİM KAYITLARI HİÇBİR STANDART ROL TARAFINDAN DEĞİŞTİRİLEMEZ */

DENY UPDATE, DELETE ON OBJECT::dbo.DenetimKayitlari
TO PUBLIC;
GO

PRINT N'Roller ve yetkiler başarıyla oluşturuldu.';
GO
GO
-- END 702.02_Kodlama_Calismalari/08_Yetkilendirme/01_Roller_ve_Izinler.sql
GO

-- BEGIN 702.02_Kodlama_Calismalari/09_Indeksler/01_Indeksler.sql
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
GO
-- END 702.02_Kodlama_Calismalari/09_Indeksler/01_Indeksler.sql
GO

-- BEGIN 702.03_Test_Calismalari/01_Dogrulama/01_Ekipman_Kayitlarini_Dogrulama.sql
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

IF EXISTS
(
    SELECT 1
    FROM @BeklenenNesneler b
    LEFT JOIN sys.objects o
        ON o.name = b.NesneAdi
       AND o.schema_id = SCHEMA_ID(N'dbo')
       AND o.type = b.NesneTuru
    WHERE o.object_id IS NULL
)
BEGIN
    SELECT b.NesneAdi AS EksikNesne, b.NesneTuru
    FROM @BeklenenNesneler b
    LEFT JOIN sys.objects o
        ON o.name = b.NesneAdi
       AND o.schema_id = SCHEMA_ID(N'dbo')
       AND o.type = b.NesneTuru
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
    INNER JOIN @BeklenenNesneler b ON b.NesneAdi = t.name AND b.NesneTuru = 'TR'
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
          AND i.name = b.IndeksAdi
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
        WHERE p.name = b.RolAdi AND p.type = 'R'
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
GO
-- END 702.03_Test_Calismalari/01_Dogrulama/01_Ekipman_Kayitlarini_Dogrulama.sql
GO
/* Aynı sorgu bağlantısında sonraki komutların çalışabilmesi için sıfırla. */
SET NOEXEC OFF;
GO
