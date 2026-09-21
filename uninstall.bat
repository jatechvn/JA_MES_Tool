@echo off
setlocal EnableExtensions DisableDelayedExpansion
chcp 65001 >nul

set "ORIGIN=%~dp0"
if "%ORIGIN:~-1%"=="\" set "ORIGIN=%ORIGIN:~0,-1%"

if "%~1"=="--staged" goto run

set "UID=%RANDOM%_%RANDOM%"
set "UNINSTALL_DRIVER=%TEMP%\JA_MES_Uninstall_%UID%.bat"
set "UNINSTALL_PS=%TEMP%\JA_MES_Uninstall_%UID%.ps1"
set "UNINSTALL_MODE=%~1"

copy /y "%~f0" "%UNINSTALL_DRIVER%" >nul
if errorlevel 1 exit /b 1

copy /y "%ORIGIN%\uninstall.ps1" "%UNINSTALL_PS%" >nul
if errorlevel 1 exit /b 1

cd /d "%TEMP%"
"%UNINSTALL_DRIVER%" --staged "%UNINSTALL_PS%" "%ORIGIN%" "%UNINSTALL_MODE%"
exit /b %errorlevel%

:run
cd /d "%TEMP%"
set "PS_SCRIPT=%~2"
set "ORIGIN=%~3"
set "MODE=%~4"

powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%PS_SCRIPT%" -Origin "%ORIGIN%" -Mode "%MODE%"
set "EXIT_CODE=%errorlevel%"

del /f /q "%PS_SCRIPT%" 2>nul
(goto) 2>nul & del /f /q "%~f0" 2>nul & exit /b %EXIT_CODE%
