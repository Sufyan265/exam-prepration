@echo off
net session >nul 2>&1
if errorlevel 1 (
  powershell -nop -ep bypass -c "Start-Process '%~f0' -Verb RunAs"
  exit /b
)
taskkill /f /t /im SafeExamBrowser.exe >nul 2>&1
start "" "%~dp0/SEB/SEB-Patch version/v1.10 (SEB v3.10.2.920).exe"