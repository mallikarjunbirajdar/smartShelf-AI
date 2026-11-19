Add-Type -AssemblyName System.Drawing

function Resize-Image {
    param(
        [string]$SrcPath,
        [string]$DestPath,
        [int]$Width,
        [int]$Height
    )
    $src = [System.Drawing.Image]::FromFile($SrcPath)
    $dest = New-Object System.Drawing.Bitmap($Width, $Height)
    $g = [System.Drawing.Graphics]::FromImage($dest)
    $g.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
    $g.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::HighQuality
    $g.PixelOffsetMode = [System.Drawing.Drawing2D.PixelOffsetMode]::HighQuality
    $g.CompositingQuality = [System.Drawing.Drawing2D.CompositingQuality]::HighQuality
    $g.DrawImage($src, 0, 0, $Width, $Height)
    
    $parentDir = Split-Path -Parent $DestPath
    if (-not (Test-Path $parentDir)) {
        New-Item -ItemType Directory -Path $parentDir -Force | Out-Null
    }
    
    $dest.Save($DestPath, [System.Drawing.Imaging.ImageFormat]::Png)
    $g.Dispose()
    $dest.Dispose()
    $src.Dispose()
    Write-Host "Generated: $DestPath ($Width x $Height)"
}

$srcLogo = (Resolve-Path "assets\images\shelf_ai_logo.jpg").Path

# Android Mipmaps
Resize-Image $srcLogo "android\app\src\main\res\mipmap-mdpi\ic_launcher.png" 48 48
Resize-Image $srcLogo "android\app\src\main\res\mipmap-hdpi\ic_launcher.png" 72 72
Resize-Image $srcLogo "android\app\src\main\res\mipmap-xhdpi\ic_launcher.png" 96 96
Resize-Image $srcLogo "android\app\src\main\res\mipmap-xxhdpi\ic_launcher.png" 144 144
Resize-Image $srcLogo "android\app\src\main\res\mipmap-xxxhdpi\ic_launcher.png" 192 192

# Web Icons
Resize-Image $srcLogo "web\favicon.png" 48 48
Resize-Image $srcLogo "web\icons\Icon-192.png" 192 192
Resize-Image $srcLogo "web\icons\Icon-512.png" 512 512
Resize-Image $srcLogo "web\icons\Icon-maskable-192.png" 192 192
Resize-Image $srcLogo "web\icons\Icon-maskable-512.png" 512 512

# iOS App Icons
$iosDir = "ios\Runner\Assets.xcassets\AppIcon.appiconset"
Resize-Image $srcLogo "$iosDir\Icon-App-20x20@1x.png" 20 20
Resize-Image $srcLogo "$iosDir\Icon-App-20x20@2x.png" 40 40
Resize-Image $srcLogo "$iosDir\Icon-App-20x20@3x.png" 60 60
Resize-Image $srcLogo "$iosDir\Icon-App-29x29@1x.png" 29 29
Resize-Image $srcLogo "$iosDir\Icon-App-29x29@2x.png" 58 58
Resize-Image $srcLogo "$iosDir\Icon-App-29x29@3x.png" 87 87
Resize-Image $srcLogo "$iosDir\Icon-App-40x40@1x.png" 40 40
Resize-Image $srcLogo "$iosDir\Icon-App-40x40@2x.png" 80 80
Resize-Image $srcLogo "$iosDir\Icon-App-40x40@3x.png" 120 120
Resize-Image $srcLogo "$iosDir\Icon-App-60x60@2x.png" 120 120
Resize-Image $srcLogo "$iosDir\Icon-App-60x60@3x.png" 180 180
Resize-Image $srcLogo "$iosDir\Icon-App-76x76@1x.png" 76 76
Resize-Image $srcLogo "$iosDir\Icon-App-76x76@2x.png" 152 152
Resize-Image $srcLogo "$iosDir\Icon-App-83.5x83.5@2x.png" 167 167
Resize-Image $srcLogo "$iosDir\Icon-App-1024x1024@1x.png" 1024 1024

# Windows Icon
$bmp = [System.Drawing.Bitmap]::FromFile("$iosDir\Icon-App-1024x1024@1x.png")
$thumb = New-Object System.Drawing.Bitmap($bmp, 256, 256)
$hIcon = $thumb.GetHicon()
$icon = [System.Drawing.Icon]::FromHandle($hIcon)
$fs = New-Object System.IO.FileStream("windows\runner\resources\app_icon.ico", [System.IO.FileMode]::Create)
$icon.Save($fs)
$fs.Close()
$icon.Dispose()
$thumb.Dispose()
$bmp.Dispose()
Write-Host "Generated: windows\runner\resources\app_icon.ico"

Write-Host "All icons generated successfully!"
