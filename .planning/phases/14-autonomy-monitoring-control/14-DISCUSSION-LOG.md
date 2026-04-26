# Phase 14: Autonomy + Monitoring + Control Plane , Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in CONTEXT.md , this log preserves the alternatives considered.

**Date:** 2026-04-26
**Phase:** 14-autonomy-monitoring-control
**Mode:** `--auto` (Claude selected recommended defaults inline; no interactive AskUserQuestion calls)
**Areas discussed:** Autonomy enforcement layer, Approval router + thread separation, Escalation protocol, JSONL log schema + path convention, Briefing agent template, Task locking, Activity feed, Cost + token tracking, Status badges, Surgical edits to existing files

---

## Autonomy Enforcement Layer (D-84)

| Option | Description | Selected |
|--------|-------------|----------|
| A. Prose-only enforcement (no runtime hook) | Trust the deployed-agent-skill template prose; rely on model compliance | |
| B. Per-tool wrapper subagent that re-injects approval prompt | Each external tool wrapped by a subagent that pauses for approval | |
| C. PreToolUse hook + SKILL.md prose (defense in depth) | Runtime hook intercepts side-effect tool calls; SKILL.md prose informs model reasoning | ✓ |
| D. Approval-required-by-default whitelist | Block all tools by default; whitelist read-only ones | |

**[auto] Selected:** Option C , defense-in-depth pattern matches Phase 12 D-67 narrow-Bash + Phase 13 D-77 three-point kill-switch precedents. Prose-only relies on model compliance (no audit guarantee). Subagent-spawn pattern was already terminated by Phase 13 D-82 precedent. Whitelist breaks `full` autonomy semantics.

---

## Approval Router + Telegram Thread Separation (D-85)

| Option | Description | Selected |
|--------|-------------|----------|
| A. Inline approval in main briefing thread | All approvals + briefings in one thread | |
| B. Per-agent dedicated thread (one per agent) | Each agent gets its own approval thread | |
| C. Reply-by-reaction (👍/👎) instead of slash command | Telegram reactions trigger approve/deny | |
| D. Single `approvals` thread + slash command with correlation_id | All approvals in one dedicated thread; `/approve <correlation_id>` syntax | ✓ |

**[auto] Selected:** Option D , CTRL-01 mandates approval queue separation from briefing thread. Per-agent threads belong to v2.5 dashboard scope. Reactions are not Telegram-API-pollable as cleanly as message replies. Slash-command syntax with correlation_id disambiguator handles concurrent pending approvals.

---

## Escalation Protocol (D-86)

| Option | Description | Selected |
|--------|-------------|----------|
| A. Escalations to same thread as briefing | Mix daily summary with crisis interruptions | |
| B. Escalations to same thread as approvals | Conflate "needs decision" with "system broken" | |
| C. Dedicated `escalations` thread + persistent halt | Separate thread; agent halts (status=error) until /resume reply | ✓ |
| D. Auto-retry with exponential backoff before escalation | Try N times before escalating | |

**[auto] Selected:** Option C , semantic separation between "needs decision" (approvals) and "system broken" (escalations) is critical for human triage. Persistent halt is safer default; auto-retry deferred to v2.5.

---

## JSONL Log Schema + Path Convention (D-87)

| Option | Description | Selected |
|--------|-------------|----------|
| A. Single team log file per day (all agents merged) | One file per team per day; concurrent writers interleave | |
| B. One file per agent per WEEK | Weekly file; smaller file count | |
| C. SQLite single DB per team | Database instead of files | |
| D. JSONL per-agent-per-day at REQUIREMENTS path | `.claude/agents/logs/<YYYY-MM-DD>/<agent-id>.jsonl` per REQUIREMENTS.md MONITOR-02 literal | ✓ |

**[auto] Selected:** Option D , per-agent files are append-safe via O_APPEND (avoids interleave on concurrent wakes). Daily boundary matches briefing cadence. SQLite deferred to v2.5 web dashboard scope. REQUIREMENTS path is canonical per D-59 triple-override precedent.

---

## Briefing Agent Template (D-88)

| Option | Description | Selected |
|--------|-------------|----------|
| A. Briefing as orchestrator subagent (AgentBloc-internal) | Briefing implemented as `.claude/agents/briefing-engine.md` | |
| B. Briefing in Python script using LangChain | External Python dependency | |
| C. Briefing as deployed agent + briefing-renderer.sh pluggable presentation | Briefing is itself a deployed agent (Phase 12 templates) using briefing-agent.md.tmpl; renderer script handles presentation per MONITOR-06 | ✓ |
| D. No briefing , agents post directly | Each agent writes its own Telegram updates | |

**[auto] Selected:** Option C , symmetry with how all other agents are deployed (single set of templates + deploy-engine path). User can edit briefing prose without touching skill internals. Pluggable renderer satisfies MONITOR-06 without forcing v2.5/v3.0 work into v2.0.

---

## Task Locking (D-89)

| Option | Description | Selected |
|--------|-------------|----------|
| A. In-memory lock (per-process) | No shared state across `claude -p` processes | |
| B. SQLite lock | Database-backed; adds dependency | |
| C. flock + JSON lock file with expiry | POSIX-standard atomic lock + JSON file with `acquired_at`+`expires_at` | ✓ |
| D. Optimistic locking (compare-and-swap on resource state) | Per-resource versioning logic in every agent | |

**[auto] Selected:** Option C , v1.0 file-based-state decision applies. flock is POSIX-standard, atomic, zero-dependency. Per-host scope acceptable for v2.0 (multi-host = v2.5).

---

## Activity Feed (D-90)

| Option | Description | Selected |
|--------|-------------|----------|
| A. Real-time merge (every log write triggers feed update) | Race conditions on concurrent writers | |
| B. Hourly merge | Cost overhead for debugging tool | |
| C. Daily merge at briefing time | Briefing-agent triggers `activity-feed-merge.sh` once per day | ✓ |

**[auto] Selected:** Option C , aligns merge cadence with briefing schedule. No race conditions (single writer, batch operation). Idempotent re-runs safe.

---

## Cost + Token Tracking (D-91)

| Option | Description | Selected |
|--------|-------------|----------|
| A. Cost tracked separately (not in log entries) | Decouples cost from action; harder attribution | |
| B. Per-tick cost as last-run.json field | Point-in-time only; aggregation requires log line trail anyway | |
| C. Per-log-line `cost_usd` + `token_count` | Each log line carries its own cost + token breakdown; briefing sums | ✓ |

**[auto] Selected:** Option C , attribution-friendly (cost is bound to the action that incurred it). Briefing aggregation is trivial sum operation. Subscription mode still computes notional cost for budgeting parity.

---

## Surgical Edits to Existing References (D-93..D-98)

All Plan 14-03 surgical edits follow Phase 13 D-83 surgical insertion-point discipline:

| Target | Edit | Pattern |
|--------|------|---------|
| SKILL.md | 4 new See-lines + monitor_wired sub-gate + Phase 6 precondition | Phase 13 D-81 precedent |
| deployed-agent-skill-{full,semi,supervised}.md.tmpl | Per-template "Side-effect Approval Routing" paragraph | Surgical insertion only |
| phase-5-deployment.md | Step 7.6 Monitor Wiring Hand-off (mirrors Phase 13 Step 7.5) | Phase 13 D-83 precedent |
| incident-response.md | Escalation Protocol H2 section (after Runtime Kill-Switch Semantics) | Phase 13 D-77 insertion precedent |
| audit-logging.md | Surgical correlation-ID format alignment with D-75 | Drift removal |
| agent-memory-schema.md | last-run.json adds `cost_usd` + `token_count` (schema_version bumps to 2) | Backward-compatible extension |

**[auto] Selected:** All 6 surgical edits per pattern; no rewrites of upstream content; only insertions. Atomic commits per surgical edit.

---

## Claude's Discretion

The following decisions deferred to plan-time (gsd-planner per Phase 13 precedent):

- Exact line counts per emitted reference (planner sets per-task budgets)
- Order of plan tasks within Plan 14-01 / 14-02 / 14-03 (planner sequences atomically)
- Specific Arco Rooms fixture line counts (planner computes from schema + samples)
- Whether `claude-wrap.sh` ships as separate Phase 14 artifact or folds into runtime-engine extension (planner picks per Phase 13 helpers.sh precedent)

---

## Deferred Ideas

Captured in CONTEXT.md `<deferred>` section:

- Per-agent dedicated approval threads (v2.5 web dashboard)
- Auto-retry with exponential backoff before escalation (v2.5)
- Real-time activity-feed merge (v2.5 streaming dashboard)
- Team-lead aggregation mid-tier between agents and briefing (v2.5)
- Multi-host coordination / locks across machines (v2.5)
- SQLite for logs (v2.5)
- Briefing markdown rendering for management UI (v3.0)
- Cost forecast / budget alerts (v2.5)
- Approval-by-reaction emoji (rejected for v2.0; slash-command is the contract)

---

*Auto-mode discussion log generated 2026-04-26.*
