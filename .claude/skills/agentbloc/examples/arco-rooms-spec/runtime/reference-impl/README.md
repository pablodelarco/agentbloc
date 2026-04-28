# Reference Implementation — Bash + cron + Telegram

> **Read first:** This folder is **advisory reference implementation**, not a
> deliverable in itself. AgentBloc emits this folder *into your project* as one
> of several runtime options. Your AI coding session (Claude Code, Codex,
> Gemini, Cursor, OpenClaw) decides whether to use it as-is, adapt it, or pick
> a different runtime entirely (see `../alternatives.md`).

## What this is

A complete, working substrate for running an AgentBloc-designed agent team on
the simplest possible stack: bash scripts + system cron + curl-to-Telegram +
file-based inbox handoff. Zero new dependencies beyond what every Claude Code
install already has (claude, jq, curl, python3 for YAML parsing).

This substrate was built as v2.5 of AgentBloc and battle-tested through 12
atomic commits before the v3.0 pivot to a spec-engine model. Rather than throw
the work away, AgentBloc v3.0 emits it as **reference patterns** an
implementation session can copy from when building the user's runtime.

## What it implements

| Concern | File |
|---|---|
| Atomic file primitives + correlation-IDs + PII redaction | `helpers.sh` |
| Cron entry point per agent | `wake.sh` |
| `claude -p` invoker with cost capture + timeout | `claude-wrap.sh` |
| Telegram outbound (retries + dedup + MOCK mode) | `telegram-send.sh` |
| Telegram inbound (short-poll + portable lock + idempotent offset) | `telegram-poll.sh` |
| `/approve` + `/reject` parser → `approvals.jsonl` | `approval-router.sh` |
| Approval-timeout watchdog (escalation) | `escalation-router.sh` |
| Cron manifest generator from `agent-profiles.yaml` | `cron-generator.sh` |
| `AGENTBLOC_NO_CRON=1` foreground substitute (macOS FDA fallback) | `loop.sh` |
| Daily merge of per-domain logs into `activity-feed.jsonl` | `activity-feed-merge.sh` |
| PreToolUse blast-radius blocker | `hooks/autonomy-gate.sh` |
| Tunable env template | `.env.example` |

Each script has a self-contained header comment explaining its contract,
exit codes, and tunables. Read each one's header before adapting.

## How to use this from a build session

If your AI coding session decides to use this reference impl as the runtime:

1. Copy this entire folder to `<project-root>/scripts/` (and `hooks/`).
2. Adapt absolute paths in `wake.sh`, `claude-wrap.sh`, etc., to the user's
   actual repo layout.
3. Run `cp .env.example .env` and fill in `TELEGRAM_BOT_TOKEN`,
   `ANTHROPIC_API_KEY`, etc.
4. Run `./scripts/cron-generator.sh apply` to install the crontab manifest
   from the user's `agent-profiles.yaml`. (Or set `AGENTBLOC_NO_CRON=1` and
   use `./scripts/loop.sh` for foreground operation.)

If your session decides on a different runtime (n8n, Temporal, Pipedream,
Inngest, plain Python), this folder is still useful as a **specification**:
each script's header documents the contract that runtime needs to fulfill.

## Architectural notes

- **Inbox-handoff** (replaces ClaudeClaw `TeamCreate`/`SendMessage` from v2.0):
  agents communicate via `.agentbloc/agents/<recipient>/inbox/` directories.
  Atomic mv-rename = ownership claim. See `helpers.sh` `atomic_write_inbox`.
- **Three-point kill switch**: team-wide `KILL_SWITCH` file + per-agent
  `pause` file + cooperative tool-level PreToolUse hook block.
- **Cost capture**: `claude -p --output-format json` emits `total_cost_usd`
  per invocation; `claude-wrap.sh` extracts via jq into `cost.jsonl`.
- **Portable locking**: macOS lacks `flock(1)` without brew install, so
  scripts use POSIX `mkdir` atomicity for non-blocking lock semantics.

## Alternatives

If your team has different operational constraints, see `../alternatives.md`
for runtimes worth considering: n8n (visual workflows), Temporal (durable
execution), Pipedream/Inngest (managed event-driven), plain Python +
APScheduler, or a custom solution.

## Provenance

Files in this folder were authored on the `v2.5-runtime` branch of the
agentbloc repo, then cherry-picked into v3.0 as reference impl. Commit
history for each file is preserved on that branch for forensic reference.
