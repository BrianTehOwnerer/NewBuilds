Function InstallDAandSU {
	$SecureUpdaterurl = "https://secureupdater.s3.us-east-2.amazonaws.com/downloads/SecureUpdater.msi"
	$SUoutpath = $Home + "\Desktop\SecureUpdater.msi"
	$DriveAdvisorurl = "https://secureupdater.s3.us-east-2.amazonaws.com/downloads/driveadviser.msi"
	$DAoutpath = $Home + "\driveadvisor.msi"

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
	Checkpoint-Computer -Description "Fresh Install of Windows" -RestorePointType "MODIFY_SETTINGS"
	#this disables bitlocker on the C drive, we had some HS laptops that re-enabled it even after a fresh install
	#better safe than sorry, its only a 1 liner any how
	Manage-Bde -off c:
	#This sets the timezone to CST, if your in a diffrent timezone, find yours via get-timezone list
	set-TimeZone -Name "Central Standard Time"
	#this loop asks for the PC Name you would like it to set
	#Conviently if the PC is already named in the correct way it skips this
	#and yes, a while loop is awful for this, but i love while loops and you cant stop me
	$PCName = $env:COMPUTERNAME
	while ($PCName -notmatch '^SI-[0-9]{1,7}$') {
		$PCName = Read-Host -Prompt 'Imput the PC Name Here. eg, SI-4938294'
		if ($PCName -match '^SI-[0-9]{1,7}$') {
			Rename-Computer -NewName $PCName
		}
		else {
			Write-Host "Name must fit format of SI-130496"
		}
	}	
	#Set all local account passwords to never expire
	$userNames = Get-LocalUser
	foreach ($accoutnname in $userNames.Name) {
		Set-LocalUser $accoutnname -PasswordNeverExpires 1
	}
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

function runUpdates {
	Install-Module PSWindowsUpdate -Force
	Get-WindowsUpdate -WindowsUpdate -UpdateType Driver -IsInstalled
	Install-WindowsUpdate -AcceptAll -IgnoreReboot 
}

function InstallChocoPrograms {
	Install-PackageProvider -Name NuGet -Force
	Set-ExecutionPolicy Bypass -Scope Process -Force; [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072; Invoke-Expression ((New-Object System.Net.WebClient).DownloadString('https://community.chocolatey.org/install.ps1'))
	choco install libreoffice-fresh -y
	choco install adobereader '"/DesktopIcon"' -y
	choco install jre8 -y
	choco install firefox -y
	choco install googlechrome -y
	choco install vlc -y
	choco install dogtail.dotnet3.5sp1 -y
	choco install dotnetfx -y
	choco install zoom -y
}

function securitySettings {
	#This sets the dns to something good, so even when cox dns dies, their internet will still work
	$interfaceName = (Get-NetAdapter -Physical)
	foreach ($tempname in $interfaceName.Name) {
		set-DnsClientServerAddress -InterfaceAlias $tempname -ServerAddresses ("9.9.9.9", "1.1.1.1", "8.8.8.8")
	}
}

# I want it known that while I am proud to have this work... I am very dissapointed in all of the browsers for making me do this in the first place...
# for refrence https://docs.microsoft.com/en-us/previous-versions/office/developer/office-xp/aa202943(v=office.10)?redirectedfrom=MSDN
# The correct way to do this is https://docs.microsoft.com/en-us/deployedge/microsoft-edge-policies
# https://support.google.com/chrome/a/answer/3115278?hl=en
# https://support.mozilla.org/en-US/kb/deploying-firefox-windows
function setDefaultBrowserHomepages {
	Start-Process "C:\Program Files\Google\Chrome\Application\chrome.exe"
	Start-Process "C:\Program Files (x86)\Microsoft\Edge\Application\msedge.exe"
	Start-Process "C:\Program Files\Mozilla Firefox\firefox.exe"
	Start-Sleep 10
	taskkill.exe /IM chrome.exe /F
	taskkill.exe /IM firefox.exe /F
	taskkill.exe /IM edge.exe /F
	Start-Process "C:\Program Files\Google\Chrome\Application\chrome.exe"
	Start-Process "C:\Program Files (x86)\Microsoft\Edge\Application\msedge.exe"
	Start-Process "C:\Program Files\Mozilla Firefox\firefox.exe"
	Start-Sleep 10

	#Edge 
	Start-Process "C:\Program Files (x86)\Microsoft\Edge\Application\msedge.exe"
	Start-Sleep 5
	$wshell = New-Object -ComObject wscript.shell;
	$wshell.AppActivate('edge')
	Start-Sleep 5
	$wshell.SendKeys('edge://settings/startHomeNTP ~ ')
	Start-Sleep 5
	$wshell.SendKeys('{TAB} {TAB} {TAB} {TAB} ~')
	Start-Sleep 1
	$wshell.SendKeys('www.schrockinnovations.com ~')

	Write-Host -NoNewLine 'Press any key to continue...';
	$null = $Host.UI.RawUI.ReadKey('NoEcho,IncludeKeyDown');

	#Firefox
	Start-Process "C:\Program Files\Mozilla Firefox\firefox.exe"
	Start-Sleep 5
	$wshell = New-Object -ComObject wscript.shell;
	$wshell.AppActivate('Fire Fox')
	Start-Sleep 5
	$wshell.SendKeys('about:preferences#home ~')
	Start-Sleep 5
	$wshell.SendKeys('{TAB} {down} {TAB} www.schrockinnovations.com ~')
	Start-Sleep 1
	Write-Host -NoNewLine 'Press any key to continue...';
	$null = $Host.UI.RawUI.ReadKey('NoEcho,IncludeKeyDown');

	#chrome
	Start-Process "C:\Program Files\Google\Chrome\Application\chrome.exe"
	Start-Sleep 5
	$wshell = New-Object -ComObject wscript.shell;
	$wshell.AppActivate('chrome')
	Start-Sleep 5
	$wshell.SendKeys('chrome://settings/onStartup ~')
	Start-Sleep 5
	$wshell.SendKeys('{TAB} {TAB} {down} {down}{TAB} ~')
	Start-Sleep 1
	$wshell.SendKeys('www.schrockinnovations.com ~')
	Start-Sleep 1
	$wshell.SendKeys('~')
	Write-Host -NoNewLine 'Press any key to continue...';
	$null = $Host.UI.RawUI.ReadKey('NoEcho,IncludeKeyDown');
}

SecuritySettings
InstallDAandSU
Misctweeks
Activate
SetWallpaper
InstallChocoPrograms
runUpdates