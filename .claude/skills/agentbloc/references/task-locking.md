# Task Locking (Phase 14)

> Phase 14 reference. CTRL-03 file+flock locking for shared resources (bank accounts, tenant records, calendar slots). POSIX flock(1) atomicity; per-host scope; multi-host coordination is v2.5 scope.

## Table of Contents

- [When This Applies](#when-this-applies)
- [Lock File Schema](#lock-file-schema)
- [Acquire / Release Pseudocode](#acquire--release-pseudocode)
- [Resource-Slug Grammar](#resource-slug-grammar)
- [deferred-locked Wake Outcome](#deferred-locked-wake-outcome)
- [Cross-References](#cross-references)

## When This Applies

Any agent working on a shared resource declared in `registry.yaml monitor.locked_resources`. Lock acquisition happens in section 4 (Input parse) of wake-job templates per Phase 13 D-73. Release happens in section 6 (State + log write). Loaded by deploy-engine when emitting per-agent SKILL.md prose.

## Lock File Schema

JSON content at `.agentbloc/locks/<resource-slug>.lock`:

```json
{
  "agent_id": "gestor-cobros",
  "correlation_id": "cron-20260501T080000Z-a3f21b",
  "acquired_at": "2026-05-01T08:00:01.234Z",
  "expires_at": "2026-05-01T08:30:01.234Z"
}
```

| Field | Type | Description |
|-------|------|-------------|
| `agent_id` | string | Agent currently holding the lock |
| `correlation_id` | string | D-75 correlation ID of the wake that acquired |
| `acquired_at` | string (ISO 8601) | When acquired, ms-precision UTC Z |
| `expires_at` | string (ISO 8601) | When the lock auto-expires; default acquired_at + 30 minutes |

## Acquire / Release Pseudocode

```bash
LOCK_FILE=".agentbloc/locks/${RESOURCE_SLUG}.lock"
mkdir -p "$(dirname "$LOCK_FILE")"

# Atomic acquire via flock
exec 200>"$LOCK_FILE"
if flock -n 200; then
  # Check if existing content (from prior holder) has expired
  EXISTING=$(cat "$LOCK_FILE" 2>/dev/null)
  if [ -n "$EXISTING" ]; then
    EXPIRES=$(echo "$EXISTING" | jq -r '.expires_at // ""')
    NOW=$(date -u +%Y-%m-%dT%H:%M:%S.000Z)
    if [ -n "$EXPIRES" ] && [ "$NOW" \< "$EXPIRES" ]; then
      flock -u 200; exec 200>&-
      WAKE_OUTCOME="deferred-locked"; exit 0
    fi
  fi
  # Write our content
  echo "{\"agent_id\":\"$AGENT_ID\",\"correlation_id\":\"$CORRELATION_ID\",\"acquired_at\":\"$NOW\",\"expires_at\":\"$EXPIRES_AT\"}" > "$LOCK_FILE"
  flock -u 200
  # ... do work ...
  # Release
  echo "null" > "$LOCK_FILE"
fi
```

**Refresh during long-running work:** if work might exceed `expires_at`, the agent updates `expires_at` mid-operation by re-acquiring + writing a new content. Documented agent-author concern.

## Resource-Slug Grammar

kebab-case, domain-scoped:
- `bank-bbva-es76-1234` (bank account by IBAN-suffix)
- `tenant-arco-rooms-apartment-3a` (tenant lock for property unit)
- `calendar-google-pablo-monday-9am` (calendar slot)
- `invoice-supplier-2026-04-001` (invoice processing lock)

Slugs derived deterministically from `registry.yaml monitor.locked_resources` declarations + the entity-id from the agent's `working_state` field. The deterministic derivation prevents drift between concurrent acquirers.

## deferred-locked Wake Outcome

When acquire fails (existing lock not expired), the agent writes JSONL with `result: skipped, details: {reason: "locked_by-other-agent", locked_by: "<existing agent_id>"}` + sets `wake_outcome: deferred-locked` + exits without further work. NO escalation: locks are normal contention.

The next cron/webhook fire retries; if the lock still held, defers again. If lock holder fails to release before `expires_at`, the next wake force-acquires + proceeds. This avoids deadlocks when an agent crashes between acquire and release.

## Cross-References

- [jsonl-log-schema.md](jsonl-log-schema.md) , `locked_by` field semantics
- [agent-memory-schema.md](agent-memory-schema.md) , `working_state` used to derive resource-slug
- runtime-coordination.md , Phase 13 wake-job section 4 timing for acquisition
