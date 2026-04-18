# AgentBloc

## What This Is

An open-source Claude Code skill that guides users from "I have a manual business process" to "I have a secure, auditable AI agent team running in production" through a structured 6-phase conversational flow (Interview → Design → Integration Analysis → Confirmation + Dry Run → Deployment → Evolution). Generated artifacts run natively on Claude Code + cron + MCP servers + Telegram with zero custom runtime.

## Current State

v1.0 shipped 2026-04-18. Published to https://github.com/pablodelarco/agentbloc as a single anonymized orphan commit (`9c74c9e`). 68/68 requirements satisfied, 77/77 TAP tests passing, 4/4 CI jobs green. Full audit in `milestones/v1.0-MILESTONE-AUDIT.md`.

## Core Value

A non-technical business owner can describe their problem and end up with a deployed, secure agent team without writing code and without improvised security scaffolding.

## Requirements

### Validated

- ✓ 6-phase conversational flow with structural gate enforcement — v1.0
- ✓ Technical-level detection and adaptive language (non-technical / basics / developer) with glossary support — v1.0 (runtime behavior flagged `human_needed` for live testing)
- ✓ Security-first design: credential management, data classification (PII/PHI/financial), blast-radius scoring, audit logging, kill switches, rate limits, prompt-injection defense — v1.0
- ✓ Integration evidence protocol: URL + package version + last-commit date, with [UNVERIFIED] fallback — v1.0
- ✓ Deployment artifacts run natively on Claude Code + cron + MCP + Telegram (no custom runtime) — v1.0
- ✓ Mandatory dry run before production: agents execute against real data with side-effect tools stubbed — v1.0
- ✓ GDPR/HIPAA/PCI-ready governance patterns activated by data classification — v1.0
- ✓ Best-of-breed framework pattern library (CrewAI, LangGraph, n8n) referenced during design — v1.0
- ✓ Phase 6 Evolution: post-deploy self-improvement loop with human approval gate — v1.0
- ✓ Incident response runbook generation per deployment — v1.0
- ✓ Lean SKILL.md (~250 lines) with progressive disclosure via references/ — v1.0
- ✓ GitHub repo that sells the vision in 30 seconds and lets a user try it in 5 minutes — v1.0
- ✓ Bilingual support (English/Spanish) with conversation-language detection — v1.0
- ✓ Complete artifact templates: team.yaml, agent.yaml, skill .md, governance.yaml, telegram.yaml, state schemas — v1.0
- ✓ Test scenarios for end-to-end validation (ecommerce CS, real estate ops, freelance pipeline) — v1.0

### Active (v2.0 Discovery Agent)

Active requirements will be defined in fresh `REQUIREMENTS.md` via `/gsd-new-milestone v2.0`. Scope direction (from `v2.0-HANDOFF.md`):

- [ ] Discovery Agent: autonomous reverse engineering of web portals + API endpoints when no MCP exists. Output: `DISCOVERY-REPORT.md` per service (endpoints, auth flow, sample calls)
- [ ] Playwright MCP + CDP network interception + curl/jq validation as the discovery toolkit
- [ ] Foundation for v3.0 Builder Agent (auto-MCP generation) and v4.0 Self-Healing Evolution
- [ ] Reference patterns from oh-my-claudecode (Ralph mode + learner `.omc/skills/`), OpenClaw (ACP runtime substrate), Superpowers (Socratic spec extraction), LangGraph (stateful checkpoint)

### Out of Scope (post-v1.0 audit)

- Custom TypeScript/Node.js runtime in v1.0 — kept as v2.0+ option pending consulting-thesis validation
- Web UI or visual workflow builder — AgentBloc is conversational, not click-UI
- CLI tool or standalone API server — the skill runs inside Claude Code
- Mobile app or native client
- SaaS multi-tenant hosting — tenant isolation patterns are documented, hosting stays self-serve
- Real-time streaming / WebSocket agent communication — agents are cron-triggered batch processes
- Paid features / license gating — fully open source
- AutoGen integration patterns — in maintenance mode (superseded by Microsoft Agent Framework)

## Context

Shipped v1.0 contains ~4,500+ lines of markdown (SKILL.md hub + 19 reference files + 3 example walkthroughs + 2 bilingual glossaries + deployment artifacts + test scenarios + CI pipeline). Repo state:
- `master` branch: full private phase history with original Arco Rooms identifiers
- `main` branch: single orphan commit (anonymized) matching the public GitHub repo
- Remote `pablodelarco/agentbloc`: single commit `9c74c9e feat: AgentBloc v1.0`, CI green

**v2.0 kickoff context:** Entering v2.0 → v4.0 arc (4-6 milestones, ~6-8 months). Goal = autonomous Discovery + Builder + Self-healing on top of v1.0. GStack installed (`~/.claude/skills/gstack`, 38 skills linked) and will be used during phase work (`/office-hours`, `/plan-ceo-review`, `/review`, `/qa`, `/cso`, `/ship`). See `.planning/v2.0-HANDOFF.md` for full direction and framework research (OpenClaw, Superpowers, oh-my-claudecode, Hermes, Paperclip).

**Target audience:** Primary = SMB owners and ops teams automating manual processes. Secondary = developers and consultants accelerating agent deliveries.
**Business model:** Open-source skill on GitHub (portfolio piece) feeding premium consulting engagements on Upwork/LinkedIn.

## Constraints

- **Stack**: Pure Claude Code skill (markdown files only) in v1.0. v2.0+ may expand into TypeScript/Python runtime via OpenClaw ACP substrate if Discovery Agent needs long-lived processes. Artifacts still target Claude Code + cron + MCP + Telegram as the default deployment surface.
- **Compliance**: GDPR patterns mandatory (European market). HIPAA/PCI-ready patterns activated when data classification warrants.
- **Deployment target**: Generated artifacts must work on any machine running Claude Code (self-hosted, VPS, cloud).
- **LLM flexibility**: Design patterns reference model routing (Opus for complex reasoning, Sonnet for standard, Haiku for checks). No vendor lock-in in the architecture.
- **Repo quality**: Must look and feel professional. README, badges, CONTRIBUTING, examples, screenshots. First impression matters for consulting pipeline.
- **Skill size**: SKILL.md capped at ~250 lines. Progressive disclosure via references/ directory. (Met in v1.0.)
- **v2.0 legal posture:** reverse-engineering private APIs can violate ToS — Discovery Agent must require explicit per-service opt-in + disclaimer from the end user (design this early).

## Key Decisions

| Decision | Rationale | Outcome |
|----------|-----------|---------|
| Skill-only for v1.0 (no custom runtime) | Validates consulting thesis before building infrastructure | ✓ Validated — skill shipped on GitHub, market reception pending |
| Claude Code + cron + MCP as deployment target | Proven in production (ClaudeClaw). Zero new dependencies | ✓ Good — all v1.0 deployment artifacts ship with this stack |
| Lean SKILL.md + references/ architecture | 539-line monolith was too long for Claude Code best practices | ✓ Good — SKILL.md ~250 lines, progressive disclosure works |
| Gate enforcement via `[PHASE: N \| GATE: X]` ritual | Prose-only gates can be skipped | ✓ Good (modulo `human_needed` runtime behaviors that require live testing) |
| Open source with consulting upsell | OSS builds trust and portfolio; premium consulting is the revenue layer | — Pending market validation |
| Security promoted from Phase 4 to Phase 2 (roadmap revision) | All user-facing phases depend on a real security framework | ✓ Good — interview classifies PII/PHI, design assigns blast-radius, all cross-reference working |
| Publish strategy: `main` = single anonymized orphan commit, `master` = private full history | Clean public repo without personal-journey noise | ✓ Good — public repo professional; local history preserved |
| Use gstack (virtual engineering team skills) inside GSD phases for v2.0+ | GSD owns workflow (discuss/plan/execute/verify gates); gstack contributes perspective (CEO / eng / QA / sec / ship reviews) | — Pending first v2.0 phase |
| v2.0 target = Discovery Agent, then v3.0 Builder, then v4.0 Self-Healing | Pipeline from "no MCP" → "custom MCP" → "self-maintaining MCP" is the consulting-product thesis | — Pending v2.0 discuss-phase |

## Evolution

This document evolves at phase transitions and milestone boundaries.

**After each phase transition** (via `/gsd-transition`):
1. Requirements invalidated? → Move to Out of Scope with reason
2. Requirements validated? → Move to Validated with phase reference
3. New requirements emerged? → Add to Active
4. Decisions to log? → Add to Key Decisions
5. "What This Is" still accurate? → Update if drifted

**After each milestone** (via `/gsd-complete-milestone`):
1. Full review of all sections
2. Core Value check — still the right priority?
3. Audit Out of Scope — reasons still valid?
4. Update Context with current state

---
*Last updated: 2026-04-18 after v1.0 milestone*
