# Generates the launcher-icon variants from assets/icon/icon.png.
#
# The source art is a rounded square (corner radius ~210px) inset ~24px inside
# an OPAQUE WHITE canvas — not a transparent one. That white is the whole
# reason this script exists:
#
#   * iOS/macOS/Windows want full-bleed art and apply their own corner mask.
#     Feeding them the source directly leaves white showing at the four edge
#     midpoints, where no platform mask cuts anything. icon_fullbleed.png
#     extends the art to every edge instead.
#   * Android's adaptive foreground is masked to roughly the centre 66%. White
#     corners would render as white wedges floating on the blue background
#     layer, so icon_foreground.png drops them and insets the art so nothing
#     important falls outside the safe zone.
#
# The corners are removed GEOMETRICALLY, by clipping to a rounded rectangle —
# NOT by colour-keying white. The artwork's own interior is full of white (the
# document, the graduation cap, the pointing hand), so keying on colour
# punches transparent holes straight through the subject. That mistake renders
# as a plausible-looking icon with the document shot through, which is exactly
# the kind of damage that survives a casual glance.
#
# Corner fill for the full-bleed variant works by compositing the same clipped
# art scaled up ~1.34x underneath the 1.0x copy. The enlarged copy's own
# corners fall outside the canvas, so its solid body covers precisely the
# wedges the 1.0x copy leaves empty, and the gradient continues naturally.
#
# Run from the project root:  pwsh -File tool\gen_icon_variants.ps1
# Only the generated PNGs are committed; rerun this if the source art changes.

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
Add-Type -AssemblyName System.Drawing

$root = Split-Path -Parent $PSScriptRoot
$src = Join-Path $root 'assets\icon\icon.png'
if (-not (Test-Path $src)) { throw "source not found: $src" }

$bmp = New-Object System.Drawing.Bitmap $src
$W = $bmp.Width
$H = $bmp.Height

# Pull the image into a byte array once; per-pixel GetPixel over a 1024x1024
# canvas is slow enough to make this script unusable.
$rect = New-Object System.Drawing.Rectangle 0, 0, $W, $H
$data = $bmp.LockBits($rect, [System.Drawing.Imaging.ImageLockMode]::ReadOnly,
    [System.Drawing.Imaging.PixelFormat]::Format32bppArgb)
$stride = $data.Stride
$buf = New-Object byte[] ($stride * $H)
[System.Runtime.InteropServices.Marshal]::Copy($data.Scan0, $buf, 0, $buf.Length)
$bmp.UnlockBits($data)

# BGRA order in memory.
function Test-WhiteAt([byte[]]$b, [int]$i) {
    return ($b[$i + 3] -lt 8) -or ($b[$i + 2] -ge 248 -and $b[$i + 1] -ge 248 -and $b[$i] -ge 248)
}

# Bounding box of the artwork, measured rather than assumed so re-exported art
# with different padding still lands correctly. Only used to locate the
# rounded square — never to decide per-pixel transparency.
$minX = $W; $maxX = -1; $minY = $H; $maxY = -1
for ($y = 0; $y -lt $H; $y++) {
    $rowBase = $y * $stride
    for ($x = 0; $x -lt $W; $x++) {
        if (-not (Test-WhiteAt $buf ($rowBase + $x * 4))) {
            if ($x -lt $minX) { $minX = $x }
            if ($x -gt $maxX) { $maxX = $x }
            if ($y -lt $minY) { $minY = $y }
            if ($y -gt $maxY) { $maxY = $y }
        }
    }
}
$boxW = $maxX - $minX + 1
$boxH = $maxY - $minY + 1
Write-Host ("artwork bbox: ({0},{1}) {2}x{3}" -f $minX, $minY, $boxW, $boxH)

# Corner radius of the source art, in source pixels. Measured from the art:
# the top-left arc runs from roughly (bbox+192, bbox+2) to (bbox+1, bbox+212).
$srcRadius = 210.0

function New-RoundedPath([single]$x, [single]$y, [single]$w, [single]$h, [single]$r) {
    $p = New-Object System.Drawing.Drawing2D.GraphicsPath
    $d = $r * 2
    $p.AddArc($x, $y, $d, $d, 180, 90)
    $p.AddArc($x + $w - $d, $y, $d, $d, 270, 90)
    $p.AddArc($x + $w - $d, $y + $h - $d, $d, $d, 0, 90)
    $p.AddArc($x, $y + $h - $d, $d, $d, 90, 90)
    $p.CloseFigure()
    return $p
}

# Artwork cropped to its bounding box, with everything outside the rounded
# rectangle made transparent. Interior white is preserved untouched.
$cut = New-Object System.Drawing.Bitmap $boxW, $boxH, ([System.Drawing.Imaging.PixelFormat]::Format32bppArgb)
$gc = [System.Drawing.Graphics]::FromImage($cut)
$gc.Clear([System.Drawing.Color]::Transparent)
$gc.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::AntiAlias
$gc.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
$gc.PixelOffsetMode = [System.Drawing.Drawing2D.PixelOffsetMode]::HighQuality
$clipPath = New-RoundedPath 0 0 $boxW $boxH $srcRadius
$gc.SetClip($clipPath)
$gc.DrawImage($bmp,
    (New-Object System.Drawing.Rectangle 0, 0, $boxW, $boxH),
    $minX, $minY, $boxW, $boxH,
    [System.Drawing.GraphicsUnit]::Pixel)
$gc.Dispose()
$clipPath.Dispose()

function New-Canvas([int]$size) {
    $b = New-Object System.Drawing.Bitmap $size, $size, ([System.Drawing.Imaging.PixelFormat]::Format32bppArgb)
    $g = [System.Drawing.Graphics]::FromImage($b)
    $g.Clear([System.Drawing.Color]::Transparent)
    $g.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
    $g.PixelOffsetMode = [System.Drawing.Drawing2D.PixelOffsetMode]::HighQuality
    $g.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::AntiAlias
    return @($b, $g)
}

# --- 1. Full-bleed variant (iOS / macOS / Windows) -------------------------
$pair = New-Canvas 1024
$fullbleed = $pair[0]; $g = $pair[1]
$over = [int](1024 * 1.34)
$overOff = [int]((1024 - $over) / 2)
$g.DrawImage($cut, $overOff, $overOff, $over, $over)
$g.DrawImage($cut, 0, 0, 1024, 1024)
$g.Dispose()
$outFull = Join-Path $root 'assets\icon\icon_fullbleed.png'
$fullbleed.Save($outFull, [System.Drawing.Imaging.ImageFormat]::Png)
Write-Host "wrote $outFull"

# --- 2. Adaptive foreground (Android) --------------------------------------
# Art inset to 72% so its content sits inside the launcher's guaranteed-safe
# centre circle, while the rounded edge still overshoots the mask and leaves
# no seam against the background layer.
$pair2 = New-Canvas 1024
$fg = $pair2[0]; $g2 = $pair2[1]
$side = [int](1024 * 0.72)
$off = [int]((1024 - $side) / 2)
$g2.DrawImage($cut, $off, $off, $side, $side)
$g2.Dispose()
$outFg = Join-Path $root 'assets\icon\icon_foreground.png'
$fg.Save($outFg, [System.Drawing.Imaging.ImageFormat]::Png)
Write-Host "wrote $outFg"

# --- 3. Linux hicolor icons, from the full-bleed variant --------------------
foreach ($size in 48, 64, 128, 256, 512) {
    $dir = Join-Path $root "linux\packaging\icons\hicolor\${size}x${size}\apps"
    New-Item -ItemType Directory -Force $dir | Out-Null
    $pair3 = New-Canvas $size
    $small = $pair3[0]; $g3 = $pair3[1]
    $g3.DrawImage($fullbleed, 0, 0, $size, $size)
    $g3.Dispose()
    $small.Save((Join-Path $dir 'top.code953.nkgrabber.png'), [System.Drawing.Imaging.ImageFormat]::Png)
    $small.Dispose()
}
Write-Host 'wrote linux/packaging/icons/hicolor/*/apps/top.code953.nkgrabber.png'

# Average colour just inside the artwork's top edge — used for the adaptive
# background layer and the iOS alpha-flatten colour, so those flat fills match
# the art instead of the package's default white.
$rs = 0; $gs = 0; $bs = 0; $n = 0
$sampleY = $minY + 6
for ($x = [int]($minX + $boxW * 0.3); $x -lt [int]($minX + $boxW * 0.7); $x += 4) {
    $i = $sampleY * $stride + $x * 4
    $bs += $buf[$i]; $gs += $buf[$i + 1]; $rs += $buf[$i + 2]; $n++
}
Write-Host ("edge blue: #{0:X2}{1:X2}{2:X2}" -f [int]($rs / $n), [int]($gs / $n), [int]($bs / $n))

$bmp.Dispose(); $cut.Dispose(); $fullbleed.Dispose(); $fg.Dispose()
