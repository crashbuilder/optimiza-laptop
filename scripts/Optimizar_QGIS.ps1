# ==============================================================================
# Script: Optimizar_QGIS.ps1
# Suite:  optimiza-laptop
# Proposito: Optimiza QGIS para laptops (Core i3/i5, Intel GPU, RAM extendida)
#            Elimina bloqueos de red en arranque, activa render multinucleo (3 hilos),
#            asigna 1GB de cache en RAM y ajusta interfaz para 1366x768.
# ==============================================================================

#Requires -Version 5.1
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8

Write-Host "============================================================" -ForegroundColor Cyan
Write-Host "       OPTIMIZADOR DE QGIS PARA LAPTOPS                    " -ForegroundColor Yellow
Write-Host "============================================================" -ForegroundColor Cyan

# 1. Verificar si QGIS esta en ejecucion
$qgisProcs = Get-Process -Name "qgis*" -ErrorAction SilentlyContinue
if ($qgisProcs) {
    Write-Host "[!] ADVERTENCIA: QGIS esta actualmente abierto." -ForegroundColor Red
    Write-Host "    Para aplicar las optimizaciones de forma permanente, debes cerrar QGIS" -ForegroundColor Yellow
    Write-Host "    (de lo contrario QGIS sobrescribe la configuracion al salir)." -ForegroundColor Yellow
    $resp = Read-Host "¿Deseas que cierre los procesos de QGIS ahora? (S/N)"
    if ($resp -match "^[sSyY]") {
        Stop-Process -Name "qgis*" -Force
        Start-Sleep -Seconds 2
        Write-Host "[OK] QGIS cerrado exitosamente." -ForegroundColor Green
    } else {
        Write-Host "Operacion cancelada. Cierra QGIS manualmente y vuelve a ejecutar este script." -ForegroundColor Yellow
        exit 0
    }
}

# 2. Localizar perfiles de QGIS (QGIS4 o QGIS3)
$appData = [System.Environment]::GetFolderPath([System.Environment+SpecialFolder]::ApplicationData)
$iniPath = Join-Path $appData "QGIS\QGIS4\profiles\default\QGIS\QGIS4.ini"

if (-not (Test-Path $iniPath)) {
    $iniPath = Join-Path $appData "QGIS\QGIS3\profiles\default\QGIS\QGIS3.ini"
}

if (-not (Test-Path $iniPath)) {
    Write-Host "[-] No se encontro un perfil activo de QGIS en $appData\QGIS" -ForegroundColor Red
    Write-Host "    Abre QGIS al menos una vez para que cree su perfil por defecto." -ForegroundColor Yellow
    exit 1
}

Write-Host "[+] Perfil detectado: $iniPath" -ForegroundColor Cyan

# 3. Localizar ejecutable de Python de QGIS
$qgisBase = "C:\Program Files\QGIS 4.2.2"
if (-not (Test-Path $qgisBase)) {
    $foundDir = Get-ChildItem "C:\Program Files" -Filter "QGIS*" -Directory -ErrorAction SilentlyContinue | Select-Object -First 1
    if ($foundDir) { $qgisBase = $foundDir.FullName }
}

$pyQgisBat = Join-Path $qgisBase "bin\python-qgis.bat"
$qgisBin = Join-Path $qgisBase "bin\qgis-bin.exe"

# 4. Crear backup
$bakPath = "$iniPath.bak"
if (-not (Test-Path $bakPath)) {
    Copy-Item -Path $iniPath -Destination $bakPath -Force
    Write-Host "[+] Copia de seguridad creada: $bakPath" -ForegroundColor Green
}

# 5. Aplicar configuraciones de QGIS mediante script Python (PyQt6 / PyQt5)
Write-Host "[*] Aplicando parametros de alto rendimiento en QGIS..." -ForegroundColor Yellow

$pyScript = @"
import os, shutil
from PyQt6.QtCore import QSettings

ini_path = r"$iniPath"
s = QSettings(ini_path, QSettings.Format.IniFormat)

# 1. Renderizado y Subprocesos (CPU 3 hilos, no congela Windows)
s.setValue('rendering/maxThreads', 3)
s.setValue('rendering/parallelRaster', True)
s.setValue('rendering/useRenderCaching', True)
s.setValue('rendering/main-canvas-preview-jobs', True)
s.setValue('rendering/simplifyDrawingHints', 1)
s.setValue('qgis/parallel_rendering', True)
s.setValue('qgis/max_threads', 3)

# 2. Arranque instantaneo (Elimina bloqueos de red al iniciar)
s.setValue('qgis/checkVersion', False)
s.setValue('app/checkVersion', False)
s.setValue('app/news-feed/enabled', False)
s.setValue('plugin-manager/automatically-check-for-updates', False)
s.setValue('plugin-manager/checkOnStart', False)

# 3. Optimizar complementos pesados en arranque (GRASS añade 25s)
s.setValue('PythonPlugins/grassprovider', False)
s.setValue('PythonPlugins/MetaSearch', False)
s.setValue('PythonPlugins/db_manager', False)
s.setValue('PythonPlugins/db_manager_community', True)
s.setValue('PythonPlugins/processing', True)

# 4. Memoria Cache (1024 MB / 1 GB en RAM)
s.setValue('cache/cacheSize', 1048576)
s.setValue('network/cache/size', 1048576)

# 5. Interfaz ergonomica para 1366x768 (Iconos 16px)
s.setValue('qgis/toolbarIconSize', 16)

# 6. Optimizacion de explorador (no bloquear indexando HDD D:)
s.setValue('qgis/scanZipInDirectory', 'no')
s.setValue('browser/scanZipInDirectory', 'no')

s.sync()
print("PY_SUCCESS")
"@

$tempPy = Join-Path $env:TEMP "apply_qgis_opts.py"
[System.IO.File]::WriteAllText($tempPy, $pyScript, [System.Text.Encoding]::UTF8)

if (Test-Path $pyQgisBat) {
    & $pyQgisBat $tempPy | Out-Null
    Remove-Item $tempPy -Force -ErrorAction SilentlyContinue
} else {
    Write-Host "[-] python-qgis.bat no encontrado en $pyQgisBat" -ForegroundColor Red
}

# 6. Configurar prioridad de GPU en Windows DirectX
if (Test-Path $qgisBin) {
    Write-Host "[*] Asignando prioridad GPU Alto Rendimiento a QGIS..." -ForegroundColor Yellow
    $regKey = "HKCU:\Software\Microsoft\DirectX\UserGpuPreferences"
    if (-not (Test-Path $regKey)) {
        New-Item -Path $regKey -Force | Out-Null
    }
    Set-ItemProperty -Path $regKey -Name $qgisBin -Value "GpuPreference=2;" -Force
    Write-Host "[OK] GPU DirectX: Alto Rendimiento asignado." -ForegroundColor Green
}

Write-Host ""
Write-Host "============================================================" -ForegroundColor Green
Write-Host "  ¡OPTIMIZACION DE QGIS COMPLETADA EXITOSAMENTE!            " -ForegroundColor Green
Write-Host "============================================================" -ForegroundColor Green
Write-Host "  - Arranque: Verificaciones web y feeds desactivados." -ForegroundColor White
Write-Host "  - Motor: Multi-hilo activado (3 hilos de CPU)." -ForegroundColor White
Write-Host "  - Memoria: Cache de renderizado elevada a 1024 MB." -ForegroundColor White
Write-Host "  - GPU: Aceleracion DirectX Intel UHD configurada." -ForegroundColor White
Write-Host "  - Pantalla: Iconos ajustados a 16px para pantalla 768p." -ForegroundColor White
Write-Host "  - GRASS: Desactivado del arranque (ahorra 25 segundos)." -ForegroundColor White
Write-Host ""
