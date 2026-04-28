# Workflow: unmatched-payment-alert

> Event-driven escalation. When `gestor-cobros` detects 3+ unmatched
> bank transactions in a single run, it wakes `recepcionista` via
> inter-agent inbox to alert Pablo in real-time.

## Trigger

| Type | Detail |
|---|---|
| `inter-agent` | Caller: `gestor-cobros` · Message: `unmatched-payment-alert` (3+ items threshold) |

## Inputs

| Name | Type | Source |
|---|---|---|
| Unmatched transactions | JSON envelope | `.agentbloc/agents/recepcionista/inbox/<correlation-id>.json` |
| Tenant registry | Google Sheet | `google-sheets-mcp` (resolved by recepcionista) |

## Outputs

| Name | Type | Sink |
|---|---|---|
| Real-time alert | Telegram message | Pablo's main thread (escalations_thread_id) |

## Agents involved

| Agent | Role |
|---|---|
| `recepcionista` | Composes + sends real-time alert with payload of 3+ unmatched items |

## Success criteria (falsifiable)

- Alert fires within 60 seconds of `gestor-cobros` writing the inbox envelope
- Alert message includes: count, transaction descriptions (PII-redacted),
  amounts, and a link to the matches.json file for human review
- Zero false positives — the 3-item threshold is exact, not fuzzy
- Recepcionista's L4 approval gate honored: alert is queued for Pablo's
  `/approve <correlation-id>` reply unless the threshold-firing wake
  was triggered with `pre_approved=true` flag (not used in v1)

## Failure modes

| Mode | Detection | Handling |
|---|---|---|
| recepcionista not awake at trigger | Inbox envelope sits unread | Next cron wake (23:00) consumes the inbox |
| Telegram delivery fails | sendMessage returns non-2xx | Retry 3x; on persistent failure, escalate to escalations_thread_id |
| Approval timeout | No `/approve` within 600s | Promote alert tier from `info` to `action_required`; re-ping operator (per `escalation.md`) |

## Topology

```
[gestor-cobros] ──unmatched ≥ 3?──yes──> [atomic_write_inbox to recepcionista]
                                                  │
                                              wake at 23:00 (or pre-empt if cron-soon)
                                                  ↓
                                          [recepcionista] ──L4 approval──> Telegram (Pablo)
```

## Cross-references

- Caller: [`gestor-cobros`](../agents/gestor-cobros/role.md)
- Receiver: [`recepcionista`](../agents/recepcionista/role.md)
- Approval gate: [`../governance/approval-protocol.md`](../governance/approval-protocol.md)
- Inter-agent primitive: `../runtime/reference-impl/helpers.sh` (`atomic_write_inbox`)
