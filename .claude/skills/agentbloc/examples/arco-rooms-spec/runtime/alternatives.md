# Runtime Alternatives — Arco Rooms

> The reference impl ships bash + cron + Telegram. This document
> covers 7 alternative runtimes with tradeoffs.

## Decision frame

The runtime layer has six responsibilities:

1. **Wake** — fire each agent on its trigger
2. **State** — persist memory, inbox, last-run across wakes
3. **Reason** — invoke the agent's reasoning loop
4. **Gate** — enforce kill-switch + blast-radius approvals
5. **Log** — append-only audit trail
6. **Notify** — approval requests + escalations + briefings

The CONTRACTS in `../governance/` define what each must do. The
runtime chooses HOW.

## Option matrix

| Runtime | Best fit for Arco Rooms | Strengths | Weaknesses |
|---|---|---|---|
| **bash + cron + Telegram (reference-impl)** | Default — Pablo's VPS + Spanish telephony reliability | Zero new deps; debuggable; offline-capable | Single-machine; bash error handling |
| **n8n self-hosted (Docker)** | If Pablo wants visual UI for runtime monitoring | Branching nodes; UI; 600+ integrations | Adds Docker dep; flows harder to version-control |
| **n8n cloud** | Demos to other property managers | No infra | Recurring cost; data residency |
| **Pipedream** | If pipeline becomes webhook-heavy (e.g., bank push notifications via n8n) | Free tier generous; webhook-native | Cold starts; pricing past free |
| **Temporal** | If invoice retries become long-running (rare) | Durable workflows; retries first-class | Steep learning curve; needs cluster |
| **Inngest** | Same as Temporal but easier | Hosted + self-hosted; declarative | Newer; smaller ecosystem |
| **Custom Python (APScheduler + FastAPI)** | If team grows + needs Python data tooling | Full control; pandas/numpy ecosystem | You own ops |
| **Claude Code Scheduled Tasks** | Demo only | Native Claude Code | Tasks expire after 7 days; needs Desktop app open |

## When each wins for this team

### Reference-impl wins when

- Pablo runs on a $5/mo VPS in Spain (default assumption)
- Cost is primary constraint
- Pablo (or his developer) is comfortable in bash
- Debuggability matters more than ergonomics
- 3 agents + ~30 wakes/day total (well within bash + cron range)

### n8n self-hosted wins when

- Pablo wants to hand-edit workflows visually (e.g., adding a new
  utility provider without re-running AgentBloc)
- A monitoring UI for runtime state would be nice-to-have
- The team grows beyond 3 agents

### Pipedream / Inngest / Temporal

Overkill for v1. If usage justifies (multiple operators, hundreds of
workflows, durable retries), revisit. AgentBloc Phase 6 spec
evolution can re-emit `runtime/BUILD.md` for a new runtime without
changing governance contracts.

### Custom Python

If Pablo or his developer prefers Python over bash, this is a clean
swap. The agent prompts in `agents/<id>/prompts.md` are
runtime-agnostic; only the wake.sh + helpers.sh primitives need
re-implementation.

## Migration paths

If team starts on reference-impl and outgrows it:

| Outgrowing | Migrate to | Effort |
|---|---|---|
| Single machine, can't scale | Custom Python (Celery / Dramatiq) | 2-3 days |
| Visual flow ergonomics | n8n self-hosted | 1-2 days |
| Need durable retries | Inngest hosted | 1 week |
| Compliance / RBAC | Custom Python + IAM | 2 weeks |

CONTRACTS in `../governance/` stay constant — only implementations
change.

## Cost comparison (rough)

| Runtime | Monthly cost (Arco Rooms scale: 3 agents, ~30 wakes/day) |
|---|---|
| reference-impl on $5/mo VPS | $5 + Anthropic API (~€15-25/mo at current Sonnet/Opus mix) |
| n8n self-hosted on $5/mo VPS | $5 + Anthropic API |
| n8n cloud (starter) | $20 + Anthropic API |
| Pipedream (basic) | $0-19 + Anthropic API |
| Temporal Cloud (starter) | $200 + Anthropic API (way overkill) |
| Inngest (free tier) | $0 + Anthropic API (until rate cap) |

## What NOT to use

| Avoid | Why |
|---|---|
| **Bare AWS Lambda + EventBridge** without a framework | You'll rebuild the contracts; pick Inngest or Pipedream instead |
| **Airflow** | Built for batch ETL, not multi-agent reactive workflows |
| **Generic CI runners** (GitHub Actions, Jenkins) | Not designed for long-lived state + Telegram I/O |
| **Cron alone** without the helpers | Reinvents `gen_correlation_id`, `audit_log`, etc. |

## Recommendation

Default: **reference-impl on Pablo's $5/mo VPS in Madrid**. ~€20-30/mo
all-in. Start there; revisit only if outgrown.

## Cross-references

- Default impl: `reference-impl/`
- Build steps: `BUILD.md`
- Governance contracts: `../governance/`
- AgentBloc reference: `references/runtime-impl/runtime-coordination.md`
