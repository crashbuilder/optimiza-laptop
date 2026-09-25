Add-Type -Path "C:\Users\Usuario\Scripts\BatteryHub.cs" -ReferencedAssemblies System.Windows.Forms, System.Drawing, System.Management
[System.Windows.Forms.Application]::EnableVisualStyles()
[System.Windows.Forms.Application]::SetCompatibleTextRenderingDefault($false)
[System.Windows.Forms.Application]::Run((New-Object BatteryHubApp.MainForm))
