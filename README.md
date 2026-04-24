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

1. [Download the repository as a ZIP](https://github.com/pdfinn/tbl4-local-llm/archive/refs/heads/main.zip) and unzip it anywhere (e.g. your Desktop).
2. Open the unzipped folder and double-click the file for your operating system:
   - **Windows:** `setup_windows.bat`
   - **macOS:** `setup_macos.command`

A window opens and walks you through the install. Leave it open until it finishes.

> **macOS first run:** Gatekeeper may block the file. Right-click `setup_macos.command` → **Open** → **Open** to approve it once. You will also be asked for your **password** during install — this is the Ollama installer adding the `ollama` command to your system.

<details>
<summary>Prefer the command line?</summary>

```bash
git clone https://github.com/pdfinn/tbl4-local-llm.git
cd tbl4-local-llm
./setup_macos.command       # macOS
.\setup_windows.bat         # Windows
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

## Using it next time

Just run the setup again — it is idempotent and will bring everything back up for you.

- **Windows:** double-click `setup_windows.bat`.
- **macOS:** double-click `setup_macos.command`.

Then open **http://localhost:3000**.

To fully stop everything (e.g., to free memory or close your laptop), quit Docker Desktop — Ollama will keep running in the background and uses very little memory when idle. Next session, re-run the setup.

<details>
<summary>Advanced: start/stop from the command line</summary>

```bash
# Stop
docker compose down
# Close Ollama: quit from menu bar (macOS) or system tray (Windows)

# Start again
ollama serve          # macOS Terminal (on Windows, open the Ollama app)
docker compose up -d
```

</details>

## Uninstalling

When you're done with the course and want to reclaim disk space, run the teardown script. It asks for confirmation before each step — nothing is deleted without your approval.

Double-click the file for your operating system:

- **Windows:** `teardown_windows.bat`
- **macOS:** `teardown_macos.command`

## Troubleshooting

| Problem | Fix |
|---------|-----|
| "Docker is not running" | Open Docker Desktop and wait for it to finish starting |
| Web UI shows "Ollama not reachable" | Make sure Ollama is running: `ollama serve` |
| Model is very slow | Try a smaller model: edit `.env` and set `MODEL=llama3.2:1b` |
| Port 3000 is already in use | Edit `.env` and change `WEBUI_PORT` to another number (e.g., `3001`) |
| Windows: setup window flashes and closes | Right-click `setup_windows.bat` → **Run as administrator**, or run it from an already-open PowerShell/Command Prompt so you can read any error |
| macOS: "cannot be opened because it is from an unidentified developer" | Right-click `setup_macos.command` → **Open** → **Open**. You only need to do this once. |
| macOS: Terminal window shows `zsh compinit: insecure directories` and then closes with `no such file or directory` | Your shell startup is prompting before the script can run. Open Terminal and run: `compaudit \| xargs chmod g-w,o-w` then double-click `setup_macos.command` again. |
| Web UI shows a blank page on first launch | Wait about a minute — it downloads components on first start |
| macOS asks for password during setup | This is the Ollama installer — enter your Mac login password |

---

## License

Copyright (c) 2026 Tarkas Brainlab IV (TBL4).

Licensed under the [PolyForm Noncommercial License 1.0.0](./LICENSE).
You may use, modify, and redistribute this software for any noncommercial
purpose, including personal study, research, teaching, and use by
educational or other noncommercial organizations. Commercial use requires
a separate license from the copyright holder.

For commercial licensing inquiries, please [open an issue on this repository](https://github.com/pdfinn/tbl4-local-llm/issues/new).

---

<p align="center">
  <a href="https://github.com/Tarkas-Brainlab-IV">Tarkas Brainlab IV</a>
</p>
