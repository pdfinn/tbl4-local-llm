#!/usr/bin/env bash
set -euo pipefail

# ─── TBL4 Local LLM Setup (macOS) ───────────────────────────────────────────
# This script installs everything you need to run a local LLM with a web UI.
# It is safe to run multiple times.

# Run from the script's own directory so double-clicking in Finder works
# (Finder launches .command files with $HOME as the cwd).
cd "$(dirname "${BASH_SOURCE[0]}")"

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

info()  { echo -e "${GREEN}[OK]${NC}  $1"; }
warn()  { echo -e "${YELLOW}[!!]${NC}  $1"; }
fail()  { echo -e "${RED}[ERR]${NC} $1"; exit 1; }

echo ""
echo "========================================="
echo "  Tarkas Brainlab IV — Local LLM Setup"
echo "========================================="
echo ""

# ─── Load config ─────────────────────────────────────────────────────────────
if [ ! -f .env ]; then
    cp .env.example .env
    info "Created .env from .env.example"
fi

# Generate a WEBUI_SECRET_KEY on first run. OpenWebUI uses this to encrypt
# OAuth credentials for MCP tools so they survive a container restart.
if ! grep -Eq '^WEBUI_SECRET_KEY=.+' .env; then
    SECRET=$(openssl rand -hex 32)
    if grep -q '^WEBUI_SECRET_KEY=' .env; then
        sed -i '' "s|^WEBUI_SECRET_KEY=.*|WEBUI_SECRET_KEY=${SECRET}|" .env
    else
        printf '\nWEBUI_SECRET_KEY=%s\n' "${SECRET}" >> .env
    fi
    info "Generated WEBUI_SECRET_KEY"
fi

source .env

MODEL="${MODEL:-llama3.2}"
WEBUI_PORT="${WEBUI_PORT:-3000}"

# ─── Check: Docker ───────────────────────────────────────────────────────────
if ! command -v docker &>/dev/null; then
    fail "Docker is not installed. Please install Docker Desktop first:
    https://www.docker.com/products/docker-desktop/"
fi

if ! docker info &>/dev/null; then
    fail "Docker is not running. Please start Docker Desktop and try again."
fi
info "Docker is running"

# ─── Install Ollama ──────────────────────────────────────────────────────────
if ! command -v ollama &>/dev/null; then
    echo ""
    warn "Ollama is not installed. Installing now..."
    curl -fsSL https://ollama.com/install.sh | sh
    echo ""
fi
info "Ollama is installed"

# ─── Start Ollama ────────────────────────────────────────────────────────────
if ! curl -sf http://localhost:11434/api/tags &>/dev/null; then
    echo ""
    warn "Starting Ollama..."
    ollama serve &>/dev/null &
    OLLAMA_PID=$!

    # Wait for it to be ready
    for i in {1..30}; do
        if curl -sf http://localhost:11434/api/tags &>/dev/null; then
            break
        fi
        sleep 1
    done

    if ! curl -sf http://localhost:11434/api/tags &>/dev/null; then
        fail "Ollama failed to start. Try running 'ollama serve' manually."
    fi
fi
info "Ollama is running"

# ─── Pull the model ──────────────────────────────────────────────────────────
echo ""
echo "Downloading model: ${MODEL}"
echo "(This may take a few minutes the first time)"
echo ""
ollama pull "${MODEL}"
info "Model '${MODEL}' is ready"

# ─── Start Open WebUI ────────────────────────────────────────────────────────
echo ""
echo "Fetching the pinned container images (first run only; fast on re-runs)..."
docker compose pull --quiet
echo "Starting Open WebUI..."
docker compose up -d
info "Open WebUI is running"

# ─── Done ────────────────────────────────────────────────────────────────────
echo ""
echo "========================================="
echo "  Setup complete!"
echo ""
echo "  Open your browser to:"
echo "  http://localhost:${WEBUI_PORT}"
echo ""
echo "  To enable the n8n tool server in OpenWebUI"
echo "  (one-time, after tbl4-n8n is running):"
echo "  Admin Settings -> Tools -> Tool Servers -> Add:"
echo "    http://host.docker.internal:5678/webhook"
echo ""
echo "  Next time, just double-click setup_macos.command"
echo "  again. It is safe to re-run any time and"
echo "  will bring everything back up for you."
echo ""
echo "  Advanced (from the command line):"
echo "    Stop:  docker compose down"
echo "    Start: docker compose up -d"
echo "           (make sure Ollama is running: 'ollama serve')"
echo "========================================="
echo ""
