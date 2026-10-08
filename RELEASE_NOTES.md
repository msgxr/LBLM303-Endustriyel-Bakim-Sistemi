# Sürüm notları

## main — 2026-10-08 kaynak düzeltmeleri

Bu değişiklikler kaynak düzeyinde incelenmiştir. Hedef Windows SQL Server üzerinde üç doğrulama dosyasının çalıştırılması gerekir; bu notlar çalışma testi onayı değildir.

- Birleşik tam kurulum dosyası kaldırıldı. 01_Veritabani_Olusturma.sql yalnız veritabanı oluşturur; tablo/kısıt/veri/görünüm/yordam/tetikleyici kodları ayrı dosyalardadır.
- Otomatik DROP DATABASE ve SINGLE_USER yoktur. Mevcut veritabanı yeniden oluşturulmaz.
- Filtreli indekslerle ilişkili DDL/DML için gerekli SET seçenekleri açıkça tanımlandı.
- Yapısal testte beklenen nesneler/kısıtlar/indeksler, etkinlik durumu, gerçek kayıt sayımı ve mevcut veri ihlalleri kontrol edilir.
- Olumsuz senaryo testi altı durumu beklenen hata kodlarıyla kontrol eder; rastgele hatalar artık başarı sayılmaz.
- Uçtan uca iş akışı testine ara/son durum, stok, denetim ve ROLLBACK doğrulamaları eklendi.
- Tetikleyici tanım dosyasından örnek veri UPDATE bölümü çıkarıldı. Yeniden tanımlama veri satırlarını düzenlemez.
- Performans dosyaları aynı veriye dayalı tarih aralığı kullanır. Deneyin zorunlu tarama ile optimize edilmiş erişim olduğu açıklandı.
- README kısaltıldı; bir kez kurulum, kurulum sonrası sorgu/rapor kullanımı ve test sırası ayrı açıklandı.
- İlk iki tablo dosyasına EndustriyelBakimDB bağlamı eklendi.
- PDF'ler, mevcut v1.0.0 etiketi ve release varlıkları korundu.

## v1.0.0 — ilk yayımlanan kaynak

- 17 tablo, 6 görünüm, 6 saklı yordam ve 7 tetikleyicinin SQL kaynakları.
- Temel örnek veri hedefleri: 100 ekipman, 300 sensör, 90.000 ölçüm.
- Bütünlük, iş akışı ve performans sorgularının ilk sürümleri.
- EER diyagramı ve proje önerisi PDF'leri.

İlk sürümdeki bazı testler her hatayı başarı sayabiliyordu. Bu nedenle v1.0.0 için eski “bütün testler tamamlandı” ifadesi kapsamlı doğrulama kanıtı olarak kullanılmamalıdır. Güncel testler main dalındadır; eski release ZIP'i main değişiklikleriyle kendiliğinden güncellenmez.

