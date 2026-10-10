@echo off
cd /d "%~dp0"
set CSC_IDENTITY_AUTO_DISCOVERY=false
echo === Building CubicLauncher for Windows ===
where node >nul 2>nul
if errorlevel 1 goto :nonode
call npm install
if errorlevel 1 goto :fail

rem Workaround for "Cannot create symbolic link" in winCodeSign (mac-only symlinks are not needed).
set "WCS=%LOCALAPPDATA%\electron-builder\Cache\winCodeSign"
if exist "%WCS%\winCodeSign-2.6.0\windows-10" goto :built
echo Preparing winCodeSign...
if not exist "%WCS%" mkdir "%WCS%"
if not exist "%WCS%\winCodeSign-2.6.0.7z" powershell -NoProfile -Command "Invoke-WebRequest -UseBasicParsing https://github.com/electron-userland/electron-builder-binaries/releases/download/winCodeSign-2.6.0/winCodeSign-2.6.0.7z -OutFile '%WCS%\winCodeSign-2.6.0.7z'"
"%~dp0node_modules\7zip-bin\win\x64\7za.exe" x -y -bd "%WCS%\winCodeSign-2.6.0.7z" "-o%WCS%\winCodeSign-2.6.0" >nul 2>nul
:built

call npm run dist > build.log 2>&1
set RC=%errorlevel%
type build.log
if not "%RC%"=="0" goto :fail
echo.
echo DONE. See the dist folder: CubicLauncher-Setup-*.exe and CubicLauncher-Portable-*.exe
explorer dist
pause
exit /b 0

:nonode
echo Node.js not found. Install Node 20+ from https://nodejs.org
pause
exit /b 1

:fail
echo.
echo BUILD FAILED. See the error above and build.log
pause
exit /b 1
