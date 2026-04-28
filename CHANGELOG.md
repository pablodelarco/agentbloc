# Changelog

All notable changes to AgentBloc are documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [1.0.0] - 2026-04-28

Initial public release.

### Added

- **6-phase conversational skill.** AgentBloc activates on `/agentbloc` (or matching intent), detects language (English / Spanish) and technical level, and walks the user through Interview → Design → Deep Tool Discovery → Spec Review → Spec Emission → Spec Evolution. Every phase has an explicit gate; nothing advances without user approval.
- **Phase 1 — Deep Interview.** 9-category structured questioning with bilingual support. Emits a schema-validated `business-graph.json` containing services, data flows, edge cases, decision patterns, and data-classification tags (PII / financial / public). Validation Checklist gates Phase 2 entry.
- **Phase 2 — General Design.** Project-local `designer-agent` subagent (fork context, scoped tools, no Bash) consumes the Business Graph and emits `agent-profiles.yaml` with CrewAI-shaped profiles (role + goal + backstory + tools + autonomy + blast-radius + escalation). Includes 5-pattern orchestration classification (`sequential | parallel | loop | event-driven | conversational`) and an anticipation pass that surfaces unrequested-but-needed agents from `references/anticipation-heuristics.md` (5 business-type mappings).
- **Phase 3 — Deep Tool Discovery with 5-tier readiness ranking.** Every tool every agent needs gets exactly one tier with an evidence URL:
  - `EXISTS-MCP` — public MCP server already exists; install instructions known
  - `NEEDS-MCP-WRAPPER` — vendor API exists, no public MCP; wrapper buildable via the `mcp-builder` skill
  - `NEEDS-N8N-FLOW` — visual / branching / multi-service logic; n8n is the right tool
  - `NEEDS-WEBHOOK` — vendor pushes events; receiver must be built and exposed
  - `MANUAL` — no automation path appropriate (compliance, frequency, cost, judgment)
  4-step search protocol (existing `.mcp.json` → ecosystem registry → wrapper synthesis via `mcp-builder` → browser fallback). The `browser-discovery` subagent fills in services without docs using Playwright + Patchright (CDP-leak patches only); per-service legal opt-in via `DISCOVERY-LICENSE-NOTICE.md`; three-tier API classification (DOCUMENTED / INTERNAL / INTERNAL-HARDENED) with PII redaction + injection-detector output firewall.
- **Phase 4 — Spec Review.** Walkthrough of the proposed spec folder shape across 6 dimensions (workflows, agents, tools, governance, effort, hand-off completeness). User signs off before any files are written. Sub-gate: `spec_review_signed_off`.
- **Phase 5 — Spec Emission.** `spec-engine` subagent reads three input artifacts (`business-graph.json`, `agent-profiles.yaml`, `inventory.yaml`), validates them, and writes the canonical spec folder via a 6-step protocol. Single sub-gate: `spec_folder_emitted`. Emits `SPEC-EMISSION-REPORT.md` (success: input SHA256s, file count, tier breakdown, effort estimate) or `SPEC-EMISSION-FAILED-REPORT.md` (named-step failure with plain-English root cause).
- **Phase 6 — Spec Evolution.** When requirements change, rerun AgentBloc on the existing spec folder. Reads `.agentbloc/spec/` as ground truth, re-interviews where needed, re-emits affected files in place; `SPEC-EMISSION-REPORT.md` gets a new Revision History section with input-SHA256 deltas.
- **Portable spec folder output.** Markdown + YAML + JSON only. Layout: `README.md`, `AGENTS.md` (universal AI-tool entry), `CLAUDE.md` (Claude-Code-specific entry), `ROADMAP.md` (phased build plan + effort estimates), `workflows/` (falsifiable specs), `agents/<id>/` (role + prompts + tools + blast-radius + escalation), `integrations/` (`INVENTORY.md` + per-tier subfolders), `governance/` (blast-radius + audit-trail + pii-redaction + kill-switch + approval-protocol), `runtime/` (`BUILD.md` tool-agnostic build plan + `reference-impl/` advisory bash + `alternatives.md`).
- **Governance contracts that follow the spec.** Per-agent blast-radius taxonomy (L1–L4), 3-trigger kill switch, append-only JSONL audit log with PII redaction (12-field schema + `correlation_id` end-to-end tracing), Telegram approval thread separation (approvals / briefings / escalations), Spain DNI/NIE patterns when GDPR scope is detected.
- **Reference implementation.** Bash + cron + Telegram substrate (`helpers.sh`, `wake.sh`, `claude-wrap.sh`, `cron-generator.sh`, `telegram-send.sh`, `telegram-poll.sh`, `approval-router.sh`, `escalation-router.sh`, `activity-feed-merge.sh`, `hooks/autonomy-gate.sh`, `.env.example`) ships inside every emitted spec folder under `runtime/reference-impl/` as advisory content. The build session can use it verbatim, adapt it, or pick a different runtime — `runtime/alternatives.md` documents 8 options (n8n self-hosted / n8n cloud / Pipedream / Temporal / Inngest / custom Python / Claude Code Scheduled Tasks).
- **Universal hand-off.** The same spec folder works in Claude Code (reads `CLAUDE.md`), Codex CLI, Cursor, Gemini Code Assist, and OpenClaw (read `AGENTS.md`). The `BUILD.md` files per integration tier and `runtime/BUILD.md` are tool-agnostic.
- **Worked example.** `examples/arco-rooms-spec/` — full Arco Rooms (Spanish property-management) spec folder showing the canonical output for a 3-agent Pipeline team across 6 utility providers and 4 banks.
- **TAP test harness.** 160+ assertions across 3 scenarios (Arco Rooms, e-commerce support, freelance pipeline) covering structural validity, field schema, phase sequence, per-message assertions, category coverage, and SKILL.md reference integrity.

### Stack

Pure Claude Code skill (markdown only). SKILL.md ~250 lines + progressive disclosure via `references/`. No TypeScript runtime. Framework patterns inherited (not adopted as dependencies) from CrewAI (role/goal/backstory), AG2 (CaptainAgent dynamic team generation), Google ADK (Sequential/Parallel/Loop primitives), LangGraph (file-based state checkpointing), and Mastra (front-matter validators). Authoritative scope source: `docs/architecture.md`.

[1.0.0]: https://github.com/pablodelarco/agentbloc/releases/tag/v1.0.0
