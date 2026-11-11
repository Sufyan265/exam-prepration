@echo off
setlocal enabledelayedexpansion
set "D=C:\Program Files\SafeExamBrowser\Application"

rem --- self-elevate ---
net session >nul 2>&1
if errorlevel 1 (
  powershell -nop -ep bypass -c "Start-Process '%~f0' -Verb RunAs"
  exit /b
)

echo Closing SEB...
taskkill /f /t /im SafeExamBrowser.exe >nul 2>&1
taskkill /f /t /im SafeExamBrowser.Client.exe >nul 2>&1
timeout /t 2 >nul

set n=0
for %%F in ("%D%\*.backup") do (
  if exist "%%~dpnF" del /f /q "%%~dpnF" >nul 2>&1
  ren "%%F" "%%~nF" >nul 2>&1
  echo restored: %%~nF
  set /a n+=1
)

echo.
echo Restored: !n! file(s)
dir /b "%D%\*.backup" >nul 2>&1 && (echo WARNING - backups still present) || (echo Clean - SEB is original again)
echo.
pause