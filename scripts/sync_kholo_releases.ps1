$token = $env:GITHUB_TOKEN
if (-not $token) {
    $token = git config --get remote.origin.url | Select-String -Pattern '(?<=https://[^:]+:)[^@]+' | ForEach-Object { $_.Matches.Value }
}

$headers = @{
    'Authorization' = "Bearer $token"
    'Accept' = 'application/vnd.github.v3+json'
    'User-Agent' = 'KHOLO-Release-Manager'
}

Write-Host "Syncing version.json to Blackproxya2z/kholo-releases..."
try {
    $fileInfo = Invoke-RestMethod -Uri 'https://api.github.com/repos/Blackproxya2z/kholo-releases/contents/version.json' -Method Get -Headers $headers
    $sha = $fileInfo.sha
    Write-Host "Found remote file sha: $sha"
    
    $contentBytes = [System.IO.File]::ReadAllBytes('version.json')
    $base64Content = [Convert]::ToBase64String($contentBytes)
    
    $body = @{
        message = 'Update version manifest to v1.4.0 (Build 22)'
        content = $base64Content
        sha = $sha
    } | ConvertTo-Json
    
    $res = Invoke-RestMethod -Uri 'https://api.github.com/repos/Blackproxya2z/kholo-releases/contents/version.json' -Method Put -Headers $headers -Body $body
    Write-Host "Successfully synced version.json to kholo-releases repository!"
} catch {
    Write-Host "Error syncing to kholo-releases: $_"
}
