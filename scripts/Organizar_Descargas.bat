@echo off
title Organizador Inteligente de Descargas
cd /d "%~dp0"
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0Organizar_Descargas.ps1"
exit
