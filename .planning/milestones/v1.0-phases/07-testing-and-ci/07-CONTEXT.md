# Phase 7: Testing and CI - Context

**Gathered:** 2026-04-16
**Status:** Ready for planning

<domain>
## Phase Boundary

Create the testing infrastructure and CI pipeline for AgentBloc: a replayable JSONL scenario format, three canonical test scenarios (one per example walkthrough), a test runner script, and a GitHub Actions CI pipeline with markdown lint, YAML validation, test scenario execution, and link-rot checks. This is the final phase: it validates everything built in Phases 1-6 and ensures ongoing quality.

</domain>

<decisions>
## Implementation Decisions

### JSONL Scenario Format (TEST-01)
- **D-01:** Each line in a scenario file is a JSON object with fields: `role` ("user" or "assistant"), `content` (the message text), `phase` (1-6), `gate` ("pending"/"approved"/"blocked"), and optional `metadata` (tech_level, data_classes_detected, topology_selected, etc.). This is the minimum viable format for replaying an AgentBloc conversation.
- **D-02:** Scenario files live in `tests/scenarios/` directory. Each file is named `{example-slug}.jsonl` (e.g., `arco-rooms.jsonl`, `ecommerce-support.jsonl`, `freelance-pipeline.jsonl`).
- **D-03:** Scenarios contain key decision points at each phase gate, not full verbatim transcripts. Target 50-100 turns per scenario. Each turn that crosses a phase boundary includes the gate transition metadata.

### Test Scenarios (TEST-02)
- **D-04:** Three canonical scenarios, one per example walkthrough from Phase 6:
  1. `arco-rooms.jsonl`: Pipeline topology, non-technical user, PII + financial data, GDPR activated, 3 agents
  2. `ecommerce-support.jsonl`: Hierarchy topology, technical-basics user, PII + financial data, GDPR + PCI activated, 5 agents
  3. `freelance-pipeline.jsonl`: Pipeline topology, developer user, PII data only, GDPR activated, 3 agents
- **D-05:** Each scenario includes artifact snapshot assertions: at specific turns, the test runner checks that expected output patterns appear (e.g., after Phase 2 gate approval, the assistant response must contain a topology diagram and agent summary table).
- **D-06:** Assertions are embedded in the JSONL as special assertion lines with `role: "assertion"` containing `pattern` (regex) and `context` (what's being validated).

### Test Runner (TEST-03)
- **D-07:** Shell-based test runner (bash script at `tests/run-tests.sh`). No npm/node dependency for the runner itself. The runner reads each .jsonl scenario, validates structural integrity (valid JSON per line, required fields present, phase transitions are sequential), and checks assertion patterns against preceding assistant turns.
- **D-08:** The runner outputs TAP (Test Anything Protocol) format for CI compatibility. Exit code 0 on all pass, exit code 1 on any failure.
- **D-09:** The runner also validates that all reference files mentioned in SKILL.md actually exist (link-rot prevention within the skill itself).

### CI Pipeline (REPO-09)
- **D-10:** GitHub Actions workflow at `.github/workflows/ci.yml` with 4 jobs running in parallel:
  1. `lint-markdown`: markdownlint-cli2 on all .md files (SKILL.md, references/, examples/, README, etc.)
  2. `validate-yaml`: yamllint on all .yaml files that would be generated (.agentbloc/ templates in deployment protocol)
  3. `test-scenarios`: run `tests/run-tests.sh` to validate all 3 scenarios
  4. `check-links`: lychee link checker on all .md files to catch broken URLs and cross-references
- **D-11:** CI runs on push to main and on pull requests. Badge in README shows CI status.
- **D-12:** Markdownlint config (`.markdownlintrc`) allows long lines (skill files are dense), allows HTML in markdown (badges), and disables rules that conflict with the established reference file structure.

### Claude's Discretion
- Exact assertion patterns per scenario (as long as key phase outputs are validated)
- TAP output formatting details
- markdownlint rule customization beyond the basics
- Whether to include a `package.json` with a `test` script or keep it purely shell-based

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Files to Create
- `tests/scenarios/arco-rooms.jsonl` : Test scenario for Arco Rooms walkthrough
- `tests/scenarios/ecommerce-support.jsonl` : Test scenario for ecommerce walkthrough
- `tests/scenarios/freelance-pipeline.jsonl` : Test scenario for freelance walkthrough
- `tests/run-tests.sh` : Test runner script
- `.github/workflows/ci.yml` : GitHub Actions CI pipeline
- `.markdownlintrc` : Markdownlint configuration

### Source Material for Scenarios
- `examples/arco-rooms.md` : Arco Rooms walkthrough (scenario source)
- `examples/ecommerce-support.md` : Ecommerce walkthrough (scenario source)
- `examples/freelance-pipeline.md` : Freelance walkthrough (scenario source)

### Reference Protocols (scenarios must be consistent with)
- `references/phase-1-interview.md` : Interview protocol (scenario interviews must follow)
- `references/phase-2-design.md` : Design protocol (scenario designs must follow)
- `references/phase-3-integration.md` : Integration protocol
- `references/phase-4-confirmation.md` : Confirmation + dry run protocol
- `references/phase-5-deployment.md` : Deployment protocol
- `references/phase-6-evolution.md` : Evolution protocol

### Existing Skill Hub
- `SKILL.md` : Hub file (CI validates all references exist)
- `README.md` : Badge location for CI status

### Requirements
- `.planning/REQUIREMENTS.md` : TEST-01..03, REPO-09 acceptance criteria
- `.planning/ROADMAP.md` : Phase 7 success criteria (4 items)

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- `examples/arco-rooms.md` (200 lines) : Complete walkthrough with all 6 phases demonstrated
- `examples/ecommerce-support.md` (227 lines) : Complete walkthrough with hierarchy topology
- `examples/freelance-pipeline.md` (222 lines) : Complete walkthrough with developer persona
- No existing test infrastructure (this is the first testing phase)

### Established Patterns
- All reference files follow consistent structure (ToC, When This Applies, sections, Quick Reference)
- SKILL.md references all files via explicit paths
- Examples follow the same 7-section structure (Business Context through Evolution Notes)

### Integration Points
- README.md needs CI badge added after workflow is created
- SKILL.md cross-references are the primary link-rot check targets
- The test runner validates the structural integrity of the JSONL format, not the AI's conversational quality

</code_context>

<specifics>
## Specific Ideas

- The JSONL format should be designed for future extensibility: v2 could add a test harness that actually feeds user turns to Claude and compares assistant responses. v1 validates structure and assertions statically.
- The markdownlint config needs to be permissive enough for the existing reference files (which use HTML comments, long lines, and complex table formatting) while still catching real issues.
- The CI pipeline should be fast (< 2 minutes) since there's no build step: just lint + validate + check.

</specifics>

<deferred>
## Deferred Ideas

- Live replay testing (actually feeding scenarios to Claude and comparing output): v2.0 feature, requires token budget and deterministic output handling
- Performance benchmarking (measuring activation rate, response quality): requires methodology definition noted in STATE.md blockers
- Visual regression testing for generated Mermaid diagrams: out of scope for v1.0

</deferred>

---

*Phase: 07-testing-and-ci*
*Context gathered: 2026-04-16*
