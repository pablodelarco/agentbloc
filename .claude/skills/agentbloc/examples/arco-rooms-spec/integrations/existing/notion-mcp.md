# notion-mcp — EXISTS-MCP

| Property | Value |
|---|---|
| Tool ID | `notion-mcp` |
| Vendor | Notion (community-maintained MCP) |
| Used by | recepcionista (RESERVED — not used in v1) |
| Tier | **EXISTS-MCP** |
| Effort | 2 CC-hours |

## MCP server

| Property | Value |
|---|---|
| Repo | https://github.com/community/notion-mcp |
| Publisher | community |
| Last commit | 2026-03-05 |
| Trust tier | MEDIUM |
| Install | `npx -y notion-mcp@0.5.3` |

## Why this MCP (and why install if unused)

The original interview surfaced a future requirement: archive
per-owner reports to Notion for long-term searchable history. v1 of
the team does NOT use Notion at runtime, but the inventory entry and
this install doc exist so the build session can wire it up later
without revisiting Phase 3.

If you don't intend to add the archive feature, you can skip
installation in v1 and remove this entry on next AgentBloc
re-emission.

## Install (when activating)

```json
{
  "mcpServers": {
    "notion-mcp": {
      "command": "npx",
      "args": ["-y", "notion-mcp@0.5.3"],
      "env": {
        "NOTION_API_TOKEN": "${env:NOTION_API_TOKEN}"
      }
    }
  }
}
```

| Variable | How to obtain |
|---|---|
| `NOTION_API_TOKEN` | Notion → Settings → Integrations → Internal Integration → Create token |

## Tools the agents would use (when activated)

| MCP tool | Used by | Operation | Blast |
|---|---|---|---|
| `create_page` | recepcionista | Archive per-owner daily summary as Notion page | L4 (write external) |
| `update_page` | recepcionista | Append updates to existing archive page | L4 |
| `search` | recepcionista | Find prior reports for a property | L1 |

When activated, `create_page` and `update_page` are L4 send-external
and route through the same approval gate as Telegram sends.

## Cross-references

- Inventory: [`../INVENTORY.md`](../INVENTORY.md)
- Future feature: revisit on AgentBloc Phase 6 spec evolution
