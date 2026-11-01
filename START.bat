@echo off
start "" "C:\Program Files\Google\Chrome\Application\chrome.exe" ^
  --user-data-dir="%~dp0profile" --disable-background-timer-throttling ^
  --new-window "file:///%~dp0ai_cloud.html"