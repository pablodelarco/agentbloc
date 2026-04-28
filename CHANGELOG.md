# Changelog

All notable changes to AgentBloc are documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [3.0.0] - 2026-04-28

### BREAKING

- **Architectural pivot — AgentBloc is now the architect, not the builder.** v3.0 emits a portable build-ready spec folder (markdown + YAML + JSON) instead of running scripts. The output is consumed by a separate AI coding session (Claude Code, Codex, Gemini, Cursor, OpenClaw) that does the implementation. v2.0/v2.5 emitted `.claude/skills/<agent-id>/SKILL.md` per agent + `.agentbloc/agents/registry.yaml` + cron lines + n8n webhook wiring; v3.0 emits a project folder under `.agentbloc/spec/` (or user-specified path) with the canonical structure in `references/spec-folder-structure.md`.
- **`runtime-engine` subagent removed.** Its work folds into the `spec-engine` output as advisory `runtime/reference-impl/` content. The v2.5-runtime substrate (helpers.sh, wake.sh, claude-wrap.sh, telegram-send.sh, telegram-poll.sh, approval-router.sh, escalation-router.sh, cron-generator.sh, loop.sh, activity-feed-merge.sh, hooks/autonomy-gate.sh, .env.example) ships inside every emitted spec folder as reference implementation, NOT as live runtime.
- **`deploy-engine` subagent renamed to `spec-engine`** and rewritten. Bash narrowed to `shasum:*` only (no `crontab`, no `claude` CLI). Inputs unchanged (business-graph.json, agent-profiles.yaml, inventory.yaml). Outputs canonicalized via `references/spec-folder-structure.md`.
- **`briefing-agent` removed.** The Phase 14 monitor + monitor_wired sub-gate are out of scope for v3.0 (no live runtime to monitor). Documented in spec output as a thing the build session can implement later if desired.
- **Phase 5 sub-gates collapsed from 3 to 1.** v2.5 had `deployment_artifacts_emitted` + `runtime_wired` + `monitor_wired`. v3.0 has only `spec_folder_emitted`. The `RUNTIME-FAILED-REPORT.md` and `BRIEFING-FIRST-RUN.md` cascade is removed.
- **ClaudeClaw runtime contract removed entirely.** v2.0 references to `TeamCreate`, `SendMessage`, transient session ledgers, and 600s long-poll approval-router are gone. Replaced by file-based inbox handoff in `runtime/reference-impl/helpers.sh` (atomic_write_inbox + read_next_inbox primitives).
- **`integration-manifest.yaml` renamed to `inventory.yaml`** and extended with the 5-tier `readiness` field.

### Added

- **Phase 3 extended to "Deep Tool Discovery"** with the 5-tier readiness ranking. Every tool gets exactly one tier:
  - `EXISTS-MCP` — public MCP server exists; install instructions known
  - `NEEDS-MCP-WRAPPER` — vendor API exists, no public MCP; wrapper buildable via `mcp-builder` skill
  - `NEEDS-N8N-FLOW` — visual / branching / multi-service logic; n8n is the right tool
  - `NEEDS-WEBHOOK` — vendor pushes events; receiver must be built and exposed
  - `MANUAL` — no automation path appropriate (compliance, frequency, cost, complexity)
- **New reference: `inventory-protocol.md`** — the 5-tier decision tree, evidence requirements, effort estimates per tier, edge cases.
- **New reference: `spec-folder-structure.md`** — canonical output shape with per-file contracts + validation checklist.
- **New reference: `spec-emission-protocol.md`** (replaces `deploy-protocol.md`) — 6-step canonical flow for the `spec-engine` subagent.
- **New reference: `phase-5-spec-emission.md`** (replaces `phase-5-deployment.md`) — Phase 5 orchestration with single sub-gate.
- **New reference: `spec-emission-report-schema.md`** (replaces `deploy-report-schema.md`) — dual-artifact contract for SPEC-EMISSION-REPORT.md / SPEC-EMISSION-FAILED-REPORT.md.
- **Phase 4 reframed to "Spec Review"** — walkthrough + sign-off ritual instead of dry run (nothing executes in v3.0). New sub-gate: `spec_review_signed_off`.
- **Phase 6 reframed to "Spec Evolution"** — rerun AgentBloc on the existing spec folder when requirements change. Drops runtime audit-log forensics, scan-detect-propose-approve, runtime-history ledgers.
- **Architecture documentation:** `docs/v3.0-architecture.md` (canonical design lock) + `docs/v3.0-simplification-plan.md` (full repo audit + simplification buckets).
- **References reorganized into `runtime-impl/` subfolders** — references that describe runtime mechanics (`runtime-coordination.md`, `scheduling.md`, `task-locking.md`, `correlation-id.md`, `jsonl-log-schema.md`, `agent-memory-schema.md`, `activity-feed.md`, `deployed-agent-skill-schema.md`) are now under `references/runtime-impl/`. Same for `templates/runtime-impl/` (wake-job templates) and `examples/runtime-impl/` (correlation-flow + runtime-artifacts).

### Removed

- 19 files: 14 PNG branding-iteration screenshots from repo root + 4 dead-concept tracked files (`runtime-engine.md` subagent, `briefing-agent.md.tmpl` template, `arco-rooms-monitor-fixtures.md` + `arco-rooms-registry.yaml` examples) + AGENTBLOC_V2_PROMPT.pdf untracked clutter.

### Migration Notes

- v2.0 deployments continue to work — but new emissions use the v3.0 spec folder model.
- The runtime substrate from v2.5-runtime branch is preserved locally for forensic reference; the same files ship inside every emitted spec folder under `runtime/reference-impl/`.
- v3.0 stops at the spec folder. Build sessions in any AI coding tool consume the folder and implement the running team. The reference impl shows one bash + cron path; `runtime/alternatives.md` lists others (n8n, Temporal, Pipedream, Inngest, custom Python).

### Stack Context

v3.0 runs as a pure markdown Claude Code skill. The conversation engine uses Claude Code's skills + subagents + (light) hook integration. The output spec folder is markdown + YAML + JSON only — tool-portable. ClaudeClaw is gone (was private + nonexistent on user machines). n8n is now a first-class output path (Tier 3) instead of "v3.0-deferred."

Authoritative scope source: `docs/v3.0-architecture.md`.

## [2.0.0] - 2026-04-26

### Added

- **Phase 8 -- Business Graph Foundation:** Schema-validated `business-graph.json` artifact emitted by v1.0 Interview phase; bilingual (EN/ES) flow preserved; Validation Checklist gates Phase 2 entry; canonical Arco Rooms fixture (INTV-01..04, BGRAPH-01..04)
- **Phase 9 -- Designer Agent:** Project-local subagent at `.claude/agents/designer-agent.md` (`context: fork`, scoped tools, no Bash) consumes Business Graph and emits `agent-profiles.yaml` with CrewAI-shaped profiles + 5-pattern orchestration classification + topology selection (DSGN-01..07, ORCH-01..04)
- **Phase 10 -- Integration Discovery (MCP Path):** 4-step search protocol (existing `.mcp.json` -> ecosystem registry -> wrapper generation via `mcp-builder` skill -> verification loop with `healthcheck_at`) + `integration-manifest.yaml` schema (INTEG-01..06)
- **Phase 11 -- Integration Discovery (Browser Fallback):** Step 4 `browser-discovery` subagent with Playwright + Patchright (CDP-leak patches only; deny-list lint forbids fingerprint-spoofing libraries); per-service legal opt-in via `DISCOVERY-LICENSE-NOTICE.md`; three-tier API classification (DOCUMENTED / INTERNAL / INTERNAL-HARDENED); PII redaction + injection-detector output firewall (BROWSER-01..12)
- **Phase 12 -- Deploy Pipeline + Agent Memory:** `agent-profiles.yaml` materializes into `.claude/skills/<agent-id>/SKILL.md` per agent + `.agentbloc/agents/<agent-id>/{memory.md, state.json, last-run.json}` memory directories + `.agentbloc/agents/registry.yaml` team registry + `.mcp.json` merges; idempotent re-runs via SHA256 + RFC 8785 canonicalization; `DEPLOY-REPORT.md` summary (DEPLOY-01..08, MEM-01..06)
- **Phase 13 -- Multi-Agent Runtime:** Cron + n8n webhook trigger plumbing; `wake.md` per trigger path; `correlation_id` propagation through SendMessage; KILL_SWITCH file + Telegram `/stop` command; transient TeamCreate sessions; `runtime-engine` subagent with narrow Bash allow-list (RUNTIME-01..07)
- **Phase 14 -- Autonomy + Monitor + Control Plane:** Per-agent autonomy levels (`full` / `semi` / `supervised`) with Telegram approval round-trip + escalation; structured JSONL log schema at `.claude/agents/logs/<DATE>/<agent-id>.jsonl`; default daily `briefing-agent` with pluggable presentation layer; Paperclip-inspired control plane (separate Telegram threads for approvals + escalations + briefing; cost tracking; flock-based task locking; status badges; daily activity-feed merge) (AUTON-01..05, MONITOR-01..06, CTRL-01..05)
- **Phase 15 -- Anticipation Engine:** Designer's `<anticipation_pass>` block proposes unrequested-but-needed agents from `references/anticipation-heuristics.md` (5 business-type mappings: rental-property-management, ecommerce, freelance-services, restaurant, professional-services; 3+ evidence sources per mapping); `ANTICIPATED` tag in proposed team presentation; `.agentbloc/graph/declined.json` decline memory at business-level (ANTIC-01..05)
- **Phase 16 -- End-to-End Validation:** TAP harness extended with Category 6 v2.0-coverage validator + 13 v2.0 assertions interleaved into canonical Arco Rooms scenario; `tests/scenarios/arco-rooms.jsonl` covers full v2.0 flow across all 13 categories; 146/146 tests pass

### Changed

- **`audit-logging.md` (v1.0 SECR-04):** Correlation-ID format aligned with Phase 13 D-75 `<source>-<UTC-Z-compact>-<nonce6>` pattern; v1.0 `sess-NNN` legacy examples preserved for backward compat
- **`agent-memory-schema.md` (Phase 12 MEM-04):** `last-run.json` schema_version bumped to 2 with optional `cost_usd` + `token_count` fields per Phase 14 CTRL-02 cost tracking (D-98 backward-compatible additive extension)
- **`agent-profile-schema.md` (Phase 9 DSGN-03):** 3 OPTIONAL anticipation fields per agent (`anticipated`, `anticipation_rationale`, `anticipation_sources`) + Validation Check 9 WARN-tier; schema_version unchanged at 1 per Phase 15 D-101 backward-compatible additive extension
- **`tests/run-tests.sh` (v1.0):** `validate_references` now resolves SKILL.md at `.claude/skills/agentbloc/SKILL.md` (v2.0 canonical path per Phase 12 D-59a); falls back to repo root for v1.0 backward compat. Fixed a latent bug where v1.0 baseline expected SKILL.md at repo root but Phase 12 moved it.

### Stack Context

v2.0 runs as a markdown skill INSIDE ClaudeClaw (TypeScript + Bun substrate providing Agent / TeamCreate / SendMessage / Jobs / Telegram primitives) with n8n as the event bus for real-time webhook triggers. AgentBloc itself remains pure markdown , no custom runtime added on AgentBloc's side. Framework patterns inherited (not adopted as dependencies) from CrewAI (role/goal/backstory) + AG2 (CaptainAgent dynamic team generation) + Google ADK (Sequential/Parallel/Loop primitives) + LangGraph (file-based state checkpointing) + Mastra (front-matter validators) + Paperclip (control plane UX patterns).

Authoritative scope source: `.planning/v2.0-PROMPT.pdf`.

## [1.0.0] - 2026-04-14

### Added

- **Phase 1 -- Skill Foundation:** Lean SKILL.md hub (~160 lines) with state protocol,
  hard gates, bilingual language detection, technical level assessment, and progressive
  disclosure via references/ directory (ARCH-01 through ARCH-08)
- **Phase 2 -- Security Framework:** Nine cross-cutting security reference files covering
  credential management, data classification, blast-radius scoring, audit logging, GDPR/HIPAA/PCI
  compliance patterns, incident response, prompt injection defense, and tenant isolation
  (SECR-01 through SECR-09)
- **Phase 3 -- Interview and Design:** Deep interview protocol with 9-category structured
  questioning and design protocol with topology selection, agent contracts, governance specs,
  and blast-radius scoring. Framework pattern reference for CrewAI, LangGraph, and n8n
  (INTV-01 through DESG-08)
- **Phase 4 -- Integration and Confirmation:** Integration analysis protocol with multi-method
  search, evidence verification, trust scoring, and decision matrices. Confirmation protocol
  with sequential agent approval, mandatory dry run with dual-layer enforcement, and final
  approval gate (INTG-01 through CONF-05)
- **Phase 5 -- Deployment and Evolution:** Deployment artifact generation for 11 artifact types
  (team.yaml, agent configs, skills, governance, Telegram, state schemas, cron jobs, runbooks).
  Evolution loop with scan-detect-propose-approve cycle and human approval gate
  (DEPL-01 through EVOL-05)
- **Phase 6 -- Repo Polish:** README with quickstart, three example walkthroughs, bilingual
  glossaries, LICENSE, CONTRIBUTING.md, SECURITY.md, and version badges
  (REPO-01 through REPO-08, ARCH-09)

[2.0.0]: https://github.com/pablodelarco/agentbloc/releases/tag/v2.0.0
[1.0.0]: https://github.com/agentbloc/agentbloc/releases/tag/v1.0.0
