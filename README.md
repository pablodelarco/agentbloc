# AgentBloc 🧱

> **Describe your business. AgentBloc designs the AI team.**
>
> _The architect for your AI workforce._

[![version: 1.0.0](https://img.shields.io/badge/version-1.0.0-blue)](https://github.com/pablodelarco/agentbloc/releases) [![license: MIT](https://img.shields.io/badge/license-MIT-green)](LICENSE) [![Claude Code: v2.1+](https://img.shields.io/badge/Claude%20Code-v2.1%2B-blueviolet)](https://claude.ai/code) [![CI](https://github.com/pablodelarco/agentbloc/actions/workflows/ci.yml/badge.svg)](https://github.com/pablodelarco/agentbloc/actions/workflows/ci.yml)

## What it does

Most people who try to automate their business with AI stall at the same place: they don't know which agents to build, how those agents should hand off to each other, or which integrations are actually possible. AgentBloc is the conversation that figures that out.

You describe your workflow. AgentBloc interviews you, designs the agent team you need, researches every integration (MCPs that already exist, APIs that need wrapping, services that need a webhook receiver, things that have to stay manual), and emits a build-ready spec.

Once you have the spec, hand it to whatever orchestrator fits. [Paperclip](https://github.com/paperclipai/paperclip) is a natural fit because it's purpose-built for running AI agent teams (heartbeats, approvals, costs, org chart out of the box). The same spec works with any AI coding agent (Claude Code, Codex, Cursor, Gemini, OpenClaw) that can build it for your runtime of choice.

## In three steps

1. **Tell it your workflow.** Bilingual interview (English / Spanish), no technical jargon required.
2. **Watch it design your team.** Every agent gets a role, goal, tools, autonomy level, and blast-radius envelope. Every integration gets a readiness rank: install today, build first, or keep manual.
3. **Run it anywhere.** Drop the spec into Paperclip for a turn-key path, or hand it to any AI coding agent to build for a different runtime.

## The split (architect / runtime)

- **AgentBloc** is the architect. It thinks, interviews, researches, designs. Never runs anything.
- **Your runtime** is the builder. Paperclip is the canonical example because it's purpose-built for running AI agent teams. Other runtimes work too; they just need a build session to wire the spec.
- **You** are the client. Describe the business. Sign off at every gate. Stay in control.

## What you get

A **portable project spec folder** — the deeply-researched answer to "what does this automation actually need, and how do I build it?" — emitted as markdown + YAML + JSON.

```
<your-project>/
├── README.md                    # Human-English overview of the team
├── AGENTS.md                    # Universal AI-tool entry (Codex/Cursor/etc)
├── CLAUDE.md                    # Claude-Code-specific entry
├── ROADMAP.md                   # Phased build plan + effort estimates
├── SPEC-EMISSION-REPORT.md      # Provenance + tier breakdown + hand-off
│
├── workflows/                   # WHAT — falsifiable workflow specs
├── agents/                      # WHO — CrewAI-shaped roles + prompts + blast-radius
├── integrations/                # HOW — INVENTORY.md + per-tier subfolders
│   ├── INVENTORY.md             #   Master tier-ranked matrix with evidence URLs
│   ├── existing/                #   Tier 1: install + config
│   ├── needs-mcp-wrapper/       #   Tier 2: openapi.yaml + BUILD.md + ENDPOINTS.md
│   ├── needs-n8n-flow/          #   Tier 3: stub flow JSON
│   ├── needs-webhook/           #   Tier 4: receiver spec
│   └── manual/                  #   Tier 5: no-automation rationale
├── governance/                  # blast-radius, audit, PII, kill-switch, approval
└── runtime/
    ├── BUILD.md                 # Tool-agnostic build plan
    ├── reference-impl/          # Bash + cron + Telegram (advisory)
    └── alternatives.md          # n8n / Temporal / Pipedream / Inngest / custom
```

The build session reads `CLAUDE.md` (or `AGENTS.md`), follows `ROADMAP.md`, and ships.

## Why this shape

The hard part of automation isn't cron firing — it's figuring out **which tools can actually do the work**, designing wrappers around APIs that don't have MCPs yet, and writing the spec deeply enough that an implementation session has zero ambiguity. Most failed automations fail at scoping, not runtime.

AgentBloc separates concerns: the conversation engine + spec emission live here, the implementation lives in your AI coding session of choice. So:

- **Tool-portable output.** Markdown + YAML + JSON. Any AI coding agent can consume it.
- **No runtime lock-in.** The reference impl is bash + cron + Telegram, but the spec emits enough context for the build session to pick n8n, Temporal, Pipedream, Inngest, or custom Python instead.
- **Cleaner mental model.** AgentBloc focuses on what Claude Code does best (conversation, subagents, hooks). Implementation tooling stays open.

## Use cases

- **Property management** — collect utility invoices from N portals, match against bank transactions, message owners on Telegram. See [`examples/arco-rooms-spec/`](.claude/skills/agentbloc/examples/arco-rooms-spec/) for the full worked example.
- **E-commerce support triage** — fan-in tickets from Zendesk + Shopify + email, classify, draft replies, escalate based on order context.
- **Freelance pipeline** — watch lead sources, qualify with the proposal pattern, draft contracts, follow up on overdue invoices.

The pattern: any workflow that's repetitive, multi-service, and human-judgment-light is a candidate. AgentBloc tells you which parts are MCP-ready, which need a wrapper, which want n8n, and which should stay manual.

## How it works — the 6 phases

```
INTERVIEW  →  DESIGN  →  DEEP TOOL DISCOVERY  →  SPEC REVIEW  →  SPEC EMISSION  →  SPEC EVOLUTION
  (deep)    (general)      (per-step)             (walkthrough)    (folder out)    (rerun on change)
```

Every phase has a gate — the user must explicitly approve before the skill advances:

1. **Deep Interview** — 9-category structured questioning until zero ambiguity. Bilingual (English / Spanish). Emits `business-graph.json` silently.
2. **General Design** — `designer-agent` subagent (fork context) emits `agent-profiles.yaml` with CrewAI-shaped profiles + topology selection. Anticipation pass surfaces unrequested-but-needed agents.
3. **Deep Tool Discovery** — Per agent action, find the BEST integration path. 4-step protocol: MCP search → API investigation → n8n suitability → manual triage. Every tool gets a readiness tier with evidence URL. `browser-discovery` subagent fills in services without docs.
4. **Spec Review** — Walkthrough of the proposed spec folder shape across 6 dimensions (workflows, agents, tools, governance, effort, hand-off completeness). User signs off before any files are written.
5. **Spec Emission** — `spec-engine` subagent writes the canonical spec folder via 6-step protocol. Single sub-gate `spec_folder_emitted`. Emits `SPEC-EMISSION-REPORT.md` (success) or `SPEC-EMISSION-FAILED-REPORT.md` (halt).
6. **Spec Evolution** — When requirements change, rerun AgentBloc on the existing spec folder. Reads existing `.agentbloc/spec/` as ground truth, re-interviews where needed, re-emits via diff mode.

## The 5-tier readiness ranking

The highest-leverage decision in the whole skill happens in Phase 3. Every tool every agent needs gets exactly one tier with an evidence URL:

| Tier | Meaning | Build effort |
|---|---|---|
| `EXISTS-MCP` | Public MCP server already exists | Hours (install + config) |
| `NEEDS-MCP-WRAPPER` | Vendor API exists, no public MCP; wrapper buildable via `mcp-builder` | Days |
| `NEEDS-N8N-FLOW` | Visual / branching / multi-service logic; n8n is the right tool | Days |
| `NEEDS-WEBHOOK` | Vendor pushes events; receiver must be built and exposed | Days |
| `MANUAL` | No automation appropriate (compliance, frequency, cost, judgment) | Near-zero (runbook only) |

`ROADMAP.md` rolls these into a phased build plan so your AI coding session knows what to do first.

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

## Hand-off to any AI coding tool

| Tool | How user invokes after AgentBloc emits |
|---|---|
| **Claude Code** | `cd <spec-folder> && claude` (CLAUDE.md + skills/subagents available) |
| **Codex CLI** | `cd <spec-folder> && codex` (reads AGENTS.md) |
| **Cursor** | Open spec folder; AGENTS.md becomes project context |
| **Gemini Code Assist** | Same — universal markdown context |
| **OpenClaw** | Same |

## Worked example

[`.claude/skills/agentbloc/examples/arco-rooms-spec/`](.claude/skills/agentbloc/examples/arco-rooms-spec/) is the full Arco Rooms (Spanish property-management) spec folder showing the canonical output for a 3-agent Pipeline team across 6 utility providers and 4 banks. Open it, read `CLAUDE.md`, and you'll see exactly what an AI coding session receives.

## Documentation

- [`docs/architecture.md`](docs/architecture.md) — design lock for the spec engine
- [`.claude/skills/agentbloc/SKILL.md`](.claude/skills/agentbloc/SKILL.md) — the conversation engine
- [`.claude/skills/agentbloc/references/`](.claude/skills/agentbloc/references/) — 40+ reference docs (one per phase + one per integration tier)
- [`.claude/skills/agentbloc/examples/`](.claude/skills/agentbloc/examples/) — worked examples (Arco Rooms, e-commerce, freelance pipeline)
- [`CHANGELOG.md`](CHANGELOG.md) — release notes

## License

MIT — see [LICENSE](LICENSE).
