@echo off
title Instalador - Optimiza Laptop
cd /d "%~dp0"
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0Instalar_Accesos_Directos.ps1"
pause
