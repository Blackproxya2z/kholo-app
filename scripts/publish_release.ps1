[CmdletBinding()]
param (
    [switch]$SkipBuild
)

[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12 -bor [Net.SecurityProtocolType]::Tls13
$ErrorActionPreference = 'Stop'

Write-Host "`n🌸 ==========================================" -ForegroundColor Magenta
Write-Host "   KHOLO AUTOMATED RELEASE PIPELINE" -ForegroundColor Magenta
Write-Host "==========================================`n" -ForegroundColor Magenta

# 1. Read Version & Build from pubspec.yaml
$pubspec = Get-Content 'pubspec.yaml' -Raw
if ($pubspec -match 'version:\s*([0-9\.]+)\+([0-9]+)') {
    $versionName = $Matches[1]
    $buildNumber = [int]$Matches[2]
} else {
    Write-Error "Could not parse version from pubspec.yaml"
    exit 1
}

$verTag = "v$versionName"
Write-Host "📦 Target Release: $verTag (Build $buildNumber)" -ForegroundColor Cyan

# 2. Build Release APK (if not skipped)
$apkPath = "build\app\outputs\flutter-apk\app-release.apk"
if (-not $SkipBuild) {
    Write-Host "🔨 Building production release APK..." -ForegroundColor Yellow
    flutter build apk --release
    if ($LASTEXITCODE -ne 0) {
        Write-Error "Flutter build failed!"
        exit 1
    }
}

if (-not (Test-Path $apkPath)) {
    Write-Error "Release APK not found at $apkPath"
    exit 1
}

# 3. Calculate Checksum & Size
$fileHash = (Get-FileHash -Algorithm SHA256 $apkPath).Hash.ToLower()
$fileSize = (Get-Item $apkPath).Length
Write-Host "🛡️ SHA-256: $fileHash" -ForegroundColor Green
Write-Host "📊 File Size: $fileSize bytes ($([math]::Round($fileSize / 1MB, 2)) MB)" -ForegroundColor Green

$apkUrl = "https://github.com/Blackproxya2z/kholo-app/releases/download/$verTag/app-release.apk"
$mirrorUrl = "https://raw.githubusercontent.com/Blackproxya2z/kholo-releases/main/$verTag/app-release.apk"

# 4. Update version.json & assets/version.json
$manifestObj = @{
    latestVersion = $versionName
    latest_version = $versionName
    versionCode = $buildNumber
    version_code = $buildNumber
    minRequiredVersionCode = 1
    min_required_version_code = 1
    min_supported_version = "1.0.0"
    update_title = "🌸 New KHOLO Update Available"
    update_message = "A new KHOLO experience is ready. Enjoy improved Bloom Health Hub, AI Health Guide, and new features."
    releaseNotes = "🌸 KHOLO $verTag (Build $buildNumber) — Production Update Release`n`n✨ New Features & Improvements:`n• 🌸 KHOLO Bloom Health Hub: Integrated into main bottom navigation`n• 🧠 Upgraded AI Health Guide: Conversational bilingual assistant`n• 📚 8 Curated Health Categories: Comprehensive medical guidance`n• ⚡ Instant Launch (< 50ms startup with resilient background initialization)`n• 🛡️ Zero Duplicate Notifications & Smart Dismissal Management`n• 🔒 100% On-Device Data Safety"
    release_notes = "🌸 KHOLO $verTag (Build $buildNumber) — Production Update Release`n`n✨ New Features & Improvements:`n• 🌸 KHOLO Bloom Health Hub: Integrated into main bottom navigation`n• 🧠 Upgraded AI Health Guide: Conversational bilingual assistant`n• 📚 8 Curated Health Categories: Comprehensive medical guidance`n• ⚡ Instant Launch (< 50ms startup with resilient background initialization)`n• 🛡️ Zero Duplicate Notifications & Smart Dismissal Management`n• 🔒 100% On-Device Data Safety"
    download_url = $apkUrl
    apkUrl = $apkUrl
    mirror_urls = @($mirrorUrl, $apkUrl)
    mirrorUrls = @($mirrorUrl, $apkUrl)
    file_size = $fileSize
    fileSize = $fileSize
    apk_sha256 = $fileHash
    apkSha256 = $fileHash
    action = "OPEN_UPDATE"
    forceUpdate = $false
    force_update = $false
}

$manifestJson = $manifestObj | ConvertTo-Json -Depth 5
[System.IO.File]::WriteAllText((Resolve-Path 'version.json').Path, $manifestJson)
[System.IO.File]::WriteAllText((Resolve-Path 'assets/version.json').Path, $manifestJson)
Write-Host "✅ version.json & assets/version.json updated!" -ForegroundColor Green

# 5. GitHub API Authentication
$token = $env:GITHUB_TOKEN
if (-not $token) {
    $token = git config --get remote.origin.url | Select-String -Pattern '(?<=https://[^:]+:)[^@]+' | ForEach-Object { $_.Matches.Value }
}
$headers = @{
    'Authorization' = "Bearer $token"
    'Accept' = 'application/vnd.github.v3+json'
    'User-Agent' = 'KHOLO-Release-Pipeline'
}

# 6. Create or Get GitHub Release
Write-Host "🚀 Creating GitHub Release for $verTag..." -ForegroundColor Yellow
$releasePayload = @{
    tag_name = $verTag
    target_commitish = 'main'
    name = "KHOLO $verTag (Build $buildNumber) — Production Update"
    body = $manifestObj.releaseNotes
    draft = $false
    prerelease = $false
} | ConvertTo-Json -Depth 5

try {
    $release = Invoke-RestMethod -Uri 'https://api.github.com/repos/Blackproxya2z/kholo-app/releases' -Method Post -Headers $headers -Body ([System.Text.Encoding]::UTF8.GetBytes($releasePayload)) -ContentType 'application/json; charset=utf-8'
    $uploadUrl = $release.upload_url -replace '\{\?name,label\}', '?name=app-release.apk'
} catch {
    $release = Invoke-RestMethod -Uri "https://api.github.com/repos/Blackproxya2z/kholo-app/releases/tags/$verTag" -Method Get -Headers $headers
    $uploadUrl = $release.upload_url -replace '\{\?name,label\}', '?name=app-release.apk'
}

# 7. Delete Old Asset & Upload New APK
$uploadHeaders = @{
    'Authorization' = "Bearer $token"
    'Content-Type' = 'application/vnd.android.package-archive'
    'User-Agent' = 'KHOLO-Release-Pipeline'
}

$existingAssets = Invoke-RestMethod -Uri "https://api.github.com/repos/Blackproxya2z/kholo-app/releases/$($release.id)/assets" -Method Get -Headers $headers
foreach ($a in $existingAssets) {
    if ($a.name -eq 'app-release.apk') {
        Invoke-RestMethod -Uri "https://api.github.com/repos/Blackproxya2z/kholo-app/releases/assets/$($a.id)" -Method Delete -Headers $headers
    }
}

Write-Host "⬆️ Uploading APK to release assets..." -ForegroundColor Yellow
$apkBytes = [System.IO.File]::ReadAllBytes((Resolve-Path $apkPath).Path)
$asset = Invoke-RestMethod -Uri $uploadUrl -Method Post -Headers $uploadHeaders -Body $apkBytes
Write-Host "🎉 APK Uploaded Successfully! Download URL: $($asset.browser_download_url)" -ForegroundColor Green

# 8. Sync kholo-releases repository
Write-Host "🔄 Syncing kholo-releases CDN repository..." -ForegroundColor Yellow
& (Resolve-Path 'scripts/sync_kholo_releases.ps1').Path

Write-Host "`n🌸 ==========================================" -ForegroundColor Magenta
Write-Host "   RELEASE $verTag (Build $buildNumber) DEPLOYED!" -ForegroundColor Green
Write-Host "==========================================`n" -ForegroundColor Magenta
