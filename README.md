# AgentBloc

> A Claude Code skill that interviews you about a manual business process and ships a deployed, monitored, security-hardened AI agent team. Conversation in, runnable agents out.

[![version: 2.0.0](https://img.shields.io/badge/version-2.0.0-blue)](https://github.com/pablodelarco/agentbloc/releases/tag/v2.0.0) [![license: MIT](https://img.shields.io/badge/license-MIT-green)](LICENSE) [![Claude Code: v2.1+](https://img.shields.io/badge/Claude%20Code-v2.1%2B-blueviolet)](https://claude.ai/code) [![CI](https://github.com/pablodelarco/agentbloc/actions/workflows/ci.yml/badge.svg)](https://github.com/pablodelarco/agentbloc/actions/workflows/ci.yml) [![tests: 146 passing](https://img.shields.io/badge/tests-146%20passing-brightgreen)](tests/run-tests.sh)

## What you get

You describe a business process you do by hand. AgentBloc returns:

- A structured **Business Graph** of your workflow, stored as JSON
- An **`agent-profiles.yaml`** team designed for you (CrewAI-shaped roles, topology picked, orchestration patterns classified)
- **Anticipated agents** you didn't ask for, tagged `[ANTICIPATED]` with rationale + 3 evidence URLs each
- Verified **MCP integrations** for every tool the team needs (with browser-fallback discovery for portals without APIs)
- A **deployed team** materialized into runnable `.claude/skills/<agent-id>/` artifacts + per-agent memory + cron + n8n webhook wiring
- A **monitor + control plane** with Telegram approvals, cost tracking, task locking, and a daily briefing message

You never write code. You confirm decisions at six conversational gates. Security, audit logging, GDPR patterns, and a kill switch are built in from the first interview question.

## Why AgentBloc exists

DIY agent scripting hits the same five walls every time: ambiguous interview, hand-curated team that misses the obvious, brittle integration discovery, no dry run before going live, and no operational story for what happens after deploy. AgentBloc is the structured flow that closes all five, plus the consulting-product layer (Anticipation Engine) that surfaces the agents you didn't think to ask for.

It runs as a pure markdown Claude Code skill. No custom runtime. The deployed agents run on your machine, your VPS, or any host with Claude Code installed.

## What's New in v2.0

| Capability | What it does | Source of truth |
|---|---|---|
| **Designer Agent** | Auto-emits `agent-profiles.yaml` from your interview. Picks topology (mesh / pipeline / hierarchy / swarm) and classifies workflows into the 5 ADK orchestration patterns. Forked context, scoped tools, no Bash. | `.claude/agents/designer-agent.md` |
| **Anticipation Engine** | Proposes unrequested-but-needed agents from evidence-backed business-type heuristics. 5 SMB shapes shipped: rental, ecommerce, freelance, restaurant, professional services. Each anticipated agent ships rationale + 3 source URLs. Declines persist in `.agentbloc/graph/declined.json` (business-level memory). | `.claude/skills/agentbloc/references/anticipation-heuristics.md` |
| **Deploy Pipeline** | Materializes the team into runnable per-agent skill files + memory directories + team `registry.yaml` + `.mcp.json` merges + a `DEPLOY-REPORT.md`. Idempotent re-runs via SHA256 + RFC 8785 canonicalization. | `.claude/agents/deploy-engine.md` |
| **Multi-Agent Runtime** | Wires cron + n8n webhook triggers + inter-agent SendMessage with `correlation_id` propagation through the full chain. KILL_SWITCH file + Telegram `/stop` halt the entire active team. | `.claude/agents/runtime-engine.md` |
| **Autonomy + Monitor + Control Plane** | Per-agent autonomy levels (`full` / `semi` / `supervised`). Approvals route through a separate Telegram thread. JSONL log schema with cost + token tracking. Daily briefing-agent emits status badges (🟢 active · 🟡 idle · 🔴 error). flock-based task locking for shared resources. | `references/autonomy-controller.md` + `references/jsonl-log-schema.md` |
| **End-to-End Validation** | Canonical Arco Rooms scenario exercises all 13 v2.0 categories. TAP harness reports 146/146 tests pass. | `tests/scenarios/arco-rooms.jsonl` |


## Quick Start

Requires [Claude Code](https://claude.ai/code) v2.1 or later.

**1. Clone and install the skill:**

```bash
git clone https://github.com/pablodelarco/agentbloc.git
mkdir -p ~/.claude/skills/agentbloc
cp -r agentbloc/.claude/skills/agentbloc/* ~/.claude/skills/agentbloc/
```

(Optional: also copy the four subagents if you want the v2.0 Designer / Deploy / Runtime / Browser-Discovery roles)

```bash
mkdir -p ~/.claude/agents
cp agentbloc/.claude/agents/*.md ~/.claude/agents/
```

**2. Start a conversation:**

Open Claude Code and either type `/agentbloc` or describe your business problem directly:

> "I run a property management company and spend 3 hours a day matching invoices to bank payments across 6 providers."

AgentBloc detects your language (English or Spanish) and technical level automatically, then begins the structured interview. No configuration needed.

## How It Works

**The 6-phase conversational flow** (every phase has a hard gate; you must explicitly approve before the skill advances):

```
INTERVIEW --> DESIGN --> INTEGRATION --> CONFIRMATION --> DEPLOYMENT --> EVOLUTION
  (deep)     (agents)   (per-action)   (+ dry run)      (artifacts)   (self-improve)
```

1. **Interview** , 9-category structured questioning until there is zero ambiguity. Emits the Business Graph silently.
2. **Design** , Designer Agent subagent runs in fork-context, emits `agent-profiles.yaml`, then runs the Anticipation Pass. You review a rendered table + per-agent cards + ASCII topology diagram.
3. **Integration** , 4-step search per tool: existing `.mcp.json` -> ecosystem MCP registry -> wrapper generation via `mcp-builder` skill -> browser-fallback discovery. Every claim backed by evidence (URL + version + last-commit date).
4. **Confirmation + Dry Run** , Step-by-step approval of every agent action, followed by a mandatory dry run with side effects stubbed.
5. **Deployment** , `deploy-engine` materializes runnable artifacts. `runtime-engine` wires cron + n8n. Approval threads + briefing agent + activity feed go live.
6. **Evolution** , Post-deploy weekly scans for new capabilities, vulnerability disclosures, MCP server updates, and selector drift on browser-fallback integrations. Every proposal requires human approval.

**After deployment**, the team runs autonomously: cron triggers fire on schedule, n8n webhooks wake event-driven agents, inter-agent SendMessage handles peer coordination, autonomy gates route external side-effects to Telegram approval threads, and the briefing agent emits a daily team-health summary at 08:00 your timezone.

## Engineering Rigor

This is not a prototype. v2.0 is the result of 9 phases of explicit planning, execution, and verification:

- **79 requirements** closed across 13 categories (INTV / BGRAPH / DSGN / ORCH / INTEG / BROWSER / DEPLOY / MEM / RUNTIME / AUTON / MONITOR / CTRL / ANTIC)
- **27 plans** shipped with atomic-commit discipline (one commit per task, every commit tested)
- **47 reference files** in `.claude/skills/agentbloc/references/` covering every protocol, schema, and security pattern
- **4 specialized subagents** (`designer-agent`, `deploy-engine`, `runtime-engine`, `browser-discovery`) with scoped tool allow-lists
- **146 TAP tests** validating scenario structure, phase sequence, v2.0 category coverage, and SKILL.md cross-references
- **Per-phase decision logs** (D-58 through D-107) documenting every architectural trade-off with alternatives considered
- **Em-dash gate, surgical-edit discipline, RFC 8785 canonicalization, SHA256 idempotency** across the deploy pipeline
- **Evidence-backed heuristics**: 15 cited URLs in the anticipation map, all reachable (Playwright-verified, no broken links at v2.0.0 ship)


## Examples

Three complete walkthroughs covering the full conversational flow:

- **[Arco Rooms](.claude/skills/agentbloc/examples/arco-rooms.md)** , Real estate property management in Almeria, Spain. Multi-provider invoice collection across 6 utility portals, payment matching across 7 bank accounts via PSD2, owner-facing Telegram reporting. **5-agent v2.0 fixture** at [`arco-rooms-anticipated-profiles.yaml`](.claude/skills/agentbloc/examples/arco-rooms-anticipated-profiles.yaml) (3 requested + 2 anticipated: Profitability Analyst + Incident Tracker).
- **[E-commerce Support](.claude/skills/agentbloc/examples/ecommerce-support.md)** , Customer support automation. Order tracking, refund processing, escalation routing. Hierarchy topology.
- **[Freelance Pipeline](.claude/skills/agentbloc/examples/freelance-pipeline.md)** , Lead capture, proposal generation, invoice tracking. Pipeline topology.

Each walkthrough covers all six phases end to end: interview transcript, agent design rationale, integration choices, dry run findings, deployed artifact tree.

## Stack Context

AgentBloc runs as a markdown skill INSIDE [ClaudeClaw](https://github.com/anthropics/claude-claw), the TypeScript + Bun substrate that provides Agent / TeamCreate / SendMessage / Jobs / Telegram primitives. [n8n](https://n8n.io) is the event bus for real-time webhook triggers. AgentBloc itself is pure markdown , no custom runtime.

Framework patterns inherited (not adopted as dependencies):
- **CrewAI** , role / goal / backstory shape per agent
- **AG2 (CaptainAgent)** , dynamic team generation via Designer Agent subagent
- **Google ADK** , 5-pattern orchestration classification (Sequential / Parallel / Loop / Event-driven / Conversational)
- **LangGraph** , file-based state checkpointing pattern
- **Mastra** , front-matter validators between agents
- **Paperclip** , control plane UX (approval queue, cost tracking, task locking, status badges)

## Project Structure

```
agentbloc/
  .claude/
    skills/agentbloc/
      SKILL.md           # The skill hub (the entry point Claude Code reads)
      references/        # 47 protocol + schema + security pattern files
      examples/          # 11 Arco Rooms + ecommerce + freelance fixtures
    agents/              # 4 subagents (designer + deploy + runtime + browser-discovery)
  tests/
    run-tests.sh         # TAP harness (146 tests, 6 validation categories)
    scenarios/           # JSONL conversation transcripts per example
  .planning/             # Phase-by-phase work product (CONTEXT, PLAN, SUMMARY, VERIFICATION per phase)
    milestones/          # Shipped milestone archives (v1.0, v2.0)
  CHANGELOG.md           # Keep-a-Changelog format
  CONTRIBUTING.md        # How to contribute + skill development rules
  SECURITY.md            # Security disclosure policy
  LICENSE                # MIT
```

`SKILL.md` is the lean hub (~210 lines). All detailed protocols live in `references/` and load on demand during each phase. This progressive-disclosure pattern keeps context windows efficient across long multi-phase conversations.

## Status

| Milestone | Status | Phases | Requirements | Shipped |
|---|---|---|---|---|
| **v1.0 Initial Release** | shipped | 7 | 68 | 2026-04-18 |
| **v2.0 Designer + Deploy** | shipped | 9 | 79 | 2026-04-26 |
| v2.5 (planned) | scope TBD | tentative web dashboard + SQLite event storage | , | , |

## Contributing

Contributions are welcome. See [CONTRIBUTING.md](CONTRIBUTING.md) for guidelines on how to contribute, skill development rules, and the code of conduct. For security disclosure, see [SECURITY.md](SECURITY.md).

## License

[MIT](LICENSE)
