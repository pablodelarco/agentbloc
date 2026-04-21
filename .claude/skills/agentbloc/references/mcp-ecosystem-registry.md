# MCP Ecosystem Registry

> Loaded by SKILL.md at Phase 3 entry alongside [mcp-integration-protocol.md](mcp-integration-protocol.md) and [integration-manifest-schema.md](integration-manifest-schema.md). Curated registry of known MCP servers seeded from CLAUDE.md Technology Stack "MCP Server Ecosystem: Verified Available" tables. Consulted by Step 2 of the 4-step search - if the user's tool has an entry here, Claude proposes `npx -y <package>` to the user for approval per D-37. Trust tiers pre-computed per v1.0 INTG-04.

## Table of Contents

- [When This Applies](#when-this-applies)
- [Communication and Reporting](#communication-and-reporting)
- [Google Workspace](#google-workspace)
- [E-Commerce and Payments](#e-commerce-and-payments)
- [CRM and Business Tools](#crm-and-business-tools)
- [Accounting and Finance](#accounting-and-finance)
- [Browser Automation](#browser-automation)
- [Development and Infrastructure](#development-and-infrastructure)
- [Workflow Automation (Meta)](#workflow-automation-meta)
- [Trust Tier Criteria](#trust-tier-criteria)
- [Quick Reference](#quick-reference)

## When This Applies

Claude loads this file at Phase 3 entry and consults a single category section based on the agent's tool name during Step 2 of the 4-step search (see [mcp-integration-protocol.md](mcp-integration-protocol.md) Step 2). Specific lookups:

- **Tool name matches an entry:** Claude proposes `npx -y <package>` plus the entry's trust tier and evidence to the user, waits for approval per D-37, then writes the MCP into `.mcp.json` and proceeds to the Verification Loop.
- **Tool name does not match any entry:** Claude proceeds to Step 3 (wrapper generation via mcp-builder skill).
- **Entry trust_tier is LOW:** Claude surfaces the trust tier prominently in the proposal and names the alternative (e.g., "if you prefer a higher-trust option, I can generate a wrapper instead").

Additions to this registry land via user-facing PRs or dogfooding feedback, not as a v2.0 concern. The seed list is ~20 entries across 8 categories - enough to cover the Arco Rooms canonical test case and the most common SMB automation targets.

**Scope note:** This registry seeds the Phase 3 4-step search only. It is NOT the authoritative directory of every MCP server in existence (PulseMCP and Awesome MCP Servers play that role). Entries here are curated for AgentBloc's target user base (SMB automation, bilingual EN/ES operations, Telegram-first reporting).

**Column legend (all tables):** `tool_id` is the kebab-case identifier the agent references in `tools[]`; `package` is the npm or GitHub package name installed via `npx -y <package>`; `publisher` is the npm publisher or GitHub org; `trust_tier` is HIGH / MEDIUM / LOW per the criteria section below; `last_commit` is the most recently verified commit month (YYYY-MM); `required_scopes` is the minimum env var set the MCP server needs to boot.

## Communication and Reporting

MCP servers for messaging, alerts, and reporting channels. Telegram is AgentBloc's primary reporting channel per PROJECT.md.

| tool_id | package | publisher | trust_tier | last_commit | required_scopes |
|---------|---------|-----------|------------|-------------|-----------------|
| telegram-mcp | telegram-mcp (guangxiangdebizi) | guangxiangdebizi | MEDIUM | 2026-01 | TELEGRAM_BOT_TOKEN |
| telegram-mtproto-mcp | mcp-telegram (sparfenyuk) | sparfenyuk | MEDIUM | 2026-02 | TELEGRAM_API_ID + TELEGRAM_API_HASH |
| slack-mcp | slack-mcp-plugin | slackapi | HIGH | 2026-03 | SLACK_BOT_TOKEN |
| slack-community-mcp | slack-mcp-server (korotovsky) | korotovsky | MEDIUM | 2026-02 | SLACK_USER_TOKEN |

**When to pick:** Telegram for mobile-first threading + voice approval; Slack for team-native deployments. Both have native MCP.

## Google Workspace

All-in-one Google Workspace MCP covers Gmail / Calendar / Docs / Sheets / Slides / Chat / Forms / Tasks / Drive. Scoped MCPs for single services exist too.

| tool_id | package | publisher | trust_tier | last_commit | required_scopes |
|---------|---------|-----------|------------|-------------|-----------------|
| google-workspace-mcp | google_workspace_mcp (taylorwilsdon) | taylorwilsdon | MEDIUM | 2026-03 | GOOGLE_OAUTH_TOKEN (scopes: gmail.readonly, calendar.readonly, drive.file) |
| google-sheets-mcp | mcp-google-sheets (xing5) | xing5 | MEDIUM | 2026-01 | GOOGLE_OAUTH_TOKEN (scope: spreadsheets) |
| gmail-mcp | @smithery-ai/gmail-mcp | smithery-ai | MEDIUM | 2026-02 | GOOGLE_OAUTH_TOKEN (scope: gmail.readonly OR gmail.modify) |

**When to pick:** google-workspace-mcp (taylorwilsdon) for multi-service access; scope-specific MCPs for least-privilege setups.

## E-Commerce and Payments

| tool_id | package | publisher | trust_tier | last_commit | required_scopes |
|---------|---------|-----------|------------|-------------|-----------------|
| shopify-mcp | shopify-mcp (community) | community | MEDIUM | 2026-02 | SHOPIFY_ADMIN_API_TOKEN |
| stripe-mcp | stripe-mcp (community) | community | MEDIUM | 2026-03 | STRIPE_SECRET_KEY |

**When to pick:** Standard payment and commerce integrations.

## CRM and Business Tools

| tool_id | package | publisher | trust_tier | last_commit | required_scopes |
|---------|---------|-----------|------------|-------------|-----------------|
| hubspot-mcp | hubspot-mcp (community) | community | MEDIUM | 2026-02 | HUBSPOT_ACCESS_TOKEN |
| salesforce-mcp | salesforce-mcp (community) | community | LOW | 2025-12 | SALESFORCE_OAUTH_TOKEN |
| notion-mcp | notion-mcp (community) | community | MEDIUM | 2026-03 | NOTION_API_TOKEN |

**When to pick:** Notion for knowledge management; HubSpot / Salesforce for CRM flows.

## Accounting and Finance

| tool_id | package | publisher | trust_tier | last_commit | required_scopes |
|---------|---------|-----------|------------|-------------|-----------------|
| xero-mcp | xero-mcp-server | XeroAPI | HIGH | 2026-03 | XERO_CLIENT_ID + XERO_CLIENT_SECRET (scopes: accounting.transactions, accounting.contacts) |
| bank-mcp | bank-mcp (elcukro) | elcukro | MEDIUM | 2026-02 | PLAID_CLIENT_ID OR TELLER_APPLICATION_TOKEN (read-only) |

**When to pick:** Xero for SMB accounting; bank-mcp for multi-provider bank access (Plaid US, Teller US, Enable Banking EU, Tink EU). PSD2 (EU) and Plaid (US) are the two primary read-only banking paths.

## Browser Automation

Playwright MCP is the standard fallback when no native MCP exists. Used by Phase 11 browser-fallback flow.

| tool_id | package | publisher | trust_tier | last_commit | required_scopes |
|---------|---------|-----------|------------|-------------|-----------------|
| playwright-mcp | @playwright/mcp | microsoft | HIGH | 2026-04 | (none - runs locally) |
| playwright-community-mcp | @executeautomation/mcp-playwright | executeautomation | MEDIUM | 2026-03 | (none) |

**When to pick:** Microsoft Playwright MCP for accessibility-snapshot-based automation (25+ tools, no vision model required).

## Development and Infrastructure

Official reference MCP servers from `modelcontextprotocol/servers` repo.

| tool_id | package | publisher | trust_tier | last_commit | required_scopes |
|---------|---------|-----------|------------|-------------|-----------------|
| filesystem-mcp | @modelcontextprotocol/server-filesystem | modelcontextprotocol | HIGH | 2026-03 | (local path scoping) |
| git-mcp | @modelcontextprotocol/server-git | modelcontextprotocol | HIGH | 2026-03 | (repository path) |
| memory-mcp | @modelcontextprotocol/server-memory | modelcontextprotocol | HIGH | 2026-02 | (none) |

**When to pick:** Official reference servers - safe defaults for file ops, git operations, persistent agent memory.

## Workflow Automation (Meta)

Meta-connectors. Use only when a direct MCP does not exist for the target service.

| tool_id | package | publisher | trust_tier | last_commit | required_scopes |
|---------|---------|-----------|------------|-------------|-----------------|
| zapier-mcp | zapier-mcp (Zapier) | Zapier | MEDIUM | 2026-03 | ZAPIER_API_KEY |

**When to pick:** Last resort meta-connector - adds cost, latency, and a dependency layer; prefer a direct MCP for the target service when one exists.

## Trust Tier Criteria

Trust tiers are pre-computed per v1.0 INTG-04 and recorded in each registry entry. Re-evaluated on every Phase 10 re-verification (D-39 `healthcheck_at` updates the last-seen evidence).

| Tier | Criteria | When to Pick |
|------|----------|--------------|
| **HIGH** | Official vendor-maintained (Anthropic, Microsoft, Google, Slack, Xero, Stripe, etc.), OR community project with >500 GitHub stars AND active maintenance (commit within 90 days) | Auto-pass proposal; user approval is default-yes |
| **MEDIUM** | Community-maintained project with 100-500 GitHub stars, commit within 180 days, clear documentation (README with examples) | Propose with evidence; user approval required |
| **LOW** | Project with <100 GitHub stars, OR >180 days since last commit, OR unclear/anonymous maintainer, OR no documentation | Surface warning; suggest wrapper generation (Step 3) as alternative; user must explicitly accept risk |

**Drift:** An MCP that was HIGH at registry-seed time might drop to MEDIUM or LOW. Phase 6 Evolution (v1.0 EVOL-02 inherited) re-verifies on a weekly cadence; the `healthcheck_at` + `trust_tier` fields in the manifest carry the drift signal forward.

## Quick Reference

- **Communication:** Telegram (primary, MEDIUM) / Slack (HIGH official).
- **Google Workspace:** google-workspace-mcp (all-in-one MEDIUM) OR scope-specific MCPs for least-privilege.
- **E-Commerce / Payments:** Shopify (MEDIUM) / Stripe (MEDIUM).
- **CRM:** Notion (MEDIUM) / HubSpot (MEDIUM) / Salesforce (LOW - re-verify before use).
- **Accounting / Finance:** Xero (HIGH) / bank-mcp (MEDIUM - multi-provider).
- **Browser:** Playwright MCP (HIGH Microsoft-maintained).
- **Development:** Filesystem / Git / Memory - all official reference servers (HIGH).
- **Meta:** Zapier (MEDIUM) - last resort only.
- **Default on ambiguity:** if no entry matches the tool name, fall through to Step 3 (wrapper generation) per [mcp-integration-protocol.md](mcp-integration-protocol.md).
- **Rule:** Registry entries are seed data for Step 2 of the 4-step search. Every entry's trust tier is load-bearing - downstream consumers (Phase 12 Deploy Pipeline) refuse LOW-tier entries without user override.
