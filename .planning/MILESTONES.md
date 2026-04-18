# AgentBloc — Milestones

Historical record of shipped versions. Full per-milestone archives live in `.planning/milestones/`.

---

## v1.0 — Initial Release

**Shipped:** 2026-04-18
**Phases:** 1-7 (18 plans, 18 SUMMARY files, 7 VERIFICATION files)
**Requirements:** 68/68 satisfied
**Tests:** 77/77 TAP checks passing, 4/4 CI jobs green
**Audit:** passed (see `milestones/v1.0-MILESTONE-AUDIT.md`)

**Delivered:**
A production-ready Claude Code skill (`SKILL.md` + progressive-disclosure `references/` directory) that guides a non-technical business owner through a 6-phase conversational flow — interview, design, integration analysis, confirmation + dry run, deployment, and evolution — producing an immediately-runnable `.agentbloc/` artifact tree that deploys to Claude Code + cron + MCP + Telegram with zero custom runtime.

**Key Accomplishments:**
1. SKILL.md redesigned from 539-line monolith into lean hub (~250 lines) + 19 progressive-disclosure reference files with structural gate enforcement (`[AGENTBLOC | PHASE: N | GATE: status | TECH: level]`)
2. Security framework (9 reference files) promoted to Phase 2 so every user-facing phase (interview, design, integration, deployment) depends on a real framework instead of improvised guidance — covers credentials, data classification (PII/PHI/financial), blast-radius scoring, audit logging, kill switches, rate limiting, GDPR/HIPAA/PCI, prompt injection defense, and tenant isolation
3. Deployment artifact generation produces a complete `.agentbloc/` directory: team.yaml, per-agent YAML, per-agent skill markdown, governance.yaml, telegram.yaml, state schemas, ClaudeClaw job definitions, SUMMARY deployment guide, and incident response runbook — all immediately runnable on Claude Code + cron + MCP + Telegram
4. Post-deployment self-improvement loop: weekly scans for new capabilities and security vulnerabilities in used dependencies, with mandatory human approval gate before any patch applies
5. Public repo polish: README (30-second pitch + 5-minute quickstart), 3 example walkthroughs (arco-rooms real-estate ops, ecommerce-support, freelance-pipeline), bilingual glossaries (EN + ES, 35+ terms), CONTRIBUTING / SECURITY / LICENSE / CHANGELOG, version badges, and a GitHub Actions CI pipeline with 4 parallel jobs (markdown lint, YAML schema validation, test scenarios, link-rot)
6. Replayable test harness: JSONL user-turn scenarios, TAP-compatible test runner, 77/77 checks passing locally and in CI on every push

**Known Deferred Items (at close):**
- Phase 01 `human_needed` verification: 3 runtime behaviors (skill activation via description, language auto-detection, technical-level inference) — design is correct, runtime behavior requires live testing. Recorded in STATE.md Deferred Items.
- Phase 05 `gaps_found` verification: resolved gaps noted in v1.0-MILESTONE-AUDIT.md `resolved_during_audit` section; remaining items are informational only.

**Archived:**
- `milestones/v1.0-ROADMAP.md`
- `milestones/v1.0-REQUIREMENTS.md`
- `milestones/v1.0-MILESTONE-AUDIT.md`
- `milestones/v1.0-phases/` (01-skill-foundation through 07-testing-and-ci)

**Git tag:** `v1.0`

**Next milestone:** v2.0 — Discovery Agent (autonomous reverse engineering of web portals and API endpoints when no MCP exists)
