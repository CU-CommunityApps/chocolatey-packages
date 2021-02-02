# Runs before the choco package is installed

$INSTALL_DIR =  Join-Path $PSScriptRoot 'installer'

New-Item -ItemType Directory "$env:allusersprofile\Minitab\Minitab 19" -Force
Copy-Item "$INSTALL_DIR\minitab.lic" "$env:allusersprofile\Minitab\Minitab 19\minitab.lic" -Recurse -Force
Copy-Item "$INSTALL_DIR\License.ini" "$env:ALLUSERSPROFILE\Minitab\License.ini" -Recurse -Force
