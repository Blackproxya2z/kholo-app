[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12 -bor [Net.SecurityProtocolType]::Tls13
$token = $env:GITHUB_TOKEN
if (-not $token) {
    $token = git config --get remote.origin.url | Select-String -Pattern '(?<=https://[^:]+:)[^@]+' | ForEach-Object { $_.Matches.Value }
}
$headers = @{
    'Authorization' = "Bearer $token"
    'Accept' = 'application/vnd.github.v3+json'
    'User-Agent' = 'KHOLO-Release-Manager'
}

$manifest = Get-Content 'version.json' -Raw | ConvertFrom-Json
$verTag = "v$($manifest.latestVersion)"
$relName = "KHOLO $verTag (Build $($manifest.versionCode)) - Production Update"
$relBody = $manifest.releaseNotes

$releasePayload = @{
    tag_name = $verTag
    target_commitish = 'main'
    name = $relName
    body = $relBody
    draft = $false
    prerelease = $false
} | ConvertTo-Json -Depth 5

Write-Host "Creating GitHub Release for $verTag..."
try {
    $release = Invoke-RestMethod -Uri 'https://api.github.com/repos/Blackproxya2z/kholo-app/releases' -Method Post -Headers $headers -Body ([System.Text.Encoding]::UTF8.GetBytes($releasePayload)) -ContentType 'application/json; charset=utf-8'
    Write-Host "Release created successfully! ID: $($release.id)"
    $uploadUrl = $release.upload_url -replace '\{\?name,label\}', '?name=app-release.apk'
} catch {
    Write-Host "Release might already exist, fetching existing release for $verTag..."
    $release = Invoke-RestMethod -Uri "https://api.github.com/repos/Blackproxya2z/kholo-app/releases/tags/$verTag" -Method Get -Headers $headers
    Write-Host "Existing Release ID: $($release.id)"
    $uploadUrl = $release.upload_url -replace '\{\?name,label\}', '?name=app-release.apk'
}

$apkPath = "build\app\outputs\flutter-apk\app-release.apk"
if (Test-Path $apkPath) {
    Write-Host "Checking existing release assets for $($release.id)..."
    $uploadHeaders = @{
        'Authorization' = "Bearer $token"
        'Content-Type' = 'application/vnd.android.package-archive'
        'User-Agent' = 'KHOLO-Release-Manager'
    }
    
    $existingAssets = Invoke-RestMethod -Uri "https://api.github.com/repos/Blackproxya2z/kholo-app/releases/$($release.id)/assets" -Method Get -Headers $headers
    foreach ($a in $existingAssets) {
        if ($a.name -eq 'app-release.apk') {
            Write-Host "Deleting existing asset ID $($a.id)..."
            Invoke-RestMethod -Uri "https://api.github.com/repos/Blackproxya2z/kholo-app/releases/assets/$($a.id)" -Method Delete -Headers $headers
        }
    }

    Write-Host "Uploading latest $apkPath to release assets..."
    $apkBytes = [System.IO.File]::ReadAllBytes((Resolve-Path $apkPath).Path)
    $asset = Invoke-RestMethod -Uri $uploadUrl -Method Post -Headers $uploadHeaders -Body $apkBytes
    Write-Host "APK uploaded successfully! Download URL: $($asset.browser_download_url)"
} else {
    Write-Host "Error: APK file not found at $apkPath"
}
