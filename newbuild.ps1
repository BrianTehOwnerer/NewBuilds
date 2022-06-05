
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
	$wallpaperlocation = $Home + "\Pictures\Schrock Wallpaper.png"
	Invoke-WebRequest -Uri "https://secureupdater.s3.us-east-2.amazonaws.com/downloads/Schrock+Wallpaper.png" -OutFile $wallpaperlocation
	#Computer\HKEY_CURRENT_USER\Control Panel\Desktop
	Set-ItemProperty -Path "HKCU:\Control Panel\Desktop" -Name "WallPaper" -Value $wallpaperlocation
	Set-ItemProperty -Path "HKCU:\Control Panel\Desktop" -Name "WallpaperStyle" -Value 22
}

function Misctweeks {
	#turns on system restore for drive C and takes a snapshot.
	Enable-ComputerRestore -Drive "C:\"
	"System restore enabled"
	Checkpoint-Computer -Description ""Fresh Install of Windows"" -RestorePointType "MODIFY_SETTINGS"
	Manage-Bde -off c:
	set-TimeZone -Name "Central Standard Time"

}
function Activate {
	#check activation status, and if windows isnt activated try installing the key from bios
	$activationStatus = Get-CIMInstance -query "select Name, LicenseStatus from SoftwareLicensingProduct where LicenseStatus=1 and Name LIKE 'Wind%'" | Format-List Name, LicenseStatus
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

InstallDAandSU
Misctweeks
Activate
SetWallpaper
InstallChocoPrograms