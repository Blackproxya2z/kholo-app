<#
.SYNOPSIS
    KHOLO Production FCM Update Notification Trigger Script
.DESCRIPTION
    Sends an FCM Topic notification to 'kholo_updates' or to a specific device registration token.
    Payload formatted to trigger automatic update prompt in installed KHOLO apps.
#>

param(
    [string]$TargetToken = "",
    [string]$ServerKey = $env:FCM_SERVER_KEY
)

$payload = @{
    to = if ($TargetToken) { $TargetToken } else { "/topics/kholo_updates" }
    priority = "high"
    notification = @{
        title = "🌸 New KHOLO Update Available"
        body = "KHOLO v1.4.0 is ready. Update now to explore Bloom Health Hub."
        click_action = "OPEN_UPDATE"
        sound = "default"
        android_channel_id = "kholo_updates_channel"
    }
    data = @{
        action = "kholo_update"
        payload = "kholo_update"
        click_action = "OPEN_UPDATE"
        latest_version = "1.4.0"
        version_code = "22"
        force_update = "false"
        title = "🌸 New KHOLO Update Available"
        body = "KHOLO v1.4.0 is ready. Update now."
    }
} | ConvertTo-Json -Depth 5

Write-Host "===================================================="
Write-Host "KHOLO FCM UPDATE CAMPAIGN DISPATCH"
Write-Host "===================================================="
Write-Host "Target: $(if ($TargetToken) { "Device Token: $TargetToken" } else { "Topic: /topics/kholo_updates" })"
Write-Host "Payload:"
Write-Host $payload
Write-Host "===================================================="

if ($ServerKey) {
    $headers = @{
        "Authorization" = "key=$ServerKey"
        "Content-Type" = "application/json"
    }
    try {
        $response = Invoke-RestMethod -Uri "https://fcm.googleapis.com/fcm/send" -Method Post -Headers $headers -Body $payload
        Write-Host "FCM Notification dispatched successfully!"
        Write-Host ($response | ConvertTo-Json)
    } catch {
        Write-Host "Error sending FCM notification: $_"
    }
} else {
    Write-Host "NOTE: To send live FCM push via this script, set `$env:FCM_SERVER_KEY or paste the payload above directly in Firebase Console -> Cloud Messaging -> Send Test Message."
}
