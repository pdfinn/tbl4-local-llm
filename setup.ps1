# ─── TBL4 Local LLM Setup (Windows) ─────────────────────────────────────────
# This script installs everything you need to run a local LLM with a web UI.
# It is safe to run multiple times.
#
# Run in PowerShell:  .\setup.ps1

$ErrorActionPreference = "Stop"

function Info($msg)  { Write-Host "[OK]  $msg" -ForegroundColor Green }
function Warn($msg)  { Write-Host "[!!]  $msg" -ForegroundColor Yellow }
function Fail($msg)  { Write-Host "[ERR] $msg" -ForegroundColor Red; exit 1 }

Write-Host ""
Write-Host "========================================="
Write-Host "  Tarkas Brainlab IV — Local LLM Setup"
Write-Host "========================================="
Write-Host ""

# ─── Load config ─────────────────────────────────────────────────────────────
if (-not (Test-Path .env)) {
    Copy-Item .env.example .env
    Info "Created .env from .env.example"
}

$envVars = @{}
Get-Content .env | ForEach-Object {
    if ($_ -match '^\s*([^#][^=]+)=(.*)$') {
        $envVars[$matches[1].Trim()] = $matches[2].Trim()
    }
}

$Model = if ($envVars["MODEL"]) { $envVars["MODEL"] } else { "llama3.2" }
$WebuiPort = if ($envVars["WEBUI_PORT"]) { $envVars["WEBUI_PORT"] } else { "3000" }

# ─── Check: Docker ───────────────────────────────────────────────────────────
try {
    $null = Get-Command docker -ErrorAction Stop
} catch {
    Fail "Docker is not installed. Please install Docker Desktop first:`nhttps://www.docker.com/products/docker-desktop/"
}

try {
    $null = docker info 2>&1
} catch {
    Fail "Docker is not running. Please start Docker Desktop and try again."
}
Info "Docker is running"

# ─── Install Ollama ──────────────────────────────────────────────────────────
$ollamaInstalled = $false
try {
    $null = Get-Command ollama -ErrorAction Stop
    $ollamaInstalled = $true
} catch {}

if (-not $ollamaInstalled) {
    Write-Host ""
    Warn "Ollama is not installed. Installing now..."
    try {
        winget install --id Ollama.Ollama --accept-source-agreements --accept-package-agreements
    } catch {
        Fail "Could not install Ollama. Please install manually from:`nhttps://ollama.com/download/windows"
    }
    # Refresh PATH so we can find ollama
    $env:PATH = [System.Environment]::GetEnvironmentVariable("PATH", "Machine") + ";" + [System.Environment]::GetEnvironmentVariable("PATH", "User")
    Write-Host ""
}
Info "Ollama is installed"

# ─── Start Ollama ────────────────────────────────────────────────────────────
$ollamaRunning = $false
try {
    $null = Invoke-RestMethod -Uri "http://localhost:11434/api/tags" -TimeoutSec 2
    $ollamaRunning = $true
} catch {}

if (-not $ollamaRunning) {
    Write-Host ""
    Warn "Starting Ollama..."
    Start-Process "ollama" -ArgumentList "serve" -WindowStyle Hidden

    for ($i = 0; $i -lt 30; $i++) {
        Start-Sleep -Seconds 1
        try {
            $null = Invoke-RestMethod -Uri "http://localhost:11434/api/tags" -TimeoutSec 2
            $ollamaRunning = $true
            break
        } catch {}
    }

    if (-not $ollamaRunning) {
        Fail "Ollama failed to start. Try running 'ollama serve' manually."
    }
}
Info "Ollama is running"

# ─── Pull the model ──────────────────────────────────────────────────────────
Write-Host ""
Write-Host "Downloading model: $Model"
Write-Host "(This may take a few minutes the first time)"
Write-Host ""
& ollama pull $Model
Info "Model '$Model' is ready"

# ─── Start Open WebUI ────────────────────────────────────────────────────────
Write-Host ""
Write-Host "Starting Open WebUI..."
& docker compose up -d
Info "Open WebUI is running"

# ─── Done ────────────────────────────────────────────────────────────────────
Write-Host ""
Write-Host "========================================="
Write-Host "  Setup complete!"
Write-Host ""
Write-Host "  Open your browser to:"
Write-Host "  http://localhost:$WebuiPort"
Write-Host ""
Write-Host "  To stop everything later:"
Write-Host "    docker compose down"
Write-Host "    (Close the Ollama app from the system tray)"
Write-Host ""
Write-Host "  To start again next time:"
Write-Host "    ollama serve"
Write-Host "    docker compose up -d"
Write-Host "========================================="
Write-Host ""
