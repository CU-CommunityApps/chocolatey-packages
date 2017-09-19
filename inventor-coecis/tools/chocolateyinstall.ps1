$packageName= 'inventor-coecis'
$toolsDir   = "$(Split-Path -Parent $MyInvocation.MyCommand.Definition)"
$url        = "https://s3.amazonaws.com/cu-deng-appstream-packages/packages/$packageName.zip"

Install-ChocolateyZipPackage $packageName $url $toolsDir

$packageArgs = @{
	packageName = $packageName
	fileType    = 'exe'
	file        = "$toolsDir\Img\Setup.exe"
	silentArgs  = "/qb /I $toolsDir\Img\autodesk-coecis.ini /language en-us"
    validExitCodes = @(0, 259)
}

Install-ChocolateyInstallPackage @packageArgs  
