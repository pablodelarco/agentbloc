# AgentBloc

> From manual process to autonomous AI agent team, one conversation at a time.

AgentBloc is a Claude Code skill that turns a business workflow description into a deployed, secure AI agent team. No code required. You describe the problem, AgentBloc interviews you, designs the agents, verifies every integration, runs a dry run, and generates production-ready artifacts.

![version: 2.0.0](https://img.shields.io/badge/version-2.0.0-blue) ![license: MIT](https://img.shields.io/badge/license-MIT-green) ![Claude Code: v2.1+](https://img.shields.io/badge/Claude%20Code-v2.1%2B-blueviolet) [![CI](https://github.com/pablodelarco/agentbloc/actions/workflows/ci.yml/badge.svg)](https://github.com/pablodelarco/agentbloc/actions/workflows/ci.yml)

## What is AgentBloc?

AgentBloc is an open-source Claude Code skill that guides you from "I have a manual business process" to "I have a secure, auditable AI agent team running in production" through a structured 6-phase conversational flow.

**Who it is for:** Business owners and ops teams who want to automate workflows without writing code. Developers and consultants who want to accelerate agent team delivery.

**What it produces:** A deployable agent team that runs natively on Claude Code + cron + MCP servers + Telegram. Zero custom runtime. File-based state. Security baked in from Phase 1.

**What makes it different:** A structured 6-phase flow with hard gates at every transition. Security-first design with data classification, blast-radius scoring, and audit logging. Mandatory dry run before anything goes live. Every integration claim backed by evidence.

The skill supports both English and Spanish, adapting language and technical depth to your level.

## What's New in v2.0

AgentBloc v2.0 ships the **proactive AI consultant** layer: the skill now designs the agent team for you, anticipates agents you didn't ask for, and deploys end-to-end without leaving the conversation.

- **Designer Agent** auto-emits an `agent-profiles.yaml` from your interview, picking topology and orchestration patterns. The user-facing review is a rendered table plus per-agent cards plus an ASCII topology diagram; the YAML stays silent.
- **Anticipation Engine** proposes unrequested-but-needed agents from evidence-backed business-type heuristics (5 SMB shapes shipped: rental, ecommerce, freelance, restaurant, professional services). Each anticipated agent carries a 1-2 sentence rationale plus 3+ source URLs and is marked `[ANTICIPATED]` so you can accept, decline, or defer each.
- **Deploy Pipeline** materializes the team into runnable `.claude/skills/<agent-id>/` artifacts plus `.agentbloc/agents/<agent-id>/{memory.md, state.json, last-run.json}` memory directories plus a team `registry.yaml`. Idempotent re-runs via SHA256 plus RFC 8785 canonicalization.
- **Multi-Agent Runtime** wires cron plus n8n webhook triggers plus inter-agent SendMessage with correlation-ID propagation through the full chain. KILL_SWITCH file plus Telegram `/stop` halt the entire active team.
- **Autonomy + Monitor + Control Plane** routes external-side-effect approvals through a separate Telegram thread, tracks per-agent cost and tokens, locks shared resources via flock, and emits a daily briefing message with status badges (🟢 active · 🟡 idle · 🔴 error).

**Stack context:** v2.0 runs as a markdown skill INSIDE [ClaudeClaw](https://github.com/anthropics/claude-claw) (TypeScript + Bun substrate providing Agent / TeamCreate / SendMessage / Jobs / Telegram primitives) with [n8n](https://n8n.io) as the event bus for real-time webhook triggers. AgentBloc itself remains pure markdown , no custom runtime added on AgentBloc's side. Framework patterns inherited (not adopted as dependencies) from CrewAI (role/goal/backstory) plus AG2 (CaptainAgent dynamic team generation) plus Google ADK (Sequential/Parallel/Loop primitives) plus LangGraph (file-based state checkpointing) plus Mastra (front-matter validators) plus Paperclip (control plane UX patterns).

## Quick Start

Requires [Claude Code](https://claude.ai/code) v2.1 or later.

**1. Clone and install the skill:**

```bash
git clone https://github.com/pablodelarco/agentbloc.git
mkdir -p ~/.claude/skills/agentbloc
cp -r agentbloc/SKILL.md agentbloc/references/ agentbloc/examples/ ~/.claude/skills/agentbloc/
```

**2. Start a conversation:**

Open Claude Code and either type `/agentbloc` or describe your business problem directly:

> "I run a property management company and spend 3 hours a day matching invoices to bank payments across 6 providers."

AgentBloc will detect your language (English or Spanish) and technical level automatically, then begin the structured interview. No configuration needed.

## How It Works

```
INTERVIEW --> DESIGN --> INTEGRATION --> CONFIRMATION --> DEPLOYMENT --> EVOLUTION
  (deep)     (agents)   (per-action)   (+ dry run)      (artifacts)   (self-improve)
```

1. **Interview** -- Deep structured interview across 9 categories until there is zero ambiguity about your workflow, data, and edge cases.
2. **Design** -- Translate the interview into an agent team: topology, contracts, schedules, governance, and blast-radius scoring.
3. **Integration** -- Research the best integration method for every agent action. API, MCP server, Playwright, email scraping, webhooks. Every claim backed by evidence.
4. **Confirmation + Dry Run** -- Step-by-step approval of every agent action, followed by a mandatory dry run against real data with side effects stubbed.
5. **Deployment** -- Generate the complete `.agentbloc/` artifact directory: YAML configs, agent skills, governance, Telegram reporting, cron jobs, incident response runbook.
6. **Evolution** -- Post-deploy self-improvement loop. Weekly scans for new capabilities and vulnerabilities, with human approval before any changes.

Each phase has a hard gate. You must explicitly approve before the skill advances.

## Project Structure

```
agentbloc/
  SKILL.md              # Skill hub (the entry point Claude Code reads)
  references/           # Phase protocols, security patterns, glossaries
  examples/             # Full 6-phase walkthrough examples
```

SKILL.md is the lean hub (~160 lines). All detailed protocols live in `references/` and are loaded on demand during each phase. This progressive disclosure pattern keeps context windows efficient across long multi-phase conversations.

## Examples

Three complete walkthroughs demonstrating the full 6-phase flow, each using a different agent team topology:

- **[Arco Rooms](examples/arco-rooms.md)** -- Real estate property management in Almeria, Spain. Multi-provider invoice collection, bank payment matching, Telegram reporting. Pipeline topology.
- **[E-commerce Support](examples/ecommerce-support.md)** -- Customer support automation. Order tracking, refund processing, escalation routing. Hierarchy topology.
- **[Freelance Pipeline](examples/freelance-pipeline.md)** -- Business pipeline management. Lead capture, proposal generation, invoice tracking. Pipeline topology.

Each walkthrough covers all six phases end to end: what was asked in the interview, how the agents were designed, which integrations were selected, what the dry run revealed, and what artifacts were generated.

## Contributing

Contributions are welcome. See [CONTRIBUTING.md](CONTRIBUTING.md) for guidelines on how to contribute, skill development rules, and our code of conduct.

## License

[MIT](LICENSE)
