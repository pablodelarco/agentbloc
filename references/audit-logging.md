# Audit Logging

> Security reference loaded by SKILL.md during Deployment (Phase 5) and when configuring Claude Code Hooks for PostToolUse audit logging.

## Table of Contents

- [When This Applies](#when-this-applies)
- [Log Format](#log-format)
- [Correlation ID Pattern](#correlation-id-pattern)
- [PII Redaction Rules](#pii-redaction-rules)
- [Retention Configuration](#retention-configuration)
- [Rate Limiting Governance](#rate-limiting-governance)
- [Quick Reference](#quick-reference)

## When This Applies

Claude reads this file during Deployment (Phase 5) when generating the `governance.yaml` audit and rate limiting blocks. It is also referenced when configuring Claude Code Hooks for PostToolUse audit logging, ensuring every side-effect tool call produces a compliant log entry. The patterns here define what gets logged, how PII is protected in logs, and how rate limits prevent runaway costs.

## Log Format

Each audit log is a JSONL file (one self-contained JSON object per line, append-only). This format is adapted from the IETF Agent Audit Trail draft (draft-sharif-agent-audit-trail-00).

### Field Definitions

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `timestamp` | string (ISO 8601) | mandatory | When the action occurred, with millisecond precision |
| `correlation_id` | string | mandatory | Session identifier linking related entries (see pattern below) |
| `agent` | string | mandatory | Agent name as defined in team.yaml |
| `action` | string | mandatory | What happened: `tool_call`, `decision`, `error`, `state_change` |
| `tool` | string | optional | MCP tool or Claude Code tool invoked (e.g., `mcp__playwright__navigate`) |
| `target` | string | optional | URL (stripped of query parameters), file path, or resource acted upon |
| `result` | string | mandatory | Outcome: `success`, `failure`, `skipped`, `blocked` |
| `duration_ms` | number | optional | Execution time in milliseconds |
| `pii_redacted` | boolean | mandatory | Whether PII redaction was applied to this entry |
| `error` | string | optional | Error message if result is `failure` |

### Example Entry

One line in the JSONL file:

```json
{"timestamp":"2026-04-14T10:23:45.123Z","correlation_id":"sess-invoice-collector-001","agent":"invoice-collector","action":"tool_call","tool":"mcp__playwright__navigate","target":"https://provider.example.com/invoices","result":"success","duration_ms":2340,"pii_redacted":true}
```

## Correlation ID Pattern

Correlation IDs link all log entries from a single agent execution into a traceable chain.

**Generation rules:**

1. Generated at session start: `sess-{agent_name}-{NNN}` where NNN is a zero-padded sequential number (e.g., `sess-invoice-collector-001`)
2. All log entries within a single agent run share the same correlation_id
3. If an agent delegates to a sub-agent, the sub-agent's correlation_id is `{parent_correlation_id}-sub-{NNN}` (e.g., `sess-invoice-collector-001-sub-001`)
4. This allows tracing a complete execution chain across multiple agents by searching for the parent prefix

**Example chain:**

```
sess-invoice-collector-001           <- parent agent
sess-invoice-collector-001-sub-001   <- first sub-agent delegation
sess-invoice-collector-001-sub-002   <- second sub-agent delegation
```

## PII Redaction Rules

Audit logs must never become a secondary PII store. These rules define what gets redacted before writing to the log file.

### ALWAYS Redact

Replace with `[REDACTED:{field_type}]` in log entries:

- Person names: `[REDACTED:name]`
- Email addresses: `[REDACTED:email]`
- Phone numbers: `[REDACTED:phone]`
- Physical addresses: `[REDACTED:address]`
- National IDs (DNI, NIE, SSN, passport): `[REDACTED:national_id]`
- Health data: `[REDACTED:health]`
- Financial account numbers: `[REDACTED:account]`

For data references that need traceability, use a SHA-256 hash of the value truncated to the first 8 characters: `hash:a1b2c3d4`. This allows correlation without exposing the original value.

### NEVER Log

These values must not appear in tool call results or log entries under any circumstance:

- Raw API keys
- Tokens (OAuth, session, refresh)
- Passwords or credentials
- Encryption keys

### KEEP As-Is

These values are safe to log without redaction:

- Service names and tool names
- URLs (stripped of query parameters)
- File paths
- Timestamps and durations
- HTTP status codes
- Agent names and action types

## Retention Configuration

### governance.yaml Audit Block Template

This block is copied into the generated `governance.yaml` during Deployment (Phase 5):

```yaml
audit:
  enabled: true
  format: jsonl
  path: .agentbloc/logs/audit.jsonl
  retention_days: 90
  pii_redaction: true
  correlation_id: true
  fields:
    - timestamp
    - correlation_id
    - agent
    - action
    - result
    - pii_redacted
```

### Storage Estimates

- ~10,000 records/day produces ~15 MB/day of JSONL data
- At 90-day retention: ~1.4 GB total storage
- For high-volume deployments, consider daily file rotation (`audit-YYYY-MM-DD.jsonl`) and gzip compression for archived logs
- Retention is configurable: 30 days for low-volume SMB, 90 days default, 365+ days for regulated industries (HIPAA requires 6 years minimum)

### Log Rotation

When `retention_days` is exceeded, archived logs are deleted automatically at the start of each agent session. The agent checks log file dates and removes files older than the configured retention period.

## Rate Limiting Governance

Rate limiting prevents runaway API costs and denial-of-wallet attacks. This pattern implements a layered approach: global defaults in `governance.yaml` and per-agent overrides in `agent.yaml`.

### governance.yaml rate_limits Block Template

```yaml
rate_limits:
  global:
    max_cost_usd_daily: 50
    max_api_calls_hourly: 500
    max_tokens_per_session: 100000
  agents:
    invoice-collector:
      max_calls: 100
      period: 1h
      max_cost_usd_daily: 15
    report-sender:
      max_calls: 20
      period: 1h
      max_cost_usd_daily: 5
```

### Enforcement

1. **Session start check:** Agent reads `governance.yaml` rate_limits at session start. If the global daily limit is already reached, the agent logs `rate_limit_exceeded` and exits immediately
2. **Per-call check:** Before each tool call, the agent checks its per-agent limits via cron interval spacing. If the per-agent hourly call limit is reached, the agent waits until the next period
3. **Cost tracking:** Each agent session appends its estimated cost to `.agentbloc/state/cost-tracker.json`

### Denial-of-Wallet Protection

| Threshold | Action |
|-----------|--------|
| 80% of daily cost budget | Agent sends a Telegram warning to the operations thread |
| 100% of daily cost budget | Agent halts execution and sends a Telegram alert |
| Global daily limit reached | All agents halt; P1 alert sent via Telegram |

### Override Priority

Per-agent limits in `agent.yaml` override `governance.yaml` agent-specific entries. Global limits cannot be overridden by individual agents.

## Quick Reference

| Topic | Key Rule | Template Location |
|-------|----------|-------------------|
| Log format | JSONL, one JSON object per line, append-only | `governance.yaml` audit block |
| Correlation ID | `sess-{agent}-{NNN}`, sub-agents append `-sub-{NNN}` | Generated at session start |
| PII redaction | Replace with `[REDACTED:{type}]` or `hash:{8-char-sha256}` | Applied before log write |
| Retention | Default 90 days, configurable in governance.yaml | `audit.retention_days` |
| Rate limits (global) | $50/day, 500 calls/hour, 100K tokens/session defaults | `rate_limits.global` |
| Rate limits (per-agent) | Override in governance.yaml agents section or agent.yaml | `rate_limits.agents.{name}` |
| Denial-of-wallet | Warning at 80%, halt at 100% of daily budget | Telegram alert |
| Never log | API keys, tokens, passwords, credentials | Omit entirely |
