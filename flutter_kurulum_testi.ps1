# Flutter Kurulum Test Script
Write-Host "==================================" -ForegroundColor Cyan
Write-Host "   FLUTTER KURULUM KONTROLÜ" -ForegroundColor Cyan
Write-Host "==================================" -ForegroundColor Cyan
Write-Host ""

# 1. Flutter dosyası var mı?
if (Test-Path "C:\src\flutter\bin\flutter.bat") {
    Write-Host "✓ Flutter dosyası bulundu: C:\src\flutter\bin\flutter.bat" -ForegroundColor Green
} else {
    Write-Host "✗ Flutter dosyası bulunamadı!" -ForegroundColor Red
    Write-Host "  Lütfen ZIP dosyasını C:\src\ konumuna çıkarın" -ForegroundColor Yellow
    exit
}

# 2. PATH'de mi?
$flutterCmd = Get-Command flutter -ErrorAction SilentlyContinue
if ($flutterCmd) {
    Write-Host "✓ Flutter PATH'de bulundu" -ForegroundColor Green
    Write-Host ""
    
    # Flutter versiyonu
    Write-Host "Flutter Versiyonu:" -ForegroundColor Cyan
    & "C:\src\flutter\bin\flutter.bat" --version
    
    Write-Host ""
    Write-Host "Flutter Doctor:" -ForegroundColor Cyan
    & "C:\src\flutter\bin\flutter.bat" doctor -v
    
} else {
    Write-Host "⚠ Flutter PATH'de değil!" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "PATH'e eklemek için:" -ForegroundColor Cyan
    Write-Host "1. Yönetici PowerShell açın" -ForegroundColor White
    Write-Host "2. Şu komutu çalıştırın:" -ForegroundColor White
    Write-Host ""
    Write-Host '   [Environment]::SetEnvironmentVariable("Path", [Environment]::GetEnvironmentVariable("Path", "User") + ";C:\src\flutter\bin", "User")' -ForegroundColor Green
    Write-Host ""
    Write-Host "3. Bu terminali kapatıp yeniden açın" -ForegroundColor White
}

Write-Host ""
Write-Host "==================================" -ForegroundColor Cyan
