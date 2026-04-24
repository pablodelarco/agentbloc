# n8n Integration Contract

> Phase 13 runtime reference. Every n8n webhook that wakes an AgentBloc agent conforms to the 4-field JSON envelope defined here. The envelope is the routing contract at the ClaudeClaw-boundary layer; event semantics are preserved inside the nested payload. Runtime-agnostic fallback (HTTP listener + claude -p) is documented for plain-Claude-Code deployments without ClaudeClaw.

## Table of Contents

- [When This Applies](#when-this-applies)
- [Envelope Schema (D-74)](#envelope-schema-d-74)
- [Bounded Enum: trigger.source](#bounded-enum-triggersource)
- [Worked Example 1: Gmail filter -> Gestor Documental](#worked-example-1-gmail-filter---gestor-documental)
- [Worked Example 2: Plaid webhook -> Gestor Cobros](#worked-example-2-plaid-webhook---gestor-cobros)
- [Worked Example 3: Web form submit -> Recepcionista](#worked-example-3-web-form-submit---recepcionista)
- [Worked Example 4: Google Calendar watch -> Agente Agenda](#worked-example-4-google-calendar-watch---agente-agenda)
- [Worked Example 5: Telegram message -> Recepcionista](#worked-example-5-telegram-message---recepcionista)
- [Runtime-Agnostic Fallback](#runtime-agnostic-fallback)
- [Route File Format (.json, per RESEARCH amendment)](#route-file-format-json-per-research-amendment)
- [Cross-References](#cross-references)

## When This Applies

Phase 13 runtime-engine subagent (`.claude/agents/runtime-engine.md`) loads this file in its forked context on invocation. The contract runs every time an agent's triggers[] array in agent-profiles.yaml contains a trigger.type of `event` (webhook). Phase 13 emits one n8n route .json stub per (agent, event-source, event-name) tuple at `.agentbloc/runtime/n8n-routes/<agent-id>.json`. The user installs these stubs into their n8n instance manually; Phase 13 does NOT auto-push routes. Loaded UNCONDITIONALLY at Phase 5 entry per D-58 context-budget discipline.

## Envelope Schema (D-74)

```json
{
  "schema_version": 1,
  "correlation_id": "<trigger-source>-<UTC-Z>-<nonce6>",
  "agent_id": "<agent-id>",
  "trigger": {
    "source": "gmail | plaid | bbva | google-calendar | telegram | form | custom-<name>",
    "event_name": "<source-specific event name>",
    "received_at": "<ISO-8601 UTC>"
  },
  "payload": { /* event-source-specific body */ }
}
```

Four top-level fields are REQUIRED. `schema_version: 1` is an integer (matches D-22 three-tier obligation discipline). `correlation_id` conforms to the D-75 format (see `references/correlation-id.md`). `agent_id` is the routing key; n8n sets it based on the route's node configuration (one n8n webhook -> one agent by convention). `trigger.source` is a bounded enum (see Section 3). `payload` is event-source-specific; the schema is declared in the agent's n8n route .json file (Section 10).

## Bounded Enum: trigger.source

| trigger.source | Description | Example event_name |
|----------------|-------------|--------------------|
| `gmail` | Gmail filter fires on incoming email matching criteria | `new-invoice-email` |
| `plaid` | Plaid webhook on bank-account event | `payment-received` |
| `bbva` | BBVA banking API webhook | `transaction-posted` |
| `google-calendar` | Google Calendar watch on calendar changes | `calendar-change` |
| `telegram` | Telegram bot receives message | `tenant-message` |
| `form` | Web form submit via HTTP POST | `contact-form-submission` |
| `custom-<name>` | Any other integration; `<name>` is kebab-case slug | `custom-zoho-invoice-sent` |

## Worked Example 1: Gmail filter -> Gestor Documental

Envelope emitted by n8n into ClaudeClaw's job endpoint:
```json
{
  "schema_version": 1,
  "correlation_id": "webhook-gmail-20260424T091523Z-b8c41e",
  "agent_id": "gestor-documental",
  "trigger": {
    "source": "gmail",
    "event_name": "new-invoice-email",
    "received_at": "2026-04-24T09:15:23Z"
  },
  "payload": {
    "message_id": "<synthetic-uuid>",
    "from": "billing@supplier.example",
    "subject": "Invoice #INV-2026-00412",
    "attachment_ids": ["att-1"]
  }
}
```

Route .json at `.agentbloc/runtime/n8n-routes/gestor-documental.json` (emitted by Phase 13 runtime-engine):
```json
{
  "schema_version": 1,
  "agent_id": "gestor-documental",
  "trigger": {
    "source": "gmail",
    "event_name": "new-invoice-email"
  },
  "n8n_config": {
    "webhook_path": "/webhook/gestor-documental-invoice",
    "http_method": "POST",
    "filter": "subject CONTAINS 'Invoice'"
  },
  "payload_schema": {
    "message_id": "string",
    "from": "string (email)",
    "subject": "string",
    "attachment_ids": "array of strings"
  },
  "evidence": {
    "verified_at": null
  }
}
```

## Worked Example 2: Plaid webhook -> Gestor Cobros

Envelope:
```json
{
  "schema_version": 1,
  "correlation_id": "webhook-plaid-20260501T083012Z-e4a2c1",
  "agent_id": "gestor-cobros",
  "trigger": {
    "source": "plaid",
    "event_name": "payment-received",
    "received_at": "2026-05-01T08:30:12Z"
  },
  "payload": {
    "account_id": "acc_abc123",
    "amount": 850.00,
    "transaction_id": "txn_202605010830_xyz"
  }
}
```

Route .json at `.agentbloc/runtime/n8n-routes/gestor-cobros.json` declares `trigger.source: plaid`, `trigger.event_name: payment-received`, `n8n_config.webhook_path: /webhook/gestor-cobros-payment`, `payload_schema: {account_id: string, amount: number, transaction_id: string}`, `evidence.verified_at: null`.

## Worked Example 3: Web form submit -> Recepcionista

Envelope:
```json
{
  "schema_version": 1,
  "correlation_id": "webhook-form-20260504T104532Z-9b7d33",
  "agent_id": "recepcionista",
  "trigger": {
    "source": "form",
    "event_name": "contact-form-submission",
    "received_at": "2026-05-04T10:45:32Z"
  },
  "payload": {
    "form_data": {
      "name": "Juan Perez",
      "email": "juan@tenant.example",
      "message": "Pregunta sobre el contrato"
    },
    "submitted_at": "2026-05-04T10:45:30Z"
  }
}
```

Route .json declares `trigger.source: form`, `trigger.event_name: contact-form-submission`, `n8n_config.webhook_path: /webhook/recepcionista-contact`, `payload_schema: {form_data: object, submitted_at: string (ISO-8601)}`, `evidence.verified_at: null`.

## Worked Example 4: Google Calendar watch -> Agente Agenda

Envelope (Agente Agenda is an anticipated agent stubbed for Phase 15 continuity):
```json
{
  "schema_version": 1,
  "correlation_id": "webhook-google-calendar-20260505T140000Z-2f1a84",
  "agent_id": "agente-agenda",
  "trigger": { "source": "google-calendar", "event_name": "calendar-change", "received_at": "2026-05-05T14:00:00Z" },
  "payload": { "calendar_id": "primary", "event_id": "evt_20260505_xyz", "change_type": "created | updated | deleted" }
}
```

## Worked Example 5: Telegram message -> Recepcionista

Envelope:
```json
{
  "schema_version": 1,
  "correlation_id": "webhook-telegram-20260504T143212Z-c7d92a",
  "agent_id": "recepcionista",
  "trigger": {
    "source": "telegram",
    "event_name": "tenant-message",
    "received_at": "2026-05-04T14:32:12Z"
  },
  "payload": {
    "chat_id": 987654321,
    "sender": "@tenant_maria",
    "text": "Cuando vence mi contrato?"
  }
}
```

Note: Telegram is also the transport for the v1.0 SECR-05 kill-switch remote-trigger (/stop command); see `references/incident-response.md` for the separate agentbloc-stop route stub emitted by Phase 13 runtime-engine (distinct from this per-agent wake route).

## Runtime-Agnostic Fallback

When ClaudeClaw is not the runtime substrate (plain Claude Code + system cron + n8n), AgentBloc degrades gracefully to a file-based fallback. The n8n HTTP node POSTs the envelope to a local HTTP listener (options: `python -m http.server` wrapper, `claudeclaw webhook --port 8080`, or a small Bun server). The listener writes the envelope to `.agentbloc/runtime/inbox/<agent-id>/<correlation-id>.json`, then invokes `claude -p --payload-file <path> .agentbloc/agents/<agent-id>/wake-webhook.md` as a foreground subprocess. This preserves the envelope shape (agents consume the same fields) and the correlation-ID chain (env var + payload file); what changes is the wake invocation mechanism, not the contract.

Decision tree:
```
IF registry.runtime.coordination_preference.prefer == "claudeclaw":
  n8n -> ClaudeClaw job endpoint -> claude -p
ELSE IF registry.runtime.coordination_preference.fallback == "writeStateHandoff":
  n8n -> local HTTP listener -> file inbox -> claude -p --payload-file
ELSE:
  halt: no runtime configured
```

Cross-reference to `references/runtime-coordination.md` for the full writeStateHandoff semantics.

## Route File Format (.json, per RESEARCH amendment)

n8n route files ship at `.agentbloc/runtime/n8n-routes/<agent-id>.json`. The `.json` extension is chosen over `.yaml` because n8n's native export format is JSON, route files are machine-read and machine-compared by runtime-engine (JSON RFC 8785 canonicalization per D-60 is well-defined; YAML canonicalization is not), and the evidence.verified_at field is machine-updated when the user confirms a route is live. Schema is the inner object from the worked examples (schema_version + agent_id + trigger + n8n_config + payload_schema + evidence).

## Cross-References

- `references/correlation-id.md` , Section 2 for `envelope.correlation_id` format spec (D-75)
- `references/runtime-coordination.md` , Section 9 writeStateHandoff fallback semantics (D-76)
- `references/telegram-patterns.md` , Worked Example 5 Telegram transport conventions (thread-per-domain, notification tiers)
- `references/incident-response.md` , agentbloc-stop Telegram /stop route (distinct from wake routes; activates KILL_SWITCH)
- `references/scheduling.md` , cron scheduling alternative when no webhook source exists
