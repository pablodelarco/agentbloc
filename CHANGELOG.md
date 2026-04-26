# Changelog

All notable changes to AgentBloc are documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

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

Authoritative scope source: `.planning/v2.0-PROMPT.pdf`. Milestone archive: `.planning/milestones/v2.0-ROADMAP.md`.

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
