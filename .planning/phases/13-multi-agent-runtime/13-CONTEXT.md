# Phase 13: Multi-Agent Runtime - Context

**Gathered:** 2026-04-24
**Status:** Ready for planning
**Decision mode:** Autonomous (per `autonomous_mode` memo , Pablo authorized expert-judgment decisions on implementation gray areas derivable from PDF + REQUIREMENTS + prior phases)
**Depends on:** Phase 12 (Deploy Pipeline + Agent Memory System , agents deployed at `.claude/skills/<agent-id>/SKILL.md` and `.agentbloc/agents/<agent-id>/*` must exist before Phase 13 can wake them), Phase 9 (workflow classification drives single-vs-team path), Phase 10 (verified integrations), v1.0 SECR-05 (kill-switch pattern carried forward)

<domain>
## Problem Statement

Deployed agents at `.claude/skills/<agent-id>/SKILL.md` (Phase 12 DEPLOY-01/D-59a artifacts) must actually wake and run. Phase 13 closes the gap between a successful `DEPLOY-REPORT.md verification_status: PASSED` (Phase 12 output) and the first productive agent tick in production. The scope is a thin wiring layer on top of ClaudeClaw primitives (`Agent` / `TeamCreate` / `SendMessage` / Jobs) , AgentBloc does not reimplement scheduling or coordination; it emits the contracts and the templates that make these primitives load correctly for every agent in the team.

Four runtime capabilities must be wired end-to-end:
1. **Cron wake** (RUNTIME-01) , deployed agents fire at the scheduled time via system cron + `claude -p` (the only production-grade path per scheduling.md; Claude Code Scheduled Tasks are dev-only), each wake carrying a new correlation ID
2. **Event wake** (RUNTIME-02, RUNTIME-03) , n8n webhooks (Gmail/Plaid/Calendar/Telegram/form) route event payloads into ClaudeClaw jobs that wake the correct agent with the payload attached; a new reference doc captures the event-source -> n8n node -> ClaudeClaw job payload contract
4. **Inter-agent coordination** (RUNTIME-04, RUNTIME-05) , ClaudeClaw's `SendMessage` and `TeamCreate` primitives are invoked when the registry declares a multi-agent workflow; single-agent workflows run without `TeamCreate` overhead per Designer Agent's orchestration classification (ORCH-03 , workflows[].type in registry.yaml)
5. **Correlation ID propagation** (RUNTIME-06) , every trigger seeds a new ID; the ID rides through `SendMessage`, `TeamCreate` team metadata, and every downstream log line; a single user event is grep-traceable end-to-end
6. **Kill switch at runtime** (RUNTIME-07) , `.agentbloc/KILL_SWITCH` (v1.0 SECR-05) is checked on every agent wake AND at every state transition inside a `TeamCreate` session; Telegram `/stop` remote trigger halts the whole team cleanly, not mid-prose

Phase 13 produces the references + templates + subagent + surgical SKILL.md edits that make the above deterministic and inspectable. It does NOT produce runtime observability (JSONL log aggregation = Phase 14 MONITOR-01..06) and does NOT enforce autonomy-level gates at side-effect time (= Phase 14 AUTON-01..05). Phase 13 wakes agents correctly and traces their conversations; Phase 14 watches them.

Phase 13 emits artifacts that Phase 14 observes and Phase 15 extends (anticipation-pass agents inherit the same wake protocol with zero runtime changes). A clean Phase 13 is a load-bearing precondition for Phase 14 plans , autonomy enforcement reads the correlation ID and approval queue routing depends on deterministic wake semantics.

**In scope:**
- `.claude/skills/agentbloc/references/n8n-integration.md` (new) , webhook-to-agent mapping pattern (event source -> n8n node -> payload shape -> correlation seed -> ClaudeClaw job), canonical payload schema, 5 worked examples from the PDF trigger matrix (Gmail filter, Plaid webhook, form submit, calendar watch, Telegram message). Prose-checklist validator per D-13.
- `.claude/skills/agentbloc/references/runtime-coordination.md` (new) , `TeamCreate` / `SendMessage` contract + topology-to-primitive mapping (pipeline/mesh/hierarchy/swarm -> primitive calls) + dual-path fallback when ClaudeClaw unavailable (writeStateHandoff: agent A writes to `.agentbloc/agents/<agent-b>/inbox/<correlation-id>.json` then issues `claude -p --session-id <correlation-id>` direct wake) + graceful-dissolution semantics (team dissolves when every member returns non-continuation outputs) + per-workflow single-agent bypass (workflows[].agents.length === 1 skips TeamCreate entirely per RUNTIME-05)
- `.claude/skills/agentbloc/references/correlation-id.md` (new) , format `<trigger-source>-<UTC-Z>-<nonce6>` with bounded trigger-source enum (`cron` / `webhook-<source>` / `telegram` / `inter` / `manual`), seeding rules per trigger, propagation mechanism (env var `AGENTBLOC_CORRELATION_ID` at `claude -p` invocation AND JSON payload field AND SendMessage message metadata), child-ID append rule `-sub-<NNN>` inherited from audit-logging.md, grep recipes for end-to-end tracing, retention policy (correlation IDs appear in JSONL logs only , no separate persistent index in v2.0 per D-1 files-first)
- `.claude/skills/agentbloc/templates/wake-job.md.tmpl` (new) , canonical 6-section wake-job markdown consumed by `claude -p`: (1) kill-switch pre-check, (2) correlation-ID ingest (from env var or payload), (3) memory.md + state.json read, (4) payload parse (event triggers) or memory-derived input (cron triggers), (5) execute per `.claude/skills/<agent-id>/SKILL.md`, (6) write state.json + last-run.json + log entry. Template follows D-62 three-file split (`wake-job-cron.md.tmpl`, `wake-job-webhook.md.tmpl`, `wake-job-inter.md.tmpl`) to avoid Markdown-in-context conditional-block failure surface.
- `.claude/agents/runtime-engine.md` (new) , Claude Code subagent that materializes wake.md files per agent, registers crontab entries (or writes `crontab.applied` manifest), emits n8n route YAML stubs for the user's n8n instance, and extends registry.yaml with the `runtime` top-level block. `context: fork` + scoped tools (Read/Grep/Glob/Write/Edit; Bash narrowed to `crontab -e/-l`, `shasum -a 256`, `claude agents list`, `claude mcp list`; NO WebFetch, NO other MCPs). Parallels deploy-engine (Phase 12) / designer-agent (Phase 9) / browser-discovery (Phase 11).
- `.claude/skills/agentbloc/examples/arco-rooms-correlation-flow.md` (new) , canonical walkthrough of 3 Arco Rooms triggers (monthly cron -> Gestor Cobros, Telegram tenant message -> Recepcionista SendMessage -> Gestor Cobros, KILL_SWITCH activation mid-pipeline) with the correlation ID visible in each log line.
- `.claude/skills/agentbloc/examples/arco-rooms-runtime-artifacts.md` (new) , fixture showing the actual wake.md files + crontab entries + n8n webhook route configs for the 3 Arco Rooms agents (textual, not executable).
- Surgical edits to `.claude/skills/agentbloc/references/deploy-protocol.md` , add Step 7 (Runtime Wiring) between the existing Step 6 (verification) and Step 8-equivalent reporting, delegating to the 4 new refs via See-lines; deploy-engine invokes runtime-engine as its final sub-step, making the `.agentbloc/deploy/crontab.proposed` file emitted in Phase 12 the direct input to runtime-engine.
- Surgical edits to `.claude/skills/agentbloc/references/phase-5-deployment.md` , add Step 7.5 (Runtime Wiring section) that narrates the runtime hand-off between deploy-engine and runtime-engine; preserve existing Step 7/8/9 structure.
- Surgical edits to `.claude/skills/agentbloc/references/incident-response.md` , add a Runtime Kill-Switch Semantics paragraph documenting wake-time check + team-wide halt discipline with correlation-ID-scoped dissolution (inherits v1.0 SECR-05 dual-path).
- Surgical edits to `.claude/skills/agentbloc/SKILL.md` , Phase 5 entry gains 3 new unconditional-load See-lines (n8n-integration + runtime-coordination + correlation-id; incident-response.md is already loaded via phase-5-deployment so no duplication); new sub-gate `runtime_wired` joins the Phase 5 State Transitions paragraph; Phase 6 Evolution precondition extends to verify `registry.yaml` has a `runtime.cron_registered_at` timestamp (proves Phase 13 completed before Evolution-scans touch live agents).

**Out of scope (belongs to later phases or v2.5+):**
- JSONL log aggregation + daily rollup + activity-feed.jsonl -> Phase 14 (MONITOR-01..06); Phase 13 writes single log lines with correlation IDs but does not build the aggregation layer
- Briefing-agent daily Telegram summaries -> Phase 14 (MONITOR-04)
- Autonomy-level enforcement at side-effect time (semi-approval, supervised-wait) -> Phase 14 (AUTON-01..05)
- Approval queue Telegram routing + cost tracking + task-locking state + status badges -> Phase 14 (CTRL-01..05)
- Anticipation-pass agents in runtime (Phase 15 extends Designer output; Phase 13's wake templates already support anticipated agents with zero change once Phase 15 ships) -> Phase 15 (ANTIC-01..05)
- Correlation-ID audit viewer (web dashboard with time-sorted ID drill-down) -> v2.5+
- SQLite persistence for log search -> v2.5+
- Cross-run correlation-ID diffing (detecting flaky paths) -> v4.0 Self-Healing Evolution
- n8n route installation automation (Phase 13 emits route YAML stubs; the user installs them into their n8n instance manually; future v2.5+ could add an n8n MCP wrapper to push routes programmatically)
- Mobile-push / SMS / phone-call wake channels , Telegram is the only human channel in v2.0 (PDF page 6 / PROJECT.md Constraints)
- Auto-remediation when a wake fires but the agent fails to complete -> v4.0 Self-Healing Evolution
- Distributed / multi-host runtime (agents on different machines coordinating via message broker) , v2.0 is single-host (PDF page 8 restrictions, CLAUDE.md constraints); multi-host is v3.0+

</domain>

<decisions>
## Implementation Decisions

### Inherited from Phases 8-12 and v1.0 (carry forward , do not re-decide)

- **Inherited D-1 (v1.0 + Phase 8 D-11):** File-based state. Phase 13 writes wake-job markdown (`wake.md` per agent), correlation IDs as bare strings in log JSONL, n8n route YAML stubs. No database.
- **Inherited D-11 (Phase 8):** Artifact emission lives in a gate, not a separate subagent flow. Runtime wiring is the Phase 5 Summary gate extension (runtime-engine runs after deploy-engine as the final step of `deploy-protocol.md`). Same pattern as Business Graph -> agent-profiles -> integration-manifest -> DISCOVERY-REPORT -> DEPLOY-REPORT -> runtime artifacts.
- **Inherited D-13 (Phase 8):** Validators are prose-checklists inside the reference file. `n8n-integration.md`, `runtime-coordination.md`, `correlation-id.md` all use prose checklists. No `ajv`, no `yamllint`, no external linter.
- **Inherited D-14 (Phase 8):** User confirms a rendered table; silent artifact emission. The user sees a rendered Runtime Summary table (agents, triggers, cron entries, n8n routes, correlation-ID prefix) and confirms; the wake.md files + crontab-applied manifest + n8n route YAML are written silently.
- **Inherited D-15 (Phase 8 + Phase 12 D-59a/b/c):** Three-namespace discipline , `.claude/skills/` for stable skill contracts (agentbloc itself + mcp-builder + deployed agents); `.claude/agents/` for AgentBloc native subagents (designer-agent, browser-discovery, deploy-engine, and now runtime-engine); `.agentbloc/` for customer mutable runtime state. Phase 13 follows verbatim: the new subagent lives at `.claude/agents/runtime-engine.md`; the wake.md files ship at `.agentbloc/agents/<agent-id>/wake.md` (mutable, regenerated if triggers change); the applied crontab manifest at `.agentbloc/runtime/crontab.applied`; the n8n route stubs at `.agentbloc/runtime/n8n-routes/<agent-id>.yaml`.
- **Inherited D-18 (Phase 8):** Bounded enums for discriminated unions. `trigger.type` in wake.md is `cron | webhook | inter | manual`; `wake_outcome` in last-run.json is `completed | failed | halted-kill-switch | halted-upstream-failure`; `team_dissolution_reason` in logs is `all-members-returned | kill-switch | timeout | error`.
- **Inherited D-21 (Phase 9):** Subagent with `context: fork`, scoped tools, Bash narrowly allow-listed. runtime-engine gets Read/Grep/Glob/Write/Edit + narrowed Bash allow-list (`crontab -e`, `crontab -l`, `shasum -a 256`, `claude agents list`, `claude mcp list`) + NO WebFetch + NO other MCPs. This is a narrower Bash surface than deploy-engine (D-67) because runtime-engine mutates crontab (a system-level resource); the allow-list is locked in the subagent's `<write_constraint>` XML block.
- **Inherited D-22 (Phase 9):** Three-tier field obligation (REQUIRED / RECOMMENDED / OPTIONAL) with `schema_version: 1` integer. Applied to the `runtime` block in registry.yaml (D-78 below), the correlation-ID format spec (D-75), and the wake.md template schema (D-74).
- **Inherited D-23 (Phase 9):** On topology ambiguity the default is `mesh`. Phase 13 `runtime-coordination.md` restates this: single-agent workflows bypass TeamCreate; multi-agent workflows with pipeline topology use staggered cron (scheduling.md pipeline-spacing pattern); mesh / hierarchy / swarm all use `TeamCreate` + `SendMessage` with the same primitive calls, differing only in which agent spawns the team (topology-to-spawn-rule matrix in runtime-coordination.md).
- **Inherited D-24 (Phase 9):** ADK vocabulary for orchestration patterns. Phase 13 runtime-coordination.md cites the 5 patterns (Sequential / Parallel / Loop / Event-driven / Conversational) by their ADK names; maps each to `TeamCreate` semantics (Sequential = no team / staggered cron; Parallel = TeamCreate with fan-out; Loop = self-SendMessage with bounded iteration; Event-driven = webhook wake with optional TeamCreate on dependency detection; Conversational = TeamCreate with peer SendMessage until consensus).
- **Inherited D-29 (Phase 9, reaffirmed by D-58 Phase 11):** SKILL.md extensions are surgical, budget <=250 lines total. SKILL.md is at ~183 lines post-Phase 12 (3b312ba + 783b538 + Phase 12 edits); Phase 13 adds ~20 lines (3 See-lines + new sub-gate bullet + Phase 6 precondition extension sentence + Phase 5 Runtime wiring paragraph). Target: ~203 lines, 47 lines of headroom under the cap. See D-83 below for the exact per-edit line budget.
- **Inherited D-31 (Phase 10):** Split references per concern: imperative flow vs declarative schema vs output contract. Phase 13 ships three concern-separated references: (a) `n8n-integration.md` (external-event-to-agent mapping contract , declarative + worked examples), (b) `runtime-coordination.md` (imperative TeamCreate/SendMessage invocation flow + fallback pattern), (c) `correlation-id.md` (declarative format spec + grep recipes). No conflation.
- **Inherited D-34 (Phase 10) + Phase 12 D-70:** Three-check verification protocol. Phase 13 extends the Phase 12 three-check loop (SKILL.md loads / MCP tools/list / crontab registered) with runtime-specific Check 4: every agent in registry.yaml has a `wake.md` file at `.agentbloc/agents/<agent-id>/wake.md` AND a crontab entry OR an n8n route YAML stub; the verification passes only when all three trigger-paths (cron / event / inter) are accounted for per the agent-profile `triggers[]` array. Check 4 is additive; the Phase 12 three-check loop runs unchanged when Phase 13 has not yet executed.
- **Inherited D-35 (Phase 10 + Phase 12 D-71):** Halt-and-name with named report on failure. Phase 13 extends: runtime wiring failure -> `.agentbloc/runtime/RUNTIME-FAILED-REPORT.md` (twin of DEPLOY-FAILED-REPORT.md) with frontmatter citing which wake path failed + specific error + recommended fix. Name format follows the same halt-and-name discipline as Phase 11 DISCOVERY-BLOCKED-REPORT.md and Phase 12 DEPLOY-FAILED-REPORT.md.
- **Inherited D-37 (Phase 10):** Approval-gated execution for anything with blast radius. Crontab mutation is a blast-radius event , runtime-engine surfaces the proposed crontab diff (comparing `.agentbloc/deploy/crontab.proposed` from Phase 12 to the user's existing `crontab -l` output) and requires user approval before applying. On approval, the manifest moves to `.agentbloc/runtime/crontab.applied`. Same approval gate applies to overwriting n8n routes if the user already has routes with matching names.
- **Inherited D-39 (Phase 10):** Evidence record + `[UNVERIFIED]` flag. Every n8n integration emitted in `.agentbloc/runtime/n8n-routes/<agent-id>.yaml` carries an `evidence.verified_at` field that starts as `null` ([UNVERIFIED] state); it moves to a timestamp only when the user confirms the route is live in their n8n instance (Phase 13 does not auto-ping n8n; user-confirmed health is the signal because n8n webhooks are generally internal-network endpoints).
- **Inherited D-40 (Phase 10) + D-73 (Phase 12):** Surgical edits to existing references. Phase 13 touches 3 existing references (phase-5-deployment.md Step 7.5 addition + deploy-protocol.md Step 7 addition + incident-response.md Runtime Kill-Switch Semantics paragraph) without refactoring unrelated content. All 3 edits are minimum-viable insertion points; no content is deleted or rephrased.
- **Inherited D-42 (Phase 10) + D-60 (Phase 12):** Idempotency fingerprint pattern. wake.md files per agent carry an HTML-comment fingerprint `<!-- agentbloc:fingerprint sha256=<64-hex> generated_at=<ISO-8601> -->`; re-running runtime-engine with unchanged inputs produces identical fingerprints. Same SHA256-over-body-with-timestamp-masking pattern (D-60). Crontab entries are not fingerprinted at the line level (crontab has no comment-fingerprint convention); the crontab.applied manifest carries a top-level fingerprint.
- **Inherited D-46 (Phase 11) + D-72 (Phase 12):** Append-only ledger format. Phase 13 extends the Phase 12 `.agentbloc/deploy/DEPLOY_HISTORY.jsonl` with runtime-side siblings: `.agentbloc/runtime/RUNTIME_HISTORY.jsonl` (one JSON per runtime-wire attempt, append-only, GDPR Article 30 record-of-processing) and `.agentbloc/runtime/TEAM_SESSIONS.jsonl` (one JSON per TeamCreate instance with correlation ID + agents + outcome; supports correlation-ID-scoped audits). Same discipline: one JSON per line, UTC-Z timestamps, GDPR Article 30 field set.
- **Inherited D-58 (Phase 11) + D-83 (Phase 13, below):** Context-budget discipline for Phase-entry loads. Phase 5 currently loads 5 references (phase-5-deployment + deploy-protocol + deployed-agent-skill-schema + agent-memory-schema + deploy-report-schema). Phase 13 adds 3 more (n8n-integration + runtime-coordination + correlation-id) for an estimated ~1,900-line Phase 5 unconditional load. Still under the budget ceiling because none of the new references exceed 250 lines. The runtime-engine subagent loads its own templates in its forked context.
- **Inherited v1.0 SECR-05:** Kill-switch pattern. Phase 13 is the phase that FINALLY implements the runtime kill-switch read , every generated wake.md starts with a prose check of `.agentbloc/KILL_SWITCH` before any side-effect tool call. The Phase 5 deployed-agent-skill-schema Validation Check 7 (Phase 12 D-70) required the prose to exist in each SKILL.md; Phase 13 now enforces that the wake.md wrapper actually executes the check on each wake. Dual-path (file or Telegram /stop) inherited verbatim from incident-response.md.
- **Inherited v1.0 Phase 4 Dry Run:** Runtime wake paths inherit the dry-run posture , every wake.md carries a prose condition: if `DRY_RUN_ACTIVE` file exists (same dual-path semantics as KILL_SWITCH), the agent executes only Read-only tools and writes a log entry without side effects. This matches the Phase 4 dry-run discipline from v1.0 and is orthogonal to the kill-switch (DRY_RUN pauses side effects; KILL_SWITCH halts execution entirely).
- **Inherited Phase 12 D-59a/b/c triple-override:** Three-namespace split stands. Phase 13 artifacts follow: developer tooling at `.claude/agents/runtime-engine.md` (native subagent); stable contracts for deployed agents remain at `.claude/skills/<agent-id>/SKILL.md` (unchanged); mutable runtime state at `.agentbloc/agents/<agent-id>/wake.md` + `.agentbloc/runtime/*`. No namespace drift.
- **Inherited Phase 12 D-62 (template-based generation):** Template-per-autonomy-variant pattern with fixed anchor points. Phase 13 applies the same pattern for wake-job templates: three files `wake-job-cron.md.tmpl`, `wake-job-webhook.md.tmpl`, `wake-job-inter.md.tmpl` (dispatch on trigger type). Each is pure `{{var}}` substitution. NO `{% if %}` conditionals, NO LLM per-agent assembly , same rationale as Phase 12 D-62: deterministic, cheap, testable with golden files in Phase 16. Autonomy variance (full / semi / supervised) is already baked into the deployed SKILL.md by Phase 12; wake.md does not re-parameterize on autonomy.
- **Inherited Phase 12 D-63 (registry format):** Registry at `.agentbloc/agents/registry.yaml` is YAML with `schema_version: 1`. Phase 13 extends with a new top-level `runtime` block (D-78 below). Additive change; does not break Phase 12 artifacts or require registry regeneration , runtime-engine reads the existing registry, adds the `runtime` block, writes it back.
- **Inherited Phase 12 D-66 (.mcp.json merge semantics):** Merge-keep-existing-with-conflict-warning pattern. Phase 13 does not touch `.mcp.json` (n8n integration is a webhook, not an MCP server). If future integration uses n8n's own MCP server, Phase 13 would defer to the Phase 12 D-66 merge semantics unchanged.
- **Inherited Phase 12 D-67 (deploy-engine narrow Bash):** Narrow Bash allow-list for subagents that touch system state. Phase 13 tightens: runtime-engine's Bash allow-list is explicitly enumerated (`crontab -e`, `crontab -l`, `shasum -a 256`, `claude agents list`, `claude mcp list`). See D-80 below for the full list + rejection of broad-Bash alternatives.

### New decisions (autonomous, per PDF + REQUIREMENTS + prior phases)

#### Wake-job template structure (resolves RUNTIME-01, RUNTIME-02, RUNTIME-05)

- **D-73 (Wake-job template is a 6-section markdown file consumed by `claude -p`, materialized per agent per trigger type, three template variants dispatched on trigger.type):** Every deployed agent gets one or more wake.md files at `.agentbloc/agents/<agent-id>/wake.md` (or `wake-<trigger-type>.md` when an agent has multiple trigger sources). The wake.md file is the literal prompt `claude -p` receives. Structure (6 sections, fixed order, mandatory):

  1. **Kill-switch pre-check** , prose citing `.agentbloc/KILL_SWITCH`; if file exists, log "halted by kill switch" with correlation ID to `.agentbloc/logs/audit.jsonl` and EXIT IMMEDIATELY before any state reads.
  2. **Correlation-ID ingest** , read `AGENTBLOC_CORRELATION_ID` env var (cron path) OR payload-field (`payload.correlation_id`, webhook path) OR SendMessage metadata (`message.correlation_id`, inter path); if missing, generate via D-75 format and tag with `correlation_id_source: self-generated` (indicates orphan wake worth investigating).
  3. **Memory + state read** , load `.agentbloc/agents/<agent-id>/memory.md` (section-headed per D-64) and `.agentbloc/agents/<agent-id>/state.json` (per D-65) BEFORE any other work; these are the agent's authority on the world.
  4. **Input parse** , trigger-type-specific: cron -> derive input from state.json's `working_state` (e.g., month-to-process, last-processed-ID); webhook -> parse payload per the n8n route's declared schema; inter -> parse incoming SendMessage body per the registry-declared message contract.
  5. **Execute** , load `.claude/skills/<agent-id>/SKILL.md` and proceed per the agent's prompt; include the correlation ID in every log call and in every tool invocation that propagates it (e.g., Telegram messages sent by this agent carry the correlation ID in the message header for human grep).
  6. **State + log write** , write updated state.json + last-run.json + append to the agent's JSONL log line with `correlation_id`, `wake_outcome`, timing. If wake was part of a `TeamCreate` session, emit a `team_session_log` entry to `.agentbloc/runtime/TEAM_SESSIONS.jsonl`.

  **Template anchor points (frozen in runtime-coordination.md):**
  - `{{agent.id}}`, `{{agent.role}}`, `{{agent.autonomy}}` (reflected for the PreToolUse hook integration in Phase 14; Phase 13 passes it through)
  - `{{agent.trigger}}` (one of cron / webhook-<source> / inter / manual)
  - `{{agent.skill_path}}` (`.claude/skills/<agent-id>/SKILL.md` per D-59a)
  - `{{agent.memory_dir}}` (`.agentbloc/agents/<agent-id>/` per D-59b)
  - `{{team.correlation_prefix}}` (defaults to team name; see D-75)
  - `{{payload.schema}}` (webhook template only; empty string for cron/inter)

  Alternatives considered:

  | Option | Description | Selected |
  |---|---|---|
  | A. Single wake.md with `{% if trigger_type == "cron" %}` conditionals | Brittle for same reasons as Phase 12 D-62; Markdown-in-context conditional rendering has nondeterministic token output | |
  | B. One wake.md per agent per trigger source (could be 3-5 files per agent) | Explodes file count (15+ wake.md files for a 3-agent 5-trigger team); hard to audit | |
  | C. Three template variants (cron / webhook / inter) + one dispatcher wake.md per agent that internally routes by env | Deterministic dispatch is fragile; claude -p receives a single prompt; internal routing would require prose-based branching | |
  | D. Three template FILES dispatched by runtime-engine at materialize time; the materialized wake.md is trigger-specific | Deterministic (runtime-engine picks the template and substitutes); audit-friendly (one file per (agent, trigger) pair); scales linearly; templates are pure `{{var}}` substitution | ✓ |

  **Rationale:** D-62 established template-based generation as the deterministic path; D-73 reuses the pattern for wake-jobs. The per-(agent, trigger) file count is bounded by the agent's `triggers[]` array in agent-profiles.yaml , usually 1-3 files per agent, not the feared 5+. Materializing a specific wake.md file per trigger source lets the user visually inspect and manually tweak if they need a custom pre-processing step (e.g., drop payloads from a specific IP range for a webhook). Single-agent workflow bypass (RUNTIME-05) is encoded at template-selection time: cron wake.md invokes the agent directly; inter wake.md invokes TeamCreate only when `registry.runtime.workflow.agents.length > 1`.

#### Event-bus contract + payload schema (resolves RUNTIME-02, RUNTIME-03)

- **D-74 (n8n webhook payload contract is a 4-field JSON envelope consumed by ClaudeClaw jobs; event-source-specific bodies nested under `payload`):** Every n8n webhook that wakes an AgentBloc agent conforms to this envelope:

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
    "payload": { /* event-source-specific body, schema declared in n8n-integration.md */ }
  }
  ```

  The `agent_id` field is the routing key , n8n sets it based on the route's node configuration (one n8n webhook -> one agent by convention; multi-agent fan-out is the ClaudeClaw job's responsibility via TeamCreate). The `correlation_id` is seeded by n8n's Set node when the webhook fires (n8n has a native UUID generator). ClaudeClaw's job endpoint reads the envelope, looks up the agent's `wake-webhook.md.tmpl`, materializes the wake.md with the payload injected into `{{payload.schema}}`, and invokes `claude -p`.

  **Runtime-agnostic fallback:** If ClaudeClaw is not the runtime (plain Claude Code + system cron + n8n), the fallback is: n8n HTTP node POSTs the envelope to a local HTTP listener (e.g., `python -m http.server` wrapper or `claudeclaw webhook --port 8080`); the listener writes the envelope to `.agentbloc/runtime/inbox/<agent-id>/<correlation-id>.json` and invokes `claude -p --payload-file <path> .agentbloc/agents/<agent-id>/wake-webhook.md`. Documented in runtime-coordination.md. This is the D-59a runtime-agnostic principle applied to event wakes.

  **Five worked examples** (from PDF page 5 trigger matrix), each rendered in n8n-integration.md:
  1. Gmail filter -> Gestor Documental (new-invoice-email event)
  2. Plaid webhook -> Gestor Cobros (payment-received event)
  3. Web form submit -> Recepcionista (contact-form-submission event)
  4. Google Calendar watch -> Agente Agenda (calendar-change event) [anticipated agent stub, shipped structurally for Phase 15 continuity]
  5. Telegram message -> Recepcionista (tenant-message event)

  **Rationale:** A thin envelope with a nested event-specific body strikes the balance between "every n8n route looks alike at the ClaudeClaw-boundary layer" (envelope is fixed) and "event semantics are preserved for the agent to act on" (payload is flexible). The `trigger.source` is a bounded enum so downstream analytics (Phase 14 CTRL-02 cost tracking per trigger source) can group cleanly. The four-field envelope matches the shape of v2.0-PROMPT.pdf page 5 "Webhooks y eventos en tiempo real" example flow.

  Alternatives considered:

  | Option | Description | Selected |
  |---|---|---|
  | Bare payload (no envelope) | Each event source has its own shape; ClaudeClaw must understand each | Rejected , no common routing contract; breaks the MCP-first principle |
  | Envelope without correlation_id at the boundary | Correlation ID would be seeded only after ClaudeClaw receives; breaks end-to-end tracing from n8n point-of-entry | Rejected , RUNTIME-06 explicitly requires propagation through the full chain |
  | Full CloudEvents spec envelope | Over-engineered for v2.0; CloudEvents is good for multi-cloud routing, not needed at single-host scale | Deferred to v3.0+ |
  | Four-field thin envelope (schema_version, correlation_id, agent_id, trigger + nested payload) | Minimal routing surface; correlation ID at the boundary; event-specific body intact; payload.schema reference is declared in the agent's n8n-route YAML for validator-free shape checking | ✓ |

#### Correlation-ID format + propagation (resolves RUNTIME-06)

- **D-75 (Correlation-ID format `<trigger-source>-<UTC-Z-compact>-<nonce6>`, trigger-source bounded enum, UTC-Z-compact is ISO-8601 without punctuation, nonce6 is 6 hex chars):** Every wake gets a correlation ID of the form:

  ```
  cron-20260424T090000Z-a3f21b
  webhook-plaid-20260424T091523Z-b8c41e
  webhook-telegram-20260424T092045Z-c7d92a
  inter-20260424T093101Z-f0e82a
  manual-20260424T094512Z-02db9c
  ```

  - **trigger-source enum (bounded):** `cron | webhook-<source> | telegram | inter | manual` (`<source>` is the n8n route's `trigger.source` field; `telegram` is a short alias for `webhook-telegram` when the Telegram message path is used; `inter` is agent-to-agent; `manual` is `claude -p` invoked directly by the user without any trigger system).
  - **timestamp:** ISO-8601 UTC with Z suffix, colons and dashes stripped so the full ID is one shell-safe token (no quoting needed).
  - **nonce6:** 6 hex chars from a cryptographic RNG at ID-generation time. 16^6 = 16.7M collision space per second per source , effectively collision-free at v2.0 scale (≤30 agents, ≤1 wake per second per trigger).
  - **Child propagation (inherited from audit-logging.md):** When agent A spawns child B via SendMessage or sub-session, B's correlation ID is `<parent-id>-sub-<NNN>` where `NNN` zero-padded to 3 digits. Supports up to 999 children per parent , exceeds any realistic fan-out.

  **Propagation mechanism (three channels):**
  1. **Env var:** `claude -p` receives `AGENTBLOC_CORRELATION_ID=<id>`. cron entry sets it via `AGENTBLOC_CORRELATION_ID=$(agentbloc-gen-correlation cron)` (runtime-engine emits a `agentbloc-gen-correlation` shell function / script in `.agentbloc/runtime/helpers.sh`).
  2. **JSON payload:** For webhook triggers, n8n's Set node seeds `correlation_id` into the envelope. The D-74 envelope carries it as a top-level field.
  3. **SendMessage metadata:** ClaudeClaw's `SendMessage` primitive carries a `metadata` field (per ClaudeClaw docs); runtime-coordination.md specifies `metadata.correlation_id` is mandatory for AgentBloc-generated SendMessage calls.

  **Grep recipes (documented in correlation-id.md):**
  ```bash
  # Trace one user event end-to-end:
  grep 'correlation_id":"webhook-plaid-20260424T091523Z-b8c41e' .agentbloc/logs/audit.jsonl

  # List all wakes for a given trigger source on a given day:
  grep 'correlation_id":"webhook-plaid-20260424' .agentbloc/logs/audit.jsonl | jq -r '.agent_id' | sort -u

  # Team session outcome for a correlation ID:
  grep '"correlation_id":"cron-20260424T090000Z-a3f21b"' .agentbloc/runtime/TEAM_SESSIONS.jsonl
  ```

  Alternatives considered:

  | Option | Description | Selected |
  |---|---|---|
  | UUID v4 | Standard but opaque; no grep-readable origin | Rejected , tracing one user event requires looking at every log; too expensive at 30-agent scale |
  | OpenTelemetry trace ID (32-char hex) | Standard for distributed tracing | Deferred , OTEL requires exporters and a collector; out of scope for v2.0 files-first |
  | Hierarchical (`<team>.<agent>.<wake-seq>`) | Readable but monotonic-seq requires coordination | Rejected , seq collision across simultaneous triggers; PDF page 5 does not specify |
  | Trigger-source-prefixed compact ID with UTC-Z + 6-hex nonce (D-75 selected) | Readable origin + collision-free at v2.0 scale + shell-safe + grep-friendly | ✓ |

  **Rationale:** Correlation IDs are debug-first at v2.0 scale. Pablo opens `audit.jsonl` and greps by correlation ID to trace a user event. An opaque UUID forces a lookup table (first glance at event source); a prefixed ID is self-documenting. The 6-hex-nonce length matches collision-free at realistic v2.0 scale without over-engineering. When Phase 14 layers on SQLite + web dashboard (v2.5+), correlation IDs persist as primary keys for cross-day queries; the format is stable.

#### Team coordination + TeamCreate/SendMessage contract (resolves RUNTIME-04, RUNTIME-05)

- **D-76 (Multi-agent workflow invocation pattern: first-agent-detects-need spawns TeamCreate with workflow.agents roster; Single-agent workflow bypass is enforced at wake-template selection, not at runtime):** Per-PDF-page-5 ("El primer agente que detecta que necesita a otro spawna el equipo"). AgentBloc codifies this as:

  1. **Single-agent workflows (RUNTIME-05 bypass):** `registry.runtime.workflows[<workflow-id>].agents.length === 1`. The wake.md template is `wake-job-<trigger-type>.md.tmpl` (cron or webhook); the agent executes directly against its `.claude/skills/<agent-id>/SKILL.md`. NO TeamCreate call. Verified at runtime-engine materialize time (workflow roster is read from registry.yaml; template dispatch is deterministic).
  2. **Multi-agent workflows with known-in-advance agents:** `workflow.agents.length > 1` AND `workflow.spawn_rule: declared`. The first agent in `workflow.agents[]` (the lead per D-23 topology selection) wakes via cron or webhook, immediately issues `TeamCreate(agents=workflow.agents, correlation_id=<ID>)`, and coordinates via `SendMessage` from then on. Team dissolves when every member returns non-continuation output (see D-77).
  3. **Multi-agent workflows with dependency-detection at runtime:** `workflow.spawn_rule: dynamic`. The wake.md template includes a prose step: "if during execution you detect you need agent X (via the `dependencies[]` array in this SKILL.md and the incoming payload shape), call TeamCreate with [self, X, ...transitive deps]." The agent's SKILL.md (Phase 12 D-62 template) already carries the `dependencies` bullet list; runtime-coordination.md adds the TeamCreate invocation template.

  **Dual-path fallback when ClaudeClaw is unavailable:**
  TeamCreate and SendMessage are ClaudeClaw primitives. In a plain-Claude-Code-without-ClaudeClaw runtime (per the D-59a runtime-agnostic principle), AgentBloc degrades to file-based coordination:
  - **writeStateHandoff:** Agent A writes the SendMessage body to `.agentbloc/agents/<agent-b>/inbox/<correlation-id>.json`, then invokes `claude -p --payload-file <path> .agentbloc/agents/<agent-b>/wake-inter.md` as a foreground subprocess. Agent B wakes, reads inbox, processes, writes response to `.agentbloc/agents/<agent-a>/inbox/<correlation-id>-reply.json`, exits. Agent A resumes.
  - **teamCreate fallback:** Spawn each agent as a sequential `claude -p` process with a shared correlation ID. Parallelism is lost; correctness is preserved.
  - The fallback is slower (no concurrency, file-system roundtrips) but works on any machine. runtime-coordination.md documents both paths with a `prefer: claudeclaw` hint and a `fallback: writeStateHandoff` field in registry.runtime.

  **Team dissolution:**
  A team dissolves when:
  - Every member agent has returned a non-continuation output (the wake.md's final state.json write indicates task completion)
  - KILL_SWITCH is activated (D-77 below)
  - The team's correlation-ID-scoped timeout expires (default 15 minutes; configurable in registry.runtime.team_timeout_minutes)
  - An unrecoverable error occurs in any member (team-wide halt; the failure is logged with the correlation ID and bubbled to the lead for escalation per v1.0 SECR escalation)

  Alternatives considered:

  | Option | Description | Selected |
  |---|---|---|
  | Always use TeamCreate | Single-agent workflows pay TeamCreate overhead for no benefit; violates RUNTIME-05 | Rejected |
  | Never use TeamCreate (serial claude -p chain) | Loses ClaudeClaw parallelism + SendMessage efficiency | Rejected |
  | Lead-only TeamCreate (lead wakes, lead spawns team always) | Inflexible for event-driven wakes where the waker is not the lead | Rejected |
  | First-agent-detects pattern with template-level single-agent bypass (D-76 selected) | Honors PDF-page-5 "first agent spawns team"; single-agent workflows pay zero overhead; dependency-detection pattern supports dynamic fan-out | ✓ |

  **Rationale:** PDF page 5 is explicit: "El primer agente que detecta que necesita a otro spawna el equipo." AgentBloc honors this verbatim for dynamic cases (dependency-detection at runtime) and adds a static-roster shortcut for cases where Designer Agent already declared the team in `workflow.agents[]`. Template-level bypass (runtime-engine chooses the wake.md template) is the cleanest enforcement of RUNTIME-05 , no runtime check needed.

#### Kill-switch runtime semantics (resolves RUNTIME-07)

- **D-77 (Kill-switch is checked at 3 points per agent wake: (1) top of wake.md before any reads, (2) before every side-effect tool call via PreToolUse hook, (3) at every state transition within a TeamCreate session; Telegram /stop activates the file-based kill-switch via n8n route; team-wide halt dissolves all active TeamCreate sessions at the next safe transition):** Three-point enforcement:

  1. **Wake-time check (new in Phase 13):** Every wake.md starts with:
     ```markdown
     ## 1. Kill-switch pre-check

     Check if `.agentbloc/KILL_SWITCH` exists.
     - If YES: Append to `.agentbloc/logs/audit.jsonl`: `{"correlation_id":"<ID>","event":"halted-kill-switch","agent_id":"<agent-id>","wake_at":"<ISO>"}`. EXIT IMMEDIATELY. Do not read state, do not call tools, do not emit Telegram.
     - If NO: Continue to step 2 (correlation-ID ingest).
     ```
  2. **Side-effect tool pre-check (existing in phase-5-deployment.md; Phase 13 confirms runtime integration):** The PreToolUse hook at `.claude/hooks/kill-switch-check.sh` (generated by Phase 12 deploy-engine; already documented in phase-5-deployment.md line 1109-1120) checks the file on every tool call, blocking with `permissionDecision: deny` if active. Phase 13 does NOT regenerate this hook; it is already emitted by Phase 12.
  3. **Team-transition check (new in Phase 13):** Inside a TeamCreate session, every agent checks the kill-switch before SendMessage send AND before SendMessage consume. If active, the agent returns `{status: halted-kill-switch}` and the team lead dissolves the team (TeamCreate explicit teardown). Logged to `.agentbloc/runtime/TEAM_SESSIONS.jsonl` with `dissolution_reason: kill-switch`.

  **Telegram /stop remote path (existing in incident-response.md; Phase 13 wires the n8n route):**
  Phase 13 emits an n8n route stub at `.agentbloc/runtime/n8n-routes/agentbloc-stop.yaml` that listens for `/stop` in the configured Telegram operations thread and runs `touch .agentbloc/KILL_SWITCH` via a shell node. A sibling route `agentbloc-resume.yaml` runs `rm .agentbloc/KILL_SWITCH` on `/resume`. Both are user-installable into the user's n8n instance. incident-response.md already covers the behavior; Phase 13 ships the route YAML stubs so the user does not have to hand-author them.

  **Team-wide halt discipline:**
  KILL_SWITCH activation mid-team does NOT interrupt the current prose execution of a given agent (Claude Code has no generic-interrupt primitive at the prose level). Instead, each agent checks the switch at every state transition (SendMessage send/consume boundaries) and returns cleanly. The team lead detects at least one `halted-kill-switch` reply and dissolves the team. Worst-case latency: one SendMessage round-trip (typically <5 seconds for simple messages). This is acceptable because KILL_SWITCH is a "halt before more damage" signal, not a "stop mid-sentence" signal.

  Alternatives considered:

  | Option | Description | Selected |
  |---|---|---|
  | Wake-time check only | Long-running agents continue after KILL_SWITCH activated mid-run | Rejected , v1.0 SECR-05 already requires per-tool check |
  | Per-tool-check only | Agents already past their last tool call continue; misses the "don't wake the next agent in the pipeline" case | Rejected , RUNTIME-07 explicitly requires team-wide halt |
  | Three-point enforcement (wake + tool + team transition) | Covers all realistic windows; adds <50ms overhead per agent wake | ✓ |
  | Async interrupt (SIGTERM + graceful shutdown) | Requires process-level control; ClaudeClaw may not propagate signals through `claude -p` cleanly; brittle across runtimes | Rejected for v2.0 |

  **Rationale:** Three-point enforcement is the minimum that satisfies RUNTIME-07 AND inherits v1.0 SECR-05. Wake-time check prevents new damage. Per-tool check (Phase 12 artifact) prevents in-flight damage. Team-transition check prevents multi-agent cascades. The Telegram-triggered n8n route is the remote-friendly path already documented in incident-response.md; Phase 13 just emits the YAML stub so the user does not recreate it from scratch.

#### Registry runtime block (resolves RUNTIME registry needs, extends DEPLOY-05)

- **D-78 (Registry gains a top-level `runtime` block, additive to Phase 12 D-63 schema):** `.agentbloc/agents/registry.yaml` is extended with:

  ```yaml
  # schema_version: 1 (unchanged from Phase 12 D-63)
  # team: ... (unchanged)
  # agents: [...] (unchanged)
  # reporting_hierarchy: ... (unchanged, Phase 14 consumes)
  # dashboard_agent: ... (unchanged, v2.5+ consumes)

  runtime:
    schema_version: 1                              # independent of registry top-level version
    correlation_prefix: "<team-name>"              # overrides default (team.name) if set
    team_timeout_minutes: 15                       # TeamCreate session timeout
    coordination_preference:                        # per D-76 dual-path
      prefer: "claudeclaw"                         # or "writeStateHandoff"
      fallback: "writeStateHandoff"
    cron_registered_at: "<ISO-8601 | null>"        # null until runtime-engine applies the crontab
    crontab_manifest: ".agentbloc/runtime/crontab.applied"
    workflows:                                     # keyed by workflow.id from Phase 9 agent-profiles.yaml
      <workflow-id>:
        agents: [<agent-id>, ...]                  # denormalized from agent-profiles.yaml for runtime scan
        spawn_rule: "declared | dynamic"           # per D-76
        trigger:
          type: "cron | webhook | inter | manual"
          schedule: "<cron expression>"            # if type=cron
          webhook_route: ".agentbloc/runtime/n8n-routes/<agent-id>.yaml"  # if type=webhook
          inter_caller: "<agent-id>"               # if type=inter
    webhook_endpoints:                             # denormalized from n8n-routes/ for quick scan
      - agent_id: "<agent-id>"
        source: "gmail | plaid | ..."
        event_name: "<event name>"
        route_file: ".agentbloc/runtime/n8n-routes/<agent-id>.yaml"
        evidence:
          verified_at: "<ISO-8601 | null>"          # null until user confirms route is live
  ```

  Additive change: Phase 12 deploy-engine does not touch the `runtime` block; runtime-engine populates it. If runtime-engine runs before deploy-engine (wrong order), it HALTS with a named report pointing to the missing `team` block. Phase 5 deploy-engine -> runtime-engine ordering is the only correct invocation sequence; codified in deploy-protocol.md Step 7.

  **Rationale:** Co-locating runtime metadata with the agent roster keeps a single source of truth for "what exists + how it wakes + where it coordinates". Denormalization of workflow.agents and webhook routes into the registry avoids cross-file lookups at runtime-engine materialize time (registry.yaml becomes the single file any runtime-observer reads). The `evidence.verified_at: null` convention mirrors Phase 10 D-39 `[UNVERIFIED]` flagging , n8n routes are generally internal-network endpoints Phase 13 cannot auto-ping.

#### Example fixture structure (resolves validation + golden-file testing)

- **D-79 (Arco Rooms canonical runtime fixture ships as two companion example files, mirroring Phase 11 + Phase 12 fixture pattern):** The v2.0 canonical test case is Arco Rooms (3 requested agents: Gestor Cobros, Recepcionista, Gestor Documental; 2 anticipated in Phase 15). Phase 13 ships two example files:

  1. `.claude/skills/agentbloc/examples/arco-rooms-correlation-flow.md` , narrative walkthrough of 3 scenarios:
     - **Scenario A (cron wake):** 1st of month at 09:00 Europe/Madrid, Gestor Cobros wakes via cron, correlation ID `cron-20260501T080000Z-<nonce>` (UTC = 08:00 Z for CEST). Shows wake.md execution, state read, BBVA MCP payment check, Telegram message to tenant with correlation ID in header, log line.
     - **Scenario B (webhook + SendMessage):** Telegram tenant sends "Cuando vence mi contrato?" , n8n Telegram route -> webhook wake -> Recepcionista wakes with `webhook-telegram-20260504T143212Z-<nonce>`. Recepcionista detects it needs payment status (dependency: gestor-cobros), calls TeamCreate([recepcionista, gestor-cobros]). Gestor Cobros receives SendMessage with `correlation_id: webhook-telegram-20260504T143212Z-<nonce>-sub-001`. Both return outputs; team dissolves. Log shows all entries grep-able by the parent correlation ID.
     - **Scenario C (KILL_SWITCH mid-team):** Scenario B in progress; operator types `/stop` in Telegram ops thread; n8n route fires `touch .agentbloc/KILL_SWITCH`; Recepcionista checks switch before next SendMessage send, returns `halted-kill-switch`; Gestor Cobros (receiving) checks switch before consume, also returns halt; team lead dissolves team; log shows `dissolution_reason: kill-switch` with the shared correlation ID.

  2. `.claude/skills/agentbloc/examples/arco-rooms-runtime-artifacts.md` , structural fixture showing literal file contents:
     - 3x wake.md files (cron for Gestor Cobros; webhook-telegram for Recepcionista; inter for both when team forms)
     - 1x `crontab.applied` manifest with entries for Gestor Cobros monthly cron + Gestor Documental weekly cron (anticipated) + Recepcionista NO cron (webhook-only)
     - 3x n8n route YAML stubs (telegram for Recepcionista, gmail for Gestor Documental, plaid for Gestor Cobros , even though Gestor Cobros is primarily cron, he also wakes on Plaid payment-received events per PDF page 3)
     - 1x extended registry.yaml with the full `runtime` block

  Alternatives considered:

  | Option | Description | Selected |
  |---|---|---|
  | One fixture file with all content | Too long (est >1000 lines); hard to audit individual artifact shape | Rejected |
  | Three fixtures (flow narrative + artifacts + failure modes) | Adequate coverage but third file (failure modes) duplicates Scenario C in flow narrative | Rejected as triplicate |
  | Two fixtures (narrative flow + structural artifacts) | Phase 11 + Phase 12 both ship 1-2 examples; two-file pattern is the established fixture cadence; clean separation of "how it behaves" (narrative) vs "what it looks like" (artifacts) | ✓ |
  | Zero fixtures (reference-docs-only) | Phase 16 validation cannot cite canonical flows; Designer Agent cannot generate similar fixtures for other business domains without a reference | Rejected |

  **Rationale:** Two fixtures match the cadence of Phase 11 (mapfre-discovery-report fixture) and Phase 12 (arco-rooms-deploy-report + arco-rooms-registry fixtures). The narrative fixture is the Phase 16 golden-file reference; the structural fixture is the Phase 16 artifact-shape reference. Designer Agent (Phase 15 anticipation) and future cross-domain validation both read these when proposing similar patterns for new business types.

#### runtime-engine subagent scope + Bash allow-list

- **D-80 (runtime-engine subagent: `.claude/agents/runtime-engine.md`, `context: fork`, tools Read/Grep/Glob/Write/Edit + narrowed Bash allow-list; parallels Phase 12 deploy-engine):** runtime-engine runs as the final step of `deploy-protocol.md` (after deploy-engine completes successfully). Responsibilities:

  1. Read `.agentbloc/agents/registry.yaml` (Phase 12 output) and `.agentbloc/team/agent-profiles.yaml` (Phase 9 output) and `.agentbloc/deploy/crontab.proposed` (Phase 12 output).
  2. For each agent in registry, materialize wake.md files by dispatching on trigger type (cron / webhook / inter); use the 3 template variants per D-73.
  3. Emit n8n route YAML stubs per webhook trigger at `.agentbloc/runtime/n8n-routes/<agent-id>.yaml`.
  4. Diff `.agentbloc/deploy/crontab.proposed` against current `crontab -l`; if non-empty diff, present to user; on approval, install via `crontab -e` scripting (echo new content; validate; install).
  5. Write `.agentbloc/runtime/crontab.applied` manifest with SHA256 fingerprint.
  6. Extend `.agentbloc/agents/registry.yaml` with the `runtime` block per D-78.
  7. Emit `.agentbloc/runtime/RUNTIME-REPORT.md` summarizing wake.md files emitted, crontab entries applied, n8n routes stubbed, evidence table for user to follow up on.
  8. On any failure: emit `.agentbloc/runtime/RUNTIME-FAILED-REPORT.md` per D-35/D-71 halt-and-name discipline.

  **Tool scope (written into the subagent's `<write_constraint>` XML block):**
  - **Read, Grep, Glob:** unrestricted within project root.
  - **Write:** ONLY to `.agentbloc/agents/<agent-id>/wake*.md`, `.agentbloc/runtime/**`, `.agentbloc/agents/registry.yaml` (Edit path), `.agentbloc/logs/audit.jsonl` (append).
  - **Edit:** ONLY to `.agentbloc/agents/registry.yaml` (adding `runtime` block), `.agentbloc/deploy/DEPLOY-REPORT.md` (adding runtime-wiring section reference if deploy-engine's report exists).
  - **Bash narrow allow-list:** `crontab -e`, `crontab -l`, `shasum -a 256`, `claude agents list`, `claude mcp list`. NO `bash -c`, NO `sh`, NO `curl`, NO `rm -rf`, NO wildcards. Every invocation must match one of these 5 command prefixes exactly.
  - **NO WebFetch, NO WebSearch, NO other MCPs.**

  Alternatives considered:

  | Option | Description | Selected |
  |---|---|---|
  | One mega-subagent (deploy + runtime combined) | Overloads context; Phase 12 deploy-engine is already 200+ lines; merging would exceed the context budget | Rejected |
  | Inline runtime logic in deploy-engine | Deploy-engine would need to handle 2 distinct responsibilities (artifact emission vs runtime wiring); violates D-31 concern-separation | Rejected |
  | Separate runtime-engine subagent invoked by deploy-protocol after deploy-engine | Clean separation; context: fork keeps each subagent's working memory clean; matches Phase 9/11/12 pattern | ✓ |
  | Runtime logic as a skill, not subagent | Skills are for user-facing conversational flows (like agentbloc itself); subagents are for autonomous tool-using agents; runtime-engine mutates crontab (autonomous tool usage) so subagent fits | Rejected |

  **Rationale:** Matches the established subagent pattern (designer-agent Phase 9, browser-discovery Phase 11, deploy-engine Phase 12). Narrowed Bash allow-list is stricter than deploy-engine's because runtime-engine mutates system-level state (crontab); every Bash invocation must be an exact-match prefix. This minimizes the blast radius if the runtime-engine's prose gets subverted (prompt injection via a malicious webhook payload that lands in n8n-route stub content).

#### Phase transition invocation + state gate

- **D-81 (New sub-gate `runtime_wired` joins Phase 5 State Transitions; Phase 6 Evolution precondition extends to verify it):** Phase 5 gate transition to `approved` gains a new sub-gate per the Phase 12 pattern. Current Phase 5 gate requires `deployment_artifacts_emitted` (Phase 12 D-55-ish). Phase 13 adds `runtime_wired` ANDed into the gate: after deploy-engine emits DEPLOY-REPORT.md, runtime-engine must emit RUNTIME-REPORT.md with all agents having at least one trigger path wired (cron, webhook, or inter). Phase 6 Evolution precondition extends: "Verify `registry.yaml runtime.cron_registered_at` is non-null OR `runtime.webhook_endpoints` is non-empty (or both); if neither, return Phase 5 with gate `pending` and re-run deploy-protocol Step 7."

  **State Transition prose update (SKILL.md line 43-ish pattern):**
  ```
  Phase 5 specific: Gate transition to approved requires BOTH the `deployment_artifacts_emitted` sub-gate
  (Phase 12; DEPLOY-REPORT.md written) AND the `runtime_wired` sub-gate (Phase 13; RUNTIME-REPORT.md
  written with at least one trigger path per agent). If RUNTIME-FAILED-REPORT.md is emitted instead,
  `runtime_wired` is false; Phase 6 Evolution entry halts and surfaces the failed report.
  ```

  **Rationale:** Same pattern as Phase 12 D-55-ish sub-gate. Additive; does not break Phase 12 behavior when Phase 13 has not executed (the absence of RUNTIME-REPORT.md is treated as "Phase 5 not yet complete" by Phase 6 precondition, identical to DEPLOY-REPORT.md absence).

#### References to inherit + references to add

- **D-82 (Reference-file inventory for Phase 13 , 3 new references + 1 template + 2 example fixtures + 1 subagent, with concrete line budgets mirroring Phase 11/12 patterns):**

  | File | Type | Purpose | Est. lines | Parallels |
  |------|------|---------|-----------|-----------|
  | `references/n8n-integration.md` | new reference | Webhook payload envelope (D-74) + 5 worked examples + n8n route YAML schema + runtime-agnostic fallback | 180-220 | mcp-integration-protocol.md |
  | `references/runtime-coordination.md` | new reference | TeamCreate/SendMessage primitives + topology-to-primitive mapping + writeStateHandoff fallback + workflow.spawn_rule enum | 180-220 | browser-fallback.md |
  | `references/correlation-id.md` | new reference | Format spec (D-75) + propagation channels + grep recipes + sub-ID convention | 120-150 | audit-logging.md |
  | `templates/wake-job-cron.md.tmpl` | new template | Cron-trigger wake template (D-73 6 sections, pure `{{var}}` substitution) | 80-100 | deployed-agent-skill.md.tmpl |
  | `templates/wake-job-webhook.md.tmpl` | new template | Webhook-trigger wake template | 80-100 | deployed-agent-skill.md.tmpl |
  | `templates/wake-job-inter.md.tmpl` | new template | Inter-agent wake template | 80-100 | deployed-agent-skill.md.tmpl |
  | `examples/arco-rooms-correlation-flow.md` | new fixture | 3-scenario narrative walkthrough (D-79) | 180-240 | mapfre-discovery-report.md + arco-rooms-deploy-report.md |
  | `examples/arco-rooms-runtime-artifacts.md` | new fixture | Literal wake.md / crontab / n8n-route / extended registry artifacts (D-79) | 200-280 | arco-rooms-registry.yaml |
  | `.claude/agents/runtime-engine.md` | new subagent | Phase 5 runtime wiring subagent (D-80) | 160-210 | deploy-engine.md, browser-discovery.md, designer-agent.md |

  | File | Type | Surgical edit scope |
  |------|------|---------------------|
  | `references/deploy-protocol.md` | existing | Insert Step 7 (Runtime Wiring) between current Step 6 and Step 8-equivalent reporting; 2 See-lines + 1 paragraph; ~25 added lines |
  | `references/phase-5-deployment.md` | existing | Insert Step 7.5 (Runtime Wiring hand-off between deploy-engine and runtime-engine); 2 See-lines + 1 paragraph; ~20 added lines |
  | `references/incident-response.md` | existing | Append Runtime Kill-Switch Semantics section (wake-time + team-transition checks); 1 new H2 + ~15 lines of prose + 1 example block; ~25 added lines |
  | `SKILL.md` | existing | Phase 5 entry: 3 See-lines (runtime-coordination + n8n-integration + correlation-id); Phase 5 State Transitions paragraph extension (D-81 prose); Phase 6 precondition extension; ~20 added lines |

  **SKILL.md line budget after Phase 13:** current ~183 lines + ~20 added = ~203 lines. Under the 250-line cap per D-29 (Phase 9) with ~47 lines of headroom for Phase 14 + Phase 15 future additions.

  **Rationale:** Inventory mirrors Phase 11 + Phase 12 cadence (3 new references + new templates + examples + new subagent + ~4 surgical edits). The line budgets are set at ~80% of Phase 12's comparable files as a calibrated estimate , Phase 12's deploy-protocol is 290 lines; Phase 13's runtime-coordination at 180-220 is appropriately lighter because runtime is a thinner layer on top of ClaudeClaw primitives. The 3-template split for wake.md is the most load-bearing single decision (D-73); its rationale is exhaustively documented above.

#### Plan structure + execution order

- **D-83 (3 plans , matching ROADMAP estimate of 3 , following Phase 11/12 cadence):** Phase 13 breaks into 3 plans:

  1. **Plan 13-01 , Contracts + fixtures** (parallel to Phase 11 Plan 1 / Phase 12 Plan 1):
     - Create 3 new references (n8n-integration.md + runtime-coordination.md + correlation-id.md)
     - Create 3 new templates (wake-job-cron/webhook/inter.md.tmpl)
     - Create 2 new fixtures (arco-rooms-correlation-flow.md + arco-rooms-runtime-artifacts.md)
     - Est. 8 files, pure Write operations, no subagent invocation, ~1,200 lines total
     - Dependencies: Phase 12 complete (done); agent-profile-schema, integration-manifest-schema, deploy-protocol all read-only

  2. **Plan 13-02 , runtime-engine subagent** (parallel to Phase 9 Plan 2 / Phase 11 Plan 3 / Phase 12 Plan 2):
     - Create `.claude/agents/runtime-engine.md` per D-80
     - Context: fork, scoped tools, narrowed Bash allow-list, `<write_constraint>` XML block
     - Est. 1 file, ~180 lines
     - Dependencies: Plan 13-01 complete (subagent cites the 3 new references)

  3. **Plan 13-03 , Surgical wiring** (parallel to Phase 9 Plan 3 / Phase 11 Plan 4 / Phase 12 Plan 3):
     - Surgical edits to deploy-protocol.md (Step 7 insertion)
     - Surgical edits to phase-5-deployment.md (Step 7.5 insertion)
     - Surgical edits to incident-response.md (Runtime Kill-Switch Semantics section)
     - Surgical edits to SKILL.md (3 See-lines + State Transitions + Phase 6 precondition)
     - Est. 4 files modified, ~90 lines added total
     - Dependencies: Plan 13-01 + 13-02 complete (wiring cites the new references and the subagent)

  Sequential execution (main-tree, no worktree per gsd_executor_sandbox lesson): 13-01 -> 13-02 -> 13-03. No parallel waves within Phase 13; each plan's output is consumed by the next. Plan 13-01 can spawn sub-tasks (one per file) but they run sequentially within the plan because they cross-reference each other (n8n-integration.md cites correlation-id.md; runtime-coordination.md cites n8n-integration.md).

  **Rationale:** Matches the Phase 9/11/12 pattern of "contracts + subagent + wiring" three-plan decomposition. Keeps per-plan scope manageable (~1,200 / 180 / 90 lines respectively, under the gsd-executor per-plan token ceiling). The 3-plan breakdown aligns with ROADMAP "Plans (est): 2-3" , lands at the upper bound because Phase 13 has a new subagent plus 3 references (not just 1-2), and the 3-template split cannot be merged into a single file per D-73.

### Claude's Discretion

During plan-phase and execution, Claude decides without re-asking:
- Exact wake.md template section wording and anchor-point naming consistency (following D-62 / D-73 discipline); may tune anchor-point names for readability as long as the 6-section structure is preserved
- n8n-integration.md worked-example selection order and verbosity (the 5 examples from PDF page 5 are mandatory; additional illustrative examples are discretionary)
- correlation-id.md grep recipe examples (minimum 3 recipes; more at discretion based on what readers would plausibly ask)
- runtime-engine subagent's exact Bash allow-list verbification wording (the 5-command list is locked per D-80; the prose around it is discretionary)
- RUNTIME-REPORT.md template structure (must include: agents, trigger paths per agent, crontab diff, n8n routes emitted, evidence table; beyond that discretionary)
- Example fixture scenario length (Scenario A/B/C outline is locked per D-79; word count and illustrative dialogue depth are discretionary)
- Whether to include or defer a 6th reference covering runtime observability primitives (currently folded into runtime-coordination.md; may split if reference exceeds 220 lines during execution)
- Inclusion order of Phase 13 See-lines in SKILL.md (alphabetical vs reading-order); Phase 12 chose alphabetical

### Folded Todos

None identified. No pending todos in `.planning/` that match Phase 13 scope (v2.0 Phase 13 was anticipated in STATE.md blockers / carry-forward section, not in a standalone todo file).

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Authoritative scope document

- `.planning/v2.0-PROMPT.pdf` , Phase 5 "Runtime y Gestión Multi-Agente" section (page 5) defines the trigger matrix (cron / n8n webhook / Telegram / inter-agent SendMessage); Stack Decisions section (page 7-8) locks ClaudeClaw + n8n + Claude Code as the runtime substrate. MUST READ for every plan; the source of truth for what Phase 13 must deliver.

### Requirements

- `.planning/REQUIREMENTS.md` §Multi-Agent Runtime (RUNTIME) , 7 requirements RUNTIME-01..07 are the acceptance criteria. Each plan MUST cite which requirement(s) it closes.
- `.planning/ROADMAP.md` §Phase 13: Multi-Agent Runtime , 5 success criteria (SC1-SC5) from ROADMAP line 149-154. Verification phase cross-checks these.

### Prior-phase context (do not re-read in full, but referenced when conflicts arise)

- `.planning/phases/12-deploy-pipeline-agent-memory/12-CONTEXT.md` , Phase 12 decisions D-59a/b/c triple-override, D-60 RFC 8785 canonicalization, D-62 three-template split, D-63 registry format, D-66 .mcp.json merge, D-67 narrow Bash, D-70 canonical tools/list, D-71 halt-and-name. Phase 13 inherits all.
- `.planning/phases/11-integration-discovery-browser-fallback/11-CONTEXT.md` , Phase 11 decisions D-35 halt-and-name, D-45 SHA256 fingerprint, D-46 append-only JSONL ledger. Phase 13 inherits all.
- `.planning/phases/09-designer-agent/09-CONTEXT.md` , Phase 9 decisions D-21 context:fork + scoped tools, D-23 mesh default, D-24 ADK vocabulary, D-29 SKILL.md budget. Phase 13 inherits all.

### Existing references consumed at plan time

- `.claude/skills/agentbloc/references/scheduling.md` (131 lines, v1.0) , cron expression format, DST safety (avoid 01:00-03:00), pipeline spacing (30-min gaps), production deployment (system cron + `claude -p`). Phase 13 runtime-coordination.md cross-references pipeline spacing; wake-job-cron template cites DST safety.
- `.claude/skills/agentbloc/references/telegram-patterns.md` (164 lines, v1.0) , thread-per-domain convention, notification tiers, approval-by-reply pattern, voice-message support, bot-setup requirements. Phase 13 n8n-integration.md cites Telegram route specifically for the /stop remote kill-switch trigger.
- `.claude/skills/agentbloc/references/audit-logging.md` , correlation-ID pattern `sess-<agent>-<NNN>` with `-sub-<NNN>` child. Phase 13 correlation-id.md extends this with trigger-source prefix (D-75); sub-ID convention is inherited verbatim.
- `.claude/skills/agentbloc/references/incident-response.md` , dual-path kill-switch (file-based + Telegram /stop). Phase 13 extends with Runtime Kill-Switch Semantics section (wake-time + team-transition checks per D-77); path mechanism unchanged.
- `.claude/skills/agentbloc/references/phase-5-deployment.md` (1358 lines, v1.0 + Phase 12 edits) , kill-switch documentation (lines 100-120), crontab template (lines 780-790), job definition template (lines 730-770). Phase 13 Step 7.5 insertion cites lines 700-790 for consistency.
- `.claude/skills/agentbloc/references/deploy-protocol.md` (290 lines, Phase 12 artifact) , 6-step deploy flow with 3-check verification. Phase 13 Step 7 insertion (Runtime Wiring) lands between verification and reporting; cites the three-check verification as precondition for runtime wiring.
- `.claude/skills/agentbloc/references/orchestration-patterns.md` (121 lines, Phase 9) , 5-pattern table (Sequential / Parallel / Loop / Event-driven / Conversational) with topology decision matrix. Phase 13 runtime-coordination.md cites pattern-to-primitive mapping.
- `.claude/skills/agentbloc/references/agent-profile-schema.md` (Phase 9) , `triggers[]` array with type enum (cron / event / inter-agent); `dependencies[]` for inter-agent SendMessage targets; `topology` enum (pipeline / mesh / hierarchy / swarm). Phase 13 wake-job templates read these fields for dispatch; runtime-coordination.md cites the topology enum for primitive mapping.
- `.claude/skills/agentbloc/references/agent-memory-schema.md` (Phase 12) , section-headed memory.md template, flat state.json schema, last-run.json log-entry shape. Phase 13 wake-job templates cite the schema for step 3 (memory + state read) and step 6 (state + log write).
- `.claude/skills/agentbloc/references/integration-manifest-schema.md` (Phase 10) , MCP tool entries consumed by deployed SKILL.md files. Phase 13 does NOT mutate this; n8n routes (for webhook triggers) are a SEPARATE runtime concern not a tool integration (no MCP). n8n-integration.md explicitly disambiguates.

### Existing subagents consumed as pattern references

- `.claude/agents/deploy-engine.md` (Phase 12) , context: fork + scoped tools + narrowed Bash. Phase 13 runtime-engine mirrors structure; Bash allow-list is tighter (crontab mutations).
- `.claude/agents/designer-agent.md` (Phase 9) , context: fork, NO Bash. Phase 13 runtime-engine is NOT a read-only design subagent; Bash is required for crontab.
- `.claude/agents/browser-discovery.md` (Phase 11) , 6-XML-block structure with checkpoint_resume, write_constraint, heartbeat. Phase 13 runtime-engine has simpler structure (no checkpointing: wake wiring is atomic) but adopts the write_constraint XML block pattern verbatim.

### SKILL.md + main-skill integration

- `.claude/skills/agentbloc/SKILL.md` (183 lines post-Phase 12) , Phase 5 entry currently loads phase-5-deployment + deploy-protocol. Phase 13 surgical edit adds 3 See-lines (n8n-integration, runtime-coordination, correlation-id), 1 State Transitions prose update (D-81), 1 Phase 6 precondition extension. Exact edit boundaries specified in D-83 Plan 13-03.

### n8n + ClaudeClaw primitive documentation (external)

- Per PROJECT.md Constraints: ClaudeClaw provides `Agent` / `TeamCreate` / `SendMessage` / Jobs / Telegram / hooks / skills system. Phase 13 treats these as external primitives; no re-implementation. No URL cited in this CONTEXT.md , the primitives are treated as established infrastructure per the AgentBloc-inside-ClaudeClaw mental model. If runtime-engine implementation discovers primitive signatures differ from assumed (`TeamCreate(agents=[...], correlation_id=<ID>)`), replan.
- n8n documentation (https://docs.n8n.io) , HTTP Request node + webhook node + Set node (for correlation-ID seeding). Linked from n8n-integration.md worked examples.

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets

- **3 existing subagent blueprints** (`.claude/agents/{designer-agent, browser-discovery, deploy-engine}.md`) , runtime-engine inherits structure (context: fork, XML-fenced sections, write_constraint block). Pattern is mature; Phase 13 adds a 4th subagent without architectural change.
- **scheduling.md** already documents cron + DST + pipeline spacing , runtime-coordination.md cites specific line ranges; no duplication.
- **audit-logging.md** already documents `correlation_id` field + `sess-<agent>-<NNN>` pattern + sub-agent child rule , correlation-id.md extends without rewriting.
- **incident-response.md** already documents dual-path kill switch (file + Telegram /stop) + PreToolUse hook template , Phase 13 extends with runtime semantics, not with a new file.
- **`.agentbloc/` customer-state namespace** already established by Phase 11 (discovery/) + Phase 12 (agents/, deploy/) , Phase 13 extends with `.agentbloc/runtime/` for crontab-applied manifest + n8n-routes + RUNTIME-REPORT.md. Namespace hygiene preserved.
- **Phase 12 `.agentbloc/deploy/crontab.proposed`** , Phase 12 already emits this file; Phase 13 consumes it. Phase 12 design explicitly anticipated Phase 13 as the consumer (see Phase 12 D-70 Check 3 "In Phase 12-only execution before Phase 13 lands, Check 3 soft-fails with note 'Phase 13 not yet executed; cron verification skipped.'"). Load-bearing precedent.
- **Phase 12 registry.yaml** , schema_version: 1 is stable; Phase 13 adds `runtime` top-level block without bumping version (additive change). D-78 codifies.
- **Phase 12 deploy-engine's Bash allow-list** (`crontab -l`, `shasum -a 256`, `claude agents list`, `claude mcp list`) , runtime-engine adopts verbatim + adds `crontab -e`. The verification-read commands are shared; the mutation command (`crontab -e`) is unique to runtime-engine per D-80.

### Established Patterns

- **Surgical edit discipline for existing references** (D-40 Phase 10; D-73 Phase 12; D-83 Phase 13) , Phase 13 touches 3 existing references with clearly bounded insertion points. No refactoring; no content rewriting.
- **Three-plan cadence** (Phase 9 / Phase 11 4-plans / Phase 12 3-plans) , Phase 13 lands at 3 plans matching ROADMAP upper bound (2-3).
- **Plan-task atomic commits per gsd_executor discipline** , each plan's tasks commit individually; phase-close commit at end after verification.
- **Halt-and-name on any runtime-wire failure** (D-71 Phase 12 -> D-35 Phase 10) , RUNTIME-FAILED-REPORT.md is the named twin of DEPLOY-FAILED-REPORT.md and DISCOVERY-BLOCKED-REPORT.md.
- **Three-tier obligation marking** (REQUIRED / RECOMMENDED / OPTIONAL) in schemas , applied to n8n-integration.md payload schema, correlation-id.md format spec, runtime registry block.
- **Em-dashes absent from emitted prose per Phase 11 commit 73a21a4 precedent** , Phase 13 prose will use "--" or plain text substitutes; grep -c "—" across emitted files is the gate (0 matches required, matching Phase 12 commit 0ab97cd).

### Integration Points

- **deploy-protocol.md Step 7 insertion** , new step lands between existing Step 6 (verification) and Step 8-equivalent (reporting). Insertion boundary: after verification prose, before DEPLOY-REPORT.md emission. deploy-engine's post-deploy step ends with "invoke runtime-engine subagent with the emitted registry.yaml + crontab.proposed as inputs."
- **phase-5-deployment.md Step 7.5 insertion** , new subsection lands after Step 7 (Job Definition Template, line 728-ish) and before Step 8 (SUMMARY.md Deployment Guide Template, line 840-ish). Hand-off prose: "After deploy-engine emits DEPLOY-REPORT.md, control hands to runtime-engine (Phase 13) which materializes the wake.md templates + installs the crontab + emits n8n route YAML stubs. See references/runtime-coordination.md."
- **incident-response.md Runtime Kill-Switch Semantics section insertion** , new H2 at the end of the file (after existing sections). Cites D-77 three-point enforcement; cites the n8n Telegram /stop route YAML in `.agentbloc/runtime/n8n-routes/agentbloc-stop.yaml` (new file emitted by runtime-engine).
- **SKILL.md Phase 5 entry** , 3 See-lines insert below existing Phase 5 See-lines (runtime-coordination + n8n-integration + correlation-id). State Transitions paragraph for Phase 5 gets the D-81 prose extension. Phase 6 precondition paragraph gets 1 additional sentence.
- **registry.yaml schema** , additive `runtime` top-level block per D-78. No migration for Phase 12 registry instances (treat absence of `runtime` block as "Phase 13 not yet run" marker).

</code_context>

<specifics>
## Specific Ideas

- **"Mobile-first debugging"** , correlation IDs must be grep-readable in a Telegram message bubble on phone. D-75 format `cron-20260424T090000Z-a3f21b` is 28 chars; fits in a Telegram reply preview line.
- **"Deterministic wake-jobs, period."** , D-73 three-file template split + D-62 template-based generation discipline ensures the same agent-profiles + same registry produces byte-identical wake.md files across machines. Phase 16 golden-file tests depend on this.
- **"Runtime is a thin layer, not a new framework."** , per PDF page 6 "Fase 5: Runtime y Gestión Multi-Agente". AgentBloc does NOT reimplement cron, webhook handling, or agent spawning. It emits the contracts (wake.md, n8n routes, registry.runtime block) that existing infrastructure (system cron, n8n, ClaudeClaw) consumes. Phase 13's thinness is a feature, not a bug.
- **"First-agent-detects-need spawns TeamCreate"** , PDF page 5 verbatim. D-76 encodes this + adds single-agent bypass per RUNTIME-05 + adds declared-vs-dynamic spawn_rule enum to cover both Designer Agent's pre-classified multi-agent workflows and runtime dependency-detection.
- **"Kill-switch wake check must happen BEFORE memory read"** , D-73 ordering is critical. If KILL_SWITCH is active, the agent must not even touch state.json (could be corrupted during the halt condition; best left untouched).
- **"n8n integration is read-through-write-through, not a separate orchestrator"** , PDF page 7 "n8n como event bus" locks this. n8n fires a webhook into ClaudeClaw (or into a local listener for runtime-agnostic path); ClaudeClaw's job endpoint wakes the agent. n8n does NOT become a dependency of AgentBloc , it is the user's existing infrastructure that AgentBloc emits route configs for.
- **"Correlation IDs travel with the payload, not via a side channel"** , no separate Redis / message-broker lookup. The ID is in the env var, in the JSON payload, in the SendMessage metadata , everywhere it needs to be grep-able, it is co-located with the data.
- **"Telegram /stop must be more than documentation"** , Phase 13 ships the n8n route YAML stub (`agentbloc-stop.yaml`) so the user installs it once and never touches it again. This is the difference between "the kill switch is documented" (v1.0) and "the kill switch is wired" (v2.0).
- **"v1.0 SECR-05 kill-switch: check prose everywhere, check action only in Phase 13 runtime"** , Phase 12 embedded kill-switch check prose into every deployed SKILL.md (Validation Check 7). Phase 13 is when a deployed agent actually reads the file on wake. Phase 12 prose was a correctness invariant; Phase 13 is the enforcement.
- **"Runtime-engine is the last subagent of the deploy-protocol chain"** , deploy-engine (Phase 12) emits artifacts; runtime-engine (Phase 13) wakes them. Future Phase 14 extends deploy-protocol with a briefing-agent subagent OR the briefing-agent is a deployed agent (TBD in Phase 14 discuss). Phase 13 leaves that hook open but does not wire it.

</specifics>

<deferred>
## Deferred Ideas

- **JSONL log aggregation + daily rollup + activity-feed.jsonl** -> Phase 14 MONITOR-01..06. Phase 13 writes individual log lines with correlation IDs; the aggregator is Phase 14.
- **Briefing-agent daily Telegram summaries** -> Phase 14 MONITOR-04. Phase 13 does NOT generate a briefing agent; Phase 14 adds it as a default-generated anticipated agent per team.
- **Autonomy-level enforcement at side-effect time (semi-approval, supervised-wait)** -> Phase 14 AUTON-01..05. Phase 13's wake.md templates include `{{agent.autonomy}}` pass-through; Phase 14 makes this actionable.
- **Approval queue Telegram routing + cost tracking + task-locking state + status badges** -> Phase 14 CTRL-01..05. Phase 13 emits `.agentbloc/agents/<agent-id>/state.json locks[]` as empty array; Phase 14 populates.
- **Anticipation-pass agents in runtime (Phase 15 extends Designer output)** -> Phase 15 ANTIC-01..05. Phase 13's wake templates support anticipated agents with zero change; Phase 15 adds them to registry.yaml and runtime-engine picks them up automatically.
- **Correlation-ID audit viewer (web dashboard with time-sorted ID drill-down)** -> v2.5+. Phase 13 correlation-id.md documents grep recipes; web UI is deferred to the v2.5 Bun + Hono dashboard.
- **SQLite persistence for log search** -> v2.5+. Files-first per D-1; SQLite is the v2.5 upgrade path when JSONL log scan becomes sluggish at scale.
- **Cross-run correlation-ID diffing (detecting flaky paths)** -> v4.0 Self-Healing Evolution. Detects that the same user event took longer this week than last week; out of scope for v2.0.
- **n8n route installation automation** (programmatic push of AgentBloc-generated routes into the user's n8n instance) -> v2.5+. Phase 13 emits YAML stubs; the user installs them manually into n8n. Automation requires an n8n MCP wrapper which is a separate integration.
- **Mobile-push / SMS / phone-call wake channels** -> out of scope for v2.0 per CLAUDE.md constraints (Telegram is the only human channel).
- **Auto-remediation when a wake fires but the agent fails to complete** -> v4.0 Self-Healing Evolution.
- **Distributed / multi-host runtime** -> v3.0+. v2.0 is explicitly single-host.
- **LLM-routed dynamic agent selection (AG2 SelectorGroupChat)** -> Out of scope permanently per PROJECT.md. Flows are hardcoded per team after Designer emits the plan.
- **Cron + webhook wake-race deduplication** (same agent triggered by cron AND by webhook within 1 minute) -> Phase 13 relies on agent's `state.processed_ids[]` (Phase 12 D-65) for idempotency; true wake-race detection at the trigger layer (n8n + cron coordination) is deferred to v2.5+ when the web dashboard can expose the race detector.

### Reviewed Todos (not folded)

None , STATE.md blockers / carry-forward section listed `.planning/STATE.md :: [v2.0 Phase 13 discuss] n8n webhook -> ClaudeClaw job contract (payload shape, ID propagation, failure handling) -- needs live test against existing n8n deployment` which IS folded into this phase (D-74 envelope + D-75 correlation + D-80 runtime-engine cover this; the "live test against existing n8n deployment" is Phase 16 validation, not Phase 13 scope).

</deferred>

---

*Phase: 13-multi-agent-runtime*
*Context gathered: 2026-04-24*
