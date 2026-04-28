# telegram-mcp — EXISTS-MCP

| Property | Value |
|---|---|
| Tool ID | `telegram-mcp` |
| Vendor | Telegram (community-maintained MCP) |
| Used by | recepcionista |
| Tier | **EXISTS-MCP** |
| Effort | 2 CC-hours |

## MCP server

| Property | Value |
|---|---|
| Repo | https://github.com/guangxiangdebizi/telegram-mcp |
| Publisher | guangxiangdebizi (community) |
| Last commit | 2026-01-20 |
| Trust tier | MEDIUM |
| Install | `npx -y telegram-mcp@0.3.8` |

## Why this MCP

Telegram Bot API approach (not MTProto user-account) — appropriate
for outbound team notifications. Three-thread separation
(approvals/briefings/escalations) per CTRL-01 separation rule is
natively supported via thread_id parameter on send_message.

## Install

1. Create bot via @BotFather (saves `TELEGRAM_BOT_TOKEN`)
2. Add bot to a Telegram group
3. Create three threads in the group: approvals, briefings,
   escalations. Note their thread IDs (visible in URL when message is
   selected: `t.me/c/<chat_id>/<thread_id>`)
4. Plus per-owner threads (one per property owner)

Add to `.mcp.json`:

```json
{
  "mcpServers": {
    "telegram-mcp": {
      "command": "npx",
      "args": ["-y", "telegram-mcp@0.3.8"],
      "env": {
        "TELEGRAM_BOT_TOKEN": "${env:TELEGRAM_BOT_TOKEN}"
      }
    }
  }
}
```

| Variable | How to obtain |
|---|---|
| `TELEGRAM_BOT_TOKEN` | @BotFather: `/newbot` |
| `TELEGRAM_APPROVAL_THREAD_ID` | URL of any message in the approvals thread |
| `TELEGRAM_BRIEFING_THREAD_ID` | Same for briefings thread |
| `TELEGRAM_ESCALATIONS_THREAD_ID` | Same for escalations thread |
| `TELEGRAM_AUTHORIZED_USERS` | Comma-separated user IDs allowed to /approve (Pablo's user ID) |

## Tools the agents use

| MCP tool | Used by | Operation | Blast |
|---|---|---|---|
| `send_message(thread_id, text)` | recepcionista | Send to per-owner / approvals / briefings / escalations threads | L4 |
| `send_voice` | recepcionista | Voice notes (v1 unused) | L4 |
| `create_thread` | (build session, install-time only) | Create approval/briefing/escalations threads | L3 |

## Authentication

Bot API token. Bot must be added to all destination groups/channels.
Per-owner threads require the bot to be added to each owner's group
(or use direct messages if owner accepts).

## Rate limits

30 messages/second per bot, 20 messages/minute per group/thread.
Recepcionista's usage (one nightly send per owner + one summary +
occasional alert) stays well within limits.

## Known issues

- 30-day inactive thread auto-archive: refresh by sending a `/ping`
  message every 25 days (cron job optional)
- Bot kicked from owner thread: recepcionista detects 403 and
  escalates per `governance/approval-protocol.md`

## Cross-references

- Inventory: [`../INVENTORY.md`](../INVENTORY.md)
- Approval protocol: [`../../governance/approval-protocol.md`](../../governance/approval-protocol.md)
