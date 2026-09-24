@echo off
title Mantenimiento y Optimizacion del Sistema
cd /d "%~dp0"

:: 1. Comprobar si tiene permisos de Administrador y auto-elevar si es necesario
net session >nul 2>&1
if %errorlevel% neq 0 (
    echo.
    echo [*] Solicitando permisos de Administrador...
    powershell -NoProfile -ExecutionPolicy Bypass -Command "Start-Process cmd.exe -ArgumentList '/c \"\"%~f0\"\"' -Verb RunAs"
    exit /b
)

:: 2. Ejecutar rutina de mantenimiento (genera reporte en el Escritorio y se auto-cierra)
if exist "%~dp0scripts\Mantenimiento_Auto.ps1" (
    powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0scripts\Mantenimiento_Auto.ps1"
) else (
    powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0Mantenimiento_Auto.ps1"
)
exit
