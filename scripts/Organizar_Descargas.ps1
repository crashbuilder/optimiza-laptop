# =====================================================================
# ORGANIZADOR INTELIGENTE DE CARPETA DE DESCARGAS
# =====================================================================
# Organiza automaticamente los archivos de Descargas en carpetas tematicas:
# - Videos
# - Imágenes
# - Documentos
#     ├── Word
#     ├── PDF
#     ├── Excel
#     ├── PowerPoint
#     ├── Datos Geográficos (Shapefiles, GDB, KML, GeoJSON, QGIS, etc.)
#     └── Instaladores (EXE, MSI, APK, ISO, etc.)
# =====================================================================
param(
    [string]$DownloadsPath = "$env:USERPROFILE\Downloads",
    [switch]$Silencioso
)

$OutputEncoding = [System.Text.Encoding]::UTF8
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8

function Invoke-OrganizarDescargas {
    param(
        [string]$RutaDescargas = "$env:USERPROFILE\Downloads",
        [switch]$ModoSilencioso
    )

    if (-not (Test-Path $RutaDescargas)) {
        if (-not $ModoSilencioso) { Write-Host "[-] No se encontro la carpeta de Descargas: $RutaDescargas" -ForegroundColor Yellow }
        return [PSCustomObject]@{
            Total = 0
            MB = 0
            Desglose = @{}
            Detalles = @()
        }
    }

    $strA_acc = [char]0x00E1 # á
    $nomImagenes = "Im" + $strA_acc + "genes"
    $nomDatosGeo = "Datos Geogr" + $strA_acc + "ficos"

    if (-not $ModoSilencioso) {
        Write-Host "=====================================================================" -ForegroundColor Cyan
        Write-Host "   ORGANIZADOR INTELIGENTE DE DESCARGAS                              " -ForegroundColor Yellow
        Write-Host "=====================================================================" -ForegroundColor Cyan
        Write-Host "  Ruta analizada: $RutaDescargas" -ForegroundColor DarkCyan
        Write-Host ""
    }

    # 1. Definir rutas de destino
    $dirVideos       = Join-Path $RutaDescargas "Videos"
    $dirImagenes     = Join-Path $RutaDescargas $nomImagenes
    $dirDocumentos   = Join-Path $RutaDescargas "Documentos"

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

    # 2. Asegurar existencia de las carpetas
    foreach ($c in $todasCarpetas) {
        if (-not (Test-Path $c)) {
            New-Item -Path $c -ItemType Directory -Force -ErrorAction SilentlyContinue | Out-Null
        }
    }

    # 3. Unificar carpeta previa de Instaladores si existia en la raiz de Descargas
    $dirInstaladoresLegacy = Join-Path $RutaDescargas "Instaladores"
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

    # 4. Extensiones por categoria
    $extVideos = @('.mp4', '.mkv', '.avi', '.mov', '.wmv', '.flv', '.webm', '.m4v', '.3gp', '.mpeg', '.mpg', '.ts')
    $extImagenes = @('.jpg', '.jpeg', '.png', '.gif', '.bmp', '.webp', '.svg', '.ico', '.tiff', '.tif', '.raw', '.cr2', '.nef', '.heic', '.psd')
    $extWord = @('.docx', '.doc', '.docm', '.dotx', '.dot', '.odt', '.rtf')
    $extPdf = @('.pdf')
    $extExcel = @('.xlsx', '.xls', '.xlsm', '.xlsb', '.xltx', '.csv', '.tsv', '.ods')
    $extPowerPoint = @('.pptx', '.ppt', '.pptm', '.potx', '.pot', '.ppsx', '.pps', '.odp')
    $extInstaladores = @('.exe', '.msi', '.apk', '.iso', '.img', '.appx', '.msix', '.msixbundle')
    $extGeo = @('.shp', '.shx', '.dbf', '.prj', '.cpg', '.sbn', '.sbx', '.fbn', '.fbx', '.ain', '.aih', '.ixs', '.mxs', '.atx', '.geojson', '.kml', '.kmz', '.gpkg', '.gdb', '.qgz', '.qgs', '.dem', '.asc', '.laz', '.las', '.ecw', '.sid')

    # Contadores y acumuladores
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

    # 5. Obtener unicamente archivos sueltos en la raiz de Descargas
    $archivosDescargas = Get-ChildItem -Path $RutaDescargas -File -Force -ErrorAction SilentlyContinue | Where-Object {
        $_.Name -notmatch '^(desktop\.ini|thumbs\.db)$' -and
        $_.Extension -notmatch '^\.(tmp|crdownload|part|download|partial)$'
    }

    foreach ($archivo in $archivosDescargas) {
        $ext = $archivo.Extension.ToLower()
        $nombre = $archivo.Name
        $tamano = $archivo.Length
        $carpetaDestino = $null
        $categoriaNombre = $null

        # Clasificacion por extension directa
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
            # Clasificacion inteligente de archivos comprimidos
            # Criterio A: Nombre con palabras clave geograficas o cartograficas
            if ($nombre -match 'SHP_|VEREDAS|DEPTO|MPIO|GDB|RUNAP|IGAC|DANE|CORPOGUAJIRA|GEO|MAPA|CUENCA|CATASTRO|PREDIO|CARTOGRAFIA|SUELOS') {
                $carpetaDestino = $dirGeo
                $categoriaNombre = $nomDatosGeo
            } else {
                # Criterio B: Inspeccionar contenido interno con tar rapido
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

        # Si se identifico un destino, mover de forma segura
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
                if (-not $ModoSilencioso) {
                    Write-Host "  [-] Error al mover $($nombre): $($_.Exception.Message)" -ForegroundColor Red
                }
            }
        }
    }

    # 7. Censo total de archivos organizados por carpeta
    $censoCarpetas = [ordered]@{
        "Documentos\Word"              = @{ Ruta = $dirWord;         Archivos = 0; MB = 0 }
        "Documentos\PDF"               = @{ Ruta = $dirPdf;          Archivos = 0; MB = 0 }
        "Documentos\Excel"             = @{ Ruta = $dirExcel;        Archivos = 0; MB = 0 }
        "Documentos\PowerPoint"        = @{ Ruta = $dirPowerPoint;   Archivos = 0; MB = 0 }
        "Documentos\Datos Geograficos" = @{ Ruta = $dirGeo;          Archivos = 0; MB = 0 }
        "Documentos\Instaladores"      = @{ Ruta = $dirInstaladores; Archivos = 0; MB = 0 }
        "Imagenes"                     = @{ Ruta = $dirImagenes;     Archivos = 0; MB = 0 }
        "Videos"                       = @{ Ruta = $dirVideos;       Archivos = 0; MB = 0 }
    }
    
    $totalExistentes = 0
    $totalExistentesBytes = 0
    foreach ($k in $censoCarpetas.Keys) {
        $p = $censoCarpetas[$k].Ruta
        if (Test-Path $p) {
            $fls = Get-ChildItem -Path $p -File -Force -ErrorAction SilentlyContinue
            $cnt = $fls.Count
            $bts = ($fls | Measure-Object -Property Length -Sum).Sum
            if (-not $bts) { $bts = 0 }
            $censoCarpetas[$k].Archivos = $cnt
            $censoCarpetas[$k].MB = [Math]::Round($bts / 1MB, 2)
            $totalExistentes += $cnt
            $totalExistentesBytes += $bts
        }
    }

    $totalMB = [Math]::Round($totalBytes / 1MB, 2)

    # 6. Mostrar resultados en consola si no es silencioso
    if (-not $ModoSilencioso) {
        if ($totalMovidos -gt 0) {
            Write-Host "[+] Organizacion completada exitosamente:" -ForegroundColor Green
            Write-Host "    Total de archivos nuevos clasificados: $totalMovidos ($totalMB MB)" -ForegroundColor White
            Write-Host ""
            Write-Host "  * Nuevas descargas clasificadas:" -ForegroundColor Cyan
            foreach ($cat in $desglose.Keys) {
                if ($desglose[$cat] -gt 0) {
                    Write-Host "    + $($cat): $($desglose[$cat]) archivo(s)" -ForegroundColor White
                }
            }
            Write-Host ""
        } else {
            Write-Host "[+] Tu carpeta de Descargas se encuentra al dia (sin archivos sueltos en la raiz)." -ForegroundColor Green
        }

        Write-Host "  * Censo de archivos organizados por carpeta ($totalExistentes en total):" -ForegroundColor Cyan
        foreach ($k in $censoCarpetas.Keys) {
            $cArch = $censoCarpetas[$k].Archivos
            $cMB = $censoCarpetas[$k].MB
            Write-Host "    - $($k): $cArch archivo(s) ($cMB MB)" -ForegroundColor Gray
        }
        Write-Host ""
    }

    return [PSCustomObject]@{
        Total           = $totalMovidos
        Bytes           = $totalBytes
        MB              = $totalMB
        Desglose        = $desglose
        Detalles        = $detalles
        Censo           = $censoCarpetas
        TotalExistentes = $totalExistentes
        MBExistentes    = [Math]::Round($totalExistentesBytes / 1MB, 2)
    }
}

# Ejecucion directa
$resultado = Invoke-OrganizarDescargas -RutaDescargas $DownloadsPath -ModoSilencioso:$Silencioso
if (-not $Silencioso) {
    Write-Host "Presiona cualquier tecla o espera 3 segundos para cerrar..." -ForegroundColor DarkGray
    Start-Sleep -Seconds 3
}
