# Android SDK 404 Hatası Düzeltme
Write-Host "================================" -ForegroundColor Cyan
Write-Host "   ANDROID SDK 404 DÜZELTME" -ForegroundColor Cyan
Write-Host "================================" -ForegroundColor Cyan
Write-Host ""

$env:ANDROID_HOME = "C:\Users\habiba.guliyeva\AppData\Local\Android\sdk"

Write-Host "1️⃣  Android Studio ve emulator kapatılıyor..." -ForegroundColor Yellow
Get-Process | Where-Object {
    $_.ProcessName -like "*studio*" -or 
    $_.ProcessName -like "*qemu*" -or 
    $_.ProcessName -like "*emulator*"
} | Stop-Process -Force -ErrorAction SilentlyContinue
Start-Sleep -Seconds 2
Write-Host "   ✓ İşlemler kapatıldı" -ForegroundColor Green
Write-Host ""

Write-Host "2️⃣  SDK Manager cache temizleniyor..." -ForegroundColor Yellow
$cacheLocations = @(
    "$env:ANDROID_HOME\.downloadIntermediates",
    "$env:ANDROID_HOME\.temp",
    "$env:USERPROFILE\.android\cache",
    "$env:USERPROFILE\.android\avd\*.avd\cache"
)

foreach ($cache in $cacheLocations) {
    if (Test-Path $cache) {
        Remove-Item -Path $cache -Recurse -Force -ErrorAction SilentlyContinue
        Write-Host "   ✓ Temizlendi: $cache" -ForegroundColor Green
    }
}
Write-Host ""

Write-Host "3️⃣  Mevcut system images kontrol ediliyor..." -ForegroundColor Yellow
$systemImages = Get-ChildItem "$env:ANDROID_HOME\system-images" -Directory -ErrorAction SilentlyContinue
if ($systemImages) {
    Write-Host "   Mevcut system images:" -ForegroundColor Cyan
    foreach ($img in $systemImages) {
        Write-Host "   📦 $($img.Name)" -ForegroundColor White
        $subDirs = Get-ChildItem $img.FullName -Directory
        foreach ($sub in $subDirs) {
            $arch = Get-ChildItem $sub.FullName -Directory
            foreach ($a in $arch) {
                Write-Host "      └─ $($sub.Name) / $($a.Name)" -ForegroundColor Gray
            }
        }
    }
} else {
    Write-Host "   ⚠ Hiç system image yok!" -ForegroundColor Red
}
Write-Host ""

Write-Host "================================" -ForegroundColor Cyan
Write-Host "✓ Temizlik tamamlandı!" -ForegroundColor Green
Write-Host ""
Write-Host "ŞİMDİ YAPMANIZ GEREKENLER:" -ForegroundColor Yellow
Write-Host ""
Write-Host "1. Android Studio'yu KAPAT (tamamen)" -ForegroundColor White
Write-Host "2. Android Studio'yu YENİDEN AÇ" -ForegroundColor White
Write-Host "3. Tools → SDK Manager" -ForegroundColor White
Write-Host "4. SDK Tools sekmesi → Android SDK Command-line Tools işaretle" -ForegroundColor White
Write-Host "5. Apply → OK" -ForegroundColor White
Write-Host ""
Write-Host "VEYA daha kolay:" -ForegroundColor Cyan
Write-Host "Zaten kurulu bir emulator kullan!" -ForegroundColor White
Write-Host ""
Write-Host "Mevcut emulator'ları görmek için:" -ForegroundColor Cyan
Write-Host '   & "$env:ANDROID_HOME\emulator\emulator.exe" -list-avds' -ForegroundColor Green
Write-Host ""
Write-Host "================================" -ForegroundColor Cyan
