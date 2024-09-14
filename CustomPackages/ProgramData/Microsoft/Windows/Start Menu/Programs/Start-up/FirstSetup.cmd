@echo off

call :ForceAdministrator
call :SETOPTIONS
call :CMDHelper
cd %temp%
if not exist MinifyBuilder (
    mkdir MinifyBuilder
)
cd MinifyBuilder

title Minify Builder
call CMDHelper "Function=Text" "Text=[blue]Welcome to the Minify Builder[/]" "Position=Center"

set /p Option="Automaticly Pick Software? (yes/no)"
if /i "%Option%"=="yes" (
    goto :auto
)

:ask
set /p NINITE="Do you want to install libraries via Ninite (yes/no)? "
set /p INSTALL_7ZIP="Do you want to install 7-Zip (yes/no)? "
set /p INSTALL_GIT="Do you want to install Git (yes/no)? "
set /p INSTALL_NODE="Do you want to install Node.js (yes/no)? "
set /p INSTALL_PYTHON="Do you want to install Python (yes/no)? "
set /p INSTALL_VLC="Do you want to install VLC (yes/no)? "
set /p INSTALL_NOTEPAD="Do you want to install Notepad++ (yes/no)? "
goto :InstallSoftware

:auto
set "NINITE=yes"
set "INSTALL_7ZIP=yes"
set "INSTALL_GIT=yes"
set "INSTALL_NODE=no"
set "INSTALL_PYTHON=yes"
set "INSTALL_VLC=yes"
set "INSTALL_NOTEPAD=no"
goto :InstallSoftware

:InstallSoftware

cls
:: Prompt for Ninite libraries
if /i "%NINITE%"=="yes" (
    call :InstallNinite
)

:: Prompt for 7-Zip installation
if /i "%INSTALL_7ZIP%"=="yes" (
    call :Install7ZIP
)

:: Prompt for Git installation
if /i "%INSTALL_GIT%"=="yes" (
    call :InstallGit
)

:: Prompt for Node.js installation
if /i "%INSTALL_NODE%"=="yes" (
    call :InstallNode
)

:: Prompt for Python installation
if /i "%INSTALL_PYTHON%"=="yes" (
    call :InstallPython
)

:: Prompt for VLC installation
if /i "%INSTALL_VLC%"=="yes" (
    call :InstallVLC
)

:: Prompt for Notepad++ installation
if /i "%INSTALL_NOTEPAD%"=="yes" (
    call :InstallNotepad
)

call CMDHelper "Function=Text" "Text=[green]All operations completed successfully.[/]" "Position=Center"
set /p DELETEFILE="Delete File (yes/no)? "
if /i "%DELETEFILE%"=="yes" (
    del /F /Q "%~f0"
)

pause
goto :Exit

:: Install Commands
:InstallNinite
call CMDHelper "Function=Text" "Text=[blue]Downloading Ninite Libraries...[/]" "Position=Left"
echo.
call CMDHelper Function=DownloadFile "Url=%NINITE_URL%" FileName=%NINITE_PATH%
call CMDHelper "Function=Text" "Text=[blue]Installing Ninite Libraries...[/]" "Position=Left"
echo.
start /min %NINITE_PATH%
exit /b

:Install7ZIP
call CMDHelper "Function=Text" "Text=[blue]Downloading 7-Zip...[/]" "Position=Left"
echo.
call CMDHelper Function=DownloadFile "Url=%ZIP7_URL%" FileName=%ZIP7_PATH%
call CMDHelper "Function=Text" "Text=[blue]Installing 7-Zip...[/]" "Position=Left"
echo.
call %ZIP7_PATH% /S
call CMDHelper "Function=Text" "Text=[blue]Installed 7-Zip[/]" "Position=Left"
echo.
exit /b

:InstallGit
call CMDHelper "Function=Text" "Text=[yellow]Downloading Git...[/]" "Position=Left"
echo.
call CMDHelper Function=DownloadFile "Url=%GIT_URL%" FileName=%GIT_PATH%
call CMDHelper "Function=Text" "Text=[yellow]Installing Git...[/]" "Position=Left"
echo.
call %GIT_PATH% /SILENT /NORESTART
call CMDHelper "Function=Text" "Text=[yellow]Installed Git[/]" "Position=Left"
echo.
exit /b

:InstallNode
call CMDHelper "Function=Text" "Text=[cyan]Downloading Node.js...[/]" "Position=Left"
echo.
call CMDHelper Function=DownloadFile "Url=%NODE_URL%" FileName=%NODE_PATH%
call CMDHelper "Function=Text" "Text=[cyan]Installing Node.js...[/]" "Position=Left"
echo.
call %NODE_PATH% /quiet /norestart
call CMDHelper "Function=Text" "Text=[cyan]Installed Node.js[/]" "Position=Left"
echo.
exit /b

:InstallPython
call CMDHelper "Function=Text" "Text=[purple]Downloading Python...[/]" "Position=Left"
echo.
call CMDHelper Function=DownloadFile "Url=%PYTHON_URL%" FileName=%PYTHON_PATH%
call CMDHelper "Function=Text" "Text=[purple]Installing Python...[/]" "Position=Left"
echo.
call %PYTHON_PATH% /quiet InstallAllUsers=1 PrependPath=1
call CMDHelper "Function=Text" "Text=[purple]Installed Python[/]" "Position=Left"
echo.
exit /b

:InstallVLC
call CMDHelper "Function=Text" "Text=[orangered1]Downloading VLC...[/]" "Position=Left"
echo.
call CMDHelper Function=DownloadFile "Url=%VLC_URL%" FileName=%VLC_PATH%
call CMDHelper "Function=Text" "Text=[orangered1]Installing VLC...[/]" "Position=Left"
echo.
call %VLC_PATH% /L=1033 /S
call CMDHelper "Function=Text" "Text=[orangered1]Installed VLC[/]" "Position=Left"
echo.
exit /b

:InstallNotepad
call CMDHelper "Function=Text" "Text=[lightgreen]Downloading Notepad++...[/]" "Position=Left"
echo.
call CMDHelper Function=DownloadFile "Url=%NOTEPAD_URL%" FileName=%NOTEPAD_PATH%
call CMDHelper "Function=Text" "Text=[lightgreen]Installing Notepad++...[/]" "Position=Left"
echo.
call %NOTEPAD_PATH% /S
call CMDHelper "Function=Text" "Text=[lightgreen]Installed Notepad++[/]" "Position=Left"
echo.
exit /b 


:: Functions
:ForceAdministrator
net session >nul 2>&1
if %errorLevel% neq 0 (
    echo Requesting administrative privileges...
    powershell -NoProfile -Command "Start-Process '%~f0' -Verb RunAs"
    exit
)
exit /b

:SETOPTIONS
set "NINITE_URL=https://ninite.com/.net4.8.1-.netx6-.netx8-git-python-nodejs-vlc-npp/ninite.exe"
set "NINITE_PATH=NiniteInstaller.exe"

set "ZIP7_URL=https://unlimited.dl.sourceforge.net/project/sevenzip/7-Zip/24.08/7z2408-x64.exe?viasf=1"
set "ZIP7_PATH=7ZIPInstaller.exe"

set "GIT_URL=https://github.com/git-for-windows/git/releases/download/v2.46.0.windows.1/Git-2.46.0-64-bit.exe"
set "GIT_PATH=GitInstaller.exe"

set "NODE_URL=https://nodejs.org/dist/v20.17.0/node-v20.17.0-x64.msi"
set "NODE_PATH=NodeInstaller.msi"

set "PYTHON_URL=https://www.python.org/ftp/python/3.12.6/python-3.12.6-amd64.exe"
set "PYTHON_PATH=PythonInstaller.exe"

set "VLC_URL=https://get.videolan.org/vlc/3.0.21/win64/vlc-3.0.21-win64.exe"
set "VLC_PATH=VLCInstaller.exe"

set "NOTEPAD_URL=https://github.com/notepad-plus-plus/notepad-plus-plus/releases/download/v8.6.9/npp.8.6.9.Installer.x64.exe"
set "NOTEPAD_PATH=NotepadPlusPlusInstaller.exe"
exit /b

:CMDHelper
if not exist CMDHelper.exe (
    echo CMDHelper.exe not found. Downloading now...
    REM Download CMDHelper.exe from the GitHub repository
    curl https://github.com/MagmaMCNet/CMDHelper/releases/download/1.0.0/CMDHelper.exe -L -o CMDHelper.exe >nul 2>&1

    REM Verify if the download was successful
    if exist CMDHelper.exe (
        echo CMDHelper.exe has been successfully downloaded.
    ) else (
        echo Failed to download CMDHelper.exe.
    )
)

exit /b
:Exit
exit /b