# Escalation — gestor-cobros

## Escalation triggers

1. **Uncaught exception** during wake (network, parsing, etc.)
2. **Critical-action failure**: bank PSD2 401 (token expired or
   user revoked Plaid Item access); Google Sheets registry unreachable
   AND no cached copy
3. **Approval timeout**: N/A in v1 — no L3+ tools currently invoked
4. **Explicit `escalate(...)`**: matching quality degraded (mean
   confidence < 0.5 for 3+ consecutive runs) — Pablo should
   investigate registry drift or bank format changes

## Escalation message format

```
🚨 ESCALATION — gestor-cobros
Correlation: <correlation-id>

What I tried: Listed transactions across 4 banks for matching against
<N> invoices from gestor-documental.

Why it failed: <root cause, e.g.:>
- BBVA bank-mcp returned 401 ITEM_LOGIN_REQUIRED (PSD2 consent expired
  after 90 days)
- Google Sheets tenant registry unreachable (504 gateway timeout) AND
  cache stale > 24h

Options:
1. Re-authorize PSD2 consent via BBVA portal (requires user browser
   session)
2. Skip BBVA this run; resume tomorrow at 22:30
3. Switch to manual transaction CSV upload for 1 day

Recommended: Option 1 (re-authorize); BBVA is the most-active account
and skipping risks 24h of unmatched payments.

Reply: /resume <correlation-id> reauthorized | /halt <correlation-id>
```

## Persistent halt

Same as gestor-documental: `last-run.json status=error` halts next
22:30 wake until `/resume <correlation-id>` lands.

If `/resume` lands with extra context (e.g., `/resume <cid>
reauthorized`), the next wake reads that text from memory.md Open
Items and acts on it.

## /resume + /halt grammar

Standard per `governance/approval-protocol.md`. `/resume <correlation-id>
[free-text]` clears the halt; `/halt <correlation-id>` confirms
persistent halt for a longer interval.

## Escalation target

`escalations_thread_id` (env). Fallback: `TELEGRAM_CHAT_ID`.

## Cross-references

- [`../../governance/approval-protocol.md`](../../governance/approval-protocol.md)
- [`../../governance/kill-switch.md`](../../governance/kill-switch.md)
- [`../../runtime/reference-impl/escalation-router.sh`](../../runtime/reference-impl/escalation-router.sh)
