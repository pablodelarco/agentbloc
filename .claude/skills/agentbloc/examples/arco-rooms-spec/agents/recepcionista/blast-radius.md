# Blast Radius — recepcionista

## Assignment

| Property | Value |
|---|---|
| Blast radius | **L4** |
| Autonomy | **semi** |

## What L4 means

**L4 — send-external.** Sends Telegram messages to property owners
(human recipients with personal stakes in the content) and to Pablo
(operator). Highest-blast tier in this team. Concentrated in this
single agent — gestor-documental and gestor-cobros do NOT have L4
access.

## Why L4 + semi

Telegram sends to property owners are:
1. **Hard to reverse** — once delivered, recall is not possible
2. **Reputation-bearing** — wrong message to wrong owner damages
   trust irreparably
3. **PII-rich** — owner messages contain tenant names, amounts,
   addresses. Wrong-recipient delivery is a GDPR breach.

`semi` autonomy means EVERY L4 send requires explicit Pablo approval
via the approvals Telegram thread. There is no `full` autonomy path
for this agent. The first version of this team ships with the
approval gate active for all sends, full stop.

A future v2 may grant pre-approval for low-risk message classes (e.g.,
"all clear, no action needed today" template). v1 does not.

## Cooperative enforcement

System prompt explicitly states "EVERY send requires approval". The
agent composes messages and waits for approval before invoking
`telegram-mcp.send_message`.

## Deterministic enforcement

`runtime/reference-impl/hooks/autonomy-gate.sh` PreToolUse:
1. Reads `CLAUDE_AGENT_ID=recepcionista`, `autonomy=semi`
2. Classifies tool blast level: `mcp__telegram-mcp__send_message` → L4
3. Looks up `.agentbloc/state/approvals.jsonl` for matching
   `correlation_id` with `decision=approve`
4. If absent: posts approval request via
   `runtime/reference-impl/approval-router.sh` and blocks until
   response (default 600s timeout)
5. On approve: exit 0 (proceed with send)
6. On deny / timeout: exit 1 (block); agent logs the denial and
   continues (does NOT escalate on deny — that's expected behavior)

Reversibility tag: `hard-to-reverse` (per
`governance/approval-protocol.md`). Pablo's expected response time:
< 5 minutes for nightly sends.

## Permission boundaries

| Permitted | Forbidden |
|---|---|
| `send_message` to per-owner threads + Pablo's threads (with approval) | `send_message` to any other Telegram chat / user |
| `send_voice` (also L4, with approval; v1 unused) | Any non-Telegram external send (email, SMS, etc.) |
| Read inter-agent inbox for triggers | Modify other agents' state.json or memory.md |

## Special PII rules

`governance/pii-redaction.md` documents that owner messages CONTAIN
PII by design. The redactor exempts the message body from the base
GDPR redaction set when destination is a known per-owner thread (the
owner is the lawful recipient of their tenants' data per the property
management contract). However:
- DNI/NIE always redacted
- Full IBAN truncated to last 4 digits
- No tenant data leaks across owners (verified by the
  per-owner-thread routing)
- All messages are still logged with their PII redacted before audit
  emission (audit log itself never contains owner-message PII)

## Escalation

Per [`escalation.md`](escalation.md). Approval timeouts and Telegram
delivery failures are the canonical L4 failure modes.

## Cross-references

- Tools: [`tools.md`](tools.md)
- Approval protocol: [`../../governance/approval-protocol.md`](../../governance/approval-protocol.md)
- PII rules: [`../../governance/pii-redaction.md`](../../governance/pii-redaction.md)
- Audit trail: [`../../governance/audit-trail.md`](../../governance/audit-trail.md)
