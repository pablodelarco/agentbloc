---
phase: 07-testing-and-ci
plan: 01
subsystem: testing
tags: [jsonl, test-scenarios, validation, interview-flow]
dependency_graph:
  requires: [examples/arco-rooms.md, examples/ecommerce-support.md, examples/freelance-pipeline.md, SKILL.md]
  provides: [tests/scenarios/arco-rooms.jsonl, tests/scenarios/ecommerce-support.jsonl, tests/scenarios/freelance-pipeline.jsonl]
  affects: [07-02-PLAN (test runner consumes these scenarios)]
tech_stack:
  added: [JSONL scenario format]
  patterns: [user/assistant/assertion role schema, gate transition metadata, structural regex assertions]
key_files:
  created:
    - tests/scenarios/arco-rooms.jsonl
    - tests/scenarios/ecommerce-support.jsonl
    - tests/scenarios/freelance-pipeline.jsonl
  modified: []
decisions:
  - "Each JSONL line includes phase and gate on every turn (not just boundaries) for self-documenting consistency"
  - "Assertion patterns validate structure (tables, diagrams, state bars) not conversational prose"
  - "50 turns per scenario balances coverage with maintainability"
metrics:
  duration: 10m
  completed: 2026-04-18
  tasks: 2
  files_created: 3
  total_lines: 150
---

# Phase 07 Plan 01: Test Scenario Files Summary

Three JSONL test scenario files covering the full 6-phase AgentBloc conversational flow across distinct topology, persona, and compliance combinations.

## What Was Built

Three machine-parseable, human-readable JSONL scenario files in `tests/scenarios/`:

| File | Lines | Topology | User Level | Data | Compliance | Agents |
|------|-------|----------|-----------|------|------------|--------|
| arco-rooms.jsonl | 50 | Pipeline | non-technical | PII + financial | GDPR | 3 (Invoice Collector, Payment Matcher, Report Sender) |
| ecommerce-support.jsonl | 50 | Hierarchy | technical-basics | PII + financial | GDPR + PCI | 4 (Support Coordinator, Order Tracker, Refund Processor, Escalation Handler) |
| freelance-pipeline.jsonl | 50 | Pipeline | developer | PII + financial | GDPR | 4 (Lead Capture, Proposal Generator, Invoice Manager, Follow-Up Agent) |

### JSONL Format

Each line is one of three types:

- **User turn:** `{"role": "user", "content": "...", "phase": N, "gate": "pending|approved", "metadata": {...}}`
- **Assistant turn:** `{"role": "assistant", "content": "...", "phase": N, "gate": "pending|approved"}`
- **Assertion:** `{"role": "assertion", "pattern": "regex", "context": "what is validated"}`

Gate transitions include `"metadata": {"gate_transition": true}` for phase boundary detection.

### Structural Assertions Per Phase

Each scenario contains assertions validating:
- Phase 1: State bar format, data classification (PII/financial/GDPR), tech level detection
- Phase 2: Topology type, agent table headers, blast radius levels, ASCII diagram
- Phase 3: Integration table (Service/Method/Trust), trust scores
- Phase 4: Agent card names, dry run processed count, blast radius in cards
- Phase 5: .agentbloc/ artifact tree, topology in config, governance.yaml reference
- Phase 6: Evolution scan items, patch proposal format, human approval requirement

## Commits

| Task | Commit | Description |
|------|--------|-------------|
| 1 | 4021ba1 | Create arco-rooms.jsonl test scenario |
| 2 | 25e2bad | Create ecommerce-support and freelance-pipeline test scenarios |

## Decisions Made

1. **Phase/gate on every turn:** Every user and assistant turn includes `phase` and `gate` fields, even mid-phase. This makes scenarios self-documenting and simplifies test runner validation (no need to track state across lines).

2. **Structural assertions only:** Assertion patterns match structural elements (table headers, state bars, topology keywords, diagram patterns) rather than specific prose. This prevents brittle tests that break when conversation content changes.

3. **50 turns per scenario:** Targets the minimum of the 50-100 range. Each scenario covers all 6 phases with meaningful turns at each decision point. Keeping scenarios concise improves maintainability while ensuring coverage.

## Deviations from Plan

None. Plan executed exactly as written.

## Verification Results

```
Line counts:     50 + 50 + 50 = 150 total
JSON validity:   All 150 lines parse with jq
Phase coverage:  All 3 files cover phases 1-6
Assertions:      18 + 20 + 20 = 58 total
Gate transitions: 6 + 6 + 6 = 18 total (one per phase per scenario)
```

## Self-Check: PASSED

- [x] tests/scenarios/arco-rooms.jsonl exists
- [x] tests/scenarios/ecommerce-support.jsonl exists
- [x] tests/scenarios/freelance-pipeline.jsonl exists
- [x] Commit 4021ba1 exists
- [x] Commit 25e2bad exists
- [x] 07-01-SUMMARY.md exists
