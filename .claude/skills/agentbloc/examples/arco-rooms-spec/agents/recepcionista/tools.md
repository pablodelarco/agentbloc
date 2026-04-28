# Tools — recepcionista

## Tool table

| Tool | Tier | Blast | Operations | Integration link |
|---|---|---|---|---|
| `telegram-mcp` | EXISTS-MCP | L4 | send_message (always L4); send_voice (L4); create_thread (L3, used at install only) | `../../integrations/existing/telegram-mcp.md` |

## Per-tool invocation pattern

### telegram-mcp

The team's only L4 tool. Every operation requires approval via
`approval-router.sh` per `governance/approval-protocol.md`.

Operations:
- `send_message(thread_id, text)` — L4 send-external. Approval
  required. Reversibility: hard-to-reverse. Used for:
  - Per-owner daily summaries (one approval per owner per day)
  - Pablo's daily self-summary on briefing thread
  - Pablo's real-time alerts (unmatched-payment-alert workflow)
- `send_voice(thread_id, audio_path)` — same as send_message, L4. Not
  used in v1.
- `create_thread(parent_chat_id, name)` — L3 write-unrestricted.
  Used at INSTALL time only (deploy-time setup of approvals/briefings/
  escalations threads). Build session executes manually; agent never
  invokes at runtime.

Approval gating (semi autonomy + L4): ALL send_message calls trigger
approval-router. Approval payload includes:
- agent_id: recepcionista
- tool: mcp__telegram-mcp__send_message
- args_summary: thread_id + first 100 chars of text (PII-redacted per
  governance/pii-redaction.md)
- reversibility: hard-to-reverse
- tool_reasoning: 1-2 sentence rationale set via env $TOOL_REASONING
  (required; missing → BLOCKED with reason: missing-tool-reasoning)

Pablo replies `/approve <correlation-id>` in approvals_thread_id; the
router unblocks the agent's send.

## Excluded tools (least-privilege boundary)

- `playwright-mcp`, `bank-mcp`, `gmail-mcp`, `google-workspace-mcp`,
  `mapfre-api`, `google-sheets-mcp` — not in this agent's scope. The
  agent only sends Telegram messages; data comes from inbox envelopes
  written by gestor-cobros + gestor-documental.
- `notion-mcp` — declared in inventory but currently unused by any
  workflow. Reserved for future "owner archive" feature.

## Cross-references

- Inventory: [`../../integrations/INVENTORY.md`](../../integrations/INVENTORY.md)
- Blast-radius: [`blast-radius.md`](blast-radius.md)
- Approval protocol: [`../../governance/approval-protocol.md`](../../governance/approval-protocol.md)
