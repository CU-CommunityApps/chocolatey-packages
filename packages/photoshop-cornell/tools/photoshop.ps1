# Hide powershell.exe window while running
Add-Type -Name win -MemberDefinition '[DllImport("user32.dll")] public static extern bool ShowWindow(int handle, int state);' -Namespace native
[native.win]::ShowWindow(([System.Diagnostics.Process]::GetCurrentProcess() | Get-Process).MainWindowHandle,0)

$wshell = New-Object -ComObject Wscript.Shell
$ans = $wshell.Popup("This application can only be used from a Cornell owned device, click OK to continue or Cancel to close",0,"Adobe License Requirement",1)
If ($ans -eq 1){& "$env:ProgramFiles\Adobe\Adobe Photoshop CC 2018\Photoshop.exe"}
Else {exit 1}
