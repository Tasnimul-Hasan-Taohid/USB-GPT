@echo off
title Luna — USB AI Setup
color 0B
chcp 65001 >nul 2>&1

echo.
echo  ██╗     ██╗   ██╗███╗   ██╗ █████╗
echo  ██║     ██║   ██║████╗  ██║██╔══██╗
echo  ██║     ██║   ██║██╔██╗ ██║███████║
echo  ██║     ██║   ██║██║╚██╗██║██╔══██║
echo  ███████╗╚██████╔╝██║ ╚████║██║  ██║
echo  ╚══════╝ ╚═════╝ ╚═╝  ╚═══╝╚═╝  ╚═╝
echo.
echo  Your personal AI. On a USB. Offline. Private.
echo  ─────────────────────────────────────────────
echo.
echo  What Luna gives you:
echo    - Runs 100%% from this USB drive
echo    - No internet needed after first setup
echo    - Nothing saved to the host computer
echo    - Beautiful chat UI (Open WebUI)
echo    - 6 AI models to choose from
echo    - Bring your own model (GGUF)
echo.
echo  Minimum: 16 GB USB  ^|  Recommended: 32 GB USB
echo.
echo  Press any key to begin setup...
pause >nul

powershell -ExecutionPolicy Bypass -File "%~dp0luna-setup.ps1"

echo.
echo  ─────────────────────────────────────────────
echo   Luna is ready. Run start-windows.bat to chat.
echo  ─────────────────────────────────────────────
echo.
pause
