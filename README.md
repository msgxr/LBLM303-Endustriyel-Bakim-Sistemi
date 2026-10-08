# LBLM303 Endüstriyel Bakım Yönetim Sistemi

![SQL Server](https://img.shields.io/badge/Microsoft-SQL_Server-CC2927?logo=microsoftsqlserver&logoColor=white)
![T-SQL](https://img.shields.io/badge/Kaynak-T--SQL-1F4E78)
![Depo](https://img.shields.io/badge/Depo-Public-blue)
![Lisans](https://img.shields.io/badge/Lisans-Tüm_Hakları_Saklıdır-lightgrey)

Endüstriyel ekipmanların sensör ölçümlerini, alarmlarını, arızalarını, bakım emirlerini, teknisyen görevlendirmelerini, yedek parça hareketlerini ve duruşlarını yöneten SQL Server veritabanı projesidir. LBLM303 Veritabanı Yönetim Sistemleri dersi kapsamında hazırlanmıştır.

İş mantığı T-SQL tabloları, kısıtları, görünümleri, saklı yordamları ve tetikleyicileri üzerinden uygulanır. Ayrı bir web/masaüstü uygulaması bulunmaz. Çalışma ekranı SSMS veya VS Code MSSQL eklentisindeki sorgu ve sonuç penceresidir.

## 1. Önce hangi yolu kullanmalıyım?

| Durum | İzlenecek yol |
|---|---|
| `EndustriyelBakimDB` zaten kurulu | Bölüm 5: kaynak güncelleme; Bölüm 8: veri silmeden güncelleme ve test |
| İlk kez, boş bir SQL Server örneğinde çalıştırıyorum | Bölüm 6: ilk kurulum |
| Terminal kullanmak istemiyorum | Bölüm 7: SSMS / VS Code |
| Hocaya çalışan sistemi göstereceğim | Bölüm 11: sunum sırası |
| Hata aldım | Bölüm 12: hata tablosu; kurulum dosyasını tekrar tekrar çalıştırmayın |

İki mevcut kurulum dosyası aynı normal T-SQL içeriğini taşır:

- `702.02_Kodlama_Calismalari/01_Veritabani/01_Veritabani_Olusturma.sql`
- `702.02_Kodlama_Calismalari/01_Veritabani/02_Tam_Kurulum_SQLCMD_Gerektirmez.sql`

Yalnızca birini kullanın. SQLCMD modu, `:r`, `:setvar` veya `ROOT` değişkeni gerekli değildir. Terminalden SQL çalıştırmak için kullanılan `sqlcmd.exe` ile editörün “SQLCMD modu” farklı şeylerdir.

Güncel kurulum kodu mevcut veritabanını otomatik silmez. Veritabanı varsa kurulum atlanır; bu durum mevcut sistemin güncellendiği veya testleri geçtiği anlamına gelmez. Eksik/yarım kurulumu onarmak için otomatik sıfırlama yapılmaz.

## 2. Teknik kapsam ve kayıt sayıları

Aşağıdaki sayılar yeni kurulumun kaynak kodunda tanımlanan nesne ve temel örnek veri hedefleridir. Mevcut sunucudaki gerçek durum doğrulama sorgusuyla ölçülmelidir.

| Bileşen | Beklenen |
|---|---:|
| Proje tablosu | 17 |
| Görünüm | 6 |
| Saklı yordam | 6 |
| Tetikleyici | 7 |
| Ekipman türü | 10 |
| Ekipman | 100 |
| Sensör | 300 |
| Ölçüm | 90.000 |
| Toplam örnek veri hedefi | 80.000–100.000 |

“Yaklaşık 95.000 kayıt” yuvarlatılmış bir açıklamadır; tam sayı garantisi değildir. 90.000 sayısı yalnız `Olcumler` tablosunu belirtir. Diğer 16 tablodaki satırlar buna eklenir. Kesin toplam, doğrulama dosyasında 17 tablo üzerinde `COUNT_BIG(*)` kullanılarak hesaplanır.

Yeni kayıtlar, denetim kayıtları ve gerçek kullanım toplamı değiştirebilir. Örnek veri üretimini yeniden çalıştırarak 100.000'e zorla tamamlamayın. Gereksinimde farklı bir kesin hedef varsa veri üretimi ayrıca buna göre tasarlanmalıdır.

Bu revizyonda kaynak dosyaları statik olarak incelenmiştir; hedef Windows SQL Server üzerinde çalıştırılmış test sonucu yerine geçmez. Tüm testlerin geçtiği ancak Bölüm 8 çalıştırılıp sonuçları görüldüğünde söylenebilir. PDF raporuyla şemanın birebir eşleştiği de yalnız bu sayı tablosundan çıkarılamaz.

## 3. Dosyalar ve görevleri

| Klasör | İçerik / kullanım |
|---|---|
| `702.01_Analiz_ve_Tasarim_Calismalari/02_EER_Diyagrami` | EER PDF |
| `702.02_Kodlama_Calismalari/01_Veritabani` | İlk kurulum için birleşik normal SQL |
| `702.02_Kodlama_Calismalari/02_Tablolar` | 17 tablonun ayrı kaynak dosyaları |
| `702.02_Kodlama_Calismalari/03_Kisitlar` | İlişkiler, CHECK/UNIQUE kuralları ve filtreli tekil indeksler |
| `702.02_Kodlama_Calismalari/04_Ornek_Veriler` | Tür, ekipman, sensör ve toplu örnek veri |
| `702.02_Kodlama_Calismalari/05_Gorunumler` | Okuma ve raporlama görünümleri |
| `702.02_Kodlama_Calismalari/06_Sakli_Yordamlar` | Altı iş akışı yordamı |
| `702.02_Kodlama_Calismalari/07_Tetikleyiciler` | Yedi tetikleyicinin tanımı |
| `702.02_Kodlama_Calismalari/08_Yetkilendirme` | SQL veritabanı rolleri ve izinler |
| `702.02_Kodlama_Calismalari/09_Indeksler` | Performans indeksleri |
| `702.02_Kodlama_Calismalari/10_Rapor_Sorgulari` | MTBF/MTTR, maliyet, duruş ve stok sorguları |
| `702.03_Test_Calismalari/01_Dogrulama` | Üç hata denetimli doğrulama testi |
| `702.03_Test_Calismalari/02_Performans` | Tarama / optimize edilmiş erişim karşılaştırması |
| `703.01_Proje_Yonetimi/03_Teslim/01_Proje_Onerisi` | Proje önerisi ve EER PDF |

Git boş klasörleri saklamaz. Yerel klasör ağacının GitHub'dan indirilen kopyada daha kısa olması, tek başına kaynak dosyaların silindiği anlamına gelmez.

### Tablolar

| Tablo | Rolü |
|---|---|
| `EkipmanTurleri` | Ekipman sınıflandırması |
| `Ekipmanlar` | Ekipman kimliği ve konumu |
| `Sensorler` | Ekipmana bağlı sensörler ve eşikler |
| `Olcumler` | Zaman damgalı sensör ölçümleri |
| `Alarmlar` | Eşik aşımı ve inceleme bilgileri |
| `Arizalar` | Ekipman arızaları ve alarm bağlantısı |
| `BakimEmirleri` | Planlı/düzeltici/önleyici bakım işleri |
| `Teknisyenler` | Teknisyen bilgileri ve saatlik ücret |
| `BakimGorevlendirmeleri` | Bakım–teknisyen ilişkisi ve çalışma süresi |
| `YedekParcalar` | Parça tanımı, maliyet ve asgari stok |
| `BakimParcalari` | Bakımda kullanım/iade bilgileri |
| `StokHareketleri` | Stok giriş, çıkış ve kullanım hareketleri |
| `DurusKayitlari` | Ekipman duruş başlangıç/bitiş bilgileri |
| `Kullanicilar` | Uygulama kullanıcı bilgileri |
| `Roller` | Uygulama rol tanımları |
| `KullaniciRolleri` | Kullanıcı–rol eşleştirmesi |
| `DenetimKayitlari` | Bakım emri ve stok değişikliklerinin denetimi |

## 4. Gereksinimler ve bağlantı

Bu kılavuzun terminal örnekleri Windows PowerShell ve SQL Server `sqlcmd` istemcisi içindir.

- SQL Server Database Engine kurulu ve çalışıyor olmalıdır. SSMS/VS Code tek başına veritabanı motoru kurmaz.
- Kod `CREATE OR ALTER` ve JSON ifadelerini kullanır; SQL Server 2016 SP1 veya daha yeni bir sürüm gerekir. Kullanılacak sürümün destek durumunu ayrıca değerlendirin.
- İlk kurulum için veritabanı oluşturma ve nesne/rol tanımlama izinleri gerekir.
- Tam doğrulama paketi, özellikle denetim koruma tetikleyicisi testi için sistem yöneticisi veya veritabanı sahibi bağlantısıyla çalıştırılmalıdır. Bu, uygulama kullanıcılarına genel yönetici yetkisi verilmesi önerisi değildir.
- Git sadece depo indirme/güncelleme için gerekir. Public depoyu okumak için GitHub hesabı veya `gh auth login` zorunlu değildir.
- Komut örnekleri `localhost` üzerindeki Windows Authentication bağlantısını kullanır. Başka bir SQL Server örneğinde sunucu adı ve yetkilendirme uyarlanmalıdır.
- Kimlik doğrulama/parola bilgilerini README'ye veya kaynak dosyalara yazmayın.

| Örnek türü | Sunucu adı |
|---|---|
| Varsayılan yerel SQL Server | `localhost` |
| Yerel SQL Server Express, örnek adı SQLEXPRESS ise | `localhost\SQLEXPRESS` |
| Yerel LocalDB, mevcut örnek adı bu ise | `(localdb)\MSSQLLocalDB` |
| Başka makinedeki SQL Server | Gerçek sunucu ve örnek/port adresi |

Bu isimler kurulu sunucunuza göre seçilir; sırayla rastgele denenerek kurulum başlatılmaz.

PowerShell'de kullanılabilir araçları ve hizmetleri görmek için:

```powershell
Get-Command git.exe, sqlcmd.exe -ErrorAction SilentlyContinue
Get-Service | Where-Object { $_.Name -like 'MSSQL*' }
sqlcmd -?
```

Hizmet durmuşsa ve hizmet yönetme yetkiniz varsa, doğru hizmeti yönetici PowerShell'de başlatın. Örneğin varsayılan örnek için:

```powershell
Start-Service -Name 'MSSQLSERVER'
```

Express örneğinin hizmet adı, gerçekten SQLEXPRESS adıyla kuruluysa `'MSSQL$SQLEXPRESS'` olur. PowerShell'de dolar işaretini değişken olarak yorumlatmamak için tek tırnak kullanın. Bu işlem SQL Server kurmaz ve SQL bağlantı izinlerini otomatik düzeltmez.

Bağlantıyı veritabanını değiştirmeden kontrol edin:

```powershell
sqlcmd -S localhost -E -C -b -r 1 -Q "SELECT @@SERVERNAME AS Sunucu, SERVERPROPERTY('ProductVersion') AS Surum, SUSER_SNAME() AS Oturum, DB_ID(N'EndustriyelBakimDB') AS VeritabaniNo;"
if ($LASTEXITCODE -ne 0) { throw 'SQL Server baglantisi basarisiz. Kuruluma gecmeyin.' }
```

`VeritabaniNo` NULL ise bu sunucuda görünür bir proje veritabanı yoktur. NULL olmayan değer mevcut veritabanını gösterir. Yanlış örneğe bağlanmadığınızdan emin olun.

`-C` geliştirme ortamındaki sunucu sertifikasına güvenmek içindir; üretim ortamında doğru sertifika doğrulamasının yerine geçmez.

## 5. Public GitHub deposunu alma ve güncelleme

### İlk indirme: Git

Var olan çalışma klasörünüzü ezmeden yeni kopya oluşturun:

```powershell
Set-Location -LiteralPath $env:USERPROFILE
git clone https://github.com/msgxr/LBLM303-Endustriyel-Bakim-Sistemi.git
if ($LASTEXITCODE -ne 0) { throw 'Depo indirilemedi.' }
Set-Location -LiteralPath '.\LBLM303-Endustriyel-Bakim-Sistemi'
```

Bundan sonraki dosya yolları bulunduğunuz proje köküne göredir. Projenin `C:\Users\msgxr` altında olması zorunlu değildir.

### Git kurmadan: ZIP

1. [Depoyu](https://github.com/msgxr/LBLM303-Endustriyel-Bakim-Sistemi) açın.
2. `Code > Download ZIP` seçin.
3. ZIP'i bir klasöre çıkarın; SQL dosyalarını ZIP içinden çalıştırmayın.
4. SSMS ile Bölüm 7'yi uygulayın.

ZIP indirmek `.git` geçmişini oluşturmaz; bu kopyada `git pull` çalışmaz. Yeni sürüm için yeniden ZIP indirin veya Git ile ayrı bir kopya oluşturun. GitHub'daki kaynak ZIP ile akademik teslim ZIP'i aynı amaçta değildir.

### Var olan Git çalışma kopyasını güncelleme

Önce mevcut SQL editörlerindeki kaydedilmemiş değişiklikleri kaydedin. Aşağıdaki kod sadece temiz çalışma kopyasında ilerler; yerel değişiklikleri silmez:

```powershell
& {
    $ErrorActionPreference = 'Stop'
    Set-Location -LiteralPath "$env:USERPROFILE\LBLM303_Endustriyel_Bakim_Projesi_SDP"
    git status --short
    if ($LASTEXITCODE -ne 0) { throw 'Bu klasor Git deposu degil.' }
    $yerelDegisiklikler = @(git status --porcelain)
    if ($LASTEXITCODE -ne 0) { throw 'Git durumu okunamadi.' }
    if ($yerelDegisiklikler.Count -gt 0) { throw 'Yerel degisiklik var. Silmeyin; once inceleyin ve koruyun.' }
    git pull --ff-only origin main
    if ($LASTEXITCODE -ne 0) { throw 'Guncelleme tamamlanmadi. Teste gecmeyin.' }
    git log -1 --oneline
}
```

Kendi klasör adınız farklıysa yalnız `Set-Location` yolunu değiştirin. `git pull` SQL Server'a kod yüklemez; sadece kaynak dosyalarını günceller. Veritabanındaki nesneler için Bölüm 8 kullanılmalıdır.

## 6. İlk kurulum: yalnız proje veritabanı yoksa

1. Bölüm 4'teki salt okunur bağlantı sorgusunu çalıştırın.
2. Doğru sunucuda `EndustriyelBakimDB` bulunmadığını kontrol edin.
3. Kaynak dosyaların güncel olduğunu doğrulayın.
4. Proje kökünde şu PowerShell kodunu çalıştırın:

```powershell
& {
    $ErrorActionPreference = 'Stop'
    $sqlcmd = (Get-Command sqlcmd.exe -ErrorAction Stop).Source
    $kurulum = Join-Path (Get-Location).Path '702.02_Kodlama_Calismalari\01_Veritabani\01_Veritabani_Olusturma.sql'
    if (-not (Test-Path -LiteralPath $kurulum)) { throw 'Proje kok klasorunde degilsiniz.' }
    [Console]::OutputEncoding = [System.Text.UTF8Encoding]::new($false)
    & $sqlcmd -S localhost -E -C -I -b -r 1 -f 65001 -i $kurulum
    if ($LASTEXITCODE -ne 0) { throw 'Kurulum hata verdi. Ayni dosyayi yeniden calistirmadan hatayi inceleyin.' }
}
```

Başarılı yeni kurulumun sonunda yapısal kontrol kayıt sayılarını listeler. Bu çıktı iş akışı testinin de geçtiğini göstermez; Bölüm 8'deki testleri ayrıca çalıştırın.

Mevcut veritabanı varsa `KURULUM ATLANDI` mesajı gelir. Veriler ve nesneler değiştirilmez; güncelleme için Bölüm 8'e geçin. Güvenlik kontrolünü atlamak için dosyanın ortasından bir bölüm seçip çalıştırmayın.

Kurulum, birden fazla SQL batch içerir ve tüm veritabanı oluşturma adımlarını tek transaction içinde atomik yapmaz. Yarım kurulum oluşursa hata mesajını ve mevcut nesneleri inceleyin; otomatik silme veya otomatik “tamir” uygulanmaz. SSMS tüm batch'lerde kendiliğinden durmayabilir; hata sonrası gelen başka bir bilgi mesajını başarı saymayın.

### Terminal parametreleri

| Parametre | Amaç |
|---|---|
| `-S` | Hedef SQL Server örneği |
| `-E` | Windows Authentication |
| `-C` | Sunucu sertifikasına güvenme |
| `-I` | ODBC sqlcmd için QUOTED_IDENTIFIER başlangıç ayarı |
| `-b` | SQL hata seviyesine göre başarısız çıkış kodu ve durdurma |
| `-r 1` | Hata/bilgi mesajlarını hata akışına yönlendirme |
| `-f 65001` | UTF-8 dosya / çıktı kod sayfası |
| `-i` | SQL dosyasını çalıştırma |
| `-Q` | Doğrudan SQL sorgusu çalıştırma |

`sqlcmd` için ODBC ve Go uygulamaları bulunur; bazı seçeneklerin davranışı farklıdır. Örneğin Go sürümünde `-I` dikkate alınmaz. Güncel SQL dosyaları gerekli SET seçeneklerini açıkça yazar. Kullandığınız istemcinin `sqlcmd -?` çıktısı desteklenen seçenekler için esas alınmalıdır.

## 7. SSMS ve VS Code: terminal olmadan çalışma

### SSMS

1. SSMS'yi açın ve Database Engine'e bağlanın.
2. Server name alanına gerçekten kurulu örneği yazın; yerel varsayılan örnek için `localhost`.
3. Authentication olarak Windows Authentication seçin.
4. Yerel geliştirme bağlantısı için gerekiyorsa Trust Server Certificate seçin.
5. `File > Open > File` ile proje kökündeki mevcut `.sql` dosyasını açın.
6. İlk kurulumda Bölüm 6'daki `01_Veritabani_Olusturma.sql` dosyasının tamamını `Execute / F5` ile çalıştırın.
7. Veritabanı zaten kuruluysa kurulum dosyasını değil, Bölüm 8'deki güncelleme modüllerini ve testleri aynı sırayla açın.
8. Her dosyanın `Messages` bölümünü kontrol edin. Beklenmeyen hata varsa sonraki dosyaya geçmeyin.
9. Object Explorer'da `Databases > Refresh` yapın; `EndustriyelBakimDB` altında Tables, Views, Programmability ve Security bölümlerini inceleyin.

Güncel kaynakta özel SQLCMD yönergeleri bulunmadığı için SSMS SQLCMD modu gerekli değildir. `GO` batch ayırıcıları SSMS ve sqlcmd tarafından işlenir; SQL Server'a doğrudan tek metin gönderen her API bunları otomatik işlemez.

### VS Code

1. `File > Open Folder` ile mevcut proje kökünü açın.
2. Microsoft'un `SQL Server (mssql)` eklentisini kurun/etkinleştirin.
3. MSSQL bağlantı görünümünden veya komut paletindeki bağlantı komutundan sunucu bağlantısı oluşturun.
4. SQL Server adresi ve Windows Authentication bilgilerini seçin.
5. Kurulum için `master`; kurulu sistemin testleri için `EndustriyelBakimDB` bağlantı bağlamını kullanın.
6. Gezgin ağacındaki mevcut `.sql` dosyasını açın; yeni “Untitled” dosya oluşturmanız gerekmez.
7. Dosyanın tamamını eklentinin sorgu çalıştırma komutuyla yürütün.
8. Results ve Messages bölümlerini birlikte inceleyin.

SQL kodunu PowerShell terminaline doğrudan yapıştırmayın. SQL editöründe `USE / SELECT / EXEC` çalışır; PowerShell terminalinde `sqlcmd ...` komutu çalışır.

Editördeki kırmızı çizgi veya dosya rozeti tek başına SQL Server çalışma hatası değildir. Bağlantı, veritabanı bağlamı, kaydedilmemiş dosya ve IntelliSense önbelleğini kontrol edin; gerçek hata Messages/terminal çıktısındadır.

## 8. Mevcut veritabanını silmeden güncelleme ve üç test

Bu yol var olan tabloları yeniden oluşturmaz, örnek veri üretimini tekrar çalıştırmaz ve veritabanını silmez.

Güncellenecek tanımlar sırayla: görünümler, yordamlar, tetikleyiciler, roller/izinler ve eksik performans indeksleri. Tablo ve kısıt modülleri ilk kurulum içindir; zaten kurulu veritabanında tekrar çalıştırılmaz.

Tetikleyici dosyasında örnek veriyi düzelten eski UPDATE bölümü kaldırılmıştır; mevcut tanımları değiştirmek için kullanıldığında veri satırlarını düzenlemez. Rol dosyası mevcut izinleri tekrar uygular; gerçek login oluşturmaz veya hesapları otomatik role atamaz.

Bu işlem DDL değişikliği yapar. Paylaşılan/üretim sunucusunda bakım zamanı ve geri dönüş planı gerektirir. Buradaki akış, yerel akademik test ortamı içindir.

Proje kökünde PowerShell'e aşağıdaki bloğun tamamını yapıştırın; ayrı bir `.ps1` dosyası gerekmez:

```powershell
& {
    $ErrorActionPreference = 'Stop'
    $sqlcmd = (Get-Command sqlcmd.exe -ErrorAction Stop).Source
    $sunucu = 'localhost'
    $kok = (Get-Location).Path
    $dosyalar = @(
        '702.02_Kodlama_Calismalari\05_Gorunumler\01_Gorunumler.sql'
        '702.02_Kodlama_Calismalari\06_Sakli_Yordamlar\01_Sakli_Yordamlar.sql'
        '702.02_Kodlama_Calismalari\07_Tetikleyiciler\01_Tetikleyiciler.sql'
        '702.02_Kodlama_Calismalari\08_Yetkilendirme\01_Roller_ve_Izinler.sql'
        '702.02_Kodlama_Calismalari\09_Indeksler\01_Indeksler.sql'
        '702.03_Test_Calismalari\01_Dogrulama\01_Ekipman_Kayitlarini_Dogrulama.sql'
        '702.03_Test_Calismalari\01_Dogrulama\02_Iliski_ve_Kisit_Testleri.sql'
        '702.03_Test_Calismalari\01_Dogrulama\03_Is_Akisi_Testleri.sql'
    )
    foreach ($dosya in $dosyalar) {
        if (-not (Test-Path -LiteralPath (Join-Path $kok $dosya))) {
            throw "Dosya eksik: $dosya. Proje kokunu ve Git guncellemesini kontrol edin."
        }
    }
    [Console]::OutputEncoding = [System.Text.UTF8Encoding]::new($false)
    & $sqlcmd -S $sunucu -E -C -b -r 1 -Q "IF DB_ID(N'EndustriyelBakimDB') IS NULL THROW 52100, 'Proje veritabani bulunamadi. Bu komut ilk kurulum yapmaz.', 1;"
    if ($LASTEXITCODE -ne 0) { throw 'Baglanti veya mevcut veritabani kontrolu basarisiz.' }
    foreach ($dosya in $dosyalar) {
        Write-Host ("CALISTIRILIYOR: " + $dosya) -ForegroundColor Cyan
        & $sqlcmd -S $sunucu -E -C -I -b -r 1 -f 65001 -i (Join-Path $kok $dosya)
        if ($LASTEXITCODE -ne 0) {
            throw "Islem durdu: $dosya. Yukaridaki SQL hatasini inceleyin."
        }
    }
    Write-Host 'Guncelleme ve uc dogrulama dosyasi hata cikis kodu olmadan tamamlandi.' -ForegroundColor Green
}
```

Yalnız test çalıştırmak isterseniz, tanımların güncel olduğundan emin olduktan sonra aynı listedeki son üç dosyayı kullanın. Sunucu adınız farklıysa `$sunucu` değerini değiştirin.

PowerShell'de `$ErrorActionPreference = 'Stop'`, harici programların her başarısız çıkışını tek başına durdurmaz. Bu nedenle her `sqlcmd` çağrısından sonra `$LASTEXITCODE` ayrıca denetlenir.

### Testlerin anlamı

| Test dosyası | Kontrol |
|---|---|
| `01_Ekipman_Kayitlarini_Dogrulama.sql` | Beklenen 17 tablo, 6 görünüm, 6 yordam, 7 tetikleyici; adlandırılmış kısıtlar; etkin/güvenilir FK-CHECK; birincil anahtarlar; beklenen indeksler; dört SQL rolü; her tablonun gerçek sayımı; temel veri hedefleri; mevcut FK/CHECK ihlalleri; tekrarlar; negatif stok; aktif bakım tekilliği |
| `02_Iliski_ve_Kisit_Testleri.sql` | Altı olumsuz senaryo: tekrar ekipman kodu, geçersiz FK, negatif maliyet, denetim UPDATE, denetim DELETE, negatif stok |
| `03_Is_Akisi_Testleri.sql` | Ölçüm → alarm → inceleme → arıza → bakım → teknisyen → stok/parça → tamamlama → denetim → ROLLBACK |

İkinci test yalnız doğru hata kodu/kuralı oluşursa başarılıdır. Örneğin bağlantı veya yetki hatası artık “başarılı kısıt testi” sayılmaz.

Üçüncü test final durumların `Alarm=Kapalı`, `Arıza=Kapalı` ve `Bakım=Tamamlandı` olduğunu kontrol eder; +100 giriş ve 2 parça kullanımının stokta +98 değişim yaptığını doğrular. Duruş başlangıcını test kendisi ekler; bitişini bakım tamamlama yordamı kapatır. Bu, arıza açılınca duruşun otomatik oluşturulduğu iddiası değildir.

Test 2 ve 3 geçici işlemler yapar ve geri alır; satırlar kalıcı bırakılmaz. IDENTITY değerleri tüketilebilir, sonraki numaralarda boşluk oluşabilir. Bu veri kaybı değildir. Test sırasında başka bir kullanıcı aynı kayıtlarda işlem yapmamalıdır.

İlk testte `@OrnekVeriHedefiniZorunluTut = 1` toplam örnek veri için 80.000–100.000 aralığını zorunlu tutar. Gerçek kullanımda bu aralık bilinçli aşılmışsa testte bu değişken `0` yapılabilir; diğer kontroller devam eder. Bu değişiklik, eksik temel örnek veri veya bozuk ilişkileri gizlemez.

Bütün testlerin geçmesi tüm olası eşzamanlılık, yetki, güvenlik ve iş kuralı senaryolarının ispatı değildir. Sonuçlara dayanarak yalnız çalıştırılan kontrollerin geçtiği söylenir.

## 9. Performans: doğru karşılaştırma

Mevcut iki dosyanın isimleri tarihsel olarak “indeks öncesi/sonrası”dır. Güncel deney fiziksel olarak indeks silip yeniden oluşturmaz:

- İlk dosya `WITH (INDEX(0))` ile tablo/clustered-index taramasını zorlar.
- İkinci dosya aynı sorguyu bu ipucu olmadan çalıştırır; erişim yolunu optimizer seçer.
- Her ikisi ilk sensörün en yeni ölçümüne göre aynı son 30 günlük pencereyi kullanır. Eski örnek veride sorgunun zamanla boşalması önlenir.
- İkinci dosya beklenen indeksin mevcut ve etkin olduğunu kontrol eder. İndeksin gerçekten seçildiği actual execution plan üzerinden görülmelidir.
- Sunucu genelindeki cache temizlenmez. `DBCC DROPCLEANBUFFERS` veya `FREEPROCCACHE` kullanılmaz.

Proje kökünden:

```powershell
& {
    $ErrorActionPreference = 'Stop'
    foreach ($dosya in @(
        '.\702.03_Test_Calismalari\02_Performans\01_Indeks_Oncesi_Olcum.sql'
        '.\702.03_Test_Calismalari\02_Performans\02_Indeks_Sonrasi_Olcum.sql'
    )) {
        sqlcmd -S localhost -E -C -I -b -r 1 -f 65001 -i $dosya
        if ($LASTEXITCODE -ne 0) { throw "Performans sorgusu durdu: $dosya" }
    }
}
```

SSMS'de Actual Execution Plan'ı açarak aynı dosyaları çalıştırabilirsiniz. Karşılaştırmada `Olcumler` tablosunun logical reads değerini, aynı sensör/tarih aralığını ve dönen satır sayısını kaydedin. CPU ve elapsed time küçük sorgularda 0 ms görünebilir; tek ölçüm kesin hızlanma oranı sayılmaz. Cache ve donanım fiziksel okuma/süreyi etkiler.

Önceki bir çalıştırmada paylaşılan 425 ve 3 logical read değerleri o çalıştırmaya aittir. Güncel sorguda ve başka bilgisayarda aynı değerler garanti edilmez. Sonuçlara ölçüm tarihi, SQL sürümü ve deney türüyle birlikte yer verin; “gerçek indeks kaldırma öncesi/sonrası” diye sunmayın.

## 10. Veriyi ve raporları ekranda gösterme

SSMS/VS Code SQL editörüne:

```sql
USE EndustriyelBakimDB;
GO
SELECT TOP (20) * FROM dbo.vw_EkipmanOzeti ORDER BY EkipmanNo;
SELECT TOP (20) * FROM dbo.vw_GuncelAlarmlar ORDER BY AlarmNo DESC;
SELECT TOP (20) * FROM dbo.vw_AktifBakimEmirleri ORDER BY BakimEmriNo DESC;
SELECT TOP (20) * FROM dbo.vw_StokDurumu ORDER BY ParcaNo;
SELECT TOP (20) * FROM dbo.vw_BakimMaliyetleri ORDER BY BakimEmriNo DESC;
SELECT TOP (20) * FROM dbo.vw_EkipmanMTBF_MTTR ORDER BY EkipmanNo;
GO
```

`vw_GuncelAlarmlar` tüm durumları içerir; yalnız açıkları görmek için `WHERE Durum IN (N'Açık', N'İncelendi')` ekleyin.

Tam rapor dosyaları:

```powershell
& {
    foreach ($dosya in @(
        '.\702.02_Kodlama_Calismalari\10_Rapor_Sorgulari\01_MTBF_MTTR_Raporlari.sql'
        '.\702.02_Kodlama_Calismalari\10_Rapor_Sorgulari\02_Maliyet_ve_Durus_Raporlari.sql'
    )) {
        sqlcmd -S localhost -E -C -I -b -r 1 -f 65001 -i $dosya
        if ($LASTEXITCODE -ne 0) { throw "Rapor sorgusu durdu: $dosya" }
    }
}
```

MTBF görünümü ardışık arıza açılışları arasındaki ortalama saat farkını; MTTR kapanmış arızaların açılış–kapanış saat farkını hesaplar. Yeterli geçmiş yoksa NULL değer anlamlıdır. Bu tanımlar her endüstriyel güvenilirlik standardının birebir uygulaması olarak sunulmamalıdır.

İşçilik, görevlendirmedeki tamamlanmış çalışma süresi ve işlem anındaki saatlik ücret üzerinden; parça maliyeti kullanım eksi iade üzerinden hesaplanır. Mevcut kullanılabilirlik sorgusu duruş aralıklarını toplar; çakışan duruşları birleştirmez. Çakışan veride sonucu kesin fiziksel kullanılabilirlik oranı saymayın.

## 11. Hocaya sunum: baştan sona sıra

Kurulum sunumdan önce tamamlanmalıdır. Derste veritabanını yeniden oluşturmak gerekmez.

| Sıra | Gösterilecek işlem | Kanıt / yorum |
|---:|---|---|
| 1 | EER PDF'yi açın | Varlıklar, PK/FK ve ilişkiler |
| 2 | SQL Server bağlantısını gösterin | Sunucu adı, sürüm, veritabanı |
| 3 | İlk doğrulama dosyasını çalıştırın | Nesneler ve 17 tablonun kesin kayıt toplamı |
| 4 | İkinci doğrulama dosyasını çalıştırın | Altı hatalı işlemin doğru kurallarla engellenmesi |
| 5 | Üçüncü doğrulama dosyasını çalıştırın | Sekiz adım mesajı; son durumlar; stok; denetim; geri alma |
| 6 | Altı görünümden kısa sonuç gösterin | Çalışma ekranı ve raporlama |
| 7 | İki performans sorgusunu çalıştırın | Aynı aralık/satır sayısı; logical reads ve actual plan |
| 8 | MTBF/MTTR ve maliyet/duruş raporlarını gösterin | Formülleri ve sınırlamaları açıklayın |
| 9 | Kayıt sayımını yeniden çalıştırın | Test satırlarının kalıcı bırakılmadığını gösterin |
| 10 | Kaynak SQL ve PDF dosyalarını gösterin | README'nin canlı sonuçlarla tutarlı olduğunu kontrol edin |

Hocaya anlatılabilecek özet:

> Ölçüm eşik dışına çıktığında tetikleyici alarm oluşturur. Alarm incelendikten sonra arıza ve bakım emri açılır. Teknisyen görevlendirilir, kullanılan parça stok hareketine işlenir ve bakım tamamlandığında bağlantılı kayıtlar kapanır. Bakım emri ve stok değişiklikleri denetim tablosuna yazılır. Test tüm bu adımları geçici bir işlemde yürütür ve sonunda geri almayı da doğrular.

Bir adım hata verirse kalan adımları “geçti” diye işaretlemeyin. İlk hatanın mesajı, dosya adı ve satır numarasını kaydedin; yanlış başarı çıktısını sunuma eklemeyin.

## 12. Hatalar ve güvenli çözüm

| Belirti | Açıklama / izlenecek yol |
|---|---|
| `Changed database context to 'master'` | İlk veritabanı oluşturma için normal bağlam mesajı; tek başına hata değil |
| `$(ROOT)` / dosya bulunamadı | Eski kurulum dosyası çalıştırılıyor olabilir. Güncel normal SQL dosyasını alın; yeni kaynak bu yönergeleri kullanmaz |
| `QUOTED_IDENTIFIER` / Msg 1934 | Dosyanın güncel SET seçeneklerini içerdiğini kontrol edin. Eski yordamlar için güncel tanımları Bölüm 8 sırasıyla uygulayın |
| Msg 2627 / 2601 | UNIQUE ihlali. İkinci testin doğrulanmış senaryosu dışındaysa yinelenen gerçek veriyi araştırın; kısıtı kaldırmayın |
| Msg 515 / NULL SensorNo | Sensör seçimi veya örnek veri eksik. Güncel test önkoşulları açıklayıcı hata verir; sensör sütununu nullable yapmayın |
| Msg 547 | FK veya CHECK ihlali. Hangi kuralın adının yazdığını okuyun; rastgele hata başarı sayılmaz |
| Msg 229 / permission denied | Kullanıcı yetkisi yetersiz. Yetkili bağlantı kullanın veya yöneticiden gerekli izni isteyin; dosya/DB izinlerini rastgele genişletmeyin |
| SQLCMD bulunamadı | Microsoft istemcisini kurun veya SSMS yolunu kullanın. SQL Server motoru ile istemci ayrı bileşenlerdir |
| Bağlantı/login hatası | Örnek adı, hizmet, kimlik doğrulama ve yetkiyi salt okunur bağlantı sorgusuyla kontrol edin |
| PowerShell `>>` gösteriyor | Eksik kapanan tırnak/parantez/bloğun devamını bekliyor. `Ctrl+C` ile iptal edin; tamamlanmış bloğu tek seferde yapıştırın |
| CMD `More?` veya `^` hatası | PowerShell kodu yanlış kabukta/parçalı çalıştırılmış olabilir. Buradaki blokları `PS ...>` terminalinde kullanın; `^` devam karakteri eklemeyin |
| Türkçe karakterler bozuk | Dosya kodlaması, SQL literal türü ve terminal kodlamasını ayrı kontrol edin; aşağıdaki örneği kullanın |
| Kırmızı editör çizgisi | Messages sonucuyla ayırın; bağlantı/veritabanı bağlamı ve IntelliSense'i kontrol edin |
| `KURULUM ATLANDI` | Var olan veritabanı korunmuştur; kurulum/yükseltme yapılmamıştır |
| Git pull yerel değişiklik nedeniyle durdu | Değişiklikleri inceleyin ve koruyun. `reset --hard` veya toplu dosya silme kullanmayın |
| `.vs` / `.vsidx` ZIP sırasında kilitli | IDE çalışma önbelleğidir. Kaynakları ayrı paketleyin; çalışan uygulama dosyalarını zorla silmeyin |
| BAK kopyalarken access denied | SQL Server hizmet hesabının ve oturum kullanıcısının dosya izinleri farklıdır; gerekli yetkiyi yöneticiden isteyin |

### Türkçe karakter kontrolü

SQL kaynakları UTF-8 olarak tutulur ve Unicode metinler `N'...'` biçiminde yazılır. Terminalde görülen bozuk karakter, veritabanında mutlaka bozuk veri olduğu anlamına gelmez.

```powershell
[Console]::OutputEncoding = [System.Text.UTF8Encoding]::new($false)
sqlcmd -S localhost -E -C -I -b -r 1 -f 65001 -Q "SELECT N'Türkçe: ğüşiöç İĞÜŞÖÇ' AS UnicodeKontrol; SELECT TOP (5) AdSoyad FROM EndustriyelBakimDB.dbo.Teknisyenler;"
if ($LASTEXITCODE -ne 0) { throw 'Karakter kontrolu sorgusu basarisiz.' }
```

Aynı veriyi SSMS/VS Code sonuçlarında karşılaştırın. Yalnız terminal bozuksa çıktı kodlamasını düzeltin; veritabanını yeniden kurmayın. Veri gerçekten bozuksa etkilenen alanları ve kaynak dosya kodlamasını belirleyin; toplu tahmini karakter değiştirme işlemi uygulamayın.

SQL dosyası VS Code'da yanlış kodlamayla açıldıysa doğru kodlamayla yeniden açın; bozuk görünümü doğrudan kaydedip asıl metnin üzerine yazmayın.

## 13. Yetkilendirme ve sınırlar

Dört SQL veritabanı rolü bulunur: `rol_yonetici`, `rol_bakim_yoneticisi`, `rol_teknisyen` ve `rol_denetci`. Bunların GRANT/DENY tanımları yetkilendirme SQL dosyasındadır.

`dbo.Kullanicilar` ve `dbo.KullaniciRolleri` uygulama verisidir. Bu tablolara satır eklemek gerçek SQL Server LOGIN/USER veya `ALTER ROLE ... ADD MEMBER` işlemi yapmaz. Hesapların gerçek SQL rollerine üyeliği ayrıca yönetilmelidir.

Mevcut teknisyen rolü bazı yordamları çalıştırabilir; yalnız kendi görevlendirmesine erişim sağlayan satır bazlı yetkilendirme uygulanmış değildir. Yordam parametrelerine verilen kullanıcı numarası, tek başına güvenli oturum kimliği doğrulaması sayılmaz.

Denetim koruması UPDATE/DELETE tetikleyicisi ve SQL izinlerinden oluşur. Sistem yöneticisinin tanım/izin değiştirme yetkisine karşı kriptografik veya dış sistemli değişmez kayıt garantisi değildir. Denetim tetikleyicileri bütün tabloları değil bakım emirleri ve stok hareketlerini kapsar.

Kod öğretim ve gösterim amacı taşır; üretim kullanımı için ek güvenlik, eşzamanlılık, iş kuralı ve kurtarma incelemesi gerekir.

## 14. Yedekler, PDF'ler ve sürümler

Çalıştırma yolu SQL kaynaklarıdır; BAK dosyası zorunlu değildir. Kaynak depo `.bak`, IDE önbellekleri, geçici SQLQuery dosyaları ve yerel ZIP'leri izlemeye almaz. Bu dosyalar yerel diskte silinmez; sadece Git tarafından dışlanır.

Bir yedeğin var olması doğrulanmış geri yükleme anlamına gelmez. `RESTORE VERIFYONLY` dahi uygulama testleriyle gerçek geri yüklemenin yerine geçmez. BAK erişiminde izin hatası varsa zorla kopyalama/izin aşma yapılmamalıdır.

İlgili dosyalar:

- [EER diyagramı (PDF)](702.01_Analiz_ve_Tasarim_Calismalari/02_EER_Diyagrami/240309910_Gun_EER_Drawio.pdf)
- [Proje önerisi (PDF)](703.01_Proje_Yonetimi/03_Teslim/01_Proje_Onerisi/240309910_Gün.pdf)
- [Sürüm notları](RELEASE_NOTES.md)
- [GitHub Releases](https://github.com/msgxr/LBLM303-Endustriyel-Bakim-Sistemi/releases)

`v1.0.0` etiketi ve onun release dosyaları ilk yayımlanan sürümü temsil eder. `main` üzerindeki sonraki düzeltmeler eski release ZIP'ini otomatik güncellemez. Güncel kod için `main` kullanın; eski etiketi zorla taşıyarak tarihçeyi değiştirmeyin.

PDF'lerin GitHub'a eklenmesi akademik teslim koşullarını otomatik sağlamaz. Verilen ders yönergesindeki LaTeX şablonu, en fazla 5 sayfa, ayrı EER dosyası ve `ogrenciNO_soyisim.zip` adlandırma şartları teslim öncesi ayrıca kontrol edilmelidir. Öneri raporuna kod eklenmemesi şartıyla, kaynak depoda SQL bulunması farklı konulardır.

Klasörlerde kullanılan `702/703` kodları tek başına Resmî Gazete, devlet yazılım standardı veya resmî uygunluk belgesi anlamına gelmez.

## 15. Kaynak kodu değiştirme ve GitHub'a gönderme

Public depo herkesin okuyabilmesini sağlar; yazma yetkisi vermez. Depo sahibi veya yetkili katkıcı değişiklikleri gönderebilir.

Önce ilgili SQL dosyasını değiştirin ve test edin. Bir modül değişirse birleşik kurulumun iki mevcut kopyası da aynı kaynakları içerecek şekilde güncellenmelidir. Bu kopyalarda schema/test kodu birbirinden farklı bırakılmamalıdır.

Commit öncesi kontrol:

```powershell
git status --short
git diff --check
if ($LASTEXITCODE -ne 0) { throw 'Diff kontrolu hata verdi; once duzeltin.' }
git diff --stat
```

Yalnız incelenen dosyaları seçin; tüm klasörde körlemesine `git add .` kullanmak zorunda değilsiniz. Örneğin sadece README düzeltmesi için:

```powershell
& {
    git add -- README.md
    if ($LASTEXITCODE -ne 0) { throw 'Dosya stage edilemedi.' }
    git diff --cached --check
    if ($LASTEXITCODE -ne 0) { throw 'Stage kontrolu hata verdi.' }
    git diff --cached --stat
    git commit -m "docs: kurulum ve dogrulama kilavuzunu guncelle"
    if ($LASTEXITCODE -ne 0) { throw 'Commit olusturulamadi.' }
    git push origin main
    if ($LASTEXITCODE -ne 0) { throw 'Push tamamlanmadi; kimlik dogrulama ve yetkiyi kontrol edin.' }
}
```

SQL değişikliklerini commit mesajıyla test edilmiş gibi göstermeyin; çalıştırma sonuçları gerçekten görülmelidir. Parola, token, kişisel/veri tabanı yedeği veya ilgisiz çalışma dosyalarını göndermeyin.

## 16. Resmî araç belgeleri ve lisans

- [SSMS kurulumu](https://learn.microsoft.com/en-us/ssms/download-sql-server-management-studio-ssms/)
- [VS Code MSSQL bağlantıları](https://learn.microsoft.com/en-us/sql/tools/visual-studio-code-extensions/mssql/mssql-database-connections)
- [sqlcmd seçenekleri](https://learn.microsoft.com/en-us/sql/tools/sqlcmd/sqlcmd-utility)
- [SET NOEXEC](https://learn.microsoft.com/en-us/sql/t-sql/statements/set-noexec-transact-sql)
- [DBCC CHECKCONSTRAINTS](https://learn.microsoft.com/en-us/sql/t-sql/database-console-commands/dbcc-checkconstraints-transact-sql)

Depo public olmakla birlikte [LICENSE](LICENSE) dosyası tüm hakların saklı olduğunu belirtir; açık kaynak lisansı verilmiş değildir. Akademik çalışmanın başka biri adına kopyalanıp teslim edilmesi uygun değildir.

