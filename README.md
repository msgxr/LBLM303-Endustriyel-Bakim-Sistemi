# LBLM303 Endüstriyel Ekipman Bakım Yönetim Sistemi

![SQL Server](https://img.shields.io/badge/Microsoft-SQL_Server-CC2927?logo=microsoftsqlserver&logoColor=white)
![T-SQL](https://img.shields.io/badge/Dil-T--SQL-1F4E78)
![Sürüm](https://img.shields.io/badge/Sürüm-v1.0.0-success)
![Durum](https://img.shields.io/badge/Durum-Doğrulandı-success)
![Lisans](https://img.shields.io/badge/Lisans-Tüm_Hakları_Saklıdır-lightgrey)

## 1. Projenin amacı

Bu proje; endüstriyel ekipmanların sensör ölçümlerini, alarmlarını, arızalarını, bakım emirlerini, teknisyen görevlendirmelerini, yedek parça stoklarını, duruş sürelerini ve bakım maliyetlerini tek bir ilişkisel veritabanı üzerinden yönetmek amacıyla geliştirilmiştir.

Proje, İstanbul Arel Üniversitesi Bilgisayar Mühendisliği Bölümü **LBLM303 Veritabanı Yönetim Sistemleri** dersi kapsamında Microsoft SQL Server ve T-SQL kullanılarak hazırlanmıştır.

## 2. Doğrulanmış teknik kapsam

| Bileşen | Beklenen değer |
|---|---:|
| Tablo | 17 |
| Görünüm | 6 |
| Saklı yordam | 6 |
| Tetikleyici | 7 |
| Ekipman türü | 10 |
| Ekipman | 100 |
| Sensör | 300 |
| Ölçüm | 90.000 |
| Toplam veri hedefi | 80.000–100.000 kayıt |

Sistemde 3NF yaklaşımı, Primary Key, Foreign Key, UNIQUE ve CHECK kısıtları, transaction yönetimi, tetikleyiciler, saklı yordamlar, rol tabanlı yetkilendirme, denetim kayıtları ve performans indeksleri kullanılmaktadır.

## 3. Proje klasörleri

```text
LBLM303_Endustriyel_Bakim_Projesi_SDP
├── 702.01_Analiz_ve_Tasarim_Calismalari
│   ├── 01_Gereksinimler
│   ├── 02_EER_Diyagrami
│   └── 03_Veri_Sozlugu
├── 702.02_Kodlama_Calismalari
│   ├── 01_Veritabani
│   ├── 02_Tablolar
│   ├── 03_Kisitlar
│   ├── 04_Ornek_Veriler
│   ├── 05_Gorunumler
│   ├── 06_Sakli_Yordamlar
│   ├── 07_Tetikleyiciler
│   ├── 08_Yetkilendirme
│   ├── 09_Indeksler
│   └── 10_Rapor_Sorgulari
├── 702.03_Test_Calismalari
│   ├── 01_Dogrulama
│   └── 02_Performans
└── 703.01_Proje_Yonetimi
    ├── 01_Planlama
    ├── 02_Rapor_ve_Sunum
    ├── 03_Teslim
    └── 04_Yedekler
```

## 4. Gereksinimler

Projeyi çalıştırmak için aşağıdaki bileşenler gereklidir:

- Windows 10 veya Windows 11
- Microsoft SQL Server
- Windows Authentication ile çalışan bir SQL Server örneği
- SQL Server Management Studio veya VS Code SQL Server eklentisi
- Komut satırından çalıştırma için Microsoft SQLCMD
- GitHub işlemleri için Git ve GitHub CLI

Varsayılan bağlantı bilgileri:

| Ayar | Değer |
|---|---|
| Sunucu | `localhost` |
| Kimlik doğrulama | Windows Authentication |
| Veritabanı | `EndustriyelBakimDB` |
| Sertifika | Trust Server Certificate açık |

## 5. Projeyi GitHub üzerinden indirme

Depoya erişim yetkiniz varsa PowerShell üzerinde şu komutları çalıştırın:

```powershell
Set-Location $env:USERPROFILE
git clone https://github.com/msgxr/LBLM303-Endustriyel-Bakim-Sistemi.git
Set-Location .\LBLM303-Endustriyel-Bakim-Sistemi
```

Depo özel durumdaysa GitHub hesabıyla giriş yapılması gerekir:

```powershell
gh auth login --hostname github.com --git-protocol https --web
```

## 6. SQL Server hizmetini kontrol etme

PowerShell terminalinde SQL Server hizmetlerini listeleyin:

```powershell
Get-Service | Where-Object {$_.Name -like 'MSSQL*' -or $_.Name -like 'SQLAgent*'}
```

Varsayılan SQL Server hizmeti durmuşsa yönetici PowerShell penceresinde başlatın:

```powershell
Start-Service MSSQLSERVER
```

SQL Server Express kullanılıyorsa hizmet ve sunucu adı çoğunlukla şöyledir:

```text
Hizmet: MSSQL$SQLEXPRESS
Sunucu: localhost\SQLEXPRESS
```

Bu durumda aşağıdaki komutlardaki `localhost` değerini `localhost\SQLEXPRESS` olarak değiştirin.

## 7. En kolay kurulum: SSMS ile çalıştırma

Bu yöntem, proje ilk kez çalıştırılırken önerilen yöntemdir.

1. SQL Server Management Studio uygulamasını açın.
2. Server name alanına `localhost` yazın.
3. Authentication alanında **Windows Authentication** seçin.
4. Gerekirse bağlantı seçeneklerinden **Trust Server Certificate** ayarını etkinleştirin.
5. **Connect** düğmesine basın.
6. Menüden **File > Open > File** yolunu izleyin.
7. Şu dosyayı açın:

```text
702.02_Kodlama_Calismalari\01_Veritabani\02_Tam_Kurulum_SQLCMD_Gerektirmez.sql
```

8. Araç çubuğundaki **Execute** düğmesine veya `F5` tuşuna basın.
9. İşlem tamamlandığında mesajlar bölümünde hata bulunmadığını kontrol edin.
10. Object Explorer üzerinde **Databases** bölümüne sağ tıklayıp **Refresh** seçin.
11. `EndustriyelBakimDB` veritabanının oluştuğunu doğrulayın.

> **Dikkat:** Tam kurulum dosyası mevcut `EndustriyelBakimDB` veritabanını kaldırıp yeniden oluşturabilir. Önemli veriler varsa önce yedek alınmalıdır.

## 8. VS Code ile çalıştırma

1. VS Code uygulamasında proje klasörünü açın.
2. Microsoft tarafından yayımlanan **SQL Server (mssql)** eklentisini kurun.
3. `Ctrl+Shift+P` tuşlarına basın.
4. **MS SQL: Connect** komutunu seçin.
5. Sunucu olarak `localhost` yazın.
6. Windows Authentication seçin.
7. Veritabanı seçiminde başlangıç için `master` kullanılabilir.
8. Trust Server Certificate seçeneğini etkinleştirin.
9. Aşağıdaki dosyayı açın:

```text
702.02_Kodlama_Calismalari\01_Veritabani\02_Tam_Kurulum_SQLCMD_Gerektirmez.sql
```

10. **Execute Query** komutuyla dosyanın tamamını çalıştırın.
11. Sonuçlarda 17 tablo, 100 ekipman, 300 sensör ve 90.000 ölçüm oluştuğunu doğrulayın.

## 9. PowerShell ve SQLCMD ile otomatik kurulum

VS Code PowerShell terminalini proje ana klasöründe açın. Terminal satırı yaklaşık olarak şöyle görünmelidir:

```text
PS C:\Users\msgxr\LBLM303_Endustriyel_Bakim_Projesi_SDP>
```

SQLCMD aracının kullanılabilir olduğunu kontrol edin:

```powershell
sqlcmd -?
```

SQLCMD gerektirmeyen birleşik kurulum dosyasını terminalden çalıştırmak için:

```powershell
$kok="$env:USERPROFILE\LBLM303_Endustriyel_Bakim_Projesi_SDP"
sqlcmd -S localhost -E -C -I -b -r 1 -f 65001 -i "$kok\702.02_Kodlama_Calismalari\01_Veritabani\02_Tam_Kurulum_SQLCMD_Gerektirmez.sql"
```

Parametrelerin anlamları:

| Parametre | Açıklama |
|---|---|
| `-S localhost` | SQL Server adresi |
| `-E` | Windows Authentication |
| `-C` | Sunucu sertifikasına güven |
| `-I` | `QUOTED_IDENTIFIER` ayarını etkinleştir |
| `-b` | SQL hatasında başarısız çıkış kodu üret |
| `-r 1` | Hata mesajlarını standart hata akışına gönder |
| `-f 65001` | SQL dosyasını UTF-8 olarak oku |
| `-i` | Çalıştırılacak SQL dosyası |

Komut tamamlandığında `$LASTEXITCODE` değeri `0` olmalıdır:

```powershell
$LASTEXITCODE
```

## 10. Modüler ana kurulum dosyasını çalıştırma

`01_Veritabani_Olusturma.sql` dosyası diğer SQL dosyalarını sırayla çağıran ana dosyadır. Dosya içinde `$(ROOT)` değişkeni kullanılır. PowerShell üzerinden güvenli biçimde çalıştırmak için değişken geçici dosyada gerçek proje yoluyla değiştirilir:

```powershell
$kok="$env:USERPROFILE\LBLM303_Endustriyel_Bakim_Projesi_SDP"
$ana="$kok\702.02_Kodlama_Calismalari\01_Veritabani\01_Veritabani_Olusturma.sql"
$gecici="$env:TEMP\LBLM303_Tam_Kurulum.sql"
$metin=[IO.File]::ReadAllText($ana).Replace('$(ROOT)',$kok)
[IO.File]::WriteAllText($gecici,$metin,[Text.UTF8Encoding]::new($false))
sqlcmd -S localhost -E -C -I -b -r 1 -f 65001 -i $gecici
```

Bu yöntem tabloları, kısıtları, örnek verileri, görünümleri, saklı yordamları, tetikleyicileri, yetkilendirmeyi, indeksleri ve rapor sorgularını belirlenen sırada çalıştırır.

## 11. Kurulumun hızlı doğrulanması

SSMS veya VS Code sorgu ekranında şu sorguyu çalıştırın:

```sql
USE EndustriyelBakimDB;
GO

SELECT
    (SELECT COUNT(*) FROM sys.tables WHERE is_ms_shipped = 0) AS TabloSayisi,
    (SELECT COUNT(*) FROM sys.views WHERE is_ms_shipped = 0) AS GorunumSayisi,
    (SELECT COUNT(*) FROM sys.procedures WHERE is_ms_shipped = 0) AS YordamSayisi,
    (SELECT COUNT(*) FROM sys.triggers WHERE parent_class_desc = N'OBJECT_OR_COLUMN') AS TetikleyiciSayisi,
    (SELECT COUNT_BIG(*) FROM dbo.Ekipmanlar) AS EkipmanSayisi,
    (SELECT COUNT_BIG(*) FROM dbo.Sensorler) AS SensorSayisi,
    (SELECT COUNT_BIG(*) FROM dbo.Olcumler) AS OlcumSayisi;
GO
```

Beklenen temel sonuç:

```text
TabloSayisi          17
GorunumSayisi         6
YordamSayisi          6
TetikleyiciSayisi     7
EkipmanSayisi       100
SensorSayisi        300
OlcumSayisi       90000
```

## 12. Veritabanı bütünlük kontrolü

Fiziksel ve mantıksal veritabanı bütünlüğünü doğrulamak için:

```sql
DBCC CHECKDB (N'EndustriyelBakimDB') WITH NO_INFOMSGS, ALL_ERRORMSGS;
GO

USE EndustriyelBakimDB;
GO

DBCC CHECKCONSTRAINTS WITH ALL_CONSTRAINTS;
GO
```

Hata satırı oluşmaması başarılı sonuç anlamına gelir.

## 13. Doğrulama testlerini çalıştırma

Test dosyaları aşağıdaki sırayla çalıştırılmalıdır:

1. `01_Ekipman_Kayitlarini_Dogrulama.sql`
2. `02_Iliski_ve_Kisit_Testleri.sql`
3. `03_Is_Akisi_Testleri.sql`

PowerShell üzerinden tamamını sırayla çalıştırmak için:

```powershell
$kok="$env:USERPROFILE\LBLM303_Endustriyel_Bakim_Projesi_SDP"
$testler=@(
    "$kok\702.03_Test_Calismalari\01_Dogrulama\01_Ekipman_Kayitlarini_Dogrulama.sql",
    "$kok\702.03_Test_Calismalari\01_Dogrulama\02_Iliski_ve_Kisit_Testleri.sql",
    "$kok\702.03_Test_Calismalari\01_Dogrulama\03_Is_Akisi_Testleri.sql"
)

foreach($test in $testler){
    Write-Host "Çalıştırılıyor: $test" -ForegroundColor Cyan
    sqlcmd -S localhost -E -C -I -b -r 1 -f 65001 -i $test
    if($LASTEXITCODE -ne 0){throw "Test başarısız oldu: $test"}
}
```

### Testlerin anlamı

- **Ekipman kayıt testi:** Temel ekipman ve ilişkili kayıtların varlığını denetler.
- **UNIQUE testi:** Aynı ekipman kodunun ikinci kez eklenmesini engeller.
- **FOREIGN KEY testi:** Var olmayan üst kayda bağlı veri eklenmesini engeller.
- **CHECK testi:** Negatif maliyet ve geçersiz durum gibi değerleri engeller.
- **İş akışı testi:** Ölçüm, alarm, arıza, bakım emri, teknisyen görevlendirme, parça kullanımı ve bakım tamamlama zincirini dener.
- **ROLLBACK:** Test sırasında oluşturulan geçici kayıtları geri alır; gerçek proje verisini değiştirmez.

## 14. Performans testleri

Performans dosyalarını şu sırayla çalıştırın:

1. `702.03_Test_Calismalari\02_Performans\01_Indeks_Oncesi_Olcum.sql`
2. `702.03_Test_Calismalari\02_Performans\02_Indeks_Sonrasi_Olcum.sql`

PowerShell komutları:

```powershell
$kok="$env:USERPROFILE\LBLM303_Endustriyel_Bakim_Projesi_SDP"
sqlcmd -S localhost -E -C -I -b -r 1 -f 65001 -i "$kok\702.03_Test_Calismalari\02_Performans\01_Indeks_Oncesi_Olcum.sql"
sqlcmd -S localhost -E -C -I -b -r 1 -f 65001 -i "$kok\702.03_Test_Calismalari\02_Performans\02_Indeks_Sonrasi_Olcum.sql"
```

Doğrulanan örnek ölçümde mantıksal okuma değeri indeks öncesinde yaklaşık `425`, indeks sonrasında yaklaşık `3` olarak gözlemlenmiştir. Bu değerler SQL Server önbelleği ve çalışma ortamına göre küçük farklılıklar gösterebilir.

## 15. Rapor sorgularını çalıştırma

### MTBF ve MTTR raporları

```text
702.02_Kodlama_Calismalari\10_Rapor_Sorgulari\01_MTBF_MTTR_Raporlari.sql
```

- MTBF, arızalar arasındaki ortalama çalışma süresini gösterir.
- MTTR, bir arızanın ortalama onarım süresini gösterir.

### Maliyet ve duruş raporları

```text
702.02_Kodlama_Calismalari\10_Rapor_Sorgulari\02_Maliyet_ve_Durus_Raporlari.sql
```

- Bakım emri bazında parça ve işçilik maliyetlerini gösterir.
- Ekipman bazında toplam duruş sürelerini raporlar.

## 16. Verileri SSMS içinde görüntüleme

SSMS üzerinde:

1. Databases bölümünü genişletin.
2. `EndustriyelBakimDB` veritabanını genişletin.
3. Tables bölümünü açın.
4. Görmek istediğiniz tabloya sağ tıklayın.
5. **Select Top 1000 Rows** seçeneğine basın.

Elle sorgulamak için:

```sql
USE EndustriyelBakimDB;
GO

SELECT TOP (100) * FROM dbo.Ekipmanlar ORDER BY EkipmanNo;
SELECT TOP (100) * FROM dbo.Sensorler ORDER BY SensorNo;
SELECT TOP (100) * FROM dbo.Olcumler ORDER BY OlcumZamani DESC;
SELECT TOP (100) * FROM dbo.Alarmlar ORDER BY AlarmNo DESC;
SELECT TOP (100) * FROM dbo.BakimEmirleri ORDER BY BakimEmriNo DESC;
```

90.000 ölçümün tamamını aynı anda açmak yerine `TOP`, `WHERE` ve `ORDER BY` kullanılmalıdır.

## 17. Yedek alma ve doğrulama

SQL Server hizmet hesabının erişebileceği bir konum kullanın:

```sql
BACKUP DATABASE EndustriyelBakimDB
TO DISK = N'C:\Users\Public\EndustriyelBakimDB_Nihai.bak'
WITH COPY_ONLY, INIT, CHECKSUM, STATS = 10;
GO

RESTORE VERIFYONLY
FROM DISK = N'C:\Users\Public\EndustriyelBakimDB_Nihai.bak'
WITH CHECKSUM;
GO
```

`RESTORE VERIFYONLY` işleminin başarılı olması, yedek dosyasının SQL Server tarafından okunabildiğini ve geri yükleme yapısının geçerli olduğunu gösterir.

## 18. Sık karşılaşılan hatalar

### `SQLCMD bulunamadı`

GitHub üzerinden Microsoft SQLCMD aracını veya SQL Server Command Line Utilities paketini kurun. Ardından terminali kapatıp yeniden açın ve şu komutu deneyin:

```powershell
sqlcmd -?
```

### `$(ROOT)` yolu bulunamadı

Ana modüler dosya SQLCMD değişkeni beklemektedir. Şu çözümlerden birini kullanın:

- `02_Tam_Kurulum_SQLCMD_Gerektirmez.sql` dosyasını çalıştırın.
- README içindeki geçici dosya oluşturan PowerShell yöntemini kullanın.

### `CREATE INDEX ... QUOTED_IDENTIFIER`

SQLCMD komutuna `-I` parametresini ekleyin:

```powershell
sqlcmd -S localhost -E -C -I -b -i dosya.sql
```

### `Violation of UNIQUE KEY constraint`

Aynı benzersiz kod ikinci kez eklenmeye çalışılmıştır. Bu hata veritabanı kısıtının doğru çalıştığını gösterir. Kurulum tekrar çalıştırılacaksa tam kurulum dosyasıyla veritabanını temiz biçimde yeniden oluşturun.

### `Cannot insert NULL into SensorNo`

Sensör seçen test sorgusu kayıt bulamamıştır veya eski test dosyası çalıştırılmıştır. Güncel `03_Is_Akisi_Testleri.sql` dosyasını ve temiz kurulumu kullanın.

### Türkçe karakterlerin terminalde bozuk görünmesi

Bu durum çoğunlukla yalnız terminal gösterim kodlamasıyla ilgilidir. Terminalde şunu çalıştırabilirsiniz:

```powershell
chcp 65001
[Console]::OutputEncoding=[Text.UTF8Encoding]::new($false)
```

Veritabanı sütunları `NVARCHAR` ve metin sabitleri `N'...'` kullanıyorsa verinin kendisi korunur.

### Veritabanı kullanımda hatası

SSMS ve VS Code içindeki açık sorgu bağlantılarını kapatın. Ardından tam kurulumu yeniden çalıştırın. Tam kurulum sırasında `master` bağlamının görünmesi normaldir; veritabanını kaldırma ve yeniden oluşturma işlemi `master` üzerinden yapılır.

## 19. Sunum sırasında önerilen çalışma sırası

1. GitHub deposundaki README ve klasör yapısını gösterin.
2. EER diyagramını açıp temel ilişkileri açıklayın.
3. `Ekipmanlar`, `Sensorler` ve `Olcumler` tablolarını gösterin.
4. Kurulum dosyasının modüler yapısını açıklayın.
5. Nesne ve kayıt sayısı doğrulama sorgusunu çalıştırın.
6. UNIQUE, FOREIGN KEY ve CHECK testlerini gösterin.
7. Uçtan uca iş akışı testini çalıştırın.
8. İndeks öncesi ve sonrası mantıksal okumaları karşılaştırın.
9. MTBF, MTTR, maliyet ve duruş raporlarını gösterin.
10. CHECKSUM yedeğinin doğrulandığını açıklayın.

## 20. Git ile güncelleme gönderme

Projede değişiklik yaptıktan sonra:

```powershell
Set-Location "$env:USERPROFILE\LBLM303_Endustriyel_Bakim_Projesi_SDP"
git status
git add .
git commit -m "docs: çalıştırma ve doğrulama açıklamaları güncellendi"
git push origin main
```

Yeni sürüm oluşturmak için örnek:

```powershell
git tag -a v1.0.1 -m "Dokümantasyon güncellemesi"
git push origin v1.0.1
gh release create v1.0.1 --title "v1.0.1" --notes "Çalıştırma ve doğrulama dokümantasyonu güncellendi."
```

## 21. Güvenlik ve teslim notları

- `.bak`, `.vs`, geçici günlükler ve isimsiz `SQLQuery` dosyaları GitHub deposuna eklenmez.
- Veritabanı yedeği yerel proje klasöründe veya güvenli bir harici ortamda saklanmalıdır.
- Teslim için yalnız öğretim elemanının istediği PDF ve EER dosyaları kullanılmalıdır.
- Proje bireyseldir; kaynak kodlar başka bir öğrenciyle ortak teslim edilmemelidir.
- Gerçek kullanıcı parolaları veya kişisel erişim belirteçleri SQL dosyalarına yazılmamalıdır.

## 22. Geliştirici

**Muhammed Sina Gün**  
Bilgisayar Mühendisliği  
İstanbul Arel Üniversitesi  
E-posta: mgun345@icloud.com

## 23. Lisans

Bu çalışma bireysel akademik proje kapsamında hazırlanmıştır. İzinsiz kopyalanamaz, dağıtılamaz veya başka bir akademik çalışmada teslim edilemez.
