# LBLM303 Endüstriyel Bakım Yönetim Sistemi

Microsoft SQL Server ile ekipman, sensör, alarm, arıza, bakım ve stok yönetimi.

**Kapsam:** 17 tablo, 6 görünüm, 6 yordam, 7 tetikleyici. Örnek veri hedefi: 100 ekipman, 300 sensör, 90.000 ölçüm. Kesin toplamı doğrulama sorgusu hesaplar.

**Doğrulanan sonuç (08.10.2026):** 94.980 toplam kayıt; üç doğrulama testi başarılı. Aynı 101 ölçüm için zorunlu tarama 425, optimize edilmiş erişim 3 mantıksal okuma yaptı (%99,29 azalma). Bu ölçüm yerel SQL Server test ortamına aittir.

## İlk kurulum — bir kez

SQL Server'a SSMS veya VS Code MSSQL ile bağlanın. SQL dosyalarını editörde açıp tamamını çalıştırın; SSMS'de F5 kullanın. Her dosyanın Messages sonucunu kontrol edin; hata varsa sonraki dosyaya geçmeyin.

`702.02_Kodlama_Calismalari` altındaki sıra:

| Sıra | Dosya / klasör |
|---:|---|
| 1 | `01_Veritabani/01_Veritabani_Olusturma.sql` — yalnız veritabanı oluşturma |
| 2 | `02_Tablolar` — 01'den 17'ye sırayla |
| 3 | `03_Kisitlar` |
| 4 | `04_Ornek_Veriler` — 01'den 04'e sırayla |
| 5 | `05_Gorunumler` |
| 6 | `06_Sakli_Yordamlar` |
| 7 | `07_Tetikleyiciler` |
| 8 | `08_Yetkilendirme` |
| 9 | `09_Indeksler` |

Veritabanı zaten kuruluysa bu kurulum sırasını tekrar çalıştırmayın. Ayrı tablo, kısıt ve örnek veri SQL dosyaları kendi klasörlerindedir.

## Kurulumdan sonra — sistemi kullanma

SSMS'de `EndustriyelBakimDB` bağlantısında **New Query** açın. VS Code'da MSSQL bağlantısıyla SQL editörünü kullanın. Aşağıdaki sorguyu çalıştırın:

```sql
USE EndustriyelBakimDB;
GO
SELECT TOP (20) * FROM dbo.vw_EkipmanOzeti ORDER BY EkipmanNo;
SELECT TOP (20) * FROM dbo.vw_GuncelAlarmlar ORDER BY AlarmNo DESC;
SELECT TOP (20) * FROM dbo.vw_BakimMaliyetleri ORDER BY BakimEmriNo DESC;
```

Raporlar için `702.02_Kodlama_Calismalari/10_Rapor_Sorgulari` içindeki SQL dosyalarını açıp çalıştırın. Bu kullanım adımında tablo/veri oluşturma dosyaları çalıştırılmaz.

## Test ve sunum

`702.03_Test_Calismalari/01_Dogrulama` dosyalarını sırayla çalıştırın:

| Dosya | Kontrol |
|---|---|
| `01_Ekipman_Kayitlarini_Dogrulama.sql` | Yapı, ilişkiler, indeksler ve kesin kayıt toplamı |
| `02_Iliski_ve_Kisit_Testleri.sql` | Altı hatalı işlemin engellenmesi |
| `03_Is_Akisi_Testleri.sql` | Alarm → arıza → bakım → stok → tamamlama → ROLLBACK |

Test 2 ve 3 satırları geri alır; kimlik numaralarında boşluk oluşabilir. Testleri yönetici/veritabanı sahibi bağlantısıyla, başka işlem yapılmayan bir ortamda çalıştırın. **BAŞARILI** mesajları görülmeden testleri geçmiş saymayın.

Performans dosyaları `702.03_Test_Calismalari/02_Performans` içindedir: zorunlu tarama ile optimizer erişimi karşılaştırılır; indeks silinmez.

Hocaya sıra: **EER → kayıt sayımı → kısıt testleri → iş akışı → raporlar → performans.**

## Kaynakları güncelleme

Proje kökündeki PowerShell terminalinde:

```powershell
git pull --ff-only origin main
if ($LASTEXITCODE -ne 0) { throw 'Git guncellemesi durdu.' }
```

Bu komut kaynak dosyalarını günceller. SQL Server'daki veriyi veya nesneleri değiştirmez.

[EER PDF](702.01_Analiz_ve_Tasarim_Calismalari/02_EER_Diyagrami/240309910_Gun_EER_Drawio.pdf) · [Proje önerisi PDF](703.01_Proje_Yonetimi/03_Teslim/01_Proje_Onerisi/240309910_Gün.pdf) · [Sürüm notları](RELEASE_NOTES.md)

[Public depoyu ZIP olarak indir](https://github.com/msgxr/LBLM303-Endustriyel-Bakim-Sistemi/archive/refs/heads/main.zip). ZIP kopyasında `git pull` kullanılmaz. Kullanım koşulları [LICENSE](LICENSE) dosyasındadır. Güncel kaynak `main` dalındadır.
