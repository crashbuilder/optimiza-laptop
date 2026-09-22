Set WshShell = CreateObject("WScript.Shell")
scriptDir = CreateObject("Scripting.FileSystemObject").GetParentFolderName(WScript.ScriptFullName)
On Error Resume Next
res = WshShell.Run("schtasks.exe /run /tn ""HWStatus_Elevated""", 0, True)
If res <> 0 Then
    WshShell.Run "powershell.exe -NoProfile -ExecutionPolicy Bypass -WindowStyle Hidden -File """ & scriptDir & "\HWStatus.ps1""", 0, False
End If
