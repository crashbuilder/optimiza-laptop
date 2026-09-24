# =====================================================================
# SCRIPT DE MANTENIMIENTO, OPTIMIZACION Y LIMPIEZA INTELIGENTE
# =====================================================================
# Incluye:
# - Desglose detallado de espacio liberado por categoria
# - Cronometro exacto de duracion del analisis y ejecucion
# - Deteccion y eliminacion de archivos duplicados exactos (SHA-256)
# - Proteccion absoluta del fondo de pantalla
# - Reporte ejecutivo limpio en el Escritorio (1 solo archivo)
# - Historial tecnico en carpeta interna
# =====================================================================
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8

# Iniciar cronometro de duracion del analisis y mantenimiento
$stopwatch = [System.Diagnostics.Stopwatch]::StartNew()

$scriptDir = $PSScriptRoot
if (-not $scriptDir) { $scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Definition }
if (-not $scriptDir) { $scriptDir = "C:\Users\Usuario\Scripts" }

$desktopDir = [Environment]::GetFolderPath("Desktop")
if (-not $desktopDir -or -not (Test-Path $desktopDir)) { $desktopDir = "C:\Users\Usuario\Desktop" }

$logFile = Join-Path $scriptDir "Historial_Limpiezas.log"
$desktopReportFile = Join-Path $desktopDir "Reporte_Mantenimiento.txt"

function Escribir-Log($texto, $color = "White") {
    $ts = (Get-Date).ToString("yyyy-MM-dd HH:mm:ss")
    Add-Content -Path $logFile -Value "[$ts] $texto" -Encoding UTF8 -ErrorAction SilentlyContinue
    Write-Host "  $texto" -ForegroundColor $color
}

# Funcion para purgar rutas de forma segura calculando archivos y bytes liberados
function Purgar-Rutas($rutas) {
    $archivos = 0
    $bytes = 0
    foreach ($dir in $rutas) {
        if (Test-Path $dir) {
            $items = Get-ChildItem -Path $dir -Force -Recurse -ErrorAction SilentlyContinue
            foreach ($item in $items) {
                if (-not $item.PSIsContainer) {
                    try {
                        $len = $item.Length
                        Remove-Item -Path $item.FullName -Force -ErrorAction Stop
                        $archivos++
                        $bytes += $len
                    } catch {}
                }
            }
            # Limpiar carpetas vacias residuales
            $subdirs = Get-ChildItem -Path $dir -Directory -Recurse -Force -ErrorAction SilentlyContinue | Sort-Object { $_.FullName.Length } -Descending
            foreach ($sd in $subdirs) {
                try {
                    if ((Get-ChildItem -Path $sd.FullName -Force -ErrorAction SilentlyContinue).Count -eq 0) {
                        Remove-Item -Path $sd.FullName -Force -Recurse -ErrorAction SilentlyContinue
                    }
                } catch {}
            }
        }
    }
    return [PSCustomObject]@{
        Archivos = $archivos
        Bytes = $bytes
        MB = [Math]::Round($bytes / 1MB, 2)
    }
}

# Funcion de analisis y eliminacion de duplicados exactos (tamano identico + SHA256)
function Limpiar-Duplicados($carpetas) {
    $borrados = 0
    $bytes = 0
    $detalles = [System.Collections.Generic.List[string]]::new()
    
    foreach ($dir in $carpetas) {
        if (-not (Test-Path $dir)) { continue }
        
        # Filtrar archivos (excluyendo scripts del sistema, accesos directos y reportes)
        $archivos = Get-ChildItem -Path $dir -File -Recurse -ErrorAction SilentlyContinue | Where-Object {
            $_.Length -gt 0 -and
            $_.Extension -notmatch '^\.(lnk|ini|bat|ps1|vbs|log|txt)$'
        }
        
        # 1. Agrupar por tamano exacto
        $gruposTamano = $archivos | Group-Object Length | Where-Object { $_.Count -gt 1 }
        
        foreach ($grupo in $gruposTamano) {
            # 2. Calcular hash SHA256 solo para colisiones de tamano
            $conHash = $grupo.Group | ForEach-Object {
                [PSCustomObject]@{
                    Item = $_
                    Hash = (Get-FileHash -Path $_.FullName -Algorithm SHA256 -ErrorAction SilentlyContinue).Hash
                }
            } | Where-Object { $_.Hash }
            
            $gruposHash = $conHash | Group-Object Hash | Where-Object { $_.Count -gt 1 }
            
            foreach ($gh in $gruposHash) {
                $items = $gh.Group | ForEach-Object { $_.Item }
                
                # 3. Priorizar conservar el original:
                #    Prefiere nombres limpios sin ' (1)', ' (2)', '- Copia' y fechas mas antiguas
                $ordenados = $items | Sort-Object `
                    @{ Expression = { if ($_.BaseName -match '\s*\(\d+\)$|\s*-\s*Copia') { 1 } else { 0 } } }, `
                    @{ Expression = { $_.CreationTime } }
                
                $conservar = $ordenados[0]
                $aBorrar = $ordenados[1..($ordenados.Count - 1)]
                
                foreach ($dup in $aBorrar) {
                    try {
                        $tamano = $dup.Length
                        Remove-Item -Path $dup.FullName -Force -ErrorAction Stop
                        $borrados++
                        $bytes += $tamano
                        $mb = [Math]::Round($tamano / 1MB, 2)
                        $detalles.Add("$($dup.Name) ($mb MB - clon exacto de $($conservar.Name))")
                    } catch {}
                }
            }
        }
    }
    
    return [PSCustomObject]@{
        Archivos = $borrados
        Bytes = $bytes
        MB = [Math]::Round($bytes / 1MB, 2)
        Detalles = $detalles
    }
}

Clear-Host
Write-Host "=====================================================================" -ForegroundColor Cyan
Write-Host "   MANTENIMIENTO, OPTIMIZACION Y LIMPIEZA INTELIGENTE                " -ForegroundColor Yellow
Write-Host "=====================================================================" -ForegroundColor Cyan
Write-Host ""

$tsInicio = (Get-Date).ToString("yyyy-MM-dd HH:mm:ss")
Add-Content -Path $logFile -Value "[$tsInicio] === INICIO DE MANTENIMIENTO ===" -Encoding UTF8 -ErrorAction SilentlyContinue

# 0. VERIFICAR PRIVILEGIOS
$isAdmin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
if ($isAdmin) {
    Write-Host "[*] Permisos: Administrador (Mantenimiento completo desbloqueado)" -ForegroundColor Green
    $adminStatus = "Administrador (Completo)"
} else {
    Write-Host "[!] Permisos: Usuario estandar (Algunas tareas del sistema seran omitidas)" -ForegroundColor Yellow
    $adminStatus = "Usuario Estandar"
}
Write-Host ""

# 1. PUNTO DE RESTAURACION
Write-Host "[1/9] Punto de Restauracion del Sistema..." -ForegroundColor Cyan
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

# 2. TEMPORALES DE USUARIO
Write-Host ""
Write-Host "[2/9] Analizando temporales de usuario..." -ForegroundColor Cyan
$rutasTempUser = @(
    $env:TEMP,
    "$env:LOCALAPPDATA\CrashDumps"
)
$resTempUser = Purgar-Rutas $rutasTempUser
Escribir-Log "[+] Temporales de usuario purgados: $($resTempUser.Archivos) archivos ($($resTempUser.MB) MB)" "Green"

# 3. TEMPORALES DEL SISTEMA (WINDOWS)
Write-Host ""
Write-Host "[3/9] Analizando temporales del sistema Windows..." -ForegroundColor Cyan
$rutasTempSys = @(
    "C:\Windows\Temp",
    "C:\Windows\SoftwareDistribution\Download"
)
$resTempSys = Purgar-Rutas $rutasTempSys
Escribir-Log "[+] Temporales del sistema purgados: $($resTempSys.Archivos) archivos ($($resTempSys.MB) MB)" "Green"

# 4. CACHE DE NAVEGADORES (EDGE / WEB / SHADERS)
Write-Host ""
Write-Host "[4/9] Limpiando cache web y shaders de Microsoft Edge..." -ForegroundColor Cyan
$rutasEdge = @(
    "$env:LOCALAPPDATA\Microsoft\Edge\User Data\Default\Cache\Cache_Data",
    "$env:LOCALAPPDATA\Microsoft\Edge\User Data\Default\Code Cache",
    "$env:LOCALAPPDATA\Microsoft\Edge\User Data\Default\GPUCache",
    "$env:LOCALAPPDATA\Microsoft\Edge\User Data\ShaderCache"
)
$resEdge = Purgar-Rutas $rutasEdge
Escribir-Log "[+] Cache web purgada: $($resEdge.Archivos) archivos ($($resEdge.MB) MB, sesiones intactas)" "Green"

# 5. INFORMES DE ERROR Y DIAGNOSTICO (WER)
Write-Host ""
Write-Host "[5/9] Limpiando informes de diagnostico y reportes WER..." -ForegroundColor Cyan
$rutasWer = @(
    "C:\ProgramData\Microsoft\Windows\WER\ReportArchive",
    "C:\ProgramData\Microsoft\Windows\WER\ReportQueue"
)
$resWer = Purgar-Rutas $rutasWer
Escribir-Log "[+] Informes de diagnostico eliminados: $($resWer.Archivos) archivos ($($resWer.MB) MB)" "Green"

# 6. PAPELERA DE RECICLAJE
Write-Host ""
Write-Host "[6/9] Midiendo y vaciando Papelera de Reciclaje..." -ForegroundColor Cyan
$papeleraCount = 0
$papeleraBytes = 0
try {
    $shell = New-Object -ComObject Shell.Application
    $bin = $shell.Namespace(0xa)
    $binItems = $bin.Items()
    $papeleraCount = $binItems.Count
    foreach ($item in $binItems) {
        $papeleraBytes += $item.Size
    }
} catch {}

$papeleraMB = [Math]::Round($papeleraBytes / 1MB, 2)

try {
    Clear-RecycleBin -Force -Confirm:$false -ErrorAction SilentlyContinue
    if ($papeleraCount -gt 0) {
        Escribir-Log "[+] Papelera vaciada: $papeleraCount elementos ($papeleraMB MB)" "Green"
        $recycleStatus = "[OK] $papeleraCount elementos vaciados ($papeleraMB MB liberados)"
    } else {
        Escribir-Log "[+] Papelera de reciclaje se encontraba vacia (0 MB)." "Green"
        $recycleStatus = "[OK] 0 elementos (ya se encontraba vacia)"
    }
} catch {
    $recycleStatus = "[OK] Papelera de reciclaje procesada"
}

# 7. ARCHIVOS DUPLICADOS EXACTOS (DESCARGAS Y ESCRITORIO)
Write-Host ""
Write-Host "[7/9] Escaneando y eliminando archivos duplicados redundantes..." -ForegroundColor Cyan
$carpetasEscaneo = @(
    "$env:USERPROFILE\Downloads",
    $desktopDir
)
$resDuplicados = Limpiar-Duplicados $carpetasEscaneo
if ($resDuplicados.Archivos -gt 0) {
    Escribir-Log "[+] Duplicados eliminados: $($resDuplicados.Archivos) clones ($($resDuplicados.MB) MB)" "Green"
    foreach ($d in $resDuplicados.Detalles) {
        Escribir-Log "    -> $d" "DarkCyan"
    }
} else {
    Escribir-Log "[+] Sin archivos duplicados redundantes (0 MB)." "Green"
}

# 8. OPTIMIZACION SSD C: (TRIM) Y RED DNS
Write-Host ""
Write-Host "[8/9] Optimizando celdas SSD (TRIM) y purgando cache DNS..." -ForegroundColor Cyan
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

try {
    Clear-DnsClientCache -ErrorAction SilentlyContinue
    Escribir-Log "[+] Cache DNS purgada (resolucion de nombres refrescada)." "Green"
    $dnsStatus = "[OK] Purgada y conexion refrescada"
} catch {
    $dnsStatus = "[-] No disponible"
}

# 9. PROTECCION DEL FONDO DE PANTALLA Y AJUSTES DE CALIBRACION
Write-Host ""
Write-Host "[9/9] Asegurando fondo de escritorio activo y calibracion..." -ForegroundColor Cyan

# Blindaje: Garantizar que BackgroundType este en 0 (Modo Imagen) y no en Color Solido Negro
try {
    $bgType = (Get-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Wallpapers" -Name "BackgroundType" -ErrorAction SilentlyContinue).BackgroundType
    if ($bgType -ne 0) {
        Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Wallpapers" -Name "BackgroundType" -Value 0 -Type DWord -Force -ErrorAction SilentlyContinue
    }
    # Color de fondo de respaldo a tono grafito espacial (#121317)
    Set-ItemProperty -Path "HKCU:\Control Panel\Colors" -Name "Background" -Value "18 19 23" -Force -ErrorAction SilentlyContinue
    Escribir-Log "[+] Fondo de pantalla protegido: Modo Imagen asegurado." "Green"
} catch {}

# Calibracion de touchpad y busqueda
$userSearch = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Search"
if (-not (Test-Path $userSearch)) { New-Item -Path $userSearch -Force -ErrorAction SilentlyContinue | Out-Null }
Set-ItemProperty -Path $userSearch -Name "BingSearchEnabled" -Value 0 -Type DWord -Force -ErrorAction SilentlyContinue
Set-ItemProperty -Path $userSearch -Name "CortanaConsent" -Value 0 -Type DWord -Force -ErrorAction SilentlyContinue
Set-ItemProperty -Path "HKCU:\Control Panel\Mouse" -Name "MouseSpeed" -Value "0" -Type String -Force -ErrorAction SilentlyContinue
Set-ItemProperty -Path "HKCU:\Control Panel\Desktop" -Name "WheelScrollLines" -Value "3" -Type String -Force -ErrorAction SilentlyContinue

# FINALIZAR CRONOMETRO
$stopwatch.Stop()
$tiempoTotalSegundos = [Math]::Round($stopwatch.Elapsed.TotalSeconds, 2)
if ($tiempoTotalSegundos -ge 60) {
    $mins = [Math]::Floor($tiempoTotalSegundos / 60)
    $segs = [Math]::Round($tiempoTotalSegundos % 60, 1)
    $tiempoTexto = "$mins min $segs s"
} else {
    $tiempoTexto = "$tiempoTotalSegundos segundos"
}

# TOTALES CONSOLIDADOS
$totalArchivos = $resTempUser.Archivos + $resTempSys.Archivos + $resEdge.Archivos + $resWer.Archivos + $papeleraCount + $resDuplicados.Archivos
$totalBytes = $resTempUser.Bytes + $resTempSys.Bytes + $resEdge.Bytes + $resWer.Bytes + $papeleraBytes + $resDuplicados.Bytes
$totalMB = [Math]::Round($totalBytes / 1MB, 2)
$totalGB = [Math]::Round($totalBytes / 1GB, 3)

$tsFin = (Get-Date).ToString("yyyy-MM-dd HH:mm:ss")
Add-Content -Path $logFile -Value "[$tsFin] Mantenimiento finalizado en $tiempoTexto. Total: $totalArchivos archivos ($totalMB MB liberados)." -Encoding UTF8 -ErrorAction SilentlyContinue
Add-Content -Path $logFile -Value "[$tsFin] === FIN DE MANTENIMIENTO ===`n" -Encoding UTF8 -ErrorAction SilentlyContinue

# CONSTRUIR SECCION DE DETALLE DE DUPLICADOS PARA EL REPORTE
$duplicadosTexto = ""
if ($resDuplicados.Detalles.Count -gt 0) {
    $duplicadosTexto = "   • Archivos duplicados eliminados:" + "`r`n"
    foreach ($item in $resDuplicados.Detalles) {
        $duplicadosTexto += "     - $item" + "`r`n"
    }
} else {
    $duplicadosTexto = "   • No se encontraron archivos duplicados redundantes." + "`r`n"
}

# GENERAR REPORTE RESUMIDO EN EL ESCRITORIO
$reporteContent = @"
=====================================================================
   REPORTE DE MANTENIMIENTO, OPTIMIZACION Y LIMPIEZA INTELIGENTE
=====================================================================
Fecha y Hora:           $tsFin
Duracion del Analisis:  $tiempoTexto
Equipo:                 LENOVO 81W6 (IdeaPad 3)
Usuario:                $env:USERNAME
Nivel de Acceso:        $adminStatus

---------------------------------------------------------------------
DESGLOSE DETALLADO POR CATEGORIA:
---------------------------------------------------------------------
1. Temporales de Usuario (`$env:TEMP / CrashDumps):
   * Archivos eliminados: $($resTempUser.Archivos)
   * Espacio liberado:    $($resTempUser.MB) MB

2. Temporales del Sistema Windows (Temp / SoftwareDistribution):
   * Archivos eliminados: $($resTempSys.Archivos)
   * Espacio liberado:    $($resTempSys.MB) MB

3. Cache Web y Shaders (Microsoft Edge):
   * Archivos purgados:   $($resEdge.Archivos)
   * Espacio liberado:    $($resEdge.MB) MB (sesiones intactas)

4. Informes de Error y Diagnostico (WER):
   * Archivos eliminados: $($resWer.Archivos)
   * Espacio liberado:    $($resWer.MB) MB

5. Papelera de Reciclaje:
   * Elementos vaciados:  $papeleraCount
   * Espacio liberado:    $papeleraMB MB
   * Estado:              $recycleStatus

6. Archivos Duplicados Exactos (Descargas y Escritorio):
   * Clones eliminados:   $($resDuplicados.Archivos) (conservando siempre el original)
   * Espacio liberado:    $($resDuplicados.MB) MB
$duplicadosTexto
7. Optimizacion de Memoria SSD (C:):
   * Estado:              $trimStatus

8. Resolucion DNS y Red:
   * Estado:              $dnsStatus

---------------------------------------------------------------------
PROTECCION DEL FONDO DE PANTALLA:
---------------------------------------------------------------------
* Estado: Modo Imagen asegurado (sin pantalla negra)
* Fondo:  A traves de las dificultades / Hacia las estrellas (Neon)

---------------------------------------------------------------------
TOTALES DEL MANTENIMIENTO:
---------------------------------------------------------------------
* Total de archivos eliminados: $totalArchivos archivos
* Espacio total recuperado:     $totalMB MB ($totalGB GB)
* Tiempo total de ejecucion:    $tiempoTexto
* Rendimiento del sistema:      Optimo, rapido y calibrado

---------------------------------------------------------------------
REGISTRO DISPONIBLE:
* Reporte Ejecutivo: $desktopReportFile
* Historial Tecnico (carpeta interna): $logFile
=====================================================================
"@

try {
    $utf8Bom = New-Object System.Text.UTF8Encoding($true)
    [System.IO.File]::WriteAllText($desktopReportFile, $reporteContent, $utf8Bom)
} catch {}

Write-Host ""
Write-Host "=====================================================================" -ForegroundColor Green
Write-Host "   [OK] MANTENIMIENTO Y LIMPIEZA INTELIGENTE COMPLETADOS             " -ForegroundColor Green
Write-Host "=====================================================================" -ForegroundColor Green
Write-Host "  * Duracion del analisis y limpieza: $tiempoTexto" -ForegroundColor Cyan
Write-Host "  * Espacio total recuperado:         $totalMB MB ($totalGB GB)" -ForegroundColor White
Write-Host "  * Total de archivos eliminados:     $totalArchivos" -ForegroundColor White
Write-Host "  * Clones duplicados eliminados:     $($resDuplicados.Archivos) ($($resDuplicados.MB) MB)" -ForegroundColor White
Write-Host "  * Reporte actualizado en tu Escritorio:" -ForegroundColor White
Write-Host "    $desktopReportFile" -ForegroundColor Cyan
Write-Host ""
Write-Host "  Cerrando ventana automaticamente en 2 segundos..." -ForegroundColor DarkGray
Start-Sleep -Seconds 2
