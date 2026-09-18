@echo off
setlocal enabledelayedexpansion
cd /d %~dp0

echo ========================================================
echo [RELEASE WIZARD] Compiling & Packaging Release Asset
echo ========================================================
echo.

echo [1/3] Building Windows application in Release mode...
call flutter build windows
if %ERRORLEVEL% neq 0 (
    echo [ERROR] Flutter build failed!
    pause
    exit /b %ERRORLEVEL%
)

echo [2/3] Auto-detecting app name and version from pubspec.yaml...
set "PROJECT_NAME="
for /f "tokens=2 delims=: " %%a in ('findstr /r "^name:" pubspec.yaml') do set "PROJECT_NAME=%%a"
if "%PROJECT_NAME%"=="" set "PROJECT_NAME=app"

set "APP_VERSION="
for /f "tokens=2 delims=: " %%a in ('findstr /r "^version:" pubspec.yaml') do set "APP_VERSION=%%a"
if "%APP_VERSION%"=="" set "APP_VERSION=1.0.0"

for /f "tokens=1 delims=+" %%a in ("%APP_VERSION%") do set "VERSION_NAME=%%a"

set "ZIP_NAME=%PROJECT_NAME%_v%VERSION_NAME%_win64.zip"

echo [3/3] Packaging release ZIP (%ZIP_NAME%)...
powershell -NoProfile -Command "Compress-Archive -Path 'build\windows\x64\runner\Release\*' -DestinationPath '%ZIP_NAME%' -Force"

if exist "%ZIP_NAME%" (
    echo.
    echo ========================================================
    echo [SUCCESS] Release ZIP created successfully!
    echo Asset File: %ZIP_NAME%
    echo Release Tag: v%VERSION_NAME%
    echo.
    echo GitHub CLI (gh) Command to publish:
    echo   gh release create v%VERSION_NAME% "%ZIP_NAME%" --title "%PROJECT_NAME% v%VERSION_NAME%" --notes "Release v%VERSION_NAME%"
    echo ========================================================
) else (
    echo [ERROR] Failed to create ZIP package!
)

pause
