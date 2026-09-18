@echo off
cd /d %~dp0
echo [LAUNCH] Starting Flutter Windows desktop application...
call flutter run -d windows
if %ERRORLEVEL% neq 0 (
    echo [ERROR] Flutter run failed!
    pause
    exit /b %ERRORLEVEL%
)
