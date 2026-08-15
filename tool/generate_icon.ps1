New-Item -ItemType Directory -Force -Path 'assets/icon' | Out-Null
Add-Type -AssemblyName System.Drawing

$src = 'C:\Users\Jain\.gemini\antigravity-ide\brain\37bae833-821c-42dd-88c0-64a6398d64d2\kholo_app_icon_1786812499667.jpg'
$bmp = [System.Drawing.Bitmap]::FromFile($src)
$resized = New-Object System.Drawing.Bitmap 1024, 1024
$g = [System.Drawing.Graphics]::FromImage($resized)
$g.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
$g.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::HighQuality
$g.PixelOffsetMode = [System.Drawing.Drawing2D.PixelOffsetMode]::HighQuality
$g.DrawImage($bmp, 0, 0, 1024, 1024)
$resized.Save('assets/icon/app_icon.png', [System.Drawing.Imaging.ImageFormat]::Png)

$g.Dispose()
$resized.Dispose()
$bmp.Dispose()

Write-Host "Generated assets/icon/app_icon.png successfully."
Get-Item assets/icon/app_icon.png
