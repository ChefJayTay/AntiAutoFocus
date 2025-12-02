# Set-BrioManualFocus.ps1
# Startup script to re-apply UVC settings via WMI to disable autofocus on Logitech Brio cameras.

$ErrorActionPreference = "SilentlyContinue"

$brios = Get-PnpDevice -Class Camera | Where-Object { $_.FriendlyName -like "*BRIO*" }

if ($brios) {
    foreach ($brio in $brios) {
        try {
            # Construct the InstanceName for WMI
            # The user provided format: InstanceId with backslashes escaped + "_0"
            $instanceName = $brio.InstanceId.replace("\","\\") + "_0"
            
            # Set FocusMode to 0 (Manual)
            $argsFocusMode = @{
                InstanceName = $instanceName
                PropertyName = "FocusMode"
                PropertyValue = 0
            }
            Set-CimInstance -Namespace root\wmi -ClassName WmiSetDeviceProperty -Property $argsFocusMode
            
            # Set Focus to 30
            $argsFocus = @{
                InstanceName = $instanceName
                PropertyName = "Focus"
                PropertyValue = 30
            }
            Set-CimInstance -Namespace root\wmi -ClassName WmiSetDeviceProperty -Property $argsFocus
            
        } catch {
            # Suppress errors during startup execution
        }
    }
}
