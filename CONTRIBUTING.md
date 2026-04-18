# Contributing to AgentBloc

Thanks for your interest in contributing to AgentBloc. This guide covers how to get started, what to keep in mind when working on the skill, and how to submit changes.

## How to Contribute

1. **Fork** the repository on GitHub.
2. **Create a branch** from `main` for your changes (`git checkout -b feature/your-change`).
3. **Make your changes** following the guidelines below.
4. **Test your changes** by installing the modified skill locally (see Quick Start in README.md).
5. **Submit a pull request** against `main` with a clear description of what you changed and why.

For bug reports and feature requests, open a GitHub issue with as much detail as possible.

## Skill Development Guidelines

AgentBloc is a Claude Code skill. The entire codebase is markdown files. When contributing, keep these rules in mind:

- **SKILL.md must stay under 250 lines.** This is the lean hub that Claude Code reads first. If you need to add content, put it in a reference file.
- **Reference files live in `references/` and are one level deep.** Claude Code loads them on demand. Do not nest references inside references.
- **Examples live in `examples/`.** Each example demonstrates a full 6-phase walkthrough.
- **Do not add runtime dependencies.** AgentBloc is pure markdown. No TypeScript, no Python, no npm packages in v1.0.
- **Generated artifacts (YAML, JSON) stay in English.** Conversation and explanations adapt to the user's language, but config files are always English for consistency.

When modifying phase protocols (`references/phase-*.md`), test your changes against all six phases to ensure nothing breaks the conversational flow.

## Testing

Run the test suite locally with:

```bash
bash tests/run-tests.sh
```

This produces TAP (Test Anything Protocol) output and exits 0 on success. No `package.json` or npm dependency is required.

The runner validates:

1. All JSONL scenarios in `tests/scenarios/` are syntactically valid.
2. Every required field (`role`, `content`, `phase`, `gate`) is present on each turn.
3. Phase transitions are sequential across each scenario.
4. Assertion patterns match preceding assistant turns.
5. Every reference file linked from SKILL.md resolves to an existing file.

CI runs the same script on every push and pull request via `.github/workflows/ci.yml`.

## Code of Conduct

This project follows the [Contributor Covenant 2.1](https://www.contributor-covenant.org/version/2/1/code_of_conduct/). By participating, you agree to uphold a welcoming, inclusive, and respectful environment.

## Questions?

If something is unclear about contributing, open an issue. We would rather answer a question than fix a misunderstanding.
