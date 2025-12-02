# Install-BrioTask.ps1
# Registers a Scheduled Task to run Set-BrioManualFocus.ps1 at logon.
# Run this script as Administrator.

$ErrorActionPreference = "Stop"

if (-not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Write-Warning "This script requires Administrator privileges. Please run as Administrator."
    exit
}

$scriptName = "Set-BrioManualFocus.ps1"
$scriptPath = Join-Path $PSScriptRoot $scriptName

if (-not (Test-Path $scriptPath)) {
    Write-Error "Script '$scriptName' not found in '$PSScriptRoot'."
    exit
}

$taskName = "BrioManualFocus"
$description = "Disables autofocus on Logitech Brio cameras at logon."

# Create Trigger: At Logon
$trigger = New-ScheduledTaskTrigger -AtLogOn

# Create Action: Run PowerShell script
# We use -WindowStyle Hidden to avoid popping up a window
$action = New-ScheduledTaskAction -Execute "powershell.exe" -Argument "-ExecutionPolicy Bypass -WindowStyle Hidden -File `"$scriptPath`""

# Create Principal: Run with highest privileges (SYSTEM or Admin user)
# The user requested "At logon", which usually implies the user's session.
# However, modifying hardware settings often requires elevation.
# We will use the current user but with RunLevel Highest.
$principal = New-ScheduledTaskPrincipal -GroupId "BUILTIN\Administrators" -RunLevel Highest

# Register the task
Write-Host "Registering Scheduled Task '$taskName'..."
try {
    Register-ScheduledTask -TaskName $taskName -Trigger $trigger -Action $action -Principal $principal -Description $description -Force
    Write-Host "Task registered successfully."
    Write-Host "The script will run at the next logon."
} catch {
    Write-Error "Failed to register task: $_"
    Write-Host "Ensure you are running this script as Administrator."
}
