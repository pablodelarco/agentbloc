# google-workspace-mcp — EXISTS-MCP

| Property | Value |
|---|---|
| Tool ID | `google-workspace-mcp` |
| Vendor | Google (community-maintained MCP wrapper) |
| Used by | gestor-documental |
| Tier | **EXISTS-MCP** |
| Effort | 2 CC-hours |

## MCP server

| Property | Value |
|---|---|
| Repo | https://github.com/taylorwilsdon/google_workspace_mcp |
| Publisher | taylorwilsdon (community) |
| Last commit | 2026-03-14 |
| Trust tier | MEDIUM (>500 stars, recent commits) |
| Install | `npx -y google_workspace_mcp@1.4.2` |

## Why this MCP

Single-server coverage of Gmail + Drive + Docs + Sheets + Calendar +
Forms + Tasks + Chat — minimizes the OAuth surface area to one app
registration. taylorwilsdon's repo is the most actively-maintained
community Google integration as of 2026-03.

## Install

```json
{
  "mcpServers": {
    "google-workspace-mcp": {
      "command": "npx",
      "args": ["-y", "google_workspace_mcp@1.4.2"],
      "env": {
        "GOOGLE_REFRESH_TOKEN": "${env:GOOGLE_REFRESH_TOKEN}",
        "GOOGLE_CLIENT_ID": "${env:GOOGLE_CLIENT_ID}",
        "GOOGLE_CLIENT_SECRET": "${env:GOOGLE_CLIENT_SECRET}"
      }
    }
  }
}
```

| Variable | How to obtain |
|---|---|
| `GOOGLE_CLIENT_ID` | Google Cloud Console → APIs & Services → Credentials → Create OAuth 2.0 Client ID |
| `GOOGLE_CLIENT_SECRET` | Same |
| `GOOGLE_REFRESH_TOKEN` | OAuth dance once at install (taylorwilsdon repo has CLI helper) |

Required scopes: `gmail.readonly`, `drive.file`. NOT `gmail.modify`
(read-only access to email).

## Tools the agents use

| MCP tool | Used by | Operation | Blast |
|---|---|---|---|
| `gmail_list_messages` | gestor-documental | Filter `from:facturas@*` | L1 |
| `gmail_get_message` | gestor-documental | Fetch message + attachments | L1 |
| `drive_list_files` | gestor-documental | Find PDF attachments by message ID | L1 |
| `drive_download_file` | gestor-documental | Download PDF locally | L2 |

## Authentication

OAuth 2.0 with refresh token. The 90-day token rotation per Google
policy is handled by the MCP server automatically.

## Rate limits

Gmail API: 1B quota units/day per user (effectively unlimited for
this usage). Drive API: 20K read requests/100s/user. Both well above
the team's expected usage (~50 messages/day).

## Cross-references

- Inventory: [`../INVENTORY.md`](../INVENTORY.md)
- Phase 3 protocol: `references/mcp-integration-protocol.md`
