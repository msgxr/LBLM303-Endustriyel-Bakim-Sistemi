# LBLM303 Endüstriyel Bakım Yönetim Sistemi

Microsoft SQL Server ile ekipman, sensör, arıza, bakım ve stok yönetimi.

**Gerekenler:** Çalışan SQL Server; SSMS veya VS Code MSSQL. PowerShell komutları için `sqlcmd`.

## Kurulu sistemi çalıştırma

PowerShell terminalinde aşağıdaki komut ekipman özetini gösterir. `localhost` yerine kendi SQL Server sunucu adınızı yazabilirsiniz.

```powershell
sqlcmd -S localhost -E -C -I -b -f 65001 -d EndustriyelBakimDB -Q "SELECT TOP (20) * FROM dbo.vw_EkipmanOzeti ORDER BY EkipmanNo;"
```

**SSMS üzerinden:** Sunucu `localhost` → Windows Authentication → Connect → New Query. Aşağıdaki SQL kodunu yapıştırıp **F5** ile çalıştırın:

```sql
USE EndustriyelBakimDB;
GO
SELECT TOP (20) * FROM dbo.vw_EkipmanOzeti ORDER BY EkipmanNo;
```

## İlk kurulum

Veritabanı henüz kurulmadıysa `702.02_Kodlama_Calismalari` içindeki SQL dosyalarını aşağıdaki sırayla açıp çalıştırın. Hata olursa sonraki dosyaya geçmeyin.

1. `01_Veritabani/01_Veritabani_Olusturma.sql`
2. `02_Tablolar` — 01–17
3. `03_Kisitlar`
4. `04_Ornek_Veriler` — 01–04
5. `05_Gorunumler`
6. `06_Sakli_Yordamlar`
7. `07_Tetikleyiciler`
8. `08_Yetkilendirme`
9. `09_Indeksler`

**Kurulu veritabanında bu kurulum sırasını tekrar çalıştırmayın.**

## Test ve raporlar

SQL dosyalarını açıp tamamını çalıştırın; klasör içinde dosya numarasına göre ilerleyin.

| Klasör | İşlem |
|---|---|
| `702.03_Test_Calismalari/01_Dogrulama` | 01: yapı ve kayıt sayımı; 02: kısıtlar; 03: bakım iş akışı |
| `702.02_Kodlama_Calismalari/10_Rapor_Sorgulari` | MTBF, MTTR, maliyet, duruş ve stok raporları |
| `702.03_Test_Calismalari/02_Performans` | Zorunlu tarama ve optimize edilmiş erişimi karşılaştırma |

Doğrulama testlerinde **BAŞARILI** mesajını kontrol edin. Testleri yönetici/veritabanı sahibi bağlantısıyla, başka işlem yapılmayan ortamda çalıştırın. Test 2 ve 3 kayıtları geri alır; kimlik numaralarında boşluk oluşabilir.

**08.10.2026 sonucu:** 17 tablo, 6 görünüm, 6 yordam, 7 tetikleyici; 100 ekipman, 300 sensör, 90.000 ölçüm ve **94.980 toplam kayıt**. Üç doğrulama testi geçti. Aynı 101 ölçümde mantıksal okuma **425 → 3** (%99,29 azalma); sonuç yerel test ortamına aittir.

**Sunum sırası:** EER → kayıt sayımı → kısıtlar → bakım iş akışı → raporlar → performans.

## Güncelleme

Git ile alınmış proje klasöründeki PowerShell terminalinde:

```powershell
git pull --ff-only origin main
if ($LASTEXITCODE -ne 0) { throw 'Git guncellemesi durdu.' }
```

Güncelleme kaynak dosyalarını yeniler; veritabanındaki kayıtları değiştirmez.

[EER PDF](702.01_Analiz_ve_Tasarim_Calismalari/02_EER_Diyagrami/240309910_Gun_EER_Drawio.pdf) · [Proje önerisi PDF](703.01_Proje_Yonetimi/03_Teslim/01_Proje_Onerisi/240309910_Gün.pdf) · [Güncel ZIP](https://github.com/msgxr/LBLM303-Endustriyel-Bakim-Sistemi/archive/refs/heads/main.zip) · [Lisans](LICENSE)
