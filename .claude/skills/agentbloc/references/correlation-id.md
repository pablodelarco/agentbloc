# Correlation ID Format + Propagation

> Phase 13 runtime reference. Every trigger seeds a new correlation ID; the ID rides through SendMessage metadata, TeamCreate team metadata, JSON webhook payloads, env vars at claude -p invocation, and every downstream log line. A single user event is grep-traceable end-to-end via one correlation ID.

## Table of Contents

- [When This Applies](#when-this-applies)
- [Format Spec (D-75)](#format-spec-d-75)
- [Bounded Enum: trigger-source](#bounded-enum-trigger-source)
- [Propagation Channels (3 mechanisms)](#propagation-channels-3-mechanisms)
- [Child-ID Convention (inherited from audit-logging.md)](#child-id-convention-inherited-from-audit-loggingmd)
- [Grep Recipes](#grep-recipes)
- [Scalability + Math](#scalability--math)
- [Cross-References](#cross-references)

## When This Applies

Phase 13 runtime-engine subagent loads this file in its forked context on invocation. Phase 13 wake-job templates cite this file in Section 2 (Correlation-ID ingest) and Section 6 (State + log write) for format compliance. Phase 14 Monitor (MONITOR-01..06) will consume correlation IDs from the JSONL logs; this file is the single source of truth for the format. Loaded UNCONDITIONALLY at Phase 5 entry per D-58 context-budget discipline.

## Format Spec (D-75)

Format: `<trigger-source>-<UTC-Z-compact>-<nonce6>`

- `<trigger-source>`: bounded enum (see Section 3)
- `<UTC-Z-compact>`: ISO-8601 UTC with Z suffix, colons and dashes stripped (e.g., `20260424T091523Z`)
- `<nonce6>`: 6 hex chars from a cryptographic RNG at ID-generation time

Regex (verbatim):
```
^(cron|webhook-[a-z][a-z0-9-]*|telegram|inter|manual)-[0-9]{8}T[0-9]{6}Z-[a-f0-9]{6}(-sub-[0-9]{3})*$
```

5 examples (verbatim):
```
cron-20260424T090000Z-a3f21b
webhook-plaid-20260424T091523Z-b8c41e
webhook-telegram-20260424T092045Z-c7d92a
inter-20260424T093101Z-f0e82a
manual-20260424T094512Z-02db9c
```

## Bounded Enum: trigger-source

| trigger-source | When used | Example |
|----------------|-----------|---------|
| `cron` | System cron fires a scheduled agent wake | `cron-20260424T090000Z-a3f21b` |
| `webhook-<source>` | n8n webhook fires; `<source>` matches the n8n route trigger.source enum (gmail, plaid, bbva, google-calendar, telegram, form, custom-<name>) | `webhook-plaid-20260424T091523Z-b8c41e` |
| `telegram` | Short alias for `webhook-telegram` when the Telegram message path is used (either form is valid) | `telegram-20260424T092045Z-c7d92a` |
| `inter` | Agent-to-agent invocation via SendMessage | `inter-20260424T093101Z-f0e82a` |
| `manual` | `claude -p` invoked directly by the user without any trigger system | `manual-20260424T094512Z-02db9c` |

## Propagation Channels (3 mechanisms)

### Channel 1: Env var `AGENTBLOC_CORRELATION_ID`

The `claude -p` wrapper receives `AGENTBLOC_CORRELATION_ID=<id>` as an environment variable. Cron entries set it via `AGENTBLOC_CORRELATION_ID=$(agentbloc-gen-correlation cron)` where `agentbloc-gen-correlation` is a shell function that runtime-engine emits to `.agentbloc/runtime/helpers.sh`. The function:

```bash
agentbloc-gen-correlation() {
  local source="${1:-manual}"
  local ts=$(date -u +%Y%m%dT%H%M%SZ)
  local nonce=$(od -An -N3 -tx1 /dev/urandom | tr -d ' \n')
  echo "${source}-${ts}-${nonce}"
}
```

### Channel 2: JSON payload top-level field

For webhook triggers, n8n's Set node seeds `correlation_id` into the D-74 envelope (see `references/n8n-integration.md`). The envelope carries it as a top-level field; the agent's wake-job-webhook.md.tmpl reads it via `{{payload.correlation_id}}` during Section 2 correlation-ID ingest.

### Channel 3: SendMessage metadata

ClaudeClaw's `SendMessage` primitive carries a `metadata` field. `references/runtime-coordination.md` specifies `metadata.correlation_id` is MANDATORY for AgentBloc-generated SendMessage calls. The receiving agent's wake-job-inter.md.tmpl reads it via `{{message.metadata.correlation_id}}`. For writeStateHandoff fallback, the correlation_id rides in the inbox file's JSON body.

## Child-ID Convention (inherited from audit-logging.md)

When agent A spawns child B via SendMessage or sub-session, B's correlation ID is `<parent-id>-sub-<NNN>` where `NNN` is zero-padded to 3 digits. Supports up to 999 children per parent, which exceeds any realistic fan-out.

Examples:
```
Parent: webhook-telegram-20260424T143212Z-c7d92a
Child 1: webhook-telegram-20260424T143212Z-c7d92a-sub-001
Child 2: webhook-telegram-20260424T143212Z-c7d92a-sub-002
Grandchild: webhook-telegram-20260424T143212Z-c7d92a-sub-001-sub-001
```

Cross-reference `references/audit-logging.md` for the original `sess-<agent>-<NNN>` pattern this extends.

## Grep Recipes

Recipe 1 , Trace one user event end-to-end:
```bash
grep 'correlation_id":"webhook-plaid-20260424T091523Z-b8c41e' .agentbloc/logs/audit.jsonl
```

Recipe 2 , List all wakes for a given trigger source on a given day:
```bash
grep 'correlation_id":"webhook-plaid-20260424' .agentbloc/logs/audit.jsonl | jq -r '.agent_id' | sort -u
```

Recipe 3 , Team session outcome for a correlation ID:
```bash
grep '"correlation_id":"cron-20260424T090000Z-a3f21b"' .agentbloc/runtime/TEAM_SESSIONS.jsonl
```

Recipe 4 , All child IDs under a parent (for multi-agent fan-out inspection):
```bash
grep -E 'correlation_id":"webhook-telegram-20260424T143212Z-c7d92a(-sub-[0-9]{3})*"' .agentbloc/logs/audit.jsonl
```

Recipe 5 , Count wake events per agent per day (operational summary):
```bash
grep 'correlation_id":"(cron|webhook|inter)-20260424' .agentbloc/logs/audit.jsonl | jq -r '.agent_id' | sort | uniq -c
```

## Scalability + Math

Nonce space: 16^6 = 16,777,216 combinations per second per source. At v2.0 scale (3 to 30 agents; at most 1 wake per second per trigger), collision probability is negligible. The 6-hex length was chosen as the smallest power-of-2 hex count that guarantees grep-friendly fixed-width tokens while remaining shell-safe.

v2.5 SQLite migration note: When JSONL log scan becomes sluggish (roughly 1M entries, or 3 to 6 months of high-traffic runtime), `.agentbloc/logs/*.jsonl` will migrate to SQLite with correlation_id as the primary-key column. The format in this file remains stable across the migration; only storage changes. See `.planning/REQUIREMENTS.md` Deferred to v2.5+ "SQLite persistence for log search".

## Cross-References

- `references/audit-logging.md` , original `sess-<agent>-<NNN>` pattern this extends; child sub-ID convention inherited verbatim
- `references/n8n-integration.md` , envelope.correlation_id top-level field (D-74) seeded by n8n Set node
- `references/runtime-coordination.md` , SendMessage metadata.correlation_id contract (D-76); writeStateHandoff inbox file carries correlation_id in JSON body
- `references/incident-response.md` , halted-kill-switch log entries include correlation_id for forensic tracing
