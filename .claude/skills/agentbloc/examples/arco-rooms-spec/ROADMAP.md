# Build Roadmap — Arco Rooms

> Phased build plan. Total estimate: ~21 CC-hours over ~3-4 elapsed days.
> Wave-parallelizable where noted.

## Phase 1 — Setup + Tier 1 EXISTS-MCP installs (~6 CC-hours)

**Goal:** All public MCP servers installed + smoke-tested before any
custom synthesis.

| Step | Work | Effort | Blocks |
|---|---|---|---|
| 1.1 | Copy `runtime/reference-impl/.env.example` → `.env`; fill credentials | 1h | All |
| 1.2 | Install `playwright-mcp` + smoke test | 1h | gestor-documental |
| 1.3 | Install `google-workspace-mcp` (Gmail + Drive + Docs scopes) + OAuth dance | 2h | gestor-documental |
| 1.4 | Install `telegram-mcp` (Bot API token); create 3 threads (approvals/briefings/escalations) | 1h | recepcionista |
| 1.5 | Install `gmail-mcp`, `google-sheets-mcp`, `notion-mcp` ecosystem entries | 1h | All |

Wave-parallelizable: 1.2, 1.3, 1.4 are independent.

## Phase 2 — Tier 2 NEEDS-MCP-WRAPPER synthesis (~11 CC-hours)

**Goal:** Both wrappers built + registered + tested.

| Step | Work | Effort | Blocks |
|---|---|---|---|
| 2.1 | Run `/mcp-build` for `bank-mcp` per `integrations/needs-mcp-wrapper/bank-mcp/BUILD.md` (PSD2 across 4 banks: BBVA, Santander, CaixaBank, Unicaja) | 6h | gestor-cobros |
| 2.2 | Run `/mcp-build` for `mapfre-api` per `integrations/needs-mcp-wrapper/mapfre-api/BUILD.md` | 5h | gestor-documental |

Wave-parallelizable: 2.1 and 2.2 are independent.

## Phase 3 — Agent + workflow wiring (~3 CC-hours)

**Goal:** Three agents wake correctly on schedule + handoff via state files.

| Step | Work | Effort |
|---|---|---|
| 3.1 | Materialize `agents/gestor-documental/` prompts.md as `wake.md`; wire to cron `0 22 * * *` | 0.5h |
| 3.2 | Materialize `agents/gestor-cobros/` prompts.md; wire to cron `30 22 * * *`; implement inter-agent inbox handler for `payment-status-query` from recepcionista | 1h |
| 3.3 | Materialize `agents/recepcionista/` prompts.md; wire to cron `0 23 * * *`; implement Telegram per-owner thread routing | 1.5h |

Sequential — agents depend on each other's state files.

## Phase 4 — Governance + safety wiring (~1.5 CC-hours)

**Goal:** All 5 governance contracts honored at runtime.

| Step | Work | Effort |
|---|---|---|
| 4.1 | Wire `runtime/reference-impl/hooks/autonomy-gate.sh` PreToolUse hook | 0.5h |
| 4.2 | Implement PII redactor (Spain DNI/NIE patterns) per `governance/pii-redaction.md` | 0.5h |
| 4.3 | Test 3-trigger kill switch (file flag + env var + `/halt-all` Telegram) | 0.5h |

## Phase 5 — End-to-end smoke test (~0.5 CC-hours)

**Goal:** One full pipeline run with all stubs disabled.

| Step | Work | Effort |
|---|---|---|
| 5.1 | Manual trigger gestor-documental at 22:00; verify invoices.json populated | 0.2h |
| 5.2 | Verify gestor-cobros wakes at 22:30, reads invoices, writes matches.json | 0.2h |
| 5.3 | Verify recepcionista wakes at 23:00, sends per-owner Telegram | 0.1h |

If all pass, install crontab via `cron-generator.sh apply` and let the
team run.

## Falsifiable team-level success criteria

- [ ] Day 1: 6 utility provider portals all yield invoices into
      `.agentbloc/state/invoices.json` within the 22:00-22:30 window
- [ ] Day 1: bank-mcp returns transactions across all 4 banks within
      the 22:30-23:00 window; matches.json populated with confidence
      scores
- [ ] Day 1: each owner receives exactly one Telegram message
      summarizing their property's invoices and matches by 23:15
- [ ] Day 1: zero PII leaks in `.agentbloc/logs/<date>/audit.jsonl`
      (PII test fixture passes)
- [ ] Day 1: `governance/audit-trail.md` 12-field schema validated by
      jq on every line
- [ ] Day 7: 3-trigger kill switch tested + recovered

## Total effort

| Phase | Effort |
|---|---|
| Phase 1 — Setup + Tier 1 | 6 CC-hours |
| Phase 2 — Tier 2 wrappers | 11 CC-hours |
| Phase 3 — Agent wiring | 3 CC-hours |
| Phase 4 — Governance | 1.5 CC-hours |
| Phase 5 — Smoke test | 0.5 CC-hours |
| **Total** | **~22 CC-hours** |

Conservative — overestimating builds trust, underestimating burns it.

## Re-emission

If requirements change (new utility provider, new bank, scope shift),
rerun AgentBloc on this folder. `spec-engine` reads existing inputs as
ground truth and re-emits affected files. The
`SPEC-EMISSION-REPORT.md` gets a new Revision History entry with input
SHA256 deltas.
