USE EndustriyelBakimDB;
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