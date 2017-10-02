$packageName= 'matlab-coecis'
$toolsDir   = "C:\Windows\Temp"
$url        = "https://s3.amazonaws.com/cu-deng-appstream-packages/packages/$packageName.zip"

Install-ChocolateyZipPackage $packageName $url $toolsDir
Copy-Item "$toolsDir\network.lic" "C:\ProgramData\network.lic"

$packageArgs = @{
	packageName = $packageName
	fileType    = 'exe'
	file        = "$toolsDir\setup.exe"
	silentArgs  = "-inputFile $toolsDir\installer_input.txt"
}

Install-ChocolateyInstallPackage @packageArgs  
