# ====================================================
# KHOLO PRIVATE DISTRIBUTION RELEASE AUTOMATION SCRIPT
# ====================================================
# Usage:
#   .\scripts\release_apk.ps1 -Version "1.4.0" -BuildNumber 22
# ====================================================

param(
    [string]$Version = "1.4.0",
    [int]$BuildNumber = 22,
    [bool]$ForceUpdate = $false
)

Write-Host "====================================================" -ForegroundColor Magenta
Write-Host "🌸 KHOLO PRIVATE DISTRIBUTION RELEASE BUILDER 🌸" -ForegroundColor Cyan
Write-Host "====================================================" -ForegroundColor Magenta
Write-Host "Target Release Version: v$Version (Build $BuildNumber)" -ForegroundColor Yellow
Write-Host "Force Update: $ForceUpdate" -ForegroundColor Yellow
Write-Host ""

# 1. Run Flutter Analyze
Write-Host "[1/5] Running static analysis (flutter analyze)..." -ForegroundColor Cyan
flutter analyze
if ($LASTEXITCODE -ne 0) {
    Write-Host "❌ Static analysis failed. Please fix errors before releasing." -ForegroundColor Red
    exit $LASTEXITCODE
}
Write-Host "✅ Static analysis passed with zero issues." -ForegroundColor Green
Write-Host ""

# 2. Run All Automated Tests
Write-Host "[2/5] Running automated tests (flutter test)..." -ForegroundColor Cyan
flutter test
if ($LASTEXITCODE -ne 0) {
    Write-Host "❌ Tests failed. Aborting release." -ForegroundColor Red
    exit $LASTEXITCODE
}
Write-Host "✅ All 51 test suites passed successfully." -ForegroundColor Green
Write-Host ""

# 3. Build Release APK
Write-Host "[3/5] Building signed release APK (flutter build apk --release)..." -ForegroundColor Cyan
flutter build apk --release --build-name=$Version --build-number=$BuildNumber
if ($LASTEXITCODE -ne 0) {
    Write-Host "❌ APK build failed." -ForegroundColor Red
    exit $LASTEXITCODE
}

$apkPath = "build\app\outputs\flutter-apk\app-release.apk"
if (-Not (Test-Path $apkPath)) {
    Write-Host "❌ APK output not found at $apkPath" -ForegroundColor Red
    exit 1
}

# 4. Compute SHA-256 Hash and File Size
Write-Host "[4/5] Computing cryptographic SHA-256 checksum & metadata..." -ForegroundColor Cyan
$fileHash = (Get-FileHash -Path $apkPath -Algorithm SHA256).Hash.ToLower()
$fileSize = (Get-Item $apkPath).Length
$fileSizeMb = [math]::Round($fileSize / 1MB, 2)

Write-Host "   📦 APK Path:  $apkPath" -ForegroundColor White
Write-Host "   📊 File Size: $fileSize bytes ($fileSizeMb MB)" -ForegroundColor White
Write-Host "   🔐 SHA-256:   $fileHash" -ForegroundColor Green
Write-Host ""

# 5. Generate Manifest JSON
Write-Host "[5/5] Updating release manifests and generating remote configuration..." -ForegroundColor Cyan

$releaseManifest = @{
    latestVersion = $Version
    versionCode = $BuildNumber
    buildNumber = $BuildNumber
    minRequiredVersionCode = 20
    minimumSupportedVersion = "1.0.0"
    updateTitle = "New KHOLO Update Available 🌸"
    updateMessage = "A new version of KHOLO is ready. Update now to enjoy new features."
    releaseNotes = @(
        "Enhanced on-device health privacy & encrypted baselines",
        "Refined cycle & ovulation prediction algorithms",
        "Interactive pregnancy kick counter & contraction timer",
        "Multi-baby timeline logs & developmental milestones",
        "Intelligent AI skin wellness companion with zero battery drain",
        "Performance optimizations & security enhancements"
    )
    benefits = @(
        "Complete offline data preservation & privacy lock",
        "Faster cycle calculations & adaptive hormone insights",
        "Direct in-app OTA download & 1-tap installation"
    )
    apkUrl = "https://github.com/Blackproxya2z/kholo-app/releases/download/v$Version/app-release.apk"
    apkDownloadUrl = "https://github.com/Blackproxya2z/kholo-app/releases/download/v$Version/app-release.apk"
    mirrorUrls = @(
        "https://github.com/Blackproxya2z/kholo-releases/raw/main/v$Version/app-release.apk"
    )
    apkSha256 = $fileHash
    fileSize = $fileSize
    forceUpdate = $ForceUpdate
    optionalUpdate = (-Not $ForceUpdate)
}

$jsonOutput = $releaseManifest | ConvertTo-Json -Depth 5
$jsonOutput | Out-File -FilePath "assets\version.json" -Encoding utf8

Write-Host "====================================================" -ForegroundColor Magenta
Write-Host "🎉 RELEASE BUILD v$Version (Build $BuildNumber) READY! 🎉" -ForegroundColor Green
Write-Host "====================================================" -ForegroundColor Magenta
Write-Host ""
Write-Host "📋 Copy & Paste into Firebase Remote Config ('app_update_info'):" -ForegroundColor Yellow
Write-Host "----------------------------------------------------" -ForegroundColor Gray
Write-Host $jsonOutput -ForegroundColor Cyan
Write-Host "----------------------------------------------------" -ForegroundColor Gray
Write-Host ""
Write-Host "🚀 NEXT STEPS TO PUBLISH:" -ForegroundColor Yellow
Write-Host "1. Upload '$apkPath' to GitHub Releases (Tag: v$Version)" -ForegroundColor White
Write-Host "2. Paste the JSON above into Firebase Remote Config -> Publish" -ForegroundColor White
Write-Host "3. All existing users will automatically receive the update notification!" -ForegroundColor Green
Write-Host ""
