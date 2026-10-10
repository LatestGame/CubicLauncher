@echo off
cd /d "%~dp0"
call npm run dist > build.log 2>&1
echo exit=%errorlevel% >> build.log
echo Готово, лог в build.log
pause
