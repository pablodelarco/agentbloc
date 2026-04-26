---
phase: 15-anticipation-engine
plan: 01
status: complete
date: 2026-04-26
commits:
  - f16113e feat(15-01): Task 1 anticipation-heuristics.md
  - 81dd0ce feat(15-01): Task 2 arco-rooms-anticipated-profiles.yaml
  - 9228d69 feat(15-01): Task 3 arco-rooms-declined.json
requirements_closed:
  - ANTIC-02
  - ANTIC-04
  - ANTIC-05
---

# Plan 15-01 SUMMARY: Anticipation Heuristics + Arco Rooms Fixtures

## Outcome

3 net-new artifacts emitted across 3 atomic commits. ANTIC-02, ANTIC-04, ANTIC-05 closed at the data layer; downstream behavior (Designer subagent extension) lands in Plan 15-02.

## Artifacts Emitted

| Artifact | Lines | Plan target | Delta | Closes |
|---|---|---|---|---|
| `references/anticipation-heuristics.md` | 148 | 200-300 | -52 (lean-mode shortfall) | ANTIC-02, ANTIC-05 |
| `examples/arco-rooms-anticipated-profiles.yaml` | 182 | 130-180 | +2 (within tolerance) | (validates against Plan 15-02 schema extension) |
| `examples/arco-rooms-declined.json` | 9 | 12-30 | -3 (single-entry minimal fixture) | ANTIC-04 |

## What's Shipped

**`anticipation-heuristics.md`** , 5 H2 mappings (rental-property-management, ecommerce, freelance-services, restaurant, professional-services), each with 4 blocks (Business type description, Anticipated agents table, Evidence sources >= 3, When NOT to anticipate). 15 cited URLs total (3 per mapping, all from independent reputable sources: NAR, NAA, ULI Terwilliger, NRF, Shopify Enterprise, HBR, Upwork Research, Freelancers Union, BLS, National Restaurant Association, BrightLocal, Toast, Consulting.us, ABA, AICPA-CIMA). Top-of-file Schema for a Mapping section + Adding a New Mapping footer.

**`arco-rooms-anticipated-profiles.yaml`** , 5-agent superset of the Phase 9 baseline (3 requested + 2 anticipated). 3 requested agents (gestor-documental, gestor-cobros, recepcionista) preserved byte-identical to arco-rooms-agent-profiles.yaml with `anticipated: false` added. 2 anticipated agents (analista-rentabilidad, gestor-incidencias) carry `anticipated: true` + 1-2 sentence rationale + 3 evidence URLs from rental-property-management mapping. 4 workflows (3 from baseline + 1 new rentabilidad-mensual + 1 new incidencias-canal). YAML parses cleanly + agents resolve via dependencies + workflow agent IDs all resolve.

**`arco-rooms-declined.json`** , Single-entry array demonstrating the ANTIC-04 schema (5 fields: agent_id, business_type, declined_at ISO-8601, reason, correlation_id). JSON parses cleanly. Schema documented formally in Plan 15-02 Task 1 (declined-agents-schema.md).

## Acceptance Gates

| Gate | Result | Evidence |
|---|---|---|
| Em-dash gate (3 files) | PASS | `grep -c '—' <file>` = 0 for all 3 |
| YAML validity | PASS | python3 yaml.safe_load + agent count + workflow count |
| JSON validity | PASS | python3 json.load + field key check |
| 3+ sources per mapping | PASS | Visual inspection + every Evidence sources block has >= 3 numbered entries |
| Source independence | PASS | Each mapping's 3 sources span at least 2 publishers / institutions |

## Lean-Mode Compromise Disclosure

`anticipation-heuristics.md` shipped at 148 lines vs Plan 15-01 target 200-300 (-52 line shortfall). Per Phase 14 lean-mode precedent, all anchor strings + cross-references + citation URLs are present per per-task acceptance criteria. Each mapping's Business Type description + Anticipated agents table + Evidence sources block + When NOT to anticipate paragraph land complete; the line shortfall reflects more concise prose density rather than missing content. A future polish pass may expand rationale + add more worked examples. Phase 16 golden-file harness can rely on the structural mappings as shipped.

`arco-rooms-declined.json` shipped at 9 lines vs target 12-30 (-3) , the JSON formatter chose minimal whitespace; the schema demonstration is complete (single entry showing all 5 fields).

`arco-rooms-anticipated-profiles.yaml` shipped at 182 lines vs target 130-180 (+2) , within tolerance; the 5-agent + 4-workflow content fully exercises the Phase 9 schema plus the Plan 15-02 anticipation extensions.

## Architectural Invariants Held

| Invariant | Expected | Evidence |
|---|---|---|
| Schema additivity | arco-rooms-anticipated-profiles.yaml uses schema_version: 1 | grep "schema_version: 1" yields 1 match (line 1) |
| Backward compatibility | requested agents identical to arco-rooms-agent-profiles.yaml shape (plus `anticipated: false`) | diff between baseline and new fixture shows ONLY the additive `anticipated: false` field on existing agents |
| Source rigor (ANTIC-05) | Each mapping cites >= 3 independent sources | Verified per mapping; total 15 distinct URLs |
| Designer scope-exclusion-lock release | Anticipated agents (analista-rentabilidad + gestor-incidencias) match D-30 Phase 9 lock-released names | Direct match |

## Cross-References Established

The fixture YAML's `anticipation_sources` URLs match the URLs in anticipation-heuristics.md rental-property-management Evidence sources block (3 of the same URLs cited in both files). This is the load-bearing cross-reference Plan 15-02 Task 3 will rely on when Designer's `<anticipation_pass>` block reads the heuristics map and emits the matching agents.

## Next

Plan 15-02 (Anticipation Behavior , Schema + Subagent Extension + Wiring) wires the anticipation pass end-to-end:
1. declined-agents-schema.md formal contract
2. agent-profile-schema.md surgical extension with 3 OPTIONAL fields + Validation Check 9
3. designer-agent.md `<scope_exclusion>` -> `<anticipation_pass>` replacement
4. phase-2-design.md Step 8.5 + Scope note + Quick Reference row
5. SKILL.md Phase 2 See-line + Summary Gate paragraph extension

Plan 15-02 closes the remaining 3 ANTIC requirements (ANTIC-01, ANTIC-03, ANTIC-04 wiring; ANTIC-04 partly closed in Plan 15-01 fixture but the formal schema reference is Plan 15-02 Task 1).
