@echo off
REM relfostgsm - Universal installer for RGSM (Windows)

:: Define RGSM directory
set RGSM_DIR=%~dp0rgsm

:: Define available games
set GAMES=rustserver trserver sfserver

:: Check for passed argument
if "%1"=="" (
    echo ============================================
    echo No game specified! Please choose one:
    echo [1] rustserver
    echo [2] trserver
    echo [3] sfserver
    echo ============================================
    set /p CHOICE=Enter the number of the game: 
    if "%CHOICE%"=="1" set GAME=rustserver
    if "%CHOICE%"=="2" set GAME=trserver
    if "%CHOICE%"=="3" set GAME=sfserver
    if not defined GAME (
        echo Invalid selection. Exiting...
        exit /b 1
    )
) else (
    set GAME=%1
)

:: Check if the game is valid
echo %GAMES% | findstr /i "\b%GAME%\b" >nul
if errorlevel 1 (
    echo Invalid game name: %GAME%.
    echo Available games: rustserver, trserver, sfserver.
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

:: Create required directories
if not exist "%RGSM_DIR%\config-default\%GAME%" (
    mkdir "%RGSM_DIR%\config-default\%GAME%"
)
if not exist "%RGSM_DIR%\config-rgsm\%GAME%" (
    mkdir "%RGSM_DIR%\config-rgsm\%GAME%"
)

:: Download default config
echo Downloading default configuration for %GAME%...
powershell -Command "Invoke-WebRequest -Uri 'https://raw.githubusercontent.com/your-repo/windows/config-default/%GAME%/_default.cfg' -OutFile '%RGSM_DIR%\config-default\%GAME%\_default.cfg'"

echo Configuration for %GAME% installed successfully.
exit /b 0
