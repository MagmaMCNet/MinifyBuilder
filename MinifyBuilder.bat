@echo off
setlocal EnableExtensions EnableDelayedExpansion

@rem pretty colors
color 1e

@rem set ESC for colorful messages
set "ESC="

@rem set the title
title Minify ISOImage Builder
@echo.Welcome to the Minify image creator!

>nul 2>&1 net session
if %errorlevel% neq 0 (
    call :showerror "Please run the script with administrative privileges."
    pause
    exit /b 1
)
@rem use script's directory for all temporary files/dirs
cd /D %~dp0
if exist "C:\Program Files (x86)\Windows Kits\10\Assessment and Deployment Kit\Deployment Tools\amd64\Oscdimg\oscdimg.exe" (
  copy "C:\Program Files (x86)\Windows Kits\10\Assessment and Deployment Kit\Deployment Tools\amd64\Oscdimg\oscdimg.exe" . >NUL
)
@rem Check if there is oscdimg.exe in PATH
where oscdimg.exe >NUL || (call :showerror "OsCdImg.exe is not found in PATH. Get it from Windows ADK and put into script dir or any other dir in PATH." & goto Stop)

@rem Get Windows ISO mounted drive letter
set DriveLetter=
set /p DriveLetter=Please enter the drive letter for the Windows 10/11 image: 
set "DriveLetter=%DriveLetter%:"


@rem Get Windows ISO mounted drive letter
set autounattend=
set /p autounattend=Please Enter The Windows Version for the Windows 10/11 image: 
set "ISOVersion=%autounattend%"
set "autounattend=autounattend%autounattend%.xml"
@echo.

@rem verify if boot.wim exists on a chosen Windows ISO path
if exist "%DriveLetter%\sources\boot.wim" goto bootWimFound

:noWimFileFound
call :showerror "Can't find %DriveLetter%\sources\boot.wim or install.wim. Please enter the correct DVD Drive Letter."
@goto :Stop

:bootWimFound
@rem verify if install.wim exists on a chosen Windows ISO path
if not exist "%DriveLetter%\sources\install.wim" goto noWimFileFound
@rem pre-cleanup of temp dirs
rd /s /q ISOImage 2>NUL
rd /s /q WindowsInstall 2>NUL

@echo Copying Windows image to .\ISOImage...
md ISOImage
xcopy.exe /E /I /H /R /Y /J %DriveLetter% .\ISOImage >nul || ( call :showerror "XCOPY failed. Check if you have enough disk space." & goto Stop )
@echo.Copy complete!

@rem clean dism log
del /f /q %windir%\Logs\DISM\dism.log %windir%\Logs\DISM\DismAppx.log >NUL

@echo.Getting image information:
dism /Get-WimInfo /wimfile:%~dp0ISOImage\sources\install.wim || (call :showerror "Dism /Get-WimInfo failed. You should run this script as an Administrator. Check the error above." & goto Stop )
md %~dp0WindowsInstall
set index=
set /p index=Please enter the image index:
set "index=%index%"
@echo.Mounting Windows image. This may take a while.
@echo.
dism /mount-image /imagefile:%~dp0ISOImage\sources\install.wim /index:%index% /mountdir:%~dp0WindowsInstall || ( call :showerror "Mounting image install.wim failed. Check if you have enough disk space. And your volume should be NTFS." & goto Stop )
@echo.Mounting complete!

del /F /Q %TEMP%\longAppPackageNames.txt >NUL 2>NUL
@echo.Getting Application Packages long names
dism /image:%~dp0WindowsInstall /Get-ProvisionedAppxPackages | findstr PackageName>%TEMP%\longAppPackageNames.txt

@echo.Preparing Long Package Names List for removal
@rem get pure long package names
del /f /q %TEMP%\pureLongAppPackageNames.txt >NUL 2>NUL
FOR /F "eol=# tokens=3" %%i IN (%TEMP%\longAppPackageNames.txt) DO @echo.%%i>>%TEMP%\pureLongAppPackageNames.txt
@rem get uncommented short app package names
del /f /q %TEMP%\uncomAppPackageNames.txt >NUL 2>NUL
FOR /F "eol=#" %%i IN (%~dp0Packages\appPackageNames.txt) DO @echo.%%i>>%TEMP%\uncomAppPackageNames.txt

@rem keep only long package names, which are found in short package names list
@findstr /B /L /G:%TEMP%\uncomAppPackageNames.txt %TEMP%\pureLongAppPackageNames.txt >%TEMP%\longAppPackageNamesToRemove.txt

@rem pause Check %TEMP%\longAppPackageNamesToRemove.txt
@echo.Removing app packages per prepared list
FOR /F %%i IN (%TEMP%\longAppPackageNamesToRemove.txt) DO ( @echo.removing.App.%%i & dism /image:%~dp0WindowsInstall /Remove-ProvisionedAppxPackage /PackageName:%%i )

@echo.Removing of system apps complete! Now proceeding to removal of system packages...

@echo.Get System Package List
dism /image:%~dp0WindowsInstall /Get-Packages | findstr /C:"Package Identity : ">%TEMP%\longSysPackageNames.txt
@echo.Preparing System Long Package Names List for removal

@rem get pure long package names
@del /f /q %TEMP%\pureLongSysPackageNames.txt >NUL 2>NUL
FOR /F "eol=# tokens=4" %%i IN (%TEMP%\longSysPackageNames.txt) DO @echo.%%i>>%TEMP%\pureLongSysPackageNames.txt

@rem get uncommented short sys package names
@del /f /q %TEMP%\uncomSysPackageNames.txt >NUL 2>NUL
FOR /F "eol=#" %%i IN (%~dp0Packages\sysPackageNames.txt) DO @echo.%%i>>%TEMP%\uncomSysPackageNames.txt

@rem keep only long package names, which are found in short package names list
@findstr /B /L /G:%TEMP%\uncomSysPackageNames.txt %TEMP%\pureLongSysPackageNames.txt >%TEMP%\LongSysPackageNamesToRemove.txt

@rem pause Check %TEMP%\LongSysPackageNamesToRemove.txt

@echo.Removing sys packages per prepared list
FOR /F %%i IN (%TEMP%\LongSysPackageNamesToRemove.txt) DO ( @echo.removing.SysPack.%%i & dism /image:%~dp0WindowsInstall /Remove-Package /PackageName:%%i )

@rem Capabilities seem to match AppPackages and SysPackages - so I keep the list commented out
echo.Get Capabilities
dism /image:%~dp0WindowsInstall /Get-Capabilities /LimitAccess | findstr /C:"Capability Identity : ">%TEMP%\longCapabilties.txt

@rem get only long Capability names
@del /f /q %TEMP%\pureLongCapabilties.txt >NUL 2>NUL
FOR /F "eol=# tokens=4" %%i IN (%TEMP%\longCapabilties.txt) DO @echo.%%i>>%TEMP%\pureLongCapabilties.txt

@rem get uncommented capability names
@del /f /q %TEMP%\uncomCapabilityNames.txt >NUL 2>NUL
FOR /F "eol=#" %%i IN (%~dp0Packages\capabilityNames.txt) DO @echo.%%i>>%TEMP%\uncomCapabilityNames.txt

@rem keep only long capability names, which are found in short capability names list
@findstr /B /L /G:%TEMP%\uncomCapabilityNames.txt %TEMP%\pureLongCapabilties.txt >%TEMP%\LongCapabiltiesToRemove.txt

@rem pause Check %TEMP%\LongCapabiltiesToRemove.txt

@rem dism /image:%~dp0WindowsInstall /Remove-Capability /CapabilityName:App.StepsRecorder~~~~0.0.1.0
echo.Removing Capabilities...
FOR /F %%i IN (%TEMP%\LongCapabiltiesToRemove.txt) DO ( @echo.removing.Capability.%%i & dism /image:%~dp0WindowsInstall /Remove-Capability /CapabilityName:%%i )

@rem Get features - those can be later enabled/disable via appwiz.cpl
@rem dism /image:%~dp0WindowsInstall /Get-features /Format:List >%TEMP%\features.txt

@rem get uncommented Feature names
@del /f /q %TEMP%\uncomFeatureNames.txt >NUL 2>NUL
FOR /F "eol=#" %%i IN (%~dp0Packages\featureNames.txt) DO @echo.%%i>>%TEMP%\uncomFeatureNames.txt

@rem pause Check %TEMP%\uncomFeatureNames.txt

@echo.Disable features: port-sharing, Media playback/player, WorkFolders, InternetPrinting
FOR /F %%i IN (%TEMP%\uncomFeatureNames.txt) DO ( @echo.removing.feature.%%i & dism /image:%~dp0WindowsInstall /Disable-Feature /FeatureName:%%i /Remove )

@rem conditional removal of MsEdgeBrowser
findstr /IC:"psedo-Minify-MsEdgeBrowser" %TEMP%\uncomSysPackageNames.txt >NUL && (
  @echo.Removing Edge
  takeown /F "%~dp0WindowsInstall\Program Files (x86)\Microsoft\Edge" /R /SKIPSL /D Y >NUL 2>NUL || call :showerror "Takeownership of Edge failed."
  icacls "%~dp0WindowsInstall\Program Files (x86)\Microsoft\Edge" /grant Administrators:F /T /C /Q >NUL 2>NUL || call :showerror "GrantAccess to Edge failed."
  rd /s /q "%~dp0WindowsInstall\Program Files (x86)\Microsoft\Edge" >NUL || call :showerror "Removal of Edge failed."
)

@rem conditional removal of MsEdgeUpdate
findstr /IC:"psedo-Minify-MsEdgeUpdate" %TEMP%\uncomSysPackageNames.txt >NUL && (
  @echo.Removing EdgeUpdate
  takeown /F "%~dp0WindowsInstall\Program Files (x86)\Microsoft\EdgeUpdate" /R /SKIPSL /D Y >NUL 2>NUL || call :showerror "Takeownership of EdgeUpdate failed."
  icacls "%~dp0WindowsInstall\Program Files (x86)\Microsoft\EdgeUpdate" /grant Administrators:F /T /C /Q >NUL 2>NUL || call :showerror "GrantAccess to EdgeUpdate failed."
  rd /s /q "%~dp0WindowsInstall\Program Files (x86)\Microsoft\EdgeUpdate" >NUL || call :showerror "Removal of EdgeUpdate failed."
)

@rem conditional removal of MsEdgeCore
findstr /IC:"psedo-Minify-MsEdgeCore" %TEMP%\uncomSysPackageNames.txt >NUL && (
  @echo.Removing EdgeCore
  takeown /F "%~dp0WindowsInstall\Program Files (x86)\Microsoft\EdgeCore" /R /SKIPSL /D Y >NUL 2>NUL || call :showerror "Takeownership of EdgeCore failed."
  icacls "%~dp0WindowsInstall\Program Files (x86)\Microsoft\EdgeCore" /grant Administrators:F /T /C /Q >NUL 2>NUL || call :showerror "GrantAccess to EdgeCore failed."
  rd /s /q "%~dp0WindowsInstall\Program Files (x86)\Microsoft\EdgeCore" >NUL || call :showerror "Removal of EdgeCore failed."
)

@rem conditional removal of MsEdgeWebView
findstr /IC:"psedo-Minify-MsEdgeWebView" %TEMP%\uncomSysPackageNames.txt >NUL && (
  @echo.Removing EdgeWebView
  takeown /F "%~dp0WindowsInstall\Program Files (x86)\Microsoft\EdgeWebView" /R /SKIPSL /D Y >NUL 2>NUL || call :showerror "Takeownership of EdgeWebView failed."
  icacls "%~dp0WindowsInstall\Program Files (x86)\Microsoft\EdgeWebView" /grant Administrators:F /T /C /Q >NUL 2>NUL || call :showerror "GrantAccess to EdgeWebView failed."
  rd /s /q "%~dp0WindowsInstall\Program Files (x86)\Microsoft\EdgeWebView" >NUL || call :showerror "Removal of EdgeWebView failed."
)

@rem conditional removal of MsOneDrive
findstr /IC:"psedo-Minify-MsOneDrive" %TEMP%\uncomSysPackageNames.txt >NUL && (
  @echo.Removing OneDrive:
  takeown /f %~dp0WindowsInstall\Windows\System32\OneDriveSetup.exe >NUL
  icacls %~dp0WindowsInstall\Windows\System32\OneDriveSetup.exe /grant Administrators:F /C /Q
  del /f /q "%~dp0WindowsInstall\Windows\System32\OneDriveSetup.exe" >NUL
)


@rem Copying Custom Packages Into Image
@echo.Adding Custom Packages To Image
xcopy /s /e /y "%~dp0CustomPackages\*" "%~dp0WindowsInstall\"

@echo.Loading registry...
reg load HKLM\zCOMPONENTS "%~dp0WindowsInstall\Windows\System32\config\COMPONENTS" >nul
reg load HKLM\zDEFAULT "%~dp0WindowsInstall\Windows\System32\config\default" >nul
reg load HKLM\zNTUSER "%~dp0WindowsInstall\Users\Default\ntuser.dat" >nul
reg load HKLM\zSOFTWARE "%~dp0WindowsInstall\Windows\System32\config\SOFTWARE" >nul
reg load HKLM\zSYSTEM "%~dp0WindowsInstall\Windows\System32\config\SYSTEM" >NUL

@echo Bypassing system requirements (on the system image):
Reg add "HKLM\zDEFAULT\Control Panel\UnsupportedHardwareNotificationCache" /v "SV1" /t REG_DWORD /d "0" /f >nul 2>&1
Reg add "HKLM\zDEFAULT\Control Panel\UnsupportedHardwareNotificationCache" /v "SV2" /t REG_DWORD /d "0" /f >nul 2>&1
Reg add "HKLM\zNTUSER\Control Panel\UnsupportedHardwareNotificationCache" /v "SV1" /t REG_DWORD /d "0" /f >nul 2>&1
Reg add "HKLM\zNTUSER\Control Panel\UnsupportedHardwareNotificationCache" /v "SV2" /t REG_DWORD /d "0" /f >nul 2>&1
Reg add "HKLM\zSYSTEM\Setup\LabConfig" /v "BypassCPUCheck" /t REG_DWORD /d "1" /f >nul 2>&1
Reg add "HKLM\zSYSTEM\Setup\LabConfig" /v "BypassRAMCheck" /t REG_DWORD /d "1" /f >nul 2>&1
Reg add "HKLM\zSYSTEM\Setup\LabConfig" /v "BypassSecureBootCheck" /t REG_DWORD /d "1" /f >nul 2>&1
Reg add "HKLM\zSYSTEM\Setup\LabConfig" /v "BypassStorageCheck" /t REG_DWORD /d "1" /f >nul 2>&1
Reg add "HKLM\zSYSTEM\Setup\LabConfig" /v "BypassTPMCheck" /t REG_DWORD /d "1" /f >nul 2>&1
Reg add "HKLM\zSYSTEM\Setup\MoSetup" /v "AllowUpgradesWithUnsupportedTPMOrCPU" /t REG_DWORD /d "1" /f >nul 2>&1
@echo Bypassing system requirements completed.


@echo.Disabling Teams:
Reg add "HKLM\zSOFTWARE\Microsoft\Windows\CurrentVersion\Communications" /v "ConfigureChatAutoInstall" /t REG_DWORD /d "0" /f >nul 2>&1
@echo.Disabling Sponsored Apps:
Reg add "HKLM\zNTUSER\SOFTWARE\Microsoft\Windows\CurrentVersion\ContentDeliveryManager" /v "OemPreInstalledAppsEnabled" /t REG_DWORD /d "0" /f >nul 2>&1
Reg add "HKLM\zNTUSER\SOFTWARE\Microsoft\Windows\CurrentVersion\ContentDeliveryManager" /v "PreInstalledAppsEnabled" /t REG_DWORD /d "0" /f >nul 2>&1
Reg add "HKLM\zNTUSER\SOFTWARE\Microsoft\Windows\CurrentVersion\ContentDeliveryManager" /v "SilentInstalledAppsEnabled" /t REG_DWORD /d "0" /f >nul 2>&1
Reg add "HKLM\zSOFTWARE\Policies\Microsoft\Windows\CloudContent" /v "DisableWindowsConsumerFeatures" /t REG_DWORD /d "1" /f >nul 2>&1
Reg add "HKLM\zSOFTWARE\Microsoft\PolicyManager\current\device\Start" /v "ConfigureStartPins" /t REG_SZ /d "{\"pinnedList\": [{}]}" /f >nul 2>&1
@echo.Enabling Local Accounts on OOBE:
Reg add "HKLM\zSOFTWARE\Microsoft\Windows\CurrentVersion\OOBE" /v "BypassNRO" /t REG_DWORD /d "1" /f >nul 2>&1
copy /y %~dp0%autounattend% %~dp0WindowsInstall\Windows\System32\Sysprep\autounattend.xml
@echo.Disabling Reserved Storage:
Reg add "HKLM\zSOFTWARE\Microsoft\Windows\CurrentVersion\ReserveManager" /v "ShippedWithReserves" /t REG_DWORD /d "0" /f >nul 2>&1
@echo.Disabling Chat icon:
Reg add "HKLM\zSOFTWARE\Policies\Microsoft\Windows\Windows Chat" /v "ChatIcon" /t REG_DWORD /d "3" /f >nul 2>&1
Reg add "HKLM\zNTUSER\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Advanced" /v "TaskbarMn" /t REG_DWORD /d "0" /f >nul 2>&1
@echo.Windows Perf Registry Tweaks
reg add "HKLM\zNTUSER\Control Panel\Desktop" /v "MenuShowDelay" /t REG_SZ /d "1" /f >nul 2>&1
reg add "HKLM\zNTUSER\Control Panel\Desktop" /v "MinAnimate" /t REG_SZ /d "0" /f >nul 2>&1
reg add "HKLM\zSOFTWARE\Policies\Microsoft\Psched" /v "NonBestEffortLimit" /t REG_DWORD /d "0" /f >nul 2>&1
reg add "HKLM\zSOFTWARE\Microsoft\Windows\CurrentVersion\Explorer" /v "DisableEdgeDesktopShortcutCreation" /t REG_DWORD /d "1" /f >nul 2>&1
reg add "HKLM\zSOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Advanced" /v "LaunchTo" /t REG_DWORD /d "1" /f >nul 2>&1
@echo.Tweaking complete!
@echo.Unmounting Registry...
reg unload HKLM\zCOMPONENTS >nul 2>&1
reg unload HKLM\zDRIVERS >nul 2>&1
reg unload HKLM\zDEFAULT >nul 2>&1
reg unload HKLM\zNTUSER >nul 2>&1
reg unload HKLM\zSCHEMA >nul 2>&1
reg unload HKLM\zSOFTWARE >nul 2>&1
reg unload HKLM\zSYSTEM >nul 2>&1
@echo.Cleaning up image...
dism /image:%~dp0WindowsInstall /Cleanup-Image /StartComponentCleanup /ResetBase
@echo.Cleanup complete.
@echo.Unmounting install.wim image/commiting changes...
dism /unmount-image /mountdir:%~dp0WindowsInstall /commit || ( call :showerror "Dism Unmount install.wim failed." & goto Stop )
rd /s /q %~dp0WindowsInstall >NUL 2>NUL
@echo.Exporting image to only keep chosen index...
Dism /Export-Image /SourceImageFile:%~dp0ISOImage\sources\install.wim /SourceIndex:%index% /DestinationImageFile:%~dp0ISOImage\sources\install2.wim /compress:max || ( call :showerror "Dism Export-Image failed" & goto Stop )
del %~dp0ISOImage\sources\install.wim
ren %~dp0ISOImage\sources\install2.wim install.wim
@echo.Windows image completed. Continuing with boot.wim.

@echo.Mounting boot image:
md %~dp0WindowsInstall
dism /mount-image /imagefile:%~dp0ISOImage\sources\boot.wim /index:2 /mountdir:%~dp0WindowsInstall || ( call :showerror "Dism Mount-Image boot.wim failed." & goto Stop )
@echo.Loading registry...
reg load HKLM\zCOMPONENTS "%~dp0WindowsInstall\Windows\System32\config\COMPONENTS" >nul
reg load HKLM\zDEFAULT "%~dp0WindowsInstall\Windows\System32\config\default" >nul
reg load HKLM\zNTUSER "%~dp0WindowsInstall\Users\Default\ntuser.dat" >nul
reg load HKLM\zSOFTWARE "%~dp0WindowsInstall\Windows\System32\config\SOFTWARE" >nul
reg load HKLM\zSYSTEM "%~dp0WindowsInstall\Windows\System32\config\SYSTEM" >nul
@echo.Bypassing system requirements(on the setup image):
Reg add "HKLM\zDEFAULT\Control Panel\UnsupportedHardwareNotificationCache" /v "SV1" /t REG_DWORD /d "0" /f >nul 2>&1
Reg add "HKLM\zDEFAULT\Control Panel\UnsupportedHardwareNotificationCache" /v "SV2" /t REG_DWORD /d "0" /f >nul 2>&1
Reg add "HKLM\zNTUSER\Control Panel\UnsupportedHardwareNotificationCache" /v "SV1" /t REG_DWORD /d "0" /f >nul 2>&1
Reg add "HKLM\zNTUSER\Control Panel\UnsupportedHardwareNotificationCache" /v "SV2" /t REG_DWORD /d "0" /f >nul 2>&1
Reg add "HKLM\zSYSTEM\Setup\LabConfig" /v "BypassCPUCheck" /t REG_DWORD /d "1" /f >nul 2>&1
Reg add "HKLM\zSYSTEM\Setup\LabConfig" /v "BypassRAMCheck" /t REG_DWORD /d "1" /f >nul 2>&1
Reg add "HKLM\zSYSTEM\Setup\LabConfig" /v "BypassSecureBootCheck" /t REG_DWORD /d "1" /f >nul 2>&1
Reg add "HKLM\zSYSTEM\Setup\LabConfig" /v "BypassStorageCheck" /t REG_DWORD /d "1" /f >nul 2>&1
Reg add "HKLM\zSYSTEM\Setup\LabConfig" /v "BypassTPMCheck" /t REG_DWORD /d "1" /f >nul 2>&1
Reg add "HKLM\zSYSTEM\Setup\MoSetup" /v "AllowUpgradesWithUnsupportedTPMOrCPU" /t REG_DWORD /d "1" /f >nul 2>&1
@echo.Tweaking complete!
@echo.Unmounting Registry...
reg unload HKLM\zCOMPONENTS >nul 2>&1
reg unload HKLM\zDRIVERS >nul 2>&1
reg unload HKLM\zDEFAULT >nul 2>&1
reg unload HKLM\zNTUSER >nul 2>&1
reg unload HKLM\zSCHEMA >nul 2>&1
reg unload HKLM\zSOFTWARE >nul 2>&1
reg unload HKLM\zSYSTEM >nul 2>&1
@echo.Unmounting image...
dism /unmount-image /mountdir:%~dp0WindowsInstall /commit || ( call :showerror "Dism Unmount boot.wim failed." & goto Stop )
rd /s /q %~dp0WindowsInstall >NUL
@echo.the Minify image is now completed. Proceeding with the making of the ISO...
@echo.Copying unattended file for bypassing MS account on OOBE...
copy /y %~dp0unattended\%autounattend% %~dp0ISOImage\autounattend.xml
@echo.
:resume2
@rem saving existing "Minified%ISOVersion%.iso" file
if exist Minified%ISOVersion%.iso ren Minified%ISOVersion%.iso "Minified%ISOVersion%-%date:~10,4%%date:~7,2%%date:~4,2%-%time:~0,2%%time:~3,2%.iso"

@echo.Creating ISO image... Make sure that you have oscdimg.exe from Windows ADK in your PATH.
oscdimg.exe -m -o -u2 -udfver102 -bootdata:2#p0,e,b%~dp0ISOImage\boot\etfsboot.com#pEF,e,b%~dp0ISOImage\efi\microsoft\boot\efisys.bin %~dp0ISOImage %~dp0Minified%ISOVersion%.iso  || call :showerror "Creating image with oscdimg.exe failed."

@rem list created ISO file
dir %~dp0Minified%ISOVersion%.iso

:Stop
@rem Performing Cleanup...
rd /s /q %~dp0ISOImage >NUL 2>NUL
rd /s /q %~dp0WindowsInstall >NUL 2>NUL
del /f /q %TEMP%\longAppPackageNames.txt %TEMP%\pureLongAppPackageNames.txt %TEMP%\uncomAppPackageNames.txt %TEMP%\longAppPackageNamesToRemove.txt %TEMP%\longSysPackageNames.txt %TEMP%\pureLongSysPackageNames.txt %TEMP%\uncomSysPackageNames.txt %TEMP%\LongSysPackageNamesToRemove.txt %TEMP%\longCapabilties.txt %TEMP%\pureLongCapabilties.txt %TEMP%\uncomCapabilityNames.txt %TEMP%\LongCapabiltiesToRemove.txt %TEMP%\uncomFeatureNames.txt >NUL 2>NUL
@echo.End of Minify script...
pause
endlocal
goto quit

@rem simple echo fails to color stdout after the error. subroutine works.
:showerror
@echo.%ESC%[91m%~1%ESC%[93m
:quit
