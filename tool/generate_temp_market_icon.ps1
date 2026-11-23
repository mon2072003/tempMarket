$ErrorActionPreference = 'Stop'
Add-Type -AssemblyName System.Drawing

$root = (Get-Location).Path
$assetDir = Join-Path $root 'assets/branding'
New-Item -ItemType Directory -Force -Path $assetDir | Out-Null

function New-TempMarketIcon([int]$size) {
  $bitmap = [System.Drawing.Bitmap]::new(
    $size,
    $size,
    [System.Drawing.Imaging.PixelFormat]::Format32bppArgb
  )
  $graphics = [System.Drawing.Graphics]::FromImage($bitmap)
  $graphics.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::AntiAlias
  $graphics.PixelOffsetMode = [System.Drawing.Drawing2D.PixelOffsetMode]::HighQuality
  $graphics.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
  $graphics.ScaleTransform($size / 1024.0, $size / 1024.0)

  $canvas = [System.Drawing.Rectangle]::new(0, 0, 1024, 1024)
  $background = [System.Drawing.Drawing2D.LinearGradientBrush]::new(
    $canvas,
    [System.Drawing.Color]::FromArgb(255, 23, 76, 120),
    [System.Drawing.Color]::FromArgb(255, 16, 43, 80),
    45
  )
  $graphics.FillRectangle($background, $canvas)

  $glowPath = [System.Drawing.Drawing2D.GraphicsPath]::new()
  $glowPath.AddEllipse(35, 25, 870, 870)
  $glow = [System.Drawing.Drawing2D.PathGradientBrush]::new($glowPath)
  $glow.CenterColor = [System.Drawing.Color]::FromArgb(64, 57, 139, 160)
  $glow.SurroundColors = @([System.Drawing.Color]::FromArgb(0, 57, 139, 160))
  $graphics.FillRectangle($glow, $canvas)

  $cream = [System.Drawing.Color]::FromArgb(255, 255, 248, 237)
  $handlePath = [System.Drawing.Drawing2D.GraphicsPath]::new()
  $handlePath.AddBezier(379, 356, 379, 253, 438, 185, 512, 185)
  $handlePath.AddBezier(512, 185, 586, 185, 645, 253, 645, 356)
  $handlePen = [System.Drawing.Pen]::new($cream, 42)
  $handlePen.StartCap = [System.Drawing.Drawing2D.LineCap]::Round
  $handlePen.EndCap = [System.Drawing.Drawing2D.LineCap]::Round
  $graphics.DrawPath($handlePen, $handlePath)

  $bag = [System.Drawing.Drawing2D.GraphicsPath]::new()
  $bag.AddBezier(318, 330, 297, 330, 277, 348, 279, 371)
  $bag.AddLine(279, 371, 316, 790)
  $bag.AddBezier(316, 790, 320, 833, 355, 866, 398, 866)
  $bag.AddLine(398, 866, 626, 866)
  $bag.AddBezier(626, 866, 669, 866, 704, 833, 708, 790)
  $bag.AddLine(708, 790, 745, 371)
  $bag.AddBezier(745, 371, 747, 348, 727, 330, 706, 330)
  $bag.CloseFigure()
  $bagBrush = [System.Drawing.Drawing2D.LinearGradientBrush]::new(
    [System.Drawing.Rectangle]::new(280, 330, 465, 540),
    $cream,
    [System.Drawing.Color]::FromArgb(255, 242, 234, 220),
    90
  )
  $graphics.FillPath($bagBrush, $bag)

  $seamPen = [System.Drawing.Pen]::new([System.Drawing.Color]::FromArgb(255, 232, 223, 208), 13)
  $seamPen.StartCap = [System.Drawing.Drawing2D.LineCap]::Round
  $seamPen.EndCap = [System.Drawing.Drawing2D.LineCap]::Round
  $graphics.DrawLine($seamPen, 333, 379, 691, 379)

  $teal = [System.Drawing.SolidBrush]::new([System.Drawing.Color]::FromArgb(255, 22, 165, 139))
  $graphics.FillEllipse($teal, 380, 453, 264, 264)
  $markPen = [System.Drawing.Pen]::new($cream, 34)
  $markPen.StartCap = [System.Drawing.Drawing2D.LineCap]::Round
  $markPen.EndCap = [System.Drawing.Drawing2D.LineCap]::Round
  $graphics.DrawLine($markPen, 512, 508, 512, 662)
  $graphics.DrawLine($markPen, 455, 520, 569, 520)
  $gold = [System.Drawing.SolidBrush]::new([System.Drawing.Color]::FromArgb(255, 244, 185, 66))
  $graphics.FillEllipse($gold, 685, 727, 44, 44)

  $graphics.Dispose()
  $background.Dispose()
  $glow.Dispose()
  $glowPath.Dispose()
  $handlePath.Dispose()
  $handlePen.Dispose()
  $bag.Dispose()
  $bagBrush.Dispose()
  $seamPen.Dispose()
  $teal.Dispose()
  $markPen.Dispose()
  $gold.Dispose()
  return $bitmap
}

$master = New-TempMarketIcon 1024
$master.Save((Join-Path $assetDir 'temp_market_icon.png'), [System.Drawing.Imaging.ImageFormat]::Png)

$targets = [ordered]@{
  'android/app/src/main/res/mipmap-mdpi/ic_launcher.png' = 48
  'android/app/src/main/res/mipmap-hdpi/ic_launcher.png' = 72
  'android/app/src/main/res/mipmap-xhdpi/ic_launcher.png' = 96
  'android/app/src/main/res/mipmap-xxhdpi/ic_launcher.png' = 144
  'android/app/src/main/res/mipmap-xxxhdpi/ic_launcher.png' = 192
  'ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-20x20@1x.png' = 20
  'ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-20x20@2x.png' = 40
  'ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-20x20@3x.png' = 60
  'ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-29x29@1x.png' = 29
  'ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-29x29@2x.png' = 58
  'ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-29x29@3x.png' = 87
  'ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-40x40@1x.png' = 40
  'ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-40x40@2x.png' = 80
  'ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-40x40@3x.png' = 120
  'ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-60x60@2x.png' = 120
  'ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-60x60@3x.png' = 180
  'ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-76x76@1x.png' = 76
  'ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-76x76@2x.png' = 152
  'ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-83.5x83.5@2x.png' = 167
  'ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-1024x1024@1x.png' = 1024
}

foreach ($entry in $targets.GetEnumerator()) {
  $filePath = Join-Path $root $entry.Key
  New-Item -ItemType Directory -Force -Path (Split-Path $filePath -Parent) | Out-Null
  $size = [int]$entry.Value
  $icon = [System.Drawing.Bitmap]::new($size, $size, [System.Drawing.Imaging.PixelFormat]::Format32bppArgb)
  $renderer = [System.Drawing.Graphics]::FromImage($icon)
  $renderer.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::HighQuality
  $renderer.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
  $renderer.PixelOffsetMode = [System.Drawing.Drawing2D.PixelOffsetMode]::HighQuality
  $renderer.DrawImage($master, 0, 0, $size, $size)
  $renderer.Dispose()
  $icon.Save($filePath, [System.Drawing.Imaging.ImageFormat]::Png)
  $icon.Dispose()
}

$master.Dispose()
Write-Output "Generated tempMarket icon assets."
