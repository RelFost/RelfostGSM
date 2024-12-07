@echo off
REM relfostgsm - Universal installer for RGSM (Windows)

:: Define RGSM directory
set RGSM_DIR=%~dp0rgsm
set TMP_DIR=%RGSM_DIR%\tmp

:: Create tmp directory if not exists
if not exist "%TMP_DIR%" mkdir "%TMP_DIR%"

:: Define available games
set GAMES=rust:Rust terraria:Terraria satisfactory:Satisfactory

:: URL for the game selector script
set GAME_SELECTOR_URL=https://raw.githubusercontent.com/RelFost/RelfostGSM/develop/windows/tmp/game_selector.ps1
set LOCAL_GAME_SELECTOR=%TMP_DIR%\game_selector.ps1

:: Always download the latest game selector script
if exist "%LOCAL_GAME_SELECTOR%" del /q "%LOCAL_GAME_SELECTOR%"
echo Downloading the latest game selector script...
powershell -NoProfile -ExecutionPolicy Bypass -Command ^
"Invoke-WebRequest -Uri '%GAME_SELECTOR_URL%' -OutFile '%LOCAL_GAME_SELECTOR%'"
if errorlevel 1 (
    echo Failed to download game selector script. Exiting...
    exit /b 1
)

REM Call PowerShell script to select game
echo ============================================
echo No game specified! Please choose one:
for %%G in (%GAMES%) do (
    for /f "tokens=1,2 delims=:" %%A in ("%%G") do (
        echo [%%A] %%B
    )
)
echo ============================================
for /f "delims=" %%G in ('powershell -NoProfile -ExecutionPolicy Bypass -File "%LOCAL_GAME_SELECTOR%" -gamesRaw "%GAMES%"') do set GAME=%%G
if errorlevel 1 (
    echo Error occurred during game selection. Exiting...
    exit /b 1
)

:: Check if GAME is defined
if not defined GAME (
    echo Invalid selection. Exiting...
    exit /b 1
)

:: Output the selected game
echo Selected game code: %GAME%

:: Determine Windows version
for /f "tokens=4-5 delims=[]. " %%a in ('ver') do set WINVER=%%a
if %WINVER%==10 set WINFILE=windows/data/10.csv
if %WINVER%==11 set WINFILE=windows/data/11.csv
if %WINFILE%==7 set WINFILE=windows/data/7.csv
if "%WINFILE%"=="" (
    echo Unsupported Windows version: %WINVER%.
    exit /b 1
)

:: Check for CSV file
set CSV_FILE=%RGSM_DIR%\%WINFILE%
set GITHUB_URL=https://raw.githubusercontent.com/RelFost/RelfostGSM/develop/%WINFILE%
if not exist "%CSV_FILE%" (
    echo Required file not found: %CSV_FILE%.
    echo Attempting to download %WINFILE% from GitHub...
    echo Full URL: %GITHUB_URL%
    powershell -NoProfile -ExecutionPolicy Bypass -Command ^
    "Invoke-WebRequest -Uri '%GITHUB_URL%' -OutFile '%CSV_FILE%'"
    if errorlevel 1 (
        echo Failed to download required file: %WINFILE%. Exiting...
        exit /b 1
    )
)

:: Output the downloaded file for verification
echo Downloaded CSV file contents:
powershell -NoProfile -ExecutionPolicy Bypass -Command ^
"Get-Content -Path '%CSV_FILE%'"

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
            Start-Process -FilePath $installer -ArgumentList $_.Arguments -Wait; ^
            Remove-Item -Force $installer; ^
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
    powershell -NoProfile -ExecutionPolicy Bypass -Command ^
    "Invoke-WebRequest -Uri 'https://raw.githubusercontent.com/RelFost/RelfostGSM/develop/windows/modules/%GAME%.ps1' -OutFile '%MODULE_FILE%'"
    if errorlevel 1 (
        echo Failed to download module for %GAME%. Exiting...
        exit /b 1
    )
)

:: Run the module
powershell -NoProfile -ExecutionPolicy Bypass -File "%MODULE_FILE%"

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
powershell -NoProfile -ExecutionPolicy Bypass -Command ^
"Invoke-WebRequest -Uri 'https://raw.githubusercontent.com/RelFost/RelfostGSM/develop/windows/config-default/%GAME%/_default.cfg' -OutFile '%RGSM_DIR%\config-default\%GAME%\_default.cfg'"
if errorlevel 1 (
    echo Failed to download default configuration for %GAME%. Exiting...
    exit /b 1
)

echo Configuration for %GAME% installed successfully.
exit /b 0
