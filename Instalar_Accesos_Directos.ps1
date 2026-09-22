# =====================================================================
# INSTALADOR 1-CLIC DE ACCESOS DIRECTOS Y HERRAMIENTAS - OPTIMIZA LAPTOP
# =====================================================================
$baseDir = Split-Path -Parent $MyInvocation.MyCommand.Definition
$desktop = [Environment]::GetFolderPath("Desktop")
$wsh = New-Object -ComObject WScript.Shell

Write-Host "=====================================================" -ForegroundColor Cyan
Write-Host " Instalando Herramientas de Optimizacion en Escritorio" -ForegroundColor Yellow
Write-Host "=====================================================" -ForegroundColor Cyan

# 1. Estado del PC (HW Monitor)
$s1 = $wsh.CreateShortcut("$desktop\Estado del PC (HW Monitor).lnk")
$s1.TargetPath = "wscript.exe"
$s1.Arguments = "`"$baseDir\scripts\Launch_HWStatus.vbs`""
$s1.WorkingDirectory = "$baseDir\scripts"
$s1.IconLocation = "$baseDir\icons\HW_Monitor.ico,0"
$s1.Description = "Monitor de Hardware, Temperaturas en Vivo y Bateria"
$s1.Save()
Write-Host "[+] Acceso directo creado: Estado del PC (HW Monitor)" -ForegroundColor Green

# 2. Sonido y Ecualizador (AudioHub)
$s2 = $wsh.CreateShortcut("$desktop\Sonido y Ecualizador (AudioHub).lnk")
$s2.TargetPath = "wscript.exe"
$s2.Arguments = "`"$baseDir\scripts\Launch_AudioHub.vbs`""
$s2.WorkingDirectory = "$baseDir\scripts"
$s2.IconLocation = "$baseDir\icons\Audio_Equalizer.ico,0"
$s2.Description = "Centro de Control de Sonido, Ecualizador Dolby y Super Booster 200%"
$s2.Save()
Write-Host "[+] Acceso directo creado: Sonido y Ecualizador (AudioHub)" -ForegroundColor Green

# 3. Maximo Rendimiento
$s3 = $wsh.CreateShortcut("$desktop\Maximo Rendimiento.lnk")
$s3.TargetPath = "$baseDir\scripts\Modo_MaximoRendimiento.bat"
$s3.WorkingDirectory = "$baseDir\scripts"
$s3.IconLocation = "$baseDir\icons\Max_Rendimiento.ico,0"
$s3.Description = "Desbloquea el 100% de CPU y graficos para trabajar con cargador"
$s3.Save()
Write-Host "[+] Acceso directo creado: Maximo Rendimiento" -ForegroundColor Green

# 4. Super Eco Bateria
$s4 = $wsh.CreateShortcut("$desktop\Super Eco Bateria.lnk")
$s4.TargetPath = "$baseDir\scripts\Modo_SuperEco.bat"
$s4.WorkingDirectory = "$baseDir\scripts"
$s4.IconLocation = "$baseDir\icons\Hoja_Eco.ico,0"
$s4.Description = "Modo ultra ahorro de bateria y ventiladores silenciosos"
$s4.Save()
Write-Host "[+] Acceso directo creado: Super Eco Bateria" -ForegroundColor Green

# 5. Limpieza y Optimizacion
$s5 = $wsh.CreateShortcut("$desktop\Limpieza y Optimizacion.lnk")
$s5.TargetPath = "powershell.exe"
$s5.Arguments = "-NoProfile -ExecutionPolicy Bypass -File `"$baseDir\scripts\Mantenimiento_Auto.ps1`""
$s5.WorkingDirectory = "$baseDir\scripts"
$s5.IconLocation = "$baseDir\icons\Limpieza_PC.ico,0"
$s5.Description = "Mantenimiento profundo, TRIM en SSD y Punto de Restauracion"
$s5.Save()
Write-Host "[+] Acceso directo creado: Limpieza y Optimizacion" -ForegroundColor Green

Write-Host "`n¡Instalacion completada con exito en tu Escritorio!" -ForegroundColor Cyan
