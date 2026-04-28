# gmail-mcp — EXISTS-MCP

| Property | Value |
|---|---|
| Tool ID | `gmail-mcp` |
| Vendor | Google (community-maintained slim MCP) |
| Used by | gestor-documental (fallback for Gmail-only flows; google-workspace-mcp covers same scope) |
| Tier | **EXISTS-MCP** |
| Effort | 2 CC-hours |

## MCP server

| Property | Value |
|---|---|
| Repo | https://github.com/smithery-ai/gmail-mcp |
| Publisher | smithery-ai |
| Last commit | 2026-02-18 |
| Trust tier | MEDIUM |
| Install | `npx -y @smithery-ai/gmail-mcp@0.2.5` |

## Why this MCP (and why install BOTH)

Smaller surface than google-workspace-mcp; useful when an agent only
needs Gmail and you want to minimize tool count for the LLM. v1 of
this team installs both — agents reference by tool name in prompts —
because the LLM is more likely to pick the right tool when scopes are
explicit.

If you prefer a smaller install footprint, you can drop this in favor
of google-workspace-mcp (it covers the same Gmail operations).

## Install

```json
{
  "mcpServers": {
    "gmail-mcp": {
      "command": "npx",
      "args": ["-y", "@smithery-ai/gmail-mcp@0.2.5"],
      "env": {
        "GMAIL_OAUTH_TOKEN": "${env:GMAIL_OAUTH_TOKEN}"
      }
    }
  }
}
```

Required scope: `gmail.readonly`.

## Tools the agents use

| MCP tool | Used by | Operation | Blast |
|---|---|---|---|
| `list_unread` | gestor-documental | List unread invoices for Naturgy/Movistar | L1 |
| `get_message` | gestor-documental | Fetch message body + attachments | L1 |
| `mark_read` | gestor-documental | Optional dedup signal | L2 (modifies remote state) |

## Authentication

OAuth refresh token. Reuse the token from google-workspace-mcp setup.

## Cross-references

- Inventory: [`../INVENTORY.md`](../INVENTORY.md)
- Sibling: [`google-workspace-mcp.md`](google-workspace-mcp.md)
