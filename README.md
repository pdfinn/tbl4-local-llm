# TBL4 Local LLM

Run a large language model locally on your laptop with a ChatGPT-like web interface. No cloud, no API keys, no cost.

## What you get

- **Ollama** — runs the LLM on your machine (uses your GPU for speed)
- **Open WebUI** — a web-based chat interface at `http://localhost:3000`

## Prerequisites

Install this **before** running setup:

- **Docker Desktop** — [download here](https://www.docker.com/products/docker-desktop/)
   - Install it, open it, and make sure it is **running** (you should see the Docker whale icon in your menu bar / system tray)

The setup script will install everything else automatically (including [Ollama](https://ollama.com/download)).

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

Open **PowerShell** and run:

```powershell
git clone https://github.com/pdfinn/tbl4-local-llm.git
cd tbl4-local-llm
.\setup.ps1
```

> If you get a script execution error, run this first:
> `Set-ExecutionPolicy -Scope CurrentUser RemoteSigned`

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

## Troubleshooting

| Problem | Fix |
|---------|-----|
| "Docker is not running" | Open Docker Desktop and wait for it to finish starting |
| Web UI shows "Ollama not reachable" | Make sure Ollama is running: `ollama serve` |
| Model is very slow | Try a smaller model: edit `.env` and set `MODEL=llama3.2:1b` |
| Port 3000 is already in use | Edit `.env` and change `WEBUI_PORT` to another number (e.g., `3001`) |
| Windows script won't run | Run: `Set-ExecutionPolicy -Scope CurrentUser RemoteSigned` |
| Web UI shows a blank page on first launch | Wait about a minute — it downloads components on first start |
| macOS asks for password during setup | This is the Ollama installer — enter your Mac login password |
