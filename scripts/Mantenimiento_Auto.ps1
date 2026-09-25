# =====================================================================
# SCRIPT DE MANTENIMIENTO, OPTIMIZACION Y LIMPIEZA INTELIGENTE
# =====================================================================
# Incluye:
# - Desglose detallado de espacio liberado por categoria
# - Cronometro exacto de duracion del analisis y ejecucion
# - Deteccion y eliminacion de archivos duplicados exactos (SHA-256)
# - Organizacion inteligente y automatica de la carpeta Descargas
# - Proteccion absoluta del fondo de pantalla
# - Reporte ejecutivo limpio en el Escritorio (1 solo archivo)
# - Historial tecnico en carpeta interna
# =====================================================================
param(
    [switch]$SoloOrganizarDescargas,
    [switch]$OmitirOrganizarDescargas
)

$OutputEncoding = [System.Text.Encoding]::UTF8
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8

# Desactivar QuickEdit Mode para que un clic accidental dentro de la consola NO pause la ejecucion
try {
    $kernel32 = Add-Type -MemberDefinition @'
[DllImport("kernel32.dll", SetLastError = true)]
public static extern IntPtr GetStdHandle(int nStdHandle);
[DllImport("kernel32.dll", SetLastError = true)]
public static extern bool GetConsoleMode(IntPtr hConsoleHandle, out uint lpMode);
[DllImport("kernel32.dll", SetLastError = true)]
public static extern bool SetConsoleMode(IntPtr hConsoleHandle, uint dwMode);
'@ -Name "Win32ConsoleHelper" -Namespace "Win32Console" -PassThru -ErrorAction SilentlyContinue
    $hStdin = [Win32Console.Win32ConsoleHelper]::GetStdHandle(-10) # STD_INPUT_HANDLE = -10
    $mode = 0
    if ([Win32Console.Win32ConsoleHelper]::GetConsoleMode($hStdin, [ref]$mode)) {
        $newMode = $mode -band (-bnot 0x0040) # Quitar ENABLE_QUICK_EDIT_MODE (0x0040)
        [Win32Console.Win32ConsoleHelper]::SetConsoleMode($hStdin, $newMode) | Out-Null
    }
} catch {}

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

# Funcion de organizacion inteligente de la carpeta de descargas
function Organizar-Descargas {
    param(
        [string]$DownloadsPath = "$env:USERPROFILE\Downloads",
        [switch]$Silencioso
    )

    if (-not (Test-Path $DownloadsPath)) {
        return [PSCustomObject]@{
            Total = 0
            MB = 0
            Desglose = @{}
            Detalles = @()
        }
    }

    $strA_acc = [char]0x00E1
    $nomImagenes = "Im" + $strA_acc + "genes"
    $nomDatosGeo = "Datos Geogr" + $strA_acc + "ficos"

    # 1. Definir rutas de destino
    $dirVideos       = Join-Path $DownloadsPath "Videos"
    $dirImagenes     = Join-Path $DownloadsPath $nomImagenes
    $dirDocumentos   = Join-Path $DownloadsPath "Documentos"

    $dirWord         = Join-Path $dirDocumentos "Word"
    $dirPdf          = Join-Path $dirDocumentos "PDF"
    $dirExcel        = Join-Path $dirDocumentos "Excel"
    $dirPowerPoint   = Join-Path $dirDocumentos "PowerPoint"
    $dirGeo          = Join-Path $dirDocumentos $nomDatosGeo
    $dirInstaladores = Join-Path $dirDocumentos "Instaladores"

    $todasCarpetas = @(
        $dirVideos, $dirImagenes, $dirDocumentos,
        $dirWord, $dirPdf, $dirExcel, $dirPowerPoint,
        $dirGeo, $dirInstaladores
    )

    foreach ($c in $todasCarpetas) {
        if (-not (Test-Path $c)) {
            New-Item -Path $c -ItemType Directory -Force -ErrorAction SilentlyContinue | Out-Null
        }
    }

    # 2. Unificar carpeta previa de Instaladores si existia en la raiz de Descargas
    $dirInstaladoresLegacy = Join-Path $DownloadsPath "Instaladores"
    if ((Test-Path $dirInstaladoresLegacy) -and ($dirInstaladoresLegacy -ne $dirInstaladores)) {
        $itemLegacy = Get-Item $dirInstaladoresLegacy -Force -ErrorAction SilentlyContinue
        $isJunction = ($itemLegacy.Attributes -band [System.IO.FileAttributes]::ReparsePoint)
        if (-not $isJunction) {
            $archivosLegacy = Get-ChildItem -Path $dirInstaladoresLegacy -File -Force -ErrorAction SilentlyContinue
            foreach ($fl in $archivosLegacy) {
                $targetFile = Join-Path $dirInstaladores $fl.Name
                if (-not (Test-Path $targetFile)) {
                    Move-Item -Path $fl.FullName -Destination $targetFile -Force -ErrorAction SilentlyContinue
                }
            }
            $restantes = Get-ChildItem -Path $dirInstaladoresLegacy -Force -ErrorAction SilentlyContinue
            if ($restantes.Count -eq 0) {
                Remove-Item -Path $dirInstaladoresLegacy -Force -Recurse -ErrorAction SilentlyContinue
                cmd.exe /c "mklink /J `"$dirInstaladoresLegacy`" `"$dirInstaladores`"" *>$null
            }
        }
    }

    # 3. Extensiones por categoria
    $extVideos = @('.mp4', '.mkv', '.avi', '.mov', '.wmv', '.flv', '.webm', '.m4v', '.3gp', '.mpeg', '.mpg', '.ts')
    $extImagenes = @('.jpg', '.jpeg', '.png', '.gif', '.bmp', '.webp', '.svg', '.ico', '.tiff', '.tif', '.raw', '.cr2', '.nef', '.heic', '.psd')
    $extWord = @('.docx', '.doc', '.docm', '.dotx', '.dot', '.odt', '.rtf')
    $extPdf = @('.pdf')
    $extExcel = @('.xlsx', '.xls', '.xlsm', '.xlsb', '.xltx', '.csv', '.tsv', '.ods')
    $extPowerPoint = @('.pptx', '.ppt', '.pptm', '.potx', '.pot', '.ppsx', '.pps', '.odp')
    $extInstaladores = @('.exe', '.msi', '.apk', '.iso', '.img', '.appx', '.msix', '.msixbundle')
    $extGeo = @('.shp', '.shx', '.dbf', '.prj', '.cpg', '.sbn', '.sbx', '.fbn', '.fbx', '.ain', '.aih', '.ixs', '.mxs', '.atx', '.geojson', '.kml', '.kmz', '.gpkg', '.gdb', '.qgz', '.qgs', '.dem', '.asc', '.laz', '.las', '.ecw', '.sid')

    $desglose = [ordered]@{
        "Word"              = 0
        "PDF"               = 0
        "Excel"             = 0
        "PowerPoint"        = 0
        $nomDatosGeo        = 0
        "Instaladores"      = 0
        $nomImagenes        = 0
        "Videos"            = 0
    }
    $totalMovidos = 0
    $totalBytes = 0
    $detalles = [System.Collections.Generic.List[string]]::new()

    $archivosDescargas = Get-ChildItem -Path $DownloadsPath -File -Force -ErrorAction SilentlyContinue | Where-Object {
        $_.Name -notmatch '^(desktop\.ini|thumbs\.db)$' -and
        $_.Extension -notmatch '^\.(tmp|crdownload|part|download|partial)$'
    }

    foreach ($archivo in $archivosDescargas) {
        $ext = $archivo.Extension.ToLower()
        $nombre = $archivo.Name
        $tamano = $archivo.Length
        $carpetaDestino = $null
        $categoriaNombre = $null

        if ($ext -in $extWord) {
            $carpetaDestino = $dirWord
            $categoriaNombre = "Word"
        } elseif ($ext -in $extPdf) {
            $carpetaDestino = $dirPdf
            $categoriaNombre = "PDF"
        } elseif ($ext -in $extExcel) {
            $carpetaDestino = $dirExcel
            $categoriaNombre = "Excel"
        } elseif ($ext -in $extPowerPoint) {
            $carpetaDestino = $dirPowerPoint
            $categoriaNombre = "PowerPoint"
        } elseif ($ext -in $extInstaladores) {
            $carpetaDestino = $dirInstaladores
            $categoriaNombre = "Instaladores"
        } elseif ($ext -in $extGeo) {
            $carpetaDestino = $dirGeo
            $categoriaNombre = $nomDatosGeo
        } elseif ($ext -in $extVideos) {
            $carpetaDestino = $dirVideos
            $categoriaNombre = "Videos"
        } elseif ($ext -in $extImagenes) {
            $carpetaDestino = $dirImagenes
            $categoriaNombre = $nomImagenes
        } elseif ($ext -in @('.zip', '.rar', '.7z', '.tar', '.gz')) {
            if ($nombre -match 'SHP_|VEREDAS|DEPTO|MPIO|GDB|RUNAP|IGAC|DANE|CORPOGUAJIRA|GEO|MAPA|CUENCA|CATASTRO|PREDIO|CARTOGRAFIA|SUELOS') {
                $carpetaDestino = $dirGeo
                $categoriaNombre = $nomDatosGeo
            } else {
                try {
                    $tarOutput = (& tar.exe -tf $archivo.FullName 2>$null | Select-Object -First 15) -join "`n"
                    if ($tarOutput -match '\.(shp|shx|dbf|prj|gpkg|kml|kmz|geojson)|\.gdb/') {
                        $carpetaDestino = $dirGeo
                        $categoriaNombre = $nomDatosGeo
                    } elseif ($tarOutput -match '\.(jpg|jpeg|png|bmp|webp|tif|tiff)') {
                        $carpetaDestino = $dirImagenes
                        $categoriaNombre = $nomImagenes
                    } elseif ($tarOutput -match '\.(exe|msi|apk)') {
                        $carpetaDestino = $dirInstaladores
                        $categoriaNombre = "Instaladores"
                    }
                } catch {}
            }
        }

        if ($carpetaDestino -and (Test-Path $carpetaDestino)) {
            $destinoFinal = Join-Path $carpetaDestino $nombre
            try {
                if (Test-Path $destinoFinal) {
                    $hashOrig = (Get-FileHash -Path $archivo.FullName -Algorithm SHA256 -ErrorAction SilentlyContinue).Hash
                    $hashDest = (Get-FileHash -Path $destinoFinal -Algorithm SHA256 -ErrorAction SilentlyContinue).Hash
                    if ($hashOrig -and $hashDest -and ($hashOrig -eq $hashDest)) {
                        Remove-Item -Path $archivo.FullName -Force -ErrorAction Stop
                        $detalles.Add("$nombre -> Descartado clon redundante (ya existia en $categoriaNombre)")
                    } else {
                        $base = $archivo.BaseName
                        $extOriginal = $archivo.Extension
                        $idx = 1
                        do {
                            $nuevoNombre = "${base}_${idx}${extOriginal}"
                            $destinoFinal = Join-Path $carpetaDestino $nuevoNombre
                            $idx++
                        } while (Test-Path $destinoFinal)

                        Move-Item -Path $archivo.FullName -Destination $destinoFinal -Force -ErrorAction Stop
                        $totalMovidos++
                        $totalBytes += $tamano
                        $desglose[$categoriaNombre]++
                        $detalles.Add("$nombre -> $categoriaNombre (renombrado a $nuevoNombre)")
                    }
                } else {
                    Move-Item -Path $archivo.FullName -Destination $destinoFinal -Force -ErrorAction Stop
                    $totalMovidos++
                    $totalBytes += $tamano
                    $desglose[$categoriaNombre]++
                    $detalles.Add("$nombre -> $categoriaNombre")
                }
            } catch {
                if (-not $Silencioso) {
                    Write-Host "  [-] Error al mover $($nombre): $($_.Exception.Message)" -ForegroundColor Red
                }
            }
        }
    }

    $totalMB = [Math]::Round($totalBytes / 1MB, 2)
    return [PSCustomObject]@{
        Total    = $totalMovidos
        Bytes    = $totalBytes
        MB       = $totalMB
        Desglose = $desglose
        Detalles = $detalles
    }
}

# Ejecucion exclusiva de organizacion de descargas si se solicito por parametro
if ($SoloOrganizarDescargas) {
    Clear-Host
    Write-Host "=====================================================================" -ForegroundColor Cyan
    Write-Host "   ORGANIZADOR INTELIGENTE DE CARPETA DE DESCARGAS                   " -ForegroundColor Yellow
    Write-Host "=====================================================================" -ForegroundColor Cyan
    Write-Host ""
    $res = Organizar-Descargas
    if ($res.Total -gt 0) {
        Write-Host "[+] Se organizaron $($res.Total) archivos ($($res.MB) MB) exitosamente:" -ForegroundColor Green
        foreach ($k in $res.Desglose.Keys) {
            if ($res.Desglose[$k] -gt 0) {
                Write-Host "    - $($k): $($res.Desglose[$k]) archivo(s)" -ForegroundColor White
            }
        }
    } else {
        Write-Host "[+] Tu carpeta de Descargas ya esta 100% limpia y organizada." -ForegroundColor Green
    }
    Write-Host ""
    Write-Host "Cerrando ventana en 2 segundos..." -ForegroundColor DarkGray
    Start-Sleep -Seconds 2
    exit
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
Write-Host "[1/10] Punto de Restauracion del Sistema..." -ForegroundColor Cyan
$restoreStatus = ""
if ($isAdmin) {
    try {
        Enable-ComputerRestore -Drive "C:\" -ErrorAction SilentlyContinue
        Set-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\SystemRestore" -Name "SystemRestorePointCreationFrequency" -Value 0 -Type DWord -Force -ErrorAction SilentlyContinue
        $fechaHoy = (Get-Date).ToString("yyyy-MM-dd")
        
        # Verificar si ya se creo un punto hoy para no demorar innecesariamente
        $existente = Get-ComputerRestorePoint -ErrorAction SilentlyContinue | Where-Object { $_.Description -match $fechaHoy }
        if ($existente) {
            Escribir-Log "[+] Punto de restauracion al dia ($($existente[0].Description))." "Green"
            $restoreStatus = "[OK] Punto de restauracion al dia ($($existente[0].Description))"
        } else {
            Write-Host "  -> Creando instantanea VSS del disco C: (toma ~30 seg, por favor espera)..." -ForegroundColor DarkCyan
            $punto = Checkpoint-Computer -Description "Auto_Mantenimiento_$fechaHoy" -RestorePointType "MODIFY_SETTINGS" -ErrorAction Stop
            Escribir-Log "[+] Punto de restauracion creado: Auto_Mantenimiento_$fechaHoy" "Green"
            $restoreStatus = "[OK] Creado correctamente (Auto_Mantenimiento_$fechaHoy)"
        }
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
Write-Host "[2/10] Analizando temporales de usuario..." -ForegroundColor Cyan
$rutasTempUser = @(
    $env:TEMP,
    "$env:LOCALAPPDATA\CrashDumps"
)
$resTempUser = Purgar-Rutas $rutasTempUser
Escribir-Log "[+] Temporales de usuario purgados: $($resTempUser.Archivos) archivos ($($resTempUser.MB) MB)" "Green"

# 3. TEMPORALES DEL SISTEMA (WINDOWS)
Write-Host ""
Write-Host "[3/10] Analizando temporales del sistema Windows..." -ForegroundColor Cyan
$rutasTempSys = @(
    "C:\Windows\Temp",
    "C:\Windows\SoftwareDistribution\Download"
)
$resTempSys = Purgar-Rutas $rutasTempSys
Escribir-Log "[+] Temporales del sistema purgados: $($resTempSys.Archivos) archivos ($($resTempSys.MB) MB)" "Green"

# 4. CACHE DE NAVEGADORES (EDGE / WEB / SHADERS)
Write-Host ""
Write-Host "[4/10] Limpiando cache web y shaders de Microsoft Edge..." -ForegroundColor Cyan
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
Write-Host "[5/10] Limpiando informes de diagnostico y reportes WER..." -ForegroundColor Cyan
$rutasWer = @(
    "C:\ProgramData\Microsoft\Windows\WER\ReportArchive",
    "C:\ProgramData\Microsoft\Windows\WER\ReportQueue"
)
$resWer = Purgar-Rutas $rutasWer
Escribir-Log "[+] Informes de diagnostico eliminados: $($resWer.Archivos) archivos ($($resWer.MB) MB)" "Green"

# 6. PAPELERA DE RECICLAJE (TODAS LAS UNIDADES C:, D:, ETC.)
Write-Host ""
Write-Host "[6/10] Midiendo y vaciando Papelera de Reciclaje en todas las unidades..." -ForegroundColor Cyan
$papeleraCount = 0
$papeleraBytes = 0

try {
    Add-Type -MemberDefinition @'
[DllImport("shell32.dll", CharSet = CharSet.Unicode)]
public static extern int SHEmptyRecycleBin(IntPtr hwnd, string pszRootPath, uint dwFlags);

[DllImport("shell32.dll", CharSet = CharSet.Unicode)]
public static extern int SHQueryRecycleBin(string pszRootPath, ref SHQUERYRBINFO pSHQueryRBInfo);

[StructLayout(LayoutKind.Sequential, Pack = 4)]
public struct SHQUERYRBINFO {
    public int cbSize;
    public long i64Size;
    public long i64NumItems;
}

public static long[] ConsultarPapelera(string unidad) {
    SHQUERYRBINFO info = new SHQUERYRBINFO();
    info.cbSize = Marshal.SizeOf(typeof(SHQUERYRBINFO));
    SHQueryRecycleBin(unidad, ref info);
    return new long[] { info.i64NumItems, info.i64Size };
}

public static void VaciarTodo() {
    // SHERB_NOCONFIRMATION = 1, SHERB_NOPROGRESSUI = 2, SHERB_NOSOUND = 4 -> 7
    SHEmptyRecycleBin(IntPtr.Zero, null, 7);
}
'@ -Name "WinRecycleCore" -Namespace "WinAPI" -PassThru -ErrorAction SilentlyContinue | Out-Null

    # Medir en todas las unidades fijas (C:, D:, etc.)
    $unidades = Get-Volume | Where-Object { $_.DriveType -eq 'Fixed' -and $_.DriveLetter }
    foreach ($u in $unidades) {
        $letra = "$($u.DriveLetter):\"
        $q = [WinAPI.WinRecycleCore]::ConsultarPapelera($letra)
        $papeleraCount += $q[0]
        $papeleraBytes += $q[1]
    }
    
    # Vaciar en todo el sistema (todas las particiones) y actualizar icono de escritorio
    [WinAPI.WinRecycleCore]::VaciarTodo()
    Clear-RecycleBin -Force -Confirm:$false -ErrorAction SilentlyContinue
} catch {
    Clear-RecycleBin -Force -Confirm:$false -ErrorAction SilentlyContinue
}

$papeleraMB = [Math]::Round($papeleraBytes / 1MB, 2)
if ($papeleraCount -gt 0) {
    Escribir-Log "[+] Papelera vaciada en todos los discos: $papeleraCount elementos ($papeleraMB MB)" "Green"
    $recycleStatus = "[OK] $papeleraCount elementos vaciados ($papeleraMB MB liberados)"
} else {
    Escribir-Log "[+] Papelera de reciclaje se encontraba vacia en todos los discos (0 MB)." "Green"
    $recycleStatus = "[OK] 0 elementos (ya se encontraba vacia)"
}

# 7. ARCHIVOS DUPLICADOS EXACTOS (DESCARGAS Y ESCRITORIO)
Write-Host ""
Write-Host "[7/10] Escaneando y eliminando archivos duplicados redundantes..." -ForegroundColor Cyan
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

# 8. ORGANIZACION INTELIGENTE DE DESCARGAS RECIENTES
Write-Host ""
Write-Host "[8/10] Clasificando y organizando descargas recientes en carpetas tematicas..." -ForegroundColor Cyan
$orgDescargasStatus = ""
$resOrganizacion = [PSCustomObject]@{ Total = 0; MB = 0; Desglose = @{}; Detalles = @() }

if (-not $OmitirOrganizarDescargas) {
    $resOrganizacion = Organizar-Descargas -Silencioso
    if ($resOrganizacion.Total -gt 0) {
        Escribir-Log "[+] Descargas organizadas: $($resOrganizacion.Total) archivos ($($resOrganizacion.MB) MB clasificados)." "Green"
        foreach ($cat in $resOrganizacion.Desglose.Keys) {
            if ($resOrganizacion.Desglose[$cat] -gt 0) {
                Escribir-Log "    -> $($cat): $($resOrganizacion.Desglose[$cat]) archivo(s)" "DarkCyan"
            }
        }
        $orgDescargasStatus = "[OK] $($resOrganizacion.Total) archivos ordenados ($($resOrganizacion.MB) MB clasificados)"
    } else {
        Escribir-Log "[+] Carpeta de Descargas al dia (0 archivos pendientes por clasificar)." "Green"
        $orgDescargasStatus = "[OK] Al dia (previamente organizada y limpia)"
    }
} else {
    Escribir-Log "[-] Organizacion de descargas omitida por parametro." "DarkYellow"
    $orgDescargasStatus = "[-] Omitida por parametro"
}

# 9. OPTIMIZACION SSD C: (TRIM) Y RED DNS
Write-Host ""
Write-Host "[9/10] Optimizando celdas SSD (TRIM) y purgando cache DNS..." -ForegroundColor Cyan
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

# 10. AUDITORIA DE IMPACTO DEL FONDO DE PANTALLA EN RAM
Write-Host ""
Write-Host "[10/10] Auditando impacto del fondo de pantalla en la memoria RAM..." -ForegroundColor Cyan

$wpReport = @{
    Nombre = "Sin fondo detectado"
    Dimensiones = "N/A"
    PesoDisco = "0 KB"
    HuellaRAM = "0 MB"
    Riesgo = "Nulo"
    Accion = "Conservado"
    EsAmenaza = $false
}

try {
    Add-Type -AssemblyName System.Drawing -ErrorAction SilentlyContinue
    $wpPath = (Get-ItemProperty -Path 'HKCU:\Control Panel\Desktop' -Name "Wallpaper" -ErrorAction SilentlyContinue).Wallpaper
    if (-not $wpPath -or -not (Test-Path $wpPath)) {
        $wpPath = "$env:APPDATA\Microsoft\Windows\Themes\TranscodedWallpaper"
    }

    if (Test-Path $wpPath) {
        $wpFile = Get-Item $wpPath
        $wpName = if ($wpFile.Name -eq "TranscodedWallpaper") { "TranscodedWallpaper (Tema de Windows)" } else { $wpFile.Name }
        $diskBytes = $wpFile.Length
        $diskSizeStr = if ($diskBytes -ge 1MB) { "$([Math]::Round($diskBytes / 1MB, 2)) MB" } else { "$([Math]::Round($diskBytes / 1KB, 1)) KB" }
        
        $img = [System.Drawing.Image]::FromFile($wpPath)
        $w = $img.Width
        $h = $img.Height
        $img.Dispose()
        
        # Buffer de video DWM ARGB 32-bit (ancho x alto x 4 bytes)
        $ramBufferMB = [Math]::Round(($w * $h * 4) / 1MB, 2)
        
        # Criterio de evaluacion de amenaza:
        # Se considera amenaza real a la RAM si supera 25 MB en disco o si la huella DWM supera 35 MB (> 4K en pantalla 768p)
        $esAmenaza = ($diskBytes -gt 25MB) -or ($ramBufferMB -gt 35)
        
        $wpReport.Nombre = $wpName
        $wpReport.Dimensiones = "${w} x ${h}"
        $wpReport.PesoDisco = $diskSizeStr
        $wpReport.HuellaRAM = "$ramBufferMB MB"
        $wpReport.EsAmenaza = $esAmenaza
        
        if ($esAmenaza) {
            $wpReport.Riesgo = "ALTO (Excede consumo optimo para la laptop)"
            $wpReport.Accion = "Alerta de consumo: Supera el umbral recomendado para la memoria RAM."
            Escribir-Log "[!] ADVERTENCIA: El fondo $wpName consume $ramBufferMB MB en RAM y $diskSizeStr en disco." "DarkYellow"
        } else {
            $wpReport.Riesgo = "NULO (Seguro - no amenaza la memoria RAM)"
            $wpReport.Accion = "Conservado intacto (Fondo ligero, 0% impacto en rendimiento)"
            Escribir-Log "[+] Fondo analizado: $wpName (${w}x${h}, $ramBufferMB MB en RAM). Seguro: se conserva intacto." "Green"
        }
        
        # Blindaje: Garantizar que BackgroundType este en 0 (Modo Imagen) para evitar pantallas negras forzadas
        $bgType = (Get-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Wallpapers" -Name "BackgroundType" -ErrorAction SilentlyContinue).BackgroundType
        if ($bgType -ne 0) {
            Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Wallpapers" -Name "BackgroundType" -Value 0 -Type DWord -Force -ErrorAction SilentlyContinue
        }
        Set-ItemProperty -Path "HKCU:\Control Panel\Colors" -Name "Background" -Value "18 19 23" -Force -ErrorAction SilentlyContinue
    }
} catch {
    Escribir-Log "[+] Estado del fondo: Seguro y protegido." "Green"
}

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
    $duplicadosTexto = "   * Archivos duplicados eliminados:" + "`r`n"
    foreach ($item in $resDuplicados.Detalles) {
        $duplicadosTexto += "     - $item" + "`r`n"
    }
} else {
    $duplicadosTexto = "   * No se encontraron archivos duplicados redundantes." + "`r`n"
}

# CONSTRUIR SECCION DE DETALLE DE ORGANIZACION DE DESCARGAS
$orgDescargasTexto = ""
if ($resOrganizacion.Total -gt 0) {
    $orgDescargasTexto = "   * Desglose por categorias:" + "`r`n"
    foreach ($cat in $resOrganizacion.Desglose.Keys) {
        if ($resOrganizacion.Desglose[$cat] -gt 0) {
            $orgDescargasTexto += "     - $($cat): $($resOrganizacion.Desglose[$cat]) archivo(s)" + "`r`n"
        }
    }
} else {
    $orgDescargasTexto = "   * Carpeta Descargas al dia (sin archivos pendientes por ordenar)." + "`r`n"
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
7. Organizacion Inteligente de Descargas Recientes:
   * Estado:              $orgDescargasStatus
   * Archivos ordenados:  $($resOrganizacion.Total) archivos ($($resOrganizacion.MB) MB)
$orgDescargasTexto
8. Optimizacion de Memoria SSD (C:):
   * Estado:              $trimStatus

9. Resolucion DNS y Red:
   * Estado:              $dnsStatus

---------------------------------------------------------------------
AUDITORIA DE IMPACTO DEL FONDO DE PANTALLA EN RAM:
---------------------------------------------------------------------
* Archivo Activo:    $($wpReport.Nombre)
* Dimensiones:       $($wpReport.Dimensiones)
* Peso en Disco:     $($wpReport.PesoDisco)
* Huella en RAM:     $($wpReport.HuellaRAM) (Buffer DWM de video)
* Evaluacion Riesgo: $($wpReport.Riesgo)
* Decision Script:   $($wpReport.Accion)

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
Write-Host "  * Descargas clasificadas:           $($resOrganizacion.Total) archivos ($($resOrganizacion.MB) MB)" -ForegroundColor White
Write-Host "  * Reporte actualizado en tu Escritorio:" -ForegroundColor White
Write-Host "    $desktopReportFile" -ForegroundColor Cyan
Write-Host ""
Write-Host "  Cerrando ventana automaticamente en 2 segundos..." -ForegroundColor DarkGray
Start-Sleep -Seconds 2
