#!/bin/bash
# Luna — Linux Launcher

USB_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
OLLAMA_BIN="$USB_DIR/ollama-linux/ollama"
WEBUI_DIR="$USB_DIR/open-webui"
VENV_PYTHON="$WEBUI_DIR/venv/bin/python3"
LUNA_DATA="$USB_DIR/luna_data"
MODEL_FILE="$USB_DIR/models/installed-model.txt"

export OLLAMA_MODELS="$USB_DIR/ollama/data"
export DATA_DIR="$LUNA_DATA"
export WEBUI_SECRET_KEY="luna-usb-local-key"

clear
echo ""
echo "  ✦  Luna — Starting on Linux"
echo "  ─────────────────────────────────"
echo ""

mkdir -p "$LUNA_DATA"

# ── Install Ollama for Linux if needed ────────────────────────────
if [ ! -f "$OLLAMA_BIN" ]; then
    echo "  [i] Downloading Ollama for Linux..."
    mkdir -p "$USB_DIR/ollama-linux"
    curl -L "https://github.com/ollama/ollama/releases/latest/download/ollama-linux-amd64.tgz" \
         -o /tmp/ollama-linux.tgz --progress-bar
    tar -xzf /tmp/ollama-linux.tgz -C "$USB_DIR/ollama-linux"
    rm -f /tmp/ollama-linux.tgz
    chmod +x "$OLLAMA_BIN"
    echo "  [✓] Ollama ready"
fi

# ── Install Open WebUI if needed ─────────────────────────────────
if [ ! -f "$VENV_PYTHON" ]; then
    if ! command -v python3 &>/dev/null; then
        echo "  [✗] Python 3 not found. Install it with:"
        echo "      sudo apt install python3 python3-venv python3-pip"
        exit 1
    fi
    echo "  [i] Setting up Open WebUI (first time, a few minutes)..."
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
echo "  [i] Opening browser..."
xdg-open http://127.0.0.1:8080 2>/dev/null || \
    echo "  [i] Visit: http://127.0.0.1:8080"

echo ""
echo "  ┌─────────────────────────────────────────────┐"
echo "  │   ✦  Luna is running!                       │"
echo "  │                                             │"
echo "  │   Open: http://127.0.0.1:8080               │"
echo "  │                                             │"
echo "  │   Keep this terminal open.                  │"
echo "  │   Press ENTER to shut down Luna.            │"
echo "  └─────────────────────────────────────────────┘"
echo ""
read -p ""

echo "  Shutting down..."
kill "$OLLAMA_PID" 2>/dev/null
kill "$WEBUI_PID"  2>/dev/null
pkill -f "open_webui" 2>/dev/null
echo "  Luna stopped. Safe to eject USB."
