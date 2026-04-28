# Blast Radius — Arco Rooms

> Team-wide risk envelope. Per-agent specifics live in
> `agents/<agent-id>/blast-radius.md`.

## The 4 levels

| Level | Definition | Approval gate |
|---|---|---|
| **L1 — read-only** | Reads state files; reads external APIs. No writes, no external sends. | Never |
| **L2 — write-scoped** | Writes only to designated paths (own state directory + designated inboxes). No external sends. | Never |
| **L3 — write-unrestricted** | Writes to arbitrary paths or runs unrestricted Bash. | Required for `semi` and `supervised` |
| **L4 — send-external** | Sends Telegram, emails, third-party API calls. | Required for `semi` and `supervised` |

**L4 is concentrated in 1 dedicated agent (recepcionista).** Two
upstream agents (gestor-documental, gestor-cobros) cap at L2. This is
the deliberate design choice for this team.

## Agent assignment

| Agent | Level | Autonomy | Approval gate active |
|---|---|---|---|
| gestor-documental | L2 | full | No (envelope is L2; full autonomy permits unattended L2) |
| gestor-cobros | L2 | semi | Active for hypothetical L3+ (none in v1; defense-in-depth) |
| recepcionista | L4 | semi | **Active on every send** |

Per-agent envelope detail in `agents/<agent-id>/blast-radius.md`.

## Why these assignments

- **gestor-documental L2/full**: invoice collection is read-from-
  external + write-to-local. Reversible. Full autonomy is appropriate.
- **gestor-cobros L2/semi**: payment matching is also read-from +
  write-to-local. L2. But its decision rule (overdue → formal notice)
  has L4 implications downstream, so `semi` autonomy adds an audit
  checkpoint without blocking.
- **recepcionista L4/semi**: ALL Telegram sends require approval. No
  exceptions in v1. PII-sensitive content + reputation-bearing nature
  of owner messages justifies the gate.

## Tool classification (deterministic)

A tool's blast level is derived from its operation, not assigned
arbitrarily:

| Pattern | Level |
|---|---|
| MCP tool name starts with `read_`, `list_`, `search_`, `fetch_`, `get_` | L1 |
| Writes to `.agentbloc/agents/<self>/` (own state) | L2 |
| Writes to `.agentbloc/agents/<other>/inbox/` (designated handoff) | L2 |
| MCP tool name starts with `create_`, `update_`, `delete_` (write to external) | L3 (or L4 if recipient is human) |
| Bash that writes outside designated dirs | L3 |
| MCP tool name starts with `send_`, `post_`, `transfer_`, `pay_`, `dispatch_` | L4 |
| Telegram MCP `send_message` (any thread) | L4 |

The `agents/<id>/tools.md` file applies this classification per tool.
The hook `runtime/reference-impl/hooks/autonomy-gate.sh` enforces it.

## Cooperative enforcement (agent prose)

Each agent's `prompts.md` system prompt instructs:

> "Before invoking any L3+ tool, send a Telegram approval request and
> wait for `/approve <correlation-id>`."

For recepcionista (the L4 agent), this rule fires on every
send_message. For gestor-cobros (semi at L2), this rule is
preventive: any future L3+ tool addition activates the gate.

## Deterministic enforcement (PreToolUse hook)

`runtime/reference-impl/hooks/autonomy-gate.sh` PreToolUse:

1. Reads `CLAUDE_AGENT_ID` from env (set by `wake.sh`)
2. Looks up the agent's autonomy level
3. Classifies the tool's blast level per patterns above
4. Checks `.agentbloc/state/approvals.jsonl` for matching
   `correlation_id` with `decision == "approve"`
5. Exits 2 (block) if blast > permitted-threshold AND no approval found

Defense in depth.

## Autonomy levels (refresher)

| Autonomy | L1 | L2 | L3 | L4 |
|---|---|---|---|---|
| `full` | proceed | proceed | proceed | proceed |
| `semi` | proceed | proceed | proceed | **approval** |
| `supervised` | proceed | proceed | **approval** | **approval** |

This team uses `full` (gestor-documental) and `semi` (the other two).
No `supervised` in v1.

## Cross-references

- Per-agent envelopes: `../agents/<id>/blast-radius.md`
- Approval protocol: [`approval-protocol.md`](approval-protocol.md)
- Audit trail: [`audit-trail.md`](audit-trail.md)
- Kill switch: [`kill-switch.md`](kill-switch.md)
- AgentBloc reference: `references/blast-radius.md`
