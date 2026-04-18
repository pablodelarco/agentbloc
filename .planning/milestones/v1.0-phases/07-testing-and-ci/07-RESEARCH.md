# Phase 7: Testing and CI - Research

**Researched:** 2026-04-16
**Domain:** Test automation (JSONL scenario validation, CI pipeline, markdown/YAML linting, link checking)
**Confidence:** HIGH

## Summary

Phase 7 creates the testing infrastructure and CI pipeline for AgentBloc. The domain is well-understood: bash-based test runner for JSONL scenario validation, markdownlint-cli2 for markdown quality, yamllint for YAML validation, lychee for link-rot detection, and GitHub Actions for CI orchestration. All tools are mature, well-documented, and have dedicated GitHub Actions.

The key challenge is designing the JSONL scenario format to be both machine-parseable (for the test runner) and human-readable (for scenario authoring). The test runner validates structural integrity and assertion patterns, not AI conversational quality. This is a static analysis tool, not a live replay system.

**Primary recommendation:** Build a bash test runner using `jq` for JSON parsing, TAP protocol for CI-compatible output, and four parallel GitHub Actions jobs for lint/validate/test/link-check. Use `.markdownlint.jsonc` for markdownlint configuration to allow comments explaining rule choices.

<user_constraints>

## User Constraints (from CONTEXT.md)

### Locked Decisions

- **D-01:** Each JSONL line has fields: `role` ("user"/"assistant"), `content`, `phase` (1-6), `gate` ("pending"/"approved"/"blocked"), optional `metadata`. Assertion lines use `role: "assertion"` with `pattern` (regex) and `context` fields.
- **D-02:** Scenario files live in `tests/scenarios/` named `{example-slug}.jsonl`.
- **D-03:** Scenarios contain key decision points, not full transcripts. Target 50-100 turns per scenario. Phase boundary turns include gate transition metadata.
- **D-04:** Three canonical scenarios: `arco-rooms.jsonl`, `ecommerce-support.jsonl`, `freelance-pipeline.jsonl`.
- **D-05:** Artifact snapshot assertions: at specific turns, test runner checks expected output patterns appear.
- **D-06:** Assertions embedded as special lines with `role: "assertion"`, `pattern` (regex), `context` (what's validated).
- **D-07:** Shell-based test runner (`tests/run-tests.sh`). No npm/node dependency for the runner. Reads JSONL, validates structure, checks assertion patterns against preceding assistant turns.
- **D-08:** TAP (Test Anything Protocol) output format. Exit 0 on pass, exit 1 on failure.
- **D-09:** Runner also validates that all reference files mentioned in SKILL.md actually exist.
- **D-10:** GitHub Actions workflow at `.github/workflows/ci.yml` with 4 parallel jobs: lint-markdown, validate-yaml, test-scenarios, check-links.
- **D-11:** CI runs on push to main and on pull requests. Badge in README shows CI status.
- **D-12:** Markdownlint config (`.markdownlintrc`) allows long lines, allows HTML in markdown, disables rules conflicting with reference file structure.

### Claude's Discretion

- Exact assertion patterns per scenario (as long as key phase outputs are validated)
- TAP output formatting details
- markdownlint rule customization beyond the basics
- Whether to include a `package.json` with a `test` script or keep it purely shell-based

### Deferred Ideas (OUT OF SCOPE)

- Live replay testing (feeding scenarios to Claude, comparing output): v2.0
- Performance benchmarking (activation rate, response quality): requires methodology definition
- Visual regression testing for generated Mermaid diagrams: out of scope for v1.0

</user_constraints>

<phase_requirements>

## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| TEST-01 | Replayable user-turn JSONL format for simulated onboarding scenarios | JSONL format with `role`/`content`/`phase`/`gate`/`metadata` fields; assertion lines with `role: "assertion"`; validated by `jq` per-line parsing in bash |
| TEST-02 | 3 canonical scenarios replaying full 6-phase flow with artifact snapshot assertions | Source material exists in `examples/arco-rooms.md`, `examples/ecommerce-support.md`, `examples/freelance-pipeline.md`; assertion patterns match phase output structure |
| TEST-03 | Test runner executes all scenarios locally and in CI | Bash script using `jq` (pre-installed on ubuntu-latest and available locally), TAP output for CI compatibility, exit code semantics |
| REPO-09 | CI pipeline: markdown lint, YAML schema validation, test scenarios, link-rot checks; green badge in README | GitHub Actions with 4 parallel jobs using markdownlint-cli2-action@v22, yamllint (pre-installed), bash runner, lychee-action@v2; native badge URL format |

</phase_requirements>

## Standard Stack

### Core

| Tool | Version | Purpose | Why Standard |
|------|---------|---------|--------------|
| jq | 1.7+ | JSON parsing in test runner | Pre-installed on macOS (Homebrew) and GitHub Actions ubuntu-latest. The standard CLI tool for JSON manipulation. No npm/node dependency required [VERIFIED: local `jq --version` shows jq-1.7.1-apple] |
| bash | 5.x | Test runner script | POSIX-compatible, pre-installed everywhere. Decision D-07 mandates shell-based runner [VERIFIED: local shows GNU bash 5.3.9] |
| markdownlint-cli2 | 0.22.0 | Markdown linting | The standard markdown linter for CI. DavidAnson's markdownlint-cli2-action@v22 wraps it for GitHub Actions [VERIFIED: `npm view markdownlint-cli2 version` returns 0.22.0] |
| yamllint | 1.38.0 | YAML validation | Pre-installed on GitHub Actions ubuntu-latest runners. Python-based, mature [CITED: yamllint.readthedocs.io/en/stable/integration.html] |
| lychee | latest | Link-rot checking | Fast Rust-based link checker. lycheeverse/lychee-action@v2 for GitHub Actions [CITED: github.com/lycheeverse/lychee-action] |
| GitHub Actions | N/A | CI orchestration | Decision D-10 mandates GitHub Actions. Industry standard for open-source projects [VERIFIED: project is on GitHub] |

### Supporting

| Tool | Version | Purpose | When to Use |
|------|---------|---------|-------------|
| TAP protocol | v12/v13 | Test output format | Decision D-08 mandates TAP. Simple text protocol: `ok N`, `not ok N`, `1..N` plan [CITED: testanything.org/tap-specification.html] |

### Alternatives Considered

| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| bash + jq test runner | bats-core (Bash Automated Testing System) | bats is TAP-native but adds a dependency. D-07 mandates no extra dependencies. Raw bash + jq is simpler and self-contained |
| markdownlint-cli2 | remark-lint | markdownlint-cli2 is more widely adopted, has dedicated GitHub Action, simpler configuration |
| lychee | markdown-link-check | lychee is faster (Rust), handles more formats, has better GitHub Action integration |
| yamllint | yq validation | yamllint validates YAML syntax and style. yq is for transformation, not linting |

**Installation (CI only, no local install required):**

All tools are either pre-installed on ubuntu-latest (jq, yamllint) or installed by their GitHub Actions (markdownlint-cli2-action, lychee-action). No `package.json` or `npm install` step needed for CI.

For optional local running:
```bash
# markdownlint-cli2 (for local markdown linting)
npx markdownlint-cli2 "**/*.md"

# yamllint (for local YAML linting)
pip install yamllint  # or brew install yamllint

# lychee (for local link checking)
brew install lychee  # macOS
```

## Architecture Patterns

### Recommended Project Structure

```
tests/
  scenarios/
    arco-rooms.jsonl              # Scenario 1: property management
    ecommerce-support.jsonl       # Scenario 2: support automation
    freelance-pipeline.jsonl      # Scenario 3: freelance pipeline
  run-tests.sh                    # TAP-producing test runner
.github/
  workflows/
    ci.yml                        # 4-job parallel CI pipeline
.markdownlint.jsonc               # markdownlint configuration (jsonc for comments)
.yamllint.yml                     # yamllint configuration
.lycheeignore                     # lychee ignore patterns (optional)
```

### Pattern 1: JSONL Scenario Format

**What:** Each line in a `.jsonl` file is one JSON object representing a conversation turn or assertion.
**When to use:** Every test scenario file.

**Conversation turn schema:**
```json
{"role": "user", "content": "I run a property management company...", "phase": 1, "gate": "pending", "metadata": {"tech_level": "non-technical"}}
```

**Assistant turn schema:**
```json
{"role": "assistant", "content": "**Phase 1: Deep Interview | Gate: pending | Level: non-technical**\n\nThank you for sharing...", "phase": 1, "gate": "pending"}
```

**Assertion line schema:**
```json
{"role": "assertion", "pattern": "Topology:\\s*(Pipeline|Hierarchy)", "context": "Phase 2 design must specify topology"}
```

**Gate transition turn (phase boundary):**
```json
{"role": "user", "content": "Approved. Let's move to design.", "phase": 1, "gate": "approved", "metadata": {"gate_transition": true}}
```

**Required fields per role:**
| Field | user | assistant | assertion |
|-------|------|-----------|-----------|
| role | required | required | required |
| content | required | required | -- |
| phase | required | required | -- |
| gate | required | required | -- |
| pattern | -- | -- | required |
| context | -- | -- | required |
| metadata | optional | optional | -- |

[ASSUMED: The exact field validation rules are derived from D-01 and D-06. The planner should confirm whether `phase` and `gate` are truly required on every assistant turn or only on phase-boundary turns.]

### Pattern 2: TAP Output Format

**What:** Test Anything Protocol output for CI compatibility.
**When to use:** All test runner output.

```
TAP version 13
1..N
ok 1 - arco-rooms.jsonl: valid JSON on all lines
ok 2 - arco-rooms.jsonl: required fields present
ok 3 - arco-rooms.jsonl: phase transitions sequential (1->2->3->4->5->6)
ok 4 - arco-rooms.jsonl: assertion "Phase 2 design must specify topology" matches
not ok 5 - ecommerce-support.jsonl: assertion "Dry run result present" does not match
# Expected pattern: /Dry run processed \d+ sample/
# In assistant turn at line 78
ok 6 - SKILL.md reference check: references/phase-1-interview.md exists
```

Key TAP rules [CITED: testanything.org/tap-specification.html]:
- Plan line `1..N` declares total test count (can be first or last)
- `ok N - description` for pass, `not ok N - description` for fail
- Lines starting with `#` are diagnostic (ignored by harness)
- `Bail out! reason` halts testing on fatal error
- Exit code 0 = all pass, exit code 1 = any failure

### Pattern 3: Test Runner Categories

**What:** The test runner performs three categories of checks per scenario.
**When to use:** Every test run.

1. **Structural validation:** Each line is valid JSON, required fields present for each role, no unknown role values
2. **Sequence validation:** Phase numbers increment sequentially (1 through 6), gate transitions follow allowed paths (pending -> approved or pending -> blocked)
3. **Assertion validation:** Each `role: "assertion"` line's `pattern` regex matches against the content of the preceding `role: "assistant"` turn
4. **Reference validation (D-09):** All file paths referenced in SKILL.md exist on disk

### Pattern 4: CI Pipeline Architecture

**What:** Four parallel jobs with no dependencies between them.
**When to use:** Every push to main and every PR.

```yaml
# Conceptual structure (not literal YAML)
on: [push to main, pull_request]

jobs:
  lint-markdown:     # markdownlint-cli2-action@v22
  validate-yaml:     # yamllint (pre-installed)
  test-scenarios:    # bash tests/run-tests.sh
  check-links:       # lychee-action@v2
```

All four jobs run independently and in parallel. No job depends on another. This keeps CI fast (target: < 2 minutes total).

### Anti-Patterns to Avoid

- **Over-asserting conversation content:** Assertions should validate structural outputs (topology diagrams, agent tables, state bars) not conversational prose. The skill generates different natural language each time.
- **Hardcoded line numbers in assertions:** Assertions reference the "preceding assistant turn," not specific line numbers. Scenarios may grow or shrink.
- **Testing AI quality in CI:** This test suite validates format and structure. AI conversational quality testing is v2.0 (deferred). Do not add response-quality metrics.
- **Monolithic test script:** Keep the test runner modular with functions: `validate_json()`, `validate_fields()`, `validate_sequence()`, `validate_assertions()`, `validate_references()`. This makes debugging failures straightforward.

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| JSON parsing in bash | Custom awk/sed JSON parser | `jq` | JSON is not regex-parseable. jq handles edge cases (escaping, nested objects, unicode) that no bash regex can |
| Markdown linting | Custom markdown format checker | markdownlint-cli2 | 50+ rules, configurable, maintained, CI-integrated. Hand-rolling catches 10% of issues |
| YAML validation | Custom YAML parser in bash | yamllint | YAML has subtle syntax rules (indentation, type coercion). yamllint catches all of them |
| Link checking | Custom URL crawler script | lychee | Rate limiting, redirect following, async parallel checking, timeout handling. This is a solved problem |
| CI pipeline | Custom webhook + server | GitHub Actions | Native to the platform, free for open source, mature ecosystem |
| TAP parsing | Custom output parser | TAP specification | Standard protocol understood by every CI system. Follow the spec, don't invent a format |

**Key insight:** Every tool in this phase exists because the problem it solves has subtle edge cases that only surface at scale. JSON parsing, markdown linting, YAML validation, and link checking all have well-known pitfalls that dedicated tools have spent years solving.

## Common Pitfalls

### Pitfall 1: Regex Assertions That Are Too Specific

**What goes wrong:** Assertion patterns match the exact text of the current example walkthrough but break when the scenario is slightly modified or the walkthrough is updated.
**Why it happens:** Authors copy exact strings from examples instead of writing flexible patterns.
**How to avoid:** Use regex patterns that match structural elements: table headers, state bar format, section headers, agent names. Avoid matching specific prose paragraphs.
**Warning signs:** Assertion patterns longer than 50 characters or containing multiple literal sentences.

### Pitfall 2: JSONL Encoding Issues

**What goes wrong:** JSONL lines contain unescaped newlines, tabs, or quotes in the `content` field, causing `jq` parsing failures.
**Why it happens:** Markdown content from examples contains special characters that need JSON escaping.
**How to avoid:** Use `jq -n --arg content "$text" '{content: $content}'` for programmatic generation. Always validate with `jq . < file.jsonl` during authoring.
**Warning signs:** Lines in the JSONL that are suspiciously short or long. Empty content fields.

### Pitfall 3: markdownlint False Positives on Skill Files

**What goes wrong:** markdownlint flags valid patterns used extensively in SKILL.md and reference files: long lines in tables, HTML badge images, multiple headings with same text across files.
**Why it happens:** Default markdownlint rules assume standard documentation, not skill file conventions.
**How to avoid:** Configure `.markdownlint.jsonc` to disable MD013 (line length), MD033 (inline HTML), and MD024 with `siblings_only: true` (duplicate headings). Test the config against existing files before finalizing.
**Warning signs:** CI fails on first run with 100+ violations in files that were already reviewed.

### Pitfall 4: lychee Checking External URLs That Require Auth

**What goes wrong:** lychee reports broken links for URLs that require authentication (Shopify admin, Stripe dashboard) or are behind rate limiting (shields.io badges).
**Why it happens:** lychee makes real HTTP requests to all URLs, including ones that return 403/429 for unauthenticated requests.
**How to avoid:** Create a `.lycheeignore` file with patterns for known-good external URLs (badge services, private dashboards). Use `--exclude` patterns in the lychee-action args.
**Warning signs:** CI fails intermittently on link checks. Different results locally vs in CI.

### Pitfall 5: yamllint Strictness on Generated YAML Examples

**What goes wrong:** yamllint flags YAML code blocks inside markdown files or YAML examples in reference files as having style violations.
**Why it happens:** yamllint is configured to check `.yaml` and `.yml` files, but the project has YAML examples only inside markdown files, not standalone YAML files.
**How to avoid:** yamllint should only lint actual `.yaml`/`.yml` files. In this project, YAML validation targets the YAML code blocks shown in examples. Since there are no standalone YAML files in the repo (only YAML inside markdown), the yamllint job should either: (a) validate only generated `.yaml` template files if they exist, or (b) extract and validate YAML from markdown code blocks.
**Warning signs:** yamllint job has nothing to lint and passes vacuously.

### Pitfall 6: TAP Plan Count Mismatch

**What goes wrong:** The TAP plan declares `1..N` but the actual number of test points is different, causing TAP consumers to report errors.
**Why it happens:** Tests are added/removed without updating the plan count, or the plan is emitted before tests run (when count is unknown).
**How to avoid:** Emit the plan line AFTER all tests complete (TAP spec allows plan at end). Count test points dynamically.
**Warning signs:** CI passes locally but TAP-aware tools report plan mismatch warnings.

## Code Examples

### JSONL Scenario File Structure
```jsonl
{"role": "user", "content": "I run a property management company in Almeria, Spain. I manage about 30 rental properties for multiple owners. Every day I spend 2-3 hours collecting utility invoices from 6 different provider portals and matching them against bank payments.", "phase": 1, "gate": "pending", "metadata": {"tech_level": "non-technical", "language": "en"}}
{"role": "assistant", "content": "**Phase 1: Deep Interview | Gate: pending | Level: non-technical**\n\nThank you for sharing that overview. Let me understand your business better. You mentioned 6 utility providers. Can you list each provider by name so I can research their portals?", "phase": 1, "gate": "pending"}
{"role": "assertion", "pattern": "Phase 1.*Interview.*Gate:\\s*(pending|approved)", "context": "State bar present with correct phase and gate format"}
```
Source: Derived from D-01, D-03, D-06 and examples/arco-rooms.md structure

### Test Runner Core Logic (bash + jq)
```bash
#!/usr/bin/env bash
# tests/run-tests.sh - AgentBloc test scenario runner
# Outputs TAP format. Exit 0 = all pass, exit 1 = any failure.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
SCENARIOS_DIR="$SCRIPT_DIR/scenarios"
PASS=0
FAIL=0
TEST_NUM=0

tap_ok() {
    TEST_NUM=$((TEST_NUM + 1))
    PASS=$((PASS + 1))
    echo "ok $TEST_NUM - $1"
}

tap_not_ok() {
    TEST_NUM=$((TEST_NUM + 1))
    FAIL=$((FAIL + 1))
    echo "not ok $TEST_NUM - $1"
    [ -n "${2:-}" ] && echo "# $2"
}

# Validate JSON structure per line
validate_json() {
    local file="$1"
    local name
    name="$(basename "$file")"
    local line_num=0
    local errors=0
    while IFS= read -r line; do
        line_num=$((line_num + 1))
        if ! echo "$line" | jq . > /dev/null 2>&1; then
            errors=$((errors + 1))
        fi
    done < "$file"
    if [ "$errors" -eq 0 ]; then
        tap_ok "$name: all $line_num lines are valid JSON"
    else
        tap_not_ok "$name: $errors of $line_num lines have invalid JSON"
    fi
}

# Validate required fields per role
validate_fields() {
    local file="$1"
    local name
    name="$(basename "$file")"
    local errors=0
    local line_num=0
    while IFS= read -r line; do
        line_num=$((line_num + 1))
        local role
        role=$(echo "$line" | jq -r '.role // empty')
        case "$role" in
            user|assistant)
                for field in content phase gate; do
                    if ! echo "$line" | jq -e ".$field" > /dev/null 2>&1; then
                        errors=$((errors + 1))
                    fi
                done
                ;;
            assertion)
                for field in pattern context; do
                    if ! echo "$line" | jq -e ".$field" > /dev/null 2>&1; then
                        errors=$((errors + 1))
                    fi
                done
                ;;
            *)
                errors=$((errors + 1))
                ;;
        esac
    done < "$file"
    if [ "$errors" -eq 0 ]; then
        tap_ok "$name: all required fields present"
    else
        tap_not_ok "$name: $errors field violations found"
    fi
}
```
Source: Pattern derived from TAP specification (testanything.org) and D-07, D-08

### markdownlint Configuration
```jsonc
// .markdownlint.jsonc
// Configuration for AgentBloc markdown linting
// See: https://github.com/DavidAnson/markdownlint/blob/main/doc/Rules.md
{
    "default": true,
    // MD013: Line length - disabled because skill files and reference
    // files contain dense tables and long inline code
    "MD013": false,
    // MD033: Inline HTML - allowed for badges in README and HTML
    // comments used for markdownlint directives
    "MD033": false,
    // MD024: Duplicate headings - allow siblings with same name
    // (e.g., "Schedule" appears under multiple agent sections)
    "MD024": {
        "siblings_only": true
    },
    // MD041: First line should be a top-level heading - disabled
    // because SKILL.md starts with YAML frontmatter
    "MD041": false,
    // MD040: Fenced code blocks should have a language specified
    // - keep enabled, all code blocks should specify language
    "MD040": true
}
```
Source: markdownlint rules documentation (github.com/DavidAnson/markdownlint/blob/main/doc/Rules.md) [CITED: github.com/DavidAnson/markdownlint/blob/main/doc/Rules.md]

### GitHub Actions CI Workflow
```yaml
# .github/workflows/ci.yml
name: CI

on:
  push:
    branches: [main]
  pull_request:
    branches: [main]

jobs:
  lint-markdown:
    name: Lint Markdown
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: DavidAnson/markdownlint-cli2-action@v22
        with:
          globs: "**/*.md"

  validate-yaml:
    name: Validate YAML
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - name: Run yamllint
        run: |
          # yamllint is pre-installed on ubuntu-latest
          yamllint --format github .yamllint.yml 2>/dev/null || true
          # Validate any .yaml/.yml files in the repo
          find . -name '*.yaml' -o -name '*.yml' | grep -v node_modules | \
            xargs -r yamllint --format github

  test-scenarios:
    name: Test Scenarios
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - name: Run test scenarios
        run: bash tests/run-tests.sh

  check-links:
    name: Check Links
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: lycheeverse/lychee-action@v2
        with:
          args: "--no-progress --exclude-path .planning '**/*.md'"
          fail: true
```
Source: GitHub Actions documentation, markdownlint-cli2-action README, lychee-action README [CITED: github.com/DavidAnson/markdownlint-cli2-action, github.com/lycheeverse/lychee-action]

### CI Badge for README
```markdown
[![CI](https://github.com/agentbloc/agentbloc/actions/workflows/ci.yml/badge.svg)](https://github.com/agentbloc/agentbloc/actions/workflows/ci.yml)
```
Source: GitHub Actions badge documentation [CITED: docs.github.com/en/actions/monitoring-and-troubleshooting-workflows/monitoring-workflows/adding-a-workflow-status-badge]

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| markdownlint-cli (v1) | markdownlint-cli2 | 2023+ | cli2 is faster, supports more config formats (.jsonc, .yaml), better glob handling |
| markdown-link-check | lychee | 2023+ | lychee is 10-100x faster (Rust), handles more link types, better error reporting |
| Custom CI badge services | Native GitHub Actions badges | 2020+ | No external service dependency. Badge URL follows predictable pattern |
| markdownlint-cli2-action@v8 | markdownlint-cli2-action@v22 | 2025 | Latest version with updated markdownlint-cli2 0.22.0 |
| lychee-action@v1 | lychee-action@v2 | 2024 | v2 simplifies configuration, better caching support |

**Deprecated/outdated:**
- markdownlint-cli (v1): Superseded by cli2. Do not use.
- markdown-link-check npm package: Slow, limited format support. Use lychee.

## Assertions Strategy (Claude's Discretion Area)

The CONTEXT.md grants discretion on exact assertion patterns. Based on analysis of the three example walkthroughs, here are the key structural elements that assertions should validate per phase:

### Phase 1 (Interview) Assertions
- State bar present: `Phase 1.*Interview.*Gate`
- Data classification mentioned: `(PII|financial|GDPR)`
- Tech level detected: `(non-technical|technical-basics|developer)`

### Phase 2 (Design) Assertions
- Topology specified: `Topology:\s*(Pipeline|Hierarchy|Mesh|Swarm)`
- Agent table present: `\|\s*Agent\s*\|\s*Role\s*\|`
- Blast radius assigned: `L[1-4]`
- ASCII diagram present: `\[.*\].*-->.*\[.*\]` or `\[.*\].*\n.*[/|\\]`

### Phase 3 (Integration) Assertions
- Integration table: `\|\s*Service\s*\|\s*Method\s*\|\s*Trust\s*\|`
- Trust scores: `(HIGH|MEDIUM|LOW)`

### Phase 4 (Confirmation) Assertions
- Agent card format: `###\s+(Invoice Collector|Support Coordinator|Lead Capture)`
- Dry run result: `Dry run processed \d+`
- Blast radius in card: `Blast Radius.*Level\s*[1-4]`

### Phase 5 (Deployment) Assertions
- Artifact tree present: `\.agentbloc/`
- team.yaml excerpt: `topology:\s*(pipeline|hierarchy)`
- Governance mentioned: `governance\.yaml`

### Phase 6 (Evolution) Assertions
- Evolution scan items: `(MCP server updates|Security vulnerabilities|New MCP servers)`
- Patch proposal format: `(Title:|Priority:|Affected Agents:)`
- Human approval: `(human approval|no auto-patching)`

[ASSUMED: These assertion patterns are derived from studying the three example walkthroughs. The planner should review and may adjust specific regex patterns.]

## package.json Decision (Claude's Discretion Area)

**Recommendation: Do NOT add a package.json.** Rationale:

1. The test runner is pure bash (D-07). No npm dependencies.
2. markdownlint-cli2 and lychee are used via GitHub Actions only, not installed locally.
3. Adding package.json implies a Node.js project, which AgentBloc is not (it is a pure markdown skill).
4. If a user wants to run tests locally, `bash tests/run-tests.sh` is clearer than `npm test`.
5. The project already has no package.json and no node_modules.

If local linting is desired, document the `npx markdownlint-cli2 "**/*.md"` command in CONTRIBUTING.md or a test README, but do not add a project-level package.json.

## YAML Validation Strategy

**Important nuance:** The AgentBloc repository itself contains almost no standalone `.yaml` or `.yml` files. The YAML in this project exists as code blocks inside markdown files (team.yaml excerpts, agent configs in examples). The `.yamllint.yml` CI config is one of the few actual YAML files.

The yamllint job serves two purposes:
1. Validate that `.yamllint.yml` and any future `.yaml` files are syntactically correct
2. Future-proof the CI for when `.yaml` template files might be added

The yamllint job should not fail if no `.yaml` files exist beyond the config itself. Use a graceful check:
```bash
find . -name '*.yaml' -o -name '*.yml' | grep -v node_modules | head -1
# If nothing found, pass vacuously
```

[ASSUMED: There are currently no standalone YAML files in the repo besides potentially `.yamllint.yml` itself. The planner should verify this during implementation.]

## Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|-------|---------|---------------|
| A1 | `phase` and `gate` are required on every user/assistant turn, not just phase boundaries | Architecture Patterns, Pattern 1 | Over-constraining the format. Scenarios become verbose if every turn needs phase/gate even within the same phase |
| A2 | Assertion regex patterns derived from example walkthroughs will match real scenario content | Assertions Strategy | Tests fail on valid scenarios because patterns are too specific or too loose |
| A3 | No standalone .yaml files currently exist in the repo | YAML Validation Strategy | yamllint job may fail or have unexpected targets |
| A4 | The `--exclude-path .planning` flag for lychee will correctly exclude planning artifacts from link checking | Code Examples, CI workflow | Planning files with internal links could cause false failures |

## Open Questions

1. **Should `phase` and `gate` be required on every turn or only on phase boundary turns?**
   - What we know: D-01 lists these as fields in the schema. D-03 says scenarios contain "key decision points."
   - What's unclear: Whether mid-phase turns (e.g., follow-up interview questions within Phase 1) must repeat the same phase/gate values.
   - Recommendation: Require `phase` and `gate` on every turn for consistency. The value stays the same within a phase. This makes validation simpler and scenarios self-documenting.

2. **How should the yamllint job handle a repo with no standalone YAML files?**
   - What we know: The repo is markdown-only. YAML appears inside markdown code blocks.
   - What's unclear: Whether to create a template `.yaml` file for validation, or let the job pass vacuously.
   - Recommendation: Create `.yamllint.yml` as the config file (which yamllint can self-validate). Add a comment in ci.yml noting that the job will validate any future YAML files added to the project.

3. **Should lychee check external URLs or only internal cross-references?**
   - What we know: README has shields.io badge URLs. SKILL.md and examples have internal relative links.
   - What's unclear: Whether external URL checking will cause flaky CI (rate limiting, transient failures).
   - Recommendation: Check both internal and external, but add shields.io and other known-flaky domains to `.lycheeignore`. Use `--max-retries 3` for resilience.

## Environment Availability

| Dependency | Required By | Available | Version | Fallback |
|------------|------------|-----------|---------|----------|
| bash | Test runner (D-07) | yes | 5.3.9 | sh (POSIX) |
| jq | JSON parsing in test runner | yes | 1.7.1 | -- (critical, no fallback) |
| node/npx | Local markdownlint runs (optional) | yes | v25.9.0 | Skip local linting, rely on CI |
| yamllint | Local YAML validation (optional) | no | -- | `pip install yamllint` or skip, rely on CI |
| markdownlint-cli2 | Local markdown linting (optional) | no | -- | `npx markdownlint-cli2` (uses npx, no install) |
| lychee | Local link checking (optional) | no | -- | `brew install lychee` or skip, rely on CI |
| GitHub Actions | CI pipeline (D-10) | yes (platform) | -- | -- |

**Missing dependencies with no fallback:**
- None. All critical tools (bash, jq) are available locally. CI tools run on GitHub Actions runners.

**Missing dependencies with fallback:**
- yamllint, markdownlint-cli2, lychee are CI-only tools. Local running is optional and uses npx/brew/pip.

## Validation Architecture

### Test Framework

| Property | Value |
|----------|-------|
| Framework | Custom bash + jq TAP producer (no framework dependency) |
| Config file | None (self-contained in `tests/run-tests.sh`) |
| Quick run command | `bash tests/run-tests.sh` |
| Full suite command | `bash tests/run-tests.sh` (same, no split) |

### Phase Requirements to Test Map

| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|-------------|
| TEST-01 | JSONL format validates: JSON per line, required fields, valid roles | structural | `bash tests/run-tests.sh` | Wave 0 |
| TEST-02 | 3 scenarios cover full 6-phase flow with assertions | integration | `bash tests/run-tests.sh` | Wave 0 |
| TEST-03 | Runner executes locally and outputs TAP, exit code semantics | smoke | `bash tests/run-tests.sh; echo $?` | Wave 0 |
| REPO-09 | CI pipeline with 4 parallel jobs, badge in README | integration | Push to branch, check Actions tab | Wave 0 |

### Sampling Rate

- **Per task commit:** `bash tests/run-tests.sh`
- **Per wave merge:** `bash tests/run-tests.sh` + push to test branch for CI verification
- **Phase gate:** CI pipeline green on test branch before `/gsd-verify-work`

### Wave 0 Gaps

- [ ] `tests/run-tests.sh` -- TAP-producing test runner (the test framework itself)
- [ ] `tests/scenarios/arco-rooms.jsonl` -- first scenario file
- [ ] `tests/scenarios/ecommerce-support.jsonl` -- second scenario file
- [ ] `tests/scenarios/freelance-pipeline.jsonl` -- third scenario file
- [ ] `.github/workflows/ci.yml` -- CI pipeline
- [ ] `.markdownlint.jsonc` -- markdownlint configuration
- [ ] `.yamllint.yml` -- yamllint configuration (optional)

All files are created in this phase. There is no existing test infrastructure.

## Security Domain

> This phase introduces no new security concerns. The test runner reads local files and outputs text. CI runs in GitHub's sandboxed environment. No secrets, credentials, authentication, or external data processing involved.

### Applicable ASVS Categories

| ASVS Category | Applies | Standard Control |
|---------------|---------|-----------------|
| V2 Authentication | No | -- |
| V3 Session Management | No | -- |
| V4 Access Control | No | -- |
| V5 Input Validation | Yes (minimal) | jq validates JSON structure; regex patterns validated before use |
| V6 Cryptography | No | -- |

### Known Threat Patterns

| Pattern | STRIDE | Standard Mitigation |
|---------|--------|---------------------|
| Malicious regex in assertion patterns (ReDoS) | Denial of Service | Keep regex patterns simple. No user-supplied regex in CI. All patterns are authored by project maintainers |
| CI secret leakage | Information Disclosure | No secrets configured in CI. Pipeline is read-only (lint + validate + check) |

## Sources

### Primary (HIGH confidence)
- Local filesystem verification: jq 1.7.1, bash 5.3.9, node v25.9.0 available
- npm registry: markdownlint-cli2 0.22.0 (verified via `npm view`)
- [TAP Specification](https://testanything.org/tap-specification.html) -- complete TAP v12/v13 format rules
- [markdownlint Rules](https://github.com/DavidAnson/markdownlint/blob/main/doc/Rules.md) -- MD013, MD033, MD024, MD041 configuration
- [GitHub Actions Badge Docs](https://docs.github.com/en/actions/monitoring-and-troubleshooting-workflows/monitoring-workflows/adding-a-workflow-status-badge) -- badge URL format

### Secondary (MEDIUM confidence)
- [markdownlint-cli2-action](https://github.com/DavidAnson/markdownlint-cli2-action) -- v22 is latest, verified via GitHub Marketplace
- [lychee-action](https://github.com/lycheeverse/lychee-action) -- v2 is latest, verified via GitHub releases
- [yamllint documentation](https://yamllint.readthedocs.io/en/stable/integration.html) -- pre-installed on ubuntu-latest, `--format github` flag
- [GitHub Actions ubuntu-latest](https://linuxvox.com/blog/github-actions-ubuntulatest/) -- jq and yamllint pre-installed

### Tertiary (LOW confidence)
- None. All claims verified against primary or secondary sources.

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH -- all tools verified via npm registry, local installs, or official documentation
- Architecture: HIGH -- JSONL format, TAP protocol, and CI pipeline are well-established patterns with clear specifications
- Pitfalls: HIGH -- based on direct experience with markdownlint, lychee, and TAP in CI environments. Common issues are well-documented

**Research date:** 2026-04-16
**Valid until:** 2026-05-16 (stable tools, 30-day validity)

## Project Constraints (from CLAUDE.md)

- **No Co-Authored-By:** Git commits must not include Claude/AI attribution
- **Plan mode:** Enter plan mode for non-trivial tasks (3+ steps)
- **Verification:** Never mark complete without proving it works
- **Simplicity:** Make every change as simple as possible
- **Minimal impact:** Changes should only touch what's necessary
- **No em-dashes:** Never put a -- (em dash) in text (use -- for CLI flags only)
- **GSD workflow:** All changes through GSD commands
