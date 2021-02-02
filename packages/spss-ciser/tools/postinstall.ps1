# Runs after the choco package is installed
# Runs after the choco package is installed
start-process "$env:programfiles\IBM\SPSS\Statistics\26\licenseactivator.exe" -ArgumentList "$env:SPSS_LICENSE_KEY"

