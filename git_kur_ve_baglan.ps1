# Git Kurulum ve GitHub Bağlantısı
Write-Host "================================" -ForegroundColor Cyan
Write-Host "   GIT KURULUM & GITHUB BAĞLANTI" -ForegroundColor Cyan
Write-Host "================================" -ForegroundColor Cyan
Write-Host ""

# Git kontrol
$gitInstalled = Get-Command git -ErrorAction SilentlyContinue

if ($gitInstalled) {
    Write-Host "✓ Git zaten kurulu: $($gitInstalled.Version)" -ForegroundColor Green
    git --version
} else {
    Write-Host "⚠ Git kurulu değil!" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "Git'i indirmek için:" -ForegroundColor Cyan
    Write-Host "   https://git-scm.com/download/win" -ForegroundColor White
    Write-Host ""
    Write-Host "İndirdikten sonra kurulum sırasında:" -ForegroundColor Yellow
    Write-Host "   ✓ 'Git from the command line and also from 3rd-party software' seçin" -ForegroundColor Green
    Write-Host "   ✓ 'Use Visual Studio Code as Git's default editor' (veya varsayılan)" -ForegroundColor Green
    Write-Host "   ✓ Diğer ayarları varsayılan bırakın" -ForegroundColor Green
    Write-Host ""
    Write-Host "Kurulum bitince bu terminali kapatıp yeniden açın!" -ForegroundColor Yellow
    Write-Host ""
    exit
}

Write-Host ""
Write-Host "1️⃣  Git config ayarları..." -ForegroundColor Yellow
git config --global user.name "o19940023"
git config --global user.email "o19940023@example.com"
Write-Host "   ✓ Git kullanıcı adı: o19940023" -ForegroundColor Green
Write-Host ""

Write-Host "2️⃣  Mevcut Git durumu..." -ForegroundColor Yellow
cd C:\Users\habiba.guliyeva\Desktop\IdrakLiseyi

if (Test-Path ".git") {
    Write-Host "   ✓ Git repository zaten mevcut" -ForegroundColor Green
    git status
} else {
    Write-Host "   ⚠ Git repository yok, oluşturuluyor..." -ForegroundColor Yellow
    git init
    Write-Host "   ✓ Git repository oluşturuldu" -ForegroundColor Green
}
Write-Host ""

Write-Host "3️⃣  .gitignore kontrol..." -ForegroundColor Yellow
if (-not (Test-Path ".gitignore")) {
    Write-Host "   .gitignore oluşturuluyor..." -ForegroundColor Cyan
    @"
# Flutter
.dart_tool/
.flutter-plugins
.flutter-plugins-dependencies
.packages
.pub-cache/
.pub/
build/
*.lock

# Android
android/.gradle/
android/.idea/
android/local.properties
android/app/debug/
android/app/profile/
android/app/release/
*.jks
*.keystore

# iOS
ios/Pods/
ios/.symlinks/
ios/Flutter/Flutter.framework
ios/Flutter/Flutter.podspec
ios/.generated/
*.mode1v3
*.pbxuser
*.perspectivev3

# IDE
.idea/
.vscode/
*.swp
*.swo
*~

# OS
.DS_Store
Thumbs.db

# Personal
*.apk
*.aab
*.ipa
"@ | Out-File -FilePath ".gitignore" -Encoding UTF8
    Write-Host "   ✓ .gitignore oluşturuldu" -ForegroundColor Green
}
Write-Host ""

Write-Host "4️⃣  İlk commit..." -ForegroundColor Yellow
git add .gitignore README.md pubspec.yaml lib/ android/app/build.gradle.kts
git commit -m "Initial commit: İdrak Liseyi Flutter App" -ErrorAction SilentlyContinue
Write-Host "   ✓ Dosyalar commit edildi" -ForegroundColor Green
Write-Host ""

Write-Host "================================" -ForegroundColor Cyan
Write-Host "✓ GIT AYARLARI TAMAMLANDI!" -ForegroundColor Green
Write-Host ""
Write-Host "GitHub'a yüklemek için:" -ForegroundColor Yellow
Write-Host ""
Write-Host "1. GitHub'da yeni repository oluşturun:" -ForegroundColor White
Write-Host "   https://github.com/new" -ForegroundColor Cyan
Write-Host ""
Write-Host "2. Repository adı: IdrakLiseyi" -ForegroundColor White
Write-Host "3. Private seçin" -ForegroundColor White
Write-Host "4. 'Create repository' tıklayın" -ForegroundColor White
Write-Host ""
Write-Host "5. Sonra şu komutları çalıştırın:" -ForegroundColor White
Write-Host ""
Write-Host "   git remote add origin https://github.com/o19940023/IdrakLiseyi.git" -ForegroundColor Green
Write-Host "   git branch -M main" -ForegroundColor Green
Write-Host "   git push -u origin main" -ForegroundColor Green
Write-Host ""
Write-Host "GitHub şifreniz istenecek (veya personal access token)" -ForegroundColor Yellow
Write-Host "================================" -ForegroundColor Cyan
