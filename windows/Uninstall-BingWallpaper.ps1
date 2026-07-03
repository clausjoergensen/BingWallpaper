<#
.SYNOPSIS
    Removes the BingWallpaper Scheduled Task.

.DESCRIPTION
    Unregisters the "BingWallpaper" Scheduled Task. Downloaded images and the log file
    are left in place (they are user data, not application artifacts).

.EXAMPLE
    .\Uninstall-BingWallpaper.ps1
#>
[CmdletBinding()]
param(
    [string] $TaskName = 'BingWallpaper'
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

if (Get-ScheduledTask -TaskName $TaskName -ErrorAction SilentlyContinue) {
    Unregister-ScheduledTask -TaskName $TaskName -Confirm:$false
    Write-Host "Removed scheduled task '$TaskName'."
} else {
    Write-Host "Scheduled task '$TaskName' is not registered; nothing to do."
}
