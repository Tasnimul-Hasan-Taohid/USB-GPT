# ================================================================
#  LUNA — USB AI Setup Script (Windows)
#  Installs Ollama engine + Open WebUI onto a USB drive
#  Everything stays on the USB. Nothing touches the host.
# ================================================================

$ErrorActionPreference = "Continue"
$USB = Split-Path -Parent $MyInvocation.MyCommand.Path

# ── Colour helpers ───────────────────────────────────────────────
function Write-Header($t) {
    Write-Host ""
    Write-Host "  ── $t ──" -ForegroundColor Cyan
    Write-Host ""
}
function Write-OK($t)   { Write-Host "  [✓] $t" -ForegroundColor Green }
function Write-Info($t) { Write-Host "  [i] $t" -ForegroundColor White }
function Write-Warn($t) { Write-Host "  [!] $t" -ForegroundColor Yellow }
function Write-Err($t)  { Write-Host "  [✗] $t" -ForegroundColor Red }
function Write-Luna($t) { Write-Host "  ✦  $t" -ForegroundColor Magenta }

# ── Folder structure ─────────────────────────────────────────────
$Folders = @("ollama","ollama\data","models","open-webui","luna_data")
foreach ($f in $Folders) {
    $p = Join-Path $USB $f
    if (!(Test-Path $p)) { New-Item -ItemType Directory -Path $p -Force | Out-Null }
}

# ── Model catalogue ──────────────────────────────────────────────
$Models = @(
    @{
        Num   = "1"; Name = "Gemma 3 4B (Google)"; File = "gemma3-4b-Q4_K_M.gguf"
        URL   = "https://huggingface.co/bartowski/gemma-3-4b-it-GGUF/resolve/main/gemma-3-4b-it-Q4_K_M.gguf"
        Size  = "2.8"; MinGB = 2; Local = "gemma3-luna"
        Label = "STANDARD"; Badge = "⭐ RECOMMENDED"
        Prompt = "Your name is Luna. You are a warm, curious, and helpful AI assistant living on a USB drive. You are private, offline, and completely loyal to the person talking to you. Be conversational, honest, and genuinely useful."
    },
    @{
        Num   = "2"; Name = "Mistral 7B Instruct v0.3"; File = "Mistral-7B-Instruct-v0.3-Q4_K_M.gguf"
        URL   = "https://huggingface.co/bartowski/Mistral-7B-Instruct-v0.3-GGUF/resolve/main/Mistral-7B-Instruct-v0.3-Q4_K_M.gguf"
        Size  = "4.1"; MinGB = 4; Local = "mistral-luna"
        Label = "STANDARD"; Badge = "CODING"
        Prompt = "Your name is Luna. You are a precise, capable, and friendly AI assistant. You help with coding, writing, reasoning, and anything else the user needs. You run privately from a USB drive."
    },
    @{
        Num   = "3"; Name = "Llama 3.2 3B Instruct"; File = "Llama-3.2-3B-Instruct-Q4_K_M.gguf"
        URL   = "https://huggingface.co/bartowski/Llama-3.2-3B-Instruct-GGUF/resolve/main/Llama-3.2-3B-Instruct-Q4_K_M.gguf"
        Size  = "2.0"; MinGB = 2; Local = "llama3-luna"
        Label = "STANDARD"; Badge = "LIGHTWEIGHT"
        Prompt = "Your name is Luna. You are a helpful, friendly AI assistant that runs from a USB drive. Be concise and clear."
    },
    @{
        Num   = "4"; Name = "Qwen 2.5 7B Instruct"; File = "Qwen2.5-7B-Instruct-Q4_K_M.gguf"
        URL   = "https://huggingface.co/bartowski/Qwen2.5-7B-Instruct-GGUF/resolve/main/Qwen2.5-7B-Instruct-Q4_K_M.gguf"
        Size  = "4.7"; MinGB = 4; Local = "qwen-luna"
        Label = "STANDARD"; Badge = "MULTILINGUAL"
        Prompt = "Your name is Luna. You are a multilingual, helpful AI assistant. You speak any language the user writes in. You run privately from a USB drive."
    },
    @{
        Num   = "5"; Name = "Phi-3.5 Mini 3.8B"; File = "Phi-3.5-mini-instruct-Q4_K_M.gguf"
        URL   = "https://huggingface.co/bartowski/Phi-3.5-mini-instruct-GGUF/resolve/main/Phi-3.5-mini-instruct-Q4_K_M.gguf"
        Size  = "2.2"; MinGB = 2; Local = "phi35-luna"
        Label = "STANDARD"; Badge = "FAST"
        Prompt = "Your name is Luna. You are a sharp, fast AI assistant with strong reasoning skills. You run privately from a USB drive."
    },
    @{
        Num   = "6"; Name = "DeepSeek R1 7B"; File = "DeepSeek-R1-Distill-Qwen-7B-Q4_K_M.gguf"
        URL   = "https://huggingface.co/bartowski/DeepSeek-R1-Distill-Qwen-7B-GGUF/resolve/main/DeepSeek-R1-Distill-Qwen-7B-Q4_K_M.gguf"
        Size  = "4.7"; MinGB = 4; Local = "deepseek-luna"
        Label = "STANDARD"; Badge = "REASONING"
        Prompt = "Your name is Luna. You are an analytical AI assistant with strong reasoning abilities. Think step by step and be thorough. You run privately from a USB drive."
    }
)

# ── USB free space ───────────────────────────────────────────────
function Get-FreeGB {
    try {
        $drive = (Get-Item $USB -ErrorAction Stop).PSDrive
        return [math]::Round((Get-PSDrive $drive.Name).Free / 1GB, 1)
    } catch { return 99 }
}

# ── Download with progress ───────────────────────────────────────
function Invoke-Download($url, $dest, $label) {
    Write-Info "Downloading $label..."
    $attempt = 0
    while ($attempt -lt 3) {
        $attempt++
        try {
            $wc = New-Object System.Net.WebClient
            $wc.Headers.Add("User-Agent", "Luna-USB-Installer/2.0")
            $wc.DownloadFile($url, $dest)
            if ((Get-Item $dest -ErrorAction SilentlyContinue).Length -gt 100000) {
                Write-OK "$label downloaded"
                return $true
            }
        } catch {
            Write-Warn "Attempt $attempt failed: $_"
            Start-Sleep 3
        }
    }
    Write-Err "Failed after 3 attempts: $label"
    return $false
}

# ================================================================
#  STEP 1 — Install Ollama engine onto USB
# ================================================================
Write-Header "Step 1 — AI Engine (Ollama)"

$ollamaExe  = Join-Path $USB "ollama\ollama.exe"
$ollamaInstaller = Join-Path $USB "ollama\OllamaSetup.exe"

if (Test-Path $ollamaExe) {
    Write-OK "Ollama already installed on USB"
} else {
    Write-Info "Downloading Ollama engine (~60 MB)..."
    $ok = Invoke-Download `
        "https://github.com/ollama/ollama/releases/latest/download/OllamaSetup.exe" `
        $ollamaInstaller "Ollama Installer"

    if ($ok) {
        Write-Info "Running installer... Choose the USB ollama folder when prompted."
        Write-Warn "IMPORTANT: Set install path to:  $USB\ollama"
        Start-Process -FilePath $ollamaInstaller -Wait
        Start-Sleep 2
    }

    # Fallback: try portable exe directly
    if (!(Test-Path $ollamaExe)) {
        Write-Info "Trying portable Ollama binary..."
        Invoke-Download `
            "https://github.com/ollama/ollama/releases/latest/download/ollama-windows-amd64.zip" `
            (Join-Path $USB "ollama\ollama.zip") "Ollama portable" | Out-Null
        $z = Join-Path $USB "ollama\ollama.zip"
        if (Test-Path $z) {
            Expand-Archive -Path $z -DestinationPath (Join-Path $USB "ollama") -Force
            Remove-Item $z -Force
        }
    }
}

if (Test-Path $ollamaExe) {
    Write-OK "Ollama engine ready"
} else {
    Write-Err "Could not find ollama.exe — please install Ollama manually into the ollama\ folder"
}

# ================================================================
#  STEP 2 — Install Open WebUI (portable Python version)
# ================================================================
Write-Header "Step 2 — Luna Chat Interface (Open WebUI)"

$webUIDir = Join-Path $USB "open-webui"
$webUIFlag = Join-Path $webUIDir "installed.txt"

if (Test-Path $webUIFlag) {
    Write-OK "Open WebUI already installed"
} else {
    Write-Info "Setting up Open WebUI (this takes a few minutes)..."

    # Check Python
    $pyPath = Get-Command python -ErrorAction SilentlyContinue
    if (!$pyPath) {
        Write-Err "Python not found on this computer."
        Write-Warn "Please install Python 3.11+ from python.org, then re-run setup."
        Write-Info "Alternatively, run setup on a PC that already has Python."
    } else {
        Write-OK "Python found: $($pyPath.Source)"

        # Create virtualenv inside USB
        $venv = Join-Path $webUIDir "venv"
        if (!(Test-Path $venv)) {
            Write-Info "Creating isolated Python environment on USB..."
            & python -m venv $venv
        }

        $pip = Join-Path $venv "Scripts\pip.exe"
        $py  = Join-Path $venv "Scripts\python.exe"

        Write-Info "Installing Open WebUI..."
        & $pip install open-webui --quiet --no-warn-script-location

        if ($LASTEXITCODE -eq 0) {
            Set-Content $webUIFlag "installed"
            Write-OK "Open WebUI installed"
        } else {
            Write-Err "Open WebUI install failed. Check your internet connection."
        }
    }
}

# ================================================================
#  STEP 3 — Choose and download AI model
# ================================================================
Write-Header "Step 3 — Choose Your AI Model"

$freeGB = Get-FreeGB
Write-Info "USB free space: ${freeGB} GB"
Write-Host ""

foreach ($m in $Models) {
    $badge = if ($m.Badge) { "[$($m.Badge)]" } else { "" }
    Write-Host ("  {0}. {1} — {2} GB  {3}" -f $m.Num, $m.Name, $m.Size, $badge) -ForegroundColor White
}
Write-Host "  C. Custom GGUF (paste your own HuggingFace link)" -ForegroundColor White
Write-Host ""

$choice = Read-Host "  Enter choice"
$modelFile = $null
$modelLocal = $null
$modelPrompt = $null
$modelName = $null

if ($choice -eq "C" -or $choice -eq "c") {
    $customURL  = Read-Host "  Paste direct .gguf download URL"
    $customFile = Read-Host "  Filename to save as (e.g. my-model.gguf)"
    $modelLocal = "custom-luna"
    $modelName  = "Custom Model"
    $modelPrompt = "Your name is Luna. You are a helpful, private AI assistant running from a USB drive."
    $destPath   = Join-Path $USB "models\$customFile"
    if (!(Test-Path $destPath)) {
        Invoke-Download $customURL $destPath $customFile | Out-Null
    }
    $modelFile = $customFile
} else {
    $selected = $Models | Where-Object { $_.Num -eq $choice }
    if (!$selected) {
        Write-Err "Invalid choice. Defaulting to option 1."
        $selected = $Models[0]
    }

    if ([float]$selected.Size -gt $freeGB) {
        Write-Warn "Model needs $($selected.Size) GB but USB only has $freeGB GB free."
        Write-Warn "You can still proceed if you free up some space first."
    }

    $modelFile   = $selected.File
    $modelLocal  = $selected.Local
    $modelPrompt = $selected.Prompt
    $modelName   = $selected.Name
    $destPath    = Join-Path $USB "models\$modelFile"

    if (Test-Path $destPath) {
        Write-OK "$modelName already on USB — skipping download"
    } else {
        Write-Info "Downloading $modelName ($($selected.Size) GB)..."
        Write-Warn "This may take a while on slower connections."
        Invoke-Download $selected.URL $destPath $modelName | Out-Null
    }
}

# ================================================================
#  STEP 4 — Write config files
# ================================================================
Write-Header "Step 4 — Writing Luna Config"

# Register model in Ollama Modelfile format
if ($modelFile -and $modelLocal) {
    $modelPath  = Join-Path $USB "models\$modelFile"
    $modelfileContent = @"
FROM $modelPath
SYSTEM """$modelPrompt"""
PARAMETER temperature 0.7
PARAMETER top_p 0.9
PARAMETER stop "<|end|>"
PARAMETER stop "</s>"
"@
    $modelfileDir = Join-Path $USB "models\modelfiles"
    if (!(Test-Path $modelfileDir)) { New-Item -ItemType Directory $modelfileDir -Force | Out-Null }
    Set-Content (Join-Path $modelfileDir "$modelLocal.Modelfile") $modelfileContent
    Write-OK "Luna model profile written"
}

# Save installed model record
$record = "$modelLocal|$modelName|STANDARD"
Set-Content (Join-Path $USB "models\installed-model.txt") $record
Write-OK "Model record saved"

Write-Header "Setup Complete"
Write-Luna "Luna is ready on your USB drive."
Write-Info "Run start-windows.bat to start chatting."
Write-Host ""
