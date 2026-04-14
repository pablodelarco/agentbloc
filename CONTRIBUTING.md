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

The test harness is under development (Phase 7). For now, contributors should verify that:

1. SKILL.md parses correctly as YAML frontmatter + markdown body.
2. All reference file links in SKILL.md resolve to existing files.
3. Modified phase protocols maintain the expected section structure.

Once available, run the full test suite with:

```bash
npm run test:agentbloc
```

## Code of Conduct

This project follows the [Contributor Covenant 2.1](https://www.contributor-covenant.org/version/2/1/code_of_conduct/). By participating, you agree to uphold a welcoming, inclusive, and respectful environment.

## Questions?

If something is unclear about contributing, open an issue. We would rather answer a question than fix a misunderstanding.
