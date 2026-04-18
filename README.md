# ✦ Luna — Your Personal AI on a USB Drive

Luna is a portable, offline AI assistant that runs entirely from a USB flash drive. Plug it into any Windows, Mac, or Linux computer, run one file, and your private AI is live in a browser tab. No accounts. No cloud. No data leaving the drive. When you unplug the USB, it's like Luna was never there.

The name is Luna. She'll remember that.

---

## What makes this different

Most "run AI locally" guides have you installing Ollama, setting up Python, configuring ports, and hoping things don't break when you switch computers. Luna wraps all of that into a single setup script. Everything — the AI engine, the chat interface, your conversation history, your model files — lives on the USB drive.

Move it to a different computer. It still works. Unplug mid-session. Your chats are still there. Lend it to someone. They can chat with Luna without installing a single thing (except Python, more on that below).

---

## What you need

| Item | Requirement |
|---|---|
| USB flash drive | 16 GB minimum, 32 GB recommended, exFAT format |
| Internet connection | Only for the first setup. Never needed again after |
| Python 3.11+ | On the host computer (install once, free, from python.org) |
| RAM | 4 GB for lightweight models, 8 GB for the 7B models |

> **Why Python?** Open WebUI (the chat interface Luna uses) is a Python application. It runs inside a virtual environment that lives entirely on the USB, but Python itself needs to be on the computer you're using. It's a one-time install and it's free.

---

## Setup

### Windows

1. Copy all files from this repo onto your USB drive
2. Double-click **`install.bat`**
3. Choose your model from the menu
4. Wait for the download to finish (anywhere from 5–30 minutes depending on your connection and model size)
5. Done

### Mac / Linux

```bash
chmod +x install-linux.sh start-linux.sh start-mac.command
./install-linux.sh
```

Choose your model from the menu, let it download, done.

---

## Starting Luna

### Windows
Double-click **`start-windows.bat`**

### Mac
Double-click **`start-mac.command`**
(First time: right-click → Open, since macOS will ask about running scripts from the internet)

### Linux
```bash
./start-linux.sh
```

Luna will open automatically at **http://127.0.0.1:8080** in your browser. Keep the terminal/launcher window open while you're chatting — closing it shuts Luna down.

---

## Models

During setup you pick one. You can re-run setup to add more. All models are Q4_K_M quantized GGUF files from Bartowski on HuggingFace — a well-known, reliable source for quality quantizations.

| # | Model | Size on disk | Good for |
|---|---|---|---|
| 1 | **Gemma 3 4B** (Google) | ~2.8 GB | ⭐ Recommended — fast, smart, great all-rounder |
| 2 | **Mistral 7B Instruct** | ~4.1 GB | Coding, writing, precise tasks |
| 3 | **Llama 3.2 3B** | ~2.0 GB | Lighter PCs, quick responses |
| 4 | **Qwen 2.5 7B** | ~4.7 GB | Multiple languages |
| 5 | **Phi-3.5 Mini** | ~2.2 GB | Fast reasoning on low-end hardware |
| 6 | **DeepSeek R1 7B** | ~4.7 GB | Step-by-step thinking, analysis |
| C | **Your own model** | Varies | Paste any HuggingFace GGUF link |

Every model gets a custom system prompt that tells it its name is Luna and that it's running privately from a USB drive. It makes the experience feel a lot more cohesive.

---

## USB size guide

| What you're doing | USB size |
|---|---|
| One lightweight model (3B) | 16 GB |
| One standard model (7B) | 16 GB |
| Two models | 32 GB |
| Multiple models + room to breathe | 64 GB |

---

## What's on your USB after setup

```
Your USB Drive/
├── install.bat              ← Windows setup (run first)
├── install-linux.sh         ← Mac/Linux setup (run first)
├── start-windows.bat        ← Windows launcher
├── start-mac.command        ← Mac launcher
├── start-linux.sh           ← Linux launcher
│
├── ollama/                  ← AI engine (Windows)
│   └── data/                ← Model registry
│
├── ollama-mac/              ← AI engine (Mac, downloaded on first run)
├── ollama-linux/            ← AI engine (Linux, downloaded on first run)
│
├── models/
│   ├── installed-model.txt  ← Which model you chose
│   ├── modelfiles/          ← Luna personality configs
│   └── *.gguf               ← Your actual AI model weights
│
├── open-webui/
│   └── venv/                ← Isolated Python environment (stays on USB)
│
└── luna_data/               ← Your chats, settings, everything
```

Nothing goes to the host computer. The only thing that stays on the PC temporarily is the Python runtime itself — which is just the language, not your data.

---

## Privacy

This is the whole point, so let's be specific:

- All conversation history is stored in `luna_data/` on the USB
- The AI model runs 100% on your CPU — no network requests at any point during use
- Open WebUI runs on localhost (127.0.0.1) — not accessible from outside your machine
- Ollama stores its model data in `ollama/data/` on the USB
- No telemetry, no phoning home, no API keys, no accounts

When you eject the USB, nothing that matters to you remains on the host computer.

---

## Switching computers

Just plug the USB into a different computer and run the launcher. Luna will:

1. Start the AI engine pointing to the USB model files
2. Start the chat interface pointing to your USB conversation history
3. Open your browser at the same address

Your chats are there. Your settings are there. It's the same Luna.

The only thing that can cause issues is if Python isn't installed on the new machine. Install it once and you're set.

---

## Switching models

Re-run `install.bat` (Windows) or `install-linux.sh` (Mac/Linux) and choose a different model. The old model file stays on the USB — you can delete it manually if you want the space back. Edit `models/installed-model.txt` to point to a different model, then restart the launcher.

---

## Troubleshooting

**Luna won't start / "ollama.exe not found"**
Run `install.bat` first. The setup has to run before the launcher.

**"Python not found" during setup**
Install Python from [python.org](https://python.org). During install, tick "Add Python to PATH". Then re-run setup.

**The browser opens but the chat UI shows an error**
Wait another 10 seconds and refresh. Open WebUI sometimes takes a moment to fully start up.

**Slow responses**
The AI runs on your CPU, not a GPU. Response times depend on your hardware and model size. A 3B model on a modern laptop gives responses in 5–15 seconds. A 7B model on an older laptop might take 30–60 seconds per response. This is normal — it's running a full AI locally.

**Chats disappeared**
They're in `luna_data/` on the USB. As long as you didn't delete that folder, they're there. If you're not seeing them, make sure you opened Luna from the same USB drive (not a copy).

**Model download failed**
The installer will tell you. You can download the GGUF file manually from HuggingFace and drop it in the `models/` folder. Re-run setup and it'll detect the file and skip the download.

---

## Technical notes

Luna uses:
- **[Ollama](https://ollama.com)** — the AI inference engine. Runs GGUF models locally.
- **[Open WebUI](https://github.com/open-webui/open-webui)** — the chat interface. A polished, full-featured UI that runs as a local web server.
- **[Bartowski's GGUF releases](https://huggingface.co/bartowski)** — Q4_K_M quantized models. Good quality-to-size ratio.

The setup scripts wire everything together so Ollama and Open WebUI both point to the USB for storage, keeping the host computer clean.

---

## License

MIT — do whatever you want with it.

---

*Luna runs from a USB. She goes where you go. She doesn't talk to anyone else.*
