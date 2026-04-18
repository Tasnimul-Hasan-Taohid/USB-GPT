#!/bin/bash
# Luna — macOS Launcher
# Double-click this file to start Luna on Mac

USB_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
OLLAMA_DIR="$USB_DIR/ollama-mac"
WEBUI_DIR="$USB_DIR/open-webui"
VENV_PYTHON="$WEBUI_DIR/venv/bin/python3"
LUNA_DATA="$USB_DIR/luna_data"
MODEL_FILE="$USB_DIR/models/installed-model.txt"

export OLLAMA_MODELS="$USB_DIR/ollama/data"
export DATA_DIR="$LUNA_DATA"
export WEBUI_SECRET_KEY="luna-usb-local-key"

clear
echo ""
echo "  ✦  Luna — Starting on macOS"
echo "  ─────────────────────────────────"
echo ""

mkdir -p "$LUNA_DATA"

# ── Install Ollama for Mac if needed ─────────────────────────────
OLLAMA_BIN="$OLLAMA_DIR/ollama"
if [ ! -f "$OLLAMA_BIN" ]; then
    echo "  [i] Downloading Ollama for Mac (~60 MB)..."
    mkdir -p "$OLLAMA_DIR"
    TMPFILE=$(mktemp /tmp/ollama-mac.XXXXXX.tgz)
    curl -L "https://github.com/ollama/ollama/releases/latest/download/ollama-darwin.tgz" \
         -o "$TMPFILE" --progress-bar
    tar -xzf "$TMPFILE" -C "$OLLAMA_DIR"
    rm -f "$TMPFILE"
    chmod +x "$OLLAMA_BIN"
    echo "  [✓] Ollama downloaded"
fi

# ── Install Open WebUI if needed ─────────────────────────────────
if [ ! -f "$VENV_PYTHON" ]; then
    echo "  [i] Setting up Open WebUI (first time, takes a few minutes)..."
    python3 -m venv "$WEBUI_DIR/venv"
    "$WEBUI_DIR/venv/bin/pip" install open-webui --quiet
    echo "installed" > "$WEBUI_DIR/installed.txt"
    echo "  [✓] Open WebUI ready"
fi

# ── Show model ────────────────────────────────────────────────────
if [ -f "$MODEL_FILE" ]; then
    LUNA_MODEL=$(cut -d'|' -f1 "$MODEL_FILE")
    MODEL_NAME=$(cut -d'|' -f2 "$MODEL_FILE")
    echo "  Model : $MODEL_NAME"
    echo ""

    # Register with Ollama
    MF="$USB_DIR/models/modelfiles/${LUNA_MODEL}.Modelfile"
    if [ -f "$MF" ]; then
        "$OLLAMA_BIN" create "$LUNA_MODEL" -f "$MF" >/dev/null 2>&1
    fi
fi

# ── Start Ollama ──────────────────────────────────────────────────
echo "  [i] Starting AI engine..."
"$OLLAMA_BIN" serve &
OLLAMA_PID=$!
sleep 4

# ── Start Open WebUI ──────────────────────────────────────────────
echo "  [i] Starting Luna chat interface..."
"$VENV_PYTHON" -m open_webui serve --host 127.0.0.1 --port 8080 &
WEBUI_PID=$!
sleep 6

# ── Open browser ──────────────────────────────────────────────────
echo "  [i] Opening Luna in browser..."
open http://127.0.0.1:8080

echo ""
echo "  ┌─────────────────────────────────────────────┐"
echo "  │   ✦  Luna is running!                       │"
echo "  │                                             │"
echo "  │   Open: http://127.0.0.1:8080               │"
echo "  │                                             │"
echo "  │   Keep this window open while chatting.     │"
echo "  │   Press ENTER to shut down Luna.            │"
echo "  └─────────────────────────────────────────────┘"
echo ""

read -p ""

# ── Clean shutdown ────────────────────────────────────────────────
echo "  Shutting down Luna..."
kill "$OLLAMA_PID" 2>/dev/null
kill "$WEBUI_PID"  2>/dev/null
pkill -f "open_webui" 2>/dev/null
echo "  Luna stopped. Safe to eject USB."
sleep 2
