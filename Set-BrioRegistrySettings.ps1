# Set-BrioRegistrySettings.ps1
# This script finds Logitech Brio cameras and sets the registry keys to force manual focus.
# Run this script as Administrator.

$ErrorActionPreference = "Stop"

Write-Host "Searching for Logitech Brio cameras..."
$brios = Get-PnpDevice -Class Camera -Status OK | Where-Object { $_.FriendlyName -like "*BRIO*" }

if (-not $brios) {
    Write-Warning "No Logitech Brio cameras found."
    exit
}

foreach ($brio in $brios) {
    Write-Host "Processing $($brio.FriendlyName) ($($brio.InstanceId))..."
    
    # Get Driver Key
    try {
        $driverKeyProp = Get-PnpDeviceProperty -InstanceId $brio.InstanceId -KeyName DEVPKEY_Device_Driver
        if ($driverKeyProp -and $driverKeyProp.Data) {
            $driverKeyPath = $driverKeyProp.Data
            # Registry path: HKLM\SYSTEM\CurrentControlSet\Control\Class\{GUID}\XXXX
            $regPath = "HKLM:\SYSTEM\CurrentControlSet\Control\Class\$driverKeyPath"
            
            Write-Host "  Registry Key: $regPath"
            
            if (Test-Path $regPath) {
                # Set FocusMode = 0 (Manual)
                Set-ItemProperty -Path $regPath -Name "FocusMode" -Value 0 -Type DWORD -Force
                Write-Host "  Set FocusMode to 0 (Manual)"
                
                # Set Focus = 30 (Manual Focus Distance)
                # User example was 1e (hex) = 30 (decimal)
                Set-ItemProperty -Path $regPath -Name "Focus" -Value 30 -Type DWORD -Force
                Write-Host "  Set Focus to 30"
            } else {
                Write-Warning "  Registry path not found: $regPath"
            }
        } else {
            Write-Warning "  Could not determine driver key for device."
        }
    } catch {
        Write-Error "  Error processing device: $_"
    }
}

Write-Host "Done."
