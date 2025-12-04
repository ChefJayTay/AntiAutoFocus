# Set-BrioManualFocus.ps1
# Startup script to re-apply UVC settings via Registry to disable autofocus on Logitech Brio cameras.

$ErrorActionPreference = "Continue"
$LogFile = "C:\ProgramData\BrioAntiAutoFocus\BrioFocusLog.txt"
if (-not (Test-Path "C:\ProgramData\BrioAntiAutoFocus")) {
    $LogFile = "$env:TEMP\BrioFocusLog.txt"
}

function Log-Message {
    param([string]$Message)
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $logEntry = "[$timestamp] $Message"
    Add-Content -Path $LogFile -Value $logEntry
    Write-Host $logEntry
}

Log-Message "Starting Brio Manual Focus script..."

$brios = @(Get-PnpDevice -Class Camera -ErrorAction SilentlyContinue; Get-PnpDevice -Class Image -ErrorAction SilentlyContinue) | Where-Object { $_.FriendlyName -like "*BRIO*" }

if ($brios) {
    foreach ($brio in $brios) {
        Log-Message "Processing $($brio.FriendlyName) ($($brio.InstanceId))..."
        try {
            # Set FocusMode to 0 (Manual) and Focus to 0 (Infinity)
            # Using the registry method as it is more reliable than WMI for this device.
            
            $driverKeyProp = Get-PnpDeviceProperty -InstanceId $brio.InstanceId -KeyName DEVPKEY_Device_Driver
            if ($driverKeyProp -and $driverKeyProp.Data) {
                $driverKeyPath = $driverKeyProp.Data
                $regPath = "HKLM:\SYSTEM\CurrentControlSet\Control\Class\$driverKeyPath"
                if (Test-Path $regPath) {
                     # Apply Registry Settings
                     # We set multiple keys to ensure compatibility across different driver versions.
                     # - FocusMode: Standard UVC (0 = Manual)
                     # - LVFocusMode: Logitech Specific (2 = Manual)
                     # - AutoFocus/FocusAuto: Common variations (0 = Off)
                     # - Focus: The manual focus distance (0 = Infinity)
                     
                     Set-ItemProperty -Path $regPath -Name "FocusMode" -Value 0 -Type DWORD -Force -ErrorAction SilentlyContinue
                     Set-ItemProperty -Path $regPath -Name "LVFocusMode" -Value 2 -Type DWORD -Force -ErrorAction SilentlyContinue
                     Set-ItemProperty -Path $regPath -Name "AutoFocus" -Value 0 -Type DWORD -Force -ErrorAction SilentlyContinue
                     Set-ItemProperty -Path $regPath -Name "FocusAuto" -Value 0 -Type DWORD -Force -ErrorAction SilentlyContinue
                     Set-ItemProperty -Path $regPath -Name "Focus" -Value 0 -Type DWORD -Force -ErrorAction SilentlyContinue
                     
                     Log-Message "  Applied registry settings to $regPath"
                     
                     # Also apply to a 'Settings' subkey
                     $settingsPath = "$regPath\Settings"
                     if (-not (Test-Path $settingsPath)) {
                        New-Item -Path $settingsPath -Force | Out-Null
                     }
                     Set-ItemProperty -Path $settingsPath -Name "FocusMode" -Value 0 -Type DWORD -Force -ErrorAction SilentlyContinue
                     Set-ItemProperty -Path $settingsPath -Name "LVFocusMode" -Value 2 -Type DWORD -Force -ErrorAction SilentlyContinue
                     Set-ItemProperty -Path $settingsPath -Name "AutoFocus" -Value 0 -Type DWORD -Force -ErrorAction SilentlyContinue
                     Set-ItemProperty -Path $settingsPath -Name "Focus" -Value 0 -Type DWORD -Force -ErrorAction SilentlyContinue
                     Log-Message "  Applied registry settings to $settingsPath"
                     
                     # Try to run the DirectShow script if it exists
                     $dsScript = Join-Path $PSScriptRoot "Set-BrioFocusDirectShow.ps1"
                     if (Test-Path $dsScript) {
                         Log-Message "  Running DirectShow script..."
                         Start-Process powershell -ArgumentList "-Sta -NoProfile -ExecutionPolicy Bypass -File `"$dsScript`"" -Wait -NoNewWindow
                         Log-Message "  DirectShow script finished."
                     }

                     # Restart the device to force the driver to read the new registry settings
                     Log-Message "  Restarting device to enforce settings..."
                     Disable-PnpDevice -InstanceId $brio.InstanceId -Confirm:$false -ErrorAction Stop
                     Start-Sleep -Seconds 2
                     Enable-PnpDevice -InstanceId $brio.InstanceId -Confirm:$false -ErrorAction Stop
                     Log-Message "  Device restarted successfully."
                } else {
                    Log-Message "  Registry path not found: $regPath"
                }
            } else {
                Log-Message "  Could not determine driver key."
            }
        } catch {
            Log-Message "  Error: $_"
        }
    }
} else {
    Log-Message "No Brio cameras found."
}
Log-Message "Script finished."
