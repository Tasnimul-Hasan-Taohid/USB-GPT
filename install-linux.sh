#!/bin/bash
# Luna — Linux/Mac Setup Script

USB_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

clear
echo ""
echo "  ██╗     ██╗   ██╗███╗   ██╗ █████╗ "
echo "  ██║     ██║   ██║████╗  ██║██╔══██╗"
echo "  ██║     ██║   ██║██╔██╗ ██║███████║"
echo "  ██║     ██║   ██║██║╚██╗██║██╔══██║"
echo "  ███████╗╚██████╔╝██║ ╚████║██║  ██║"
echo "  ╚══════╝ ╚═════╝ ╚═╝  ╚═══╝╚═╝  ╚═╝"
echo ""
echo "  Your personal AI. On a USB. Offline. Private."
echo "  ─────────────────────────────────────────────"
echo ""

# Detect OS
OS="linux"
if [[ "$OSTYPE" == "darwin"* ]]; then OS="mac"; fi
echo "  Platform: $OS"
echo ""

# Folders
mkdir -p "$USB_DIR"/{ollama/data,models/modelfiles,open-webui,luna_data}

# Models
declare -A MODEL_NAMES=(
    ["1"]="Gemma 3 4B (Recommended)"
    ["2"]="Mistral 7B Instruct"
    ["3"]="Llama 3.2 3B (Lightweight)"
    ["4"]="Qwen 2.5 7B (Multilingual)"
    ["5"]="Phi-3.5 Mini (Fast)"
    ["6"]="DeepSeek R1 7B (Reasoning)"
)
declare -A MODEL_FILES=(
    ["1"]="gemma3-4b-Q4_K_M.gguf"
    ["2"]="Mistral-7B-Instruct-v0.3-Q4_K_M.gguf"
    ["3"]="Llama-3.2-3B-Instruct-Q4_K_M.gguf"
    ["4"]="Qwen2.5-7B-Instruct-Q4_K_M.gguf"
    ["5"]="Phi-3.5-mini-instruct-Q4_K_M.gguf"
    ["6"]="DeepSeek-R1-Distill-Qwen-7B-Q4_K_M.gguf"
)
declare -A MODEL_URLS=(
    ["1"]="https://huggingface.co/bartowski/gemma-3-4b-it-GGUF/resolve/main/gemma3-4b-it-Q4_K_M.gguf"
    ["2"]="https://huggingface.co/bartowski/Mistral-7B-Instruct-v0.3-GGUF/resolve/main/Mistral-7B-Instruct-v0.3-Q4_K_M.gguf"
    ["3"]="https://huggingface.co/bartowski/Llama-3.2-3B-Instruct-GGUF/resolve/main/Llama-3.2-3B-Instruct-Q4_K_M.gguf"
    ["4"]="https://huggingface.co/bartowski/Qwen2.5-7B-Instruct-GGUF/resolve/main/Qwen2.5-7B-Instruct-Q4_K_M.gguf"
    ["5"]="https://huggingface.co/bartowski/Phi-3.5-mini-instruct-GGUF/resolve/main/Phi-3.5-mini-instruct-Q4_K_M.gguf"
    ["6"]="https://huggingface.co/bartowski/DeepSeek-R1-Distill-Qwen-7B-GGUF/resolve/main/DeepSeek-R1-Distill-Qwen-7B-Q4_K_M.gguf"
)
declare -A MODEL_LOCALS=(
    ["1"]="gemma3-luna" ["2"]="mistral-luna" ["3"]="llama3-luna"
    ["4"]="qwen-luna"   ["5"]="phi35-luna"   ["6"]="deepseek-luna"
)
declare -A MODEL_PROMPTS=(
    ["1"]="Your name is Luna. You are a warm, curious, and helpful AI assistant living on a USB drive. You are private, offline, and completely loyal to the person talking to you."
    ["2"]="Your name is Luna. You are a precise, capable, and friendly AI assistant. You help with coding, writing, reasoning, and anything else the user needs."
    ["3"]="Your name is Luna. You are a helpful, friendly AI assistant that runs from a USB drive. Be concise and clear."
    ["4"]="Your name is Luna. You are a multilingual, helpful AI assistant. You speak any language the user writes in."
    ["5"]="Your name is Luna. You are a sharp, fast AI assistant with strong reasoning skills."
    ["6"]="Your name is Luna. You are an analytical AI assistant. Think step by step and be thorough."
)

echo "  Choose your AI model:"
echo ""
for i in 1 2 3 4 5 6; do
    echo "    $i. ${MODEL_NAMES[$i]}"
done
echo "    C. Custom GGUF URL"
echo ""
read -p "  Choice: " CHOICE

if [[ "$CHOICE" == "C" || "$CHOICE" == "c" ]]; then
    read -p "  Paste .gguf URL: " CUSTOM_URL
    read -p "  Filename: " CUSTOM_FILE
    MODEL_LOCAL="custom-luna"
    MODEL_NAME="Custom Model"
    MODEL_PROMPT="Your name is Luna. You are a helpful private AI assistant."
    DEST="$USB_DIR/models/$CUSTOM_FILE"
    if [ ! -f "$DEST" ]; then
        echo "  Downloading..."
        curl -L "$CUSTOM_URL" -o "$DEST" --progress-bar
    fi
    MODEL_FILE_NAME="$CUSTOM_FILE"
else
    MODEL_FILE_NAME="${MODEL_FILES[$CHOICE]}"
    MODEL_LOCAL="${MODEL_LOCALS[$CHOICE]}"
    MODEL_NAME="${MODEL_NAMES[$CHOICE]}"
    MODEL_PROMPT="${MODEL_PROMPTS[$CHOICE]}"
    DEST="$USB_DIR/models/$MODEL_FILE_NAME"
    URL="${MODEL_URLS[$CHOICE]}"

    if [ -f "$DEST" ]; then
        echo "  [✓] Model already downloaded"
    else
        echo "  Downloading $MODEL_NAME..."
        curl -L "$URL" -o "$DEST" --progress-bar
    fi
fi

# Write Modelfile
MODELFILE="$USB_DIR/models/modelfiles/${MODEL_LOCAL}.Modelfile"
cat > "$MODELFILE" << EOF
FROM $USB_DIR/models/$MODEL_FILE_NAME
SYSTEM """$MODEL_PROMPT"""
PARAMETER temperature 0.7
PARAMETER top_p 0.9
EOF

# Save record
echo "${MODEL_LOCAL}|${MODEL_NAME}|STANDARD" > "$USB_DIR/models/installed-model.txt"

# Install Open WebUI
VENV="$USB_DIR/open-webui/venv"
if [ ! -d "$VENV" ]; then
    echo "  Setting up Open WebUI..."
    python3 -m venv "$VENV"
    "$VENV/bin/pip" install open-webui --quiet
    echo "installed" > "$USB_DIR/open-webui/installed.txt"
    echo "  [✓] Open WebUI installed"
else
    echo "  [✓] Open WebUI already installed"
fi

# Make launchers executable
chmod +x "$USB_DIR/start-linux.sh" "$USB_DIR/start-mac.command" 2>/dev/null

echo ""
echo "  ✦  Luna setup complete!"
echo "  Run ./start-linux.sh (Linux) or double-click start-mac.command (Mac)"
echo ""
