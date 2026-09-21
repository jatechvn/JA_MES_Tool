@echo off
cd /d %~dp0
echo [BUILD] Compiling Windows desktop application in Release mode...
call flutter build windows --release
if %ERRORLEVEL% neq 0 (
    echo [ERROR] Build failed!
    pause
    exit /b %ERRORLEVEL%
)

set "REL=build\windows\x64\runner\Release"
if exist "%REL%\config.json" del /f /q "%REL%\config.json"
if exist "%REL%\config.ini" del /f /q "%REL%\config.ini"
if exist "%REL%\logs" rmdir /s /q "%REL%\logs"

for %%f in (install.bat uninstall.bat uninstall.ps1 debug.bat ABOUT.txt README.md CHANGELOG.md RELEASE_NOTES.md USERGUIDE.md LICENSE) do (
    if exist "%%f" copy /y "%%f" "%REL%\" >nul
)

echo [STAGE] Syncing files to dist...
if not exist "dist" mkdir "dist"
robocopy "%REL%" "dist" /E /R:1 /W:1 /XD logs /XF config.json config.ini *.log *.key >nul

echo [OTA] Generating dist/version.json metadata...
powershell -NoProfile -ExecutionPolicy Bypass -Command "$pub = Get-Content 'pubspec.yaml' -Raw; if ($pub -match '(?m)^version:\s*([^\r\n]+)') { $v = $Matches[1].Trim(); $baseV = $v.Split('+')[0]; $zip = 'JA_MES_Tool_v' + $baseV + '_Windows_x64.zip'; $notes = ''; if (Test-Path 'RELEASE_NOTES.md') { $notes = (Get-Content 'RELEASE_NOTES.md' -Raw).Trim() }; if (-not (Test-Path 'dist')) { New-Item -ItemType Directory -Path 'dist' | Out-Null }; $meta = [ordered]@{ version = $v; fileName = $zip; releaseNotes = $notes; releaseDate = (Get-Date -Format 'yyyy-MM-ddTHH:mm:ssZ') }; $meta | ConvertTo-Json -Depth 4 | Set-Content 'dist\version.json' -Encoding UTF8; Write-Host ('[OTA] version.json created with version ' + $v) }"

echo [LINK] Creating shortcut .Release.lnk to Release directory...
powershell -NoProfile -Command "$WshShell = New-Object -ComObject WScript.Shell; $Shortcut = $WshShell.CreateShortcut('.Release.lnk'); $Shortcut.TargetPath = Join-Path (Get-Item .).FullName 'build\windows\x64\runner\Release'; $Shortcut.Save()"
echo [SUCCESS] Release build complete. Shortcut .Release.lnk created.
pause
