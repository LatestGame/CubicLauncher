@echo off
chcp 65001 >nul
cd /d "%~dp0"
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0make-portable.ps1"
if errorlevel 1 (
  echo.
  echo Сборка не удалась - смотрите ошибку выше.
)
pause
