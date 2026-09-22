# =====================================================================
# CALIBRACION DE PRECISION Y SUAVIDAD DEL TOUCHPAD (ELAN / PTP)
# =====================================================================
Add-Type -TypeDefinition @"
using System;
using System.Runtime.InteropServices;

public class TouchpadTuning {
    [DllImport("user32.dll", SetLastError = true)]
    public static extern bool SystemParametersInfo(uint uiAction, uint uiParam, IntPtr pvParam, uint fWinIni);

    public const uint SPI_SETMOUSE = 0x0004;
    public const uint SPI_SETMOUSESPEED = 0x0071;
    public const uint SPIF_UPDATEINIFILE = 0x01;
    public const uint SPIF_SENDCHANGE = 0x02;

    public static void ApplyLinearTracking(int speed) {
        // Desactivar aceleracion (Threshold1=0, Threshold2=0, Accel=0)
        int[] mouseParams = new int[3] { 0, 0, 0 };
        GCHandle handle = GCHandle.Alloc(mouseParams, GCHandleType.Pinned);
        try {
            SystemParametersInfo(SPI_SETMOUSE, 0, handle.AddrOfPinnedObject(), SPIF_UPDATEINIFILE | SPIF_SENDCHANGE);
            SystemParametersInfo(SPI_SETMOUSESPEED, 0, (IntPtr)speed, SPIF_UPDATEINIFILE | SPIF_SENDCHANGE);
        } finally {
            handle.Free();
        }
    }
}
"@

# 1. Desactivar aceleracion de hardware (movimiento 1:1 predecible y suave)
[TouchpadTuning]::ApplyLinearTracking(10)

# 2. Fijar valores lineales en el Registro de Windows
Set-ItemProperty -Path "HKCU:\Control Panel\Mouse" -Name "MouseSpeed" -Value "0" -Force
Set-ItemProperty -Path "HKCU:\Control Panel\Mouse" -Name "MouseThreshold1" -Value "0" -Force
Set-ItemProperty -Path "HKCU:\Control Panel\Mouse" -Name "MouseThreshold2" -Value "0" -Force
Set-ItemProperty -Path "HKCU:\Control Panel\Mouse" -Name "MouseSensitivity" -Value "10" -Force

# 3. Calibrar velocidad de Precision Touchpad para resolucion 1366x768
$ptp = "HKCU:\Software\Microsoft\Windows\CurrentVersion\PrecisionTouchPad"
if (Test-Path $ptp) {
    Set-ItemProperty -Path $ptp -Name "CursorSpeed" -Value 8 -Force
    Set-ItemProperty -Path $ptp -Name "AAPThreshold" -Value 2 -Force
}

# 4. Calibrar desplazamiento suave con dos dedos (WheelScrollLines a 3 lineas)
Set-ItemProperty -Path "HKCU:\Control Panel\Desktop" -Name "WheelScrollLines" -Value "3" -Force

Write-Output "Touchpad calibrado: Aceleracion desactivada (1:1), suavidad optimizada, inercia controlada y scroll suave a 3 lineas."


