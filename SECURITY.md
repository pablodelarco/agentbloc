# Security Policy

## Supported Versions

| Version | Supported          |
| ------- | ------------------ |
| 1.0.x   | :white_check_mark: |

## Reporting a Vulnerability

If you discover a security vulnerability in AgentBloc, please report it responsibly.

**Do NOT open a public GitHub issue for security vulnerabilities.**

<!-- TODO: Replace this placeholder email with the actual security contact email before public launch -->
Instead, email: security@agentbloc.dev

### What to Include

- Description of the vulnerability
- Steps to reproduce
- Potential impact
- Suggested fix (if any)

### Response Timeline

- **Acknowledgment:** Within 48 hours
- **Assessment:** Within 5 business days
- **Fix for critical issues:** Within 7 days
- **Fix for non-critical issues:** Within 30 days

### Disclosure Policy

We follow coordinated disclosure. We will work with you to understand and address the issue before any public disclosure. We ask that you give us reasonable time to release a fix before publishing details.

## Scope

AgentBloc is a Claude Code skill (markdown files). Security concerns most relevant to this project include:

- Credential handling patterns in generated deployment artifacts
- Data classification accuracy for PII/PHI/financial data
- Prompt injection defenses in agent skill templates
- Audit logging completeness in generated governance configs

If you find an issue in any of these areas, please report it using the process above.
