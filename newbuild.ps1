Function InstallDAandSU {
	#$DesktopPath = [Environment]::GetFolderPath("Desktop")
	$SecureUpdaterurl = "https://secureupdater.s3.us-east-2.amazonaws.com/downloads/SecureUpdater.msi"
	$SUoutpath = "$PSScriptRoot\SecureUpdater.msi"
	$DriveAdvisorurl = "https://secureupdater.s3.us-east-2.amazonaws.com/downloads/driveadviser.msi"
	$DAoutpath = "$PSScriptRoot\driveadvisor.msi"

	#checks for SU and Drive Advisor, if not found installs them from the folders.
	if (Test-Path -Path "C:\Program Files (x86)\Secure Updater\Secure Updater.exe") {
		Write-Host "SU is already installed"
	}
	else {
		Invoke-WebRequest -Uri $SecureUpdaterurl -OutFile $SUoutpath
		Start-Process $SUoutpath "/quiet"
	}

	if (Test-Path -Path "C:\Program Files (x86)\Drive Adviser\Drive Adviser.exe") {
		Write-Host "Drive Adviser already installed"
	}
	else {
		Invoke-WebRequest -Uri $DriveAdvisorurl -OutFile $DAoutpath
		Start-Process $DAoutpath "/quiet"
		Start-Process "C:\Program Files (x86)\Drive Adviser\Drive Adviser.exe"
	}

}


function  SetWallpaper {
	#sets the wallpaperlocation variable to your pictures folder and name
	$wallpaperlocation = $Home + "\Pictures\Schrock Wallpaper.png"
	#Downloads and saves our wallpaper to the correct place
	Invoke-WebRequest -Uri "https://secureupdater.s3.us-east-2.amazonaws.com/downloads/Schrock+Wallpaper.png" -OutFile $wallpaperlocation
	#Sets the wallpaper to ours, then sets it to style "span" 
	Set-ItemProperty -Path "HKCU:\Control Panel\Desktop" -Name "WallPaper" -Value $wallpaperlocation
	Set-ItemProperty -Path "HKCU:\Control Panel\Desktop" -Name "WallpaperStyle" -Value 22
}

function Misctweeks {
	#turns on system restore for drive C and takes a snapshot.
	Enable-ComputerRestore -Drive "C:\"
	"System restore enabled"
	Checkpoint-Computer -Description ""Fresh Install of Windows"" -RestorePointType "MODIFY_SETTINGS"
	#this disables bitlocker on the C drive, we had some HS laptops that re-enabled it even after a fresh install
	#better safe than sorry, its only a 1 liner any how
	Manage-Bde -off c:
	#This sets the timezone to CST, if your in a diffrent timezone, find yours via get-timezone list
	set-TimeZone -Name "Central Standard Time"
}

function Activate {
	#check activation status, and if windows isnt activated try installing the key from bios
	$activationStatus = Get-CIMInstance -query "select Name, LicenseStatus from SoftwareLicensingProduct where LicenseStatus=1 and Name LIKE 'Wind%'"
	if (!$activationStatus) {
		$biosKey = (Get-WmiObject -query ‘select * from SoftwareLicensingService’).OA3xOriginalProductKey
		if ($biosKey) {
			slmgr.vbs /ipk $biosKey
			slmgr.vbs /ato
			else {
				$windowsKey = Read-Host -Prompt 'Imput the windows key now'
				slmgr.vbs /ipk $windowsKey
				slmgr.vbs /ato
			}
		}
	}
}
function InstallChocoPrograms {
	Set-ExecutionPolicy Bypass -Scope Process -Force; [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072; Invoke-Expression ((New-Object System.Net.WebClient).DownloadString('https://community.chocolatey.org/install.ps1'))
	choco install libreoffice-fresh -y
	choco install adobereader '"/DesktopIcon"' -y
	choco install jre8 -y
	choco install firefox -y
	choco install googlechrome -y
	choco install vlc -y
	choco install dogtail.dotnet3.5sp1 -y
	choco install dotnetfx --version -y
	choco install zoom -y
}

function securitySettings {
	#This sets the dns to something good, so even when cox dns dies, their internet will still work
	$interfaceName = (Get-NetAdapter -Physical)
	foreach ($tempname in $interfaceName.Name) {
		set-DnsClientServerAddress -InterfaceAlias $tempname -ServerAddresses ("9.9.9.9", "1.1.1.1", "8.8.8.8")
	}
}

InstallDAandSU
Misctweeks
Activate
SetWallpaper
InstallChocoPrograms