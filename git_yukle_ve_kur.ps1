# Git İndirme ve Kurulum Script
Write-Host "================================" -ForegroundColor Cyan
Write-Host "   GIT KURULUM" -ForegroundColor Cyan
Write-Host "================================" -ForegroundColor Cyan
Write-Host ""

# Git zaten kurulu mu?
$gitPath = "C:\Program Files\Git\bin\git.exe"
if (Test-Path $gitPath) {
    Write-Host "✓ Git zaten kurulu!" -ForegroundColor Green
    & $gitPath --version
    exit
}

# Git indirme URL'si
$gitUrl = "https://github.com/git-for-windows/git/releases/download/v2.47.1.windows.1/Git-2.47.1-64-bit.exe"
$installerPath = "$env:TEMP\Git-Installer.exe"

Write-Host "1️⃣  Git indiriliyor..." -ForegroundColor Yellow
Write-Host "   URL: $gitUrl" -ForegroundColor Cyan
Write-Host "   Bu işlem 2-3 dakika sürebilir..." -ForegroundColor Gray
Write-Host ""

try {
    # Download Git installer
    $ProgressPreference = 'SilentlyContinue'
    Invoke-WebRequest -Uri $gitUrl -OutFile $installerPath -UseBasicParsing
    Write-Host "   ✓ Git indirildi: $installerPath" -ForegroundColor Green
    Write-Host ""
} catch {
    Write-Host "   ✗ İndirme hatası: $_" -ForegroundColor Red
    Write-Host ""
    Write-Host "Manuel indirme için:" -ForegroundColor Yellow
    Write-Host "   https://git-scm.com/download/win" -ForegroundColor Cyan
    exit 1
}

Write-Host "2️⃣  Git kuruluyor..." -ForegroundColor Yellow
Write-Host "   Sessiz kurulum başlıyor..." -ForegroundColor Cyan
Write-Host ""

# Sessiz kurulum parametreleri
$arguments = @(
    "/VERYSILENT",
    "/NORESTART",
    "/NOCANCEL",
    "/SP-",
    "/CLOSEAPPLICATIONS",
    "/RESTARTAPPLICATIONS",
    "/COMPONENTS=`"icons,ext\reg\shellhere,assoc,assoc_sh`"",
    "/EditorOption=VIM",
    "/GitAndUnixToolsOnPath",
    "/NoAutoCrlf"
)

try {
    $process = Start-Process -FilePath $installerPath -ArgumentList $arguments -Wait -PassThru -NoNewWindow
    
    if ($process.ExitCode -eq 0) {
        Write-Host "   ✓ Git başarıyla kuruldu!" -ForegroundColor Green
        Write-Host ""
        
        # PATH'e ekle (bu session için)
        $env:Path += ";C:\Program Files\Git\bin"
        
        # Git version kontrol
        Start-Sleep -Seconds 2
        if (Test-Path $gitPath) {
            & $gitPath --version
        }
    } else {
        Write-Host "   ✗ Kurulum hatası! Exit code: $($process.ExitCode)" -ForegroundColor Red
    }
} catch {
    Write-Host "   ✗ Kurulum hatası: $_" -ForegroundColor Red
}

# Temp dosyayı sil
Remove-Item $installerPath -Force -ErrorAction SilentlyContinue

Write-Host ""
Write-Host "================================" -ForegroundColor Cyan
Write-Host "⚠ BU TERMİNALİ KAPATIP YENİ BİR TANE AÇIN!" -ForegroundColor Yellow
Write-Host ""
Write-Host "Yeni terminalde test edin:" -ForegroundColor Cyan
Write-Host "   git --version" -ForegroundColor White
Write-Host ""
Write-Host "Sonra Git'i yapılandırın:" -ForegroundColor Cyan
Write-Host "   .\git_yapilandir.ps1" -ForegroundColor White
Write-Host "================================" -ForegroundColor Cyan
