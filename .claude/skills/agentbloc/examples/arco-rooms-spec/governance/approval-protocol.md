# Approval Protocol — Arco Rooms

> When + how the team requests Pablo's approval. Contract every
> `semi`/`supervised` agent honors before L3+ tool calls.

## When approval is required

| Autonomy | L1 | L2 | L3 | L4 |
|---|---|---|---|---|
| `full` | proceed | proceed | proceed | proceed |
| `semi` | proceed | proceed | proceed | **approval required** |
| `supervised` | proceed | proceed | **approval required** | **approval required** |

This team uses `full` (gestor-documental) and `semi` (gestor-cobros,
recepcionista). `recepcionista` is the only L4 agent — every Telegram
send fires the approval gate.

Approval is NEVER required for L1 (read-only) or L2 (write-scoped)
regardless of autonomy.

## Approval channel

| Property | Value |
|---|---|
| Medium | Telegram |
| Thread | `TELEGRAM_APPROVAL_THREAD_ID` (per `.env`) |
| Bot | Team bot (`TELEGRAM_BOT_TOKEN`) |
| Authorized approvers | Pablo (per `TELEGRAM_AUTHORIZED_USERS`) |

Approvals live in a DIFFERENT Telegram thread from briefings and
escalations. Rationale: time-sensitive decisions must not be buried.

## Request message format

```
[APPROVE/DENY] {{agent_id}}
Correlation: {{correlation_id}}
Action: {{tool_name}}({{args_summary_redacted}})
Reversibility: {{reversibility_tag}}
Reasoning: {{tool_reasoning}}

Reply: /approve {{correlation_id}}
   OR  /deny    {{correlation_id}}
```

| Field | Source | Notes |
|---|---|---|
| `agent_id` | env `CLAUDE_AGENT_ID` | Set by `wake.sh` |
| `correlation_id` | env `CLAUDE_CORRELATION_ID` | Flows through entire wake |
| `tool_name` | runtime hook | The MCP tool about to fire |
| `args_summary_redacted` | hook | PII-redacted single-line summary |
| `reversibility_tag` | derived from blast | `reversible` / `hard-to-reverse` / `irreversible` |
| `tool_reasoning` | env `TOOL_REASONING` | 1-2 sentence rationale set by agent |

`semi`/`supervised` agents that fail to set `TOOL_REASONING` have the
tool BLOCKED with `result: blocked, reason: missing-tool-reasoning`.

## Reversibility tags

| Tag | Examples (this team) | Default response time |
|---|---|---|
| `reversible` | (none currently — no tool fits this for arco-rooms) | n/a |
| `hard-to-reverse` | recepcionista send_message to per-owner thread (Telegram doesn't recall) | 5 min |
| `irreversible` | recepcionista send_message tagged "formal notice" (legal/contractual weight) | 1 min |

## Approval response

Pablo replies in approvals thread:

| Reply | Effect |
|---|---|
| `/approve <correlation-id>` | Append to `approvals.jsonl` with `decision: approve`; agent unblocks |
| `/approve <correlation-id> <reasoning>` | Same + reasoning captured |
| `/deny <correlation-id>` | Append with `decision: deny`; agent skips action |
| `/deny <correlation-id> <reasoning>` | Same + reasoning captured |

`<correlation-id>` arg disambiguates concurrent pending approvals.
Multiple agents may have pending approvals simultaneously
(e.g., recepcionista with 5 owner messages all queued).

## Timeout behavior

If no approval within `APPROVAL_TIMEOUT_SECONDS` (default 600 = 10 min):

- Tier 1 ping: re-send approval message tagged `[ESC1]`
  (correlation-id `<orig>-esc1`)
- Tier 2 ping: re-send tagged `[ESC2]` (correlation-id `<orig>-esc2`)
- Tier 3 final: escalate to `escalations_thread_id`; agent sets
  `last-run.json status=error`; subsequent wakes short-circuit

Each tier uses derived child correlation-id to bypass dedup in
`telegram-send.sh`. Persistent halt continues until `/resume
<correlation-id>` lands.

## Authorized users

Only Telegram user IDs in `.env` `TELEGRAM_AUTHORIZED_USERS` can
approve. Replies from other users are logged + ignored. Authorization
enforced in `runtime/reference-impl/approval-router.sh`, NOT by
Telegram itself.

For multi-approver setups (not used in v1; reserved for future
compliance scenarios), require two distinct authorized IDs both
posting `/approve <correlation-id>` within the timeout window.

## State persistence

```
.agentbloc/state/approvals.jsonl
```

Append-only. Two lines per round-trip:

1. `action: approval_request` — set when agent posts the message
2. `action: approval_response` — set when operator replies (or
   timeout)

Schema in [`audit-trail.md`](audit-trail.md). `details.outcome` enum:
`approved` / `denied` / `timeout`.

## Build-session responsibilities

1. Implement request poster (Telegram MCP `send_message` to thread)
2. Implement response listener (Telegram `getUpdates` long-poll)
3. Implement timeout watchdog (re-pings + escalation tier ladder)
4. Implement authorization check (sender ID matches authorized list)
5. Wire to PreToolUse hook so tool calls block until decision lands
6. Append to approvals.jsonl per [`audit-trail.md`](audit-trail.md)
7. Write tests:
   - Request fires; approve unblocks; deny blocks; timeout escalates
   - Unauthorized reply ignored
   - Concurrent pending approvals (5 owner messages at once) all
     resolve correctly without cross-contamination

## Cross-references

- Blast radius: [`blast-radius.md`](blast-radius.md)
- Audit trail: [`audit-trail.md`](audit-trail.md)
- Per-agent escalation: `../agents/<id>/escalation.md`
- Reference impl: `../runtime/reference-impl/approval-router.sh`
- AgentBloc reference: `references/approval-router.md`
