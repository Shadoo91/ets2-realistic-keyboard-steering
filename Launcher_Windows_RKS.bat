@echo off
title RKS Profile Installer Launcher
cd /d "%~dp0"

if not exist "rks_injector_core.ps1" (
    echo [ERROR] Core file 'rks_injector_core.ps1' not found in this directory!
    pause
    exit
)

powershell -NoProfile -ExecutionPolicy Bypass -Command "Start-Process powershell -ArgumentList '-NoProfile -ExecutionPolicy Bypass -File \"""%~dp0rks_injector_core.ps1\"""' -Verb RunAs"
exit
