# =====================================================================
# SCRIPT DE MANTENIMIENTO Y OPTIMIZACION PERIODICA (SUPERIOR A CCLEANER)
# =====================================================================

$logDir = $PSScriptRoot
if (-not $logDir) { $logDir = Split-Path -Parent $MyInvocation.MyCommand.Definition }
if (-not (Test-Path $logDir)) { New-Item -Path $logDir -ItemType Directory -Force | Out-Null }
$logFile = "$logDir\Historial_Limpiezas.log"


function Escribir-Log($texto) {
    $ts = (Get-Date).ToString("yyyy-MM-dd HH:mm:ss")
    Add-Content -Path $logFile -Value "[$ts] $texto"
}

Escribir-Log "=== INICIO DE MANTENIMIENTO AUTOMATICO ==="
$archivosEliminados = 0
# 0. CREAR PUNTO DE RESTAURACION SEMANAL REAL ANTES DE LA LIMPIEZA
try {
    $fechaHoy = (Get-Date).ToString("yyyy-MM-dd")
    Checkpoint-Computer -Description "Auto_Mantenimiento_$fechaHoy" -RestorePointType "MODIFY_SETTINGS" -ErrorAction SilentlyContinue
    Escribir-Log "Punto de restauracion semanal creado: Auto_Mantenimiento_$fechaHoy"
} catch {
    Escribir-Log "Aviso en punto de restauracion: $($_.Exception.Message)"
}

# 1. CARPETAS TEMPORALES
$carpetas = @(
    $env:TEMP,
    "C:\Windows\Temp",
    "C:\Windows\SoftwareDistribution\Download",
    "$env:LOCALAPPDATA\CrashDumps",
    "C:\ProgramData\Microsoft\Windows\WER\ReportArchive",
    "C:\ProgramData\Microsoft\Windows\WER\ReportQueue"
)

foreach ($dir in $carpetas) {
    if (Test-Path $dir) {
        try {
            $items = Get-ChildItem -Path $dir -Force -ErrorAction SilentlyContinue
            foreach ($item in $items) {
                try {
                    Remove-Item -Path $item.FullName -Recurse -Force -ErrorAction SilentlyContinue
                    $archivosEliminados++
                } catch {}
            }
        } catch {}
    }
}

# 2. CACHE DE MICROSOFT EDGE (SIN TOCAR SESIONES, HISTORIAL NI PASSWORDS)
$edgeCaches = @(
    "$env:LOCALAPPDATA\Microsoft\Edge\User Data\Default\Cache\Cache_Data",
    "$env:LOCALAPPDATA\Microsoft\Edge\User Data\Default\Code Cache",
    "$env:LOCALAPPDATA\Microsoft\Edge\User Data\Default\GPUCache",
    "$env:LOCALAPPDATA\Microsoft\Edge\User Data\ShaderCache"
)

foreach ($ec in $edgeCaches) {
    if (Test-Path $ec) {
        try {
            $items = Get-ChildItem -Path $ec -Force -ErrorAction SilentlyContinue
            foreach ($item in $items) {
                try {
                    Remove-Item -Path $item.FullName -Recurse -Force -ErrorAction SilentlyContinue
                    $archivosEliminados++
                } catch {}
            }
        } catch {}
    }
}

# 3. VACIAR PAPELERA DE RECICLAJE
try {
    Clear-RecycleBin -Force -Confirm:$false -ErrorAction SilentlyContinue
    Escribir-Log "Papelera de reciclaje vaciada."
} catch {}

# 4. PURGAR CACHE DNS (OPTIMIZAR RED)
try {
    Clear-DnsClientCache -ErrorAction SilentlyContinue
    Escribir-Log "Cache DNS purgada con exito."
} catch {}

# 5. TRIM AUTOMATICO SSD
try {
    Optimize-Volume -DriveLetter C -ReTrim -ErrorAction SilentlyContinue
    Escribir-Log "TRIM ejecutado en SSD C:."
} catch {}

# 6. OPTIMIZACION Y ACELERACION DE BUSQUEDA EN WINDOWS (BUSQUEDA INSTANTANEA SIN BING)
try {
    # Politicas a nivel de maquina (HKLM)
    & reg.exe add "HKLM\SOFTWARE\Policies\Microsoft\Windows\Windows Search" /v "DisableWebSearch" /t REG_DWORD /d 1 /f | Out-Null
    & reg.exe add "HKLM\SOFTWARE\Policies\Microsoft\Windows\Windows Search" /v "ConnectedSearchUseWeb" /t REG_DWORD /d 0 /f | Out-Null
    & reg.exe add "HKLM\SOFTWARE\Policies\Microsoft\Windows\Windows Search" /v "AllowCloudSearch" /t REG_DWORD /d 0 /f | Out-Null
    & reg.exe add "HKLM\SOFTWARE\Policies\Microsoft\Windows\Windows Search" /v "AllowCortana" /t REG_DWORD /d 0 /f | Out-Null
    & reg.exe add "HKLM\SOFTWARE\Policies\Microsoft\Windows\Windows Search" /v "DisableSearchBoxSuggestions" /t REG_DWORD /d 1 /f | Out-Null
    & reg.exe add "HKLM\SOFTWARE\Policies\Microsoft\Windows\Windows Search" /v "EnableDynamicContentInWSB" /t REG_DWORD /d 0 /f | Out-Null

    & reg.exe add "HKLM\SOFTWARE\Policies\Microsoft\Windows\Explorer" /v "DisableSearchBoxSuggestions" /t REG_DWORD /d 1 /f | Out-Null

    # Aplicar a todos los perfiles de usuario en HKEY_USERS
    $userSids = Get-ChildItem Registry::HKEY_USERS | Where-Object { $_.Name -match "S-1-5-21-" -and $_.Name -notmatch "_Classes" }
    foreach ($u in $userSids) {
        $sid = $u.PSChildName
        & reg.exe add "HKU\$sid\Software\Microsoft\Windows\CurrentVersion\Search" /v "BingSearchEnabled" /t REG_DWORD /d 0 /f | Out-Null
        & reg.exe add "HKU\$sid\Software\Microsoft\Windows\CurrentVersion\Search" /v "CortanaConsent" /t REG_DWORD /d 0 /f | Out-Null
        & reg.exe add "HKU\$sid\Software\Microsoft\Windows\CurrentVersion\Search" /v "DeviceHistoryEnabled" /t REG_DWORD /d 0 /f | Out-Null
        & reg.exe add "HKU\$sid\Software\Microsoft\Windows\CurrentVersion\Search" /v "HistoryViewEnabled" /t REG_DWORD /d 0 /f | Out-Null

        & reg.exe add "HKU\$sid\Software\Microsoft\Windows\CurrentVersion\SearchHost" /v "EnableDynamicContentInWSB" /t REG_DWORD /d 0 /f | Out-Null

        & reg.exe add "HKU\$sid\Software\Policies\Microsoft\Windows\Explorer" /v "DisableSearchBoxSuggestions" /t REG_DWORD /d 1 /f | Out-Null
    }
    Escribir-Log "Politicas de busqueda instantanea local aplicadas con exito (Bing desactivado)."
} catch {
    Escribir-Log "Aviso en configuracion de busqueda: $($_.Exception.Message)"
}

# 7. CALIBRACION DE SUAVIDAD, PRECISION Y SCROLL DEL TOUCHPAD (ELAN & PTP)
try {
    # Desactivar la inercia salvaje ("potro loco") del controlador Elantech manteniendo buena respuesta
    & reg.exe add "HKLM\SYSTEM\CurrentControlSet\Control\Elantech\SmartPad" /v "SC_InertialScroll_Enable" /t REG_DWORD /d 0 /f | Out-Null
    & reg.exe add "HKLM\SYSTEM\CurrentControlSet\Control\Elantech\SmartPad" /v "SC_AutoScroll_Enable" /t REG_DWORD /d 0 /f | Out-Null
    & reg.exe add "HKLM\SYSTEM\CurrentControlSet\Control\Elantech\SmartPad" /v "SC_ContinueScroll_Enable" /t REG_DWORD /d 0 /f | Out-Null
    & reg.exe add "HKLM\SYSTEM\CurrentControlSet\Control\Elantech\SmartPad" /v "SC_Speed" /t REG_DWORD /d 2 /f | Out-Null

    $userSids = Get-ChildItem Registry::HKEY_USERS | Where-Object { $_.Name -match "S-1-5-21-" -and $_.Name -notmatch "_Classes" }
    foreach ($u in $userSids) {
        $sid = $u.PSChildName
        & reg.exe add "HKU\$sid\Control Panel\Mouse" /v "MouseSpeed" /t REG_SZ /d "0" /f | Out-Null
        & reg.exe add "HKU\$sid\Control Panel\Mouse" /v "MouseThreshold1" /t REG_SZ /d "0" /f | Out-Null
        & reg.exe add "HKU\$sid\Control Panel\Mouse" /v "MouseThreshold2" /t REG_SZ /d "0" /f | Out-Null
        & reg.exe add "HKU\$sid\Control Panel\Desktop" /v "WheelScrollLines" /t REG_SZ /d "3" /f | Out-Null
        & reg.exe add "HKU\$sid\Software\Microsoft\Windows\CurrentVersion\PrecisionTouchPad" /v "CursorSpeed" /t REG_DWORD /d 8 /f | Out-Null
    }
    Escribir-Log "Touchpad y scroll equilibrados: Elantech SC_Speed=2 sin inercia, WheelScrollLines=3."
} catch {
    Escribir-Log "Aviso en calibracion de touchpad: $($_.Exception.Message)"
}

Escribir-Log "Mantenimiento finalizado: $archivosEliminados carpetas/archivos procesados."
Escribir-Log "=== FIN DE MANTENIMIENTO ===`n"



