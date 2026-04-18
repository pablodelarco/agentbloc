# Phase 7: Testing and CI - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.

**Date:** 2026-04-16
**Phase:** 07-testing-and-ci
**Mode:** --auto
**Areas discussed:** JSONL format, Test scenarios, Test runner, CI pipeline

---

## JSONL Scenario Format

| Option | Description | Selected |
|--------|-------------|----------|
| Minimal JSONL (role/content/phase/gate) | Static structural validation | Yes |
| Full conversation replay format | Live Claude interaction testing | |

**User's choice:** [auto] Minimal JSONL with assertion lines (v1.0 validates structure, v2.0 adds live replay)

---

## Test Runner

| Option | Description | Selected |
|--------|-------------|----------|
| Shell-based (bash) | No dependencies, TAP output | Yes |
| Node.js script | Richer assertion library | |
| Python pytest | Full test framework | |

**User's choice:** [auto] Shell-based (zero dependencies, CI-friendly)

---

## CI Pipeline

| Option | Description | Selected |
|--------|-------------|----------|
| 4-job parallel (lint + yaml + test + links) | Fast, comprehensive | Yes |
| Single sequential job | Simpler but slower | |

**User's choice:** [auto] 4-job parallel GitHub Actions

---

## Claude's Discretion

- Assertion pattern specifics
- TAP output formatting
- markdownlint rule customization
- package.json inclusion
