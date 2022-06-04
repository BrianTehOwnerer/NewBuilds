
Function InstallDAandSU {
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
	#Computer\HKEY_CURRENT_USER\Control Panel\Desktop
	$wallpaperlocation = $Home + "\Pictures\Schrock Wallpaper.png"
	Set-ItemProperty -Path "HKCU:\Control Panel\Desktop" -Name "WallPaper" -Value $wallpaperlocation
	Set-ItemProperty -Path "HKCU:\Control Panel\Desktop" -Name "WallpaperStyle" -Value 22
}

function Misctweeks {

	set-TimeZone -Name "Central Standard Time"
}

function InstallChocoPrograms {
	Set-ExecutionPolicy Bypass -Scope Process -Force; [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072; iex ((New-Object System.Net.WebClient).DownloadString('https://community.chocolatey.org/install.ps1'))
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



SetWallpaper