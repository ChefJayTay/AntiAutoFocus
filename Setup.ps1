# Setup.ps1
# Installs the Brio Anti-AutoFocus solution.
# 1. Applies the focus settings immediately.
# 2. Registers a Scheduled Task to re-apply settings at System Startup and User Logon.
# Run this script as Administrator.

$ErrorActionPreference = "Stop"
$SetupLog = "$env:TEMP\BrioSetupLog.txt"

function Log-Setup {
    param([string]$Message)
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $logEntry = "[$timestamp] $Message"
    Add-Content -Path $SetupLog -Value $logEntry
    Write-Host $logEntry
}

# Check for Administrator privileges
if (-not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Write-Warning "This script requires Administrator privileges. Please run as Administrator."
    exit
}

Log-Setup "Starting Setup..."

$scriptName = "Set-BrioManualFocus.ps1"
$scriptPath = Join-Path $PSScriptRoot $scriptName

if (-not (Test-Path $scriptPath)) {
    Log-Setup "Error: Script '$scriptName' not found in '$PSScriptRoot'."
    exit
}

Log-Setup "--- Step 1: Preparing Installation Directory ---"
$installDir = "C:\ProgramData\BrioAntiAutoFocus"
if (-not (Test-Path $installDir)) {
    New-Item -Path $installDir -ItemType Directory -Force | Out-Null
    Log-Setup "Created directory: $installDir"
}

$installedScriptPath = Join-Path $installDir $scriptName
Copy-Item -Path $scriptPath -Destination $installedScriptPath -Force
Log-Setup "Copied script to: $installedScriptPath"

# Also copy the DirectShow script
$dsScriptName = "Set-BrioFocusDirectShow.ps1"
$dsScriptPath = Join-Path $PSScriptRoot $dsScriptName
if (Test-Path $dsScriptPath) {
    $installedDsPath = Join-Path $installDir $dsScriptName
    Copy-Item -Path $dsScriptPath -Destination $installedDsPath -Force
    Log-Setup "Copied DirectShow script to: $installedDsPath"
}

Log-Setup "-------------------------------------------"

Log-Setup "--- Step 2: Applying settings immediately ---"
try {
    & $installedScriptPath
} catch {
    Log-Setup "Failed to run the focus script: $_"
}
Log-Setup "-------------------------------------------"

Log-Setup "--- Step 3: Installing Scheduled Task ---"
$taskName = "BrioManualFocus"
$description = "Disables autofocus on Logitech Brio cameras at Startup and Logon."

# Create Triggers: At Logon AND At Startup
$triggerLogon = New-ScheduledTaskTrigger -AtLogOn
$triggerStartup = New-ScheduledTaskTrigger -AtStartup

# Create Action: Run PowerShell script
# -WindowStyle Hidden to avoid popping up a window
$action = New-ScheduledTaskAction -Execute "powershell.exe" -Argument "-ExecutionPolicy Bypass -WindowStyle Hidden -File `"$installedScriptPath`""

# Create Principal: Run as SYSTEM to ensure permissions and independence from user accounts
$principal = New-ScheduledTaskPrincipal -UserId "SYSTEM" -RunLevel Highest

# Create Settings: Allow start if on batteries, don't stop if going on batteries
$settings = New-ScheduledTaskSettingsSet -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries -ExecutionTimeLimit (New-TimeSpan -Minutes 5)

# Register the task
Log-Setup "Registering Scheduled Task '$taskName'..."
try {
    Register-ScheduledTask -TaskName $taskName -Trigger @($triggerLogon, $triggerStartup) -Action $action -Principal $principal -Settings $settings -Description $description -Force
    Log-Setup "Task registered successfully."
    Log-Setup "The script will run automatically at system startup and user logon."
    Log-Setup "Logs are written to C:\ProgramData\BrioAntiAutoFocus\BrioFocusLog.txt (or %TEMP% if run manually)."
} catch {
    Log-Setup "Failed to register task: $_"
}
Log-Setup "-------------------------------------------"
Log-Setup "Setup Complete."
