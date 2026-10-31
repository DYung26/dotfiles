@echo off
cd /d C:\Users\oyeku
set "ECHOPROFILE_HOST=100.98.45.0"
set "ECHOPROFILE_CHANNEL=msedge"
set "ECHOPROFILE_MULTICA_DIR=%USERPROFILE%/Projects/multica-web-runtime/extension/dist"
set "ECHOPROFILE_NO_RELOAD=1"
"C:\Users\oyeku\.local\bin\echoprofile.exe" serve >> "%LOCALAPPDATA%\EchoProfile\serve.log" 2>&1
