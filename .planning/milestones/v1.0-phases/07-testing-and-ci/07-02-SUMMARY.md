---
phase: 07-testing-and-ci
plan: 02
subsystem: testing-infrastructure
tags: [test-runner, ci, tap, linting, github-actions]
dependency_graph:
  requires: [07-01]
  provides: [test-runner, ci-pipeline, linting-configs]
  affects: [README.md]
tech_stack:
  added: [TAP v13, markdownlint-cli2, yamllint, lychee, GitHub Actions]
  patterns: [modular-bash-validation, parallel-ci-jobs]
key_files:
  created:
    - tests/run-tests.sh
    - .github/workflows/ci.yml
    - .markdownlint.jsonc
    - .yamllint.yml
    - .lycheeignore
  modified:
    - README.md
decisions:
  - Used grep -qE (extended regex) for portability across macOS and Linux
  - TAP plan line emitted at end for dynamic test count
  - No package.json added; test runner is pure bash + jq
  - Used agentbloc/agentbloc as GitHub org/repo placeholder for CI badge (no remote configured)
  - JSONC format for markdownlint config to allow inline comments explaining rule choices
metrics:
  duration: 148s
  completed: "2026-04-18T13:42:04Z"
  tasks: 2
  files_created: 5
  files_modified: 1
  test_points: 77
---

# Phase 07 Plan 02: Test Runner and CI Pipeline Summary

TAP-producing bash test runner validating 3 JSONL scenarios across 5 categories (JSON structure, required fields, phase sequence, assertion matching, SKILL.md references) plus GitHub Actions CI pipeline with 4 parallel jobs and linting configurations.

## What Was Done

### Task 1: Create test runner with TAP output
**Commit:** ad53348

Created `tests/run-tests.sh`, a self-contained bash + jq test runner that produces TAP version 13 output. The runner validates all `.jsonl` files in `tests/scenarios/` across five categories:

1. **JSON structure** -- every line must parse as valid JSON via jq
2. **Required fields** -- user/assistant turns need role, content, phase, gate; assertion lines need role, pattern, context
3. **Phase sequence** -- phases must appear in non-decreasing order (1 through 6), all six phases present
4. **Assertion matching** -- each assertion's regex pattern tested against the preceding assistant turn's content using grep -qE
5. **SKILL.md references** -- all `references/*.md` and `examples/*.md` paths found in SKILL.md checked for existence on disk

The runner produces 77 test points across the three scenario files and 10 SKILL.md reference checks. All pass with exit code 0.

### Task 2: Create CI pipeline, linting configs, and add badge to README
**Commit:** 403d2c5

Created five files and updated README:

- **`.github/workflows/ci.yml`** -- 4 parallel jobs (lint-markdown, validate-yaml, test-scenarios, check-links) triggered on push to main and pull requests. No job dependencies between them.
- **`.markdownlint.jsonc`** -- Permissive config: MD013 (line length) disabled for dense tables, MD033 (inline HTML) disabled for badges, MD024 siblings_only for duplicate headings, MD041 disabled for YAML frontmatter.
- **`.yamllint.yml`** -- Default rules with 200-char line length, truthy check-keys disabled, document-start disabled. Handles gracefully when no standalone YAML files exist.
- **`.lycheeignore`** -- Ignores shields.io badges, private service dashboards (Stripe, Shopify), and .planning artifacts.
- **`README.md`** -- CI status badge added to the existing badge row.

## Deviations from Plan

None -- plan executed exactly as written.

## Decisions Made

1. **grep -qE over grep -qP**: Used extended regex (-E) instead of Perl regex (-P) for portability. Both macOS and GitHub Actions ubuntu-latest support -E reliably.
2. **TAP plan at end**: Emitting `1..N` after all tests complete allows dynamic counting without pre-computing the total.
3. **No package.json**: Keeping the project as pure markdown + bash. No npm dependency for the test runner.
4. **Badge placeholder URL**: Used `agentbloc/agentbloc` as the GitHub org/repo since no git remote is configured. User should update when the remote is set.
5. **set -uo pipefail (not -e)**: Omitted `set -e` to prevent individual jq/grep failures from killing the script. Validation functions handle errors internally.

## Verification Results

| Check | Result |
|-------|--------|
| `bash tests/run-tests.sh` exits 0 | PASS (77/77 tests) |
| CI config has 4 `runs-on` lines | PASS (4) |
| No `needs:` dependencies between jobs | PASS |
| `.markdownlint.jsonc` has MD013: false | PASS |
| README contains `ci.yml/badge.svg` | PASS |

## Self-Check: PASSED
