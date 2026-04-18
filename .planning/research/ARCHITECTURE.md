# Architecture Research — v2.0 Discovery Agent

**Domain:** Claude Code skill extension (autonomous web-portal reverse engineering layer on top of v1.0 conversational skill)
**Researched:** 2026-04-18
**Confidence:** HIGH for integration-point mapping against shipped v1.0 code; MEDIUM for checkpoint/resume semantics (depends on yet-to-ship OpenClaw ACP decision); MEDIUM for Evolution re-discovery interface (designed forward for v4.0, no live consumer yet).

---

## Executive Positioning

Discovery is **not a new user-facing phase** and it is **not a sibling skill**. It is a **dedicated Claude Code subagent** invoked from a new structural branch inside the existing Phase 3 (Deep Integration Analysis). The v1.0 Phase 3 already defines a 6-option search priority (`API > MCP > Playwright > email > webhook > manual`) terminating in "Manual Notification (Last Resort)" on line 107 of `phase-3-integration.md`. v2.0 inserts Discovery **between priority 5 (webhook) and priority 6 (manual)**, turning the fallback chain into:

```
API > MCP > Playwright > email > webhook > [NEW: Discovery Agent] > manual
```

This placement is load-bearing for four reasons:

1. Discovery is only attempted when all first-class integrations fail — preserves the "prefer official" hierarchy
2. Phase 3 already owns evidence verification, trust scoring, and user-approval gates — Discovery plugs into the same gate machinery
3. The `[UNVERIFIED]` marker (phase-3-integration.md line 144) already has a rendering path in the matrix — Discovery simply upgrades `[UNVERIFIED]` → `[DISCOVERED]` once a report lands
4. Subagent isolation gives Discovery its own context window (it reads HTML dumps, HAR files, response bodies — content that would blow the main session's context)

Discovery does NOT get its own Phase number. Inserting a "Phase 7" would break the 6-phase mental model SKILL.md advertises to users, and would require re-educating every example walkthrough. Instead, Discovery is a **Phase 3.5 structural branch**: visible as a sub-state of Phase 3 (`Gate: pending → blocked → discovery-running → discovery-complete → pending`), not as a top-level phase.

---

## System Overview

```
┌──────────────────────────────────────────────────────────────────────────────┐
│                      USER-FACING CONVERSATIONAL LAYER                         │
│                          (v1.0, unchanged in v2.0)                            │
├──────────────────────────────────────────────────────────────────────────────┤
│  Phase 1    Phase 2    Phase 3         Phase 4    Phase 5    Phase 6          │
│  Interview  Design     Integration     Confirm    Deploy     Evolution        │
│                        │                                      │               │
│                        │ [NEW BRANCH]                         │ [NEW HOOK]    │
│                        ▼                                      ▼               │
├──────────────────────────────────────────────────────────────────────────────┤
│                       DISCOVERY ORCHESTRATION LAYER                           │
│                            (v2.0, NEW)                                        │
│                                                                               │
│   ┌─────────────────┐    ┌────────────────┐    ┌──────────────────────┐      │
│   │ discovery-gate  │───▶│ tos-opt-in     │───▶│ discovery-agent      │      │
│   │ (new ref file)  │    │ (new ref file) │    │ (new subagent)       │      │
│   └─────────────────┘    └────────────────┘    └──────────┬───────────┘      │
│                                                            │                  │
│                              ┌─────────────────────────────┤                  │
│                              │                             │                  │
│   ┌──────────────────────────▼─────┐   ┌──────────────────▼──────────────┐   │
│   │   Discovery State Machine       │   │   Discovery Toolchain            │   │
│   │   (LangGraph-style, per-service)│   │  (Playwright MCP / CDP / curl)   │   │
│   │                                 │   │                                  │   │
│   │  pre-login → login → walk →     │   │  - Playwright MCP (browser)      │   │
│   │  capture → analyze → validate → │   │  - CDP network interception      │   │
│   │  report                         │   │  - curl + jq (replay + validate) │   │
│   │                                 │   │  - har-to-schema inference       │   │
│   └──────────────┬──────────────────┘   └──────────────────────────────────┘   │
│                  │                                                            │
├──────────────────┼────────────────────────────────────────────────────────────┤
│                  │           PERSISTENCE + GOVERNANCE LAYER                   │
│                  │              (v2.0 extensions to v1.0)                    │
├──────────────────┼────────────────────────────────────────────────────────────┤
│                  ▼                                                            │
│  .agentbloc/discovery/<service>/           .agentbloc/                        │
│  ├── state.json          (checkpoint)      ├── governance.yaml (EXT: disc.*) │
│  ├── DISCOVERY-REPORT.md (output)          ├── telegram.yaml   (EXT: thread) │
│  ├── har/*.har           (evidence)        └── logs/audit.jsonl (EXT: events)│
│  ├── responses/*.json    (fixtures)                                          │
│  ├── screenshots/*.png   (evidence)        .planning/research/  (unchanged)  │
│  └── tos-acknowledgement.json (legal)                                        │
└──────────────────────────────────────────────────────────────────────────────┘
```

### Component Responsibilities

| Component | Responsibility | Typical Implementation | Status |
|-----------|----------------|------------------------|--------|
| `references/phase-3-integration.md` | Existing user-facing Phase 3 protocol; gains a "Step 2.5: Discovery Branch" and a "Step 5b: Discovered Integration Rendering" | Markdown, ~+120 lines added | MODIFIED |
| `references/discovery-gate.md` | Hard-gate protocol: preconditions (no MCP/API/Playwright-happy-path verified), ToS opt-in collected, blast-radius score approved, Telegram approval thread configured | Markdown, ~200 lines | NEW |
| `references/discovery-protocol.md` | Socratic spec extraction (Superpowers methodology) for scoping a discovery target before invoking the subagent | Markdown, ~250 lines | NEW |
| `.claude/agents/discovery-agent.md` | Claude Code subagent definition: role, system prompt, allowed tools (Playwright MCP, Bash restricted to curl/jq, Read/Write scoped to `.agentbloc/discovery/`), model routing (Opus for inference, Sonnet for walk, Haiku for validation) | Subagent YAML+MD | NEW |
| `references/discovery-state-machine.md` | 7-state lifecycle (pre-login → login → walk → capture → analyze → validate → report), transition conditions, checkpoint schema, resume contract | Markdown + JSON schema, ~300 lines | NEW |
| `references/discovery-toolchain.md` | How to combine Playwright MCP + CDP network interception + curl/jq replay; fixture capture format; Ralph-style retry envelope (oh-my-claudecode pattern) | Markdown, ~220 lines | NEW |
| `references/discovery-report-schema.md` | `DISCOVERY-REPORT.md` output contract: endpoints[], auth_flow, sample_calls[], ui_selectors[], rate_limit_hints, confidence_per_endpoint | Markdown + markdown template, ~180 lines | NEW |
| `references/legal-posture.md` | Per-service ToS opt-in, disclaimer text templates, acknowledgement persistence, jurisdictions-where-forbidden list | Markdown, ~150 lines | NEW |
| `references/blast-radius.md` | **EXTEND:** add Level 2.5 "discovery-probe" between Level 2 and Level 3, with new approval semantics (Telegram approval per-target, not per-run) | Modified, +40 lines | MODIFIED |
| `references/credentials.md` | **EXTEND:** new "user-supplied discovery credentials" pattern — credentials the user types once to seed a login flow, held in-memory during the discovery session, never persisted to `.env` | Modified, +60 lines | MODIFIED |
| `references/audit-logging.md` | **EXTEND:** new event types (`discovery_started`, `tos_acknowledged`, `endpoint_captured`, `discovery_checkpoint`, `discovery_resumed`, `discovery_completed`, `discovery_failed`) | Modified, +80 lines | MODIFIED |
| `references/prompt-injection.md` | **EXTEND:** add Layer 5 "untrusted HTML during Discovery" — HTML pages a target portal returns during walk phase are the highest-risk injection surface in AgentBloc; mandatory isolated context | Modified, +40 lines | MODIFIED |
| `references/tenant-isolation.md` | **EXTEND:** discovery artifacts never cross tenant boundaries; `.agentbloc/discovery/<service>/` must be path-scoped per deployment | Modified, +30 lines | MODIFIED |
| `references/phase-6-evolution.md` | **EXTEND:** new Step 2b "Re-discovery Trigger" — when a deployed MCP (from v3.0 Builder) reports repeated failures, Evolution emits a `REDISCOVER-REQUEST.md` proposal routed through the same human approval gate as other patches | Modified, +80 lines | MODIFIED |
| `SKILL.md` | **EXTEND:** add Discovery Agent section (~20 lines) pointing to new reference files; bump version to 2.0.0 | Modified, +25 lines | MODIFIED |

**New files: 7. Modified files: 6. No deleted files. No renamed phases.**

---

## Invocation Contract (Phase 3 → Discovery)

This is the critical integration point. Current v1.0 Phase 3 fails silently to "Manual Notification" when no integration exists. v2.0 inserts a structured handoff.

### Handoff sequence (inside `phase-3-integration.md` Step 2)

```
For each service in inventory:
  Priority 1: API search       → found? build matrix row, next service
  Priority 2: MCP search       → found? build matrix row, next service
  Priority 3: Playwright assess→ automatable? build matrix row, next service
  Priority 4: Email scraping   → viable? build matrix row, next service
  Priority 5: Webhook          → available? build matrix row, next service
  [NEW] Step 2.5: Discovery Branch Decision
    - Check discovery-gate.md preconditions
    - If preconditions NOT met → fall through to Priority 6 (manual)
    - If preconditions met:
        a. Enter Phase 3 sub-state: Gate: blocked (reason: no-integration-found)
        b. Present discovery-gate.md user prompt (legal + blast-radius + credentials)
        c. On user approval:
           - Load discovery-protocol.md (Socratic scoping)
           - Invoke `.claude/agents/discovery-agent.md` as a subagent
           - Subagent writes to .agentbloc/discovery/<service>/
           - Main session polls for DISCOVERY-REPORT.md existence at next turn
        d. On user rejection → fall through to Priority 6 (manual)
  Priority 6: Manual notification (last resort, now rarely reached)
```

### Gate state transitions during Discovery

```
Phase 3: Deep Integration Analysis | Gate: pending | Level: developer
  ↓ (no integration found for service X)
Phase 3: Deep Integration Analysis | Gate: blocked | Level: developer
  ↓ (user approves Discovery for service X)
Phase 3: Deep Integration Analysis | Gate: discovery-running | Level: developer
  ↓ (subagent completes + writes DISCOVERY-REPORT.md)
Phase 3: Deep Integration Analysis | Gate: discovery-complete | Level: developer
  ↓ (main session reads report, adds matrix row with trust=DISCOVERED, user reviews)
Phase 3: Deep Integration Analysis | Gate: pending | Level: developer
  ↓ (remaining services analyzed)
Phase 3: Deep Integration Analysis | Gate: approved | Level: developer
```

Two new gate values (`blocked`, `discovery-running`, `discovery-complete`) extend the v1.0 state vocabulary (`pending / approved / blocked`). The existing `blocked` value — documented on SKILL.md line 31 — is repurposed for "blocked until Discovery runs" rather than only "blocked by a general issue." Parse logic in SKILL.md line 36-39 needs a minor update to allow the two new intermediate values, otherwise v1.0 post-compaction recovery cannot re-enter Discovery context after a session break.

### Why not a new Phase 7?

- User-facing 6-phase narrative is a v1.0 brand promise; all three example walkthroughs end at Phase 6
- Discovery is machinery, not a user milestone — users think of it as "research that Phase 3 does for hard services"
- A new phase would need its own hard-gate entry in the top-5 list, diluting the existing structural enforcement
- Subagent pattern matches Claude Code idioms: delegated context, isolated tool access, clean return to parent

---

## Discovery Agent: Subagent Design

### Why a subagent, not an inline Phase 3 branch?

Four reasons, all load-bearing:

1. **Context isolation.** Discovery ingests raw HTML pages (kilobytes each), HAR files (10s of MB), and response bodies. Running this in the main conversation would evict Phase 1 interview context and break the 6-phase narrative. Subagents get their own window.
2. **Tool scoping.** The main AgentBloc conversation never touches Playwright. Subagent YAML frontmatter can restrict tools to `Playwright, Bash, Read, Write` with Bash path-restricted to `curl|jq|npx`.
3. **Model routing.** The discovery walk is Sonnet-class work; endpoint-schema inference from captured responses is Opus-class; validation replay is Haiku. Subagent can route per-state-machine-state.
4. **Compaction independence.** If the main session compacts mid-discovery, the subagent keeps running. When it finishes, the main session reads the report file from disk — no context recovery needed.

### Subagent file shape

```markdown
---
name: discovery-agent
description: Reverse-engineers web portals when no MCP or API exists. Captures endpoints, auth flow, and sample calls into DISCOVERY-REPORT.md. Invoked only from AgentBloc Phase 3 after discovery-gate preconditions pass.
allowed-tools:
  - Read
  - Write
  - Bash(curl:*, jq:*, npx:@playwright/mcp:*, gh:*)
  - WebFetch
  - WebSearch
  - Grep
  - Glob
context: fork
model-routing:
  default: sonnet
  states:
    analyze: opus
    validate: haiku
---

# Discovery Agent (v2.0)

You are invoked from AgentBloc Phase 3 with a scoped discovery target...
```

`context: fork` is critical — this is the one skill-family context-reset in the whole pipeline. Everything else keeps the main conversation intact.

---

## State Architecture

### Where state lives

```
.agentbloc/                                     # Deployment artifacts (v1.0 unchanged)
├── team.yaml                                   # v1.0
├── governance.yaml                             # v1.0 + EXTENDED disc.* block
├── telegram.yaml                               # v1.0 + EXTENDED discovery thread
├── agents/                                     # v1.0
├── state/                                      # v1.0 (runtime agent state)
├── logs/
│   └── audit.jsonl                             # v1.0 + EXTENDED event types
└── discovery/                                  # v2.0 NEW
    └── <service-slug>/                         # one directory per target service
        ├── state.json                          # checkpoint (RESUMABLE)
        ├── tos-acknowledgement.json            # legal record (IMMUTABLE)
        ├── DISCOVERY-REPORT.md                 # final output (generated)
        ├── har/                                # captured network traffic
        │   ├── 001-login.har
        │   ├── 002-walk-dashboard.har
        │   └── 003-walk-detail.har
        ├── responses/                          # raw response fixtures
        │   ├── endpoints/
        │   │   └── <endpoint-hash>.json
        │   └── samples/
        │       └── <flow-name>-<step>.json
        ├── screenshots/                        # visual evidence for report
        │   ├── login-success.png
        │   └── dashboard-captured.png
        └── retry-ledger.jsonl                  # Ralph-style retry log
```

### Checkpoint schema (`state.json`)

```json
{
  "discovery_id": "disc-2026-04-18-acme-portal-001",
  "service_slug": "acme-portal",
  "service_url": "https://portal.acme.example",
  "target_workflow": "List and download monthly invoices",
  "initiated_by_phase_3_turn": 47,
  "parent_session_id": "agentbloc-2026-04-18-xyz",
  "current_state": "walk",
  "state_history": [
    { "state": "pre-login", "entered_at": "2026-04-18T10:00:00Z", "exited_at": "2026-04-18T10:02:00Z", "status": "ok" },
    { "state": "login",     "entered_at": "2026-04-18T10:02:00Z", "exited_at": "2026-04-18T10:04:30Z", "status": "ok" },
    { "state": "walk",      "entered_at": "2026-04-18T10:04:30Z", "exited_at": null,                    "status": "running" }
  ],
  "credentials_consumed": true,
  "credentials_in_memory": "REDACTED",
  "tos_acknowledged": true,
  "tos_acknowledgement_ref": "tos-acknowledgement.json",
  "captured_endpoints_count": 14,
  "last_har_written": "har/002-walk-dashboard.har",
  "retry_count": 2,
  "retry_ledger_tail": "retry-ledger.jsonl:line:7",
  "resumable": true,
  "blocked_on": null,
  "expected_final_state": "report",
  "model_budget_consumed_usd": 3.42,
  "model_budget_limit_usd": 25.00
}
```

### Resume contract

When a Discovery session is killed (context compaction, user /exit, OS reboot), any new Claude Code session can resume by:

1. Reading `state.json` for the target service
2. If `resumable: true` and `current_state != "report"` → invoke `discovery-agent` subagent with `--resume <service-slug>` argument
3. Subagent reloads state history, replays last successful state's exit conditions, re-enters next state
4. `retry-ledger.jsonl` shows prior failed attempts; subagent avoids repeating them

This is the LangGraph checkpointing pattern adapted to file-based state (per v1.0 decision D — "Use YAML for human-authored config, JSON for machine-written state").

### Why `.agentbloc/discovery/` and NOT `.planning/discovery/`?

- `.planning/` is GSD scratch space (for AgentBloc's own development). It is ephemeral, gitignored at the product level, and belongs to the skill author, not the skill user.
- `.agentbloc/` is the deployment artifact directory — the user's own workspace. Discovery runs against **the user's** services on **the user's** behalf, producing artifacts the user owns.
- The deployed MCP that v3.0 Builder will generate from `DISCOVERY-REPORT.md` also lives in `.agentbloc/` (or wherever the user publishes it). Keeping Discovery output next to other deployment artifacts matches the mental model.
- HAR files + screenshots can contain user PII and credentials — they must live under the user's governance rules, not in a planning scratch space.

---

## Data Flow

### Discovery Agent inputs (from Phase 3)

```json
{
  "service_slug": "acme-portal",
  "service_url": "https://portal.acme.example",
  "target_workflow_description": "Login, navigate to Invoices, list all invoices from last 90 days, download PDFs",
  "agent_blast_radius_hint": "read-only",
  "credentials_mode": "user-supplied-in-session",
  "credentials_ref": null,
  "tos_acknowledgement": {
    "service": "acme-portal",
    "user_id": "operator",
    "acknowledged_at": "2026-04-18T09:58:00Z",
    "disclaimer_version": "v1",
    "jurisdiction_checked": "EU/Spain",
    "user_attests": ["i_own_this_account", "not_violating_tos_knowingly", "read_disclaimer"]
  },
  "scoping": {
    "in_scope": ["login flow", "invoice list view", "invoice detail view"],
    "out_of_scope": ["admin endpoints", "other tenants' data", "write operations"],
    "stop_conditions": ["first write attempt", "admin URL discovered", "MFA challenge"]
  },
  "budget": {
    "max_model_usd": 25.00,
    "max_wall_clock_minutes": 120,
    "max_retries_per_state": 3
  }
}
```

### Discovery Agent outputs

Primary output: `DISCOVERY-REPORT.md` with a strict schema (see `discovery-report-schema.md`):

```markdown
# Discovery Report: Acme Portal

**Service:** acme-portal
**Discovered:** 2026-04-18
**Discovery ID:** disc-2026-04-18-acme-portal-001
**Target Workflow:** List and download monthly invoices
**Confidence:** MEDIUM
**Legal Posture:** User-acknowledged ToS opt-in (see tos-acknowledgement.json)

## Auth Flow

**Method:** Form-based session cookie
**Endpoints:**
- POST /api/login  (Content-Type: application/json; body: {email, password})
- GET  /api/session (returns 200 + user profile if authenticated)

## Endpoints (14 discovered)

| # | Method | Path | Purpose | Confidence | Sample |
|---|--------|------|---------|------------|--------|
| 1 | POST   | /api/login | Establish session | HIGH | responses/endpoints/001.json |
| 2 | GET    | /api/invoices?from={date}&to={date} | List invoices | HIGH | responses/endpoints/002.json |
| ...

## Sample Calls (replayable via curl)

### 1. Login

\`\`\`bash
curl -c cookies.txt -X POST https://portal.acme.example/api/login \\
  -H 'Content-Type: application/json' \\
  -d '{"email":"$ACME_EMAIL","password":"$ACME_PASSWORD"}'
\`\`\`
...

## UI Selectors (Playwright fallback)

| Action | Selector Strategy | Selector |
|--------|-------------------|----------|
| Submit login | role=button | button[type=submit] |
| Invoice row | role=row | tr[data-invoice-id] |
| ...

## Rate Limit Hints

- Observed: no explicit 429s in 14 captured requests
- Suggested: 1 req/sec conservative starting point
- Header hints: none found (no X-RateLimit-* headers)

## Evidence

- HAR files: har/*.har
- Response fixtures: responses/
- Screenshots: screenshots/

## Open Questions

- MFA flow not captured (user confirmed MFA disabled on test account)
- Write endpoints not explored (out of scope per scoping)
- Admin UI present but not entered (out of scope)
```

Secondary outputs (evidence):

- `har/*.har` — captured browser traffic (Chrome DevTools Protocol format)
- `responses/endpoints/<hash>.json` — one fixture per unique endpoint
- `responses/samples/<flow>-<step>.json` — flow-structured samples
- `screenshots/*.png` — visual evidence per state transition
- `retry-ledger.jsonl` — append-only log of retry attempts
- `tos-acknowledgement.json` — immutable legal record

### How Phase 3 consumes the report

When `DISCOVERY-REPORT.md` exists for a service that was `blocked` during Step 2:

1. Phase 3 re-enters the service (from Step 2.5 resume point)
2. Builds a new decision matrix row: `trust = DISCOVERED (custom)`, `package = discovery/<service>/`, `setup complexity = HIGH (requires v3.0 Builder to produce MCP)`
3. In v2.0, Discovery output is treated as an `[UNVERIFIED-BUT-DOCUMENTED]` integration method. User can still accept it as best-available.
4. In v3.0, the Builder Agent will consume `DISCOVERY-REPORT.md` and generate a production MCP — that MCP then populates Priority 2 in future Phase 3 runs.

---

## Security Integration

Every existing v1.0 security reference needs review. Eight security references exist in v1.0; five need extension, three are unaffected.

### `credentials.md` — EXTEND

**New pattern:** User-supplied discovery credentials.

The v1.0 decision tree (credentials.md line 22-36) covers OAuth / scoped API key / admin token for **deployed agents**. Discovery is different: the user is authenticating **as themselves** to a portal they own, typing credentials into a prompt, the credentials never hit disk. New sub-decision-tree:

```
Discovery target needs login?
  YES: How will credentials be provided?
    a) User types credentials into Claude Code conversation (in-memory only)
       → Pattern: credentials_mode: "user-supplied-in-session"
       → Subagent receives credentials via secure prompt
       → Credentials zeroed from state.json before checkpoint write
       → On resume, subagent re-prompts user (safer than persistence)
    b) Service offers OAuth that user has already authorized
       → Pattern: credentials_mode: "oauth-delegated"
       → Follow normal OAuth flow from credentials.md
    c) Service offers an API key user is willing to scope
       → Pattern: credentials_mode: "scoped-api-key-for-discovery"
       → Key stored in .env with rotation flag = 7 days
  NO: Target is public
    → Pattern: credentials_mode: "none"
```

**Rotation policy extension:** discovery-mode credentials expire at end of discovery session (in-memory) OR at 24h (API key fallback).

### `blast-radius.md` — EXTEND

**New level:** Level 2.5 "discovery-probe."

The v1.0 scoring (blast-radius.md line 22-28) has 4 levels. Discovery creates a sixth agent type that doesn't fit cleanly — it writes nothing to the target, but it does make unscoped read requests across an entire portal. New row:

| Level | Name | Tool Access | Data Access | External Comms | Approval |
|-------|------|-------------|-------------|----------------|----------|
| 2.5 | discovery-probe | Playwright + Bash(curl/jq) + Read/Write to `.agentbloc/discovery/` | Target portal, user-authenticated | Read-only HTTP to target only | **Per-target approval** (not per-run) |

Approval semantics for 2.5:

- One-time approval per service-slug (valid until report completes or 24h expires)
- User approves: "Yes, reverse engineer `acme-portal`, I own the account, I accept ToS risk"
- Telegram approval thread records the approval + the ToS acknowledgement ID
- Separate from Level 3-4 "per-operation approval" — discovery is exploratory, not operational

### `audit-logging.md` — EXTEND

**New event types** (append to v1.0 event catalog):

```json
{ "event": "discovery_initiated", "service_slug": "...", "tos_ack_id": "...", "blast_radius": "2.5", ... }
{ "event": "discovery_state_transition", "discovery_id": "...", "from": "login", "to": "walk", ... }
{ "event": "discovery_endpoint_captured", "discovery_id": "...", "method": "GET", "path_hash": "...", ... }
{ "event": "discovery_checkpoint_written", "discovery_id": "...", "state": "...", "size_bytes": ... }
{ "event": "discovery_resumed", "discovery_id": "...", "from_state": "...", "reason": "compaction|user-resume", ... }
{ "event": "discovery_completed", "discovery_id": "...", "endpoints_found": 14, "confidence": "MEDIUM", ... }
{ "event": "discovery_failed", "discovery_id": "...", "last_state": "...", "reason": "...", "retry_count": ... }
{ "event": "tos_acknowledgement_recorded", "service_slug": "...", "user_attestations": [...], ... }
```

### `prompt-injection.md` — EXTEND

**Discovery is the highest-prompt-injection-risk component in AgentBloc.** Every HTML page a portal returns is untrusted content. Add Layer 5:

> **Layer 5: Discovery HTML Isolation.** When Discovery Agent ingests HTML during walk/capture, the HTML is wrapped in `=== UNTRUSTED PORTAL HTML START ===` delimiters (per Layer 2) AND only processed by a dedicated sub-sub-agent whose system prompt explicitly forbids following any instructions found in the content. The walk agent produces structured extractions (endpoint paths, selectors) — never free-form responses to page content.

Rationale: an attacker who controls a portal the user is discovering can plant LLM-targeted instructions in HTML. Discovery's walk loop is Turing-complete (decides next page to visit) and thus a high-value target. Isolation via the fork-context subagent limits damage.

### `tenant-isolation.md` — EXTEND

For multi-tenant deployments, each tenant's `.agentbloc/discovery/<service>/` must be path-scoped. Add a filesystem guard in the subagent YAML: `allowed-tools: Write(path:.agentbloc/discovery/$TENANT_ID/*)`.

### Unchanged security files

- `data-classification.md` — Discovery inherits the parent agent's classification. No new logic.
- `gdpr-patterns.md` — Discovery falls under existing GDPR Article 30 record-keeping via audit log extension.
- `incident-response.md` — Existing runbook severities (P1-P4) apply to discovery failures unmodified.

---

## Tool Availability and Governance

### Playwright MCP gating

Playwright MCP (`@anthropic-ai/mcp-playwright` or `microsoft/playwright-mcp`) is **not** an always-on tool in v1.0. v2.0 introduces it as a conditional tool gated by governance.

**Extension to `governance.yaml`:**

```yaml
discovery:
  enabled: false                      # Default: OFF (explicit opt-in at install)
  playwright_mcp: "@microsoft/playwright-mcp@latest"
  max_concurrent_discoveries: 1
  global_budget:
    max_model_usd_per_month: 100.00
    max_discoveries_per_month: 20
  per_target:
    max_model_usd: 25.00
    max_wall_clock_minutes: 120
    require_tos_acknowledgement: true
    require_telegram_approval: true
  forbidden_targets:
    # Jurisdictions where reverse engineering is unambiguously illegal
    - "*.gov"
    - "*.mil"
    # User-extendable blocklist
  approval_thread: discovery-approvals    # new Telegram thread per telegram.yaml
```

### Subagent tool scope (enforced in discovery-agent.md frontmatter)

```
allowed-tools:
  - Read(path:.agentbloc/discovery/<service>/**)
  - Write(path:.agentbloc/discovery/<service>/**)
  - Bash(curl:*, jq:*, npx:@playwright/mcp:*)
  - WebFetch                                # for documentation lookups during analyze
  - WebSearch                               # for "{service} API documentation" during pre-login
  - mcp__playwright__*                      # Playwright MCP tools
```

Deny-by-default: main conversation subagent cannot write outside its service directory, cannot run arbitrary bash, cannot touch deployment artifacts in `.agentbloc/agents/` or `.agentbloc/state/`.

---

## Phase 6 Evolution: Re-Discovery Trigger Interface

This is the forward-compatibility contract for v4.0 Self-Healing. Designing it now — even if v2.0 only implements the observer side — prevents a v4.0 architecture rewrite.

### Failure signal path

```
Deployed agent runs → calls MCP generated by v3.0 Builder → MCP call fails repeatedly
         ↓
runtime state machine records failures in .agentbloc/state/<agent>-state.json
         ↓
Weekly Phase 6 evolution scan (phase-6-evolution.md Step 3) inspects state files
         ↓
[NEW Step 2b] Re-discovery detection:
  - Count consecutive failures for each integration in last 7 days
  - If >= failure_threshold (default: 3) AND integration came from Discovery:
      emit a REDISCOVER-REQUEST proposal
         ↓
Proposal routed through existing human approval gate (EVOL-05, phase-6-evolution.md line 277)
         ↓
On approval: re-invoke discovery-agent with --resume-existing flag
         ↓
New DISCOVERY-REPORT.md replaces old; v3.0 Builder re-generates MCP (v4.0 scope)
```

### REDISCOVER-REQUEST proposal schema (new patch proposal type)

```markdown
# Rediscovery Request: [Service Name]

**Date:** [YYYY-MM-DD]
**Scan ID:** [evol-scan-NNN]
**Priority:** [P2 HIGH | P3 MEDIUM]    # P1 reserved for CVEs
**Trigger:** deployed-mcp-failure-threshold-exceeded

## Failure Signal

- Integration: [service-slug]
- MCP version: [from v3.0 Builder]
- Consecutive failures: [N]
- First failure: [timestamp]
- Last failure: [timestamp]
- Failure fingerprints: [top 3 error patterns]
- Affected agents: [agent-name-1, agent-name-2]

## Proposed Action

Re-run Discovery Agent against `[service-slug]` to detect schema drift, new UI selectors,
or auth-flow changes. Previous DISCOVERY-REPORT.md version: [hash].

## Estimated Cost

- Model budget: ~$[N] USD (based on prior run)
- Wall clock: ~[N] minutes
- Downtime during rediscovery: none (deployed agents continue with broken integration
  until replacement MCP is generated in v3.0 Builder phase)

## Approval Required

[Standard EVOL-05 approval semantics]
```

### Why this is safe for v2.0 to ship

- v2.0 only **emits** the REDISCOVER-REQUEST — no auto-rediscovery loop
- The proposal goes through the same Telegram approval as every other Evolution proposal
- If user approves, v2.0 can re-run Discovery manually; v4.0 adds the full auto-regen loop
- The schema is defined now, so when v4.0 ships, no contract change is needed

### The interface is a FILE CONTRACT, not a function call

The cleanest decoupling is: Evolution writes `REDISCOVER-REQUEST.md`, user approves, human or future-v4.0-automation invokes `discovery-agent --resume-existing <service>`. No tight coupling between Evolution and Discovery subagents. This matches the v1.0 pattern where Phase 5 emits artifact files and Phase 6 consumes them.

---

## Recommended Project Structure (delta from v1.0)

```
.claude/skills/agentbloc/
├── SKILL.md                              # MODIFIED: +discovery pointer, v2.0.0
├── references/
│   ├── phase-1-interview.md              # unchanged
│   ├── phase-2-design.md                 # unchanged
│   ├── phase-3-integration.md            # MODIFIED: +Step 2.5 Discovery Branch
│   ├── phase-4-confirmation.md           # unchanged
│   ├── phase-5-deployment.md             # unchanged
│   ├── phase-6-evolution.md              # MODIFIED: +Step 2b Re-discovery Trigger
│   │
│   ├── discovery-gate.md                 # NEW
│   ├── discovery-protocol.md             # NEW (Socratic scoping)
│   ├── discovery-state-machine.md        # NEW (7-state lifecycle)
│   ├── discovery-toolchain.md            # NEW (Playwright/CDP/curl recipes)
│   ├── discovery-report-schema.md        # NEW (output contract)
│   ├── legal-posture.md                  # NEW (ToS opt-in)
│   │
│   ├── credentials.md                    # MODIFIED: +user-supplied-in-session
│   ├── blast-radius.md                   # MODIFIED: +Level 2.5 discovery-probe
│   ├── audit-logging.md                  # MODIFIED: +8 discovery events
│   ├── prompt-injection.md               # MODIFIED: +Layer 5 HTML isolation
│   ├── tenant-isolation.md               # MODIFIED: +discovery path scoping
│   ├── data-classification.md            # unchanged
│   ├── gdpr-patterns.md                  # unchanged
│   ├── incident-response.md              # unchanged
│   ├── frameworks.md                     # unchanged
│   ├── telegram-patterns.md              # unchanged
│   ├── scheduling.md                     # unchanged
│   ├── glossary-en.md                    # MODIFIED: +discovery terms
│   └── glossary-es.md                    # MODIFIED: +discovery terms
│
├── .claude/agents/                       # NEW directory
│   └── discovery-agent.md                # NEW subagent definition
│
├── templates/                            # MODIFIED: extend governance.yaml.tmpl + telegram.yaml.tmpl
│   ├── governance.yaml.tmpl              # MODIFIED: +discovery: block
│   ├── telegram.yaml.tmpl                # MODIFIED: +discovery-approvals thread
│   ├── discovery-report.md.tmpl          # NEW
│   └── tos-acknowledgement.json.tmpl     # NEW
│
└── examples/
    ├── arco-rooms.md                     # unchanged
    ├── ecommerce-support.md              # unchanged
    ├── freelance-pipeline.md             # unchanged
    └── discovery-acme-portal.md          # NEW — end-to-end Discovery walkthrough
```

### Structure rationale

- **Flat `references/` directory preserved.** v1.0 uses flat, not `references/security/`. v2.0 keeps this — all discovery-* files are siblings to phase-N-*.md.
- **Subagent in `.claude/agents/`.** Standard Claude Code convention. Not in `references/` because subagents are not documentation, they are executable units with their own lifecycle.
- **New template files as assets.** `discovery-report.md.tmpl` and `tos-acknowledgement.json.tmpl` follow v1.0's "templates never loaded until needed" pattern.
- **Example as a walkthrough.** `discovery-acme-portal.md` demonstrates the full Phase 3 → Discovery → Phase 4 flow, following v1.0's convention that every non-trivial feature has a reference implementation.

---

## Suggested Build Order (Phase Decomposition for v2.0)

Dependency graph (bottom-up):

```
Level 0 (foundation, no new dependencies):
  - legal-posture.md                              # Pure markdown, legal/policy content
  - discovery-report-schema.md                    # Output contract (ships before producer)

Level 1 (extensions to v1.0 security, depend on Level 0 schema for vocabulary):
  - credentials.md extension
  - blast-radius.md extension
  - audit-logging.md extension
  - prompt-injection.md extension
  - tenant-isolation.md extension

Level 2 (discovery toolchain, depends on schema + security extensions):
  - discovery-toolchain.md                        # Playwright MCP + CDP + curl recipes
  - discovery-state-machine.md                    # 7-state lifecycle + checkpoint schema

Level 3 (discovery orchestration, depends on Level 2):
  - discovery-protocol.md                         # Socratic scoping
  - discovery-gate.md                             # Preconditions + approval flow
  - discovery-agent.md (subagent)                 # The executable unit

Level 4 (integration into v1.0 conversational flow):
  - phase-3-integration.md modification           # +Step 2.5
  - SKILL.md modification                         # +pointer, version bump
  - governance.yaml.tmpl + telegram.yaml.tmpl ext

Level 5 (evolution interface for v4.0 forward compatibility):
  - phase-6-evolution.md modification             # +Step 2b
  - REDISCOVER-REQUEST schema in report ref

Level 6 (validation):
  - discovery-acme-portal.md walkthrough
  - TAP test scenario for full Phase 3 → Discovery → Phase 4 loop
  - CI integration
```

### Suggested phase decomposition (8 phases for v2.0 milestone)

**Phase 8: Legal + Schema Foundation**
- Goal: Unblock all downstream work by fixing the output contract and legal posture
- Depends on: nothing
- Ships: `legal-posture.md`, `discovery-report-schema.md`, `tos-acknowledgement.json.tmpl`, `discovery-report.md.tmpl`
- Verification: schemas validate against synthetic examples; legal text reviewed (human_needed)

**Phase 9: Security Extensions**
- Goal: Every existing security reference knows about Discovery before Discovery exists
- Depends on: Phase 8 schemas (for event vocabulary)
- Ships: modified `credentials.md`, `blast-radius.md`, `audit-logging.md`, `prompt-injection.md`, `tenant-isolation.md`
- Verification: existing v1.0 tests still pass; new security sections cross-reference correctly

**Phase 10: Discovery Toolchain**
- Goal: Document the mechanical recipes for capturing traffic, replaying calls, inferring schemas
- Depends on: Phase 9 (subagent needs to reference security patterns)
- Ships: `discovery-toolchain.md`, `discovery-state-machine.md`, checkpoint JSON schema
- Verification: manual smoke test of curl/jq recipes against a known public API

**Phase 11: Discovery Orchestration**
- Goal: Assemble the subagent and its gate
- Depends on: Phase 10
- Ships: `discovery-protocol.md` (Socratic scoping), `discovery-gate.md` (preconditions + approval), `.claude/agents/discovery-agent.md` (subagent)
- Verification: gate refuses to fire without ToS + blast-radius + approval; subagent metadata validates

**Phase 12: v1.0 Integration**
- Goal: Wire Discovery into existing Phase 3; preserve all v1.0 behavior when Discovery preconditions fail
- Depends on: Phase 11 (subagent must exist before Phase 3 can invoke it)
- Ships: modified `phase-3-integration.md` (+Step 2.5, +Step 5b), modified `SKILL.md` (+pointer, v2.0.0), modified templates
- Verification: v1.0 test scenarios still pass (Discovery branch doesn't fire for services with MCPs); new scenario invokes Discovery branch correctly

**Phase 13: Evolution Forward Compatibility**
- Goal: Ship the REDISCOVER-REQUEST interface so v4.0 Self-Healing can plug in later
- Depends on: Phase 12 (Phase 3 must emit Discovery output first)
- Ships: modified `phase-6-evolution.md` (+Step 2b), REDISCOVER-REQUEST proposal template
- Verification: synthetic failure signal triggers proposal emission; proposal goes through approval gate

**Phase 14: Validation Walkthrough + Test Scenario**
- Goal: One end-to-end verification that Discovery actually works
- Depends on: Phase 13
- Ships: `examples/discovery-acme-portal.md`, JSONL test scenario, TAP extension
- Verification: CI runs new scenario; 1 real-world dry discovery against a user-owned test portal (human_needed)

**Phase 15: Repo Polish + v2.0 Release**
- Goal: Ship v2.0 publicly
- Depends on: Phase 14
- Ships: README update (Discovery section), CHANGELOG v2.0, examples README, optional Discovery demo GIF
- Verification: CI green; manual walkthrough from fresh install; tag v2.0.0

**Why this order is load-bearing:**

1. Schema before producer (Phase 8 → 11) — consumers need to know the output contract before the producer exists
2. Security extensions before discovery agent (Phase 9 → 11) — the subagent YAML references the new security patterns
3. Toolchain before orchestration (Phase 10 → 11) — subagent prompts reference the toolchain recipes
4. Subagent before Phase 3 modification (Phase 11 → 12) — Phase 3 invokes the subagent; subagent must exist
5. Phase 3 modification before Evolution modification (Phase 12 → 13) — Evolution only makes sense once Phase 3 produces Discovery artifacts to monitor
6. Walkthrough last (Phase 14) — can only be written once the full path works

### Do NOT build in this order

- Discovery subagent first, then security extensions → subagent will reference security patterns that don't exist, causing rework
- Phase 3 modification before subagent exists → Phase 3 will have dangling pointers, failing to fire correctly
- Evolution interface before Phase 3 integration → premature abstraction without a real producer to validate against

---

## Architectural Patterns

### Pattern 1: Structural Branch Inside Existing Phase (not new phase)

**What:** Insert Discovery as a sub-state of Phase 3 rather than creating a Phase 7.
**When to use:** When the new capability is machinery-for-an-existing-phase, not a new user milestone.
**Trade-offs:** Preserves user-facing narrative; slightly more complex state vocabulary; requires careful documentation of the sub-states.

**Structural rendering:**

```
[AGENTBLOC | PHASE: 3 | GATE: discovery-running | TECH: developer | SERVICE: acme-portal | DISCOVERY: walk (3/7)]
```

The state bar grows to carry per-discovery sub-state when active, reverting to the base 3-field bar when Discovery is not running.

### Pattern 2: File-Based Resume Contract (LangGraph-style, v1.0-compatible)

**What:** Checkpoint every state transition to `state.json`. New sessions can resume without re-reading conversation history.
**When to use:** Any long-running subagent that may outlive a single Claude Code session.
**Trade-offs:** Adds filesystem I/O per state transition (acceptable — file writes are fast); credentials MUST be zeroed before checkpoint write (security requirement); retry ledger grows unbounded without rotation (cap at 100 entries).

### Pattern 3: Subagent Context Fork for High-Noise Data

**What:** Use `context: fork` in subagent frontmatter when the work involves ingesting large untrusted content (HTML, HAR, API responses).
**When to use:** When the main conversation must preserve its context and the subagent's work is well-scoped.
**Trade-offs:** Subagent cannot see interview/design context (must re-derive from structured inputs); main session cannot see subagent's raw work (must read output files). Both are features, not bugs.

### Pattern 4: Forward-Compatible File Contracts for Future Phases

**What:** When designing for a future milestone (v4.0 Self-Healing), define the file interface now and let v2.0 emit it even if nothing consumes it yet.
**When to use:** When downstream milestones are close enough that interface drift would be expensive.
**Trade-offs:** v2.0 writes files no one reads → looks like dead code; but when v4.0 ships, no contract migration is needed. Document the intent clearly ("this file is v4.0's consumer contract").

### Pattern 5: Opt-In Governance Gates for Risky Capabilities

**What:** Features with legal/ethical/security exposure are `enabled: false` by default in governance.yaml.
**When to use:** Discovery (ToS risk), future Builder (code generation risk), future Self-Healing (auto-apply risk).
**Trade-offs:** Adds a user-visible flag to flip; but prevents accidental activation. v1.0 already uses this pattern for human approval requirements — reuse the mental model.

---

## Integration Points Summary

### Integration with v1.0 reference files (named)

| v1.0 File | v2.0 Touchpoint | Type |
|-----------|-----------------|------|
| `SKILL.md` | Add ~20-line Discovery section with pointers; bump version to 2.0.0; extend state-bar vocabulary (blocked / discovery-running / discovery-complete) | MODIFY |
| `references/phase-3-integration.md` | Insert Step 2.5 (Discovery Branch Decision) between Step 2 Priority 5 and Priority 6; insert Step 5b (Discovered Integration Rendering) for matrix row rendering | MODIFY |
| `references/phase-6-evolution.md` | Insert Step 2b (Re-discovery Trigger) between Step 2 (Feature Detection) and Step 3 (Vulnerability Detection); add REDISCOVER-REQUEST proposal type | MODIFY |
| `references/credentials.md` | Extend decision tree with user-supplied-in-session pattern; add rotation policy for discovery-scoped API keys | MODIFY |
| `references/blast-radius.md` | Add Level 2.5 discovery-probe between Level 2 and Level 3; add per-target approval semantics | MODIFY |
| `references/audit-logging.md` | Add 8 new event types (discovery_* and tos_*) to event catalog | MODIFY |
| `references/prompt-injection.md` | Add Layer 5 (Discovery HTML Isolation) to 4-Layer Defense Pipeline → becomes 5-Layer for agents that ingest Discovery content | MODIFY |
| `references/tenant-isolation.md` | Add path-scoping rule for `.agentbloc/discovery/$TENANT_ID/` | MODIFY |
| `references/data-classification.md` | UNCHANGED (Discovery inherits parent agent's classification) | NONE |
| `references/gdpr-patterns.md` | UNCHANGED (existing Article 30 record-keeping via audit log extension covers Discovery) | NONE |
| `references/incident-response.md` | UNCHANGED (P1-P4 severities apply to Discovery failures unmodified) | NONE |
| `references/frameworks.md` | UNCHANGED (framework patterns reference is static) | NONE |
| `references/telegram-patterns.md` | UNCHANGED at ref level (the new thread is configured in telegram.yaml.tmpl, not here) | NONE |
| `references/scheduling.md` | UNCHANGED (Discovery is not scheduled; it's on-demand from Phase 3) | NONE |
| `references/glossary-{en,es}.md` | Add ~10 discovery terms (Discovery Agent, HAR, Playwright MCP, ToS opt-in, etc.) | MODIFY |

### Integration with v1.0 deployment artifacts

| v1.0 Artifact | v2.0 Touchpoint | Type |
|---------------|-----------------|------|
| `templates/governance.yaml.tmpl` | Add `discovery:` block (enabled, budgets, forbidden_targets, approval_thread) | MODIFY |
| `templates/telegram.yaml.tmpl` | Add `discovery-approvals` thread | MODIFY |
| `.agentbloc/state/` directory | UNCHANGED (Discovery has its own `.agentbloc/discovery/` sibling) | NONE |
| `.agentbloc/logs/audit.jsonl` | Extended with new event types (no schema migration — JSONL is append-only) | EXTEND |
| `.env` / `.env.example` | Extended with discovery-scoped credential variables when scoped-api-key mode used | EXTEND |

### New artifact directories

| Location | Purpose | Persistence |
|----------|---------|-------------|
| `.agentbloc/discovery/<service-slug>/state.json` | Checkpoint + resume | Resumable across sessions |
| `.agentbloc/discovery/<service-slug>/DISCOVERY-REPORT.md` | Final output for Phase 3 / v3.0 Builder | Permanent |
| `.agentbloc/discovery/<service-slug>/har/` | Evidence (gitignored by default) | Permanent, user-managed |
| `.agentbloc/discovery/<service-slug>/responses/` | Fixtures for v3.0 Builder | Permanent |
| `.agentbloc/discovery/<service-slug>/screenshots/` | Evidence | Permanent, user-managed |
| `.agentbloc/discovery/<service-slug>/retry-ledger.jsonl` | Ralph-retry history | Permanent, bounded (last 100) |
| `.agentbloc/discovery/<service-slug>/tos-acknowledgement.json` | Immutable legal record | Permanent, immutable |

---

## Anti-Patterns to Avoid

### Anti-Pattern 1: Making Discovery a New Top-Level Phase

**What people do:** Add Phase 7 to SKILL.md, introduce it in README as "the 7-phase flow."
**Why wrong:** Violates v1.0 brand promise (6-phase). Requires rewriting every example walkthrough. Breaks gate-vocabulary invariants. Discovery is machinery; users don't think of "reverse-engineer a portal" as one of the big milestones of onboarding their agents.
**Do this instead:** Structural branch inside Phase 3 with sub-state vocabulary. Preserves the 6-phase narrative while adding machinery underneath.

### Anti-Pattern 2: Putting Discovery State in `.planning/`

**What people do:** Write Discovery checkpoints to `.planning/discovery/` because "it's exploration/research."
**Why wrong:** `.planning/` is AgentBloc-the-product's development scratch space. Discovery runs on the **user's** behalf, producing **the user's** artifacts. Checkpoints contain user PII (credentials, portal contents). Conflating the two breaks governance and tenant isolation.
**Do this instead:** All Discovery state lives in `.agentbloc/discovery/<service-slug>/` — the deployment artifact directory the user owns.

### Anti-Pattern 3: Discovery Agent Inlined in Main Conversation

**What people do:** Add a "discovery mode" flag to the main AgentBloc skill, have the same conversation both interview the user AND reverse engineer the portal.
**Why wrong:** Context contamination. HAR file parses evict Phase 1 interview content. HTML content is a prompt-injection vector directly into the main conversation. No per-tool scoping possible.
**Do this instead:** Subagent with `context: fork` and strict `allowed-tools` whitelist. Main conversation reads only the finished report file.

### Anti-Pattern 4: Automatic Re-Discovery on Failure (in v2.0)

**What people do:** Detect an MCP failure, auto-run Discovery, auto-regenerate MCP.
**Why wrong:** This is v4.0 territory. Shipping it in v2.0 bypasses the human approval gate that is NON-NEGOTIABLE in v1.0 Phase 6. Also concentrates blast radius at a time when Discovery itself is unproven.
**Do this instead:** v2.0 ships the REDISCOVER-REQUEST proposal type. Evolution emits proposals, user approves, human or future-v4.0 automation actually runs the rediscovery. File-based contract, loose coupling.

### Anti-Pattern 5: Persisting User-Supplied Discovery Credentials

**What people do:** Store the credentials the user typed into a Discovery prompt in `.env` for "convenience on resume."
**Why wrong:** Discovery credentials are usually the user's personal login (not a service account). Persisting them elevates blast radius, violates least privilege, and creates a high-value attack target. On resume, re-prompting is only mildly inconvenient.
**Do this instead:** In-memory only. Zero from `state.json` before checkpoint. Re-prompt on resume. (Service-account API keys are a different path and can be persisted under existing credentials.md rules.)

---

## Scaling Considerations

| Scale | Architecture Adjustments |
|-------|--------------------------|
| 1 service per deployment | Default. File-based state, single subagent invocation per Phase 3 run. No special handling. |
| 3-10 services per deployment (typical SMB) | Default still works. Subagent invoked serially per service. Parallelism not needed — Phase 3 is conversational and one service at a time matches the user's cognitive load. |
| 10+ services (enterprise multi-portal) | Add `max_concurrent_discoveries` in governance.yaml (default 1, can raise to 3). Discovery artifacts stay per-service; no contention. |
| Repeated rediscoveries (v4.0 steady state) | `retry-ledger.jsonl` bounded at 100 entries; `.agentbloc/discovery/<service>/history/` archives prior reports with timestamp suffix. |

### Scaling priorities

1. **First bottleneck:** Model budget during a single discovery (Opus tokens for schema inference). Cap via `max_model_usd` per target; emit partial report at budget exhaustion.
2. **Second bottleneck:** HAR file disk growth over time. Gitignore HAR files by default; document rotation (keep last 3 HAR per service).
3. **Third bottleneck (v4.0):** Parallel rediscovery if many MCPs degrade simultaneously. Address with queue + concurrent-discoveries limit, not an immediate concern for v2.0.

---

## Confidence Assessment

| Area | Confidence | Reason |
|------|------------|--------|
| Phase 3 handoff point (Step 2.5 between Priority 5 and Priority 6) | HIGH | Directly read v1.0 `phase-3-integration.md`; insertion point is unambiguous |
| Subagent design vs. new phase vs. sibling skill | HIGH | Three alternatives evaluated; subagent win is decisive on context, tool scoping, compaction independence |
| `.agentbloc/discovery/` state location | HIGH | Matches v1.0 architectural principle (user artifacts in `.agentbloc/`, product scratch in `.planning/`) |
| Checkpoint schema and resume contract | MEDIUM | Follows LangGraph patterns; v1.0 has no live precedent to validate against; may need iteration after first real Discovery runs |
| Evolution REDISCOVER-REQUEST interface | MEDIUM | Forward-designed for v4.0; correct in principle but no consumer yet; schema may drift when v4.0 Builder lands |
| Security extensions (5 files) | HIGH | Each extension has a clear insertion point; v1.0 security refs are well-structured; diff surface is small |
| Build order (8 phases, Phase 8-15) | HIGH | Dependency graph is explicit; no circular dependencies; matches v1.0 build-order discipline |
| Governance.yaml extension shape | MEDIUM | Reasonable schema but not tested against user feedback; may want an `opt_in_flow` sub-block based on real-world ToS variance |
| Playwright MCP tool scoping in subagent YAML | MEDIUM | Claude Code subagent YAML supports `allowed-tools` with glob patterns; specific syntax for path-restricted `Write(path:...)` may need tool-specific verification |

---

## Open Questions (for downstream consumers)

1. **Does v2.0 ship the v4.0 REDISCOVER-REQUEST interface now, or defer?** My recommendation: ship the schema and the Step 2b emission logic now (it's cheap and prevents v4.0 contract migration). The consumer (auto-rediscovery loop) is deferred.

2. **Should Discovery be available to deployed agents at runtime, or only during Phase 3?** Strong recommendation: only Phase 3. Letting a deployed cron-triggered agent invoke Discovery is equivalent to letting it reverse-engineer portals unattended — no human oversight, no ToS check at the right moment. v4.0 reconsiders this for auto-rediscovery.

3. **How does Discovery interact with Phase 4 (Confirmation + Dry Run)?** Discovered integrations become normal Phase 4 confirmation items, marked with `[DISCOVERED]` trust tier. User approves or rejects per the existing Phase 4 protocol. The dry run stubs side effects as usual; for Discovery-derived integrations the stubs are generated from the `sample_calls` in the report.

4. **What happens when Discovery succeeds but the derived integration has no MCP yet (v2.0 without v3.0 Builder)?** In v2.0, Phase 4 flags it as "documentation-only" — the user gets a report they can manually translate into an integration (or wait for v3.0 Builder). Phase 5 doesn't generate deployment artifacts for Discovery-only integrations until v3.0 lands.

5. **How does the main conversation know when the subagent is done?** File-based polling: on each Phase 3 turn after Discovery invocation, the main conversation checks for `DISCOVERY-REPORT.md` existence. This avoids any stateful communication channel between subagents.

6. **Do we need a separate `REQUIREMENTS.md` category for Discovery?** (Note for downstream roadmapper.) Yes — at minimum: DISC-01 through DISC-NN for discovery mechanics, TOS-01 through TOS-NN for legal posture, RDSV-01 through RDSV-NN for rediscovery interface. Existing categories (SECR, INTG, EVOL) get extensions rather than new numbering.

---

## Sources

### Primary (HIGH confidence — directly read)
- `/Users/pablodelarco/agentbloc/.planning/PROJECT.md` (v2.0 scope direction)
- `/Users/pablodelarco/agentbloc/.planning/v2.0-HANDOFF.md` (framework research, locked decisions)
- `/Users/pablodelarco/agentbloc/.planning/milestones/v1.0-research/ARCHITECTURE.md` (v1.0 architectural baseline)
- `/Users/pablodelarco/agentbloc/.planning/milestones/v1.0-ROADMAP.md` (shipped phase structure)
- `/Users/pablodelarco/agentbloc/.claude/skills/agentbloc/SKILL.md` (live hub — 2.0.0 target)
- `/Users/pablodelarco/agentbloc/.claude/skills/agentbloc/references/phase-3-integration.md` (Discovery insertion point)
- `/Users/pablodelarco/agentbloc/.claude/skills/agentbloc/references/phase-6-evolution.md` (Re-discovery trigger insertion point)
- `/Users/pablodelarco/agentbloc/.claude/skills/agentbloc/references/blast-radius.md` (Level 2.5 extension point)
- `/Users/pablodelarco/agentbloc/.claude/skills/agentbloc/references/credentials.md` (user-supplied extension point)
- `/Users/pablodelarco/agentbloc/.claude/skills/agentbloc/references/prompt-injection.md` (Layer 5 extension point)

### Secondary (MEDIUM confidence — referenced without deep read, well-known from v1.0 research)
- Claude Code Subagents official docs (for `context: fork`, `allowed-tools`, model routing)
- Playwright MCP (microsoft/playwright-mcp) README for tool names
- LangGraph checkpointing pattern (adapted file-based)
- oh-my-claudecode Ralph mode (retry ledger pattern)
- Superpowers socratic spec extraction (Phase 2.5 scoping)

### Tertiary (context only, no direct citation needed)
- Chrome DevTools Protocol (CDP) HAR format
- OWASP LLM06:2025 (Excessive Agency — informs blast-radius Level 2.5)
- GDPR Article 30 (record-keeping — informs audit log extension)

---

*Architecture research for: AgentBloc v2.0 Discovery Agent integration*
*Researched: 2026-04-18*
