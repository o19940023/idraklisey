# Flutter Test Script
Write-Host "=== FLUTTER KONTROL ===" -ForegroundColor Cyan

# Flutter PATH'de mi kontrol et
$flutterCmd = Get-Command flutter -ErrorAction SilentlyContinue
if ($flutterCmd) {
    Write-Host "✓ Flutter PATH'de bulundu: $($flutterCmd.Source)" -ForegroundColor Green
    flutter --version
    Write-Host ""
    flutter doctor -v
} else {
    Write-Host "✗ Flutter PATH'de bulunamadı!" -ForegroundColor Red
    Write-Host ""
    Write-Host "Lütfen Flutter SDK'yı PATH'e ekleyin:" -ForegroundColor Yellow
    Write-Host "1. Flutter SDK'yı indirin: https://docs.flutter.dev/get-started/install/windows"
    Write-Host "2. ZIP'i C:\src\ klasörüne çıkarın"
    Write-Host "3. C:\src\flutter\bin klasörünü PATH'e ekleyin"
    Write-Host "4. Bu terminali kapatıp yeniden açın"
}
