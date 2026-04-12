# ─── Tarkas Brainlab IV — Local LLM Teardown (Windows) ──────────────────────
# Safely removes the local LLM stack. Asks before each step.
# Nothing is deleted without your confirmation.
#
# Run in PowerShell:  .\teardown.ps1

$ErrorActionPreference = "Stop"

function Info($msg)  { Write-Host "[OK]  $msg" -ForegroundColor Green }
function Warn($msg)  { Write-Host "[!!]  $msg" -ForegroundColor Yellow }
function Skip($msg)  { Write-Host "[--]  Skipped: $msg" -ForegroundColor Yellow }

function Confirm-Step($message) {
    Write-Host ""
    Write-Host $message -ForegroundColor Yellow
    $answer = Read-Host "Proceed? (y/N)"
    return ($answer -eq "y" -or $answer -eq "Y" -or $answer -eq "yes")
}

Write-Host ""
Write-Host "========================================="
Write-Host "  Tarkas Brainlab IV — Teardown"
Write-Host "========================================="
Write-Host ""
Write-Host "This script will walk you through removing"
Write-Host "the local LLM stack. You will be asked"
Write-Host "before anything is deleted."
Write-Host ""

# ─── Step 1: Stop and remove Open WebUI container ───────────────────────────
$container = docker ps -a --filter name=open-webui --format '{{.Names}}' 2>$null
if ($container -eq "open-webui") {
    if (Confirm-Step "Stop and remove the Open WebUI container?") {
        docker compose down
        Info "Open WebUI container removed"
    } else {
        Skip "Open WebUI container"
    }
} else {
    Info "Open WebUI container is not running (nothing to do)"
}

# ─── Step 2: Remove Open WebUI Docker volume (chat history) ─────────────────
$volume = docker volume ls --filter name=open-webui_data -q 2>$null
if ($volume) {
    if (Confirm-Step "Remove Open WebUI data volume? (This deletes your chat history.)") {
        docker volume rm $volume
        Info "Open WebUI data volume removed"
    } else {
        Skip "Open WebUI data volume (chat history preserved)"
    }
} else {
    Info "No Open WebUI data volume found (nothing to do)"
}

# ─── Step 3: Remove Open WebUI Docker image ─────────────────────────────────
$image = docker images ghcr.io/open-webui/open-webui -q 2>$null
if ($image) {
    if (Confirm-Step "Remove the Open WebUI Docker image? (Frees ~2GB of disk space.)") {
        docker rmi ghcr.io/open-webui/open-webui:main
        Info "Open WebUI Docker image removed"
    } else {
        Skip "Open WebUI Docker image"
    }
} else {
    Info "No Open WebUI Docker image found (nothing to do)"
}

# ─── Step 4: Remove downloaded models from Ollama ───────────────────────────
$ollamaInstalled = $false
try {
    $null = Get-Command ollama -ErrorAction Stop
    $ollamaInstalled = $true
} catch {}

if ($ollamaInstalled) {
    $models = @()
    try {
        $rawOutput = ollama list 2>$null
        $models = ($rawOutput | Select-Object -Skip 1 | ForEach-Object { ($_ -split '\s+')[0] }) | Where-Object { $_ }
    } catch {}

    if ($models.Count -gt 0) {
        Write-Host ""
        Write-Host "Ollama has the following models installed:"
        foreach ($m in $models) { Write-Host "  - $m" }
        if (Confirm-Step "Remove ALL downloaded models? (Frees several GB of disk space.)") {
            foreach ($m in $models) {
                & ollama rm $m
                Info "Removed model: $m"
            }
        } else {
            Skip "Ollama models"
        }
    } else {
        Info "No Ollama models found (nothing to do)"
    }

    # ─── Step 5: Uninstall Ollama itself ────────────────────────────────────
    if (Confirm-Step "Uninstall Ollama from your system?") {
        try {
            Stop-Process -Name "ollama*" -Force -ErrorAction SilentlyContinue
        } catch {}
        try {
            winget uninstall --id Ollama.Ollama --accept-source-agreements
            Info "Ollama uninstalled"
        } catch {
            Warn "Could not auto-uninstall Ollama. Remove it from Settings > Apps > Installed apps."
        }
    } else {
        Skip "Ollama uninstall"
    }
} else {
    Info "Ollama is not installed (nothing to do)"
}

# ─── Done ────────────────────────────────────────────────────────────────────
Write-Host ""
Write-Host "========================================="
Write-Host "  Teardown complete."
Write-Host ""
Write-Host "  If you also want to remove Docker Desktop"
Write-Host "  itself, do that from Settings > Apps."
Write-Host "========================================="
Write-Host ""
