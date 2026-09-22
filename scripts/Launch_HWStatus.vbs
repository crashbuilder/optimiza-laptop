Set WshShell = CreateObject("WScript.Shell")
WshShell.Run "schtasks.exe /run /tn ""HWStatus_Elevated""", 0, False
