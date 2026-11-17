# Web Site Texnologiya Yoxlama Skripti
$url = "https://new.idrak.edu.az"

Write-Host "`n=== WEB SITE TEXNOLOGIYA ANALIZI ===" -ForegroundColor Cyan
Write-Host "URL: $url`n" -ForegroundColor Yellow

# 1. HTTP Headers
Write-Host "1. SERVER HEADERS:" -ForegroundColor Green
try {
    $response = Invoke-WebRequest -Uri $url -Method Head -UseBasicParsing -ErrorAction SilentlyContinue
    $response.Headers | Format-Table -AutoSize
} catch {
    Write-Host "Headers alınmadı" -ForegroundColor Red
}

# 2. Cookies yoxla (Laravel session)
Write-Host "`n2. COOKIES:" -ForegroundColor Green
try {
    $webReq = Invoke-WebRequest -Uri "$url/panel" -UseBasicParsing -SessionVariable session
    $session.Cookies.GetCookies($url) | Format-Table -AutoSize
} catch {
    Write-Host "Cookie yoxlanılmadı" -ForegroundColor Red
}

# 3. Page source Laravel izləri
Write-Host "`n3. LARAVEL İZLƏRİ:" -ForegroundColor Green
try {
    $content = (Invoke-WebRequest -Uri "$url/panel" -UseBasicParsing).Content
    
    if ($content -match "laravel") {
        Write-Host "✓ Laravel tapıldı!" -ForegroundColor Green
    }
    if ($content -match "XSRF-TOKEN|_token") {
        Write-Host "✓ CSRF Token (Laravel xüsusiyyəti)" -ForegroundColor Green
    }
    if ($content -match "app\.js|app\.css") {
        Write-Host "✓ Laravel Mix asset compilation" -ForegroundColor Green
    }
} catch {
    Write-Host "Content yoxlanılmadı" -ForegroundColor Red
}

# 4. DNS və IP
Write-Host "`n4. SERVER LOCATION:" -ForegroundColor Green
try {
    $ip = [System.Net.Dns]::GetHostAddresses("new.idrak.edu.az") | Select-Object -First 1
    Write-Host "IP Address: $ip" -ForegroundColor Yellow
    
    # Whois-like info (ping ilə)
    $ping = Test-Connection -ComputerName "new.idrak.edu.az" -Count 2 -ErrorAction SilentlyContinue
    if ($ping) {
        Write-Host "Server cavab verir: $($ping[0].ResponseTime)ms" -ForegroundColor Yellow
    }
} catch {
    Write-Host "DNS resolve edilmədi" -ForegroundColor Red
}

Write-Host "`n=== ANALIZ TAMAMLANDI ===" -ForegroundColor Cyan
