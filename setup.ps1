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
function Test-OllamaUp {
    # Use /api/version: it is a trivial endpoint that does not touch disk.
    # /api/tags can take several seconds on machines with many models, which
    # made the old 2-second timeout spuriously fail on healthy systems.
    try {
        $null = Invoke-RestMethod -Uri "http://localhost:11434/api/version" -TimeoutSec 5
        return $true
    } catch {
        return $false
    }
}

$ollamaRunning = Test-OllamaUp

if (-not $ollamaRunning) {
    # On Windows, Ollama normally runs as a tray app that auto-starts at login.
    # After a fresh install or reboot the tray app may still be coming up, so
    # only launch a new instance if nothing is already starting.
    $trayApp = Get-Process -Name "ollama app" -ErrorAction SilentlyContinue
    if (-not $trayApp) {
        Write-Host ""
        Warn "Starting Ollama..."
        $trayAppPath = Join-Path $env:LOCALAPPDATA "Programs\Ollama\ollama app.exe"
        if (Test-Path -LiteralPath $trayAppPath) {
            Start-Process -FilePath $trayAppPath
        } else {
            Start-Process "ollama" -ArgumentList "serve" -WindowStyle Hidden
        }
    } else {
        Write-Host ""
        Warn "Ollama is starting up, waiting..."
    }

    for ($i = 0; $i -lt 60; $i++) {
        Start-Sleep -Seconds 1
        if (Test-OllamaUp) {
            $ollamaRunning = $true
            break
        }
    }

    if (-not $ollamaRunning) {
        Fail "Ollama did not respond within 60 seconds. Open the Ollama app from the Start menu and re-run this setup."
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
