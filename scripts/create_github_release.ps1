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

$releasePayload = @{
    tag_name = 'v1.4.0'
    target_commitish = 'main'
    name = 'KHOLO v1.4.0 (Build 22) — Bloom Health Hub'
    body = @"
🌸 **নতুন KHOLO v1.4.0 — Bloom Health Hub রিলিজ!**

✨ **নতুন ফিচারসমূহ:**
• 🌸 **KHOLO Bloom Health Hub:** দৈনিক স্বাস্থ্য শিক্ষা ও ৬টি ক্যাটাগরি (Women Health, Skin Care, Sexual Wellness, Men Health, Mental Wellness, Nutrition)
• 🧠 **AI পারসোনালাইজড হেলথ ফিড:** প্রেগন্যান্সি, সাইকেল ফেজ ও PCOS প্রোফাইল অনুযায়ী কাস্টমাইজড গাইড
• 🔍 **রিয়েল-টাইম বাইলিঙ্গুয়াল সার্চ ইঞ্জিন:** বাংলা ও ইংরেজি উভয় ভাষায় লাইভ সার্চ
• 💬 **KHOLO AI Health Guide:** রেফারেন্সভিত্তিক নিরাপদ ক্লিনিক্যাল স্বাস্থ্য পরামর্শক
• 🌟 **দৈনিক স্বাস্থ্য কার্ড ও স্ট্রিক:** অফলাইন বুকমার্কস ও স্ট্রিক ট্র্যাকার
• 🌐 **তাৎক্ষণিক ভাষা পরিবর্তন:** বাংলা ⇄ English

⚡ **পারফরম্যান্স ও সিকিউরিটি:**
• 🛡️ WHO / NHS / ACOG ক্লিনিক্যাল তথ্যসূত্র
• 📦 SHA-256 ইন্টিগ্রিটি হ্যাশ: `c26115ce11ed58f5e8eab39579cf44761104809193bc7f837bd30c5e38969730`
• 🚀 জিরো-ক্যাশ ইন-অ্যাপ অটো-আপডেট ও ওয়ান-ট্যাপ নোটিফিকেশন ইনস্টলার
"@
    draft = $false
    prerelease = $false
} | ConvertTo-Json -Depth 5

Write-Host "Creating GitHub Release for v1.4.0..."
try {
    $release = Invoke-RestMethod -Uri 'https://api.github.com/repos/Blackproxya2z/kholo-app/releases' -Method Post -Headers $headers -Body ([System.Text.Encoding]::UTF8.GetBytes($releasePayload)) -ContentType 'application/json; charset=utf-8'
    Write-Host "Release created successfully! ID: $($release.id)"
    $uploadUrl = $release.upload_url -replace '\{\?name,label\}', '?name=app-release.apk'
} catch {
    Write-Host "Release might already exist, fetching existing release for v1.4.0..."
    $release = Invoke-RestMethod -Uri 'https://api.github.com/repos/Blackproxya2z/kholo-app/releases/tags/v1.4.0' -Method Get -Headers $headers
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
