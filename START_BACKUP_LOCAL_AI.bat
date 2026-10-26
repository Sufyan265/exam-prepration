@echo off
start "" "%~dp0llama\koboldcpp-oldpc.exe" --model "%~dp0llama\qwen2.5-1.5b-instruct-q4_k_m.gguf" ^
  --contextsize 2048 --threads 4 --port 5001 --launch
timeout /t 8 >nul
start "" "%~dp0chrome\chrome.exe" --user-data-dir="%~dp0profile" ^
  --new-window "file:///%~dp0ai_local.html"