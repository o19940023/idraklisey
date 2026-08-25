# Android Studio Tamamen Temizleme ve Yeniden Kurulum
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "   ANDROID STUDIO TAMİZLİK & KURULUM" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# 1. Android Studio ve ilgili işlemleri kapat
Write-Host "1️⃣  Android Studio ve ilgili işlemler kapatılıyor..." -ForegroundColor Yellow
$processes = @("studio64", "studio", "java", "gradle", "qemu-system-x86_64", "emulator")
foreach ($proc in $processes) {
    Get-Process -Name $proc -ErrorAction SilentlyContinue | Stop-Process -Force -ErrorAction SilentlyContinue
}
Start-Sleep -Seconds 3
Write-Host "   ✓ Tüm işlemler kapatıldı" -ForegroundColor Green
Write-Host ""

# 2. Android Studio kaldır
Write-Host "2️⃣  Android Studio kaldırılıyor..." -ForegroundColor Yellow
$uninstallers = @(
    "$env:ProgramFiles\Android\Android Studio\uninstall.exe",
    "${env:ProgramFiles(x86)}\Android\Android Studio\uninstall.exe"
)

foreach ($uninstaller in $uninstallers) {
    if (Test-Path $uninstaller) {
        Write-Host "   Uninstaller bulundu: $uninstaller" -ForegroundColor Cyan
        Start-Process $uninstaller -ArgumentList "/S" -Wait -NoNewWindow -ErrorAction SilentlyContinue
        Write-Host "   ✓ Android Studio kaldırıldı" -ForegroundColor Green
        break
    }
}
Write-Host ""

# 3. Klasörleri temizle
Write-Host "3️⃣  Tüm Android Studio klasörleri temizleniyor..." -ForegroundColor Yellow
$foldersToDelete = @(
    "$env:ProgramFiles\Android",
    "${env:ProgramFiles(x86)}\Android",
    "$env:LOCALAPPDATA\Android",
    "$env:APPDATA\Google\AndroidStudio*",
    "$env:USERPROFILE\.android",
    "$env:USERPROFILE\.AndroidStudio*",
    "$env:USERPROFILE\.gradle",
    "$env:USERPROFILE\.m2"
)

foreach ($folder in $foldersToDelete) {
    $expandedPaths = Get-Item $folder -ErrorAction SilentlyContinue
    foreach ($path in $expandedPaths) {
        if (Test-Path $path) {
            Write-Host "   Siliniyor: $path" -ForegroundColor Gray
            Remove-Item -Path $path -Recurse -Force -ErrorAction SilentlyContinue
            Write-Host "   ✓ Silindi" -ForegroundColor Green
        }
    }
}
Write-Host ""

# 4. Registry temizliği (opsiyonel - dikkatli!)
Write-Host "4️⃣  Registry temizleniyor..." -ForegroundColor Yellow
$regKeys = @(
    "HKCU:\Software\Google\AndroidStudio*",
    "HKLM:\SOFTWARE\Android Studio"
)

foreach ($key in $regKeys) {
    Remove-Item -Path $key -Recurse -Force -ErrorAction SilentlyContinue
}
Write-Host "   ✓ Registry temizlendi" -ForegroundColor Green
Write-Host ""

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "✓ TEMİZLİK TAMAMLANDI!" -ForegroundColor Green
Write-Host ""
Write-Host "ŞİMDİ YAPMANIZ GEREKENLER:" -ForegroundColor Yellow
Write-Host ""
Write-Host "1. Bilgisayarı YENİDEN BAŞLAT (önemli!)" -ForegroundColor White
Write-Host "2. Android Studio'yu indir:" -ForegroundColor White
Write-Host "   https://developer.android.com/studio" -ForegroundColor Cyan
Write-Host "3. İndirilen .exe dosyasını çalıştır" -ForegroundColor White
Write-Host "4. Kurulum sırasında:" -ForegroundColor White
Write-Host "   ✓ Android SDK'yı kur" -ForegroundColor Green
Write-Host "   ✓ Android Virtual Device kur" -ForegroundColor Green
Write-Host "   ✓ Intel HAXM kur (varsa)" -ForegroundColor Green
Write-Host "5. İlk açılışta 'Standard' setup seç" -ForegroundColor White
Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
