@echo off
if exist "%APPDATA%\SafeExamBrowser_old" rd /s /q "%APPDATA%\SafeExamBrowser_old"
if exist "%LOCALAPPDATA%\SafeExamBrowser_old" rd /s /q "%LOCALAPPDATA%\SafeExamBrowser_old"
if exist "%PROGRAMDATA%\SafeExamBrowser_old" rd /s /q "%PROGRAMDATA%\SafeExamBrowser_old"
if exist "%APPDATA%\SafeExamBrowser" move "%APPDATA%\SafeExamBrowser" "%APPDATA%\SafeExamBrowser_old"
if exist "%LOCALAPPDATA%\SafeExamBrowser" move "%LOCALAPPDATA%\SafeExamBrowser" "%LOCALAPPDATA%\SafeExamBrowser_old"
if exist "%PROGRAMDATA%\SafeExamBrowser" move "%PROGRAMDATA%\SafeExamBrowser" "%PROGRAMDATA%\SafeExamBrowser_old"
echo done
pause