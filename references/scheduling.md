# Scheduling Patterns

> Loaded during Phase 2 (schedule definition in Design step 4) and Phase 5 (cron job generation in deployment artifacts). Provides cron expression format, timezone handling, DST safety rules, pipeline spacing, and deployment method guidance.

## Table of Contents

- [When This Applies](#when-this-applies)
- [Cron Expression Format](#cron-expression-format)
- [Timezone Handling](#timezone-handling)
- [DST Safety Rules](#dst-safety-rules)
- [Pipeline Spacing](#pipeline-spacing)
- [Deployment Methods](#deployment-methods)
- [Holiday Limitation](#holiday-limitation)
- [Quick Reference](#quick-reference)

## When This Applies

Referenced during Phase 2 (Design step 4: Schedule and Trigger Definitions) and Phase 5 (deployment artifact generation for cron jobs). This is a supporting pattern library, not a standalone conversational phase. The design and deployment protocols cross-reference this file for scheduling details.

## Cron Expression Format

Standard 5-field cron format used for all agent scheduling:

```
minute  hour  day-of-month  month  day-of-week
  0      22       *           *         *
```

| Pattern | Expression | Description |
|---------|-----------|-------------|
| Daily at 22:00 | `0 22 * * *` | Default for single-agent or pipeline start |
| Every 6 hours | `0 */6 * * *` | High-frequency collection agents |
| Weekdays only | `0 9 * * 1-5` | Business-hours agents (Mon-Fri) |
| Weekly Sunday | `0 3 * * 0` | Evolution scan, weekly reports |
| Twice daily | `0 8,20 * * *` | Morning and evening collection |

All times are expressed in the user's local timezone as documented in `team.yaml`. The system timezone must match the configured timezone (see Timezone Handling below).

## Timezone Handling

Use IANA timezone identifiers in `team.yaml`:

```yaml
timezone: Europe/Madrid    # Spain (CET/CEST)
# timezone: America/New_York  # US Eastern (EST/EDT)
# timezone: Asia/Tokyo        # Japan (JST, no DST)
```

The deployment server's system timezone must match the value in `team.yaml`. For VPS setup:

```bash
sudo timedatectl set-timezone Europe/Madrid
timedatectl  # Verify: "Time zone: Europe/Madrid (CET, +0100)" or "(CEST, +0200)"
```

All cron expressions are interpreted in this local timezone. When documenting schedules for the user, always state the timezone explicitly: "Daily at 22:00 Europe/Madrid."

## DST Safety Rules

Daylight Saving Time creates two scheduling hazards:

1. **Spring forward** (last Sunday of March in Europe): clocks jump from 01:59 to 03:00. Any job scheduled between 02:00 and 02:59 **does not exist** and will be skipped entirely.
2. **Fall back** (last Sunday of October in Europe): clocks go from 02:59 back to 02:00. Any job scheduled between 01:00 and 01:59 **runs twice**.

**Recommendation:** Schedule all agents outside the 01:00 to 03:00 local time window. This avoids both hazards regardless of the timezone's DST rules.

The Arco Rooms default schedule (22:00, 22:30, 23:00) is safe because it falls well outside the danger window. Regions without DST (e.g., `Asia/Tokyo`, `UTC`) are unaffected, but the recommendation still applies for portability.

## Pipeline Spacing

For sequential agent pipelines, space cron times to prevent overlap. If two agents write to state files concurrently, JSON corruption can occur.

**Default spacing:** 30-minute gaps between pipeline stages.

| Pipeline Stage | Cron Time | Agent |
|---------------|-----------|-------|
| Stage 1 | `0 22 * * *` | Invoice Collector |
| Stage 2 | `30 22 * * *` | Payment Matcher |
| Stage 3 | `0 23 * * *` | Report Sender |

**Why 30 minutes:** Most agent sessions complete within 5-15 minutes. A 30-minute gap provides a safe buffer for slow providers, retries, and Telegram approval timeouts. Adjust based on observed run durations after the first week of production operation.

**State isolation:** Each agent writes to its own state file (`state/{agent-slug}.json`), which minimizes shared-write risks. Pipeline spacing is still required because downstream agents read upstream state files.

## Deployment Methods

### Production: System Cron + `claude -p`

System cron is the production scheduling method. It survives reboots, requires no open terminal, and uses standard Unix tooling.

**Crontab entry template:**

```bash
0 22 * * * /usr/bin/env bash -c 'source /home/user/project/.env && cd /home/user/project && claude -p "$(cat .agentbloc/jobs/daily-pipeline.md)" >> .agentbloc/logs/cron.log 2>&1'
```

**Critical:** The `.env` file must be explicitly sourced because cron runs with a minimal environment. Without sourcing, agents will fail with missing API keys and authentication errors.

### Development/Demo: Claude Code Scheduled Tasks (Desktop)

Claude Code Desktop app supports persistent scheduling via `/schedule` or the task scheduler UI. These tasks are convenient for development and demos but have two limitations:

- **Expire after 7 days.** Tasks must be manually renewed.
- **Require the Desktop app to be running.** If the app closes, tasks stop.

Desktop Scheduled Tasks are not suitable for production deployments.

### Session-Scoped: `/loop` (Not Recommended)

The `/loop` command creates a recurring task within the current Claude Code session. It is session-scoped: when the terminal closes, the loop stops. Not suitable for any persistent scheduling.

## Holiday Limitation

v1.0 does not support holiday-aware scheduling. Agents run on their configured schedule regardless of public holidays, weekends, or business closures.

If an agent collects data from a service that is unavailable on holidays (e.g., a bank API), the agent's error handling should gracefully skip that provider and log the failure. No schedule modification is needed.

Holiday awareness could be added through the evolution loop (Phase 6): a governance.yaml configuration change that skips runs on specified dates. This is a v2.0 consideration.

## Quick Reference

| Practice | Rule |
|----------|------|
| Time format | 5-field cron (minute hour dom month dow) |
| Timezone | IANA identifier in team.yaml; server must match |
| DST safety | Avoid scheduling between 01:00 and 03:00 local time |
| Pipeline gaps | 30-minute default spacing between sequential agents |
| Production method | System cron + `claude -p` with explicit .env sourcing |
| Dev/demo method | Claude Code Scheduled Tasks (Desktop); expires after 7 days |
| Holidays | No support in v1.0; agents run regardless |
| State files | Per-agent JSON; never concurrent writes to same file |
