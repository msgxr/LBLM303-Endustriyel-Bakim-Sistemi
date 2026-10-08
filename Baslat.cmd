@echo off
setlocal EnableExtensions DisableDelayedExpansion
chcp 65001 >nul
title LBLM303 Endustriyel Bakim Sistemi
set "LBLM_SQL_SERVER=localhost"
if not "%~1"=="" set "LBLM_SQL_SERVER=%~1"
set "LBLM_ROOT=%~dp0"
cd /d "%LBLM_ROOT%"
if errorlevel 1 goto Hata
where sqlcmd.exe >nul 2>&1
if errorlevel 1 goto SqlcmdEksik
call :Ozet
if errorlevel 1 goto Hata

:Menu
echo.
echo LBLM303 - SUNUM MENUSU
echo 1 - Ekipman ozeti
echo 2 - Yapi ve kayit sayimi
echo 3 - Iliski ve kisit testleri
echo 4 - Bakim is akisi testi
echo 5 - Raporlar
echo 6 - Performans karsilastirmasi
echo 7 - Tum test ve raporlari sirayla calistir
echo 8 - EER diyagramini ac
echo 0 - Cikis
choice /c 123456780 /n /m "Secim: "
if errorlevel 255 goto Hata
if errorlevel 9 goto Bitir
if errorlevel 8 goto EER
if errorlevel 7 goto Sunum
if errorlevel 6 goto Performans
if errorlevel 5 goto Raporlar
if errorlevel 4 goto IsAkisi
if errorlevel 3 goto Kisitlar
if errorlevel 2 goto Kayitlar
if errorlevel 1 goto OzetMenu
goto Bitir

:OzetMenu
call :Ozet
if errorlevel 1 goto Hata
goto Sonuc

:Kayitlar
call :Dosya "702.03_Test_Calismalari\01_Dogrulama\01_Ekipman_Kayitlarini_Dogrulama.sql"
if errorlevel 1 goto Hata
goto Sonuc

:Kisitlar
call :Dosya "702.03_Test_Calismalari\01_Dogrulama\02_Iliski_ve_Kisit_Testleri.sql"
if errorlevel 1 goto Hata
goto Sonuc

:IsAkisi
call :Dosya "702.03_Test_Calismalari\01_Dogrulama\03_Is_Akisi_Testleri.sql"
if errorlevel 1 goto Hata
goto Sonuc

:Raporlar
call :Dosya "702.02_Kodlama_Calismalari\10_Rapor_Sorgulari\01_MTBF_MTTR_Raporlari.sql"
if errorlevel 1 goto Hata
call :Dosya "702.02_Kodlama_Calismalari\10_Rapor_Sorgulari\02_Maliyet_ve_Durus_Raporlari.sql"
if errorlevel 1 goto Hata
goto Sonuc

:Performans
call :Dosya "702.03_Test_Calismalari\02_Performans\01_Indeks_Oncesi_Olcum.sql"
if errorlevel 1 goto Hata
call :Dosya "702.03_Test_Calismalari\02_Performans\02_Indeks_Sonrasi_Olcum.sql"
if errorlevel 1 goto Hata
goto Sonuc

:Sunum
for %%F in (
    "702.03_Test_Calismalari\01_Dogrulama\01_Ekipman_Kayitlarini_Dogrulama.sql"
    "702.03_Test_Calismalari\01_Dogrulama\02_Iliski_ve_Kisit_Testleri.sql"
    "702.03_Test_Calismalari\01_Dogrulama\03_Is_Akisi_Testleri.sql"
    "702.02_Kodlama_Calismalari\10_Rapor_Sorgulari\01_MTBF_MTTR_Raporlari.sql"
    "702.02_Kodlama_Calismalari\10_Rapor_Sorgulari\02_Maliyet_ve_Durus_Raporlari.sql"
    "702.03_Test_Calismalari\02_Performans\01_Indeks_Oncesi_Olcum.sql"
    "702.03_Test_Calismalari\02_Performans\02_Indeks_Sonrasi_Olcum.sql"
) do (
    call :Dosya "%%~F"
    if errorlevel 1 goto Hata
    echo.
    echo Asama tamamlandi. Devam etmek icin bir tusa basin.
    pause >nul
)
echo.
echo TUM TEST VE RAPOR SORGULARI TAMAMLANDI.
goto Menu

:EER
if not exist "%LBLM_ROOT%702.01_Analiz_ve_Tasarim_Calismalari\02_EER_Diyagrami\240309910_Gun_EER_Drawio.pdf" goto Hata
start "" "%LBLM_ROOT%702.01_Analiz_ve_Tasarim_Calismalari\02_EER_Diyagrami\240309910_Gun_EER_Drawio.pdf"
if errorlevel 1 goto Hata
goto Menu

:Sonuc
if errorlevel 1 goto Hata
echo.
echo ISLEM TAMAMLANDI. Menuye donmek icin bir tusa basin.
pause >nul
goto Menu

:Ozet
echo.
echo EKIPMAN OZETI - "%LBLM_SQL_SERVER%"
sqlcmd -S "%LBLM_SQL_SERVER%" -E -C -I -b -l 30 -f 65001 -d EndustriyelBakimDB -Q "SET NOCOUNT ON; SELECT TOP (20) EkipmanKodu, CAST(EkipmanAdi AS NVARCHAR(24)) AS EkipmanAdi, SensorSayisi, AlarmSayisi, ArizaSayisi, BakimEmriSayisi FROM dbo.vw_EkipmanOzeti ORDER BY EkipmanNo;"
exit /b %errorlevel%

:Dosya
if not exist "%LBLM_ROOT%%~1" (
    echo DOSYA BULUNAMADI: "%~1"
    exit /b 1
)
echo.
echo CALISTIRILIYOR: "%~1"
sqlcmd -S "%LBLM_SQL_SERVER%" -E -C -I -b -l 30 -f 65001 -d EndustriyelBakimDB -i "%LBLM_ROOT%%~1"
exit /b %errorlevel%

:SqlcmdEksik
echo SQLCMD BULUNAMADI. sqlcmd.exe kurulu ve PATH icinde olmalidir.
goto Hata

:Hata
echo.
echo ISLEM DURDU. Yukaridaki hata mesajini kontrol edin.
pause
endlocal
exit /b 1

:Bitir
endlocal
exit /b 0
