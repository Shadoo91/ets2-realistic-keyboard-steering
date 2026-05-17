@echo off
:: ==============================================================================
:: ETS2 Realistic Keyboard Steering (RKS) - Windows Launcher
:: Developer: Shadoo91
:: ==============================================================================

TITLE ETS2 Realistic-Keyboard-Steering (RKS) Launcher
SET "SCRIPT_DIR=%~dp0"

:: Ensure the script has administrator privileges (required for Documents/Steam access)
net session >nul 2>&1
IF %errorLevel% == 0 (
    GOTO :run_injector
) ELSE (
    GOTO :get_admin
)

:get_admin
    echo =====================================================================
    echo   RKS LAUNCHER: Administrator privileges required...
    echo =====================================================================
    echo.
    echo Please allow administrator execution in the UAC prompt.
    echo.
    powershell -Command "Start-Process -FilePath '%0' -Verb RunAs"
    EXIT /B

:run_injector
    :: Launches the PowerShell Core in the same directory
    powershell -NoProfile -ExecutionPolicy Bypass -File "%SCRIPT_DIR%rks_injector_core.ps1"
    EXIT /B
