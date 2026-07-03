<#
.SYNOPSIS
    Downloads the daily Bing wallpaper and sets it as the Windows desktop background.

.DESCRIPTION
    Stateless worker script intended to be run by a Scheduled Task (at logon and daily).
    It queries the Bing "HPImageArchive" API for today's image, downloads the UHD variant
    (falling back to 1920x1080), caches it under Pictures\Bing, and applies it via the
    Win32 SystemParametersInfo(SPI_SETDESKWALLPAPER) API. If the image is already the
    active wallpaper, it does nothing.

    This is the Windows port of the macOS BingWallpaper menu-bar app.

.PARAMETER Market
    Bing market/locale (e.g. en-US, da-DK). Defaults to the machine's current culture.

.PARAMETER Destination
    Directory to store downloaded images. Defaults to <Pictures>\Bing.

.EXAMPLE
    .\Set-BingWallpaper.ps1 -Verbose
#>
[CmdletBinding()]
param(
    [string] $Market = (Get-Culture).Name,
    [string] $Destination = (Join-Path ([Environment]::GetFolderPath('MyPictures')) 'Bing')
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$LogFile = Join-Path ([Environment]::GetFolderPath('MyDocuments')) 'BingWallpaper.log'

function Write-Log {
    param(
        [string] $Message,
        [ValidateSet('INFO', 'ERROR')] [string] $Level = 'INFO'
    )
    $timestamp = (Get-Date).ToString('yyyy-MM-dd HH:mm:ss')
    $line = "[$timestamp] [$Level] $Message"
    try { Add-Content -Path $LogFile -Value $line -Encoding UTF8 } catch { }
    if ($Level -eq 'ERROR') { Write-Verbose $line } else { Write-Verbose $line }
}

# P/Invoke wrapper around SystemParametersInfo for setting the desktop wallpaper.
if (-not ('BingWallpaper.NativeMethods' -as [type])) {
    Add-Type -Namespace 'BingWallpaper' -Name 'NativeMethods' -MemberDefinition @'
[System.Runtime.InteropServices.DllImport("user32.dll", CharSet = System.Runtime.InteropServices.CharSet.Auto, SetLastError = true)]
public static extern int SystemParametersInfo(int uAction, int uParam, string lpvParam, int fuWinIni);
'@
}

function Set-Wallpaper {
    param([Parameter(Mandatory)] [string] $Path)

    $SPI_SETDESKWALLPAPER = 0x0014
    $SPIF_UPDATEINIFILE   = 0x01
    $SPIF_SENDWININICHANGE = 0x02

    $result = [BingWallpaper.NativeMethods]::SystemParametersInfo(
        $SPI_SETDESKWALLPAPER, 0, $Path, ($SPIF_UPDATEINIFILE -bor $SPIF_SENDWININICHANGE))

    if ($result -eq 0) {
        throw "SystemParametersInfo failed to set wallpaper (path: $Path)."
    }
}

function Get-CurrentWallpaper {
    try {
        return (Get-ItemProperty -Path 'HKCU:\Control Panel\Desktop' -Name 'WallPaper' -ErrorAction Stop).WallPaper
    } catch {
        return $null
    }
}

try {
    Write-Log "Started Bing Wallpaper (market: $Market)."

    $apiUrl = "https://www.bing.com/HPImageArchive.aspx?format=js&idx=0&n=1&mkmt=$Market"
    $response = Invoke-RestMethod -Uri $apiUrl -UseBasicParsing

    if (-not $response.images -or $response.images.Count -eq 0) {
        throw "Bing API returned no images."
    }
    $image = $response.images[0]

    # Filename derived from urlbase (strip leading "/th?id=", 7 chars) -> "OHR.Name".
    $fileName = $image.urlbase.Substring(7)
    $destFile = Join-Path $Destination "$fileName.jpg"

    if (-not (Test-Path -LiteralPath $Destination)) {
        New-Item -ItemType Directory -Path $Destination -Force | Out-Null
    }

    if (Test-Path -LiteralPath $destFile) {
        Write-Log "Image already cached: $destFile"
    } else {
        $uhdUrl = "https://www.bing.com" + ($image.url -replace '_1920x1080', '_UHD')
        $stdUrl = "https://www.bing.com" + $image.url
        try {
            Write-Log "Downloading UHD image from $uhdUrl"
            Invoke-WebRequest -Uri $uhdUrl -OutFile $destFile -UseBasicParsing
        } catch {
            Write-Log "UHD download failed ($($_.Exception.Message)); falling back to 1920x1080." -Level 'ERROR'
            Invoke-WebRequest -Uri $stdUrl -OutFile $destFile -UseBasicParsing
        }
        Write-Log "Saved image to $destFile"
    }

    $current = Get-CurrentWallpaper
    if ($current -eq $destFile) {
        Write-Log "Wallpaper already set to $destFile; nothing to do."
    } else {
        Set-Wallpaper -Path $destFile
        Write-Log "Wallpaper set to $destFile ($($image.title))."
    }
} catch {
    Write-Log "Run failed: $($_.Exception.Message)" -Level 'ERROR'
    exit 1
}
