# AgentBloc — Architecture

AgentBloc is a Claude Code skill that interviews a user about a manual business workflow, deeply researches which tools (existing MCPs, raw APIs, n8n flows, custom integrations) can do each step, and emits a portable **project spec folder** that any AI coding agent — Claude Code, Codex, Gemini, Cursor, OpenClaw — can build from without ambiguity.

AgentBloc is the architect. The build session — wherever the user runs it — is the builder. This split lets AgentBloc focus on the conversational design problem (which is genuinely hard) and lets implementation tooling stay open.

## Six phases

```
INTERVIEW  →  DESIGN  →  DEEP TOOL DISCOVERY  →  SPEC REVIEW  →  SPEC EMISSION  →  SPEC EVOLUTION
  (deep)    (general)      (per-step)             (walkthrough)    (folder out)    (rerun on change)
```

Every phase has an explicit gate; nothing advances without user approval. State is kept in `.agentbloc/` (graph, agent profiles, inventory).

### Phase 1 — Deep Interview
9-category structured questioning with bilingual support (English / Spanish). Outputs a schema-validated `business-graph.json` capturing services, data flows, edge cases, decision patterns, and data-classification tags (PII / financial / public). Validation Checklist gates Phase 2 entry.

### Phase 2 — General Design
Project-local `designer-agent` subagent (fork context, scoped tools, no Bash) consumes the Business Graph and emits `agent-profiles.yaml` with CrewAI-shaped profiles (role + goal + backstory + tools + autonomy + blast-radius + escalation). Includes 5-pattern orchestration classification (`sequential | parallel | loop | event-driven | conversational`) and an anticipation pass that surfaces unrequested-but-needed agents from `references/anticipation-heuristics.md`.

Sub-gate: `agent_profiles_validated`.

### Phase 3 — Deep Tool Discovery
Phase 3 produces `inventory.yaml` plus per-tool subfolders, ranking each tool by **readiness tier**:

| Tier | Meaning | Output |
|---|---|---|
| `EXISTS-MCP` | Public MCP server exists, install instructions known | `integrations/existing/<tool>.md` |
| `NEEDS-MCP-WRAPPER` | Vendor API exists, no public MCP, wrapper buildable via `mcp-builder` skill | `integrations/needs-mcp-wrapper/<tool>/` with OpenAPI spec + BUILD.md + ENDPOINTS.md |
| `NEEDS-N8N-FLOW` | Visual / branching / multi-service logic best done in n8n | `integrations/needs-n8n-flow/<tool>-flow.json` stub |
| `NEEDS-WEBHOOK` | Event-driven; receiver must be built | `integrations/needs-webhook/<tool>-receiver.md` spec |
| `MANUAL` | No automation path appropriate / advisable | `integrations/manual/<tool>.md` documenting why |

Tier assignment is the high-leverage decision. The protocol uses 4 steps:

1. **MCP Search** — existing 4-step protocol from `mcp-integration-protocol.md` (existing `.mcp.json` → ecosystem registry → wrapper synthesis → verification)
2. **API Investigation** — if no MCP, find OpenAPI spec; assess wrap-ability
3. **n8n Suitability** — branching logic, multi-service, polling? n8n wins
4. **Manual Triage** — exotic / one-off / human-required

The `browser-discovery` subagent (Playwright + Patchright stack with CDP-leak patches only; deny-list lint forbids fingerprint-spoofing libraries) fills in services without docs. Per-service legal opt-in via `DISCOVERY-LICENSE-NOTICE.md`. Three-tier API classification (DOCUMENTED / INTERNAL / INTERNAL-HARDENED) with PII redaction + injection-detector output firewall.

The `mcp-builder` skill is invoked for `NEEDS-MCP-WRAPPER` tools to scaffold wrapper code into `integrations/needs-mcp-wrapper/<tool>/`.

Sub-gates: `mcp_integrations_verified` + `tool_inventory_complete` (every workflow step has a tier assignment with evidence; no unverified claims).

### Phase 4 — Spec Review
Walk the user through the proposed spec folder shape (without writing it yet). Confirm:

- All workflows have falsifiable success criteria
- All agents have unambiguous role / goal / blast-radius
- All tools have a tier + readiness assessment
- All security envelopes (PII, GDPR, audit, kill-switch) are addressed
- Build effort estimate is realistic (CC-hours / human days)

Spec Review is a walkthrough + sign-off ritual, not an execution dry run.

Sub-gate: `spec_review_signed_off`.

### Phase 5 — Spec Emission
The `spec-engine` subagent reads three input artifacts (`business-graph.json`, `agent-profiles.yaml`, `inventory.yaml`), validates them, and writes the canonical spec folder via a 6-step protocol. Single sub-gate: `spec_folder_emitted`. Two terminal artifacts:

- **Success** — `SPEC-EMISSION-REPORT.md` with input SHA256s, file count, tier breakdown, effort estimate, hand-off checklist
- **Failure** — `SPEC-EMISSION-FAILED-REPORT.md` with the failed step number, the input that failed validation, and a plain-English root cause

Bash is narrowed to `shasum:*` only — no `crontab`, no `claude` CLI invocations. Nothing executes in the user's environment beyond writing files.

The emission produces this structure:

```
<your-project>/
├── README.md                    # Human-English overview of the team
├── AGENTS.md                    # Universal AI-tool entry (Codex/Cursor/etc)
├── CLAUDE.md                    # Claude-Code-specific entry
├── ROADMAP.md                   # Phased build plan + effort estimates
├── SPEC-EMISSION-REPORT.md      # Provenance + tier breakdown + hand-off
│
├── workflows/                   # WHAT — falsifiable workflow specs
│   ├── 01-<workflow-id>.md
│   └── ...
│
├── agents/                      # WHO — CrewAI-shaped agent definitions
│   ├── <agent-id>/
│   │   ├── role.md              # role + goal + backstory
│   │   ├── prompts.md           # system prompt + wake prompt
│   │   ├── tools.md             # tools this agent uses (links integrations/)
│   │   ├── blast-radius.md      # security envelope + autonomy
│   │   └── escalation.md        # failure handling + tier
│   └── ...
│
├── integrations/                # HOW — deeply-researched tool inventory
│   ├── INVENTORY.md             # Master matrix; tier per tool with evidence
│   ├── existing/                # Tier 1: install + config docs
│   ├── needs-mcp-wrapper/       # Tier 2: openapi.yaml + BUILD.md + ENDPOINTS.md
│   ├── needs-n8n-flow/          # Tier 3: stub flow JSON + activation steps
│   ├── needs-webhook/           # Tier 4: receiver spec
│   └── manual/                  # Tier 5: no-automation rationale
│
├── governance/                  # GUARDRAILS
│   ├── blast-radius.md          # Per-agent risk envelope
│   ├── audit-trail.md           # JSONL log schema + retention
│   ├── pii-redaction.md         # GDPR posture
│   ├── kill-switch.md           # 3-trigger halt mechanism
│   └── approval-protocol.md     # When + how to request human approval
│
└── runtime/                     # IMPLEMENTATION (advisory)
    ├── BUILD.md                 # Tool-agnostic build plan
    ├── reference-impl/          # Bash + cron + Telegram substrate
    │   ├── helpers.sh           #   correlation-id generator + atomic writes
    │   ├── wake.sh              #   per-agent wake entrypoint
    │   ├── claude-wrap.sh       #   headless `claude -p` wrapper
    │   ├── cron-generator.sh    #   crontab apply / remove
    │   ├── telegram-{send,poll}.sh
    │   ├── approval-router.sh   #   inbox-driven approval bridge
    │   ├── escalation-router.sh
    │   ├── activity-feed-merge.sh
    │   ├── hooks/autonomy-gate.sh
    │   └── .env.example
    └── alternatives.md          # n8n / Temporal / Pipedream / Inngest / custom Python
```

The highest-leverage artifact is `integrations/INVENTORY.md` — the deeply-researched answer to "which tools do I actually need and which exist."

### Phase 6 — Spec Evolution
When requirements change, rerun AgentBloc on the existing spec folder. Reads `.agentbloc/spec/` as ground truth, identifies what changed (new service, deprecated endpoint, compliance shift, build-session learning), re-runs only the affected phases, and re-emits affected files in place. `SPEC-EMISSION-REPORT.md` gets a new Revision History section with input-SHA256 deltas.

## Subagent inventory

| Subagent | Phase | Role |
|---|---|---|
| `designer-agent` | 2 | Reads `business-graph.json`; emits `agent-profiles.yaml` |
| `browser-discovery` | 3 | Fills in services without docs (Playwright + Patchright) |
| `spec-engine` | 5 | Validates inputs; writes the canonical spec folder |

The `mcp-builder` skill (already in Claude Code) is invoked from Phase 3 for `NEEDS-MCP-WRAPPER` tools.

## Phase gates

| Phase | Sub-gates |
|---|---|
| 1 | `business_graph_validated` |
| 2 | `agent_profiles_validated` |
| 3 | `mcp_integrations_verified` + `tool_inventory_complete` |
| 4 | `spec_review_signed_off` |
| 5 | `spec_folder_emitted` |
| 6 | (entry presupposes spec folder exists) |

## Universal hand-off

The same spec folder works in any AI coding tool:

| Tool | Entry path |
|---|---|
| Claude Code | `cd <spec-folder> && claude` reads `CLAUDE.md` (skills/subagents/hooks vocabulary) then walks `ROADMAP.md` |
| Codex CLI | `cd <spec-folder> && codex` reads `AGENTS.md` (universal vocabulary) |
| Cursor | Open spec folder; `AGENTS.md` becomes project context |
| Gemini Code Assist | Same — universal markdown context |
| OpenClaw | Same |

The `BUILD.md` files per integration tier (`integrations/needs-mcp-wrapper/<tool>/BUILD.md`, `runtime/BUILD.md`) are tool-agnostic. The `runtime/reference-impl/` is bash + cron, but that's a substrate, not a tool requirement — `runtime/alternatives.md` documents 8 options (n8n self-hosted / n8n cloud / Pipedream / Temporal / Inngest / custom Python / Claude Code Scheduled Tasks).

## Governance contracts that follow the spec

- Per-agent blast-radius taxonomy (L1 read-only / L2 write-scoped / L3 write-unrestricted / L4 send-external)
- 3-trigger kill switch (file flag + env var + `/halt-all` Telegram command)
- Append-only JSONL audit log with PII redaction (12 fields: `correlation_id`, `agent_id`, `wake_id`, `action`, `tool`, `args_summary`, `result`, `duration_ms`, `details`, `trace_parent`, `log_version`, `timestamp`)
- Telegram approval thread separation (approvals / briefings / escalations)
- Spain DNI/NIE patterns when GDPR scope is detected; HIPAA/PCI patterns activate based on data classification

## What AgentBloc does NOT do

- **Run anything in the user's environment.** No cron lines installed, no `.mcp.json` mutated outside the spec folder, no live Telegram round-trips.
- **Bundle a runtime.** The reference impl ships as content the build session may use, adapt, or replace.
- **Auto-deploy a monitor.** Audit-log forensics and daily briefings belong to the build session per `governance/audit-trail.md` and `runtime/reference-impl/activity-feed-merge.sh`.
- **Lock the user to one AI coding tool.** Spec folder is markdown + YAML + JSON. Universally readable.
