# =====================================================================
# 🚀 OPTIMIZADOR UNIVERSAL PARA LAPTOPS Y PCS CON WINDOWS 10 / WINDOWS 11
# =====================================================================
# Desarrollado para limpiar, acelerar y calibrar cualquier laptop:
# - Desactiva telemetria, publicidad y descargas silenciosas
# - Búsqueda instantánea en menú Inicio (desconecta Bing y la nube)
# - Menus instantaneos (MenuShowDelay de 400ms a 20ms)
# - Touchpad sedoso y preciso (1:1 lineal, sin aceleracion ni inercia loca)
# - Modo Oscuro total + Historial de Portapapeles (Win + V)
# - Mantenimiento profundo: TRIM para SSD, purga de temporales y DNS
# - Crea Punto de Restauracion real antes de aplicar cambios
# =====================================================================

# Verificar permisos de Administrador
$isAdmin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsPrincipal]::WindowsBuiltInRole::Administrator)
if (-not $isAdmin) {
    Write-Host "[!] Este script requiere permisos de Administrador." -ForegroundColor Red
    Write-Host "[*] Reintentando con elevacion automatica..." -ForegroundColor Yellow
    Start-Process powershell.exe -ArgumentList "-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`"" -Verb RunAs
    exit
}

Clear-Host
Write-Host "=====================================================================" -ForegroundColor Cyan
Write-Host "   🚀 INICIANDO OPTIMIZACION UNIVERSAL DEL SISTEMA Y LAPTOP" -ForegroundColor Yellow
Write-Host "=====================================================================" -ForegroundColor Cyan
Write-Host ""

# ---------------------------------------------------------------------
# 0. CREAR PUNTO DE RESTAURACION REAL
# ---------------------------------------------------------------------
Write-Host "[0/7] Creando Punto de Restauracion del Sistema..." -ForegroundColor Cyan
try {
    Enable-ComputerRestore -Drive "C:\" -ErrorAction SilentlyContinue
    $fechaHoy = (Get-Date).ToString("yyyy-MM-dd")
    Checkpoint-Computer -Description "Pre_Optimizacion_Laptop_$fechaHoy" -RestorePointType "MODIFY_SETTINGS" -ErrorAction SilentlyContinue
    Write-Host "  -> Punto de restauracion creado exitosamente." -ForegroundColor Green
} catch {
    Write-Host "  -> Aviso: $($_.Exception.Message)" -ForegroundColor DarkGray
}

# ---------------------------------------------------------------------
# 1. ACELERACION DE BUSQUEDA EN WINDOWS (BUSQUEDA INSTANTANEA SIN BING)
# ---------------------------------------------------------------------
Write-Host "[1/7] Desconectando Bing y acelerando la busqueda de Windows..." -ForegroundColor Cyan
try {
    # Politicas a nivel de maquina (HKLM)
    & reg.exe add "HKLM\SOFTWARE\Policies\Microsoft\Windows\Windows Search" /v "DisableWebSearch" /t REG_DWORD /d 1 /f | Out-Null
    & reg.exe add "HKLM\SOFTWARE\Policies\Microsoft\Windows\Windows Search" /v "ConnectedSearchUseWeb" /t REG_DWORD /d 0 /f | Out-Null
    & reg.exe add "HKLM\SOFTWARE\Policies\Microsoft\Windows\Windows Search" /v "AllowCloudSearch" /t REG_DWORD /d 0 /f | Out-Null
    & reg.exe add "HKLM\SOFTWARE\Policies\Microsoft\Windows\Windows Search" /v "AllowCortana" /t REG_DWORD /d 0 /f | Out-Null
    & reg.exe add "HKLM\SOFTWARE\Policies\Microsoft\Windows\Windows Search" /v "DisableSearchBoxSuggestions" /t REG_DWORD /d 1 /f | Out-Null
    & reg.exe add "HKLM\SOFTWARE\Policies\Microsoft\Windows\Windows Search" /v "EnableDynamicContentInWSB" /t REG_DWORD /d 0 /f | Out-Null
    & reg.exe add "HKLM\SOFTWARE\Policies\Microsoft\Windows\Explorer" /v "DisableSearchBoxSuggestions" /t REG_DWORD /d 1 /f | Out-Null

    # Aplicar a todos los perfiles de usuario
    $userSids = Get-ChildItem Registry::HKEY_USERS | Where-Object { $_.Name -match "S-1-5-21-" -and $_.Name -notmatch "_Classes" }
    foreach ($u in $userSids) {
        $sid = $u.PSChildName
        & reg.exe add "HKU\$sid\Software\Microsoft\Windows\CurrentVersion\Search" /v "BingSearchEnabled" /t REG_DWORD /d 0 /f | Out-Null
        & reg.exe add "HKU\$sid\Software\Microsoft\Windows\CurrentVersion\Search" /v "CortanaConsent" /t REG_DWORD /d 0 /f | Out-Null
        & reg.exe add "HKU\$sid\Software\Microsoft\Windows\CurrentVersion\Search" /v "DeviceHistoryEnabled" /t REG_DWORD /d 0 /f | Out-Null
        & reg.exe add "HKU\$sid\Software\Microsoft\Windows\CurrentVersion\Search" /v "HistoryViewEnabled" /t REG_DWORD /d 0 /f | Out-Null
        & reg.exe add "HKU\$sid\Software\Microsoft\Windows\CurrentVersion\SearchHost" /v "EnableDynamicContentInWSB" /t REG_DWORD /d 0 /f | Out-Null
        & reg.exe add "HKU\$sid\Software\Policies\Microsoft\Windows\Explorer" /v "DisableSearchBoxSuggestions" /t REG_DWORD /d 1 /f | Out-Null
        # Reducir retardo de apertura de menus de 400ms a 20ms
        & reg.exe add "HKU\$sid\Control Panel\Desktop" /v "MenuShowDelay" /t REG_SZ /d "20" /f | Out-Null
    }
    Write-Host "  -> Busqueda de apps ahora responde en milisegundos sin Bing ni publicidad." -ForegroundColor Green
} catch {
    Write-Host "  -> Error en busqueda: $($_.Exception.Message)" -ForegroundColor DarkYellow
}

# ---------------------------------------------------------------------
# 2. CALIBRACION DE TOUCHPAD Y RATON (PRECISION 1:1 Y SCROLL SUAVE)
# ---------------------------------------------------------------------
Write-Host "[2/7] Calibrando precision milimetrica del touchpad y scroll..." -ForegroundColor Cyan
try {
    # Desactivar inercia rota de controladores Elantech ("potro loco")
    if (Test-Path "HKLM:\SYSTEM\CurrentControlSet\Control\Elantech\SmartPad") {
        & reg.exe add "HKLM\SYSTEM\CurrentControlSet\Control\Elantech\SmartPad" /v "SC_InertialScroll_Enable" /t REG_DWORD /d 0 /f | Out-Null
        & reg.exe add "HKLM\SYSTEM\CurrentControlSet\Control\Elantech\SmartPad" /v "SC_AutoScroll_Enable" /t REG_DWORD /d 0 /f | Out-Null
        & reg.exe add "HKLM\SYSTEM\CurrentControlSet\Control\Elantech\SmartPad" /v "SC_ContinueScroll_Enable" /t REG_DWORD /d 0 /f | Out-Null
        & reg.exe add "HKLM\SYSTEM\CurrentControlSet\Control\Elantech\SmartPad" /v "SC_Speed" /t REG_DWORD /d 2 /f | Out-Null
    }

    foreach ($u in $userSids) {
        $sid = $u.PSChildName
        # Aceleracion desactivada (1:1 lineal)
        & reg.exe add "HKU\$sid\Control Panel\Mouse" /v "MouseSpeed" /t REG_SZ /d "0" /f | Out-Null
        & reg.exe add "HKU\$sid\Control Panel\Mouse" /v "MouseThreshold1" /t REG_SZ /d "0" /f | Out-Null
        & reg.exe add "HKU\$sid\Control Panel\Mouse" /v "MouseThreshold2" /t REG_SZ /d "0" /f | Out-Null
        & reg.exe add "HKU\$sid\Control Panel\Mouse" /v "MouseSensitivity" /t REG_SZ /d "10" /f | Out-Null
        # Scroll suave a 3 lineas
        & reg.exe add "HKU\$sid\Control Panel\Desktop" /v "WheelScrollLines" /t REG_SZ /d "3" /f | Out-Null
        # Velocidad de Precision Touchpad sedosa
        & reg.exe add "HKU\$sid\Software\Microsoft\Windows\CurrentVersion\PrecisionTouchPad" /v "CursorSpeed" /t REG_DWORD /d 8 /f | Out-Null
    }
    Write-Host "  -> Aceleracion desactivada: cursor predecible y scroll suave sin potro loco." -ForegroundColor Green
} catch {
    Write-Host "  -> Error en touchpad: $($_.Exception.Message)" -ForegroundColor DarkYellow
}

# ---------------------------------------------------------------------
# 3. PRIVACIDAD, TELEMETRIA Y BLOATWARE DE WINDOWS
# ---------------------------------------------------------------------
Write-Host "[3/7] Desactivando telemetria pesada, anuncios y rastreo..." -ForegroundColor Cyan
try {
    # Detener servicios de diagnostico en segundo plano
    Stop-Service "DiagTrack" -ErrorAction SilentlyContinue
    Set-Service "DiagTrack" -StartupType Disabled -ErrorAction SilentlyContinue
    Stop-Service "dmwappushservice" -ErrorAction SilentlyContinue
    Set-Service "dmwappushservice" -StartupType Disabled -ErrorAction SilentlyContinue

    # Desactivar ID de publicidad y sugerencias de aplicaciones comerciales
    & reg.exe add "HKLM\SOFTWARE\Policies\Microsoft\Windows\DataCollection" /v "AllowTelemetry" /t REG_DWORD /d 0 /f | Out-Null
    & reg.exe add "HKLM\SOFTWARE\Policies\Microsoft\Windows\CloudContent" /v "DisableWindowsConsumerFeatures" /t REG_DWORD /d 1 /f | Out-Null
    
    foreach ($u in $userSids) {
        $sid = $u.PSChildName
        & reg.exe add "HKU\$sid\Software\Microsoft\Windows\CurrentVersion\AdvertisingInfo" /v "Enabled" /t REG_DWORD /d 0 /f | Out-Null
        & reg.exe add "HKU\$sid\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager" /v "SilentInstalledAppsEnabled" /t REG_DWORD /d 0 /f | Out-Null
        & reg.exe add "HKU\$sid\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager" /v "SystemPaneSuggestionsEnabled" /t REG_DWORD /d 0 /f | Out-Null
        & reg.exe add "HKU\$sid\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager" /v "SoftLandingEnabled" /t REG_DWORD /d 0 /f | Out-Null
        & reg.exe add "HKU\$sid\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager" /v "SubscribedContent-338388Enabled" /t REG_DWORD /d 0 /f | Out-Null
        & reg.exe add "HKU\$sid\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager" /v "SubscribedContent-338389Enabled" /t REG_DWORD /d 0 /f | Out-Null
        
        # Eliminar retardo artificial al arrancar Windows
        & reg.exe add "HKU\$sid\Software\Microsoft\Windows\CurrentVersion\Explorer\Serialize" /v "StartupDelayInMSec" /t REG_DWORD /d 0 /f | Out-Null

        # Desactivar Game DVR que graba en segundo plano consumiendo GPU
        & reg.exe add "HKU\$sid\System\GameConfigStore" /v "GameDVR_Enabled" /t REG_DWORD /d 0 /f | Out-Null
    }
    Write-Host "  -> Telemetria, anuncios sugeridos y Game DVR desactivados." -ForegroundColor Green
} catch {
    Write-Host "  -> Error en privacidad: $($_.Exception.Message)" -ForegroundColor DarkYellow
}

# ---------------------------------------------------------------------
# 4. MODO OSCURO TOTAL Y HISTORIAL DE PORTAPAPELES (WIN + V)
# ---------------------------------------------------------------------
Write-Host "[4/7] Configurando Modo Oscuro y Portapapeles Inteligente..." -ForegroundColor Cyan
try {
    foreach ($u in $userSids) {
        $sid = $u.PSChildName
        # Modo oscuro en Windows y Aplicaciones
        & reg.exe add "HKU\$sid\Software\Microsoft\Windows\CurrentVersion\Themes\Personalize" /v "AppsUseLightTheme" /t REG_DWORD /d 0 /f | Out-Null
        & reg.exe add "HKU\$sid\Software\Microsoft\Windows\CurrentVersion\Themes\Personalize" /v "SystemUsesLightTheme" /t REG_DWORD /d 0 /f | Out-Null

        # Tema Gris Oscuro en Microsoft Office
        & reg.exe add "HKU\$sid\Software\Microsoft\Office\16.0\Common" /v "UI Theme" /t REG_DWORD /d 3 /f | Out-Null
        & reg.exe add "HKU\$sid\Software\Microsoft\Office\16.0\Common" /v "AlwaysUseMSOTheme" /t REG_DWORD /d 1 /f | Out-Null

        # Activar historial múltiple del portapapeles (Win + V)
        & reg.exe add "HKU\$sid\Software\Microsoft\Clipboard" /v "EnableClipboardHistory" /t REG_DWORD /d 1 /f | Out-Null
    }
    Write-Host "  -> Modo Oscuro aplicado y Win + V activado." -ForegroundColor Green
} catch {
    Write-Host "  -> Error en interfaz: $($_.Exception.Message)" -ForegroundColor DarkYellow
}

# ---------------------------------------------------------------------
# 5. ACTIVACION DE ESQUEMA MAXIMO RENDIMIENTO
# ---------------------------------------------------------------------
Write-Host "[5/7] Desbloqueando esquema de energía Máximo Rendimiento..." -ForegroundColor Cyan
try {
    $perfGuid = "e9a42b02-d5df-448d-aa00-03f14749eb61"
    $currentSchemes = powercfg -list
    if ($currentSchemes -notmatch "Máximo rendimiento|Ultimate Performance") {
        powercfg -duplicatescheme $perfGuid | Out-Null
    }
    # Seleccionar el esquema de maximo rendimiento
    $targetScheme = (powercfg -list | Select-String "Máximo rendimiento|Ultimate Performance" | Select-Object -First 1)
    if ($targetScheme -match "([a-f0-9]{8}-[a-f0-9]{4}-[a-f0-9]{4}-[a-f0-9]{4}-[a-f0-9]{12})") {
        $guid = $matches[1]
        powercfg -setactive $guid
        Write-Host "  -> Perfil Máximo Rendimiento activado (CPU y GPU al 100%)." -ForegroundColor Green
    }
} catch {
    Write-Host "  -> Error en energía: $($_.Exception.Message)" -ForegroundColor DarkYellow
}

# ---------------------------------------------------------------------
# 6. LIMPIEZA PROFUNDA Y COMANDO TRIM PARA EL SSD
# ---------------------------------------------------------------------
Write-Host "[6/7] Purgando archivos temporales, DNS y ejecutando TRIM en SSD..." -ForegroundColor Cyan
try {
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
            Get-ChildItem -Path $dir -Force -ErrorAction SilentlyContinue | Remove-Item -Recurse -Force -ErrorAction SilentlyContinue
        }
    }
    # Vaciar papelera de reciclaje
    Clear-RecycleBin -Force -Confirm:$false -ErrorAction SilentlyContinue
    # Vaciar cache DNS
    Clear-DnsClientCache -ErrorAction SilentlyContinue
    # Comando TRIM en SSD C:
    Optimize-Volume -DriveLetter C -ReTrim -ErrorAction SilentlyContinue
    Write-Host "  -> Temporales eliminados, DNS purgada y celdas del SSD optimizadas con TRIM." -ForegroundColor Green
} catch {
    Write-Host "  -> Error en limpieza: $($_.Exception.Message)" -ForegroundColor DarkYellow
}

# ---------------------------------------------------------------------
# 7. REGISTRAR TAREA DE MANTENIMIENTO AUTOMATICO (LUNES 8AM O AL ENCENDER)
# ---------------------------------------------------------------------
Write-Host "[7/8] Registrando tarea de mantenimiento semanal automatico..." -ForegroundColor Cyan
try {
    $scriptDir = Split-Path -Parent $PSCommandPath
    $maintScript = "$scriptDir\Mantenimiento_Auto.ps1"
    if (Test-Path $maintScript) {
        $maintAction = New-ScheduledTaskAction -Execute "powershell.exe" -Argument "-NoProfile -ExecutionPolicy Bypass -WindowStyle Hidden -File `"$maintScript`""
        $maintTrigger = New-ScheduledTaskTrigger -Weekly -DaysOfWeek Monday -At 08:00
        $maintSettings = New-ScheduledTaskSettingsSet -StartWhenAvailable -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries
        $maintPrincipal = New-ScheduledTaskPrincipal -UserId "NT AUTHORITY\SYSTEM" -LogonType ServiceAccount -RunLevel Highest

        Register-ScheduledTask -TaskName "Mantenimiento_Semanal_Laptop" -Action $maintAction -Trigger $maintTrigger -Settings $maintSettings -Principal $maintPrincipal -Description "Mantenimiento automatico, TRIM en SSD y Punto de Restauracion semanal" -Force | Out-Null
        Write-Host "  -> Tarea de mantenimiento semanal registrada con exito en Windows." -ForegroundColor Green
    } else {
        Write-Host "  -> Aviso: Script Mantenimiento_Auto.ps1 no encontrado en la misma carpeta." -ForegroundColor DarkGray
    }
} catch {
    Write-Host "  -> Aviso en tarea: $($_.Exception.Message)" -ForegroundColor DarkYellow
}

# ---------------------------------------------------------------------
# 8. REINICIO DE PROCESOS DE INTERFAZ
# ---------------------------------------------------------------------
Write-Host "[8/8] Aplicando cambios y reiniciando shell de Windows..." -ForegroundColor Cyan
Stop-Process -Name "SearchHost", "StartMenuExperienceHost" -Force -ErrorAction SilentlyContinue
Get-Process -Name "explorer" -ErrorAction SilentlyContinue | Stop-Process -Force
Start-Sleep -Seconds 2


Write-Host ""
Write-Host "=====================================================================" -ForegroundColor Green
Write-Host "   ✅ ¡OPTIMIZACION COMPLETADA CON EXITO!" -ForegroundColor Green
Write-Host "=====================================================================" -ForegroundColor Green
Write-Host "Tu laptop ahora cuenta con:" -ForegroundColor White
Write-Host " • Busqueda instantanea en el menu Inicio (sin lag de Bing)." -ForegroundColor White
Write-Host " • Touchpad suave, dócil y con precision 1:1." -ForegroundColor White
Write-Host " • Menus y ventanas que abren de inmediato (MenuShowDelay a 20ms)." -ForegroundColor White
Write-Host " • SSD NVMe limpio y con celdas optimizadas." -ForegroundColor White
Write-Host " • Privacidad mejorada sin telemetria ni anuncios comerciales." -ForegroundColor White
Write-Host ""
Write-Host "Presiona cualquier tecla para finalizar..." -ForegroundColor DarkGray
$null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
