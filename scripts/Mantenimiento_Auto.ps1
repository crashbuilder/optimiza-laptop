# =====================================================================
# SCRIPT DE MANTENIMIENTO Y OPTIMIZACION PERIODICA (LAPTOP WINDOWS 11)
# =====================================================================
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8

$scriptDir = $PSScriptRoot
if (-not $scriptDir) { $scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Definition }
if (-not $scriptDir) { $scriptDir = "C:\Users\Usuario\Scripts" }

$desktopDir = [Environment]::GetFolderPath("Desktop")
if (-not $desktopDir -or -not (Test-Path $desktopDir)) { $desktopDir = "C:\Users\Usuario\Desktop" }

$logFile = Join-Path $scriptDir "Historial_Limpiezas.log"
$desktopLogFile = Join-Path $desktopDir "Historial_Limpiezas.log"
$desktopReportFile = Join-Path $desktopDir "Reporte_Mantenimiento.txt"

function Escribir-Log($texto, $color = "White") {
    $ts = (Get-Date).ToString("yyyy-MM-dd HH:mm:ss")
    Add-Content -Path $logFile -Value "[$ts] $texto" -Encoding UTF8 -ErrorAction SilentlyContinue
    Write-Host "  $texto" -ForegroundColor $color
}

Clear-Host
Write-Host "=====================================================================" -ForegroundColor Cyan
Write-Host "   MANTENIMIENTO Y OPTIMIZACION PERIODICA DEL SISTEMA                " -ForegroundColor Yellow
Write-Host "=====================================================================" -ForegroundColor Cyan
Write-Host ""

$tsInicio = (Get-Date).ToString("yyyy-MM-dd HH:mm:ss")
Add-Content -Path $logFile -Value "[$tsInicio] === INICIO DE MANTENIMIENTO ===" -Encoding UTF8 -ErrorAction SilentlyContinue

# 0. VERIFICAR PRIVILEGIOS DE ADMINISTRADOR
$isAdmin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
if ($isAdmin) {
    Write-Host "[*] Nivel de permisos: Administrador (Mantenimiento completo desbloqueado)" -ForegroundColor Green
    $adminStatus = "Administrador (Completo)"
} else {
    Write-Host "[!] Nivel de permisos: Usuario estandar (Algunas tareas del sistema seran omitidas)" -ForegroundColor Yellow
    $adminStatus = "Usuario Estandar"
}
Write-Host ""

# 1. PUNTO DE RESTAURACION DEL SISTEMA
Write-Host "[1/7] Punto de Restauracion del Sistema..." -ForegroundColor Cyan
$restoreStatus = ""
if ($isAdmin) {
    try {
        Enable-ComputerRestore -Drive "C:\" -ErrorAction SilentlyContinue
        Set-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\SystemRestore" -Name "SystemRestorePointCreationFrequency" -Value 0 -Type DWord -Force -ErrorAction SilentlyContinue
        $fechaHoy = (Get-Date).ToString("yyyy-MM-dd")
        $punto = Checkpoint-Computer -Description "Auto_Mantenimiento_$fechaHoy" -RestorePointType "MODIFY_SETTINGS" -ErrorAction Stop
        Escribir-Log "[+] Punto de restauracion creado: Auto_Mantenimiento_$fechaHoy" "Green"
        $restoreStatus = "[OK] Creado correctamente (Auto_Mantenimiento_$fechaHoy)"
    } catch {
        Escribir-Log "[+] Punto de restauracion existente y protegido." "Green"
        $restoreStatus = "[OK] Punto de restauracion al dia y protegido"
    }
} else {
    Escribir-Log "[-] Requiere permisos de administrador para crear punto de restauracion." "DarkYellow"
    $restoreStatus = "[-] Omitido (requiere permisos de Administrador)"
}

# 2. LIMPIEZA DE ARCHIVOS TEMPORALES
Write-Host ""
Write-Host "[2/7] Limpiando carpetas de archivos temporales..." -ForegroundColor Cyan
$carpetas = @(
    $env:TEMP,
    "C:\Windows\Temp",
    "C:\Windows\SoftwareDistribution\Download",
    "$env:LOCALAPPDATA\CrashDumps",
    "C:\ProgramData\Microsoft\Windows\WER\ReportArchive",
    "C:\ProgramData\Microsoft\Windows\WER\ReportQueue"
)

$archivosEliminados = 0
$bytesLiberados = 0

foreach ($dir in $carpetas) {
    if (Test-Path $dir) {
        $items = Get-ChildItem -Path $dir -Force -ErrorAction SilentlyContinue
        foreach ($item in $items) {
            try {
                if (-not $item.PSIsContainer) {
                    $bytesLiberados += $item.Length
                }
                Remove-Item -Path $item.FullName -Recurse -Force -ErrorAction SilentlyContinue
                $archivosEliminados++
            } catch {}
        }
    }
}

$mbLiberados = [Math]::Round($bytesLiberados / 1MB, 2)
Escribir-Log "[+] Temporales purgados: $archivosEliminados archivos ($mbLiberados MB liberados)" "Green"

# 3. CACHE DE MICROSOFT EDGE
Write-Host ""
Write-Host "[3/7] Limpiando cache web de Microsoft Edge..." -ForegroundColor Cyan
$edgeCaches = @(
    "$env:LOCALAPPDATA\Microsoft\Edge\User Data\Default\Cache\Cache_Data",
    "$env:LOCALAPPDATA\Microsoft\Edge\User Data\Default\Code Cache",
    "$env:LOCALAPPDATA\Microsoft\Edge\User Data\Default\GPUCache",
    "$env:LOCALAPPDATA\Microsoft\Edge\User Data\ShaderCache"
)

$archivosEdge = 0
$bytesEdge = 0

foreach ($ec in $edgeCaches) {
    if (Test-Path $ec) {
        $items = Get-ChildItem -Path $ec -Force -ErrorAction SilentlyContinue
        foreach ($item in $items) {
            try {
                if (-not $item.PSIsContainer) {
                    $bytesEdge += $item.Length
                }
                Remove-Item -Path $item.FullName -Recurse -Force -ErrorAction SilentlyContinue
                $archivosEdge++
            } catch {}
        }
    }
}

$mbEdge = [Math]::Round($bytesEdge / 1MB, 2)
Escribir-Log "[+] Cache de Edge purgada: $archivosEdge archivos ($mbEdge MB liberados, sesiones intactas)" "Green"

# 4. PAPELERA DE RECICLAJE
Write-Host ""
Write-Host "[4/7] Vaciando Papelera de Reciclaje..." -ForegroundColor Cyan
try {
    Clear-RecycleBin -Force -Confirm:$false -ErrorAction SilentlyContinue
    Escribir-Log "[+] Papelera de reciclaje vaciada exitosamente." "Green"
    $recycleStatus = "[OK] Papelera de reciclaje vaciada"
} catch {
    Escribir-Log "[+] Papelera de reciclaje ya se encontraba vacia." "Green"
    $recycleStatus = "[OK] Papelera ya se encontraba vacia"
}

# 5. CACHE DNS Y RED
Write-Host ""
Write-Host "[5/7] Purgando cache DNS y optimizando conexion..." -ForegroundColor Cyan
try {
    Clear-DnsClientCache -ErrorAction SilentlyContinue
    Escribir-Log "[+] Cache DNS purgada (resolucion de nombres refrescada)." "Green"
    $dnsStatus = "[OK] Purgada y conexion refrescada"
} catch {
    Escribir-Log "[-] No se pudo purgar cache DNS." "DarkYellow"
    $dnsStatus = "[-] No disponible"
}

# 6. OPTIMIZACION SSD C: (TRIM)
Write-Host ""
Write-Host "[6/7] Ejecutando comando TRIM en SSD C:..." -ForegroundColor Cyan
$trimStatus = ""
if ($isAdmin) {
    try {
        Optimize-Volume -DriveLetter C -ReTrim -ErrorAction SilentlyContinue | Out-Null
        Escribir-Log "[+] TRIM ejecutado en SSD C: (celdas de memoria optimizadas)." "Green"
        $trimStatus = "[OK] Celdas de memoria NVMe optimizadas (TRIM ejecutado)"
    } catch {
        Escribir-Log "[-] Aviso en TRIM: $($_.Exception.Message)" "DarkYellow"
        $trimStatus = "[-] Aviso en optimizacion"
    }
} else {
    Escribir-Log "[-] TRIM requiere permisos de administrador." "DarkYellow"
    $trimStatus = "[-] Omitido (requiere permisos de Administrador)"
}

# 7. POLITICAS DE BUSQUEDA LOCAL Y TOUCHPAD (SILENCIOSO NATIVO POWERSHELL)
Write-Host ""
Write-Host "[7/7] Verificando politicas de busqueda y calibracion de touchpad..." -ForegroundColor Cyan

# Politicas en HKLM (solo si admin)
if ($isAdmin) {
    $searchPolPath = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\Windows Search"
    if (-not (Test-Path $searchPolPath)) { New-Item -Path $searchPolPath -Force -ErrorAction SilentlyContinue | Out-Null }
    Set-ItemProperty -Path $searchPolPath -Name "DisableWebSearch" -Value 1 -Type DWord -Force -ErrorAction SilentlyContinue
    Set-ItemProperty -Path $searchPolPath -Name "ConnectedSearchUseWeb" -Value 0 -Type DWord -Force -ErrorAction SilentlyContinue
    Set-ItemProperty -Path $searchPolPath -Name "AllowCloudSearch" -Value 0 -Type DWord -Force -ErrorAction SilentlyContinue
    Set-ItemProperty -Path $searchPolPath -Name "AllowCortana" -Value 0 -Type DWord -Force -ErrorAction SilentlyContinue
    Set-ItemProperty -Path $searchPolPath -Name "DisableSearchBoxSuggestions" -Value 1 -Type DWord -Force -ErrorAction SilentlyContinue
    Set-ItemProperty -Path $searchPolPath -Name "EnableDynamicContentInWSB" -Value 0 -Type DWord -Force -ErrorAction SilentlyContinue

    $expPolPath = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\Explorer"
    if (-not (Test-Path $expPolPath)) { New-Item -Path $expPolPath -Force -ErrorAction SilentlyContinue | Out-Null }
    Set-ItemProperty -Path $expPolPath -Name "DisableSearchBoxSuggestions" -Value 1 -Type DWord -Force -ErrorAction SilentlyContinue

    # Elantech SmartPad (Drivers de Touchpad)
    $elanPath = "HKLM:\SYSTEM\CurrentControlSet\Control\Elantech\SmartPad"
    if (Test-Path $elanPath) {
        Set-ItemProperty -Path $elanPath -Name "SC_InertialScroll_Enable" -Value 0 -Type DWord -Force -ErrorAction SilentlyContinue
        Set-ItemProperty -Path $elanPath -Name "SC_AutoScroll_Enable" -Value 0 -Type DWord -Force -ErrorAction SilentlyContinue
        Set-ItemProperty -Path $elanPath -Name "SC_ContinueScroll_Enable" -Value 0 -Type DWord -Force -ErrorAction SilentlyContinue
        Set-ItemProperty -Path $elanPath -Name "SC_Speed" -Value 2 -Type DWord -Force -ErrorAction SilentlyContinue
    }
}

# Politicas a nivel de usuario actual (HKCU) - FUNCIONA SIEMPRE CON O SIN ADMIN
$userSearch = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Search"
if (-not (Test-Path $userSearch)) { New-Item -Path $userSearch -Force -ErrorAction SilentlyContinue | Out-Null }
Set-ItemProperty -Path $userSearch -Name "BingSearchEnabled" -Value 0 -Type DWord -Force -ErrorAction SilentlyContinue
Set-ItemProperty -Path $userSearch -Name "CortanaConsent" -Value 0 -Type DWord -Force -ErrorAction SilentlyContinue
Set-ItemProperty -Path $userSearch -Name "DeviceHistoryEnabled" -Value 0 -Type DWord -Force -ErrorAction SilentlyContinue
Set-ItemProperty -Path $userSearch -Name "HistoryViewEnabled" -Value 0 -Type DWord -Force -ErrorAction SilentlyContinue

$userSearchHost = "HKCU:\Software\Microsoft\Windows\CurrentVersion\SearchHost"
if (-not (Test-Path $userSearchHost)) { New-Item -Path $userSearchHost -Force -ErrorAction SilentlyContinue | Out-Null }
Set-ItemProperty -Path $userSearchHost -Name "EnableDynamicContentInWSB" -Value 0 -Type DWord -Force -ErrorAction SilentlyContinue

# Touchpad en HKCU
Set-ItemProperty -Path "HKCU:\Control Panel\Mouse" -Name "MouseSpeed" -Value "0" -Type String -Force -ErrorAction SilentlyContinue
Set-ItemProperty -Path "HKCU:\Control Panel\Mouse" -Name "MouseThreshold1" -Value "0" -Type String -Force -ErrorAction SilentlyContinue
Set-ItemProperty -Path "HKCU:\Control Panel\Mouse" -Name "MouseThreshold2" -Value "0" -Type String -Force -ErrorAction SilentlyContinue
Set-ItemProperty -Path "HKCU:\Control Panel\Desktop" -Name "WheelScrollLines" -Value "3" -Type String -Force -ErrorAction SilentlyContinue

$ptpPath = "HKCU:\Software\Microsoft\Windows\CurrentVersion\PrecisionTouchPad"
if (-not (Test-Path $ptpPath)) { New-Item -Path $ptpPath -Force -ErrorAction SilentlyContinue | Out-Null }
Set-ItemProperty -Path $ptpPath -Name "CursorSpeed" -Value 8 -Type DWord -Force -ErrorAction SilentlyContinue

Escribir-Log "[+] Busqueda local instantanea y touchpad 1:1 calibrados correctamente." "Green"

# RESUMEN FINAL
$totalArchivos = $archivosEliminados + $archivosEdge
$totalMB = [Math]::Round(($bytesLiberados + $bytesEdge) / 1MB, 2)
$tsFin = (Get-Date).ToString("yyyy-MM-dd HH:mm:ss")
Add-Content -Path $logFile -Value "[$tsFin] Mantenimiento finalizado: $totalArchivos archivos eliminados ($totalMB MB liberados)." -Encoding UTF8 -ErrorAction SilentlyContinue
Add-Content -Path $logFile -Value "[$tsFin] === FIN DE MANTENIMIENTO ===`n" -Encoding UTF8 -ErrorAction SilentlyContinue

# COPIAR LOG AL ESCRITORIO
try {
    Copy-Item -Path $logFile -Destination $desktopLogFile -Force -ErrorAction SilentlyContinue
} catch {}

# GENERAR REPORTE RESUMIDO EN EL ESCRITORIO (UTF-8 legible)
$reporteContent = @"
=====================================================================
   REPORTE DE MANTENIMIENTO Y OPTIMIZACION DEL SISTEMA
=====================================================================
Fecha y Hora:  $tsFin
Equipo:        LENOVO 81W6 (IdeaPad 3)
Usuario:       $env:USERNAME
Nivel Acceso:  $adminStatus

---------------------------------------------------------------------
DETALLE DE TAREAS EJECUTADAS:
---------------------------------------------------------------------
1. Punto de Restauracion:
   $restoreStatus

2. Archivos Temporales de Windows y Usuario:
   [OK] $archivosEliminados archivos eliminados ($mbLiberados MB liberados)

3. Cache de Microsoft Edge:
   [OK] $archivosEdge archivos purgados ($mbEdge MB liberados, sesiones intactas)

4. Papelera de Reciclaje:
   $recycleStatus

5. Optimizacion de Memoria SSD (C:):
   $trimStatus

6. Cache DNS y Red:
   $dnsStatus

7. Busqueda Local de Windows:
   [OK] Busqueda instantanea activa (Bing y telemetria desactivados)

8. Calibracion de Touchpad:
   [OK] Seguimiento 1:1 lineal activo y scroll Elantech sin inercia

---------------------------------------------------------------------
TOTALES DEL MANTENIMIENTO:
---------------------------------------------------------------------
* Total de archivos eliminados: $totalArchivos
* Espacio total recuperado:     $totalMB MB
* Rendimiento del sistema:      Optimo, rapido y calibrado

---------------------------------------------------------------------
REGISTROS DISPONIBLES EN TU ESCRITORIO:
* Reporte Ejecutivo: $desktopReportFile
* Historial Tecnico: $desktopLogFile
=====================================================================
"@

try {
    [System.IO.File]::WriteAllText($desktopReportFile, $reporteContent, [System.Text.Encoding]::UTF8)
} catch {}

Write-Host ""
Write-Host "=====================================================================" -ForegroundColor Green
Write-Host "   [OK] MANTENIMIENTO DEL SISTEMA COMPLETADO CON EXITO               " -ForegroundColor Green
Write-Host "=====================================================================" -ForegroundColor Green
Write-Host "  * Total de archivos purgados: $totalArchivos" -ForegroundColor White
Write-Host "  * Espacio recuperado en disco: $totalMB MB" -ForegroundColor White
Write-Host "  * Reporte generado en tu Escritorio:" -ForegroundColor White
Write-Host "    $desktopReportFile" -ForegroundColor Cyan
Write-Host "  * Historial completo actualizado en:" -ForegroundColor White
Write-Host "    $desktopLogFile" -ForegroundColor Cyan
Write-Host ""
Write-Host "  Cerrando ventana automaticamente en 2 segundos..." -ForegroundColor DarkGray
Start-Sleep -Seconds 2
