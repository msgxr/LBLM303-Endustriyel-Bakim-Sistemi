:ON ERROR EXIT
:setvar ROOT "C:\Users\msgxr\LBLM303_Endustriyel_Bakim_Projesi_SDP"

USE master;
GO

IF DB_ID(N'EndustriyelBakimDB') IS NOT NULL
BEGIN
    ALTER DATABASE EndustriyelBakimDB
    SET SINGLE_USER WITH ROLLBACK IMMEDIATE;

    DROP DATABASE EndustriyelBakimDB;
END;
GO

CREATE DATABASE EndustriyelBakimDB;
GO

USE EndustriyelBakimDB;
GO

/* 17 ANA TABLO */

:r "$(ROOT)\702.02_Kodlama_Calismalari\02_Tablolar\01_EkipmanTurleri.sql"
:r "$(ROOT)\702.02_Kodlama_Calismalari\02_Tablolar\02_Ekipmanlar.sql"
:r "$(ROOT)\702.02_Kodlama_Calismalari\02_Tablolar\03_Sensorler.sql"
:r "$(ROOT)\702.02_Kodlama_Calismalari\02_Tablolar\04_Olcumler.sql"
:r "$(ROOT)\702.02_Kodlama_Calismalari\02_Tablolar\05_Alarmlar.sql"
:r "$(ROOT)\702.02_Kodlama_Calismalari\02_Tablolar\06_BakimEmirleri.sql"
:r "$(ROOT)\702.02_Kodlama_Calismalari\02_Tablolar\07_Arizalar.sql"
:r "$(ROOT)\702.02_Kodlama_Calismalari\02_Tablolar\08_Teknisyenler.sql"
:r "$(ROOT)\702.02_Kodlama_Calismalari\02_Tablolar\09_BakimGorevlendirmeleri.sql"
:r "$(ROOT)\702.02_Kodlama_Calismalari\02_Tablolar\10_YedekParcalar.sql"
:r "$(ROOT)\702.02_Kodlama_Calismalari\02_Tablolar\11_BakimParcalari.sql"
:r "$(ROOT)\702.02_Kodlama_Calismalari\02_Tablolar\12_StokHareketleri.sql"
:r "$(ROOT)\702.02_Kodlama_Calismalari\02_Tablolar\13_DurusKayitlari.sql"
:r "$(ROOT)\702.02_Kodlama_Calismalari\02_Tablolar\14_Kullanicilar.sql"
:r "$(ROOT)\702.02_Kodlama_Calismalari\02_Tablolar\15_Roller.sql"
:r "$(ROOT)\702.02_Kodlama_Calismalari\02_Tablolar\16_KullaniciRolleri.sql"
:r "$(ROOT)\702.02_Kodlama_Calismalari\02_Tablolar\17_DenetimKayitlari.sql"

/* KISITLAR */

:r "$(ROOT)\702.02_Kodlama_Calismalari\03_Kisitlar\01_Veri_Butunlugu_Kisitlari.sql"

/* YAKLAŞIK 95.000 ÖRNEK KAYIT */

:r "$(ROOT)\702.02_Kodlama_Calismalari\04_Ornek_Veriler\01_EkipmanTurleri_Ornek_Veriler.sql"
:r "$(ROOT)\702.02_Kodlama_Calismalari\04_Ornek_Veriler\02_Ekipmanlar_Ornek_Veriler.sql"
:r "$(ROOT)\702.02_Kodlama_Calismalari\04_Ornek_Veriler\03_Sensorler_Ornek_Veriler.sql"
:r "$(ROOT)\702.02_Kodlama_Calismalari\04_Ornek_Veriler\04_Toplu_Veri_Uretimi.sql"

/* GÖRÜNÜM, YORDAM, TETİKLEYİCİ, YETKİ VE İNDEKSLER */

:r "$(ROOT)\702.02_Kodlama_Calismalari\05_Gorunumler\01_Gorunumler.sql"
:r "$(ROOT)\702.02_Kodlama_Calismalari\06_Sakli_Yordamlar\01_Sakli_Yordamlar.sql"
:r "$(ROOT)\702.02_Kodlama_Calismalari\07_Tetikleyiciler\01_Tetikleyiciler.sql"
:r "$(ROOT)\702.02_Kodlama_Calismalari\08_Yetkilendirme\01_Roller_ve_Izinler.sql"
:r "$(ROOT)\702.02_Kodlama_Calismalari\09_Indeksler\01_Indeksler.sql"

/* SONUÇ KONTROLÜ */

USE EndustriyelBakimDB;
GO

SELECT
    (SELECT COUNT(*) FROM sys.tables) AS TabloSayisi,
    (SELECT COUNT(*) FROM sys.views) AS GorunumSayisi,
    (SELECT COUNT(*) FROM sys.procedures) AS YordamSayisi,
    (SELECT COUNT(*) FROM sys.triggers) AS TetikleyiciSayisi,
    (SELECT COUNT(*) FROM dbo.Ekipmanlar) AS EkipmanSayisi,
    (SELECT COUNT(*) FROM dbo.Sensorler) AS SensorSayisi,
    (SELECT COUNT_BIG(*) FROM dbo.Olcumler) AS OlcumSayisi;
GO

PRINT N'SİSTEM TAMAMEN KURULDU VE ÇALIŞIYOR.';
GO