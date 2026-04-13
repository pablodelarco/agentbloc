# AgentBloc

## What This Is

An open-source Claude Code skill that guides users from "I have a manual business process" to "I have a secure, auditable AI agent team running in production" through a structured 6-phase conversational flow. The skill handles the entire journey: deep interviewing, agent team design, integration discovery, step-by-step confirmation, mandatory dry run, and deployment artifact generation. The generated artifacts run natively on Claude Code + cron + MCP servers + Telegram with zero custom runtime.

## Core Value

A non-technical business owner can describe their problem and end up with a deployed, secure agent team without writing code and without improvised security scaffolding.

## Requirements

### Validated

(None yet -- ship to validate)

### Active

- [ ] 6-phase conversational flow (Interview, Design, Integration Analysis, Confirmation + Dry Run, Deployment, Evolution) with structural gate enforcement
- [ ] Technical-level detection and adaptive language (non-technical / basics / developer) with glossary support
- [ ] Security-first design: credential management, data classification (PII/PHI/financial), blast-radius scoring, audit logging, kill switches, rate limits, prompt-injection defense
- [ ] Integration evidence protocol: every claim backed by URL + package version + last-commit date, with [UNVERIFIED] fallback
- [ ] Deployment artifacts that run natively on Claude Code + cron + MCP + Telegram (no custom runtime)
- [ ] Mandatory dry run before production: agents execute against real data with side-effect tools stubbed
- [ ] GDPR/HIPAA/PCI-ready governance patterns activated by data classification
- [ ] Best-of-breed framework pattern library (CrewAI, LangGraph, AutoGen, n8n) referenced during design
- [ ] Phase 6 Evolution: post-deploy self-improvement loop with human approval gate
- [ ] Incident response runbook generation per deployment
- [ ] Lean SKILL.md (~250 lines) with progressive disclosure via references/
- [ ] GitHub repo that sells the vision in 30 seconds and lets a user try it in 5 minutes (README, badges, examples, screenshots)
- [ ] Bilingual support (English/Spanish) with conversation-language detection
- [ ] Complete artifact templates: team.yaml, agent.yaml, skill .md, governance.yaml, telegram.yaml, state schemas
- [ ] Test scenarios for end-to-end validation (ecommerce CS, real estate ops, freelance pipeline, etc.)

### Out of Scope

- TypeScript/Node.js runtime framework -- v2.0 only, contingent on v1.0 validating the consulting thesis
- Web UI or visual workflow builder -- AgentBloc is conversational, not click-UI
- CLI tool or API server -- the skill runs inside Claude Code
- Mobile app or native client
- SaaS multi-tenant hosting -- tenant isolation patterns are documented but hosting is self-serve
- Real-time streaming / WebSocket agent communication -- agents are cron-triggered batch processes
- Paid features / license gating -- fully open source

## Context

**Current state:** Two files in the repo: SKILL.md (539-line vibe-coded skeleton) and enterprise-readiness.md (audit identifying 18 prioritized gaps). The 5-phase flow is conceptually correct but untested, with critical gaps in security governance, enforcement mechanisms, and product completeness.

**Enterprise readiness audit findings (3 buckets):**
1. Security & data governance (CRITICAL) -- zero guidance on credentials, data classification, blast radius, audit, kill switches, incident response
2. Enforcement mechanisms (HIGH) -- hard gates are prose only, dry run missing, integration claims unverified
3. Product completeness (HIGH) -- self-improvement loop missing, framework integration missing, non-tech adaptation vestigial, 4 of 6 artifact templates undefined

**Runtime architecture:** Claude Code is the runtime. Each deployed agent is a Claude Code session triggered by cron, with tools defined via MCP servers, state tracked in YAML/JSON files, and reporting via Telegram threads. This is the proven ClaudeClaw pattern.

**Target audience:** Primary = SMB owners and ops teams (non-technical) automating manual processes. Secondary = developers and consultants accelerating agent deliveries.

**Business model:** Open-source skill on GitHub (portfolio piece) feeding premium consulting engagements on Upwork/LinkedIn.

## Constraints

- **Stack**: Pure Claude Code skill (markdown files only). No TypeScript runtime in v1.0. Artifacts target Claude Code + cron + MCP + Telegram
- **Compliance**: GDPR patterns mandatory (European market). HIPAA/PCI-ready patterns activated when data classification warrants
- **Deployment target**: Generated artifacts must work on any machine running Claude Code (self-hosted, VPS, cloud)
- **LLM flexibility**: Design patterns should reference model routing (Opus for complex reasoning, Sonnet for standard, Haiku for checks) but no vendor lock-in in the architecture
- **Repo quality**: Must look and feel professional. README, badges, CONTRIBUTING, examples, screenshots. First impression matters for consulting pipeline
- **Skill size**: SKILL.md capped at ~250 lines. Progressive disclosure via references/ directory

## Key Decisions

| Decision | Rationale | Outcome |
|----------|-----------|---------|
| Skill-only for v1.0 (no custom runtime) | Validates consulting thesis before building infrastructure. Claude Code is already the runtime | -- Pending |
| Claude Code + cron + MCP as deployment target | Proven in production (ClaudeClaw). Zero new dependencies | -- Pending |
| Lean SKILL.md + references/ architecture | 539 lines is too long for Claude Code best practices. Progressive disclosure improves reliability | -- Pending |
| Gate enforcement via [PHASE: N \| GATE: X] ritual | Prose-only gates can be skipped. Structural ritual forces acknowledgement | -- Pending |
| Open source with consulting upsell | OSS builds trust and portfolio. Premium consulting is the revenue layer | -- Pending |

## Evolution

This document evolves at phase transitions and milestone boundaries.

**After each phase transition** (via `/gsd-transition`):
1. Requirements invalidated? -> Move to Out of Scope with reason
2. Requirements validated? -> Move to Validated with phase reference
3. New requirements emerged? -> Add to Active
4. Decisions to log? -> Add to Key Decisions
5. "What This Is" still accurate? -> Update if drifted

**After each milestone** (via `/gsd-complete-milestone`):
1. Full review of all sections
2. Core Value check -- still the right priority?
3. Audit Out of Scope -- reasons still valid?
4. Update Context with current state

---
*Last updated: 2026-04-13 after initialization*
