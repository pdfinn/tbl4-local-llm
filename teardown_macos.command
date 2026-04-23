#!/usr/bin/env bash
set -euo pipefail

# ─── Tarkas Brainlab IV — Local LLM Teardown (macOS) ────────────────────────
# Safely removes the local LLM stack. Asks before each step.
# Nothing is deleted without your confirmation.

# Run from the script's own directory so double-clicking in Finder works
# (Finder launches .command files with $HOME as the cwd).
cd "$(dirname "${BASH_SOURCE[0]}")"

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

info()  { echo -e "${GREEN}[OK]${NC}  $1"; }
warn()  { echo -e "${YELLOW}[!!]${NC}  $1"; }
skip()  { echo -e "${YELLOW}[--]${NC}  Skipped: $1"; }

confirm() {
    echo ""
    echo -e "${YELLOW}$1${NC}"
    read -r -p "Proceed? (y/N): " answer
    case "$answer" in
        [yY]|[yY][eE][sS]) return 0 ;;
        *) return 1 ;;
    esac
}

echo ""
echo "========================================="
echo "  Tarkas Brainlab IV — Teardown"
echo "========================================="
echo ""
echo "This script will walk you through removing"
echo "the local LLM stack. You will be asked"
echo "before anything is deleted."
echo ""

# ─── Step 1: Stop and remove Open WebUI container ───────────────────────────
if docker ps -a --filter name=open-webui --format '{{.Names}}' 2>/dev/null | grep -q open-webui; then
    if confirm "Stop and remove the Open WebUI container?"; then
        docker compose down
        info "Open WebUI container removed"
    else
        skip "Open WebUI container"
    fi
else
    info "Open WebUI container is not running (nothing to do)"
fi

# ─── Step 2: Remove Open WebUI Docker volume (chat history) ─────────────────
VOLUME_NAME=$(docker volume ls --filter name=open-webui_data -q 2>/dev/null || true)
if [ -n "$VOLUME_NAME" ]; then
    if confirm "Remove Open WebUI data volume? (This deletes your chat history.)"; then
        docker volume rm "$VOLUME_NAME"
        info "Open WebUI data volume removed"
    else
        skip "Open WebUI data volume (chat history preserved)"
    fi
else
    info "No Open WebUI data volume found (nothing to do)"
fi

# ─── Step 3: Remove Open WebUI Docker image ─────────────────────────────────
IMAGE_ID=$(docker images ghcr.io/open-webui/open-webui -q 2>/dev/null || true)
if [ -n "$IMAGE_ID" ]; then
    if confirm "Remove the Open WebUI Docker image? (Frees ~2GB of disk space.)"; then
        docker rmi ghcr.io/open-webui/open-webui:main
        info "Open WebUI Docker image removed"
    else
        skip "Open WebUI Docker image"
    fi
else
    info "No Open WebUI Docker image found (nothing to do)"
fi

# ─── Step 4: Remove downloaded models from Ollama ───────────────────────────
if command -v ollama &>/dev/null; then
    MODELS=$(ollama list 2>/dev/null | tail -n +2 | awk '{print $1}' || true)
    if [ -n "$MODELS" ]; then
        echo ""
        echo "Ollama has the following models installed:"
        echo "$MODELS" | while read -r m; do echo "  - $m"; done
        if confirm "Remove ALL downloaded models? (Frees several GB of disk space.)"; then
            echo "$MODELS" | while read -r m; do
                ollama rm "$m" && info "Removed model: $m"
            done
        else
            skip "Ollama models"
        fi
    else
        info "No Ollama models found (nothing to do)"
    fi
else
    info "Ollama is not installed (nothing to do)"
fi

# ─── Step 5: Uninstall Ollama itself ────────────────────────────────────────
if command -v ollama &>/dev/null; then
    if confirm "Uninstall Ollama from your system?"; then
        # Stop Ollama if running
        pkill -x ollama 2>/dev/null || true
        pkill -x Ollama 2>/dev/null || true

        # Remove the app and symlink
        if [ -d "/Applications/Ollama.app" ]; then
            rm -rf "/Applications/Ollama.app"
        fi
        if [ -L "/usr/local/bin/ollama" ]; then
            rm -f "/usr/local/bin/ollama" 2>/dev/null || sudo rm -f "/usr/local/bin/ollama"
        elif [ -f "/usr/local/bin/ollama" ]; then
            rm -f "/usr/local/bin/ollama" 2>/dev/null || sudo rm -f "/usr/local/bin/ollama"
        fi

        # Remove Ollama data directory
        if [ -d "$HOME/.ollama" ]; then
            rm -rf "$HOME/.ollama"
        fi

        info "Ollama uninstalled"
    else
        skip "Ollama uninstall"
    fi
fi

# ─── Done ────────────────────────────────────────────────────────────────────
echo ""
echo "========================================="
echo "  Teardown complete."
echo ""
echo "  If you also want to remove Docker Desktop"
echo "  itself, do that from your Applications"
echo "  folder or System Settings."
echo "========================================="
echo ""
