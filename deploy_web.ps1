# == Deploy Web Script ==
# Build Flutter web + Them cache-busting version + Nen thanh file ZIP

Write-Host "1. Dang build Flutter web..." -ForegroundColor Cyan
flutter build web --release --base-href / --no-tree-shake-icons
if ($LASTEXITCODE -ne 0) {
    Write-Host "X Build that bai!" -ForegroundColor Red
    Pause
    exit 1
}

Write-Host "2. Dang cap nhat version de pha cache Cloudflare..." -ForegroundColor Cyan
$timestamp = Get-Date -Format "yyyyMMddHHmmss"
$appDir = "build\web"

# Sua flutter_bootstrap.js
$bootstrapPath = "$appDir\flutter_bootstrap.js"
if (Test-Path $bootstrapPath) {
    $bootstrap = Get-Content $bootstrapPath -Raw
    $bootstrap = $bootstrap -replace '"mainJsPath":"main\.dart\.js"', "`"mainJsPath`":`"main.dart.js?v=$timestamp`""
    Set-Content $bootstrapPath $bootstrap -NoNewline
}

# Sua index.html
$indexPath = "$appDir\index.html"
if (Test-Path $indexPath) {
    $index = Get-Content $indexPath -Raw
    $index = $index -replace 'src="flutter_bootstrap\.js.*?"', "src=`"flutter_bootstrap.js?v=$timestamp`""
    Set-Content $indexPath $index -NoNewline
}

Write-Host "3. Dang tao file nen zip..." -ForegroundColor Cyan
$zipPath = "web_build_FINAL.zip"
Remove-Item $zipPath -Force -ErrorAction SilentlyContinue
Compress-Archive -Path "$appDir\*" -DestinationPath $zipPath -Force

Write-Host "=============================================" -ForegroundColor Green
Write-Host "DONE! File web_build_FINAL.zip da san sang." -ForegroundColor Green
Write-Host "=============================================" -ForegroundColor Green
Write-Host "-> Copy file web_build_FINAL.zip sang may chu va giai nen vao C:\web_build" -ForegroundColor Yellow

Pause
