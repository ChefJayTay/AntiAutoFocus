# Uninstall.ps1
# Removes the Brio Anti-AutoFocus solution.
# 1. Unregisters the Scheduled Task.
# 2. Removes the installation directory and logs.
# Run this script as Administrator.

$ErrorActionPreference = "Stop"

# Check for Administrator privileges
if (-not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Write-Warning "This script requires Administrator privileges. Please run as Administrator."
    exit
}

$taskName = "BrioManualFocus"
$installDir = "C:\ProgramData\BrioAntiAutoFocus"

Write-Host "--- Uninstalling Brio Anti-AutoFocus ---"

# 1. Remove Scheduled Task
Write-Host "Removing Scheduled Task '$taskName'..."
try {
    Unregister-ScheduledTask -TaskName $taskName -Confirm:$false -ErrorAction Stop
    Write-Host "  Task removed successfully."
} catch {
    Write-Warning "  Task not found or could not be removed: $_"
}

# 2. Remove Installation Directory
if (Test-Path $installDir) {
    Write-Host "Removing installation directory '$installDir'..."
    try {
        Remove-Item -Path $installDir -Recurse -Force -ErrorAction Stop
        Write-Host "  Directory removed successfully."
    } catch {
        Write-Warning "  Could not remove directory: $_"
    }
} else {
    Write-Host "  Installation directory not found."
}

Write-Host "----------------------------------------"
Write-Host "Uninstallation Complete."
Write-Host "Note: Registry settings applied to the camera driver have not been reverted."
Write-Host "You can use Logitech G Hub or LogiTune to re-enable Autofocus if desired."
