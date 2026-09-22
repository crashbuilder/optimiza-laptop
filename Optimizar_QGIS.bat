@echo off
title Optimizar QGIS
cd /d "%~dp0"
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0scripts\Optimizar_QGIS.ps1"
pause
