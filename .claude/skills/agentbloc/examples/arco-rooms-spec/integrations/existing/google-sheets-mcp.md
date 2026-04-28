# google-sheets-mcp — EXISTS-MCP

| Property | Value |
|---|---|
| Tool ID | `google-sheets-mcp` |
| Vendor | Google (community-maintained slim MCP) |
| Used by | gestor-cobros (tenant registry lookup) |
| Tier | **EXISTS-MCP** |
| Effort | 2 CC-hours |

## MCP server

| Property | Value |
|---|---|
| Repo | https://github.com/xing5/mcp-google-sheets |
| Publisher | xing5 |
| Last commit | 2026-01-30 |
| Trust tier | MEDIUM |
| Install | `npx -y mcp-google-sheets@0.4.1` |

## Why this MCP

Focused on Sheets CRUD. Smaller surface than google-workspace-mcp's
Sheets tools — useful when agent reasoning is sheet-heavy. The tenant
registry is the source of truth for owner ↔ property ↔ tenant ↔
contract mappings.

## Install

```json
{
  "mcpServers": {
    "google-sheets-mcp": {
      "command": "npx",
      "args": ["-y", "mcp-google-sheets@0.4.1"],
      "env": {
        "GOOGLE_SHEETS_OAUTH_TOKEN": "${env:GOOGLE_SHEETS_OAUTH_TOKEN}",
        "TENANT_REGISTRY_SHEET_ID": "${env:TENANT_REGISTRY_SHEET_ID}"
      }
    }
  }
}
```

Required scope: `spreadsheets` (read + write own sheets).

## Tools the agents use

| MCP tool | Used by | Operation | Blast |
|---|---|---|---|
| `read_range(sheet_id, range)` | gestor-cobros | Read tenant registry | L1 |
| `append_row(sheet_id, row)` | gestor-cobros | Append to own daily-log sheet (separate from registry) | L2 |
| `write_range` | (NOT USED) | Out of envelope — would write to master registry | — |

## Authentication

Reuse Google OAuth refresh token.

## Cross-references

- Inventory: [`../INVENTORY.md`](../INVENTORY.md)
- Sibling: [`google-workspace-mcp.md`](google-workspace-mcp.md)
