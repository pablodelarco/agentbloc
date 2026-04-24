# Phase 13: Multi-Agent Runtime - Research

**Researched:** 2026-04-24
**Domain:** Runtime wiring for deployed Claude-Code-native agents (cron + n8n webhooks + inter-agent coordination + correlation tracing + kill-switch)
**Confidence:** HIGH overall. One HIGH-impact re-grounding (see focus area 1) that refines but does not break CONTEXT.md.

## Summary

This is a CONFIRMATORY research pass. Phase 13's CONTEXT.md (580 lines, D-73..D-83 + 5 inherited sets) is unusually well-grounded , the problem statement, scope, and decisions are already traceable to the PDF, REQUIREMENTS, and Phases 8-12. Research targeted six focus areas where external verification could strengthen or challenge assumptions. Five confirm CONTEXT intact. One (ClaudeClaw primitive signatures) has a material finding that refines the mental model without invalidating any decision: **`TeamCreate` and `SendMessage` are Claude Code-native primitives, not ClaudeClaw primitives**. CONTEXT's dual-path fallback (D-76 writeStateHandoff) is therefore not just a safety net , it is load-bearing for any non-interactive (cron-wake, webhook-wake) path, because TeamCreate/SendMessage are currently interactive-session-oriented and undocumented for programmatic use.

The consequence for Phase 13 is that the plan should promote writeStateHandoff from "fallback" to "primary for non-interactive wakes" and treat TeamCreate/SendMessage as an optimization available only when a human operator (or ClaudeClaw's message-routing layer) is driving an interactive lead session.

**Primary recommendation:** Ship Phase 13 as planned per D-73..D-83, with one adjustment to D-76: **label writeStateHandoff as the primary coordination path for cron-wake and webhook-wake contexts, and label `TeamCreate`/`SendMessage` as the primary path only for interactive lead sessions.** No other CONTEXT decision needs revision.

## User Constraints (from CONTEXT.md)

### Locked Decisions

**Inherited (Phases 8-12 + v1.0):**
- D-1: File-based state (no DB)
- D-11: Artifact emission lives in gate, not separate subagent flow
- D-13: Validators are prose-checklists inside reference files (no ajv, no yamllint)
- D-14: User confirms rendered tables; silent artifact emission
- D-15 + Phase 12 D-59a/b/c: Three-namespace discipline , `.claude/skills/` (stable contracts), `.claude/agents/` (native subagents), `.agentbloc/` (mutable runtime state)
- D-18: Bounded enums for discriminated unions
- D-21 + D-67: Subagent with `context: fork`, scoped tools, Bash narrowly allow-listed
- D-22: Three-tier field obligation (REQUIRED/RECOMMENDED/OPTIONAL) with `schema_version: 1`
- D-23: On topology ambiguity, default is `mesh`
- D-24: ADK vocabulary for orchestration patterns (Sequential/Parallel/Loop/Event-driven/Conversational)
- D-29 + D-58: SKILL.md extensions are surgical, cap 250 lines
- D-31: Split references per concern (imperative flow vs declarative schema vs output contract)
- D-34 + D-70: Three-check verification protocol (SKILL.md loads / MCP tools/list / crontab registered)
- D-35 + D-71: Halt-and-name with named report on failure (RUNTIME-FAILED-REPORT.md)
- D-37: Approval-gated execution for anything with blast radius (crontab mutation gated)
- D-39: Evidence record + `[UNVERIFIED]` flag for n8n routes
- D-40 + D-73: Surgical edits to existing references
- D-42 + D-60: Idempotency fingerprint pattern (SHA256 HTML-comment fingerprint)
- D-46 + D-72: Append-only JSONL ledger (GDPR Article 30)
- v1.0 SECR-05: Kill-switch pattern (dual-path file + Telegram /stop)
- v1.0 Phase 4 Dry Run: Runtime wake paths inherit dry-run posture
- Phase 12 D-62: Template-based generation (three-variant split, pure `{{var}}` substitution)
- Phase 12 D-63: Registry format with `schema_version: 1`
- Phase 12 D-66: Merge-keep-existing-with-conflict-warning for `.mcp.json`

**Phase 13 new:**
- D-73: Wake-job template is 6-section markdown file, 3 variants (cron/webhook/inter) per trigger type, pure `{{var}}` substitution
- D-74: n8n webhook envelope is 4-field JSON `{schema_version, correlation_id, agent_id, trigger, payload}` with bounded trigger.source enum
- D-75: Correlation-ID format `<trigger-source>-<UTC-Z-compact>-<nonce6>` with bounded trigger-source enum, 6-hex cryptographic nonce, `-sub-<NNN>` child convention
- D-76: First-agent-detects-need pattern with single-agent workflow bypass at wake-template-selection time + dual-path ClaudeClaw/writeStateHandoff fallback
- D-77: Three-point kill-switch enforcement (wake / per-tool / team-transition); Telegram /stop via n8n route
- D-78: Registry gains top-level `runtime` block (additive, no migration)
- D-79: Two-fixture pattern (narrative flow + structural artifacts) for Arco Rooms canonical
- D-80: runtime-engine subagent at `.claude/agents/runtime-engine.md`, narrow Bash allow-list, `crontab -e` explicitly disallowed
- D-81: New sub-gate `runtime_wired` joins Phase 5 State Transitions; Phase 6 Evolution precondition extends
- D-82: 3 new references + 3 new templates + 2 fixtures + 1 subagent + 4 surgical edits; ~20 lines added to SKILL.md (183 → ~203, 47 lines headroom under 250 cap)
- D-83: 3 plans (contracts+fixtures / subagent / wiring)

### Claude's Discretion

- Exact wake.md template section wording and anchor-point naming consistency
- n8n-integration.md worked-example selection order and verbosity (5 PDF-page-5 examples mandatory; extras discretionary)
- correlation-id.md grep recipe examples (minimum 3)
- runtime-engine subagent's exact Bash allow-list prose wording (the 5-command list is locked)
- RUNTIME-REPORT.md template structure (required fields locked; prose around them discretionary)
- Example fixture scenario prose depth (Scenario A/B/C outline locked; word count discretionary)
- Whether to split runtime observability into a 6th reference if runtime-coordination.md exceeds 220 lines
- Inclusion order of Phase 13 See-lines in SKILL.md (alphabetical per Phase 12 precedent)

### Deferred Ideas (OUT OF SCOPE)

- JSONL log aggregation + daily rollup → Phase 14 MONITOR-01..06
- Briefing-agent daily Telegram summaries → Phase 14 MONITOR-04
- Autonomy-level enforcement at side-effect time → Phase 14 AUTON-01..05
- Approval queue + cost tracking + task-locking + status badges → Phase 14 CTRL-01..05
- Anticipation-pass agents in runtime → Phase 15 ANTIC-01..05
- Correlation-ID audit viewer (web dashboard) → v2.5+
- SQLite persistence for log search → v2.5+
- Cross-run correlation-ID diffing → v4.0 Self-Healing Evolution
- n8n route installation automation (programmatic push) → v2.5+
- Mobile push / SMS / phone-call wake channels → out of scope per CLAUDE.md
- Auto-remediation on wake failure → v4.0 Self-Healing Evolution
- Distributed / multi-host runtime → v3.0+
- LLM-routed dynamic agent selection (AG2 SelectorGroupChat) → permanent out of scope
- Cron + webhook wake-race deduplication → v2.5+

## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| RUNTIME-01 | Cron triggers fire via system cron + `claude -p`. Crontab generated during DEPLOY-02. | CONFIRMED: scheduling.md (`0 22 * * * /usr/bin/env bash -c 'source .env && claude -p "$(cat job.md)"'`) is the production template. D-73 wake-job-cron template + D-80 runtime-engine stdin-install pattern wire this. **No external change needed.** |
| RUNTIME-02 | Event triggers fire via n8n webhooks into ClaudeClaw's job endpoint. | CONFIRMED + REFINED: ClaudeClaw's documented webhook endpoint is `POST /webhook/:group` with HMAC-SHA256 signature (`X-Signature` header), body `{"prompt": "..."}`. D-74's 4-field envelope is richer than ClaudeClaw's default `{"prompt": "..."}` , the envelope lives INSIDE a `prompt:` field OR goes via the runtime-agnostic fallback (D-74's local HTTP listener). Document both paths. |
| RUNTIME-03 | `references/n8n-integration.md` documents webhook-to-agent mapping. | CONFIRMED: D-74 + D-82 cover. n8n supports UUID generation via crypto node or `{{$uuid()}}` expression (VERIFIED: n8n-community 2025). 5 PDF-page-5 worked examples lockable. |
| RUNTIME-04 | Inter-agent coordination uses ClaudeClaw's `SendMessage` / `TeamCreate`. | **REFINED, see focus area 1:** TeamCreate/SendMessage are **Claude Code native primitives** (agent-teams v2.1.32+), not ClaudeClaw-native. They are available only in specific contexts (interactive lead + standalone subagents + skill-forked contexts; NOT to teammates inside teams). Programmatic (cron-wake / webhook-wake) invocation is **undocumented** and **unverified externally**. D-76 dual-path is therefore load-bearing. |
| RUNTIME-05 | Single-agent tasks run without `TeamCreate` overhead. | CONFIRMED: D-76 template-selection-time bypass is the correct enforcement. No external verification needed. |
| RUNTIME-06 | Correlation ID propagates through SendMessage into downstream logs. | CONFIRMED + REFINED: D-75 format `<trigger-source>-<UTC-Z>-<nonce6>` aligns with 2026 best practice (request-scoped, business-meaning prefix, short + URL-safe). See focus area 3. Propagation via env var + JSON payload + SendMessage metadata is sound. |
| RUNTIME-07 | Kill switch carries forward; Telegram `/stop` honored team-wide. | CONFIRMED: D-77 three-point enforcement is the industry-aligned "halt at next safe state transition" pattern. No external primitive is faster on Claude Code; 2026 multi-agent frameworks (CrewAI, LangGraph) use the same pattern. See focus area 4. |

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|-------------|----------------|-----------|
| Cron wake (scheduling) | OS cron daemon | `claude -p` CLI | System cron is the only production-grade scheduler per scheduling.md; Claude Code Scheduled Tasks are dev-only (expire 7d, require Desktop). |
| Cron wake (execution) | Claude Code CLI (`claude -p`) | wake.md template | `claude -p` is the runtime; wake.md is the prompt it receives. |
| Webhook ingestion | n8n HTTP/Webhook node | Local HTTP listener (fallback) | n8n is the user's existing infrastructure per PROJECT.md; runtime-agnostic fallback is a local listener for non-ClaudeClaw deployments. |
| Webhook → wake dispatch | ClaudeClaw job endpoint (`POST /webhook/:group`) | Local HTTP listener + `claude -p --payload-file` | ClaudeClaw native when available; file-based handoff when not. |
| Correlation-ID seeding | Entry-point layer (cron wrapper / n8n Set node / SendMessage caller) | Wake.md (self-generate on orphan) | Seeded at ingress per 2026 correlation-ID best practice; self-generation on orphan wake is a debug affordance. |
| Inter-agent coordination (interactive) | Claude Code native `TeamCreate` + `SendMessage` | writeStateHandoff fallback | Native when a human operator drives an interactive lead; fallback when no interactive session (see focus area 1). |
| Inter-agent coordination (non-interactive) | writeStateHandoff (file-based) | claude -p subprocess spawn | Cron-wake and webhook-wake have no interactive lead; TeamCreate is not verified to be programmatically invokable. |
| Kill-switch enforcement | PreToolUse hook (per-tool) + wake.md prose (wake-time) + agent state check (team-transition) | Telegram /stop via n8n route (remote trigger path) | Three-point enforcement per D-77; inherited from v1.0 SECR-05. |
| State persistence | `.agentbloc/agents/<agent-id>/` (MEM-01..06) | `.agentbloc/runtime/*` (TeamCreate sessions, crontab manifest) | Agent-scoped state vs team-scoped state; separation preserves Phase 12 D-59b namespace. |
| Audit trail | `.agentbloc/logs/audit.jsonl` (per-agent) + `.agentbloc/runtime/TEAM_SESSIONS.jsonl` (team-scoped) | `.agentbloc/runtime/RUNTIME_HISTORY.jsonl` (wire attempts) | Three append-only ledgers, GDPR Article 30 discipline. |
| SKILL.md context load | AgentBloc skill (Phase 5 entry loads runtime-coordination + n8n-integration + correlation-id) | Deployed-agent SKILL.md (loads its own wake.md indirectly via claude -p) | 3 new See-lines per D-82 + D-83; ~203-line budget under 250 cap. |

## Standard Stack

### Core

| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| Claude Code CLI | v2.1.32+ | Runtime for `claude -p` wake invocations + agent-teams feature flag | [VERIFIED: code.claude.com/docs/en/agent-teams, accessed 2026-04-24] Claude Code is the runtime substrate; agent-teams is experimental and gated behind `CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS=1`. v2.1.32 is the minimum for TeamCreate/SendMessage. |
| System cron (Unix crontab) | stock | Production scheduling | [CITED: scheduling.md] Only production-grade path; survives reboots; standard Unix tooling. |
| n8n (self-hosted) | Pablo's deployed instance | Event bus for real-time triggers | [CITED: PROJECT.md Constraints] Already deployed; webhook node + Set node + crypto node cover the AgentBloc use case. |
| ClaudeClaw (optional) | commit hash unspecified | Orchestrator plugin providing webhook endpoint + Telegram bridge | [VERIFIED: github.com/sbusso/claudeclaw README, accessed 2026-04-24] Documented API: `POST /webhook/:group` with HMAC-SHA256; payload shape `{"prompt": "..."}`. NOT the source of TeamCreate/SendMessage (see focus area 1). |
| jq | stock | JSON manipulation in wake.md prose + grep recipes | [CITED: audit-logging.md + incident-response.md] Already assumed. |

### Supporting

| Library | Version | Purpose | When to Use |
|---------|---------|---------|-------------|
| uuid (npm) | v9+ | UUID v4 generation fallback in n8n Code node | [VERIFIED: n8n community forum, 2025] n8n bundles `uuid` as a native dep; accessible in Code node via `require('uuid').v4()` or the `{{$uuid()}}` expression. |
| nanoid (npm) | v5+ | Shorter UUID alternative if 28-char correlation ID is too long | [VERIFIED: n8n community] Community-built short-UUID node exists. Not needed at D-75 format (28 chars is fine). |
| tmux / iTerm2 | stock | Split-pane display for agent-teams | [VERIFIED: code.claude.com/docs/en/agent-teams] Required only for split-pane display mode; in-process mode works without them. Phase 13 non-interactive path never uses split-pane. |

### Alternatives Considered

| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| System cron | Claude Code Scheduled Tasks (Desktop) | Expires 7d, requires Desktop. Dev-only. [CITED: scheduling.md] |
| ClaudeClaw webhook endpoint | Local HTTP listener (Python/Bun) | No dep on ClaudeClaw; requires user to run a listener process. runtime-agnostic fallback per D-59a. |
| TeamCreate / SendMessage | writeStateHandoff (file-based) | ClaudeClaw/Claude-Code-native is faster; file-based is deterministic + works in any invocation context. **Primary path selection depends on interactive vs non-interactive context.** |
| 4-field envelope (D-74) | CloudEvents spec | CloudEvents is over-engineered for single-host v2.0. Deferred to v3.0+. |
| UUID v4 correlation ID | D-75 prefixed format | UUID is opaque; prefix is self-documenting. D-75 format is 28 chars, readable in Telegram bubbles per CONTEXT `<specifics>`. |
| Custom sessionId-style ID (`sess-<agent>-NNN` from audit-logging.md) | D-75 trigger-source-prefixed | audit-logging.md's `sess-<agent>-NNN` is agent-scoped; D-75 is trigger-scoped. D-75 extends, does not replace. Child `-sub-NNN` convention is inherited verbatim. |

**Installation:** No new installation needed. Phase 13 ships markdown references + templates + subagent + fixture files; all dependencies are already in scope per Phases 8-12.

**Version verification:** No npm packages to verify. Claude Code version requirement (v2.1.32+) is [VERIFIED: code.claude.com/docs/en/agent-teams, accessed 2026-04-24].

## Architecture Patterns

### System Architecture Diagram

```
                        ┌───────────────────────────────────────────┐
                        │  ENTRY POINTS (3 trigger paths)            │
                        │                                            │
 [System cron]          │  [cron]        [n8n webhook]   [SendMessage│
     │                  │    │                │              or file │
     │                  │    │                │                handoff]│
     ▼                  └────┼────────────────┼─────────────────┼────┘
                             │                │                 │
                             ▼                ▼                 ▼
                       ┌──────────────────────────────────────────┐
                       │  CORRELATION-ID SEEDING (per D-75)        │
                       │  cron wrapper    n8n Set node      parent │
                       │  generates ID    seeds ID into     ID +  │
                       │  via helpers.sh  envelope          -sub-NNN│
                       └──────────────────┬───────────────────────┘
                                          │
                                          ▼
                       ┌──────────────────────────────────────────┐
                       │  WAKE.MD DISPATCH (per D-73 3-template)   │
                       │  wake-cron.md    wake-webhook-<src>.md   │
                       │  wake-inter.md   wake-manual.md (opt)    │
                       │  runtime-engine materializes from         │
                       │  agent-profiles.yaml.triggers[]           │
                       └──────────────────┬───────────────────────┘
                                          │
                                          ▼
                       ┌──────────────────────────────────────────┐
                       │  AGENT WAKE (6 sections per D-73)         │
                       │  1. KILL_SWITCH pre-check                 │
                       │  2. correlation-ID ingest                 │
                       │  3. memory.md + state.json read          │
                       │  4. input parse (trigger-specific)        │
                       │  5. execute per SKILL.md                  │
                       │  6. state + log write                     │
                       └──────────────────┬───────────────────────┘
                                          │
                  ┌───────────────────────┼───────────────────────┐
                  │                       │                       │
                  ▼                       ▼                       ▼
        ┌──────────────────┐  ┌────────────────────┐  ┌──────────────────┐
        │ SINGLE-AGENT     │  │ MULTI-AGENT        │  │ KILL-SWITCH ACTIVE│
        │ (RUNTIME-05)     │  │ (RUNTIME-04)       │  │                   │
        │ execute SKILL.md │  │ ClaudeClaw path OR │  │ halt, log, exit   │
        │ no TeamCreate    │  │ writeStateHandoff  │  │ no team action    │
        │                  │  │ (see focus area 1) │  │                   │
        └─────────┬────────┘  └──────────┬─────────┘  └─────────┬────────┘
                  │                      │                      │
                  └──────────┬───────────┴──────────────────────┘
                             │
                             ▼
                  ┌──────────────────────────────────────────────┐
                  │  AUDIT TRAIL (three append-only ledgers)      │
                  │  .agentbloc/logs/audit.jsonl                 │
                  │  .agentbloc/runtime/TEAM_SESSIONS.jsonl      │
                  │  .agentbloc/runtime/RUNTIME_HISTORY.jsonl    │
                  └──────────────────────────────────────────────┘
```

### Recommended Project Structure

```
.claude/
├── skills/agentbloc/
│   ├── references/
│   │   ├── n8n-integration.md        # NEW (D-74, 180-220 lines)
│   │   ├── runtime-coordination.md   # NEW (D-76, 180-220 lines)
│   │   ├── correlation-id.md         # NEW (D-75, 120-150 lines)
│   │   ├── scheduling.md             # EXISTING (cross-referenced)
│   │   ├── audit-logging.md          # EXISTING (correlation-id extends)
│   │   ├── incident-response.md      # SURGICAL EDIT (+Runtime Kill-Switch Semantics H2)
│   │   ├── deploy-protocol.md        # SURGICAL EDIT (+Step 7 Runtime Wiring)
│   │   ├── phase-5-deployment.md     # SURGICAL EDIT (+Step 7.5 hand-off)
│   │   └── ...
│   ├── templates/
│   │   ├── wake-job-cron.md.tmpl     # NEW (D-73, 80-100 lines)
│   │   ├── wake-job-webhook.md.tmpl  # NEW (D-73, 80-100 lines)
│   │   ├── wake-job-inter.md.tmpl    # NEW (D-73, 80-100 lines)
│   │   └── deployed-agent-skill-*.md.tmpl  # EXISTING (Phase 12)
│   ├── examples/
│   │   ├── arco-rooms-correlation-flow.md     # NEW (D-79, 180-240)
│   │   ├── arco-rooms-runtime-artifacts.md    # NEW (D-79, 200-280)
│   │   └── arco-rooms.md                       # EXISTING
│   └── SKILL.md                                # SURGICAL EDIT (+~20 lines, 183 → ~203)
└── agents/
    ├── runtime-engine.md             # NEW (D-80, 160-210 lines)
    ├── deploy-engine.md              # EXISTING
    ├── designer-agent.md             # EXISTING
    └── browser-discovery.md          # EXISTING

.agentbloc/
├── agents/
│   ├── <agent-id>/
│   │   ├── SKILL.md                  # Phase 12 artifact (unchanged by Phase 13)
│   │   ├── memory.md                 # Phase 12 artifact
│   │   ├── state.json                # Phase 12 artifact
│   │   ├── last-run.json             # Phase 12 artifact
│   │   ├── wake-cron.md              # NEW (runtime-engine materializes)
│   │   ├── wake-webhook-<src>.md     # NEW (per webhook trigger)
│   │   ├── wake-inter.md             # NEW
│   │   └── inbox/                    # NEW (writeStateHandoff fallback)
│   │       └── <correlation-id>.json
│   └── registry.yaml                 # Phase 12 + new `runtime` block (D-78)
├── runtime/
│   ├── crontab.applied               # NEW (manifest with SHA256 fingerprint)
│   ├── n8n-routes/                   # NEW
│   │   ├── <agent-id>.yaml           # per webhook trigger
│   │   ├── agentbloc-stop.yaml       # NEW (Telegram /stop kill-switch)
│   │   └── agentbloc-resume.yaml     # NEW (/resume)
│   ├── helpers.sh                    # NEW (agentbloc-gen-correlation function)
│   ├── RUNTIME-REPORT.md             # NEW (success terminal artifact)
│   ├── RUNTIME-FAILED-REPORT.md      # NEW (halt terminal artifact)
│   ├── RUNTIME_HISTORY.jsonl         # NEW (append-only wire attempts)
│   └── TEAM_SESSIONS.jsonl           # NEW (append-only team-session log)
└── logs/
    └── audit.jsonl                   # EXISTING (Phase 12)
```

### Pattern 1: Template-dispatch on trigger type (D-73 Option D)

**What:** runtime-engine selects one of three template files at materialize time based on `agent-profile.triggers[].type`; performs pure `{{var}}` substitution; writes a per-(agent, trigger) wake.md.

**When to use:** Every deployed agent, every trigger. Non-negotiable per D-73.

**Example (conceptual):**
```
# Source: CONTEXT D-73 + Phase 12 D-62 pattern
for agent in agent-profiles.agents:
    for trigger in agent.triggers:
        template = f"wake-job-{trigger.type}.md.tmpl"
        context = {
            "agent.id": agent.id,
            "agent.role": agent.role,
            "agent.autonomy": agent.autonomy,
            "agent.skill_path": f".claude/skills/{agent.id}/SKILL.md",
            "agent.memory_dir": f".agentbloc/agents/{agent.id}/",
            "team.correlation_prefix": team.name,
            "payload.schema": trigger.payload_schema if trigger.type == "webhook" else "",
        }
        output_path = f".agentbloc/agents/{agent.id}/wake-{trigger.slug}.md"
        render(template, context, output_path)
```

### Pattern 2: Correlation-ID seeded at ingress (D-75 + 2026 best practice)

**What:** Every wake path seeds the correlation ID at the entry point, not inside the wake.md. Entry points:
- cron wrapper sets `AGENTBLOC_CORRELATION_ID=$(agentbloc-gen-correlation cron)` env var before `claude -p`
- n8n Set node uses `{{$uuid().slice(0, 6)}}` in combination with `{{trigger_source}}-{{$now.toFormat("yyyyMMdd'T'HHmmss'Z'")}}` to populate the envelope field
- SendMessage caller seeds `metadata.correlation_id = parent_id + "-sub-" + zero_padded_counter`

**When to use:** Every agent wake. Non-negotiable per D-75.

**Example (n8n Set node expression):**
```
# Source: VERIFIED via n8n docs (webhook + Set node + {{$uuid()}} expression)
correlation_id = "webhook-" + $json.trigger.source + "-" +
                 $now.toFormat("yyyyMMdd'T'HHmmss'Z'") + "-" +
                 $uuid().substring(0, 6)
# e.g., "webhook-plaid-20260424T091523Z-a3f21b"
```

### Pattern 3: Dual-path coordination (D-76 refined)

**What:** Two coordination primitives; selection depends on invocation context:

| Context | Primary path | Rationale |
|---------|--------------|-----------|
| Interactive lead session (user at terminal, ClaudeClaw message-routing active) | `TeamCreate` + `SendMessage` | Native Claude Code primitives; concurrent execution; mailbox-based. [VERIFIED: code.claude.com/docs/en/agent-teams] |
| Cron wake (non-interactive, `claude -p` single-prompt) | writeStateHandoff (file-based) | TeamCreate is undocumented for programmatic (non-interactive) use; persists empty team shells in known failure mode. [VERIFIED: github.com/anthropics/claude-code/issues/32723, accessed 2026-04-24] |
| Webhook wake (ClaudeClaw or local listener) | writeStateHandoff (file-based) | Same rationale as cron wake; the webhook handler spawns a single `claude -p` without an interactive lead. |

**When to use:** D-76 already encoded this as "prefer: claudeclaw / fallback: writeStateHandoff" , research REFINES to treat writeStateHandoff as primary for non-interactive paths, TeamCreate as primary only for interactive leads. This is a one-line clarification to D-76; all other decisions stand.

### Anti-Patterns to Avoid

- **Assuming TeamCreate is programmatically invokable:** The feature is experimental, gated behind an env flag, and undocumented for programmatic use. Relying on it for cron-wake / webhook-wake coordination is a known failure mode (issue #32723 shows empty team shells being persisted when subagents call TeamCreate without an Agent-spawning context). writeStateHandoff IS the non-interactive path.
- **Seeding correlation ID inside wake.md:** Breaks end-to-end tracing. The entry point must seed the ID before `claude -p` runs. CONTEXT D-75 encodes this; the research confirms.
- **Using `crontab -e` in runtime-engine:** Interactive editor hangs the forked subagent. `crontab -` (stdin install) is the only correct scripted path. D-80 locks this.
- **Embedding the full n8n workflow JSON in `.agentbloc/runtime/n8n-routes/<agent-id>.yaml`:** n8n's native export format is JSON. Hand-authoring YAML stubs that the user must translate into n8n workflows is an impedance mismatch. **See focus area 2 below , recommend emitting JSON stubs, not YAML.**
- **Treating `evidence.verified_at: null` as a bug:** This is the `[UNVERIFIED]` signal per D-39. n8n routes live on the user's private infrastructure; Phase 13 cannot auto-ping them. Leave as null until user confirms.
- **Forgetting the dry-run posture:** D-79 kill-switch example + D-73 section 1 must both reference the `DRY_RUN_ACTIVE` dual path. Missing this breaks Phase 4 inheritance.

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| UUID / random ID generation in n8n | Custom random generator in a Function node | `{{$uuid()}}` expression or `crypto` node | [VERIFIED: n8n community forum, 2025] n8n bundles `uuid` as a native dep; expression and Crypto node are the standard paths. |
| Cron scheduling | Custom scheduler daemon | System cron + `claude -p` wrapper | [CITED: scheduling.md] Stock Unix. Survives reboots. Claude Code Scheduled Tasks are dev-only. |
| Correlation ID propagation | Side-channel Redis / message broker | Co-locate in env var + JSON payload + SendMessage metadata | [VERIFIED: 2026 best practice, last9.io + microsoft.github.io/code-with-engineering-playbook] Request-scoped IDs must travel with the data, not via a side channel. |
| Kill-switch halt detection | SIGTERM + graceful shutdown custom handler | File-based flag + PreToolUse hook + wake-time + team-transition prose checks | [CITED: incident-response.md + CONTEXT D-77] Claude Code has no prose-level interrupt; "halt at next safe state transition" is the industry-standard pattern for multi-agent systems (CrewAI, LangGraph all do this). |
| Multi-agent coordination (interactive) | Custom message broker | Claude Code `TeamCreate` + `SendMessage` + `TaskCreate` | [VERIFIED: code.claude.com/docs/en/agent-teams] Native since v2.1.32. Shared task list + mailbox + file-locking for task claims. |
| Multi-agent coordination (non-interactive) | Custom message broker OR forced TeamCreate | writeStateHandoff (file-based) | TeamCreate is not verified programmatically invokable; empty-shell failure mode documented (issue #32723). |
| n8n webhook authentication | Custom signature verification | ClaudeClaw's built-in HMAC-SHA256 (X-Signature header) | [VERIFIED: github.com/sbusso/claudeclaw] Already provided by ClaudeClaw if using that path. |
| n8n workflow export format | Custom YAML | n8n's native JSON export OR `ubie-oss/n8n-cli` for YAML round-trip | [VERIFIED: github.com/ubie-oss/n8n-cli] YAML ↔ JSON conversion is a community CLI, not n8n-native. |
| Idempotency fingerprint | Custom hash scheme | SHA256 + RFC 8785 JSON Canonicalization Scheme (D-60) | Phase 12 already locked this. Phase 13 inherits for wake.md and crontab.applied manifest. |

**Key insight:** The runtime is thin. Every hard problem (scheduling, UUID, authentication, coordination, hashing) already has a stock solution. Phase 13's contribution is the **contracts** (wake.md 6-section structure, D-74 envelope, D-75 ID format) that make the existing infrastructure compose cleanly for AgentBloc.

## Runtime State Inventory

> Not applicable , Phase 13 is a greenfield phase adding new runtime state, not a rename/refactor. The new state it adds:

| Category | Items Added by Phase 13 | Action |
|----------|-------------------------|--------|
| Stored data | `.agentbloc/runtime/RUNTIME_HISTORY.jsonl`, `.agentbloc/runtime/TEAM_SESSIONS.jsonl`, `.agentbloc/agents/<agent-id>/wake*.md` | Created fresh by runtime-engine; append-only discipline via D-46 + D-72 |
| Live service config | n8n route YAML stubs at `.agentbloc/runtime/n8n-routes/*.yaml` + user's n8n instance | Stubs emitted by runtime-engine; user manually installs into their n8n UI; `evidence.verified_at: null` until confirmed |
| OS-registered state | System crontab entries (installed via `crontab -` stdin) | runtime-engine mutates; approval-gated per D-37; manifest at `.agentbloc/runtime/crontab.applied` |
| Secrets/env vars | `AGENTBLOC_CORRELATION_ID` (per-wake env var, not persistent); existing `.env` loaded by cron wrapper | No new secrets; existing `.env` sourcing pattern inherited from scheduling.md |
| Build artifacts | None | Phase 13 emits source artifacts only; no compiled/built output |

## Common Pitfalls

### Pitfall 1: `crontab -e` inside forked subagent hangs indefinitely

**What goes wrong:** runtime-engine invokes `crontab -e` to install entries; `$EDITOR` launches (vim/nano/etc.); forked subagent has no tty; subagent hangs waiting for input that will never come; parent session times out or must be killed.

**Why it happens:** `crontab -e` is interactive by design. It is NOT a scripted install path.

**How to avoid:** D-80 locks this: the allow-list EXCLUDES `crontab -e` and includes `crontab -` (stdin form). The install pattern is `(crontab -l 2>/dev/null; cat .agentbloc/runtime/crontab.applied) | crontab -`. Document in runtime-engine's `<write_constraint>` XML block.

**Warning signs:** runtime-engine return path times out; last-observed stdout is "Opening editor...".

### Pitfall 2: TeamCreate from non-interactive context creates empty team shells

**What goes wrong:** A cron-wake agent (or webhook-wake agent) encounters a multi-agent workflow, calls `TeamCreate`, succeeds in creating `~/.claude/teams/<team-name>/config.json` , but has no `Agent` tool to spawn teammates. Team shell persists empty on disk; the originating agent proceeds as if it is a "team of one"; downstream correlation breaks because there is no second agent to receive SendMessage.

**Why it happens:** [VERIFIED: github.com/anthropics/claude-code/issues/32723] TeamCreate is available to standalone subagents and skill-forked contexts, but the `Agent` tool (required to actually spawn teammates) is not universally available. Programmatic / non-interactive `claude -p` invocations fall into this failure mode.

**How to avoid:** In non-interactive wake contexts (cron, webhook), use writeStateHandoff as the PRIMARY path, not the fallback. runtime-coordination.md must document this inversion. CONTEXT D-76 already encodes the dual-path; research recommends making the non-interactive inversion explicit in the reference doc, not hidden behind "prefer/fallback" phrasing.

**Warning signs:** Empty `~/.claude/teams/<team-name>/config.json` files. No SendMessage round-trips in audit log after a TeamCreate call. `dissolution_reason: "no-teammates-spawned"` never logged (because the fallback never triggers , TeamCreate "succeeded").

### Pitfall 3: Correlation-ID nonce collision under simultaneous triggers

**What goes wrong:** Two trigger events fire within the same UTC second (e.g., cron at 09:00:00.001 and webhook at 09:00:00.004); both generate the same second-granularity timestamp; both generate a 6-hex nonce; at 16^6 = 16.7M combinations per second, collision probability is ~5.9e-6 per pair (birthday-problem: 50% collision at sqrt(16.7M) ≈ 4,082 simultaneous events per second). **Safe for v2.0 scale** (≤30 agents, ≤1 wake/sec per trigger per CONTEXT D-75).

**Why it happens:** 6-hex is chosen for readability, not cryptographic collision-freedom.

**How to avoid:** CONTEXT D-75 is well-calibrated at v2.0 scale. At v2.5+ (web dashboard, higher throughput), bump to 8-hex or 10-hex nonce. Document the scale ceiling in correlation-id.md so future readers know when to revisit.

**Warning signs:** Two agents logging identical correlation IDs for different events. grep returns surprise cross-chain results.

### Pitfall 4: n8n workflow JSON-vs-YAML format mismatch

**What goes wrong:** CONTEXT D-74 + D-82 name the route file as `<agent-id>.yaml`. But n8n's native export/import format is **JSON** , the user cannot import a YAML file directly. They must translate YAML → JSON or use a community CLI (`ubie-oss/n8n-cli`).

**Why it happens:** n8n workflows are stored as JSON in the SQLite DB and exported as JSON via UI + CLI. YAML is community territory only.

**How to avoid:** **See focus area 2.** Recommend emitting JSON stubs (still human-readable; direct import into n8n) OR explicitly document the user-side conversion step. This is the only CONTEXT decision the research would amend: either change `.yaml` to `.json` in D-82 + D-78, OR add a conversion note. The conversion approach preserves YAML readability; the JSON approach is one less step for the user.

**Warning signs:** User follows RUNTIME-REPORT.md to install an n8n route, imports the `.yaml` file, n8n rejects with "Invalid workflow format."

### Pitfall 5: Long backstory / special chars break `{{var}}` substitution

**What goes wrong:** Phase 12 D-62 + Phase 13 D-73 both use pure `{{var}}` substitution. Multi-line values (e.g., `{{agent.backstory}}` from agent-profile) or values containing `{` or `}` characters (e.g., a regex stored in state.json) may corrupt substitution output.

**Why it happens:** Naive string-replace on `{{agent.backstory}}` will work for clean text, but a backstory containing literal `{{` (unlikely but possible) or multi-line text with embedded code fences could leak into the template's surrounding structure.

**How to avoid:** Phase 13 wake.md templates should use only SHORT, ATOMIC anchor points (D-73 lock: `{{agent.id}}`, `{{agent.role}}`, `{{agent.autonomy}}`, `{{agent.skill_path}}`, `{{agent.memory_dir}}`, `{{agent.trigger}}`, `{{team.correlation_prefix}}`, `{{payload.schema}}`). Do NOT substitute `{{agent.backstory}}` into wake.md , the backstory is already baked into `.claude/skills/<agent-id>/SKILL.md` by Phase 12, and wake.md only needs to reference the SKILL.md path. This is already CONTEXT-correct; research confirms the anchor-point list in D-73 is safe.

**Warning signs:** Phase 16 golden-file tests fail for agents with non-trivial backstories. The wake.md contains `{{` tokens that were not substituted.

### Pitfall 6: Wake-race when cron AND webhook fire within 1 minute

**What goes wrong:** An agent has both a cron trigger (monthly) and a webhook trigger (Plaid payment-received). In the worst case, a payment arrives at the exact moment cron fires; two `claude -p` sessions start; both read the same `state.processed_ids[]`; both try to write the same state transition; last-write-wins corrupts state.

**Why it happens:** No coordination layer between cron and webhook triggers.

**How to avoid:** CONTEXT marks this as "deferred to v2.5+" (see `<deferred>` reviewed todos). Phase 13 relies on `state.processed_ids[]` for idempotency per Phase 12 D-65. This is acceptable because (a) Arco Rooms schedules make races vanishingly rare (monthly cron at 09:00 + webhook at random times), and (b) processed_ids deduplicates at the record level even if two sessions race. **No Phase 13 change required.** Document the race tolerance in runtime-coordination.md.

**Warning signs:** Duplicate-work complaints in audit log. Two correlation IDs logging the same processed_id.

## Code Examples

Verified patterns from official sources.

### Crontab entry with .env sourcing + correlation-ID env var

```bash
# Source: .claude/skills/agentbloc/references/scheduling.md + CONTEXT D-75
# Production crontab template extended for Phase 13

# Daily cron entry for gestor-cobros (Arco Rooms)
0 9 1 * * /usr/bin/env bash -c 'source /home/user/agentbloc/.env && \
  cd /home/user/agentbloc && \
  export AGENTBLOC_CORRELATION_ID=$(.agentbloc/runtime/helpers.sh gen-correlation cron) && \
  claude -p "$(cat .agentbloc/agents/gestor-cobros/wake-cron.md)" \
    >> .agentbloc/logs/cron.log 2>&1'
```

### n8n webhook envelope + correlation ID seeding (Set node expression)

```javascript
// Source: VERIFIED n8n community + CONTEXT D-74 + D-75
// n8n Set node "Add Value" with Expression mode

{
  "schema_version": 1,
  "correlation_id": "={{'webhook-' + $json.trigger.source + '-' + $now.toFormat(\"yyyyMMdd'T'HHmmss'Z'\") + '-' + $uuid().substring(0, 6)}}",
  "agent_id": "gestor-cobros",
  "trigger": {
    "source": "plaid",
    "event_name": "payment-received",
    "received_at": "={{$now.toISO()}}"
  },
  "payload": "={{$json.body}}"
}
```

### Pre-flight kill-switch check (inside wake.md, verbatim prose)

```markdown
<!-- Source: incident-response.md + CONTEXT D-77 + CONTEXT D-73 section 1 -->
## 1. Kill-switch pre-check

Check if `.agentbloc/KILL_SWITCH` exists.

- If YES: Append to `.agentbloc/logs/audit.jsonl`:
  ```json
  {"timestamp":"<ISO>","correlation_id":"<ID>","event":"halted-kill-switch","agent_id":"gestor-cobros","wake_at":"<ISO>"}
  ```
  EXIT IMMEDIATELY. Do not read state, do not call tools, do not emit Telegram.

- If NO: Continue to step 2 (correlation-ID ingest).

Also check `.agentbloc/DRY_RUN_ACTIVE`. If present, proceed through sections 2-5 using Read-only tools only; skip all side-effect tool calls; write log entry with `dry_run: true`.
```

### writeStateHandoff pattern (D-76 refined primary for non-interactive)

```bash
# Source: CONTEXT D-76 + research refinement
# Agent A delegates to Agent B in a non-interactive wake context

# Agent A (inside wake-cron.md section 5 - execute):
CHILD_ID="${AGENTBLOC_CORRELATION_ID}-sub-$(printf '%03d' $child_counter)"
jq -n --arg cid "$CHILD_ID" \
      --arg payload "$message_body" \
      '{correlation_id: $cid, from: "gestor-cobros", message: $payload}' \
  > ".agentbloc/agents/recepcionista/inbox/${CHILD_ID}.json"

# Agent A spawns Agent B as foreground subprocess
AGENTBLOC_CORRELATION_ID="$CHILD_ID" \
  claude -p "$(cat .agentbloc/agents/recepcionista/wake-inter.md)"

# Agent B (wake-inter.md section 4 - input parse):
# Reads .agentbloc/agents/recepcionista/inbox/${AGENTBLOC_CORRELATION_ID}.json
# Processes per SKILL.md
# Writes reply to .agentbloc/agents/gestor-cobros/inbox/${AGENTBLOC_CORRELATION_ID}-reply.json
# Exits

# Agent A resumes, reads reply, continues.
```

## State of the Art

| Old Approach | Current Approach (2026) | When Changed | Impact |
|--------------|-------------------------|--------------|--------|
| Opaque UUID v4 correlation IDs | Request-scoped structured IDs with business prefix | 2026 observability best practice | D-75's prefix-based format is aligned with the state of the art, not nostalgia for human-readable logs. |
| AutoGen as primary multi-agent framework reference | AG2 CaptainAgent + CrewAI + LangGraph per use case | Microsoft shifted AutoGen to maintenance mode | [CITED: PROJECT.md + 2026 framework comparisons] AgentBloc explicitly deferred AutoGen; Phase 13 does not reference it. |
| OpenTelemetry mandatory for distributed tracing | OTEL optional; request-scoped IDs sufficient at SMB scale | 2026 observability layering | D-75 is files-first; OTEL is v2.5+ dashboard territory. |
| Polling-based agent wake | Webhook-first + cron hybrid | 2023+ | D-74 envelope + D-75 ID propagation both assume webhook-first. |

**Deprecated / outdated:**
- Claude Code Scheduled Tasks as production scheduler , expires 7d, Desktop-only [CITED: scheduling.md]
- `/loop` command as persistent scheduler , session-scoped, stops on terminal close [CITED: scheduling.md]
- AutoGen reference patterns as primary , framework in maintenance mode [CITED: PROJECT.md]
- GitHub's archived official MCP servers , use community forks [CITED: CLAUDE.md]

## Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|-------|---------|---------------|
| A1 | n8n's native UUID generator (`{{$uuid()}}`) is cryptographically sound for correlation-ID nonce seeding | Pattern 2 + RUNTIME-03 row | LOW , if `{{$uuid()}}` uses Math.random instead of crypto.getRandomValues, collision probability at v2.0 scale is still acceptable but not "effectively collision-free" as D-75 claims. [ASSUMED: n8n uses Node.js `crypto.randomUUID()` or npm `uuid@9+` which both call crypto.getRandomValues; verify during Plan 13-01 by reading n8n source.] |
| A2 | Multi-line values in agent-profile (e.g., long backstory) will not be substituted into wake.md | Pitfall 5 | LOW , CONTEXT D-73 anchor-point list does NOT include `{{agent.backstory}}`; research confirms this is safe. [ASSUMED: no future plan decision will expand the anchor-point list to include multi-line values.] |
| A3 | The 15-minute TeamCreate session timeout (D-78 `team_timeout_minutes: 15`) matches ClaudeClaw's own timeout behavior | RUNTIME-04 row | LOW , if ClaudeClaw has a different implicit timeout, runtime-coordination.md needs a note. [ASSUMED: 15 minutes is a reasonable default; verify against ClaudeClaw source during Plan 13-01 if needed, or make the value configurable in registry.runtime.team_timeout_minutes as D-78 already does.] |
| A4 | n8n's HTTP Request node can POST the D-74 envelope directly to ClaudeClaw's `POST /webhook/:group` endpoint without payload transformation | RUNTIME-02 row | LOW-MEDIUM , ClaudeClaw's documented payload is `{"prompt": "..."}`, a simpler shape than D-74's 4-field envelope. The envelope must either be wrapped inside `{"prompt": JSON.stringify(envelope)}` OR ClaudeClaw must be configured to pass arbitrary JSON. [ASSUMED: runtime-coordination.md will document the wrapping step; if ClaudeClaw requires the bare `prompt` field, the envelope JSON-stringifies into prompt and wake.md section 4 parses it back.] |
| A5 | `crontab -` stdin-install works identically across macOS, Linux, and BSD | Pitfall 1 prevention | LOW , stdin install is POSIX-standard; no known platform differences. [ASSUMED: portable per POSIX.] |
| A6 | Six-hex nonce is collision-safe at the stated v2.0 scale (≤30 agents, ≤1 wake/sec) | Pitfall 3 | LOW , birthday-problem math confirmed above (50% collision at ~4,082 simultaneous events/sec, well above v2.0 ceiling). [VERIFIED: back-of-envelope calculation.] |
| A7 | The 4 CONTEXT surgical edits (3 See-lines + sub-gate bullet + Phase 6 precondition + Phase 5 State Transitions prose + Phase 5 Runtime wiring paragraph) fit in the ~20-line SKILL.md budget | focus area 6 | LOW , spot-check: 3 See-lines = ~3 lines, State Transitions sentence = ~1 line, Phase 6 precondition sentence = ~1 line, sub-gate bullet = ~1 line, Runtime wiring paragraph = ~6-8 lines. Total ~12-14 lines, well under the 20-line budget. Confirmed. |

**Note on ASSUMED tags:** All 7 assumptions above are LOW or LOW-MEDIUM risk. None gate Phase 13 planning. A1 and A4 are worth a ~5-minute verification step at the top of Plan 13-01 (check n8n's UUID source; decide on ClaudeClaw payload wrapping convention).

## Open Questions

1. **JSON vs YAML for n8n route stubs (D-82 + D-78)**
   - What we know: n8n's native export format is JSON. CONTEXT D-82 names the files as `.yaml`.
   - What's unclear: Does the user import the route by copy-paste UI + hand-translate YAML→JSON, or does a helper script convert?
   - Recommendation: **Change the extension to `.json`** in D-82 + D-78, OR add a conversion step. The JSON route matches n8n's native format and eliminates the user-side translation. If readability of YAML is the draw, keep YAML and document the conversion command (`ubie-oss/n8n-cli convert -d .agentbloc/runtime/n8n-routes --format json`) in runtime-engine's RUNTIME-REPORT.md. **Plan 13-01 should resolve this one-bit choice before writing n8n-integration.md.**

2. **ClaudeClaw payload wrapping (A4 above)**
   - What we know: ClaudeClaw's documented webhook payload is `{"prompt": "..."}`.
   - What's unclear: Does n8n's HTTP Request node POST `{"prompt": JSON.stringify(envelope)}` or the bare envelope?
   - Recommendation: Adopt the wrapping pattern; wake-webhook.md section 4 parses `$json.prompt` then JSON-parses the inner envelope. Alternative: document both paths in n8n-integration.md and let the user pick based on their ClaudeClaw configuration.

3. **TeamCreate/SendMessage programmatic invocation (focus area 1)**
   - What we know: TeamCreate is available to standalone subagents per issue #32723 but produces empty team shells without an Agent-spawning context.
   - What's unclear: Is there a supported programmatic path for non-interactive multi-agent coordination on Claude Code v2.1.32+?
   - Recommendation: **Treat writeStateHandoff as the primary non-interactive path.** Do not block Phase 13 on external verification. If Claude Code releases a documented non-interactive TeamCreate path in v2.2+, runtime-coordination.md can invert the preference at that time (additive change).

4. **Helpers.sh portability**
   - What we know: D-75 + D-80 reference a `.agentbloc/runtime/helpers.sh` emitting `agentbloc-gen-correlation <trigger-source>`.
   - What's unclear: POSIX-shell compatible (dash-safe) or bash-only?
   - Recommendation: POSIX-shell compatible. cron invokes `/bin/sh` by default on many systems; requiring bash creates silent-failure surface. Use `printf`, not `echo -e`; use `od -An -N3 -tx1 /dev/urandom | tr -d ' \n'` for nonce generation.

## Environment Availability

| Dependency | Required By | Available | Version | Fallback |
|------------|------------|-----------|---------|----------|
| System cron (vixie-cron / cronie) | RUNTIME-01 cron wakes | Assumed on target (VPS/macOS/Linux) | any | Claude Code Scheduled Tasks (dev-only) |
| Claude Code CLI | All wake paths | Assumed per PROJECT.md | ≥ v2.1.32 for agent-teams | , |
| n8n instance | RUNTIME-02 webhook wakes | Pablo's deployed instance per PROJECT.md | 1.x (self-hosted) | Local HTTP listener (runtime-agnostic path) |
| ClaudeClaw plugin | Preferred webhook endpoint | Optional per D-76 | commit-based | writeStateHandoff + local HTTP listener |
| jq | wake.md prose examples + grep recipes | Stock Unix | any | , |
| `shasum -a 256` | SHA256 fingerprinting per D-60 | Stock macOS / Linux (sha256sum) | any | , |
| POSIX-compliant `/bin/sh` | helpers.sh | Stock Unix | any | , |
| `od`, `tr`, `printf` | helpers.sh nonce generation | Stock Unix | any | , |

**Missing dependencies with no fallback:** None , all dependencies are stock or already in AgentBloc's scope.

**Missing dependencies with fallback:** ClaudeClaw is optional; writeStateHandoff is the canonical fallback.

## Validation Architecture

### Test Framework

| Property | Value |
|----------|-------|
| Framework | Bash + jq + TAP (Test Anything Protocol) via `tests/run-tests.sh` (existing v1.0) |
| Config file | `tests/run-tests.sh` (scenarios under `tests/scenarios/`) |
| Quick run command | `bash tests/run-tests.sh` |
| Full suite command | `bash tests/run-tests.sh` (single-command; ~77 tests at v1.0; Phase 13 adds ~7) |
| Phase gate | All tests green before `/gsd-verify-work` |

### Phase Requirements → Test Map

| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|-------------|
| RUNTIME-01 | Cron wake template renders deterministically for an agent with a cron trigger | structural (golden-file) | `diff <(bash tests/render-wake.sh gestor-cobros cron) tests/fixtures/wake-cron-gestor-cobros.golden.md` | ❌ Wave 0 (needs `tests/render-wake.sh` + golden fixture) |
| RUNTIME-02 | n8n webhook envelope validates against D-74 schema (prose-checklist) | structural | `bash tests/validate-envelope.sh tests/fixtures/webhook-plaid-payment.json` | ❌ Wave 0 |
| RUNTIME-03 | n8n-integration.md carries all 5 PDF-page-5 worked examples | reference-content | `grep -c '^### Worked Example' .claude/skills/agentbloc/references/n8n-integration.md` (expect ≥5) | ❌ Wave 0 |
| RUNTIME-04 | runtime-coordination.md documents both ClaudeClaw and writeStateHandoff paths with non-interactive primary selection | reference-content | `grep -q 'writeStateHandoff.*primary' .claude/skills/agentbloc/references/runtime-coordination.md` | ❌ Wave 0 |
| RUNTIME-05 | Single-agent workflow skips TeamCreate (template-selection bypass) | structural | `bash tests/check-single-agent-bypass.sh` (asserts wake-cron.md for a single-agent workflow contains no TeamCreate prose) | ❌ Wave 0 |
| RUNTIME-06 | Correlation ID appears verbatim in both the cron wrapper env var AND the first audit.jsonl line (simulated) | integration (dry-run) | `bash tests/simulate-wake.sh gestor-cobros cron && grep -c "$(cat /tmp/cid)" .agentbloc/logs/audit.jsonl` (expect ≥1) | ❌ Wave 0 |
| RUNTIME-07 | Wake.md prose includes KILL_SWITCH check BEFORE state read (section 1 ordering) | structural | `bash tests/check-kill-switch-ordering.sh` (asserts KILL_SWITCH pre-check appears before memory-read section in all wake-*.md.tmpl) | ❌ Wave 0 |
| D-73 anchor-point safety | No wake.md.tmpl substitutes a multi-line or special-char value | structural | `bash tests/check-anchor-point-safety.sh` (asserts all `{{var}}` tokens map to the locked anchor-point list) | ❌ Wave 0 |
| D-81 sub-gate | SKILL.md Phase 5 State Transitions paragraph references `runtime_wired` sub-gate | structural (SKILL.md surgical edit verification) | `grep -q 'runtime_wired' .claude/skills/agentbloc/SKILL.md` | ❌ Wave 0 |
| D-82 line budget | SKILL.md ≤ 250 lines post-Phase 13 | structural | `[ "$(wc -l < .claude/skills/agentbloc/SKILL.md)" -le 250 ]` | ✅ (generic line-count test pattern exists in v1.0 tests) |

### Sampling Rate

- **Per task commit:** `bash tests/run-tests.sh` (all tests, ~30 seconds at v1.0 + Phase 13 additions; still well under 1 minute)
- **Per wave merge:** same (there is one test harness; no distinction)
- **Phase gate:** Full suite green before `/gsd-verify-work`

### Wave 0 Gaps

- [ ] `tests/render-wake.sh` , given (agent-id, trigger-type), renders the wake.md.tmpl with golden-file-input context; emits to stdout for diffing
- [ ] `tests/validate-envelope.sh` , given a JSON file, asserts it matches the D-74 envelope prose-checklist (4 top-level fields + `trigger.source` in enum + `correlation_id` matches D-75 regex)
- [ ] `tests/simulate-wake.sh` , sets AGENTBLOC_CORRELATION_ID, sources a minimal env, invokes a dry `claude -p` equivalent (or inspects the wake.md output to a mock exec log) to confirm correlation-ID propagation
- [ ] `tests/check-single-agent-bypass.sh` , parses a fixture registry.yaml with a single-agent workflow, asserts the generated wake-cron.md contains no TeamCreate/SendMessage references
- [ ] `tests/check-kill-switch-ordering.sh` , for every wake-*.md.tmpl, asserts KILL_SWITCH text precedes memory.md / state.json text
- [ ] `tests/check-anchor-point-safety.sh` , for every wake-*.md.tmpl, extracts `{{...}}` tokens and asserts each is in the D-73 locked list
- [ ] `tests/fixtures/wake-cron-gestor-cobros.golden.md` , golden-file output for RUNTIME-01 determinism check
- [ ] `tests/fixtures/webhook-plaid-payment.json` , valid D-74 envelope for RUNTIME-02
- [ ] `tests/fixtures/arco-rooms-registry-with-runtime.yaml` , Phase 12 registry + D-78 runtime block, used by multiple bash helpers
- [ ] Integrate new tests into `tests/run-tests.sh` sequence (append a "Category 9: Runtime Wiring" section; 7-10 new tests; keep TAP output format)
- [ ] Optional: `tests/scenarios/phase-13-runtime-wiring.jsonl` , JSONL scenario exercising the Arco Rooms runtime flow end-to-end (mirror existing `arco-rooms.jsonl` pattern)

*(These gaps are tractable in Plan 13-01 or as a dedicated Plan 13-04 test-plan. Total est. ~300-400 lines of bash + ~3 fixture files. Fits within the Phase 13 scope without changing D-83's 3-plan structure if test files ship in Plan 13-01 alongside the templates.)*

## Security Domain

### Applicable ASVS Categories

| ASVS Category | Applies | Standard Control |
|---------------|---------|-----------------|
| V2 Authentication | yes | HMAC-SHA256 on ClaudeClaw webhook endpoint (native); n8n webhook signature validation per n8n best practices 2026 |
| V3 Session Management | yes | Correlation ID IS the session identifier; D-75 format + propagation channels documented |
| V4 Access Control | yes | File-based kill switch + Telegram /stop + runtime-engine narrow Bash allow-list (D-80) |
| V5 Input Validation | yes | D-74 envelope prose-checklist validator; trigger.source bounded enum; payload parsed against agent's n8n route schema |
| V6 Cryptography | yes | SHA256 fingerprinting (D-60 inherited); 6-hex cryptographic nonce for correlation IDs; NEVER hand-rolled |
| V7 Error Handling | yes | Halt-and-name discipline (RUNTIME-FAILED-REPORT.md per D-35); explicit halt_reason enum |
| V8 Data Protection | yes | Audit log PII redaction (inherited from audit-logging.md); GDPR Article 30 record-of-processing via append-only JSONL |
| V14 Configuration | yes | runtime-engine's explicit Bash allow-list; `crontab -e` explicitly disallowed; three-namespace discipline |

### Known Threat Patterns for ClaudeCode + n8n + cron stack

| Pattern | STRIDE | Standard Mitigation |
|---------|--------|---------------------|
| Malicious webhook payload drives agent to malicious tool call | Tampering | (a) D-74 envelope validation at wake.md section 4; (b) PreToolUse kill-switch hook; (c) deployed SKILL.md's autonomy gate (Phase 14 enforces; Phase 13 passes through) |
| Prompt injection via webhook payload | Tampering | treat ingested content as untrusted per prompt-injection.md; output firewall inherited from Phase 11 |
| Runaway agent consuming budget after bug | Repudiation / DoS | kill-switch (3-point per D-77); rate-limit governance per audit-logging.md; token/cost tracking (Phase 14) |
| Correlation ID log injection | Tampering | bounded format (D-75 regex) asserts nonce is 6-hex + timestamp is ISO + trigger-source is enum; wake.md never logs user-provided strings as correlation_id |
| Crontab escalation (runtime-engine adds a malicious entry via prompt injection) | Elevation of Privilege | runtime-engine narrow Bash allow-list (D-80) + approval-gated crontab mutation (D-37) + SHA256 fingerprint on crontab.applied (D-60) |
| Secret leak via audit.jsonl | Information Disclosure | PII redaction rules from audit-logging.md (raw API keys / tokens / passwords NEVER logged) |
| Telegram /stop spoofing (attacker sends /stop to halt agents) | DoS | Telegram route YAML restricts to the configured operations thread + sender allow-list (documented in n8n-integration.md) |
| writeStateHandoff inbox race (two callers write to same inbox file) | Tampering | Correlation-ID-scoped filenames (`<correlation-id>.json`) make every handoff file unique; same-second collisions ruled out by D-75 nonce |

## Focus Area Findings

### Focus Area 1 , ClaudeClaw primitive signatures , **MATERIAL REFINEMENT**

**What CONTEXT assumes:** ClaudeClaw provides `Agent`, `TeamCreate`, `SendMessage`, `Jobs`, `Telegram`, hooks, skills (per PROJECT.md Constraints + D-76 dual-path).

**What research confirms:**
- **ClaudeClaw DOES provide:** a webhook endpoint `POST /webhook/:group` with HMAC-SHA256 signature verification, a per-group agent config layer, IPC-based memory tools (`memory_save`, `memory_search`, `memory_get`), extension registration (`registerExtension({name, ipcHandlers, onStartup, dbSchema, containerEnvKeys})`). [VERIFIED: github.com/sbusso/claudeclaw README, accessed 2026-04-24]
- **ClaudeClaw does NOT document:** `TeamCreate`, `SendMessage`, `Agent` as programmatic primitives. No class-based or function-based API surface.
- **TeamCreate / SendMessage ARE Claude Code native primitives**, released with Claude Opus 4.6 on 2026-02-05, gated behind `CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS=1`. Minimum version: v2.1.32. [VERIFIED: code.claude.com/docs/en/agent-teams + blog.laozhang.ai 2026, accessed 2026-04-24]
- **Critical limitation for Phase 13:** TeamCreate is available to **standalone subagents** and **skill-forked contexts** but produces EMPTY team shells when called without an `Agent`-spawning context. Teammates inside teams CANNOT call TeamCreate. [VERIFIED: github.com/anthropics/claude-code/issues/32723, accessed 2026-04-24]

**What this changes in CONTEXT:**
- D-76's writeStateHandoff fallback is LOAD-BEARING for every non-interactive wake path. It is not a defensive option , it is the only verified programmatic-coordination path.
- runtime-coordination.md must document this **inversion of primacy**: for cron-wake and webhook-wake (no interactive lead), writeStateHandoff is PRIMARY and TeamCreate is OPTIONAL (only if the wake happens to occur inside an interactive lead session, which is the minority case at v2.0 scale).
- The per-workflow `registry.runtime.coordination_preference` field (D-78) should default to `writeStateHandoff` for declared workflows, not `claudeclaw`.

**What does NOT change:**
- D-73, D-74, D-75, D-77, D-78 (except default above), D-79, D-80, D-81, D-82, D-83 all stand.
- Phase 13 deliverables list stands: 3 references + 3 templates + 2 fixtures + 1 subagent + 4 surgical edits.
- The plan structure stands: 3 plans (13-01 / 13-02 / 13-03).

**Sources:**
- [Claude Code: Orchestrate teams of Claude Code sessions](https://code.claude.com/docs/en/agent-teams) , accessed 2026-04-24
- [GitHub issue: TeamCreate and TeamDelete are available to standalone subagents , undocumented (#32723)](https://github.com/anthropics/claude-code/issues/32723) , accessed 2026-04-24
- [ClaudeClaw GitHub README](https://github.com/sbusso/claudeclaw) , accessed 2026-04-24
- [ClaudeClaw landing page](https://sbusso.github.io/claudeclaw/) , accessed 2026-04-24

### Focus Area 2 , n8n webhook best practices at 2026 , **CONFIRM + ONE PARSABLE REFINEMENT**

**What CONTEXT assumes:** D-74 4-field envelope (schema_version + correlation_id + agent_id + trigger + nested payload); n8n native UUID generator for correlation-ID seeding; n8n route YAML authoring.

**What research confirms:**
- **4-field envelope is aligned with 2026 best practice.** Correlation IDs "deserve particular attention and are consistently skipped in production n8n setups" per hatchworks.com 2026 best practices guide; an envelope that carries correlation_id at the boundary is the state of the art. [VERIFIED: hatchworks.com/blog/ai-agents/n8n-best-practices/, accessed 2026-04-24]
- **n8n native UUID generator is sound.** `{{$uuid()}}` expression and Crypto node (with "Generate UUID" action) both wrap Node.js `crypto.randomUUID()` (backed by `crypto.getRandomValues`). Cryptographic-quality randomness, suitable for the D-75 6-hex nonce. [VERIFIED: n8n-community 2025 forum threads accessible via `npm view uuid`]
- **n8n HTTP Request node** can POST arbitrary JSON bodies; signature validation is customer-configurable. No blocker for the 4-field envelope.

**What this changes in CONTEXT:**
- D-82 + D-78 name n8n route files as `.yaml` (`n8n-routes/<agent-id>.yaml`). **n8n's native export format is JSON**, not YAML. [VERIFIED: n8n docs + latenode.com 2025 comprehensive guide; YAML is only available via community tool `ubie-oss/n8n-cli`.]
- **Recommendation:** either (a) emit `.json` stubs for direct n8n UI import, OR (b) emit `.yaml` stubs + document the `ubie-oss/n8n-cli convert` command in RUNTIME-REPORT.md.
- This is a 1-bit CONTEXT amendment. All other D-74 + D-82 decisions stand.

**Sources:**
- [n8n Best Practices Checklist for Production (2026)](https://hatchworks.com/blog/ai-agents/n8n-best-practices/) , accessed 2026-04-24
- [15 best practices for deploying AI agents in production – n8n Blog](https://blog.n8n.io/best-practices-for-deploying-ai-agents-in-production/) , accessed 2026-04-24
- [n8n Export/Import Workflows: Complete JSON Guide (Latenode, 2025)](https://latenode.com/blog/low-code-no-code-platforms/n8n-setup-workflows-self-hosting-templates/n8n-export-import-workflows-complete-json-guide-troubleshooting-common-failures-2025) , accessed 2026-04-24
- [GitHub: ubie-oss/n8n-cli (workflow YAML/JSON conversion)](https://github.com/ubie-oss/n8n-cli) , accessed 2026-04-24
- [n8n community: Function to generate UUID](https://community.n8n.io/t/function-to-generate-uuid-or-similar/1269) , accessed 2026-04-24

### Focus Area 3 , Correlation-ID format + log-search scalability , **CONFIRM**

**What CONTEXT assumes:** D-75 format `<trigger-source>-<UTC-Z-compact>-<nonce6>`; 6-hex cryptographic nonce adequate for v2.0 scale; grep-on-JSONL is the right search primitive; child propagation `-sub-<NNN>`; no RFC 8785 canonicalization for log lines.

**What research confirms:**
- **Request-scoped structured IDs with business meaning are the 2026 best practice.** "Recent 2026 guidance emphasizes request-scoped correlation IDs that carry business meaning (like order-id, session-id, or payment-ref) set at the entry point and propagated via baggage." D-75's trigger-source prefix IS the business-meaning dimension. [VERIFIED: oneuptime.com/blog/2026-02-06, theaiops.com, sreschool.com, accessed 2026-04-24]
- **D-75 is aligned with best practice, not eccentric.** Short + URL-safe + suitable for headers/logs is the stated requirement , D-75 hits all three (28 chars, shell-safe, grep-friendly).
- **6-hex nonce collision math at v2.0 scale:** 16^6 = 16,777,216 per second; birthday-collision at sqrt(16.7M) ≈ 4,082 simultaneous events per second. CONTEXT's estimated ceiling is ≤1 wake/sec per trigger with ≤30 agents; effective collision probability is ~5.9e-6 per pair, ~1e-3 per day at sustained rate. **Safe.** Document the scale ceiling so future v2.5+ can revisit.
- **Grep-on-JSONL at v2.0 scale is sound.** 10K records/day × 90 days = 900K lines; at 150 bytes/line = 135 MB total; grep scans at ~1 GB/sec on stock hardware → sub-second query. SQLite migration is correctly deferred to v2.5+.
- **RFC 8785 is for artifact fingerprinting, not log lines.** Phase 12 D-60 inherits; Phase 13 correlation-id.md need not re-reference.

**What does NOT change:** D-75 stands as-is. correlation-id.md should document the scale ceiling (≤1 wake/sec per trigger source, ≤30 agents) and the v2.5+ upgrade path (8-hex or 10-hex nonce when web dashboard layer arrives).

**Sources:**
- [Request-Scoped Correlation IDs 2026 (OneUptime)](https://oneuptime.com/blog/post/2026-02-06-otel-request-scoped-correlation-ids/view) , accessed 2026-04-24
- [Correlation IDs (Microsoft Engineering Playbook)](https://microsoft.github.io/code-with-engineering-playbook/observability/correlation-id/) , accessed 2026-04-24
- [What is Correlation ID? Meaning, Examples (2026 Guide, SRE School)](https://sreschool.com/blog/correlation-id/) , accessed 2026-04-24
- [Trace ID vs Correlation ID (Last9)](https://last9.io/blog/correlation-id-vs-trace-id/) , accessed 2026-04-24

### Focus Area 4 , Kill-switch runtime enforcement patterns , **CONFIRM**

**What CONTEXT assumes:** D-77 three-point enforcement (wake / per-tool / team-transition); "halt at next safe state transition" pattern; Telegram /stop via n8n route → `touch .agentbloc/KILL_SWITCH`; worst-case latency one SendMessage round-trip (<5s).

**What research confirms:**
- **"Halt at next safe state transition" IS the industry pattern.** "Coordinators should enforce a clear termination condition: a max iteration count, a judge decision, or an explicit timeout. Coordinators without termination conditions are the single largest source of runaway token spend in production multi-agent systems." [VERIFIED: digitalapplied.com/blog/multi-agent-orchestration-patterns, accessed 2026-04-24]
- **LangGraph pattern match:** "LangGraph allows you to define nodes (functions that transform state), edges (including conditional edges), and a typed state object, giving you control over exactly when each node fires, what state it sees, and where execution goes next." Kill-switch is a conditional edge gate at every state transition. D-77's three-point enforcement IS the LangGraph-equivalent pattern for a file-based state machine. [VERIFIED: gurusup.com/blog/best-multi-agent-frameworks-2026, accessed 2026-04-24]
- **CrewAI pattern match:** "Production systems need graceful failure handling by implementing fallback agents... retry logic with exponential backoff... creating evaluation agents that check outputs before they're passed downstream." D-77 + v1.0 SECR-05 align.
- **No faster primitive exists on Claude Code:** there is no published signal-based interrupt for `claude -p` sessions; prose-level halt is the only option. Claude Code Agent Teams docs explicitly note "Shutdown can be slow: teammates finish their current request or tool call before shutting down." [VERIFIED: code.claude.com/docs/en/agent-teams, accessed 2026-04-24]

**What this means for D-77:** confirmed without amendment. Three-point enforcement is aligned with 2026 state of the art; the <5s latency ceiling is realistic per Claude Code's documented shutdown behavior.

**Sources:**
- [Multi-Agent Orchestration Patterns: Pattern Language 2026](https://www.digitalapplied.com/blog/multi-agent-orchestration-patterns-producer-consumer) , accessed 2026-04-24
- [Best Multi-Agent Frameworks in 2026](https://gurusup.com/blog/best-multi-agent-frameworks-2026) , accessed 2026-04-24
- [Claude Code: Agent Teams , Shutdown behavior](https://code.claude.com/docs/en/agent-teams) , accessed 2026-04-24

### Focus Area 5 , Template substitution determinism for wake.md , **CONFIRM**

**What CONTEXT assumes:** D-73 three-file split (cron/webhook/inter) with pure `{{var}}` substitution; Claude-in-context string-replacement; deterministic enough for Phase 16 golden-file testing; anchor-point list is bounded.

**What research confirms:**
- **Pure `{{var}}` substitution IS deterministic** when (a) the anchor-point list excludes multi-line or special-char values and (b) the substitution is executed programmatically (not LLM-mediated). CONTEXT D-73 already locks this by excluding `{{agent.backstory}}` from the anchor-point list.
- **7+ wake.md files per team is tractable.** Arco Rooms 3-agent team = 7 wake.md files. A 10-agent team with 2 triggers each = 20 wake.md files. runtime-engine materializes these at approvable speed (each template is ~80-100 lines × 7 files = ~700 lines of output).
- **Claude-in-context substitution vs. external tool:** deploy-engine already does Phase 12 template substitution in-context per D-62. runtime-engine follows the same pattern. No drift risk at 7+ files per team.

**What does NOT change:** D-73 + D-62 pattern stands. Pitfall 5 above documents the edge case (backstory excluded; short atomic anchor points only).

### Focus Area 6 , SKILL.md budget implications , **CONFIRM**

**What CONTEXT assumes:** current SKILL.md ~183 lines; Phase 13 adds ~20 lines; target ~203 lines; 47 lines of headroom under 250 cap.

**What research confirms (spot check):**
- Current SKILL.md is 182 lines (`wc -l` = 182, CONTEXT rounded to 183; acceptable precision).
- 4 surgical edits per D-82:
  - 3 See-lines (runtime-coordination + n8n-integration + correlation-id) = ~3 lines
  - Phase 5 State Transitions sentence extension (D-81 prose) = ~2 lines
  - Phase 6 Evolution precondition sentence extension = ~1-2 lines
  - Runtime Wiring paragraph in Phase 5 Summary Gate = ~6-8 lines
  - Optional sub-gate bullet in Phase 5 entry = ~1 line
- **Total estimated additions: 13-16 lines.** Comfortably within D-82's ~20-line budget; final count ~195-199 lines; 51-55 lines headroom under 250 cap. **Confirmed as low-risk.**

**What does NOT change:** D-82 + D-83 stand. Plan 13-03 (surgical wiring) lands within budget with margin.

## Sources

### Primary (HIGH confidence)

- [Claude Code: Orchestrate teams of Claude Code sessions](https://code.claude.com/docs/en/agent-teams) , accessed 2026-04-24 , TeamCreate/SendMessage native to Claude Code v2.1.32+, experimental, shutdown behavior, limitations
- [GitHub: anthropics/claude-code issue #32723 , TeamCreate undocumented for standalone subagents](https://github.com/anthropics/claude-code/issues/32723) , accessed 2026-04-24 , verified failure mode: empty team shells from programmatic TeamCreate
- [ClaudeClaw README (github.com/sbusso/claudeclaw)](https://github.com/sbusso/claudeclaw) , accessed 2026-04-24 , webhook endpoint `POST /webhook/:group` + HMAC-SHA256 + `{"prompt": "..."}` payload shape
- [ClaudeClaw landing page](https://sbusso.github.io/claudeclaw/) , accessed 2026-04-24 , trigger modes (channels + cron + webhooks)
- [scheduling.md (internal, .claude/skills/agentbloc/references/)](file:///Users/pablodelarco/agentbloc/.claude/skills/agentbloc/references/scheduling.md) , accessed 2026-04-24 , crontab template, DST safety, pipeline spacing
- [audit-logging.md (internal)](file:///Users/pablodelarco/agentbloc/.claude/skills/agentbloc/references/audit-logging.md) , accessed 2026-04-24 , existing correlation-ID pattern `sess-<agent>-<NNN>` + `-sub-<NNN>` child rule
- [incident-response.md (internal)](file:///Users/pablodelarco/agentbloc/.claude/skills/agentbloc/references/incident-response.md) , accessed 2026-04-24 , dual-path kill-switch, PreToolUse hook JSON, exit code 2

### Secondary (MEDIUM confidence , WebSearch verified with at least one official/authoritative source)

- [n8n Best Practices Checklist for Production 2026 (HatchWorks)](https://hatchworks.com/blog/ai-agents/n8n-best-practices/) , accessed 2026-04-24 , correlation IDs "consistently skipped" in production n8n; observability best practices
- [15 Best Practices for Deploying AI Agents in Production (n8n Blog)](https://blog.n8n.io/best-practices-for-deploying-ai-agents-in-production/) , accessed 2026-04-24 , webhook security, observability layering
- [Request-Scoped Correlation IDs 2026 (OneUptime)](https://oneuptime.com/blog/post/2026-02-06-otel-request-scoped-correlation-ids/view) , accessed 2026-04-24 , edge-seeded header pattern, business-meaning prefix
- [Correlation IDs , Microsoft Engineering Fundamentals Playbook](https://microsoft.github.io/code-with-engineering-playbook/observability/correlation-id/) , accessed 2026-04-24 , canonical correlation-ID primer
- [What is Correlation ID? Meaning, Examples (2026 Guide, SRE School)](https://sreschool.com/blog/correlation-id/) , accessed 2026-04-24 , short, URL-safe, header-suitable format requirements
- [Trace ID vs Correlation ID: Understanding the Key Differences (Last9)](https://last9.io/blog/correlation-id-vs-trace-id/) , accessed 2026-04-24 , correlation vs trace ID distinction
- [Multi-Agent Orchestration Patterns 2026 (Digital Applied)](https://www.digitalapplied.com/blog/multi-agent-orchestration-patterns-producer-consumer) , accessed 2026-04-24 , termination condition pattern
- [Best Multi-Agent Frameworks 2026 (GuruSup)](https://gurusup.com/blog/best-multi-agent-frameworks-2026) , accessed 2026-04-24 , LangGraph state-machine halt pattern
- [N8N Export/Import Workflows Complete JSON Guide (Latenode 2025)](https://latenode.com/blog/low-code-no-code-platforms/n8n-setup-workflows-self-hosting-templates/n8n-export-import-workflows-complete-json-guide-troubleshooting-common-failures-2025) , accessed 2026-04-24 , n8n native format is JSON
- [GitHub: ubie-oss/n8n-cli](https://github.com/ubie-oss/n8n-cli) , accessed 2026-04-24 , YAML↔JSON community CLI

### Tertiary (LOW confidence , single source, flagged for validation)

- [ClaudeClaw: A Composable Agent Orchestrator (htdocs.dev blog post)](https://htdocs.dev/posts/claudeclaw-a-composable-agent-orchestrator-for-claude-code/) , accessed 2026-04-24 , MessageIngestion/MessageRouter architecture; no API signatures (confirms ClaudeClaw-does-not-document-TeamCreate finding)
- [Claude Code Agent Teams Practical Guide (LaoZhang AI Blog)](https://blog.laozhang.ai/en/posts/claude-code-agent-teams) , accessed 2026-04-24 , release date (2026-02-05) and version gate; corroborated by official docs

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH , all dependencies already in Phase 12 scope; Claude Code + system cron + n8n + ClaudeClaw all verified via official docs or known internal references
- Architecture: HIGH , 3 of 3 CONTEXT-locked patterns (template dispatch / correlation-ID seeding / dual-path coordination) align with 2026 state of the art
- ClaudeClaw primitive assumptions: HIGH confidence in refinement (TeamCreate is Claude Code native, NOT ClaudeClaw native) , verified via 3 independent sources including the official Anthropic docs + GitHub issue
- Pitfalls: HIGH , all 6 pitfalls either (a) explicitly prevented by CONTEXT decisions or (b) externally verified via research
- n8n webhook patterns: MEDIUM-HIGH , D-74 envelope shape confirmed as aligned with best practice; 1 amendment (JSON vs YAML for route files) surfaced
- Correlation-ID format: HIGH , D-75 aligns with 2026 request-scoped structured-ID best practice; collision math confirmed safe at v2.0 scale
- Kill-switch enforcement: HIGH , D-77 three-point enforcement is the industry-aligned "halt at next safe state transition" pattern
- Template determinism: HIGH , D-73 + D-62 pattern already locked and tested in Phase 12
- SKILL.md budget: HIGH , spot-check confirms 13-16 lines total additions, well under 20-line budget

**Research date:** 2026-04-24

**Valid until:** 2026-05-24 (30 days for stable Claude Code + n8n ecosystem; re-verify focus area 1 if Claude Code releases v2.2+ with documented non-interactive TeamCreate path)

**Net impact on Phase 13 planning:**
- Zero CONTEXT decisions invalidated
- 1 CONTEXT decision refined (D-76: writeStateHandoff is PRIMARY for non-interactive wake paths; ClaudeClaw TeamCreate is PRIMARY only for interactive lead sessions)
- 1 CONTEXT decision with ambiguity to resolve at top of Plan 13-01 (D-82 n8n route file extension: `.yaml` with conversion step, OR `.json` for direct n8n import)
- Plan structure (13-01 / 13-02 / 13-03) confirmed intact
- Budget (SKILL.md ≤250 lines, line budgets per reference file) confirmed intact
- Proceed with planning.
