@echo off
title Luna — Starting...
color 0B
chcp 65001 >nul 2>&1

echo.
echo   ✦  Starting Luna from USB...
echo.

:: ── All paths live on the USB, not the host PC ──────────────────
set "USB=%~dp0"
set "OLLAMA_MODELS=%USB%ollama\data"
set "OLLAMA_HOME=%USB%ollama"
set "LUNA_DATA=%USB%luna_data"
set "WEBUI_DIR=%USB%open-webui"
set "VENV_PYTHON=%WEBUI_DIR%\venv\Scripts\python.exe"

:: Keep Open WebUI data on USB
set "DATA_DIR=%LUNA_DATA%"
set "WEBUI_SECRET_KEY=luna-usb-local-key"

:: ── Create data folder if needed ─────────────────────────────────
if not exist "%LUNA_DATA%" mkdir "%LUNA_DATA%"

:: ── Check ollama exists ──────────────────────────────────────────
if not exist "%USB%ollama\ollama.exe" (
    echo   [!] ollama.exe not found.
    echo       Please run install.bat first.
    echo.
    pause
    exit /b
)

:: ── Check Open WebUI exists ──────────────────────────────────────
if not exist "%VENV_PYTHON%" (
    echo   [!] Open WebUI not installed.
    echo       Please run install.bat first.
    echo.
    pause
    exit /b
)

:: ── Show installed model ─────────────────────────────────────────
if exist "%USB%models\installed-model.txt" (
    for /f "usebackq tokens=1,2 delims=|" %%a in ("%USB%models\installed-model.txt") do (
        echo   Model : %%b
        set "LUNA_MODEL=%%a"
    )
)
echo.

:: ── Register model with Ollama (if not already) ──────────────────
set "MF_DIR=%USB%models\modelfiles"
if defined LUNA_MODEL (
    if exist "%MF_DIR%\%LUNA_MODEL%.Modelfile" (
        echo   [i] Registering Luna model with Ollama...
        "%USB%ollama\ollama.exe" create "%LUNA_MODEL%" -f "%MF_DIR%\%LUNA_MODEL%.Modelfile" >nul 2>&1
    )
)

:: ── Start Ollama engine in background ────────────────────────────
echo   [i] Starting AI engine...
start "" /B "%USB%ollama\ollama.exe" serve
timeout /t 4 >nul

:: ── Start Open WebUI in background ──────────────────────────────
echo   [i] Starting Luna chat interface...
start "" /B "%VENV_PYTHON%" -m open_webui serve --host 127.0.0.1 --port 8080
timeout /t 6 >nul

:: ── Open browser ─────────────────────────────────────────────────
echo   [i] Opening Luna in your browser...
start "" http://127.0.0.1:8080

:: ── Running ──────────────────────────────────────────────────────
title Luna — Running (keep this window open)
echo.
echo  ┌─────────────────────────────────────────────┐
echo  │   ✦  Luna is running!                       │
echo  │                                             │
echo  │   Open: http://127.0.0.1:8080               │
echo  │                                             │
echo  │   Keep this window open while chatting.     │
echo  │   Press any key here to shut down Luna.     │
echo  └─────────────────────────────────────────────┘
echo.
pause >nul

:: ── Clean shutdown ───────────────────────────────────────────────
echo   Shutting down Luna...
taskkill /F /IM "ollama.exe"   >nul 2>&1
taskkill /F /FI "WINDOWTITLE eq Luna*" >nul 2>&1

:: Kill Open WebUI (Python process on port 8080)
for /f "tokens=5" %%p in ('netstat -aon ^| findstr ":8080"') do (
    taskkill /F /PID %%p >nul 2>&1
)

echo   Luna stopped. Safe to eject USB.
timeout /t 3 >nul
