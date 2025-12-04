# Brio Anti-AutoFocus

This project provides a robust solution to permanently disable autofocus on Logitech Brio cameras and force them to Manual Focus (Infinity). It solves the issue where the camera resets to Autofocus after a reboot or device restart.

## Features

-   **Dual Enforcement:** Uses both Windows Registry settings (`LVFocusMode`, `FocusMode`) and DirectShow commands to force the camera into Manual Focus mode.
-   **Persistence:** Installs a Windows Scheduled Task that runs at **System Startup** and **User Logon** to ensure settings are always applied.
-   **Device Reset:** Automatically restarts the camera driver to ensure settings take effect immediately.
-   **System-Wide:** Installs to `C:\ProgramData` and runs as the `SYSTEM` account, making it independent of specific user sessions.

## Files

-   `Setup.ps1`: The main installer. Run this to set everything up.
-   `Uninstall.ps1`: Removes the scheduled task and installed files.
-   `Set-BrioManualFocus.ps1`: The core logic script.
-   `Set-BrioFocusDirectShow.ps1`: A helper script that uses DirectShow (C#) to send focus commands.

## Installation

1.  **Download** the project files to a folder on your computer.
2.  **Open PowerShell as Administrator.**
3.  Navigate to the folder:
    ```powershell
    cd "C:\Path\To\BrioAntiAutoFocus"
    ```
4.  **Run the Setup Script:**
    ```powershell
    .\Setup.ps1
    ```
    This will:
    *   Create `C:\ProgramData\BrioAntiAutoFocus` and copy the scripts there.
    *   Apply the manual focus settings immediately (your camera will restart briefly).
    *   Register the "BrioManualFocus" Scheduled Task.

## Uninstallation

To remove the solution:
1.  Open PowerShell as Administrator.
2.  Run:
    ```powershell
    .\Uninstall.ps1
    ```

## Verification & Troubleshooting

-   **Logs:** The script logs its activity to:
    ```powershell
    Get-Content "C:\ProgramData\BrioAntiAutoFocus\BrioFocusLog.txt"
    ```
-   **Task Scheduler:** You can find the task named "BrioManualFocus" in the Windows Task Scheduler.
-   **Manual Run:** You can manually trigger the installed script at any time by running:
    ```powershell
    & "C:\ProgramData\BrioAntiAutoFocus\Set-BrioManualFocus.ps1"
    ```

## Customization

To change the manual focus distance (default is 0/Infinity), edit the `$Focus` value in `Set-BrioManualFocus.ps1` before running Setup, or edit the installed file at `C:\ProgramData\BrioAntiAutoFocus\Set-BrioManualFocus.ps1`.
