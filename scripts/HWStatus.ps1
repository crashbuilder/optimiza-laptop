$dir = $PSScriptRoot
if (-not $dir) { $dir = Split-Path -Parent $MyInvocation.MyCommand.Definition }
Add-Type -Path "$dir\HWStatus.cs" -ReferencedAssemblies System.Windows.Forms, System.Drawing, System.Management
[System.Windows.Forms.Application]::EnableVisualStyles()
[System.Windows.Forms.Application]::SetCompatibleTextRenderingDefault($false)
[System.Windows.Forms.Application]::Run((New-Object HWStatusApp.MainForm))
