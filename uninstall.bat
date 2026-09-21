@echo off
setlocal EnableExtensions DisableDelayedExpansion
chcp 65001 >nul
if "%~1"=="--staged" goto run
set "UNINSTALL_HELPER=%~dp0uninstall.ps1"
set "UNINSTALL_ORIGIN=%~dp0"
set "UNINSTALL_MODE=%~1"
set "UNINSTALL_DRIVER=%TEMP%\JA_MES_Uninstall_%RANDOM%_%RANDOM%.bat"
copy /y "%~f0" "%UNINSTALL_DRIVER%" >nul
if errorlevel 1 exit /b 1
cd /d "%TEMP%"
"%UNINSTALL_DRIVER%" --staged
exit /b %errorlevel%
:run
cd /d "%TEMP%"
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%UNINSTALL_HELPER%" -Mode "%UNINSTALL_MODE%"
set "EXIT_CODE=%errorlevel%"
del /f /q "%~f0" 2>nul
exit /b %EXIT_CODE%
