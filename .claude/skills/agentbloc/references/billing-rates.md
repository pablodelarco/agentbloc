# Billing Rates (Phase 14)

> Phase 14 reference. Static rate table for Claude API tokens as of v2.0 ship date (April 2026). Consumed by `.agentbloc/runtime/claude-wrap.sh` to compute per-call `cost_usd`. Update when API pricing changes.

## Table of Contents

- [When This Applies](#when-this-applies)
- [Rates Table](#rates-table)
- [claude-wrap.sh Consumer Contract](#claude-wrapsh-consumer-contract)
- [Subscription Mode Note](#subscription-mode-note)
- [Cross-References](#cross-references)

## When This Applies

Every deployed agent's cron entry runs through the `claude-wrap.sh` wrapper that intercepts Claude API token usage from the response trailer + computes `cost_usd` via this rate table. Loaded by runtime-engine when emitting `claude-wrap.sh`.

## Rates Table

USD per million tokens (April 2026 published rates):

| Model | Input | Output | Cached Input |
|-------|-------|--------|--------------|
| Opus 4.7 (`claude-opus-4-7`) | $15.00 | $75.00 | $1.50 |
| Sonnet 4.6 (`claude-sonnet-4-6`) | $3.00 | $15.00 | $0.30 |
| Haiku 4.5 (`claude-haiku-4-5-20251001`) | $0.80 | $4.00 | $0.08 |

> Verify against the Anthropic pricing page before relying on these numbers in production. Update this file when rates change. The wrapper script reads this table line-by-line; preserve the column order.

## claude-wrap.sh Consumer Contract

**Input:** `claude -p ...` invocation forwarded verbatim. The wrapper inspects the Claude API response trailer for `usage: {input_tokens, output_tokens, cache_read_input_tokens}` per call.
**Behavior:** lookup rate by model name (from `--model` flag or `ANTHROPIC_MODEL` env var; defaults to Sonnet 4.6 per CLAUDE.md project guidance) -> compute `cost_usd = (input * input_rate + output * output_rate + cached_input * cached_input_rate) / 1_000_000`.
**Output:** annotated JSONL log line with `cost_usd` + `token_count: {input, output, cached_input}` fields populated; appended to the agent's per-day log file per `references/jsonl-log-schema.md`.
**Side effects:** appends to `last-run.json` rolling totals per Phase 14 D-98 schema_version=2 extension to `agent-memory-schema.md`.

## Subscription Mode Note

When `governance.yaml billing.mode = max_subscription`, `cost_usd` is still computed AS IF the call were billed via API key. The briefing-agent annotates the daily summary with footer "(included in Claude Max subscription)" so the user has a comparable number for budgeting an eventual API-key migration. The notional cost figure is also useful for cross-deployment comparison + future cost-forecast features (v2.5 scope).

## Cross-References

- [jsonl-log-schema.md](jsonl-log-schema.md) , `cost_usd` + `token_count` field semantics
- [agent-memory-schema.md](agent-memory-schema.md) , `last-run.json` rolling totals per D-98 (Phase 14 schema_version=2)
