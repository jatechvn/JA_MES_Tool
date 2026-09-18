@echo off
cd /d %~dp0
echo [BUILD] Compiling Windows desktop application in Release mode...
call flutter build windows
if %ERRORLEVEL% neq 0 (
    echo [ERROR] Build failed!
    pause
    exit /b %ERRORLEVEL%
)

echo [LINK] Creating shortcut .Release.lnk to Release directory...
powershell -NoProfile -Command "$WshShell = New-Object -ComObject WScript.Shell; $Shortcut = $WshShell.CreateShortcut('.Release.lnk'); $Shortcut.TargetPath = Join-Path (Get-Item .).FullName 'build\windows\x64\runner\Release'; $Shortcut.Save()"
echo [SUCCESS] Release build complete. Shortcut .Release.lnk created.
pause
