# Startup script for suppressing SolidWorks prompts
# Run as scheduled task at every login?

# SolidWorks 2020
$solid = "Registry::\HKCU\Software\SolidWorks\SolidWorks 2020\Security"
If (!(Test-Path $solid)){New-Item -Path $solid -force}
New-ItemProperty -Path $solid -Name "EULA Accepted 2020 SP3.0 $env:ComputerName $env:UserName" -Value "Yes" -PropertyType "string" -force

$composer = "Registry::\HKCU\Software\Dassault Systemes\Composer\7.6\Preferences"
If (!(Test-Path $composer)){New-Item -Path $composer -force}
New-ItemProperty -Path $composer -Name "Composer.EulaAccepted" -Value "0" -PropertyType "DWORD" -Force
New-ItemProperty -Path $composer -Name "EulaAccepted" -Value "0" -PropertyType "DWORD" -Force
New-ItemProperty -Path $composer -Name "EulaAccepted 2020 7.6.5.1481 $env:ComputerName $env:Username" -Value "1" -PropertyType "DWORD" -Force
New-ItemProperty -Path $composer -Name "RefreshProgressUI" -Value "1" -PropertyType "DWORD" -Force
New-ItemProperty -Path $composer -Name "Sync.EulaAccepted" -Value "0" -PropertyType "DWORD" -Force

# eDrawings
$eDraw = "Registry::\HKCU\Software\eDrawings\e2020\General"
If (!(Test-Path $eDraw)){New-Item -Path $eDraw -force}
New-ItemProperty -Path $eDraw -Name "ShowLicense 2020 sp3 $env:ComputerName $env:UserName" -Value "0" -PropertyType "DWORD" -Force
