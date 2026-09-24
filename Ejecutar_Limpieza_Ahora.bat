@echo off
title Mantenimiento y Optimizacion del Sistema
cd /d "%~dp0"

:: 1. Comprobar si tiene permisos de Administrador
net session >nul 2>&1
if %errorlevel% neq 0 (
    echo.
    echo [*] Solicitando permisos de Administrador para mantenimiento completo...
    echo     (Acepta la ventana emergente de Windows para continuar)
    powershell -NoProfile -ExecutionPolicy Bypass -Command "Start-Process cmd.exe -ArgumentList '/c \"\"%~f0\"\"' -Verb RunAs"
    exit /b
)

:: 2. Ejecutar rutina de mantenimiento en PowerShell con ventana interactiva
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0Mantenimiento_Auto.ps1"

:: 3. Pausa de seguridad para que la ventana NUNCA se cierre sola
echo.
echo Presione una tecla para salir...
pause >nul
