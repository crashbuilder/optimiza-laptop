# =====================================================================
# INSTALADOR 1-CLIC DE HERRAMIENTAS Y TAREAS - OPTIMIZA LAPTOP
# =====================================================================
$baseDir = Split-Path -Parent $MyInvocation.MyCommand.Definition
if (-not $baseDir) { $baseDir = $PSScriptRoot }
$desktop = [Environment]::GetFolderPath("Desktop")
$wsh = New-Object -ComObject WScript.Shell

# 0. Verificar y solicitar permisos de Administrador
$isAdmin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsPrincipal]::WindowsBuiltInRole::Administrator)
if (-not $isAdmin) {
    Write-Host "[*] Solicitando permisos de Administrador para registrar tareas y accesos..." -ForegroundColor Yellow
    Start-Process powershell.exe -ArgumentList "-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`"" -Verb RunAs
    exit
}

Clear-Host
Write-Host "=====================================================================" -ForegroundColor Cyan
Write-Host "   ⚙️ INSTALANDO SUITE DE HERRAMIENTAS Y TAREAS AUTOMATICAS" -ForegroundColor Yellow
Write-Host "=====================================================================" -ForegroundColor Cyan
Write-Host ""

# 1. Registrar Tarea de HWStatus para leer sensores termicos sin UAC
Write-Host "[1/3] Registrando tarea de hardware (HWStatus_Elevated)..." -ForegroundColor Cyan
try {
    $hwAction = New-ScheduledTaskAction -Execute "powershell.exe" -Argument "-NoProfile -ExecutionPolicy Bypass -WindowStyle Hidden -File `"$baseDir\scripts\HWStatus.ps1`""
    $hwPrincipal = New-ScheduledTaskPrincipal -UserId $env:USERNAME -LogonType Interactive -RunLevel Highest
    $hwSettings = New-ScheduledTaskSettingsSet -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries
    Register-ScheduledTask -TaskName "HWStatus_Elevated" -Action $hwAction -Principal $hwPrincipal -Settings $hwSettings -Description "Monitor de Hardware y Temperaturas sin UAC" -Force | Out-Null
    Write-Host "  -> Tarea de monitoreo de temperaturas registrada con exito." -ForegroundColor Green
} catch {
    Write-Host "  -> Aviso en tarea HWStatus: $($_.Exception.Message)" -ForegroundColor DarkYellow
}

# 2. Registrar Tarea de Mantenimiento Semanal Automatico (Lunes 8:00 AM o al encender)
Write-Host "[2/3] Registrando Tarea de Mantenimiento y Punto de Restauracion Semanal..." -ForegroundColor Cyan
try {
    Enable-ComputerRestore -Drive "C:\" -ErrorAction SilentlyContinue
    Set-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\SystemRestore" -Name "SystemRestorePointCreationFrequency" -Value 0 -Type DWord -Force -ErrorAction SilentlyContinue
    
    $maintScript = "$baseDir\scripts\Mantenimiento_Auto.ps1"
    $maintAction = New-ScheduledTaskAction -Execute "powershell.exe" -Argument "-NoProfile -ExecutionPolicy Bypass -WindowStyle Hidden -File `"$maintScript`""
    $maintTrigger = New-ScheduledTaskTrigger -Weekly -DaysOfWeek Monday -At 08:00
    $maintSettings = New-ScheduledTaskSettingsSet -StartWhenAvailable -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries
    $maintPrincipal = New-ScheduledTaskPrincipal -UserId "NT AUTHORITY\SYSTEM" -LogonType ServiceAccount -RunLevel Highest

    Register-ScheduledTask -TaskName "Mantenimiento_Semanal_Laptop" -Action $maintAction -Trigger $maintTrigger -Settings $maintSettings -Principal $maintPrincipal -Description "Mantenimiento automatico, TRIM en SSD y Punto de Restauracion semanal" -Force | Out-Null
    Write-Host "  -> Tarea programada 'Mantenimiento_Semanal_Laptop' registrada con exito." -ForegroundColor Green
} catch {
    Write-Host "  -> Aviso en tarea mantenimiento: $($_.Exception.Message)" -ForegroundColor DarkYellow
}

# 3. Crear Accesos Directos en el Escritorio
Write-Host "[3/3] Creando accesos directos con iconos de alta resolucion en Escritorio..." -ForegroundColor Cyan

# 3.1 Estado del PC (HW Monitor)
$s1 = $wsh.CreateShortcut("$desktop\Estado del PC (HW Monitor).lnk")
$s1.TargetPath = "wscript.exe"
$s1.Arguments = "`"$baseDir\scripts\Launch_HWStatus.vbs`""
$s1.WorkingDirectory = "$baseDir\scripts"
$s1.IconLocation = "$baseDir\icons\HW_Monitor.ico,0"
$s1.Description = "Monitor de Hardware, Temperaturas en Vivo y Bateria"
$s1.Save()
Write-Host "  [+] Estado del PC (HW Monitor)" -ForegroundColor Green

# 3.2 Sonido y Ecualizador (AudioHub)
$s2 = $wsh.CreateShortcut("$desktop\Sonido y Ecualizador (AudioHub).lnk")
$s2.TargetPath = "wscript.exe"
$s2.Arguments = "`"$baseDir\scripts\Launch_AudioHub.vbs`""
$s2.WorkingDirectory = "$baseDir\scripts"
$s2.IconLocation = "$baseDir\icons\Audio_Equalizer.ico,0"
$s2.Description = "Centro de Control de Sonido, Ecualizador Dolby y Super Booster 200%"
$s2.Save()
Write-Host "  [+] Sonido y Ecualizador (AudioHub)" -ForegroundColor Green

# 3.3 Maximo Rendimiento
$s3 = $wsh.CreateShortcut("$desktop\Maximo Rendimiento.lnk")
$s3.TargetPath = "$baseDir\scripts\Modo_MaximoRendimiento.bat"
$s3.WorkingDirectory = "$baseDir\scripts"
$s3.IconLocation = "$baseDir\icons\Max_Rendimiento.ico,0"
$s3.Description = "Desbloquea el 100% de CPU y graficos para trabajar con cargador"
$s3.Save()
Write-Host "  [+] Maximo Rendimiento" -ForegroundColor Green

# 3.4 Super Eco Bateria
$s4 = $wsh.CreateShortcut("$desktop\Super Eco Bateria.lnk")
$s4.TargetPath = "$baseDir\scripts\Modo_SuperEco.bat"
$s4.WorkingDirectory = "$baseDir\scripts"
$s4.IconLocation = "$baseDir\icons\Hoja_Eco.ico,0"
$s4.Description = "Modo ultra ahorro de bateria y ventiladores silenciosos"
$s4.Save()
Write-Host "  [+] Super Eco Bateria" -ForegroundColor Green

# 3.5 Limpieza y Optimizacion
$s5 = $wsh.CreateShortcut("$desktop\Limpieza y Optimizacion.lnk")
$s5.TargetPath = "powershell.exe"
$s5.Arguments = "-NoProfile -ExecutionPolicy Bypass -File `"$baseDir\scripts\Mantenimiento_Auto.ps1`""
$s5.WorkingDirectory = "$baseDir\scripts"
$s5.IconLocation = "$baseDir\icons\Limpieza_PC.ico,0"
$s5.Description = "Mantenimiento profundo, TRIM en SSD y Punto de Restauracion"
$s5.Save()
Write-Host "  [+] Limpieza y Optimizacion" -ForegroundColor Green

Write-Host ""
Write-Host "=====================================================================" -ForegroundColor Green
Write-Host "   ✅ ¡INSTALACION Y CONFIGURACION COMPLETADAS CON EXITO!" -ForegroundColor Green
Write-Host "=====================================================================" -ForegroundColor Green
Write-Host " • Tarea semanal de mantenimiento activa (Lunes 8:00 AM o al encender)." -ForegroundColor White
Write-Host " • Monitor de temperaturas configurado sin avisos de UAC." -ForegroundColor White
Write-Host " • 5 accesos directos creados en tu Escritorio." -ForegroundColor White
Write-Host ""
Write-Host "Presiona cualquier tecla para finalizar..." -ForegroundColor DarkGray
$null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
