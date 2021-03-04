# Runs before the choco package is installed

$INSTALL_DIR =  Join-Path $PSScriptRoot 'installer'

Copy-Item -Path "$env:INSTALL_DIR\*" -Destination "$env:ProgramFiles(x86)\UNR" -recurse
