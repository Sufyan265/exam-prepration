@echo off
start "" "%~dp0llama\llama-b11874-bin-win-cpu-x64\llama-server.exe" -m "%~dp0llama\qwen2.5-1.5b-instruct-q4_k_m.gguf" ^
  -c 2048 -t 4 --port 8080
timeout /t 8 >nul
start "" "C:\Program Files\Google\Chrome\Application\chrome.exe" --user-data-dir="%~dp0profile" ^
  --new-window "file:///%~dp0ai_local.html"