# Audit Trail — Arco Rooms

> Append-only JSONL log. Every tool call + lifecycle event captured.
> PII redacted before emission. GDPR Article 30 record of processing
> compliant.

## Scope

- Every tool call by every agent → 1 log line
- Every wake start + wake end → 1 line each
- Every approval request + response → 1 line each
- Every escalation → 1 line
- Every kill-switch fire → 1 line

Append-only. PII redacted before emission per
[`pii-redaction.md`](pii-redaction.md).

## Schema (12 fields)

```json
{
  "timestamp": "2026-04-28T22:00:00.123Z",
  "correlation_id": "cron-20260428T220000Z-a3f21b",
  "agent_id": "gestor-documental",
  "wake_id": "wake-20260428T220000Z-a3f21b",
  "action": "tool_call",
  "tool": "mcp__playwright-mcp__browser_navigate",
  "args_summary": "url=https://endesa.es/login",
  "result": "success",
  "duration_ms": 1240,
  "details": {"http_status": 200},
  "trace_parent": "cron-20260428T220000Z-a3f21b",
  "log_version": 1
}
```

| Field | Type | Required | Notes |
|---|---|---|---|
| `timestamp` | ISO-8601 UTC | yes | RFC 3339 with millisecond precision |
| `correlation_id` | string | yes | Set by `gen_correlation_id` at trigger time |
| `agent_id` | string | yes | One of: gestor-documental, gestor-cobros, recepcionista |
| `wake_id` | string | yes | One per wake invocation |
| `action` | enum | yes | `tool_call` / `wake_start` / `wake_end` / `approval_request` / `approval_response` / `escalation` / `kill_switch_fire` |
| `tool` | string | conditional | Required when `action == "tool_call"` |
| `args_summary` | string | conditional | PII-redacted summary; NEVER full args |
| `result` | enum | yes | `success` / `failure` / `blocked` / `pending` / `denied` / `timeout` |
| `duration_ms` | int | yes | Wall-clock duration |
| `details` | object | optional | Action-specific structured payload |
| `trace_parent` | string | yes | For nested calls; usually equals `correlation_id` |
| `log_version` | int | yes | `1` |

## File layout

```
.agentbloc/logs/
└── 2026-04-28/
    ├── audit.jsonl           # All tool calls (highest-volume file)
    ├── approvals.jsonl       # action=approval_request|approval_response only
    ├── escalations.jsonl     # action=escalation only
    └── kill-switch.jsonl     # action=kill_switch_fire only (rare)
```

Per-day rotation. Logs older than 90 days are pruned by
`runtime/reference-impl/log-rotate.sh` (run nightly).

## PII redaction

Before emitting any log line, run args / details through
`runtime/reference-impl/scripts/pii-redact.sh` (or runtime
equivalent) per [`pii-redaction.md`](pii-redaction.md). Patterns:

1. Email addresses → `<email-redacted>`
2. Phone numbers → `<phone-redacted>`
3. IBAN / SEPA → `<iban-redacted>`
4. Spain DNI/NIE → `<dni-redacted>` / `<nie-redacted>`
5. Credit card (Luhn-valid) → `<card-redacted>`
6. Long alphanumeric tokens (32+ chars) → `<token-redacted>`
7. Free text > 200 chars → first 100 + `[truncated]`

## What NEVER appears in logs

- Tenant full names (DNI/NIE redaction strips identifiers; full names
  stay only in agent runtime memory + Telegram messages, never in
  audit log)
- Bank account numbers (truncated to last 4)
- Authentication tokens or API keys
- Full email bodies (only metadata: sender domain, subject hash, date)
- File contents over 200 chars (truncated)

## Retention

| Log type | Retention | Rotation |
|---|---|---|
| audit.jsonl | 90 days | Daily |
| approvals.jsonl | 365 days (compliance) | Daily |
| escalations.jsonl | 365 days | Daily |
| kill-switch.jsonl | indefinite | Daily |

GDPR Article 30 compliance: 365-day retention on approvals +
escalations gives Pablo a year of records of processing decisions.
Audit log proper rotates faster (90 days) since it's high-volume.

## Tests the build session writes

Assert on shape:

1. Every tool call produces exactly one `tool_call` line
2. Every wake produces exactly one `wake_start` and one `wake_end`
3. `correlation_id` is non-empty + matches `gen_correlation_id` format
4. `args_summary` contains no DNI/NIE/IBAN/email/token patterns (PII
   test fixtures provided in
   `runtime/reference-impl/tests/redact_test.sh`)
5. `log_version` matches schema version (currently 1)
6. JSON parses cleanly (one object per line, newline-delimited)

## Cross-references

- PII patterns: [`pii-redaction.md`](pii-redaction.md)
- Approval entries: [`approval-protocol.md`](approval-protocol.md)
- Per-agent escalations: `../agents/<id>/escalation.md`
- Reference impl: `../runtime/reference-impl/helpers.sh` (`audit_log`)
