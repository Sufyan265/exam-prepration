@echo off
cd /d "%~dp0"
taskkill /f /t /im SafeExamBrowser.exe >nul 2>&1
taskkill /f /t /im SafeExamBrowser.Client.exe >nul 2>&1
timeout /t 2 >nul
powershell -nop -ep bypass -NoExit -f "%~dp0relax.ps1"