# Startup script for suppressing SolidWorks prompts
# Run as scheduled task at every login?

# SolidWorks 2018
$solid = "Registry::\HKCU\Software\SolidWorks\SolidWorks 2018\Security"
If (!(Test-Path $solid)){New-Item -Path $solid -force}
New-ItemProperty -Path $solid -Name "EULA Accepted 2018 SP4.0 $env:ComputerName $env:UserName" -Value "Yes" -PropertyType "string" -force

$composer = "Registry::\HKCU\Software\Dassault Systemes\Composer\7.5\Preferences"
If (!(Test-Path $composer)){New-Item -Path $composer -force}
New-ItemProperty -Path $composer -Name "Composer.EulaAccepted" -Value "0" -PropertyType "DWORD" -Force
New-ItemProperty -Path $composer -Name "EulaAccepted" -Value "0" -PropertyType "DWORD" -Force
New-ItemProperty -Path $composer -Name "EulaAccepted 2018 7.5.5.1346 $env:ComputerName $env:Username" -Value "1" -PropertyType "DWORD" -Force
New-ItemProperty -Path $composer -Name "RefreshProgressUI" -Value "1" -PropertyType "DWORD" -Force
New-ItemProperty -Path $composer -Name "Sync.EulaAccepted" -Value "0" -PropertyType "DWORD" -Force

# eDrawings
$eDraw = "Registry::\HKCU\Software\eDrawings\e2018\General"
If (!(Test-Path $eDraw)){New-Item -Path $eDraw -force}
New-ItemProperty -Path $eDraw -Name "ShowLicense 2018 sp04 $env:ComputerName $env:UserName" -Value "0" -PropertyType "DWORD" -Force
