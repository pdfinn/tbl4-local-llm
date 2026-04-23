<p align="center">
  <img src="logo.png" alt="Tarkas Brainlab IV" width="200">
</p>

<h1 align="center">Tarkas Brainlab IV — Local LLM</h1>

<p align="center">
  Run a large language model locally on your laptop with a ChatGPT-like web interface.<br>
  No cloud. No API keys. No cost.
</p>

---

## What you get

- **[Ollama](https://ollama.com)** — runs the LLM on your machine (uses your GPU for speed)
- **[Open WebUI](https://github.com/open-webui/open-webui)** — a web-based chat interface at `http://localhost:3000`

## Prerequisites

Install this **once, before** running setup:

- **Docker Desktop** — [download here](https://www.docker.com/products/docker-desktop/)
   - Run the installer and accept the defaults.
   - **Windows only:** Docker will ask to enable WSL 2 and will require a **reboot** after install. This is normal and only happens once.
   - After reboot, open Docker Desktop, accept the agreement, and wait until the whale icon in your system tray (Windows) or menu bar (macOS) is steady (not animated). That means Docker is running.

The setup script installs everything else automatically (including [Ollama](https://ollama.com/download)).

## Setup

### macOS

Open **Terminal** and run:

```bash
git clone https://github.com/pdfinn/tbl4-local-llm.git
cd tbl4-local-llm
chmod +x setup.sh
./setup.sh
```

> The Ollama installer may ask for your **password** once — this is normal. It needs it to add the `ollama` command to your system.

### Windows

1. [Download the repository as a ZIP](https://github.com/pdfinn/tbl4-local-llm/archive/refs/heads/main.zip) and unzip it anywhere (e.g. your Desktop).
2. Open the unzipped folder and **double-click `setup.bat`**.

That's it — a window will open and walk you through the install. Leave it open until it finishes.

<details>
<summary>Prefer the command line?</summary>

```powershell
git clone https://github.com/pdfinn/tbl4-local-llm.git
cd tbl4-local-llm
.\setup.bat
```

</details>

## Using it

After setup completes, open your browser to:

**http://localhost:3000**

> The **first launch** takes about a minute while the web interface downloads some internal components. This only happens once — after that it starts in seconds.

Select the model from the dropdown at the top of the chat and start chatting.

## Choosing a different model

Edit the `.env` file and change the `MODEL` line, then re-run the setup script. Browse available models at [ollama.com/library](https://ollama.com/library).

Some good options:

| Model | Size | Good for |
|-------|------|----------|
| `llama3.2` | 3B | General use, fast (default) |
| `phi3:mini` | 3.8B | Coding tasks |
| `mistral` | 7B | Longer, more detailed answers |
| `llama3.2:1b` | 1B | Older/slower machines |

## Starting and stopping

**Stop everything:**
```bash
docker compose down
# Close Ollama: quit from menu bar (macOS) or system tray (Windows)
```

**Start again later:**
```bash
ollama serve          # macOS terminal (Windows: open the Ollama app)
docker compose up -d
```
Then open http://localhost:3000.

## Uninstalling

When you're done with the course and want to reclaim disk space, run the teardown script. It asks for confirmation before each step — nothing is deleted without your approval.

**macOS:**
```bash
chmod +x teardown.sh
./teardown.sh
```

**Windows:**

Double-click `teardown.bat`.

## Troubleshooting

| Problem | Fix |
|---------|-----|
| "Docker is not running" | Open Docker Desktop and wait for it to finish starting |
| Web UI shows "Ollama not reachable" | Make sure Ollama is running: `ollama serve` |
| Model is very slow | Try a smaller model: edit `.env` and set `MODEL=llama3.2:1b` |
| Port 3000 is already in use | Edit `.env` and change `WEBUI_PORT` to another number (e.g., `3001`) |
| Windows: setup window flashes and closes | Right-click `setup.bat` → **Run as administrator**, or run it from an already-open PowerShell/Command Prompt so you can read any error |
| Web UI shows a blank page on first launch | Wait about a minute — it downloads components on first start |
| macOS asks for password during setup | This is the Ollama installer — enter your Mac login password |

---

<p align="center">
  <a href="https://github.com/Tarkas-Brainlab-IV">Tarkas Brainlab IV</a>
</p>
