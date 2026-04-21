# Phase 10: Integration Discovery — MCP Path - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in [10-CONTEXT.md](10-CONTEXT.md) — this log preserves the alternatives considered and the reasoning for each autonomous pick.

**Date:** 2026-04-21
**Phase:** 10-integration-discovery-mcp-path
**Decision mode:** Autonomous (per `autonomous_mode` memo — Pablo authorized expert-judgment decisions on implementation gray areas derivable from PDF + REQUIREMENTS + prior phases). No interactive AskUserQuestion calls were made; each area below shows the options Claude considered and the rationale for the pick.
**Areas discussed:** Protocol reference structure · mcp-builder skill architecture · Wrapper MCP stack · Verification protocol depth · Halt-on-failure UX · Integration manifest location · Install-flow discipline · Credential gap UX · Evidence protocol extension · Relationship to v1.0 phase-3-integration.md · SKILL.md Phase 3 extensions · Canonical fixture shape

---

## Protocol Reference Structure (→ D-31)

| Option | Description | Selected |
|--------|-------------|----------|
| Single mega-reference | One `mcp-integration-protocol.md` with protocol + registry + schema inline | |
| Two references | Protocol + combined registry/schema | |
| Three references | Protocol + registry + schema, each a structural twin of a prior phase reference | ✓ |

**Auto-selected:** Three references — `mcp-integration-protocol.md` (imperative flow) + `mcp-ecosystem-registry.md` (declarative lookup) + `integration-manifest-schema.md` (output contract).

**Notes:** Mirrors the Phase 8/9 pattern of one-purpose-per-file (`business-graph-schema.md` vs `orchestration-patterns.md` vs `agent-profile-schema.md`). Single mega-file would balloon past 400 lines and violate the CLAUDE.md reference-file-conciseness norm.

---

## mcp-builder Skill Architecture (→ D-32)

| Option | Description | Selected |
|--------|-------------|----------|
| Subagent at `.claude/agents/mcp-builder.md` | Same pattern as Designer Agent (Phase 9) | |
| Nested skill at `.claude/skills/agentbloc/mcp-builder/` | Coupled to AgentBloc, not reusable | |
| Top-level skill at `.claude/skills/mcp-builder/` | Composable, reusable by other projects | ✓ |

**Auto-selected:** Top-level skill.

**Notes:** `mcp-builder` is a **composable utility**, not a contextual worker. A subagent forks context from the calling session; `mcp-builder` takes an API spec + tool surface and produces a file — it doesn't need the caller's context. Top-level placement signals composability and avoids coupling AgentBloc to its wrapper generator. Future projects (other skill suites, standalone users) can depend on `mcp-builder` without pulling in the AgentBloc skill hub.

---

## Wrapper MCP Stack (→ D-33)

| Option | Description | Selected |
|--------|-------------|----------|
| Python + `mcp` SDK + `uv` | Matches some reference MCP servers in the ecosystem | |
| TypeScript + `@modelcontextprotocol/sdk` + Node | Official SDK, broad ecosystem | |
| TypeScript + `@modelcontextprotocol/sdk` + Bun | Matches ClaudeClaw runtime (TS + Bun per PROJECT.md) | ✓ |
| Language-agnostic JSON-RPC template | Maximum flexibility, minimum ergonomics | |

**Auto-selected:** TypeScript + `@modelcontextprotocol/sdk` + Bun executor.

**Notes:** ClaudeClaw is the AgentBloc runtime platform (per PROJECT.md constraints). Generated wrappers must run on the same runtime — a Python wrapper would introduce a cross-language dep. Bun over Node because ClaudeClaw is Bun-native and `bun install + bun run` is faster than `npm install + node` for generated packages. Generator output shape: `.mcp/generated/<tool-id>/index.ts` + `package.json` + `README.md`, single-file server, deps limited to `@modelcontextprotocol/sdk`.

---

## Wrapper Tool Surface Depth (→ D-33b)

| Option | Description | Selected |
|--------|-------------|----------|
| Full API surface per service | Wrap every endpoint of the upstream API | |
| Minimum viable per agent | Read agent's `tools[]` + `outputs.schema` and expose only what's needed | ✓ |
| User-driven surface selection | Prompt user to pick which endpoints to wrap | |

**Auto-selected:** Minimum viable per agent.

**Notes:** Least-privilege is baked into AgentBloc's security posture (v1.0 credentials.md). A wrapper exposing only `list_unread(since_iso)` for a Recepcionista agent that reads Gmail is objectively safer than wrapping all of Gmail. Also keeps the verification scope small — Phase 10 D-34 can probe one tool; it cannot probe every Gmail endpoint. Full-surface wrappers belong to v3.0 Builder Agent (explicit deferral).

---

## Verification Protocol Depth (→ D-34)

| Option | Description | Selected |
|--------|-------------|----------|
| Single ping check | `tools/list` responds = verified | |
| Three-check prose checklist | Ping + scope-match + shape-probe | ✓ |
| Runtime probe suite (new TS code) | Automated test harness for every tool | |

**Auto-selected:** Three-check prose checklist.

**Notes:** INTEG-04 explicitly asks for "responds + has scopes + returns expected shape" — that maps to three checks. Running them as prose steps (Claude executes) preserves the Markdown-only skill constraint (no new npm deps for verification). A full runtime probe suite is attractive but premature for Phase 10 — Phase 16 TAP tests are the external rigor layer, and Phase 13 RUNTIME monitoring handles ongoing verification after deploy.

---

## Halt-on-Failure UX (→ D-35)

| Option | Description | Selected |
|--------|-------------|----------|
| Silent degradation | Mark tool as `pending`, proceed to Phase 4 | |
| Halt-and-name with specific gap | Write VERIFICATION-FAILED.md + halt gate + targeted conversation | ✓ |
| Halt-and-retry automatically | Retry verification 3× with backoff before surfacing | |

**Auto-selected:** Halt-and-name with specific gap.

**Notes:** INTEG-05 explicitly forbids silent failures. The v1.0 "specific failure, not generic" principle applies — users who get "verification failed" give up; users who get "GOOGLE_OAUTH_TOKEN missing gmail.modify scope, here's how to fix" resolve the issue and continue. Auto-retry is tempting but masks real issues (credential expired is permanent until the user rotates). Halt-and-name keeps the human in the loop exactly where it's productive.

---

## Integration Manifest Location (→ D-36)

| Option | Description | Selected |
|--------|-------------|----------|
| Extend `agent-profiles.yaml` with `integrations` section | Single source of truth | |
| Separate `integration-manifest.yaml` | Idempotent re-verification, stable design state | ✓ |
| Per-agent manifest files | Granular but fragments the verification surface | |

**Auto-selected:** Separate file at `.agentbloc/integrations/integration-manifest.yaml`.

**Notes:** The two files rotate on different cadences. Designer's output (agent-profiles.yaml) rotates when the user edits the team (rename, merge, drop). Verification state rotates when MCPs update, tokens expire, or Phase 6 Evolution re-verifies on schedule. Coupling them would make every re-verification mutate agent-profiles.yaml — which would violate idempotency and force Designer to re-run on every Phase 3 touch. Separating them keeps each artifact's lifecycle clean.

---

## Install-Flow Discipline (→ D-37)

| Option | Description | Selected |
|--------|-------------|----------|
| Claude runs `npx -y @mcp/xxx` via Bash | Zero-friction but executes arbitrary install scripts | |
| Approval-gated, Claude writes `.mcp.json` declaratively; user runs npx in shell | User retains install boundary | ✓ |
| Interactive install wizard | Over-engineered for Phase 10 | |

**Auto-selected:** Approval-gated, user-runs-npx, Claude-writes-`.mcp.json`-only.

**Notes:** `npx -y` download-and-execute is a real supply-chain attack surface — the package could run arbitrary install scripts with the user's shell privileges. v1.0 security posture (credentials.md, blast-radius.md) treats Claude as a privileged-but-auditable actor: Claude edits declarative config, user executes commands that mutate the environment. This preserves the auditable boundary. The approval + evidence + trust-tier presentation makes the decision informed, not friction.

---

## Credential Gap UX (→ D-38)

| Option | Description | Selected |
|--------|-------------|----------|
| Interactive conversation + .env.example auto-append | Phase 10 stays in the design-time conversation | ✓ |
| Telegram prompt to the user | Belongs to Phase 14 AUTON escalation UX | |
| Auto-generate stub credentials | Unsafe, violates least-privilege | |

**Auto-selected:** Interactive conversation + .env.example auto-append.

**Notes:** Phase 10 is design-time verification. The user is present in the conversation. Telegram-delivered credential prompts are a Phase 14 AUTON-02 concern (for deployed agents, where the user is not in the conversation). Auto-appending to `.env.example` gives the user a survivable checklist — if the session ends, the example file is still in the repo with the missing vars commented in.

---

## Evidence Protocol Extension (→ D-39)

| Option | Description | Selected |
|--------|-------------|----------|
| v1.0 evidence (URL + version + last-commit + publisher) only | Consistent with v1.0 | |
| v1.0 + MCP-specific fields (tools_declared, required_scopes, healthcheck_at, trust_tier) | Extends without breaking | ✓ |
| Completely new evidence shape | Breaks v1.0 compatibility | |

**Auto-selected:** v1.0 evidence fields + 4 MCP-specific extensions.

**Notes:** INTEG-06 explicitly asks for v1.0 evidence protocol carry-forward, but v1.0 was API-first framing and didn't know about MCP verification state. The 4 new fields answer questions v1.0 couldn't: what tools does this MCP expose? What scopes does it need? When was it last verified? What trust tier does it currently carry? `[UNVERIFIED]` flag semantics carry over unchanged.

---

## Relationship to v1.0 phase-3-integration.md (→ D-40)

| Option | Description | Selected |
|--------|-------------|----------|
| Rewrite from scratch with MCP-first framing | Loses 388 lines of correct v1.0 content | |
| Keep verbatim, add new reference alongside | MCP stays Priority 2, contradicting PROJECT.md | |
| Surgical edits — promote MCP to Priority 1, stub browser-fallback for Phase 11 | Preserves v1.0 content, aligns with v2.0 constraint | ✓ |
| Deprecate phase-3-integration.md entirely | Throws away 388 lines of still-valid content | |

**Auto-selected:** Surgical edits — 3 specific edits to preserve everything that's still correct.

**Notes:** The v1.0 reference's sections on evidence verification, trust scoring, decision matrices, credential cross-references, and prompt-injection assessment are all still correct in v2.0. Only the priority ladder needs reordering to match PROJECT.md's MCP-first constraint. Respecting Phase 9 D-29's budget discipline: small additive edits, not rewrites.

---

## SKILL.md Phase 3 Extensions (→ D-41)

| Option | Description | Selected |
|--------|-------------|----------|
| Mirror Phase 8/9 pattern exactly | Three surgical edits (State Transitions + Phase 3 entry + Phase 4 precondition) | ✓ |
| Minimal (just add the new gate value) | Loses the precondition safety and load-list hints | |
| Larger restructure | Risks breaking Phase 1/2 continuity | |

**Auto-selected:** Three surgical edits exactly mirroring the Phase 8/9 precedent.

**Notes:** The Phase 8 SKILL.md extension landed `business_graph_validated` + Phase 2 precondition + Phase 1 load-list extension. Phase 9 mirrored with `agent_profiles_validated` + Phase 3 precondition + Phase 2 load-list extension. Phase 10 mirrors with `mcp_integrations_verified` + Phase 4 precondition + Phase 3 load-list extension. SKILL.md stays under 250 lines (currently 170; expected +~12 for Phase 10 = ~182, still 68 lines of budget headroom).

---

## Canonical Fixture Shape (→ D-42)

| Option | Description | Selected |
|--------|-------------|----------|
| One-method-per-fixture (3 fixtures) | Covers each method in isolation | |
| Single fixture showing all three methods in one manifest | Matches Arco Rooms reality; demonstrates method diversity | ✓ |
| Minimal fixture (2 tools) | Insufficient to prove all methods work | |
| Maximal fixture (20+ tools) | Overkill for verification | |

**Auto-selected:** Single fixture at `.claude/skills/agentbloc/examples/arco-rooms-integration-manifest.yaml` with ~8 tools distributed across existing / ecosystem / wrapper paths.

**Notes:** Arco Rooms agents (Phase 9 D-30 lock: Gestor Cobros, Recepcionista, Gestor Documental) need ~8 tools total. Distributing across all three resolution methods in one fixture:
- **existing** (`.mcp.json` already has the entry): playwright-mcp, google-workspace-mcp
- **ecosystem** (npx install needed): telegram-mcp, xero-mcp, notion-mcp
- **wrapper** (generator needed): bbva (PSD2 API), arco-reservations (custom API), sms-twilio

Browser-fallback case is NOT in this fixture — Phase 11 ships its own fixture demonstrating `.agentbloc/discovery/<service-slug>/` for services without even an API.

---

## Claude's Discretion

These gray areas were explicitly left to Claude's implementation-time judgment during plan execution — they don't materially change the phase boundary:

- Exact wording of the 4-step search protocol prose in `mcp-integration-protocol.md`
- Registry curation depth (~20 entries seed from CLAUDE.md is the baseline)
- Single-file vs split wrapper template style (lean: single-file until ≥300 lines)
- Exact trust-tier thresholds (keep v1.0's; revisit during Phase 16 if the numbers feel wrong)
- Generated wrapper `package.json` name style (bare vs `@mcp/` scoped — lean: bare to avoid npm-scope pollution)
- Mermaid diagram in `mcp-integration-protocol.md` (include if ≤30 lines)

## Deferred Ideas

Surfaced during analysis, belong to later phases or later milestones (detail in [10-CONTEXT.md](10-CONTEXT.md) `<deferred>` section):

- Production-grade wrapper MCP with tests + CI + npm publishing → v3.0 Builder Agent
- Cross-run manifest diff (drift detection) → v2.5+
- Self-healing re-discovery → v4.0
- Auto-install via `npx` → explicitly rejected (never, security posture)
- Telegram credential prompts → Phase 14 AUTON
- Browser-fallback flow → Phase 11 BROWSER
- Per-tool rate-limit enforcement → Phase 14 CTRL
- MCP server sandboxing → v3.0 OpenClaw evaluation
- Localized (non-English) registry → v3.0 or later

---

*Log preserved: 2026-04-21. Decision audit trail for Phase 10 Integration Discovery (MCP Path). See [10-CONTEXT.md](10-CONTEXT.md) for the canonical decisions that downstream agents consume.*
