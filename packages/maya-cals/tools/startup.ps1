Write-Output "Setting network license settings..."
Start-Process "${env:CommonProgramFiles(x86)}\Autodesk Shared\AdskLicensing\Current\helper\AdskLicensingInstHelper.exe" -ArgumentList "change -pk 657L1 -pv 2020.0.0.F -lm NETWORK -lt SINGLE -ls 2080$env:ADSKFLEX_LICENSE_FILE"
