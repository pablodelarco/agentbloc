---
phase: 13
slug: multi-agent-runtime
status: draft
nyquist_compliant: false
wave_0_complete: false
created: 2026-04-24
---

# Phase 13 , Validation Strategy

> Per-phase validation contract for feedback sampling during execution. Phase 13 emits references + templates + subagent + fixtures (no runtime-executable code); validation focuses on prose-checklist compliance, fixture shape verification, and schema integrity of emitted artifacts. Phase 16 drives the end-to-end runtime validation (cron fires -> agent wakes -> correlation ID propagates -> KILL_SWITCH halts team).

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | Existing v1.0 TAP runner (`node --test` equivalent via tap@16.x; tests/ directory) |
| **Config file** | `.github/workflows/ci.yml` (existing Phase 7 CI job; Phase 13 does not modify) |
| **Quick run command** | `grep -c "—" .planning/phases/13-multi-agent-runtime/*.md .claude/skills/agentbloc/references/n8n-integration.md .claude/skills/agentbloc/references/runtime-coordination.md .claude/skills/agentbloc/references/correlation-id.md 2>/dev/null` (em-dash gate) |
| **Full suite command** | `node tests/run-tap.js --scope phase-13` (will be emitted in Wave 0 if Phase 13 gains runtime tests) |
| **Estimated runtime** | <5 seconds (prose + schema checks; no runtime spin-up in Phase 13 scope) |

---

## Sampling Rate

- **After every task commit:** Run em-dash gate + prose-checklist grep (verifies REQUIRED fields in each new reference)
- **After every plan wave:** Run full em-dash gate across all 13 new/modified files + fixture shape validation (YAML parseability for registry.yaml + n8n route JSON files + wake.md frontmatter)
- **Before `/gsd-verify-work`:** All 7 RUNTIME-0X requirements traceable to an emitted artifact + all Phase 16 golden-file anchors present
- **Max feedback latency:** 5 seconds (prose greps + YAML/JSON parse; no subprocess spin-up)

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 13-01-01 | 01 | 1 | RUNTIME-03 | T-13-01 / prompt-injection inherited | n8n envelope validates schema_version=1 + bounded trigger.source enum | fixture-shape | `python3 -c "import json; d=json.loads(open('.claude/skills/agentbloc/examples/arco-rooms-runtime-artifacts.md').read().split('\`\`\`json')[1].split('\`\`\`')[0]); assert d['schema_version']==1"` | ❌ W0 | ⬜ pending |
| 13-01-02 | 01 | 1 | RUNTIME-04, RUNTIME-05 | T-13-02 / coordination bypass | TeamCreate invoked only when workflows[].agents.length > 1 | prose-checklist | `grep -q "workflows\[\].agents.length > 1" .claude/skills/agentbloc/references/runtime-coordination.md` | ❌ W0 | ⬜ pending |
| 13-01-03 | 01 | 1 | RUNTIME-06 | T-13-03 / ID collision | Correlation-ID format regex `^(cron|webhook-[a-z][a-z0-9-]*|telegram|inter|manual)-[0-9]{8}T[0-9]{6}Z-[a-f0-9]{6}(-sub-[0-9]{3})*$` | regex-compile | `python3 -c "import re; r=re.compile(r'^(cron\|webhook-[a-z][a-z0-9-]*\|telegram\|inter\|manual)-[0-9]{8}T[0-9]{6}Z-[a-f0-9]{6}(-sub-[0-9]{3})*$'); assert r.match('cron-20260501T080000Z-a3f21b')"` | ❌ W0 | ⬜ pending |
| 13-01-04 | 01 | 1 | RUNTIME-01 | T-13-04 / interactive-editor hang | crontab install uses stdin form, NEVER `crontab -e` | grep-check | `! grep -E '\bcrontab -e\b' .claude/skills/agentbloc/references/runtime-coordination.md && grep -q 'crontab -$' .claude/skills/agentbloc/references/runtime-coordination.md` | ❌ W0 | ⬜ pending |
| 13-01-05 | 01 | 1 | (template-fidelity) | T-13-05 / template drift | wake-job templates contain exactly 6 numbered sections | section-count | `for f in .claude/skills/agentbloc/templates/wake-job-cron.md.tmpl .claude/skills/agentbloc/templates/wake-job-webhook.md.tmpl .claude/skills/agentbloc/templates/wake-job-inter.md.tmpl; do n=$(grep -cE '^## [1-6]\. ' "$f"); [ "$n" -eq 6 ] \|\| exit 1; done` | ❌ W0 | ⬜ pending |
| 13-01-06 | 01 | 1 | RUNTIME-07 | T-13-06 / missing kill-switch | Every wake.md template section 1 contains `.agentbloc/KILL_SWITCH` check | grep-all | `for f in .claude/skills/agentbloc/templates/wake-job-*.md.tmpl; do grep -q '.agentbloc/KILL_SWITCH' "$f" \|\| exit 1; done` | ❌ W0 | ⬜ pending |
| 13-01-07 | 01 | 1 | (fixture) | T-13-07 / fixture drift | arco-rooms-correlation-flow.md contains 3 scenarios (A cron + B webhook + C kill-switch) | grep-count | `[ $(grep -cE '^### Scenario [A-C]' .claude/skills/agentbloc/examples/arco-rooms-correlation-flow.md) -eq 3 ]` | ❌ W0 | ⬜ pending |
| 13-01-08 | 01 | 1 | RUNTIME-02 | T-13-08 / n8n format | n8n route files use `.json` extension (not `.yaml`) per RESEARCH amendment | file-ext | `ls .claude/skills/agentbloc/examples/arco-rooms-runtime-artifacts.md \| xargs grep -E "n8n-routes/.+\.(json\|yaml)" \| grep -v "\.yaml" \| head -1` | ❌ W0 | ⬜ pending |
| 13-02-01 | 02 | 2 | (subagent-scope) | T-13-09 / Bash blast radius | runtime-engine allow-list contains `crontab -` + `crontab -l` + `shasum` + `claude agents list` + `claude mcp list`; NOT `crontab -e` + NOT `bash -c` | grep-negative | `! grep -E '(crontab -e\|bash -c\|curl\|rm -rf)' .claude/agents/runtime-engine.md` | ❌ W0 | ⬜ pending |
| 13-02-02 | 02 | 2 | (context:fork) | T-13-10 / context leak | runtime-engine YAML frontmatter contains `context: fork` | grep-check | `head -10 .claude/agents/runtime-engine.md \| grep -q '^context: fork$'` | ❌ W0 | ⬜ pending |
| 13-02-03 | 02 | 2 | RUNTIME-01..07 traceability | T-13-11 / missing req | runtime-engine cites each RUNTIME-0X at least once | grep-each | `for r in RUNTIME-01 RUNTIME-02 RUNTIME-03 RUNTIME-04 RUNTIME-05 RUNTIME-06 RUNTIME-07; do grep -q "$r" .claude/agents/runtime-engine.md \|\| exit 1; done` | ❌ W0 | ⬜ pending |
| 13-03-01 | 03 | 3 | (wiring) | T-13-12 / SKILL.md budget | SKILL.md total <= 225 lines (Phase 12 baseline 183 + Phase 13 budget 20 + 10 safety) | line-count | `[ $(wc -l < .claude/skills/agentbloc/SKILL.md) -le 225 ]` | ❌ W0 | ⬜ pending |
| 13-03-02 | 03 | 3 | (wiring) | T-13-13 / sub-gate | SKILL.md Phase 5 State Transitions paragraph contains `runtime_wired` sub-gate | grep-check | `grep -q 'runtime_wired' .claude/skills/agentbloc/SKILL.md` | ❌ W0 | ⬜ pending |
| 13-03-03 | 03 | 3 | (wiring) | T-13-14 / Phase 6 precondition | SKILL.md Phase 6 precondition checks `registry.yaml` runtime.cron_registered_at or runtime.webhook_endpoints | grep-regex | `grep -E 'runtime\.(cron_registered_at\|webhook_endpoints)' .claude/skills/agentbloc/SKILL.md` | ❌ W0 | ⬜ pending |
| 13-03-04 | 03 | 3 | (wiring) | T-13-15 / kill-switch paragraph | incident-response.md gains a "Runtime Kill-Switch Semantics" section with 3-point enforcement | grep-section | `grep -q 'Runtime Kill-Switch Semantics' .claude/skills/agentbloc/references/incident-response.md && grep -cE '^(1\|2\|3)\. .+(wake\|tool\|transition)' .claude/skills/agentbloc/references/incident-response.md \| head -1` | ❌ W0 | ⬜ pending |
| 13-03-05 | 03 | 3 | (wiring) | T-13-16 / deploy-protocol Step 7 | deploy-protocol.md gains Step 7 (Runtime Wiring) after Step 6 verification | grep-check | `grep -q '## Step 7.*Runtime' .claude/skills/agentbloc/references/deploy-protocol.md` | ❌ W0 | ⬜ pending |
| 13-03-06 | 03 | 3 | (wiring) | T-13-17 | em-dash gate across all emitted files | grep-sum | `[ $(grep -c "—" .claude/skills/agentbloc/references/n8n-integration.md .claude/skills/agentbloc/references/runtime-coordination.md .claude/skills/agentbloc/references/correlation-id.md .claude/skills/agentbloc/templates/wake-job-cron.md.tmpl .claude/skills/agentbloc/templates/wake-job-webhook.md.tmpl .claude/skills/agentbloc/templates/wake-job-inter.md.tmpl .claude/skills/agentbloc/examples/arco-rooms-correlation-flow.md .claude/skills/agentbloc/examples/arco-rooms-runtime-artifacts.md .claude/agents/runtime-engine.md 2>/dev/null \| awk -F: '{s+=$2} END{print s}') -eq 0 ]` | ❌ W0 | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

No Wave 0 infrastructure installs required. Phase 13 inherits:
- Phase 7 TAP runner (`tests/run-tap.js`)
- Phase 7 GitHub Actions CI workflow (`.github/workflows/ci.yml`)
- Python 3.12 (system-available on macOS + CI runners) for JSON/regex spot-checks in verification commands
- `grep`, `awk`, `sed` (POSIX; CI base image has them)

All verification commands in the Per-Task Verification Map use standard Unix tooling already present in the project. No new dependencies.

*Existing infrastructure covers all Phase 13 requirements.*

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| n8n route deploys into user's n8n instance and triggers correctly on live event | RUNTIME-02, RUNTIME-03 | n8n is external infrastructure; CONTEXT D-78 evidence.verified_at: null until user confirms. No automatable probe from Phase 13 scope. | User imports `arco-rooms-runtime-artifacts.md` route stub into n8n, activates the webhook, fires a test event from the source (e.g., sends a test Gmail to the monitored mailbox), verifies the agent wakes and logs the correlation ID. |
| `TeamCreate` primitive signature matches Claude Code implementation at runtime | RUNTIME-04 | ClaudeClaw + Claude Code experimental flag `CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS=1` may change between versions; research verified current signature but not future compat | Plan 13-02 runtime-engine authoring reads then-current Claude Code docs + Sample-calls an interactive `TeamCreate` with correlation_id metadata + confirms the metadata round-trips through `SendMessage`. If the signature differs from CONTEXT D-76's documented call, Plan 13-02 replans runtime-coordination.md. |
| KILL_SWITCH halts a live team mid-session within 1 SendMessage round-trip | RUNTIME-07 | Requires a live 2-agent team running in ClaudeClaw with cron + n8n routes installed. Not automatable from static Phase 13 artifacts alone. | Phase 16 canonical E2E test: spin up Arco Rooms team, fire Telegram `/stop`, observe `dissolution_reason: kill-switch` logged in TEAM_SESSIONS.jsonl within 5 seconds with all team members returning `halted-kill-switch` wake_outcome. |
| Correlation ID propagates end-to-end through a real n8n webhook -> cron-wake -> TeamCreate -> SendMessage chain | RUNTIME-06 | Requires full live stack (n8n + ClaudeClaw + deployed agents) | Phase 16 Scenario B rerun with live audit.jsonl grep; single correlation ID must appear in Recepcionista wake + Gestor Cobros SendMessage receive + Gestor Cobros log + return SendMessage + Recepcionista second log. |

---

## Validation Sign-Off

- [ ] All tasks have `<automated>` verify or Wave 0 dependencies
- [ ] Sampling continuity: no 3 consecutive tasks without automated verify
- [ ] Wave 0 covers all MISSING references (none needed; existing infrastructure suffices)
- [ ] No watch-mode flags
- [ ] Feedback latency <5s
- [ ] `nyquist_compliant: true` set in frontmatter (once all checks pass during execution)

**Approval:** pending (planner spawns; will be approved after gsd-plan-checker validates per-task verify commands match emitted artifacts)
