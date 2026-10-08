# LBLM303 Endüstriyel Bakım Yönetim Sistemi

Ekipman, sensör, alarm, arıza, bakım ve stok yönetimi için Microsoft SQL Server projesi.

**Kaynak kapsamı:** 17 tablo, 6 görünüm, 6 saklı yordam, 7 tetikleyici. Örnek veri hedefi: 100 ekipman, 300 sensör ve 90.000 ölçüm. Toplam kayıt sayısını test hesaplar.

## 1. Nerede çalıştıracağım?

VS Code'da proje klasörünü açın. **Terminal > New Terminal > PowerShell** seçin.

Gerekli araçlar: çalışan SQL Server, Git ve `sqlcmd`. Komutlar yerel `localhost` sunucusunda Windows Authentication kullanır. Sunucunuz Express ise `localhost` yerine kendi örnek adınızı yazın.

## 2. Kurulu sistemi güncelle ve test et

Aşağıdaki bloğu terminale **tek seferde** yapıştırın. Görünüm/yordam/tetikleyici tanımları ve izinler güncellenir; eksik performans indeksleri oluşturulur. Ardından üç test çalışır. Veritabanı silinmez; ilk hatada işlem durur.

```powershell
& {
    $ErrorActionPreference = 'Stop'
    Set-Location "$env:USERPROFILE\LBLM303_Endustriyel_Bakim_Projesi_SDP"
    git pull --ff-only origin main
    if ($LASTEXITCODE -ne 0) { throw 'Guncelleme durdu; yukaridaki Git hatasini paylas.' }
    $sqlcmd = (Get-Command sqlcmd.exe -ErrorAction Stop).Source
    [Console]::OutputEncoding = [Text.UTF8Encoding]::new($false)
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
        if (-not (Test-Path -LiteralPath $dosya)) { throw "Dosya eksik: $dosya" }
    }
    foreach ($dosya in $dosyalar) {
        Write-Host "CALISIYOR: $dosya" -ForegroundColor Cyan
        & $sqlcmd -S localhost -E -C -I -b -r 1 -f 65001 -d EndustriyelBakimDB -i $dosya
        if ($LASTEXITCODE -ne 0) { throw "DURDU: $dosya. Yukaridaki SQL hatasini paylas." }
    }
    Write-Host 'GUNCELLEME VE UC TEST TAMAMLANDI.' -ForegroundColor Green
}
```

Başarı için test mesajlarında **BAŞARILI** ve sonunda yeşil tamamlanma mesajı görülmelidir. Gerçek çalışma onayı bu çıktıya bağlıdır.

| Test | Ne gösterir? |
|---|---|
| 01 | Nesneler, ilişkiler, indeksler ve kesin kayıt toplamı |
| 02 | Altı hatalı işlemin doğru kurallarla engellenmesi |
| 03 | Alarmdan bakım tamamlamaya iş akışı ve ROLLBACK |

Test 2 ve 3 satırları geri alır; kimlik numaralarında boşluk oluşabilir. Testleri yönetici/veritabanı sahibi bağlantısıyla, başka işlem yapılmayan bir ortamda çalıştırın.

## 3. Veriyi ekranda göster

SSMS veya VS Code **SQL editöründe** aşağıdaki sorguyu çalıştırın:

```sql
USE EndustriyelBakimDB;
GO
SELECT TOP (20) * FROM dbo.vw_EkipmanOzeti ORDER BY EkipmanNo;
SELECT TOP (20) * FROM dbo.vw_GuncelAlarmlar ORDER BY AlarmNo DESC;
SELECT TOP (20) * FROM dbo.vw_BakimMaliyetleri ORDER BY BakimEmriNo DESC;
```

PowerShell komutları terminalde; SQL sorguları SQL editöründe çalıştırılır.

## 4. İlk kez kuracak kişi için

[Depoyu ZIP olarak indirin](https://github.com/msgxr/LBLM303-Endustriyel-Bakim-Sistemi/archive/refs/heads/main.zip), çıkarın ve SSMS'de şu dosyayı açıp **F5** ile tamamını çalıştırın:

`702.02_Kodlama_Calismalari/01_Veritabani/01_Veritabani_Olusturma.sql`

Mevcut veritabanı varsa kurulum atlanır. İki kurulum dosyasından yalnızca biri kullanılır. İlk kurulumdan sonra üç doğrulama SQL dosyasını sırayla açıp F5 ile çalıştırın. ZIP kopyasında Git güncelleme komutu kullanılmaz.

## 5. Hocaya gösterme sırası

1. EER diyagramı.
2. Test 01: kayıt sayıları ve bütünlük.
3. Test 02: hatalı işlemler.
4. Test 03: iş akışı ve geri alma.
5. Görünümler, raporlar ve performans karşılaştırması.

Raporlar `702.02_Kodlama_Calismalari/10_Rapor_Sorgulari`; performans dosyaları `702.03_Test_Calismalari/02_Performans` içindedir. SSMS'de dosyaları sırayla açıp F5 ile çalıştırın. Performans deneyi zorunlu tarama ile optimizer seçiminin karşılaştırmasıdır; indeks silmez.

**Hata olursa:** sonraki adıma geçmeyin. Hata mesajını ve dosya adını paylaşın. Veritabanını yeniden silip kurmayın.

[EER PDF](702.01_Analiz_ve_Tasarim_Calismalari/02_EER_Diyagrami/240309910_Gun_EER_Drawio.pdf) · [Proje önerisi PDF](703.01_Proje_Yonetimi/03_Teslim/01_Proje_Onerisi/240309910_Gün.pdf) · [Sürüm notları](RELEASE_NOTES.md)

Public depo okunabilir; kullanım koşulları [LICENSE](LICENSE) dosyasındadır. Güncel kod `main` dalında; `v1.0.0` eski sürümdür.
