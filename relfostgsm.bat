@echo off
REM relfostgsm - Universal installer for RGSM (Windows)

:: Define RGSM directory
set RGSM_DIR=%~dp0rgsm
set TMP_DIR=%RGSM_DIR%\tmp

:: Create tmp directory if not exists
if not exist "%TMP_DIR%" mkdir "%TMP_DIR%"

:: Define available games
set GAMES=rust:Rust terraria:Terraria satisfactory:Satisfactory

:: Check for passed argument
if "%1"=="" (
    REM Download game selector script if not exists
    if not exist "%TMP_DIR%\game_selector.ps1" (
        powershell -Command "Invoke-WebRequest -Uri 'https://raw.githubusercontent.com/RelFost/RelfostGSM/main/windows/tmp/game_selector.ps1' -OutFile '%TMP_DIR%\game_selector.ps1'"
    )

    REM Call PowerShell script to select game
    for /f "delims=" %%G in ('powershell -NoProfile -ExecutionPolicy Bypass -File "%TMP_DIR%\game_selector.ps1" -gamesRaw "%GAMES%"') do set GAME=%%G
) else (
    set GAME=%1
)

:: Check if GAME is defined
if not defined GAME (
    echo Invalid selection. Exiting...
    exit /b 1
)

:: Determine Windows version
for /f "tokens=4-5 delims=[]. " %%a in ('ver') do set WINVER=%%a
if %WINVER%==10 set WINFILE=10.csv
if %WINVER%==11 set WINFILE=11.csv
if %WINVER%==7 set WINFILE=7.csv
if "%WINFILE%"=="" (
    echo Unsupported Windows version: %WINVER%.
    exit /b 1
)

:: Check for CSV file
set CSV_FILE=%RGSM_DIR%\windows\%WINFILE%
if not exist "%CSV_FILE%" (
    echo Required file not found: %CSV_FILE%.
    exit /b 1
)

:: Install required packages from CSV
echo Checking and installing required packages for Windows %WINVER%...
powershell -NoProfile -ExecutionPolicy Bypass -Command ^
"Import-Csv '%CSV_FILE%' | ForEach-Object { ^
    Write-Host 'Checking package:' $_.Package; ^
    if (!(Get-Package -Name $_.Package -ErrorAction SilentlyContinue)) { ^
        Write-Host 'Installing:' $_.Package; ^
        if ($_.DownloadUrl) { ^
            $installer = Join-Path $env:TEMP ([System.IO.Path]::GetFileName($_.DownloadUrl)); ^
            Invoke-WebRequest -Uri $_.DownloadUrl -OutFile $installer; ^
            Start-Process $installer -ArgumentList $_.Arguments -Wait; ^
            Remove-Item $installer -Force; ^
        } else { ^
            Write-Host 'No DownloadUrl provided for package:' $_.Package; ^
        } ^
    } else { ^
        Write-Host 'Package already installed:' $_.Package; ^
    } ^
}"

:: Check for module and download if not exists
set MODULE_FILE=%RGSM_DIR%\modules\%GAME%.ps1
if not exist "%MODULE_FILE%" (
    echo Downloading module for %GAME%...
    powershell -Command "Invoke-WebRequest -Uri 'https://raw.githubusercontent.com/RelFost/RelfostGSM/main/windows/modules/%GAME%.ps1' -OutFile '%MODULE_FILE%'"
)

:: Run the module
powershell -ExecutionPolicy Bypass -NoProfile -File "%MODULE_FILE%"

:: Clean up tmp directory
del /q "%TMP_DIR%\*.ps1"

:: Create required directories
if not exist "%RGSM_DIR%\config-default\%GAME%" (
    mkdir "%RGSM_DIR%\config-default\%GAME%"
)
if not exist "%RGSM_DIR%\config-rgsm\%GAME%" (
    mkdir "%RGSM_DIR%\config-rgsm\%GAME%"
)

:: Download default config
echo Downloading default configuration for %GAME%...
powershell -Command "Invoke-WebRequest -Uri 'https://raw.githubusercontent.com/RelFost/RelfostGSM/main/windows/config-default/%GAME%/_default.cfg' -OutFile '%RGSM_DIR%\config-default\%GAME%\_default.cfg'"

echo Configuration for %GAME% installed successfully.
exit /b 0
