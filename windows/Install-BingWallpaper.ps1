<#
.SYNOPSIS
    Registers the BingWallpaper Scheduled Task and runs it once.

.DESCRIPTION
    Creates a Scheduled Task named "BingWallpaper" that runs Set-BingWallpaper.ps1
    hidden (no window) at user logon and once daily. The task runs in the interactive
    desktop session so the wallpaper change takes effect. Re-running this script
    updates the existing task in place, then triggers an immediate run.

.EXAMPLE
    .\Install-BingWallpaper.ps1
#>
[CmdletBinding()]
param(
    [string] $TaskName = 'BingWallpaper',
    [datetime] $DailyAt = '9:00AM'
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$workerPath = Join-Path $PSScriptRoot 'Set-BingWallpaper.ps1'
if (-not (Test-Path -LiteralPath $workerPath)) {
    throw "Worker script not found at $workerPath"
}

$action = New-ScheduledTaskAction `
    -Execute 'powershell.exe' `
    -Argument "-NoProfile -WindowStyle Hidden -ExecutionPolicy Bypass -File `"$workerPath`""

$triggers = @(
    New-ScheduledTaskTrigger -AtLogOn
    New-ScheduledTaskTrigger -Daily -At $DailyAt
)

$principal = New-ScheduledTaskPrincipal `
    -UserId ([System.Security.Principal.WindowsIdentity]::GetCurrent().Name) `
    -LogonType Interactive `
    -RunLevel Limited

$settings = New-ScheduledTaskSettingsSet `
    -AllowStartIfOnBatteries `
    -DontStopIfGoingOnBatteries `
    -StartWhenAvailable

Register-ScheduledTask `
    -TaskName $TaskName `
    -Action $action `
    -Trigger $triggers `
    -Principal $principal `
    -Settings $settings `
    -Description 'Downloads the daily Bing wallpaper and sets it as the desktop background.' `
    -Force | Out-Null

Write-Host "Registered scheduled task '$TaskName' (triggers: at logon, daily at $($DailyAt.ToString('h:mmtt')))."

# Run once now so the wallpaper is set without waiting for the first trigger.
Start-ScheduledTask -TaskName $TaskName
Write-Host "Started '$TaskName' to set the wallpaper now."
