# İdrak Liseyi - Emulator Başlatma Script
Write-Host "================================" -ForegroundColor Cyan
Write-Host "   İDRAK LİSEYİ BAŞLATILIYOR" -ForegroundColor Cyan
Write-Host "================================" -ForegroundColor Cyan
Write-Host ""

# Ortam değişkenleri
$env:Path += ";C:\src\flutter\bin"
$env:ANDROID_HOME = "C:\Users\habiba.guliyeva\AppData\Local\Android\sdk"

# 1. Flutter pub get
Write-Host "1️⃣  Flutter bağımlılıkları yükleniyor..." -ForegroundColor Yellow
& C:\src\flutter\bin\flutter.bat pub get
if ($LASTEXITCODE -eq 0) {
    Write-Host "✓ Bağımlılıklar yüklendi!" -ForegroundColor Green
} else {
    Write-Host "⚠ Pub get hatası, devam ediliyor..." -ForegroundColor Yellow
}
Write-Host ""

# 2. Emulator'ları listele
Write-Host "2️⃣  Mevcut emulator'lar:" -ForegroundColor Yellow
$avds = & "$env:ANDROID_HOME\emulator\emulator.exe" -list-avds 2>$null
if ($avds) {
    $avds | ForEach-Object { Write-Host "   📱 $_" -ForegroundColor Cyan }
    $emulatorName = $avds[0]
} else {
    Write-Host "   ❌ Emulator bulunamadı!" -ForegroundColor Red
    Write-Host ""
    Write-Host "Android Studio'da emulator oluşturun:" -ForegroundColor Yellow
    Write-Host "   Tools → Device Manager → Create Device" -ForegroundColor White
    exit
}
Write-Host ""

# 3. Emulator başlat
Write-Host "3️⃣  Emulator başlatılıyor: $emulatorName" -ForegroundColor Yellow
Start-Process "$env:ANDROID_HOME\emulator\emulator.exe" -ArgumentList "-avd", $emulatorName -WindowStyle Hidden
Write-Host "⏳ Emulator açılması bekleniyor (30 saniye)..." -ForegroundColor Yellow
Start-Sleep -Seconds 30
Write-Host ""

# 4. Flutter devices kontrol
Write-Host "4️⃣  Bağlı cihazlar:" -ForegroundColor Yellow
& C:\src\flutter\bin\flutter.bat devices
Write-Host ""

# 5. Uygulamayı başlat
Write-Host "5️⃣  İdrak Liseyi başlatılıyor..." -ForegroundColor Yellow
Write-Host ""
Write-Host "⏳ İlk çalıştırma uzun sürebilir (2-3 dakika)" -ForegroundColor Cyan
Write-Host ""
& C:\src\flutter\bin\flutter.bat run

Write-Host ""
Write-Host "================================" -ForegroundColor Cyan
