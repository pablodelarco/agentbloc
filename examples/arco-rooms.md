# Arco Rooms -- Reference Implementation

Arco Rooms is a property management system in Almeria, Spain that manages utility invoices and bank payments across multiple rental properties. It serves as the reference implementation for AgentBloc, demonstrating every pattern the skill should support. The system runs as a Claude Code agent team triggered by a single daily cron job.

## Patterns Demonstrated

### 1. Multi-provider invoice collection

Six utility companies (electricity, water, gas, internet, waste, insurance), each with different integration methods: direct API for modern providers, Gmail scraping for email-based invoices, and Playwright browser automation for legacy portals with no API or email notifications.

### 2. Multi-bank payment tracking

Seven bank accounts across four banks monitored via PSD2/OpenBanking APIs. Each bank has different authentication flows (JWT, OAuth2, certificate-based) and different data formats that must be normalized into a common transaction schema.

### 3. Intelligent matching

Regex-based tenant-to-payment matching with confidence thresholds. High-confidence matches are processed automatically. Low-confidence matches are flagged for human review. The matching rules evolve as new patterns are discovered.

### 4. State-based idempotency

JSON state files track processed message IDs, transaction hashes, and entity mappings. Re-running the agent team never duplicates work. Each provider has its own state file with a simple processed/pending model.

### 5. Unmapped entity feedback loop

When a new contract number or tenant reference appears that the system cannot match, it prompts the user via Telegram for the mapping. Once provided, the mapping is stored and applied automatically on subsequent runs.

### 6. Spreadsheet integration

Google Sheets serves as both data source (tenant registry, property details) and reporting layer (monthly summaries, payment status). Read/write operations use the Google Sheets MCP server.

### 7. Notification discipline

Silence by default. The system only sends Telegram notifications for: confirmed payments, new invoices detected, unmapped items requiring attention, and errors. No "everything is fine" messages.

### 8. Fallback chains

Every integration has a degradation path: API (primary) -> Gmail scraping (secondary) -> Playwright browser automation (tertiary) -> manual notification asking the user to handle it. The agent tries each method in order before escalating.

### 9. Date-filtered entity management

Tenants have start and end dates. Active filtering ensures that only current tenants are included in matching and reporting. Historical tenants are preserved for audit but excluded from active processing.

### 10. Single cron job orchestration

One daily job at 22:00 (after business hours, after banks process daily transactions) runs all six collection passes sequentially. Each pass is idempotent. If one fails, the others still run.

### 11. Multi-owner support

Bank accounts belong to different family members. The system handles ownership mapping so that payments from any family member's account are correctly attributed to the right property and tenant.

## When to Reference

Use these patterns as your playbook when designing new agent teams. Not every team needs all 11 patterns, but knowing they exist helps you recognize when a user's workflow calls for one of them. The patterns are composable: a simple automation might use only patterns 4 (idempotency) and 7 (notification discipline), while a complex multi-provider system might use all 11.

## Full Walkthrough

A complete step-by-step walkthrough showing how AgentBloc designed and deployed the Arco Rooms agent team will be added as part of the repository polish phase (REPO-03 scope). The walkthrough will demonstrate the full 6-phase flow from initial interview through production deployment.
