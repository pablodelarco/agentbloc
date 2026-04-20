# Requirements: AgentBloc v2.0 Designer + Deploy

**Defined:** 2026-04-20 (realigned from 2026-04-18 Discovery Agent scope after PDF pivot)
**Source:** `.planning/v2.0-PROMPT.pdf` (authoritative)
**Core Value:** A non-technical business owner can describe their problem and end up with a deployed, secure, proactive agent team without writing code and without improvised security scaffolding. v2.0 automates the design and deployment pipeline end-to-end and proactively suggests agents the user did not request.

---

## Milestone Scope (Locked 2026-04-20)

- **Positioning:** AgentBloc is a **proactive AI consultant**, not just an automator. Three intelligence layers: **Understand** (Business Graph from interview) → **Diagnose** (classify each process into automation type) → **Anticipate** (suggest agents the user didn't ask for).
- **Platform:** AgentBloc runs as a markdown skill INSIDE ClaudeClaw (TypeScript + Bun). ClaudeClaw provides `Agent` / `TeamCreate` / `SendMessage` / Jobs / Telegram / hooks / skills system. n8n provides the event bus. No custom runtime on AgentBloc's side.
- **Framework pattern inheritance** (from `v2.0-PROMPT.pdf`): CrewAI (role/goal/backstory), AG2 (CaptainAgent dynamic team generation), Google ADK (Sequential/Parallel/Loop primitives), LangGraph (checkpointing schema shape — Git commits on state files), Mastra (Zod-style schema validation between agents — implemented via front-matter validators), Paperclip (control plane UX — approval queue, cost tracking, task locking, status badges).
- **Canonical test case:** Arco Rooms — 7-property rental management — 5-agent team (3 requested: Gestor Cobros, Recepcionista, Gestor Documental; 2 anticipated: Analista Rentabilidad, Gestor Incidencias).

---

## v2.0 Requirements

### Interview Extension (INTV)

Extends the existing v1.0 Phase 1 Interview. The interview already collects the information; v2.0 structures it.

- [x] **INTV-01**: v1.0 Interview phase emits a Business Graph JSON artifact at `.agentbloc/graph/business-graph.json` in addition to the existing conversational confirmation — completed 2026-04-21 (Phase 08-02) via Summary-gate Business Graph Emission subsection
- [x] **INTV-02**: Interview captures `decision_patterns` as free-text rules the user describes (e.g. "if overdue > 7 days → formal notice") — stored as string array in the Business Graph — completed 2026-04-21 (Phase 08-02) via Category 7 seed question #3 + Decision Patterns Summary table
- [x] **INTV-03**: Interview captures `channels` (Telegram / email / web / other) and `tools_available` (list of existing tools the user already pays for) as distinct Business Graph fields — completed 2026-04-21 (Phase 08-02) via Tools Available + Channels Summary tables extracted from Categories 3 and 8
- [x] **INTV-04**: Interview concludes with a structured review: user sees the Business Graph sections rendered in the conversation (business, processes, tools, channels, decision_patterns) and confirms or corrects each before advancing — completed 2026-04-21 (Phase 08-02) via rendered-table review per D-14 (silent JSON emission)

### Business Graph Schema (BGRAPH)

- [x] **BGRAPH-01**: `references/business-graph-schema.md` defines the canonical Business Graph JSON schema with `business` (type / size / owner), `processes` (name / steps / trigger / tools / pain / frequency / current_actor), `tools_available`, `channels`, `decision_patterns` — completed 2026-04-21 (Phase 08-01)
- [x] **BGRAPH-02**: Business Graph file carries a `schema_version` field so future schema changes are versioned and backward-compatible — completed 2026-04-21 (Phase 08-01)
- [x] **BGRAPH-03**: Each `process` entry carries a `trigger` object with a bounded type set (`cron` / `event` / `manual`) and trigger-type-specific fields (cron schedule / event source + name / manual description) — completed 2026-04-21 (Phase 08-01)
- [x] **BGRAPH-04**: A lightweight validator skill checks a Business Graph JSON file against the schema before Designer Agent consumes it; validation errors surface in the conversation with line numbers — completed 2026-04-21 (Phase 08-01) via prose-checklist validator per D-13

### Designer Agent (DSGN)

The core new capability. AG2 CaptainAgent pattern adapted to AgentBloc.

- [ ] **DSGN-01**: Designer Agent lives at `.claude/agents/designer-agent.md` (Claude Code subagent definition) with `context: fork` and scoped tool access
- [ ] **DSGN-02**: Designer Agent consumes the Business Graph JSON and emits an `agent-profiles.yaml` artifact containing `team` (name + topology) and `agents` (list of full profiles)
- [ ] **DSGN-03**: Each generated agent profile includes `id`, `role`, `goal`, `backstory` (CrewAI pattern), `tools` (list of MCP references), `triggers` (cron / event / inter-agent), `autonomy` (`full` / `semi` / `supervised`), `outputs` (type + schema), `escalation` (target like `telegram:pablo`), `dependencies` (other agents referenced)
- [ ] **DSGN-04**: Designer Agent selects a team `topology` from `{pipeline, mesh, hierarchy, swarm}` with documented rationale based on process interdependencies observed in the Business Graph
- [ ] **DSGN-05**: Designer Agent groups processes by role (one role = one agent) rather than one-process-per-agent, so a single agent can own multiple related steps
- [ ] **DSGN-06**: Designer Agent presents the proposed team to the user conversationally with an ASCII interaction diagram (from v1.0 Design phase DESG-08) before the deploy pipeline runs
- [ ] **DSGN-07**: User can edit the generated profiles (rename agents, merge roles, drop an anticipated agent) and Designer regenerates `agent-profiles.yaml` with the edits applied

### Orchestration Classifier (ORCH)

Part of the Designer Agent's output. Separated because it maps to a known pattern set.

- [ ] **ORCH-01**: Designer Agent classifies each workflow into one of five orchestration patterns from `v2.0-PROMPT.pdf`: **Graph / Conversational / Role-delegation / Handoff-chain / Event-bus**, or their simpler ADK-equivalent `Sequential / Parallel / Loop / Event-driven`
- [ ] **ORCH-02**: `references/orchestration-patterns.md` documents the five patterns, when each applies, and example workflow shapes — Designer Agent cites this reference when picking
- [ ] **ORCH-03**: The `agent-profiles.yaml` `orchestration.workflows` section lists each workflow with `type`, `agents`, `trigger`, and either `steps` (sequential/loop) or `flow` (event-driven narrative)
- [ ] **ORCH-04**: Workflows reference agents by `id` only — cross-references must resolve to agents listed in the same file (validator check)

### Integration Discovery (INTEG) — Steps 1-3 MCP path

Four-step search per required tool. Steps 1-3 cover the MCP path; step 4 (browser fallback) is scoped separately under BROWSER.

- [ ] **INTEG-01**: Step 1 — Discovery Pipeline checks `.mcp.json` for an existing server matching the tool name; if present, skips to verification
- [ ] **INTEG-02**: Step 2 — Discovery Pipeline queries a curated ecosystem MCP registry (referenced in `references/mcp-ecosystem.md`, seeded from v1.0 technology stack); if a match exists, proposes `npx -y @mcp/xxx` installation
- [ ] **INTEG-03**: Step 3 — If no MCP exists but a public API does, a `mcp-builder` skill generates a minimal wrapper MCP at `.mcp/generated/<tool-id>/` and registers it in `.mcp.json`
- [ ] **INTEG-04**: Each integration is **verified** before deploy: the MCP responds to a ping/health call, has the credential scopes the agent needs, and returns a sample shape matching the agent's expected input
- [ ] **INTEG-05**: Verification failures surface in the conversation with the specific scope or credential missing, and the pipeline halts until the user provides or approves the missing piece
- [ ] **INTEG-06**: Evidence protocol from v1.0 INTG-03 carries forward — every integration claim includes URL + package version + last-commit date; missing evidence is flagged `[UNVERIFIED]`

### Browser Automation Fallback (BROWSER) — INTEG Step 4

The earlier "Discovery Agent" scope (pre-2026-04-20) becomes this subset. Reuses the 2026-04-18 research in `research/{STACK,FEATURES,ARCHITECTURE,PITFALLS,SUMMARY}.md`.

- [ ] **BROWSER-01**: Step 4 — When Steps 1-3 all fail, Discovery Pipeline invokes a browser-fallback subagent at `.claude/agents/browser-discovery.md` (context:fork, Playwright MCP only) with a `TARGET.md` describing the service + target workflow + budget
- [ ] **BROWSER-02**: Browser discovery produces a `DISCOVERY-REPORT.md` per service at `.agentbloc/discovery/<service-slug>/` with YAML front-matter (schema-locked, SHA256 signed, `expires_at` field) + structured body (endpoints, auth flow, sample calls, UI selectors, rate limits, anti-bot observations)
- [ ] **BROWSER-03**: Per-service legal opt-in is mandatory before any browser launches; generates `DISCOVERY-LICENSE-NOTICE.md` with ToS URL + keyword excerpt + tier classification (TOS-GREEN / TOS-AMBER / TOS-RED); append-only `OPT_IN_LEDGER.json` per project
- [ ] **BROWSER-04**: Every discovered endpoint carries a three-tier API classification (DOCUMENTED / INTERNAL / INTERNAL-HARDENED)
- [ ] **BROWSER-05**: Anti-bot policy: **detect-and-degrade, never bypass**. CI deny-list lint rejects `playwright-extra`, `puppeteer-extra-plugin-stealth`, CAPTCHA solvers, fingerprint-spoofing libraries
- [ ] **BROWSER-06**: Browser discovery uses Patchright (version-locked to Playwright 1.59.x) for legitimate CDP-leak patches only; fingerprint spoofing remains explicitly disallowed
- [ ] **BROWSER-07**: Stack pins captured in `references/browser-stack.md`: `playwright@^1.59.1`, `patchright@^1.59.4`, `curlconverter@^4.12.0`, `@har-sdk/validator@^2.6.1`, `fetch-har@^12.0.1`
- [ ] **BROWSER-08**: Checkpointed multi-turn workflow: Browser discovery resumable after up to 4-hour pauses (real-world 2FA / SMS latency) via `.agentbloc/discovery/<service-slug>/state.json`
- [ ] **BROWSER-09**: Ralph-style retry loop with capped iteration budget (from governance), logged reasoning, exponential backoff — NO fingerprint adjustment on retry
- [ ] **BROWSER-10**: Output firewall — injection detector scans captured response bodies for imperative strings, Base64 blobs, invisible Unicode; findings isolated inside `untrusted-data` fences; fresh-context verification pass before release to the Deploy Pipeline
- [ ] **BROWSER-11**: PII redaction pipeline runs on every HAR + response body (EU IBAN, US SSN, credit-card Luhn, E.164 phones, email addresses) with verification scan before emit
- [ ] **BROWSER-12**: `references/legal-posture.md` documents jurisdictional variance (CFAA US, CMA UK, StGB DE, GDPR EU, LGPD BR) so users understand regional constraints

### Deploy Pipeline (DEPLOY)

Materializes the `agent-profiles.yaml` into a running ClaudeClaw-compatible deployment.

- [ ] **DEPLOY-01**: For each agent in `agent-profiles.yaml`, generate `skills/{agent-id}/SKILL.md` containing the full prompt (role + goal + backstory + tool list + autonomy rules + escalation)
- [ ] **DEPLOY-02**: For each agent trigger, generate a ClaudeClaw job config (cron entry or webhook subscription pointing to n8n route)
- [ ] **DEPLOY-03**: Merge required MCP server entries into `.mcp.json` (newly generated wrappers from INTEG-03 + ecosystem installs from INTEG-02)
- [ ] **DEPLOY-04**: Generate per-agent memory directory `.claude/agents/{agent-id}/` with stub `memory.md`, empty `state.json`, and `last-run.json: null`
- [ ] **DEPLOY-05**: Generate `.claude/agents/registry.yaml` listing the team (lead, agents, reporting hierarchy, dashboard_agent)
- [ ] **DEPLOY-06**: Deploy Pipeline is idempotent — re-running with the same `agent-profiles.yaml` does not duplicate or corrupt existing artifacts; differences present a diff for user approval before overwrite
- [ ] **DEPLOY-07**: Deploy Pipeline emits a `DEPLOY-REPORT.md` summarizing what was created, what was updated, what was skipped, and any pending user actions (credentials missing, ToS opt-in needed, etc.)
- [ ] **DEPLOY-08**: Deploy Pipeline runs a post-deploy verification: every generated SKILL.md loads cleanly, every MCP server responds, every cron job is registered with ClaudeClaw

### Agent Memory System (MEM)

- [ ] **MEM-01**: Each deployed agent has a directory `.claude/agents/{agent-id}/` with three canonical files: `memory.md`, `state.json`, `last-run.json`
- [ ] **MEM-02**: `memory.md` holds durable domain knowledge (tenants, contracts, account numbers — scoped to the agent's domain) in agent-editable Markdown
- [ ] **MEM-03**: `state.json` holds machine-written working state (current month's payments processed, locked resources, retry counts) with `schema_version` field
- [ ] **MEM-04**: `last-run.json` holds the most recent execution log entry (action, result, timestamp, `status: active|idle|error`)
- [ ] **MEM-05**: On every wake, the agent reads `memory.md` and `state.json` first; on every completion, it updates both before emitting log entries
- [ ] **MEM-06**: Memory directories are version-controllable (plain text) and debuggable (human-editable) per v1.0's file-based-state decision

### Multi-Agent Runtime (RUNTIME)

Triggers, coordination primitives, team lifecycle. Thin layer on top of ClaudeClaw primitives — we do not reimplement them.

- [ ] **RUNTIME-01**: Cron triggers fire via system cron + `claude -p` wrapper (ClaudeClaw standard). AgentBloc generates the crontab entries during DEPLOY-02.
- [ ] **RUNTIME-02**: Event triggers fire via n8n webhooks (Gmail / Plaid / BBVA / Google Calendar / custom form). n8n route calls ClaudeClaw's job endpoint, which wakes the agent.
- [ ] **RUNTIME-03**: `references/n8n-integration.md` documents the webhook-to-agent mapping pattern (event source → n8n node → ClaudeClaw job payload) with examples
- [ ] **RUNTIME-04**: Inter-agent coordination uses ClaudeClaw's `SendMessage` (one-to-one) and `TeamCreate` (transient team assembly). Agent A spawns Team T when it detects a multi-agent task; team dissolves when done.
- [ ] **RUNTIME-05**: Single-agent tasks run without `TeamCreate` overhead — Designer Agent's workflow classification determines which path applies
- [ ] **RUNTIME-06**: Every trigger records a correlation ID propagated through SendMessage into all downstream agent log entries so a multi-agent run can be traced end-to-end
- [ ] **RUNTIME-07**: Kill switch from v1.0 SECR-05 carries forward — `.agentbloc/KILL_SWITCH` checked on every agent wake; Telegram `/stop` command honored team-wide

### Autonomy Controller (AUTON)

- [ ] **AUTON-01**: Every agent profile declares `autonomy: full | semi | supervised`; the generated SKILL.md injects autonomy-appropriate language (full = no prompt, semi = confirm before external side-effects, supervised = propose + wait for approval)
- [ ] **AUTON-02**: External side-effect actions (send email, post message, modify record, spend money) route through an autonomy check before execution; `semi` sends a Telegram approval request with context (what the agent intends, why, reversibility); `supervised` always waits
- [ ] **AUTON-03**: Approval round-trip is append-only logged with (agent, action, proposal timestamp, approval timestamp, approver, outcome)
- [ ] **AUTON-04**: Escalation path on any agent failure: the agent writes an escalation entry to its log (`priority: critical`), triggers a Telegram message to the configured escalation target, and halts until human acknowledges
- [ ] **AUTON-05**: Escalation messages include: what the agent tried, why it failed, what options exist, and a one-line recommended next action. Not just an error stack.

### Monitoring + Hierarchical Reporting (MONITOR)

- [ ] **MONITOR-01**: Every agent emits structured log entries in JSONL format matching the canonical log schema (agent_id, team, action, result, details, timestamp, requires_human, priority, token_count, cost_usd, locked_by)
- [ ] **MONITOR-02**: Logs land at `.claude/agents/logs/<YYYY-MM-DD>/<agent-id>.jsonl` — append-only, one JSON per line, Git-versionable
- [ ] **MONITOR-03**: `.claude/agents/registry.yaml` declares the team structure: `lead`, `agents[]`, `reporting_hierarchy` (parent → children map), `dashboard_agent`
- [ ] **MONITOR-04**: A `briefing-agent` (generated by Designer as a default anticipated agent for every team) runs daily and produces a consolidated Telegram briefing: what each agent did, what escalations are pending, cost + token totals, health status
- [ ] **MONITOR-05**: Hierarchical reporting pattern documented in `references/reporting-hierarchy.md`: individual agents → team leads → briefing agent → human. Individual agents never send directly to Telegram EXCEPT critical escalations.
- [ ] **MONITOR-06**: Briefing agent consumes the JSONL logs + registry, not each agent's state directly — presentation layer is pluggable (Telegram in v2.0, web dashboard in v2.5, management UI in v3.0)

### Control Plane UX (CTRL) — Paperclip-inspired patterns

- [ ] **CTRL-01**: Approval queue — every `requires_human: true` log entry surfaces in a separate Telegram thread (not the main briefing thread) so human decisions aren't lost in noise
- [ ] **CTRL-02**: Cost tracking — `token_count` + `cost_usd` recorded per log entry; briefing agent surfaces per-agent and per-team totals; tracker references the active billing mode (Max subscription vs API key)
- [ ] **CTRL-03**: Task locking — when an agent starts work on a shared resource (e.g., bank account reconciliation), it writes `locked_by: <agent-id>` into a shared lock file; other agents checking that resource see the lock and defer
- [ ] **CTRL-04**: Status badges — every agent's `last-run.json` includes `status: active | idle | error`; briefing agent surfaces the team health glance (e.g., "5 active, 0 idle, 0 error")
- [ ] **CTRL-05**: Activity feed — chronological merge of all agents' JSONL logs into a single per-day `activity-feed.jsonl` for operational debugging

### Anticipation Engine (ANTIC)

The differentiator. Core of the "proactive AI consultant" positioning.

- [ ] **ANTIC-01**: Designer Agent runs an anticipation pass after producing the user-requested agents: analyzes the Business Graph for business-type patterns (e.g., "rental management" ⇒ "you probably need profitability analyst + incident tracker")
- [ ] **ANTIC-02**: `references/anticipation-heuristics.md` documents the mapping from business type → commonly-needed-but-often-forgotten agents, with rationale per mapping (why real estate needs incident tracking, why ecommerce needs returns analyst, etc.)
- [ ] **ANTIC-03**: Anticipated agents are clearly marked in the proposed team presentation (DSGN-06) with an `ANTICIPATED` tag and the rationale so the user can accept / reject / defer each
- [ ] **ANTIC-04**: Rejected anticipated agents are remembered in a `.agentbloc/graph/declined.json` so re-running Designer doesn't re-propose them
- [ ] **ANTIC-05**: Anticipation heuristics are evidence-backed (at least three independent sources per mapping) — consulting-product integrity matters

### Inherited from v1.0 (extensions / touchpoints)

These are not new requirements — they are v1.0 requirements that v2.0 work must respect or extend:

- v1.0 interview (INTV-01 through INTV-04 from v1.0 REQUIREMENTS) remains the input surface — v2.0 adds the Business Graph emission on top
- v1.0 security framework (credentials, blast-radius, audit logging, kill switch, rate limiting, GDPR, prompt injection, tenant isolation, prompt-injection defense) applies to every generated agent via DEPLOY-01's SKILL.md generation
- v1.0 Phase 4 dry run applies to every team before production deploy — DEPLOY-08 explicitly triggers it
- v1.0 Phase 6 Evolution (weekly capability + vulnerability scans) applies to every deployed team

---

## Deferred to v2.5+

- Web dashboard (Bun + Hono) with real-time activity feed, per-agent drill-down, cost trending
- SQLite event storage (migration from JSONL)
- Cross-run diff of DISCOVERY-REPORT.md (browser discovery delta detection → self-healing signal for v4.0)
- Learner system that auto-extracts reusable skills from debug sessions (inspired by oh-my-claudecode `.omc/skills/`)
- Multi-account tier-shape detection during browser discovery (Free vs Pro endpoint differences)
- Contract-test export from Business Graph / DISCOVERY-REPORT.md (Pact / OpenAPI examples)

## Deferred to v3.0+

- Builder Agent — consumes DISCOVERY-REPORT.md (from BROWSER path) and generates a production TypeScript MCP (tested, CI'd, publishable to npm)
- OpenClaw as runtime substrate evaluation (ACP + Docker sandboxing + multi-channel messaging)

## Deferred to v4.0+

- Self-Healing Evolution — auto-triggers re-discovery when a deployed MCP starts failing, regenerates + human-approves patches
- Drift detection via `expires_at` + healthcheck recipe (contract surfaces emitted in v2.0, consumer in v4.0)

---

## Out of Scope (v2.0 and beyond unless noted)

| Feature | Reason |
|---------|--------|
| Fingerprint evasion / stealth plugins in browser fallback | Violates target-vendor ToS + CFAA exposure. Enforced by CI deny-list lint (BROWSER-05). |
| CAPTCHA solving services | ToS violation for both solver vendor and target. Explicit anti-feature. |
| TLS fingerprint (JA3/JA4) spoofing | Same legal reasoning as fingerprint evasion. |
| Writing to third-party services during browser discovery | Discovery is read-only. Observed writes are documented, never called. |
| MFA seed / passkey extraction | Permanent anti-feature — registers a persistent backdoor. |
| Mobile app reverse engineering (Frida, iOS SSL pinning bypass) | Defer to v3.5+. |
| Browser extension reverse engineering | Defer. v2.0 targets web portals only via browser fallback. |
| Custom Python / Node.js server for orchestration | Claude Code + ClaudeClaw IS the runtime. No new services. |
| Filesystem as primary inter-agent bus | `SendMessage` is faster and cleaner than Paperclip's file-based pattern. |
| LLM-routed dynamic agent selection (AG2 SelectorGroupChat) | Too much latency. Flows hardcoded per team after Designer emits the plan. |
| Manual agent definition by user | Designer auto-generates from the interview; user approves or tweaks. |
| Web UI / visual workflow builder | Out of scope for v2.0. Telegram → dashboard (v2.5) → management UI (v3.0). |
| Database in v2.0 | Files-first. SQLite arrives with v2.5 web dashboard. |
| Agent processes running 24/7 | Agents sleep between triggers. Cron + n8n webhooks wake them. |
| AutoGen as primary framework reference | In maintenance mode. Use AG2 CaptainAgent specifically, not AutoGen broadly. |

---

## Traceability

_Populated by `gsd-roadmapper` when rewriting `ROADMAP.md`._

**Coverage target:**
- New v2.0 requirements: ~60 (4 INTV + 4 BGRAPH + 7 DSGN + 4 ORCH + 6 INTEG + 12 BROWSER + 8 DEPLOY + 6 MEM + 7 RUNTIME + 5 AUTON + 6 MONITOR + 5 CTRL + 5 ANTIC)
- Mapped to phases: pending (9-phase structure proposed in ROADMAP.md)
- Unmapped: 0 (must verify after roadmap)

---

*Requirements defined 2026-04-20 after PDF scope pivot. Supersedes the 2026-04-18 Discovery-centric requirements (46 reqs, commit `c32d27d`). Research artifacts in `.planning/research/` remain valid for BROWSER-xx requirements.*
