# BingWallpaper for Windows

A no-UI Windows port of the macOS BingWallpaper app. It downloads the daily Bing
homepage image and sets it as your desktop background. Instead of a persistent tray
process, it runs as a **Scheduled Task** that fires at logon and once daily, does its
work, and exits.

## Install

Open PowerShell and run:

```powershell
.\Install-BingWallpaper.ps1
```

This registers a scheduled task named `BingWallpaper` (triggers: at logon and daily at
9:00 AM) and runs it once immediately so your wallpaper updates right away.

You do **not** need to change your machine's execution policy — the task launches the
worker with `-ExecutionPolicy Bypass`. If your policy blocks running the installer
itself, launch it once with:

```powershell
powershell -ExecutionPolicy Bypass -File .\Install-BingWallpaper.ps1
```

### Options

- `-DailyAt` — change the daily run time, e.g. `.\Install-BingWallpaper.ps1 -DailyAt 7:30AM`.

## How it works

- Queries `https://www.bing.com/HPImageArchive.aspx` for today's image, using your
  system locale as the market.
- Downloads the **UHD** variant (falls back to 1920x1080 if UHD is unavailable).
- Caches images in `%USERPROFILE%\Pictures\Bing\`. Already-downloaded images are reused.
- Sets the wallpaper via the Win32 `SystemParametersInfo(SPI_SETDESKWALLPAPER)` API.
  If today's image is already the active wallpaper, it does nothing.

You can also run the worker directly at any time:

```powershell
.\Set-BingWallpaper.ps1 -Verbose
```

## Files & locations

- **Images:** `%USERPROFILE%\Pictures\Bing\`
- **Log:** `%USERPROFILE%\Documents\BingWallpaper.log`

## Uninstall

```powershell
.\Uninstall-BingWallpaper.ps1
```

This removes the scheduled task. Downloaded images and the log file are left in place.
