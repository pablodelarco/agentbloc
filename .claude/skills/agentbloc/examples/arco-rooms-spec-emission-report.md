---
schema_version: 1
deployment_id: "3a4b5c6d-7e8f-4a0b-9c1d-2e3f4a5b6c7d"
deployed_at: "2026-04-24T18:30:00Z"
team_name: arco-rooms
agent_count: 3
integration_count: 3
verification_status: PARTIAL
idempotent_hash: "b2c3d4e5f60718293041526374859607182930415263748596071829304152a1"
sha256: "c3d4e5f60718293041526374859607182930415263748596071829304152a1b2"
---

# DEPLOY-REPORT: arco-rooms

> Canonical happy-path fixture for the Arco Rooms team (3 agents: gestor-documental, recepcionista, gestor-cobros). All data is synthetic; no real PII, no real credentials, no real account numbers. Fixture family linkage: `team_name: arco-rooms` matches the team identity declared in `examples/arco-rooms-agent-profiles.yaml` and consumed in `examples/arco-rooms-integration-manifest.yaml`.

## Created

| filepath | sha256 | generation_source |
|---|---|---|
| `.claude/skills/gestor-documental/SKILL.md` | `d4e5f60718293041526374859607182930415263748596071829304152a1b2c3` | `arco-rooms-agent-profiles.yaml + deployed-agent-skill-full.md.tmpl` |
| `.claude/skills/recepcionista/SKILL.md` | `e5f60718293041526374859607182930415263748596071829304152a1b2c3d4` | `arco-rooms-agent-profiles.yaml + deployed-agent-skill-semi.md.tmpl` |
| `.claude/skills/gestor-cobros/SKILL.md` | `f60718293041526374859607182930415263748596071829304152a1b2c3d4e5` | `arco-rooms-agent-profiles.yaml + deployed-agent-skill-semi.md.tmpl` |
| `.agentbloc/agents/gestor-documental/memory.md` | `0718293041526374859607182930415263748596071829304152a1b2c3d4e5f6` | `agent-memory-schema.md Section 2 template` |
| `.agentbloc/agents/gestor-documental/state.json` | `18293041526374859607182930415263748596071829304152a1b2c3d4e5f607` | `agent-memory-schema.md Section 3 initialization` |
| `.agentbloc/agents/gestor-documental/last-run.json` | `293041526374859607182930415263748596071829304152a1b2c3d4e5f60718` | `agent-memory-schema.md Section 4 initialization` |
| `.agentbloc/agents/recepcionista/memory.md` | `3041526374859607182930415263748596071829304152a1b2c3d4e5f6071829` | `agent-memory-schema.md Section 2 template` |
| `.agentbloc/agents/recepcionista/state.json` | `41526374859607182930415263748596071829304152a1b2c3d4e5f607182930` | `agent-memory-schema.md Section 3 initialization` |
| `.agentbloc/agents/recepcionista/last-run.json` | `526374859607182930415263748596071829304152a1b2c3d4e5f60718293041` | `agent-memory-schema.md Section 4 initialization` |
| `.agentbloc/agents/gestor-cobros/memory.md` | `6374859607182930415263748596071829304152a1b2c3d4e5f6071829304152` | `agent-memory-schema.md Section 2 template` |
| `.agentbloc/agents/gestor-cobros/state.json` | `74859607182930415263748596071829304152a1b2c3d4e5f607182930415263` | `agent-memory-schema.md Section 3 initialization` |
| `.agentbloc/agents/gestor-cobros/last-run.json` | `859607182930415263748596071829304152a1b2c3d4e5f60718293041526374` | `agent-memory-schema.md Section 4 initialization` |
| `.agentbloc/agents/registry.yaml` | `9607182930415263748596071829304152a1b2c3d4e5f607182930415263748` | `D-63 schema + arco-rooms-agent-profiles.yaml denormalization` |
| `.mcp.json` (delta: google-workspace-mcp, telegram-mcp, bank-mcp entries added) | `07182930415263748596071829304152a1b2c3d4e5f6071829304152637485960` | `arco-rooms-integration-manifest.yaml + D-66 merge-keep-existing` |

## Updated

(none, first deploy)

## Skipped

(none, first deploy)

## Pending User Actions

- Set `TELEGRAM_BOT_TOKEN` in `.env` as documented in `.env.example`. Required by `recepcionista` for daily owner-summary messages via `telegram-mcp`.
- Complete the Xero OAuth flow at `https://login.xero.com/identity/connect/authorize` and paste the returned refresh token into `.env` as `XERO_REFRESH_TOKEN`. Required by `gestor-cobros` for invoice posting (currently routed through `google-sheets-mcp` as a fallback; Xero wiring is scheduled once OAuth lands).
- Upload the Google Workspace service-account JSON key to `.secrets/google-workspace-key.json` (path pre-approved in `.mcp.json`). Required by `gestor-documental` for Gmail invoice-scraping and Drive file attachment.
- Set `N8N_BASE_URL` in `.env` (no event-triggered agents in this team, but the env var is reserved for forward compatibility per D-73 stub).
- Run `crontab .agentbloc/deploy/crontab.proposed` in your shell to register the Phase 13 cron entries. The proposed file contains 3 cron lines (one per agent) with the schedules declared in `arco-rooms-agent-profiles.yaml` (22:00 UTC for gestor-documental, 22:30 for gestor-cobros, 23:00 for recepcionista).

## Post-Deploy Verification

| check | status | note |
|---|---|---|
| SKILL.md loads cleanly (`claude agents list`) | PASS | 3 of 3 agent-ids present (gestor-documental, recepcionista, gestor-cobros) |
| MCP servers respond (`tools/list`) | PASS | 3 of 3 servers responded within timeout (google-workspace-mcp warm 5s, bank-mcp warm 8s, telegram-mcp warm 6s) |
| Cron registered (`crontab -l`) | SKIP | Phase 13 not yet shipped; cron verification deferred. `crontab.proposed` file written to `.agentbloc/deploy/crontab.proposed` for user review. |

Rollup: `verification_status: PARTIAL` (Check 1 PASS, Check 2 PASS, Check 3 SKIP with known soft-fail reason). Gate advances; Phase 13 will verify cron registration on first wake.

## Deployment Summary

3 agents deployed as peer skills under `.claude/skills/` per D-59a. 9 memory files initialized under `.agentbloc/agents/` per D-59b. Registry written at `.agentbloc/agents/registry.yaml` per D-59c. `.mcp.json` delta applied non-destructively per D-66 (3 new server entries added; no conflicts encountered). Idempotent hash `b2c3d4e5...304152a1` computed over all emitted artifacts; matches this report's frontmatter `idempotent_hash`. Next re-deploy with unchanged inputs will produce an equivalent `idempotent_hash` and route every artifact to the `## Skipped` section.

Team topology is `hierarchy` with `gestor-cobros` as the team lead. The reporting tree is flattened by a single level: gestor-cobros acts as the billing-and-reconciliation lead, with recepcionista (owner reporting) and gestor-documental (invoice collection) feeding into the lead's summary tick. Inter-agent messaging uses the ClaudeClaw `SendMessage` primitive declared in the Phase 9 `agent-profiles.yaml` triggers: `recepcionista` calls `gestor-cobros` with `message: payment-status-query` before composing the owner summary. Phase 13 Multi-Agent Runtime will wire the actual SendMessage channel on first wake.

## Autonomy Distribution

| agent | autonomy | template used | rationale |
|---|---|---|---|
| gestor-documental | full | `deployed-agent-skill-full.md.tmpl` | Pure internal state writes (invoice JSON under `.agentbloc/state/invoices.json`); blast_radius 2 is write-scoped; no external side-effects warrant approval gates |
| recepcionista | semi | `deployed-agent-skill-semi.md.tmpl` | blast_radius 4 (send-external, Telegram to owners); semi-autonomy with Telegram approval-before-send chosen over supervised because owners expect low-latency daily summaries |
| gestor-cobros | semi | `deployed-agent-skill-semi.md.tmpl` | blast_radius 2 (write-scoped to state files + Google Sheets); semi-autonomy gates the decision to escalate an overdue invoice past the 7-day threshold |

All three templates share an identical skeleton; the only per-file difference is the `<!-- agentbloc:template autonomy=<level> schema_version=1 -->` marker comment at the bottom of each rendered SKILL.md. Phase 14 Monitor uses this marker to route SKILL.md files to the correct approval-gate policy.

## Integration Surface

| tool_id | resolution_method | package | trust_tier | used_by |
|---|---|---|---|---|
| google-workspace-mcp | existing | `google_workspace_mcp@1.4.2` | MEDIUM | gestor-documental |
| telegram-mcp | existing | `telegram-mcp@0.3.8` | MEDIUM | recepcionista |
| bank-mcp | wrapper | `.mcp/generated/bank-mcp/` | MEDIUM | gestor-cobros |

All three MCP servers responded to the canonical `tools/list` probe during Step 8 post-deploy verification (per D-69). No `[DISCOVERED]`-tier entries; all integrations are VERIFIED-tier per Phase 10 INTG-04.

## Decisions Applied

Plan 12-01 decisions exercised by this deploy run:

- **D-59a:** SKILL.md files ship at `.claude/skills/<agent-id>/SKILL.md` (Claude Code native skill discovery path). The three Arco Rooms agents become peer skills to `agentbloc` and `mcp-builder`.
- **D-59b:** memory files ship at `.agentbloc/agents/<agent-id>/` (customer-mutable namespace). Registry co-located at `.agentbloc/agents/registry.yaml` per D-59c.
- **D-60:** every emitted JSON artifact (state.json, last-run.json) is canonicalized per RFC 8785 before SHA256 fingerprint computation. Timestamp-masking applied to all ISO-8601 values before hashing.
- **D-61:** no unified diffs were emitted this run because every artifact is new (Step 3 diff queue empty). A re-deploy after any profile edit would populate `## Updated` and emit diffs under `.agentbloc/deploy/pending-diffs/`.
- **D-62:** three separate per-autonomy templates selected by `agent.autonomy_level`. Zero in-template conditionals or loops.
- **D-63:** registry schema followed verbatim. Denormalized triggers and dependencies enable Phase 14 topology visualization without requiring a full registry crawl.
- **D-66:** `.mcp.json` merge applied non-destructively. All 3 server entries were `add-new` (no conflicts).
- **D-69:** post-deploy verification ran the canonical `tools/list` JSON-RPC probe on all 3 MCP servers. Warm responses within 5-8 seconds; no retries needed.
- **D-70:** halt-and-name not triggered. All steps completed cleanly; DEPLOY-FAILED-REPORT.md not emitted.
- **D-71:** one JSONL line appended to `.agentbloc/deploy/DEPLOY_HISTORY.jsonl` with the deploy summary for Phase 14 Monitor cross-run audit.
- **D-73:** n8n webhook placeholder stubs not emitted (no event-triggered agents in this team). `N8N_BASE_URL` reserved in `.env.example` per forward-compatibility rule.

Fixture notes for Phase 16 TAP replay: all sha256 values are synthetic placeholders that preserve the 64-hex shape for schema compliance but are not the actual hashes of the emitted content. Real deploy runs produce real hashes. Email placeholders, Telegram handles, and bank account numbers used in the agent profiles are synthetic test data at `example.invalid` with phone numbers in the documentation range. This fixture is safe to commit publicly. The deployment_id `3a4b5c6d-7e8f-4a0b-9c1d-2e3f4a5b6c7d` is a stable test fixture UUID; real deploy runs emit fresh UUIDs per `deployment_id`.

<!-- agentbloc:fingerprint sha256=c3d4e5f60718293041526374859607182930415263748596071829304152a1b2 generated_at=2026-04-24T18:30:00Z -->
