# Phase 6: Spec Evolution

> Loaded by SKILL.md when Phase 6 begins. There is no live runtime to monitor;
> audit-log forensics, scan-detect-propose-approve loops, and runtime-history
> ledgers are all out of scope.

## Table of Contents

- [When This Applies](#when-this-applies)
- [Preconditions](#preconditions)
- [The Loop](#the-loop)
- [What Triggers Evolution](#what-triggers-evolution)
- [Diff vs Replace](#diff-vs-replace)
- [Cross-References](#cross-references)

## When This Applies

Phase 6 is the post-emission lifecycle. The user has a spec folder
(emitted in Phase 5) and now wants to update it because something
changed: new business requirement, new tool became available, security
posture shifted, the build session learned something the spec didn't
anticipate.

This is a SHORT phase. AgentBloc is not a live monitor. The user's
build session — wherever it lives — owns runtime monitoring. AgentBloc
owns spec evolution.

## Preconditions

- A spec folder exists at `.agentbloc/spec/` (or user-provided path)
- The folder validates against [spec-folder-structure.md](spec-folder-structure.md)
- The folder contains a SPEC-EMISSION-REPORT.md from a prior Phase 5

If any of these fail, return Phase 5 to `pending` and re-run the spec
emission flow before attempting evolution.

## The Loop

Spec Evolution is a re-entry into AgentBloc with the existing spec
folder as ground truth:

1. **Read existing spec** — load business-graph.json, agent-profiles.yaml,
   inventory.yaml, and SPEC-EMISSION-REPORT.md from the prior emission
2. **Identify the change** — ask the user what shifted (new requirement,
   tool change, scope reduction, etc.)
3. **Re-interview only the affected phases** — if a workflow changed,
   re-run Phase 1 for that workflow only; if a tool became available,
   re-run Phase 3 for that tool only
4. **Re-emit the affected portions** — `spec-engine` re-writes the
   affected files in place; the SPEC-EMISSION-REPORT.md gets a new
   "Revision History" section appended
5. **Hand back to the build session** — the build session reads the
   updated spec and adjusts its work

Phase 6 has no sub-gate of its own. It exits when the user says the
revised spec covers the change. If the change is large enough to affect
all phases, AgentBloc will recommend starting fresh in a new spec folder
rather than mutating the existing one.

## What Triggers Evolution

Common triggers and which phase they touch:

| Trigger | Affected phase | Re-run cost |
|---|---|---|
| New workflow added (e.g., "also handle refunds") | Phase 1 + 2 + 3 + 5 | High — most of the spec changes |
| Existing workflow changed (different success criteria) | Phase 1 + 5 | Medium |
| New agent role needed | Phase 2 + 3 + 5 | Medium |
| Tool deprecated / replaced (new MCP appeared) | Phase 3 + 5 | Low |
| Tool tier changed (was MANUAL, now NEEDS-MCP-WRAPPER) | Phase 3 + 5 | Low |
| Compliance posture changed (new GDPR requirement) | Phase 4 (governance) + 5 | Low |
| Security finding from build session | Phase 4 + 5 | Low |
| Build session blocked on ambiguity | Targeted re-interview + 5 | Low |

The cost column is an estimate; the actual re-run scope depends on how
much the change cascades through dependent phases.

## Diff vs Replace

When re-emitting, `spec-engine` defaults to **diff mode**: only files
affected by the change get rewritten. The SPEC-EMISSION-REPORT.md gets
a new section:

```markdown
## Revision History

### Revision 2 — 2026-05-15

Trigger: User added a refunds workflow.

Files changed:
  workflows/04-refund-handling.md  (new)
  agents/refund-processor/         (new agent)
  integrations/INVENTORY.md        (added Stripe webhook tier)
  integrations/needs-webhook/stripe-refund-webhook.md  (new)
  ROADMAP.md                       (effort estimate updated)
```

If the change is so large that diff mode produces a tangled spec,
recommend `--replace` mode instead: re-emit the entire folder under a
new path (`spec-v2/`) and let the user migrate. This preserves the prior
spec for forensic comparison.

## Cross-References

- [phase-5-spec-emission.md](phase-5-spec-emission.md) — what gets re-emitted
- [spec-emission-protocol.md](spec-emission-protocol.md) — the 6-step canonical flow
- [spec-folder-structure.md](spec-folder-structure.md) — output shape spec
- [.claude/agents/spec-engine.md](../../../agents/spec-engine.md) — the subagent
