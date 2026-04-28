# AgentBloc

> A Claude Code skill that interviews you about a manual business workflow, deeply researches the right tools (existing MCPs, custom MCP wrappers, n8n flows, webhooks), and emits a portable build-ready spec folder that any AI coding agent — Claude Code, Codex, Gemini, Cursor, OpenClaw — can execute. **AgentBloc is the architect, not the builder.**

[![version: 3.0.0](https://img.shields.io/badge/version-3.0.0-blue)](https://github.com/pablodelarco/agentbloc/releases) [![license: MIT](https://img.shields.io/badge/license-MIT-green)](LICENSE) [![Claude Code: v2.1+](https://img.shields.io/badge/Claude%20Code-v2.1%2B-blueviolet)](https://claude.ai/code) [![CI](https://github.com/pablodelarco/agentbloc/actions/workflows/ci.yml/badge.svg)](https://github.com/pablodelarco/agentbloc/actions/workflows/ci.yml)

## What you get

You describe a business workflow you do by hand. AgentBloc returns a **project spec folder** — a complete, build-ready package that contains:

- **Workflow definitions** with falsifiable success criteria
- **Agent designs** (CrewAI-shaped roles, blast-radius, autonomy)
- **Deeply-researched tool inventory** ranked across 5 readiness tiers:
  - `EXISTS-MCP` — public MCP server exists; install instructions known
  - `NEEDS-MCP-WRAPPER` — API exists, no public MCP; wrapper specs ready for `mcp-builder`
  - `NEEDS-N8N-FLOW` — visual / branching logic; flow stub generated
  - `NEEDS-WEBHOOK` — event-driven; receiver design spec
  - `MANUAL` — no automation appropriate; runbook documented
- **Governance contracts** (PII, GDPR, audit, kill-switch, approval)
- **Build-ready ROADMAP.md** with effort estimates
- **CLAUDE.md / AGENTS.md** so any AI coding session can start without re-asking AgentBloc-level questions
- **Reference implementation** (bash + cron + Telegram substrate, advisory only)

You hand the folder to a fresh Claude Code session — or Codex, Gemini, Cursor, OpenClaw — and the build session executes the spec.

## Why this shape

The hard part of automation isn't cron firing — it's figuring out **which tools can actually do the work**, designing wrappers around APIs that don't have MCPs yet, and writing the spec deeply enough that an implementation session has zero ambiguity. Most failed automations fail at scoping, not runtime.

v3.0 separates concerns cleanly: AgentBloc is the architect (conversation engine + spec emission), and your AI coding session of choice is the builder (executes the spec). This split means:

- **Tool-portable output.** The spec folder is markdown + YAML + JSON. Any AI coding agent can consume it.
- **No runtime lock-in.** The reference impl is bash + cron, but the spec emits enough context for the build session to pick n8n, Temporal, Pipedream, Inngest, or custom Python instead.
- **Cleaner mental model.** AgentBloc focuses on what Claude Code does best (conversation, subagents, hooks). Implementation tooling stays open.

## What's new in v3.0

| Change | v2.0/v2.5 | v3.0 |
|---|---|---|
| **Output** | Running scripts (cron, hooks, settings.json patches) | Portable spec folder (markdown + YAML + JSON) |
| **Phase 3** | Deep Integration Analysis (binary: exists / doesn't) | **Deep Tool Discovery** with 5-tier readiness ranking |
| **Phase 4** | Step-by-step confirmation + dry run | **Spec Review** walkthrough + sign-off |
| **Phase 5** | Deployment with `deploy-engine` + `runtime-engine` | **Spec Emission** with `spec-engine` (single sub-gate) |
| **Phase 6** | Live audit-log monitoring + scan-detect-propose-approve | **Spec Evolution** — rerun on requirements change |
| **Subagents** | 4 (browser-discovery, designer-agent, deploy-engine, runtime-engine) | 3 (browser-discovery, designer-agent, **spec-engine**) |
| **ClaudeClaw** | Required (private + nonexistent on user machines) | **Removed** — replaced with file-based inbox handoff in reference impl |

The conversation flow + phase gates + agent profile schema + business graph schema are unchanged. The runtime-contract change is documented as breaking in CHANGELOG.

## Quick start

Requires [Claude Code](https://claude.ai/code) v2.1 or later.

```bash
git clone https://github.com/pablodelarco/agentbloc.git
mkdir -p ~/.claude/skills/agentbloc ~/.claude/agents
cp -r agentbloc/.claude/skills/agentbloc/* ~/.claude/skills/agentbloc/
cp agentbloc/.claude/agents/*.md ~/.claude/agents/
```

Open Claude Code and trigger AgentBloc:

> "I run a property management company and spend 3 hours a day matching invoices to bank payments across 6 providers."

— or —

```
/agentbloc
```

AgentBloc detects your language (English or Spanish) and technical level automatically, then begins the structured interview. No configuration needed.

## How it works — the 6 phases

```
INTERVIEW  →  DESIGN  →  DEEP TOOL DISCOVERY  →  SPEC REVIEW  →  SPEC EMISSION  →  SPEC EVOLUTION
  (deep)     (general)      (per-step)             (walkthrough)    (folder out)    (rerun on change)
```

Every phase has a gate — the user must explicitly approve before the skill advances:

1. **Deep Interview** — 9-category structured questioning until zero ambiguity. Emits the Business Graph (`business-graph.json`) silently.
2. **General Design** — `designer-agent` subagent (fork context) emits `agent-profiles.yaml` with CrewAI-shaped profiles + topology selection. Anticipation pass surfaces unrequested-but-needed agents.
3. **Deep Tool Discovery** — Per agent action, find the BEST integration path. 4-step protocol: MCP search → API investigation → n8n suitability → manual triage. Every tool gets a readiness tier with evidence URL. `browser-discovery` subagent fills in services without docs.
4. **Spec Review** — Walkthrough of the proposed spec folder shape across 6 dimensions (workflows, agents, tools, governance, effort, hand-off completeness). User signs off before any files are written.
5. **Spec Emission** — `spec-engine` subagent writes the canonical spec folder via 6-step protocol. Single sub-gate `spec_folder_emitted`. Emits `SPEC-EMISSION-REPORT.md` (success) or `SPEC-EMISSION-FAILED-REPORT.md` (halt).
6. **Spec Evolution** — When requirements change, rerun AgentBloc on the existing spec folder. Reads existing `.agentbloc/spec/` as ground truth, re-interviews where needed, emits an updated spec via diff mode.

## The output: spec folder shape

```
<your-project>/
├── README.md                # Human-English overview of the team
├── AGENTS.md                # Universal AI-tool context (Codex/Cursor/etc)
├── CLAUDE.md                # Claude-Code-specific project context
├── ROADMAP.md               # Phased build plan + effort estimates
├── SPEC-EMISSION-REPORT.md  # Provenance + tier breakdown + hand-off
│
├── workflows/               # WHAT — falsifiable workflow specs
├── agents/                  # WHO — CrewAI-shaped roles + prompts + blast-radius
├── integrations/            # HOW — INVENTORY.md + per-tier subfolders
│   ├── INVENTORY.md         # Master tier-ranked matrix
│   ├── existing/            # Tier 1: install + config
│   ├── needs-mcp-wrapper/   # Tier 2: openapi.yaml + BUILD.md + ENDPOINTS.md
│   ├── needs-n8n-flow/      # Tier 3: stub flow JSON
│   ├── needs-webhook/       # Tier 4: receiver spec
│   └── manual/              # Tier 5: no-automation rationale
├── governance/              # blast-radius, audit, PII, kill-switch, approval
└── runtime/
    ├── BUILD.md             # Tool-agnostic build plan
    ├── reference-impl/      # Bash + cron + Telegram (advisory)
    └── alternatives.md      # n8n / Temporal / Pipedream / Inngest / custom
```

The build session opens this folder, reads `CLAUDE.md` (or `AGENTS.md`), and follows `ROADMAP.md`.

## Hand-off to any AI coding tool

| Tool | How user invokes after AgentBloc emits |
|---|---|
| **Claude Code** | `cd <spec-folder> && claude` (CLAUDE.md + skills/subagents available) |
| **Codex CLI** | `cd <spec-folder> && codex` (reads AGENTS.md) |
| **Cursor** | Open spec folder; AGENTS.md becomes project context |
| **Gemini Code Assist** | Same — universal markdown context |
| **OpenClaw** | Same |

## Documentation

- [`docs/v3.0-architecture.md`](docs/v3.0-architecture.md) — design lock for the spec engine
- [`docs/v3.0-simplification-plan.md`](docs/v3.0-simplification-plan.md) — repo audit and simplification buckets
- [`.claude/skills/agentbloc/SKILL.md`](.claude/skills/agentbloc/SKILL.md) — the conversation engine
- [`.claude/skills/agentbloc/references/`](.claude/skills/agentbloc/references/) — 40+ reference docs (one per phase + one per integration tier)
- [`.claude/skills/agentbloc/examples/`](.claude/skills/agentbloc/examples/) — worked examples (Arco Rooms, e-commerce, freelance pipeline)
- [`CHANGELOG.md`](CHANGELOG.md) — version history with breaking-change disclosure

## Migration from v2.0

v2.0 emitted running scripts via `deploy-engine` + `runtime-engine`. v3.0 emits a portable spec folder via `spec-engine`. The runtime-engine subagent is removed. The deploy-engine is renamed to spec-engine and rewritten.

If you have existing v2.0 deployments, they continue to work — but new emissions use the v3.0 spec folder model. See [CHANGELOG.md](CHANGELOG.md) `[3.0.0]` for the full breaking-change disclosure.

## Status

v3.0 is the active milestone. v2.0 (released 2026-04-26) ran as a Claude Code skill that emitted running scripts; the v2.5 runtime substrate (helpers.sh, wake.sh, telegram-send.sh, etc.) is preserved as `templates/spec-folder/runtime/reference-impl/` and ships inside every emitted spec folder as advisory reference. The v2.5-runtime branch is preserved locally for forensic reference.

## License

MIT — see [LICENSE](LICENSE).
