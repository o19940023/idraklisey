# Android Emulator Kurulum Script
Write-Host "================================" -ForegroundColor Cyan
Write-Host "   ANDROID EMULATOR KURULUMU" -ForegroundColor Cyan
Write-Host "================================" -ForegroundColor Cyan
Write-Host ""

$env:ANDROID_HOME = "C:\Users\habiba.guliyeva\AppData\Local\Android\sdk"
$sdkmanager = "$env:ANDROID_HOME\cmdline-tools\latest\bin\sdkmanager.bat"

# 1. Stable Android 34 (Android 14) system image kur - ÖNERILEN
Write-Host "1️⃣  Android 14 (API 34) System Image kuruluyor..." -ForegroundColor Yellow
Write-Host "   (Stable, Google Play Store dahil)" -ForegroundColor Cyan
& $sdkmanager "system-images;android-34;google_apis_playstore;x86_64"
Write-Host ""

# 2. Emulator tools güncelle
Write-Host "2️⃣  Emulator tools güncelleniyor..." -ForegroundColor Yellow
& $sdkmanager "emulator" "platform-tools"
Write-Host ""

# 3. Emulator cihazı oluştur
Write-Host "3️⃣  Emulator cihazı oluşturuluyor..." -ForegroundColor Yellow
$avdName = "Idrak_Liseyi_Pixel_7"

# Eski emulator varsa sil
& "$env:ANDROID_HOME\cmdline-tools\latest\bin\avdmanager.bat" delete avd -n $avdName 2>$null

# Yeni emulator oluştur - Pixel 7 (modern, orta boyut)
& "$env:ANDROID_HOME\cmdline-tools\latest\bin\avdmanager.bat" create avd `
    -n $avdName `
    -k "system-images;android-34;google_apis_playstore;x86_64" `
    -d "pixel_7" `
    --force

Write-Host ""
Write-Host "✓ Emulator başarıyla oluşturuldu: $avdName" -ForegroundColor Green
Write-Host ""

# 4. Mevcut emulator'ları listele
Write-Host "4️⃣  Mevcut emulator'lar:" -ForegroundColor Yellow
& "$env:ANDROID_HOME\emulator\emulator.exe" -list-avds

Write-Host ""
Write-Host "================================" -ForegroundColor Cyan
Write-Host "✓ Kurulum tamamlandı!" -ForegroundColor Green
Write-Host ""
Write-Host "Emulator'ı başlatmak için:" -ForegroundColor Cyan
Write-Host "   .\emulator_baslat.ps1" -ForegroundColor White
Write-Host "================================" -ForegroundColor Cyan
