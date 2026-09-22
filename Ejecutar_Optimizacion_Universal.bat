@echo off
title Optimizador Universal de Laptops - Windows 10 y 11
cd /d "%~dp0"

:: Auto-elevar a Administrador si no lo esta
net session >nul 2>&1
if %errorlevel% neq 0 (
    echo [!] Solicitando permisos de Administrador...
    powershell.exe -NoProfile -ExecutionPolicy Bypass -Command "Start-Process '%~f0' -Verb RunAs"
    exit /b
)

powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0scripts\Optimizador_Universal.ps1"
