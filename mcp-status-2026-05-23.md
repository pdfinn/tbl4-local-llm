# MCP Cancel-Scope Bug — Status Check 2026-05-23

## Versions

| | Version | Date |
|---|---|---|
| **Pinned (docker-compose.yml)** | v0.9.1 | — |
| **Latest OpenWebUI** | v0.9.5 | 2026-05-10 |
| **mcp-python-sdk (latest visible)** | v1.27.1 | 2025-05-08 |

---

## Verdict: LIKELY FIXED

OpenWebUI **v0.9.2** (released 2026-04-24) contains an explicit fix for the exact
cancel-scope bug logged in `TODO.md`.

---

## Relevant Release-Note Excerpts

### OpenWebUI v0.9.2 (2026-04-24)

> **MCP Task Cancellation:**
> "Interrupted MCP tool calls no longer cause CPU spikes or runaway cleanup behavior.
> MCP client disconnection now runs in the same asyncio task as connection, **respecting
> cancel scope constraints**, and chat-active events are properly shielded during
> cancellation."

> **Cancelled Response Streams:**
> "Cancelled chat generation now explicitly closes the upstream response body iterator,
> preventing orphaned async generators from spinning in anyio internals."

This directly addresses `RuntimeError: Attempted to exit cancel scope in a different
task than it was entered in` — the connection is now entered and exited in the same
task, satisfying anyio's cancel-scope invariant.

### OpenWebUI v0.9.3 (2026-05-09)

> **MCP Cleanup Response Reliability:**
> "Successful native MCP tool calls no longer get replaced by a 500 'No response
> returned' error during cleanup, so valid chat responses are now returned consistently."

A follow-on hardening to the MCP client; no cancel-scope content.

### OpenWebUI v0.9.5 (2026-05-10)

MCP tools referenced as a supported pipeline feature (channel streaming). No further
cancel-scope fixes needed.

---

## mcp-python-sdk

The releases page shows v1.27.1 (2025-05-08) as the most recent entry with no
cancel-scope or streamable-http fixes visible since 2026-04. The fix for this bug
was made at the **OpenWebUI application layer** (v0.9.2) rather than in the SDK
itself, so the SDK version is not blocking resolution.

---

## Reasoning

The v0.9.2 release note uses the phrase "same asyncio task … respecting cancel scope
constraints" — this is an exact description of the root cause documented in `TODO.md`
(`RuntimeError: Attempted to exit cancel scope in a different task than it was entered
in`). No ambiguous or indirect language; this is a targeted fix.

---

## Recommended Next Action

**Bump the OpenWebUI pin to v0.9.5 and test the MCP path end-to-end** before merging.

Quick test sequence (from `TODO.md`):

```bash
docker compose pull && docker compose up -d
# In OpenWebUI UI → Admin Settings → Tool Servers → add MCP server
# URL: http://host.docker.internal:5678/webhook/mcpTools/mcp/tools
# Type: MCP
# Verify: "Tools" page shows no "Failed to connect" error
# In chat: toggle tool on, ask "summarise https://en.wikipedia.org/wiki/Singapore"
```

If successful, the mcpo proxy workaround (TODO path 2) is no longer needed for the
n8n integration path.
