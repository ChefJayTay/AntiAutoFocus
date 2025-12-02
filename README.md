# Brio Anti-AutoFocus

This project contains PowerShell scripts to disable autofocus on Logitech Brio cameras and force a manual focus distance. This is achieved through two methods:
1.  **Registry Settings:** Modifying the driver registry keys to set the default focus mode.
2.  **Startup Script:** A scheduled task that re-applies the settings via WMI at every logon to persist the configuration.

## Prerequisites

-   Windows PowerShell 5.1 or later.
-   **Administrator privileges** are required to run the setup scripts (to modify registry and scheduled tasks).
-   Logitech Brio cameras connected.

## Files

-   `Set-BrioRegistrySettings.ps1`: Scans for connected Brio cameras (checking both `Camera` and `Image` device classes) and sets the `FocusMode` (Manual) and `Focus` (Distance) registry keys.
-   `Set-BrioManualFocus.ps1`: The script designed to run at startup. It uses WMI to enforce the focus settings.
-   `Install-BrioTask.ps1`: Registers a Windows Scheduled Task to run `Set-BrioManualFocus.ps1` automatically at logon.

## Installation Instructions

1.  **Open PowerShell as Administrator.**
2.  Navigate to the directory where you saved the files:
    ```powershell
    cd "C:\Path\To\BrioAntiAutoFocus"
    ```
3.  **Apply Registry Settings (One-time setup):**
    Run the registry script to set the initial configuration.
    ```powershell
    .\Set-BrioRegistrySettings.ps1
    ```
    *Note: This script will output the registry keys it modifies. If no Brio cameras are found, ensure they are connected.*

4.  **Install the Startup Task:**
    Run the installation script to create the Scheduled Task.
    ```powershell
    .\Install-BrioTask.ps1
    ```
    This will create a task named "BrioManualFocus" that runs `Set-BrioManualFocus.ps1` with highest privileges whenever a user logs on.

## Customization

To change the manual focus distance, edit the `$argsFocus` value in `Set-BrioManualFocus.ps1` and the `$Focus` value in `Set-BrioRegistrySettings.ps1`.
-   Current Value: `30` (approx. middle distance).

## Troubleshooting

-   **Script Execution Policy:** If you encounter errors about running scripts, you may need to set the execution policy:
    ```powershell
    Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope Process
    ```
-   **Task Not Running:** Check the Task Scheduler (run `taskschd.msc`) and look for "BrioManualFocus". Check the "History" tab for any errors.
