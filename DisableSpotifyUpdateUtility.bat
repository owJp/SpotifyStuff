@echo off
setlocal EnableDelayedExpansion

:: ============================================================
::  Spotify Auto-Update Disabler/Enabler
::  Compatible: Windows 10 / 11
:: ============================================================

:: Auto-relaunch as Administrator if not already elevated
net session >nul 2>&1
if %errorLevel% neq 0 (
    echo Requesting Administrator privileges...
    powershell -Command "Start-Process '%~f0' -Verb RunAs"
    exit /b
)

set "spotifyBase=%localappdata%\Spotify"
set "updateFolder=%localappdata%\Spotify\Update"
set "regKey1=HKLM\SOFTWARE\Policies\Spotify"
set "regKey2=HKLM\SOFTWARE\WOW6432Node\Policies\Spotify"

echo.
echo  =============================================
echo   Spotify Update Utility
echo  =============================================
echo   1. LOCK   - Disable Spotify auto-updates
echo   2. UNLOCK - Re-enable Spotify auto-updates
echo  =============================================
echo.
set /p choice=" Choose an option (1 or 2): "

if "%choice%"=="1" goto :LOCK
if "%choice%"=="2" goto :UNLOCK
echo.
echo  Invalid choice. Please enter 1 or 2.
echo.
pause
exit /b

:: ============================================================
:LOCK
:: ============================================================

echo.
echo  [1/4] Killing Spotify process...
taskkill /f /im spotify.exe >nul 2>&1

echo  [2/4] Resetting and locking Update folder...

:: Remove existing Update folder (clean slate)
if exist "%updateFolder%" (
    :: Reset permissions first so rd can delete it even if previously locked
    icacls "%updateFolder%" /reset /t /q >nul 2>&1
    rd /s /q "%updateFolder%" >nul 2>&1
)

:: Recreate the folder as a decoy/blocker
mkdir "%updateFolder%" >nul 2>&1
if not exist "%updateFolder%" (
    echo  ERROR: Could not create Update folder. Check that Spotify is installed.
    pause
    exit /b
)

:: Deny Delete, Write, and Create on the Update folder itself
:: (OI)(CI) ensures the deny propagates to any files/subfolders Spotify might try to create inside
icacls "%updateFolder%" /deny "%username%":(OI)(CI)(DE,WD,AD,WA) /q
icacls "%updateFolder%" /deny "SYSTEM":(OI)(CI)(DE,WD,AD,WA) /q

:: Also deny write/create-child on the PARENT Spotify folder so Spotify
:: cannot delete and recreate the Update folder from scratch
icacls "%spotifyBase%" /deny "%username%":(AD) /q
icacls "%spotifyBase%" /deny "SYSTEM":(AD) /q

echo  [3/4] Adding Registry policies...

:: Standard 64-bit hive
reg add "%regKey1%" /v "DisableAutoUpdate"        /t REG_DWORD /d 1 /f >nul
reg add "%regKey1%" /v "DisableAutomaticUpdates"  /t REG_DWORD /d 1 /f >nul
reg add "%regKey1%" /v "DisableAutomaticUpdate"   /t REG_DWORD /d 1 /f >nul

:: WOW6432Node (32-bit apps on 64-bit Windows)
reg add "%regKey2%" /v "DisableAutoUpdate"        /t REG_DWORD /d 1 /f >nul
reg add "%regKey2%" /v "DisableAutomaticUpdates"  /t REG_DWORD /d 1 /f >nul
reg add "%regKey2%" /v "DisableAutomaticUpdate"   /t REG_DWORD /d 1 /f >nul

echo  [4/4] Done!
echo.
echo  STATUS: Spotify updates LOCKED.
echo   - Update folder is locked and write-protected
echo   - Parent folder blocked from recreating Update folder
echo   - Registry policies applied (both 64-bit and 32-bit hives)
echo.
pause
exit /b

:: ============================================================
:UNLOCK
:: ============================================================

echo.
echo  [1/3] Resetting folder permissions...

if exist "%updateFolder%" (
    icacls "%updateFolder%" /reset /t /q >nul 2>&1
    echo   Update folder permissions reset.
) else (
    echo   Update folder not found - skipping folder reset.
)

:: Also reset the parent Spotify folder deny we added during lock
if exist "%spotifyBase%" (
    icacls "%spotifyBase%" /reset /q >nul 2>&1
    echo   Spotify base folder permissions reset.
)

echo  [2/3] Removing Registry policies...
reg delete "%regKey1%" /f >nul 2>&1
reg delete "%regKey2%" /f >nul 2>&1

echo  [3/3] Done!
echo.
echo  STATUS: Spotify updates UNLOCKED.
echo   - Folder permissions restored to default
echo   - Registry policies removed
echo.
pause
exit /b
