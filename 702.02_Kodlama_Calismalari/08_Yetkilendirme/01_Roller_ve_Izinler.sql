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
   Kendisine ait işlerde gerekli yordamları çalıştırabilir.
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