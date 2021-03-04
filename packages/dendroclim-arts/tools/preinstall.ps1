# Runs before the choco package is installed

$INSTALL_DIR =  Join-Path $PSScriptRoot 'installer'

Expand-Archive -LiteralPath "$env:INSTALL_DIR\dendroclim.zip" -DestinationPath "env:ProgramFiles(x86)"\UNR" -recurse
