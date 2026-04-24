# TODO

## MCP Tool Server path is currently broken

**Status:** blocked on OpenWebUI 0.9.1 client bug. n8n side verified working.

### Symptom

When OpenWebUI is configured with a Tool Server of type `MCP` pointing at the
n8n MCP Server Trigger (`http://host.docker.internal:5678/webhook/mcpTools/mcp/tools`),
OpenWebUI's `openwebui-tools` page shows `Failed to connect to MCP server`.

Container logs reveal:

```
RuntimeError: Attempted to exit cancel scope in a different task than it was
entered in
  File "/usr/local/lib/python3.11/site-packages/mcp/client/streamable_http.py",
  line 670, in streamable_http_client
```

### Root cause

Known issue in the MCP Python SDK's `streamable_http_client` around async-context
lifecycle — the client is entered in one asyncio task and exited in another,
which anyio's cancel-scope machinery refuses. OpenWebUI's `MCPClient` wraps the
SDK and inherits the bug.

### Verification that n8n side is correct

```bash
# Initialize MCP session
curl -sD- -X POST http://localhost:5678/webhook/mcpTools/mcp/tools \
  -H 'content-type: application/json' \
  -H 'accept: application/json, text/event-stream' \
  -d '{"jsonrpc":"2.0","id":1,"method":"initialize","params":{"protocolVersion":"2024-11-05","capabilities":{},"clientInfo":{"name":"test","version":"0.1"}}}'
# → 200 OK with mcp-session-id header and capabilities.tools: {}

# List tools (with session from above)
curl -s -X POST ... -H 'mcp-session-id: <sid>' \
  -d '{"jsonrpc":"2.0","id":2,"method":"tools/list"}'
# → returns `summariseUrl` with full description

# Call the tool
curl -s -X POST ... -H 'mcp-session-id: <sid>' \
  -d '{"jsonrpc":"2.0","id":3,"method":"tools/call","params":{"name":"summariseUrl","arguments":{"input":"{\"url\":\"https://example.com\",\"focus\":\"\"}"}}}'
# → returns real summary over Ollama
```

All three calls succeed. The n8n MCP server is conformant.

### Two paths to resolution

**1. Wait for an OpenWebUI MCP client fix.**
Track https://github.com/open-webui/open-webui and the `mcp-python-sdk` for
fixes to the cancel-scope bug. When a new OpenWebUI release lands that bumps
the MCP SDK past the buggy version, pin to it in `docker-compose.yml` and
test end-to-end:

```bash
# quickcheck after bumping the OpenWebUI image tag:
docker compose pull && docker compose up -d
# then in OpenWebUI UI, re-add the MCP Tool Server and try a chat.
```

**2. Put mcpo back in the data path as an MCP→OpenAPI proxy.**
mcpo is already in `docker-compose.yml` (profile-gated). Configure it to
proxy the n8n MCP endpoint and register mcpo in OpenWebUI as a *Tool Server
of type OpenAPI* instead. OpenWebUI's OpenAPI path does not hit the buggy
MCP client.

Sketch:

```json
// mcpo.config.json
{
  "mcpServers": {
    "tbl4": {
      "type": "streamable-http",
      "url": "http://host.docker.internal:5678/webhook/mcpTools/mcp/tools"
    }
  }
}
```

```bash
docker compose --profile mcp up -d
# Register in OpenWebUI → Admin Settings → Tools → Tool Servers:
#   Type: OpenAPI
#   URL:  http://mcpo:8000/tbl4
```

Unverified — the `type: streamable-http` key is what mcpo's current docs
suggest but exact form may differ by release. Test before committing.

### Until one of those lands

The working path is **Workspace → Tools → Create New Tool**, pasting
`openwebui-tools/summarise_url.py`. That path is classroom-ready today.
