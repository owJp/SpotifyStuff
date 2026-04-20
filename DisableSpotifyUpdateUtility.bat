@echo off
:: Check for Administrator privileges
net session >nul 2>&1
if %errorLevel% neq 0 (
    echo.
    echo ERROR: This script must be run as an ADMINISTRATOR.
    echo Please right-click the file and select 'Run as administrator'.
    echo.
    pause
    exit /b
)

set "updateFolder=%localappdata%\Spotify\Update"
set "regKey1=HKLM\SOFTWARE\Policies\Spotify"
set "regKey2=HKLM\SOFTWARE\WOW6432Node\Policies\Spotify"

echo 1. Lock Spotify Updates (Close Spotify + Disable Update Folder + Registry)
echo 2. Unlock Spotify Updates (Revert Changes)
set /p choice="Choose an option (1 or 2): "

if "%choice%"=="1" (
    :: 0. Kill Spotify process to properly apply changes
    taskkill /f /im spotify.exe >nul 2>&1

    :: 1. Lock and prevent Spotify from adding/instaling updates inside the folder
    if exist "%updateFolder%" rd /s /q "%updateFolder%"
    mkdir "%updateFolder%"
    icacls "%updateFolder%" /deny "%username%":D
    icacls "%updateFolder%" /deny "%username%":R
    
    :: 2. Registry to disable autoupdate (Standard)
    reg add "%regKey1%" /v "DisableAutoUpdate" /t REG_DWORD /d 1 /f
    reg add "%regKey1%" /v "DisableAutomaticUpdates" /t REG_DWORD /d 1 /f
    reg add "%regKey1%" /v "DisableAutomaticUpdate" /t REG_DWORD /d 1 /f

    :: 3. Registry to disable autoupdate (WOW6432Node)
    reg add "%regKey2%" /v "DisableAutoUpdate" /t REG_DWORD /d 1 /f
    reg add "%regKey2%" /v "DisableAutomaticUpdates" /t REG_DWORD /d 1 /f
    reg add "%regKey2%" /v "DisableAutomaticUpdate" /t REG_DWORD /d 1 /f
    
    echo.
    echo Status: Spotify killed, Update LOCKED, and Registry Policies added.
) else if "%choice%"=="2" (
    :: 1. Reset Spotify folder back to default
    icacls "%updateFolder%" /reset /t
    
    :: 2. Revert registry changes back to default
    reg delete "%regKey1%" /f >nul 2>&1
    reg delete "%regKey2%" /f >nul 2>&1
    
    echo.
    echo Status: Spotify Updates UNLOCKED. Permissions reset and Registry Policies removed (changes reverted).
) else (
    echo.
    echo Invalid choice.
)

pause
