@echo off
start "" "%~dp0chrome\chrome.exe" --user-data-dir="%~dp0profile" ^
  --disable-background-timer-throttling --disable-features=CalculateNativeWinOcclusion ^
  --new-window "file:///%~dp0ai_cloud.html"