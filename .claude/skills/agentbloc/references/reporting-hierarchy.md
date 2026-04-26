# Reporting Hierarchy (Phase 14)

> Phase 14 reference. MONITOR-05 chain: individual agents -> team leads -> briefing agent -> human. v2.0 ships flat (every agent writes own log; briefing reads all). Team-lead aggregation is v2.5 scope.

## Table of Contents

- [When This Applies](#when-this-applies)
- [The 4-Layer Chain](#the-4-layer-chain)
- [v2.0 Flat Hierarchy](#v20-flat-hierarchy)
- [v2.5 Team-Lead Placeholder](#v25-team-lead-placeholder)
- [Critical Escalations Bypass Briefing](#critical-escalations-bypass-briefing)
- [Cross-References](#cross-references)

## When This Applies

Every team deploys with a briefing agent (per `templates/briefing-agent.md.tmpl`). Reporting flows through the chain at the briefing-agent's daily wake. Loaded UNCONDITIONALLY at Phase 5 entry per D-58.

## The 4-Layer Chain

```
[Layer 1: Individual Agents]   <- write own JSONL logs per wake
        |
        v
[Layer 2: Team Leads]   <- v2.5 mid-tier aggregators (NOT in v2.0)
        |
        v
[Layer 3: Briefing Agent]   <- consolidates day's logs + dispatches
        |
        v
[Layer 4: Human]   <- receives Telegram briefing thread message
```

- **Layer 1:** Each deployed agent writes to `.claude/agents/logs/<DATE>/<agent-id>.jsonl` per `references/jsonl-log-schema.md`.
- **Layer 2 (v2.5 placeholder):** When team size > 5 agents, deploy-engine generates a team-lead aggregator agent that pre-reduces sibling agents' logs. v2.0 ships flat (no Layer 2); v2.5 web dashboard scope.
- **Layer 3:** The briefing-agent (per `templates/briefing-agent.md.tmpl`) globs all Layer 1 (and Layer 2 in v2.5) outputs + produces the daily summary.
- **Layer 4:** Human reads the Telegram briefing thread message; replies with `/approve` (approvals thread) or `/resume` (escalations thread) when action required.

## v2.0 Flat Hierarchy

v2.0 collapses Layer 2; briefing reads Layer 1 directly:

```
[All deployed agents]
        |
        v (briefing-agent globs .claude/agents/logs/<TODAY>/*.jsonl)
        |
[Briefing Agent]
        |
        v (Telegram briefing thread)
        |
[Human]
```

Rationale: small-team scale (typical AgentBloc deployment is 3-7 agents per Arco Rooms target). Mid-tier aggregation pays off when team size exceeds Layer-3 context budget; rarely the case at v2.0 scope. Flat hierarchy is operationally simpler, debuggable, and matches v1.0 file-based-state principles.

## v2.5 Team-Lead Placeholder

When v2.5 web dashboard ships:
- `registry.yaml` gains a `team_leads:` array + per-agent `lead_for: <team-id>` field.
- Team-lead aggregator script `.agentbloc/runtime/team-lead-aggregate.sh <team-id> <DATE>` pre-reduces logs.
- Briefing agent reads team-lead summaries instead of (or in addition to) raw per-agent logs.
- Schema is forward-compatible: v2.0 deployments do not need migration.

The placeholder is documented here so v2.5 phase work needs zero rewrites of this reference.

## Critical Escalations Bypass Briefing

Escalations with `priority: critical` route directly to the `escalations_thread_id` Telegram thread per AUTON-04 + `references/escalation-protocol.md`. The briefing-agent summarizes them in next morning's briefing but does NOT gate them; latency would be unacceptable for system-broken states. The 3-thread separation per CTRL-01 (approvals + briefing + escalations) is the structural enforcement.

## Cross-References

- [jsonl-log-schema.md](jsonl-log-schema.md) , Layer 1 file format
- [escalation-protocol.md](escalation-protocol.md) , critical-escalation bypass path
- [briefing-agent.md.tmpl](../templates/briefing-agent.md.tmpl) , Layer 3 template (Plan 14-02)
