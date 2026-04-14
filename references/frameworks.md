# Agent Framework Patterns

> Loaded by the design protocol during Phase 2. Maps patterns from CrewAI, LangGraph, and n8n to AgentBloc design decisions. These frameworks are referenced for their design patterns, not their runtimes. AgentBloc runs on Claude Code natively.

## Table of Contents

- [When This Applies](#when-this-applies)
- [CrewAI Patterns for AgentBloc](#crewai-patterns-for-agentbloc)
- [LangGraph Patterns for AgentBloc](#langgraph-patterns-for-agentbloc)
- [n8n Patterns for AgentBloc](#n8n-patterns-for-agentbloc)
- [Pattern Application by Tech Level](#pattern-application-by-tech-level)
- [Quick Reference](#quick-reference)

## When This Applies

Claude loads this file during the Design Phase. Specific sections are referenced based on the current design step:

- **Agent Identification (Step 1):** reference CrewAI for role-based decomposition. Break the workflow into distinct job roles, each with a clear responsibility boundary.
- **Topology Selection (Step 2):** reference LangGraph for the topology decision tree. Match the workflow's coordination pattern to Pipeline, Hierarchy, Mesh, or Swarm.
- **User Explanation:** reference n8n for the visual DAG mental model. Non-technical users understand "steps with arrows" better than "agents with topologies."

## CrewAI Patterns for AgentBloc

**Key concept:** Role-based agent definition. Each agent has a specific job title, a bounded scope of work, and defined outputs.

### Concept Mapping

| CrewAI Concept | AgentBloc Equivalent | Notes |
|---------------|---------------------|-------|
| `role` | Role field in contract card | Function or expertise description. Be specific. |
| `goal` | Responsibility field | Scoped outcome this agent owns |
| `backstory` | Not used | AgentBloc agents are cron-triggered, not conversational personas |
| `tools` | Tools field + blast-radius allowed_tools | Restricted by blast-radius level (see blast-radius.md) |
| `expected_output` | Outputs field | Specific file paths, message formats, or state mutations |
| `Task.description` | Agent's responsibility scoped to one workflow step | One task per agent. If an agent has two tasks, split it. |

### Best Practices

Use specific, function-focused role descriptions. "Invoice Collection Specialist" not "Data Agent." "Payment Reconciliation Engine" not "Processor." The role name should tell a stranger what this agent does without reading the rest of the contract.

**When to apply:** Always. This is the default agent identification method for every AgentBloc design.

### Arco Rooms Example

The Arco Rooms property management team uses CrewAI-style role decomposition:

| Agent | Role | Responsibility | Blast Radius |
|-------|------|---------------|--------------|
| Invoice Collector | Invoice Collection Specialist | Fetch new invoices from six utility providers via API, Gmail, or Playwright | Level 2 (write-scoped) |
| Payment Matcher | Payment Reconciliation Engine | Match bank transactions to invoices using regex patterns and confidence thresholds | Level 2 (write-scoped) |
| Report Sender | Daily Operations Reporter | Send Telegram summaries for confirmed payments, new invoices, and unmapped items | Level 4 (send-external) |

Each agent owns one step. No agent both collects data and sends reports.

## LangGraph Patterns for AgentBloc

**Key concept:** Stateful topology patterns. The shape of agent coordination determines how data flows and who controls sequencing.

### Topology Mapping

| LangGraph Pattern | AgentBloc Topology | When to Use | Agent Count |
|-------------------|-------------------|-------------|-------------|
| Sequential Pipeline | Pipeline | Fixed sequential stages, each feeding the next | 1-3 |
| Supervisor | Hierarchy | Centralized coordinator delegates to specialist agents | 3-5+ |
| Swarm | Swarm | Unknown optimal paths, parallel collection from many sources | 5+ |
| Mesh (peer-to-peer) | Mesh | Iterative refinement on shared artifacts, mutual feedback | 3-8 |

### Topology Decision Tree

Follow these steps to select the right topology:

1. Are all subtasks independent with no inter-agent communication needed? Use **Pipeline**.
2. Is the sequence fixed and predictable (collect, process, report)? Use **Pipeline**.
3. Do 3-8 agents iterate on a shared artifact, each improving the other's output? Use **Mesh**.
4. Is the optimal execution path unknown or data-dependent? Use **Swarm**.
5. Are there 5+ agents spanning multiple domains that need centralized coordination? Use **Hierarchy**.
6. When in doubt: start with **Pipeline**. Upgrade to Hierarchy if the team grows beyond 3 agents.

### Practical Sizing

| Agent Count | Recommended Topology | Rationale |
|-------------|---------------------|-----------|
| 1-3 | Pipeline | Simple sequential flow, minimal coordination overhead |
| 3-5 | Hierarchy | Coordinator agent manages handoffs and error routing |
| 5+ | Evaluate Hierarchy or Hybrid | Pure Pipeline becomes brittle. Consider a Hierarchy with Pipeline sub-chains |

### State Checkpoint Pattern

LangGraph uses persistent state with time-travel for crash recovery. AgentBloc borrows this concept through JSON state files in `.agentbloc/state/`. Each agent writes a checkpoint after every side effect. If a run crashes mid-execution, the next run resumes from the last checkpoint rather than reprocessing everything. This maps directly to the idempotency pattern demonstrated in Arco Rooms.

## n8n Patterns for AgentBloc

**Key concept:** Visual DAG mental model. n8n represents workflows as boxes connected by arrows, where each box is a step and each arrow shows information flow.

### What AgentBloc Borrows

The explanatory mental model for non-technical users. When presenting a design to someone who has never heard of "agent topology," describe it as: "Each agent is a step in your workflow. Arrows show where information flows from one step to the next. Some steps run in sequence, others run in parallel."

This framing makes Pipeline topology intuitive ("a straight line of steps"), Hierarchy understandable ("one coordinator step managing several worker steps"), and even Mesh approachable ("steps that pass work back and forth until the result is good enough").

### Deterministic + AI Step Mix

n8n mixes deterministic nodes (HTTP request, filter, transform) with AI nodes (LLM call, classification). AgentBloc applies the same principle through model routing: not every agent needs Opus-level reasoning. A data collector checking for new invoices can use Haiku. A payment matcher applying regex rules can use Sonnet. Only complex reconciliation or anomaly detection warrants Opus. This maps to the model field in agent.yaml.

### When to Apply

Use the n8n mental model whenever explaining the agent team design to non-technical users. Do not use n8n terminology in the generated artifacts (agent.yaml, governance.yaml). The artifacts use AgentBloc's own vocabulary.

## Pattern Application by Tech Level

Claude adjusts how deeply it references each framework based on the user's technical level (captured during the interview phase):

| User Tech Level | CrewAI Pattern | LangGraph Pattern | n8n Pattern |
|-----------------|---------------|-------------------|-------------|
| non-technical | Implicit (applied behind the scenes, not named) | Implicit (topology chosen without framework jargon) | Primary: visual flow metaphor used to explain the design |
| technical-basics | Light reference ("we use role-based decomposition") | Light reference ("pipeline topology for your 3-step workflow") | Light reference ("think of it like a workflow builder") |
| developer | Full mapping table shown, pattern names explicit | Full decision tree walkthrough, topology trade-offs discussed | Brief mention as explanatory analogy only |

For non-technical users, the frameworks inform the design silently. The user sees "here are your three agents and what each one does," not "we applied CrewAI role-based decomposition with a LangGraph sequential pipeline topology."

## Quick Reference

- **CrewAI:** Role-based agent decomposition. Every agent gets a specific job title, bounded responsibility, and defined outputs. Default method for agent identification.
- **LangGraph:** Topology selection via decision tree. Pipeline for simple flows, Hierarchy for 3-5+ agents, Mesh for iterative refinement, Swarm for unknown paths.
- **n8n:** Visual DAG mental model for non-technical explanation. "Steps with arrows." Also informs the deterministic vs. AI step mix through model routing.
- **Key rule:** These are borrowed patterns, not imported runtimes. AgentBloc runs on Claude Code. No Python, no TypeScript frameworks, no `pip install`, no `npm install`.
