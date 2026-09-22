@echo off
title Instalador de Accesos y Tareas - Optimiza Laptop
cd /d "%~dp0"

:: Auto-solicitar permisos de Administrador
net session >nul 2>&1
if %errorlevel% neq 0 (
    echo [!] Solicitando permisos de Administrador...
    powershell.exe -NoProfile -ExecutionPolicy Bypass -Command "Start-Process '%~f0' -Verb RunAs"
    exit /b
)

powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0Instalar_Accesos_Directos.ps1"
