# SPEC-EMISSION-REPORT.md

**agentbloc_version:** 1.0.0
**emitted_at:** 2026-04-28T15:00:00Z
**destination:** `examples/arco-rooms-spec/`
**sub_gate:** `spec_folder_emitted` ✓ closed

## Summary

Three-agent property management team for Arco Rooms (Almeria, Spain).
Pipeline topology: invoice collection → payment matching →
per-owner reporting. Emitted from Phase 4 sign-off on 2026-04-28.

The spec folder is portable: any AI coding agent (Claude Code, Codex,
Gemini, Cursor, OpenClaw) can consume the folder and build the
running team. The folder is the contract; the build session picks the
runtime.

## Input snapshot SHA256s (forensics + drift detection)

| File | SHA256 |
|---|---|
| `business-graph.json` | `0546e27a532d77938e66ccc7968a22517422e3cf6bc215a41e6583b112bfbd3d` |
| `agent-profiles.yaml` | `0cf5835b448f107bb42bfeec090c2bfe21570c3334c659bdfed8c6bda809e5fd` |
| `inventory.yaml` | `2e7dff6f10e48764942b764a5468079fa4e9de140cb33fce048abf4ce62a5ec8` |

If any input changes on a future re-emission, this report's Revision
History will note the SHA delta.

## File tree (54 files written)

```
arco-rooms-spec/
├── README.md                                    (1.8K)
├── AGENTS.md                                    (3.0K)
├── CLAUDE.md                                    (4.2K)
├── ROADMAP.md                                   (4.0K)
├── SPEC-EMISSION-REPORT.md                      (this file)
│
├── workflows/
│   ├── 01-cobro-diario.md                       (2.5K)
│   └── 02-unmatched-payment-alert.md            (1.9K)
│
├── agents/
│   ├── gestor-documental/
│   │   ├── role.md                              (1.7K)
│   │   ├── prompts.md                           (3.4K)
│   │   ├── tools.md                             (2.5K)
│   │   ├── blast-radius.md                      (2.7K)
│   │   └── escalation.md                        (2.5K)
│   ├── gestor-cobros/
│   │   ├── role.md                              (1.7K)
│   │   ├── prompts.md                           (3.7K)
│   │   ├── tools.md                             (2.0K)
│   │   ├── blast-radius.md                      (2.6K)
│   │   └── escalation.md                        (1.9K)
│   └── recepcionista/
│       ├── role.md                              (1.7K)
│       ├── prompts.md                           (4.3K)
│       ├── tools.md                             (2.4K)
│       ├── blast-radius.md                      (3.4K)
│       └── escalation.md                        (2.7K)
│
├── integrations/
│   ├── INVENTORY.md                             (2.4K)
│   ├── existing/
│   │   ├── playwright-mcp.md                    (1.8K)
│   │   ├── google-workspace-mcp.md              (2.3K)
│   │   ├── telegram-mcp.md                      (2.6K)
│   │   ├── gmail-mcp.md                         (1.4K)
│   │   ├── google-sheets-mcp.md                 (1.4K)
│   │   └── notion-mcp.md                        (1.6K)
│   ├── needs-mcp-wrapper/
│   │   ├── bank-mcp/
│   │   │   ├── README.md                        (1.6K)
│   │   │   ├── BUILD.md                         (3.5K)
│   │   │   └── ENDPOINTS.md                     (2.3K)
│   │   └── mapfre-api/
│   │       ├── README.md                        (1.0K)
│   │       ├── BUILD.md                         (1.7K)
│   │       └── ENDPOINTS.md                     (1.5K)
│   ├── needs-n8n-flow/                          (empty — no Tier 3 tools)
│   ├── needs-webhook/                           (empty — no Tier 4 tools)
│   └── manual/                                  (empty — no Tier 5 tools)
│
├── governance/
│   ├── blast-radius.md                          (3.0K)
│   ├── audit-trail.md                           (3.4K)
│   ├── pii-redaction.md                         (3.7K)
│   ├── kill-switch.md                           (2.8K)
│   └── approval-protocol.md                     (4.0K)
│
└── runtime/
    ├── BUILD.md                                 (3.6K)
    ├── alternatives.md                          (3.7K)
    └── reference-impl/                          (13 files, ~95K)
        ├── .env.example
        ├── README.md
        ├── helpers.sh
        ├── wake.sh
        ├── claude-wrap.sh
        ├── cron-generator.sh
        ├── telegram-send.sh
        ├── telegram-poll.sh
        ├── approval-router.sh
        ├── escalation-router.sh
        ├── loop.sh
        ├── activity-feed-merge.sh
        └── hooks/autonomy-gate.sh
```

## Tier breakdown

| Tier | Count | Tools | Effort (CC-hours) |
|---|---|---|---|
| EXISTS-MCP | 6 | playwright-mcp, google-workspace-mcp, telegram-mcp, gmail-mcp, google-sheets-mcp, notion-mcp | 12 |
| NEEDS-MCP-WRAPPER | 2 | bank-mcp (PSD2 across BBVA, Santander, CaixaBank, Unicaja); mapfre-api | 11 |
| NEEDS-N8N-FLOW | 0 | — | 0 |
| NEEDS-WEBHOOK | 0 | — | 0 |
| MANUAL | 0 | — | 0 |
| **Total** | **8** | | **23** |

## Effort estimate

| Phase | Effort (CC-hours) | Phase ROADMAP reference |
|---|---|---|
| Phase 1 — Setup + Tier 1 EXISTS-MCP | 6 | Phase 1 |
| Phase 2 — Tier 2 wrappers (bank-mcp + mapfre-api) | 11 | Phase 2 |
| Phase 3 — Agent + workflow wiring | 3 | Phase 3 |
| Phase 4 — Governance + safety wiring | 1.5 | Phase 4 |
| Phase 5 — End-to-end smoke test | 0.5 | Phase 5 |
| **Total** | **~22 CC-hours** | |

Conservative estimate.

## Hand-off instructions for the build session

1. Open the spec folder in your AI coding tool of choice
2. Read `AGENTS.md` (any tool) or `CLAUDE.md` (Claude Code)
3. Walk `ROADMAP.md` Phase by Phase
4. Honor the 5 governance contracts in `governance/`
5. When done, the verification checklist at the end of `runtime/BUILD.md`
   tells you whether the team is built

## Provenance

Generated by AgentBloc v1.0.0 at 2026-04-28T15:00:00Z by hand-execution
of the Phase 5 spec-engine 6-step protocol per
`references/spec-emission-protocol.md`.

This is a **worked-example fixture** for the AgentBloc test suite +
documentation. It demonstrates that the architecture produces a
complete, build-ready spec folder from the three input artifacts.
Real-world spec emissions (when end users invoke `/agentbloc`) follow
the same 6-step protocol with the same canonical structure.

## Revision History

(none — initial emission 2026-04-28)
