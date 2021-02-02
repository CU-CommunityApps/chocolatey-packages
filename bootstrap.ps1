[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

$BUILD_DIR = Join-Path $Env:TEMP "image-build"
$PACKAGE_DIR = Join-Path $BUILD_DIR "packages"
$CHOCO_REPO = "https://chocolatey.org/api/v2"
$BUILDER_PACKAGE = "image-builder-cornell"
$BUILDER_VERSION = "1.0"
$STARTUP_USER = "$env:ALLUSERSPROFILE\SessionScripts\startupuser.ps1"
$STARTUP_SYSTEM = "$env:ALLUSERSPROFILE\SessionScripts\startupsystem.ps1"
$SHUTDOWN_USER = "$env:ALLUSERSPROFILE\SessionScripts\shutdownuser.ps1"
$SHUTDOWN_SYSTEM = "$env:ALLUSERSPROFILE\SessionScripts\shutdownsystem.ps1"
$POWERSHELL_PATH = "$env:WINDIR\System32\WindowsPowerShell\v1.0\powershell.exe"
$SESSION_SCRIPTS = "$env:SystemDrive\AppStream\SessionScripts\config.json"
$BUILDER_STDOUT_LOG = "$env:SystemDrive\builder-console.log"
$BUILDER_STDERR_LOG = "$env:SystemDrive\builder-console-err.log"
$SESSION_CONTENTS = Get-Content $SESSION_SCRIPTS | Out-String | ConvertFrom-Json
$LONGPATH_KEY = "HKLM:\SYSTEM\CurrentControlSet\Control\FileSystem"
$REBOOT_LOCK = "$env:ALLUSERSPROFILE\TEMP\REBOOT.lock"
$OSVERSION = (get-itemproperty -Path "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion" -Name ProductName).ProductName

if (-Not (Test-Path $BUILD_DIR)) {

    # Wait Five Minutes on First Run
    Start-Sleep -Seconds 300

    # Set system time zone
    Set-TimeZone -Name "Eastern Standard Time"
    
    # Create Session Script Template Files
    If (!(Test-Path "$env:ALLUSERSPROFILE\SessionScripts")){New-Item -Path $env:ALLUSERSPROFILE -ItemType Directory -Name SessionScripts}
    If (!(Test-Path $STARTUP_USER)){New-Item -Path "$env:ALLUSERSPROFILE\SessionScripts" -Name startupuser.ps1}
    If (!(Test-Path $STARTUP_SYSTEM)){New-Item -Path "$env:ALLUSERSPROFILE\SessionScripts" -Name startupsystem.ps1}
    If (!(Test-Path $SHUTDOWN_USER)){New-Item -Path "$env:ALLUSERSPROFILE\SessionScripts" -Name shutdownuser.ps1}
    If (!(Test-Path $SHUTDOWN_SYSTEM)){New-Item -Path "$env:ALLUSERSPROFILE\SessionScripts" -Name shutdownsystem.ps1}

    # Point scripts to AppStream session script location / format

    # Startup System
    $SESSION_CONTENTS.SessionStart.executables[0].filename = $POWERSHELL_PATH
    $SESSION_CONTENTS.SessionStart.executables[0].arguments = "-File `"$STARTUP_SYSTEM`""

    # Startup User
    $SESSION_CONTENTS.SessionStart.executables[1].filename = $POWERSHELL_PATH
    $SESSION_CONTENTS.SessionStart.executables[1].arguments = "-File `"$STARTUP_USER`""

    # Shutdown System
    $SESSION_CONTENTS.SessionTermination.executables[0].filename = $POWERSHELL_PATH
    $SESSION_CONTENTS.SessionTermination.executables[0].arguments = "-File `"$SHUTDOWN_SYSTEM`""

    # Shutdown User
    $SESSION_CONTENTS.SessionTermination.executables[1].filename = $POWERSHELL_PATH
    $SESSION_CONTENTS.SessionTermination.executables[1].arguments = "-File `"$SHUTDOWN_USER`""

    # Add contents to AppStream config.json file
    $SESSION_CONTENTS | ConvertTo-Json -Depth 3 | Set-Content $SESSION_SCRIPTS

    # Add Long File Path Support for Server '16/'19
    Set-ItemProperty -Path $LONGPATH_KEY -Name "LongPathsEnabled" -Value 1
    
    # Create Temp Directories
    Write-Output "Creating Temporary Build Directories"
    New-Item -ItemType Directory -Force -Path $BUILD_DIR
    New-Item -ItemType Directory -Force -Path $PACKAGE_DIR
    
    # No Path set for SYSTEM so move to BUILD_DIR
    Set-Location $BUILD_DIR
    
    # Install Chocolatey
    Write-Output "Installing Chocolatey"
    Invoke-Expression ((New-Object System.Net.WebClient).DownloadString('https://chocolatey.org/install.ps1'))
    
    # Install Sysinterals
    Write-Output "Installing Sysinterals"
    Start-Process -FilePath "choco.exe" -ArgumentList "install sysinternals --no-progress -r -y" -NoNewWindow -Wait
    
    # Uninstall Corrupt Windows Feature from AWS AMI
    If($OSVERSION -match "2016"){Uninstall-WindowsFeature -Name Windows-Defender}

    # Parse EC2 Metadata
    $user_data_uri = "http://169.254.169.254/latest/user-data"
    $bucket_prefix = "image-build"
    $user_data = (irm -Uri $user_data_uri).resourceARN
    $region = $user_data.Split(":")[3]
    $account = $user_data.Split(":")[4]
    $build_id = $user_data.Split(":")[5].Split("/")[1]
    $package_branch = $build_id.Split(".")[1]
    $image_id = $build_id.Split(".")[2..$build_id.Split(".").Length] -join "."
    $build_bucket = "$bucket_prefix-$account-$region"
    $build_package_uri = "https://s3.amazonaws.com/$build_bucket/packages/$package_branch/$BUILDER_PACKAGE.$BUILDER_VERSION.nupkg"
    
    # Parse Database
    $build_bucket_uri = "https://$build_bucket.s3.amazonaws.com"
    $api_uri = (irm -URI "$build_bucket_uri/api_endpoint.txt").Trim()
    $api_headers = @{"Accept"="application/json"}
    $api_post = @{
        BuildId="$image_id"
    }
    $json = $api_post | ConvertTo-Json
    $build_info = irm -URI "$api_uri/$bucket_prefix" -Headers $api_headers -Method POST -Body $json -ContentType "application/json"

    # Set system level environment variable for manual processing
    If ($build_info.Manual -eq $true){[System.Environment]::SetEnvironmentVariable("AoD_Manual", $true, 'Machine')}
    Else {[System.Environment]::SetEnvironmentVariable("AoD_Manual", $false, 'Machine')}

    # Download ImageBuild Package
    Write-Output "Downloading ImageBuilder Nupkg: $BUILD_PACKAGE_URI"
    (New-Object System.Net.WebClient).DownloadFile($BUILD_PACKAGE_URI, (Join-Path "$PACKAGE_DIR" "$BUILDER_PACKAGE.$BUILDER_VERSION.nupkg"))
    
    # Install ImageBuilder
    Write-Output "Installing ImageBuilder Package"
    Start-Process -FilePath "choco.exe" -ArgumentList "install $BUILDER_PACKAGE -s $PACKAGE_DIR;$CHOCO_REPO --no-progress -r -y" -NoNewWindow -Wait
    
    # Install .NET 4.8
    Write-Output "Installing .NET 4.8"
    Start-Process -FilePath "choco.exe" -ArgumentList "install dotnetfx -s $PACKAGE_DIR;$CHOCO_REPO --no-progress -r -y" -NoNewWindow -Wait

}
else {
    # No Path set for SYSTEM so move to BUILD_DIR
    Set-Location $BUILD_DIR

    # Install Windows Defender if not installer
    If (!((Get-WindowsFeature -Name Windows-Defender).Installed) -and $OSVERSION -match "2016"){
        Write-Output "Installing Windows Defender"
        
        # Re-install Windows Defender
        Install-WindowsFeature -Name Windows-Defender
        
        # Disable Windows Defender
        Set-ItemProperty "HKLM:\SOFTWARE\Policies\Microsoft\Windows Defender" DisableAntiSpyware 1 -Force -ErrorAction SilentlyContinue
        Remove-Item $REBOOT_LOCK -Force -ErrorAction SilentlyContinue
    }
}

# Run ImageBuilder
If ([System.Environment]::GetEnvironmentVariable("AoD_Manual", 'Machine') -ne $true){
    Write-Output "Running ImageBuilder"
    Start-Process -FilePath "PsExec.exe" -ArgumentList "-w $BUILD_DIR -i -s ImageBuilder.exe" -RedirectStandardOutput "$BUILDER_STDOUT_LOG" -RedirectStandardError "$BUILDER_STDERR_LOG" -NoNewWindow -Wait
}
Else {
    $URI = "https://raw.githubusercontent.com/CU-CommunityApps/choco-packages/master/packages/troubleshooting.ps1"
    Start-BitsTransfer -Source $URI -Destination "$env:PUBLIC\Desktop\troubleshooting.ps1"
}
