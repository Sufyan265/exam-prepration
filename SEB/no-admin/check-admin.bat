@echo off
set "RESULT=NOT ADMIN"

net session >nul 2>&1
if "%errorlevel%"=="0" (
    set "RESULT=ADMIN"
    goto :done
)

whoami /groups 2>nul | find "S-1-5-32-544" >nul 2>&1
if "%errorlevel%"=="0" (
    set "RESULT=ADMIN (NON-ELEVATED)"
)

:done
echo %RESULT%
echo.
@REM whoami /groups | find "S-1-5-32-544"
pause
