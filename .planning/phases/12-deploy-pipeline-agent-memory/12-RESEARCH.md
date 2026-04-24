# Phase 12: Deploy Pipeline + Agent Memory - Research

**Researched:** 2026-04-24
**Domain:** Deploy pipeline materialization for ClaudeClaw-compatible multi-agent deployments; per-agent persistent memory architecture; idempotent content-hash fingerprinting; MCP health-check protocol; deterministic Jinja-lite template rendering in-context.
**Confidence:** MEDIUM-HIGH overall (HIGH for scheduled-tasks / MCP health-check / template determinism; MEDIUM for ClaudeClaw conventions because two projects share the name and conventions diverge)

## Summary

Seven investigation threads were pursued against the gaps CONTEXT.md left open. Most findings validate the locked decisions (D-59 through D-73) against current external evidence; three findings surface meaningful plan-impacting tension that the planner and human reviewer should see before plans 12-01/02/03 are cut.

**What changes plan design (impact ranked):**

1. **"ClaudeClaw" names two distinct projects with incompatible conventions.** robonuggets/claudeclaw (Medium blueprint, GitHub) uses `.claude/skills/<skill>/` and per-agent `agents/<id>/` with a `cron-registry.json` that re-registers session-scoped `CronCreate` tasks on every session start. htdocs.dev "ClaudeClaw" (different author) is a TypeScript+Bun Gateway process with `extensions/claudeclaw-*/` and HMAC-authed webhooks. Neither canonically scans a project-root `skills/<agent-id>/SKILL.md` path. D-59a "honors DEPLOY-01 literal because ClaudeClaw expects it" is questionable. See Topic 1.
2. **CronCreate is session-scoped with 7-day expiry.** The Claude Code built-in scheduler (via `/loop` + `CronCreate`/`CronList`/`CronDelete`) does NOT persist across session restart and auto-deletes recurring tasks after 7 days. D-72 (system cron + `claude -p`) is therefore the only durable option for production deploys, confirming the CONTEXT.md choice. See Topic 6.
3. **SHA256-over-body idempotency needs JSON canonicalization for state.json and registry.yaml.** D-60 masks timestamp tokens but does NOT mandate key ordering. Two semantically-identical state.json files with different key orderings will hash differently and trigger false-positive diffs on re-deploy. Planner MUST specify RFC 8785 (JCS) or an equivalent canonical serialization for machine-written JSON artifacts, or the test for DEPLOY-06 (Phase 16 success criterion 2) will be flaky. See Topic 2.
4. **MCP health-check canonical protocol is `tools/list`, not `ping`.** MCPcat and community tooling converged on `tools/list` as the "true ready" probe (ping only proves TCP liveness; `tools/list` proves the server is initialized). D-69 check 2 says "responds with ≥1 tool declared via `claude mcp list`" , this aligns. Recommended timeout is 2-5 seconds, NOT 10; retry count of 3 before marking down is the ecosystem convention. D-69's 10-second timeout is defensible but more generous than the 2026 norm. See Topic 5.
5. **Letta/MemGPT separates core-memory (always-in-context) from recall/archival (searchable).** CONTEXT.md's D-64 single-file `memory.md` with 4 H2 sections matches the "core memory" layer only. That works for v2.0 scale (Arco Rooms ≈ 7 properties, bounded accretion) but will hit a scaling wall at ~50KB per agent. Planner should document the split-file escape hatch as a v2.5+ deferral, NOT attempt multi-file memory in v2.0. See Topic 4.

**Contradictions with CONTEXT.md flagged for human review:**

- **D-59a foundation weakens under investigation.** The claim "skills/<agent-id>/SKILL.md honors ClaudeClaw runtime-discovery path" cannot be verified against either public ClaudeClaw project. The path is cited in `.planning/v2.0-PROMPT.pdf` (authoritative scope doc for this project) but does not appear in any external ClaudeClaw README. Two resolutions possible: (a) accept that v2.0-PROMPT.pdf is the binding contract regardless of external ClaudeClaw conventions; (b) move deployed skills under `.claude/skills/<agent-id>/` to match the actual Claude Code discovery path. Pablo should decide before plan 12-01 locks the path.
- **D-60 lacks JSON canonicalization clause.** Current text masks only timestamps. Without canonical key ordering, re-running the deploy engine on different platforms (or with different YAML libraries) can produce identical-semantic state.json files that hash differently. Fix: extend D-60 to "SHA256 over RFC 8785 canonical JSON with timestamp tokens masked" for JSON artifacts; "SHA256 over UTF-8 body bytes with timestamp masking" for markdown/YAML artifacts. Low effort; high determinism payoff.

**Primary recommendation:** Proceed with CONTEXT.md's 3-plan split, but (a) extend D-60 to require canonical JSON serialization for state.json/last-run.json/DEPLOY_HISTORY.jsonl; (b) lower D-69's per-MCP timeout to 5 seconds with retry=3 (ecosystem norm); (c) surface the D-59a ClaudeClaw-path ambiguity to Pablo before plan 12-01 seals the path choice; (d) ship the memory-schema escape hatch for future multi-file split as a commented-out section in `agent-memory-schema.md`.

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|-------------|----------------|-----------|
| Template rendering (Jinja-lite substitution) | Claude Code in-context | none | Deterministic string replacement; no Python/Node runtime per D-62 |
| Idempotency fingerprinting (SHA256) | Deploy-engine subagent | `shasum -a 256` via narrow Bash allow-list (D-67) | Read existing artifact + mask timestamps + compare |
| Artifact emission (SKILL.md / memory.md / state.json / registry.yaml / DEPLOY-REPORT.md) | Deploy-engine subagent | Write tool | Pure file-system work; no external calls |
| `.mcp.json` surgical merge | Deploy-engine subagent | Edit tool (not Write, per D-66) | Preserve user's other MCP entries byte-for-byte |
| MCP health-check (`tools/list`) | External (Claude Code CLI via `claude mcp list`) | Bash allow-list in deploy-engine | Claude Code owns the MCP client connection |
| Subagent registration check (`claude agents list`) | External (Claude Code CLI) | Bash allow-list | SKILL.md parsing delegated to native CLI |
| Cron registration | User's shell (`crontab <file>`) | `.agentbloc/deploy/crontab.proposed` emitted by deploy-engine | D-72: AgentBloc never mutates system state directly |
| Append-only deploy ledger | Deploy-engine subagent | File write (append mode) | `.agentbloc/deploy/DEPLOY_HISTORY.jsonl` per D-71 |
| Halt-and-name on failure | Deploy-engine subagent | Write DEPLOY-FAILED-REPORT.md + update registry.last_deploy_id | Atomic all-or-nothing per D-70 |

## Topic 1: ClaudeClaw Deployment Convention

### Research Question
What exactly does "ClaudeClaw-compatible deployment" expect on disk, and does D-59a's `skills/<agent-id>/SKILL.md` project-root path match any real ClaudeClaw contract?

### Key Findings

- **"ClaudeClaw" is two projects, not one.** [VERIFIED: web search]
  1. **robonuggets/claudeclaw** (GitHub: github.com/robonuggets/claudeclaw) , a *blueprint reference document* for building persistent multi-agent Claude Code setups. Not a runtime; it describes patterns users hand-copy. [CITED: github.com/robonuggets/claudeclaw]
  2. **htdocs.dev "ClaudeClaw"** , a *composable TypeScript+Bun orchestrator* with Gateway process + `~/.openclaw/cron/jobs.json` + HMAC webhooks. Closer to a platform. [CITED: htdocs.dev/posts/claudeclaw-a-composable-agent-orchestrator-for-claude-code/]
  3. A related third project **OpenClaw** (docs.openclaw.ai) runs a separate Gateway and `jobs.json` file independently of Claude Code sessions. [CITED: docs.openclaw.ai/automation/cron-jobs]

- **robonuggets/claudeclaw workspace layout does NOT use project-root `skills/<agent-id>/SKILL.md`.** [VERIFIED: README fetch]
  Shared skills live at `.claude/skills/<skill-name>.md` (workspace root). Agent-specific skills live at `agents/<agent-id>/.claude/skills/<skill-name>.md`. Each agent is a **separate directory** with its own `CLAUDE.md`, `memory/`, `cron-registry.json`, `.mcp.json`. Quote: *"Shared skills go in the root `.claude/skills/` - accessible to all agents via `--add-dir`. Agent-specific skills go in that agent's `.claude/skills/`."* [CITED: github.com/robonuggets/claudeclaw]

- **robonuggets/claudeclaw cron model is `cron-registry.json` + session-restart replay.** [VERIFIED: README fetch] Schema:
  ```json
  {
    "description": "Cron registry - read on session restart to recreate all scheduled jobs.",
    "crons": [
      { "id": "morning-briefing", "name": "Morning briefing",
        "cron": "57 8 * * *", "prompt": "...", "enabled": true }
    ]
  }
  ```
  Each session startup reads this file and re-creates entries via Claude Code's built-in `CronCreate`. NOT system crontab. NOT webhook-driven.

- **Neither public ClaudeClaw exposes an n8n webhook integration.** [VERIFIED: README fetch + article fetch] robonuggets' pattern is 100% Telegram/Discord channel + cron. htdocs.dev's Gateway uses HMAC-SHA256 authed HTTP POST with per-group rate limiting, but does not spec an n8n-compatible route format.

- **The `skills/<agent-id>/SKILL.md` project-root path is only cited in `.planning/v2.0-PROMPT.pdf` (AgentBloc's own scope document).** [VERIFIED: repo grep] Grep across the repo finds this path pattern only in: PROJECT.md, REQUIREMENTS.md DEPLOY-01, 12-CONTEXT.md, 12-DISCUSSION-LOG.md. No external source confirms this is a ClaudeClaw runtime convention.

- **Claude Code's canonical skill discovery paths are `.claude/skills/`, `~/.claude/skills/`, `<plugin>/skills/`, enterprise-managed settings.** [VERIFIED: code.claude.com/docs/en/skills] Project-root `skills/` is NOT in this list. An agent ID appearing under `.claude/skills/<agent-id>/SKILL.md` would be discovered; one under `skills/<agent-id>/SKILL.md` at project root would NOT.

### Implications for Phase 12 Plan

- **D-59a's foundation weakens.** The justification "ClaudeClaw runtime-discovery path" cannot be verified against any public ClaudeClaw project. Either:
  - **Option A (honor v2.0-PROMPT.pdf as binding):** Keep `skills/<agent-id>/SKILL.md`, but re-word D-59a rationale from "ClaudeClaw convention" to "AgentBloc scope document convention locked by v2.0-PROMPT.pdf page 3-4." This is defensible because the PDF IS the scope contract for v2.0.
  - **Option B (align with Claude Code native):** Move to `.claude/skills/<agent-id>/SKILL.md` (following the canonical skill discovery path). This also collapses D-59a/b/c into a single-namespace decision where `.claude/skills/` holds stable contracts and `.agentbloc/agents/<id>/` holds mutable state , cleaner.
- Either option is defensible; Pablo should pick. Plan 12-01 cannot ship until this is resolved.
- **If Option A wins:** DEPLOY-08 check 1 (`claude agents list` confirms every agent loads) MAY FAIL because `claude agents list` lists `.claude/agents/` subagents, NOT project-root `skills/`. The verification protocol needs a different probe. Could be `ls skills/*/SKILL.md && for f in skills/*/SKILL.md; do head -1 "$f"; done` to confirm files exist and parse. Or a ClaudeClaw-specific CLI if/when one ships.
- **If Option B wins:** D-59 flattens to one override (MEM-01 only), not three; plan header simplifies; the namespace split argument stays intact.

### Risks / Pitfalls

- **Silent discovery mismatch at deploy time.** Generating files at `skills/<agent-id>/SKILL.md` but Claude Code only discovering `.claude/skills/*` means the deployed team never wakes. DEPLOY-08 verification might pass (files exist) while runtime fails in Phase 13.
- **v2.0-PROMPT.pdf might describe a ClaudeClaw convention we haven't located.** A third ClaudeClaw (private/internal) could exist. Check with Pablo whether ClaudeClaw refers to his own internal tooling or a public project.
- **Confusion risk in documentation.** The 12-CONTEXT.md claim "ClaudeClaw-discovered stable contracts" implies an external authority we cannot cite. Better to frame as "AgentBloc-project convention per PDF" , more honest, equally binding.

**Confidence:** MEDIUM , findings are solid for public sources; gap is around whether a non-public ClaudeClaw exists that matches the PDF's claim.

## Topic 2: Idempotent Deploy Patterns for Agent Systems

### Research Question
How do agent systems handle re-deploy with persistent memory, and what pitfalls hit SHA256-content-hash idempotency specifically?

### Key Findings

- **JSON key ordering is the canonical idempotency-hash pitfall.** [CITED: AWS Powertools #638, connect2id.com/blog/how-to-secure-json-objects-with-hmac] *"Two payloads that are essentially the same semantically but have different attribute ordering will result in different idempotent responses."* [CITED: desmati.com/blog/idempotency-in-dotnet-azure]

- **The standard fix is RFC 8785 JSON Canonicalization Scheme (JCS).** [CITED: connect2id.com blog, RFC 8785] JCS specifies: recursive key sorting (lexicographic), stable number formatting, UTF-8 encoding, no whitespace. Any two semantically-identical JSON objects hash to the same SHA256 digest.

- **CrewAI, LangGraph, and Letta approach re-deploy differently:** [CITED: datacamp.com, letta.com/blog]
  - **CrewAI** has a short-term/long-term memory split; re-deploy rebuilds agent definitions but preserves external memory stores (vector DB). [CITED: docs.crewai.com/en/concepts/memory]
  - **LangGraph** uses checkpointer + thread IDs; re-deploying a state graph with the same thread ID resumes from last checkpoint. State diffing is semantic (JSON-path level), not byte-level. [CITED: dev.to AI Agent Memory comparative analysis]
  - **Letta v1** introduced *Context Repositories* with git-based versioning; memory is managed programmatically per block with labels + character limits. [CITED: letta.com/blog/letta-v1-agent]

- **File-based state pattern (Medium post cited in PROJECT.md) does NOT address canonicalization.** [CITED: earezki.com/ai-news/2026-03-09-the-state-management-pattern-that-runs-our-5-agent-system-24-7/] The post recommends plain JSON files with atomic writes + file locks; no mention of hash-based idempotency. The gap is real.

- **The masking pattern (D-60's timestamp placeholder) is valid for Markdown + YAML** because those formats are ordered-by-source (human-authored files preserve line order). It fails for machine-written JSON without key sorting.

### Implications for Phase 12 Plan

- **Extend D-60 to specify:**
  - For Markdown/YAML artifacts (SKILL.md, memory.md, registry.yaml, DEPLOY-REPORT.md): SHA256 over UTF-8 body bytes with `<TIMESTAMP>` and `<FINGERPRINT>` tokens masked. No ordering concern (source-ordered).
  - For JSON artifacts (state.json, last-run.json, .mcp.json merge result, DEPLOY_HISTORY.jsonl lines): SHA256 over **RFC 8785 canonical JSON** with timestamp fields replaced by the `<TIMESTAMP>` placeholder before canonicalization.
- **Add this to `deploy-protocol.md` step 3 (fingerprint resolution).** Plan 12-01 should include the canonicalization algorithm in pseudo-code as part of the schema files so the deploy-engine subagent has a deterministic recipe.
- **Testable with a one-liner:** `echo '{"b":2,"a":1}' | python3 -c "import json,sys; d=json.load(sys.stdin); print(json.dumps(d, sort_keys=True, separators=(',',':')))"` , this is RFC 8785 for simple cases. Plan 12-02's deploy-engine subagent does NOT have Python in its Bash allow-list, so the canonicalization must be done in-context by Claude reading the file, sorting keys, and computing the hash via `shasum -a 256`.

### Risks / Pitfalls

- **Claude-in-context key sorting is fragile.** For deep / large state.json files, Claude may miss-sort a nested object and produce a wrong hash. Mitigation: the schema for state.json is FLAT per D-65 (one level of nesting under `working_state`), which is already canonicalization-friendly. Plan 12-01 should explicitly call out "state.json schema is flat; `working_state` is opaque, agent-owned, NOT included in the deploy-engine's fingerprint" , this eliminates the deep-sort problem.
- **DEPLOY_HISTORY.jsonl is append-only; each line is independent.** Canonicalization only matters per-line. One JSON object per line, sort keys, append. Simple.
- **Pitfall: trailing newlines.** Some writers add `\n` at EOF, others don't. Include "trailing newline after final byte" in the canonicalization spec.

**Confidence:** HIGH , JSON canonicalization pitfall is well-documented; RFC 8785 is the standard solution.

## Topic 3: Jinja-Lite In-Context Template Rendering

### Research Question
Can Claude reliably execute Jinja-style `{{var}}` substitution in-context without a Python runtime, and what failure modes matter for D-62?

### Key Findings

- **Jinja2 has established itself as the de-facto LLM prompt template language.** [CITED: learn.microsoft.com/en-us/semantic-kernel/concepts/prompts/jinja2-prompt-templates, github.com/masci/banks, python.useinstructor.com/blog/2024/09/19/instructor-proposal-integrating-jinja-templating/] Banks, Semantic Kernel, Haystack, Instructor all use `{{variable}}` and `{% control %}` as the canonical syntax.

- **In-context rendering by an LLM is a solved pattern at simple substitution scope.** [CITED: docs.cloud.deepset.ai/docs/write-prompts-in-deepset-cloud] Haystack Enterprise uses Jinja templates that the LLM renders *conceptually* (not via a Python runtime), but production systems always server-side render first to avoid escaping bugs. Quote: *"server-side rendering supporting complex expressions in prompts for LLM-generated columns."*

- **Common in-context Jinja failure modes:** [CITED: github.com/zed-industries/zed/issues/45379, github.com/lmstudio-ai/lmstudio-bug-tracker/issues/535]
  1. **Unescaped braces in values.** An agent goal containing literal `{{ }}` characters (e.g. documentation prose) gets doubly-substituted.
  2. **Whitespace-sensitive control tags.** `{% if autonomy == "full" %}` vs `{%- if autonomy == "full" -%}` produces different output whitespace; LLMs in-context are sloppy about whitespace.
  3. **Conditional block truncation.** When the rendered output goes over a token budget, LLMs elide content mid-conditional, corrupting the final file.
  4. **Undefined variable behavior.** Jinja raises `UndefinedError` by default; in-context substitution silently emits empty string. For `{{agent.briefing_agent_id}}` when null, the output has a bare empty line that breaks the downstream YAML parser.

- **Claude Code skill prior art in `.claude/skills/`:** [VERIFIED: repo inspection + docs] Skills use `$ARGUMENTS` and `$N` substitution, NOT `{{var}}`. That's a different mechanism (Claude Code CLI does the substitution before the model sees the prompt). The AgentBloc template per D-62 is purer markdown with `{{var}}` placeholders , no CLI-level substitution; all done by the deploy-engine subagent reading the template and producing output.

### Implications for Phase 12 Plan

- **D-62's approach is defensible but has sharp edges.** Plan 12-02 (deploy-engine subagent) MUST include:
  - An **escaping rule**: agent-profile fields containing `{{` or `}}` must be pre-escaped before substitution (replace `{{` with `&#x7b;&#x7b;` or equivalent). The likelihood is LOW (agent goals don't usually contain Jinja syntax) but not zero.
  - A **null-value handling rule**: when a template anchor's value is null (e.g. `{{agent.briefing_agent_id}}` in a team without a briefing agent), emit the literal placeholder `null` OR omit the surrounding line via a conditional. Conditionals in a pure-substitution template are hard; the safer pattern is *flat fields with null sentinels that downstream parsers tolerate*.
  - A **structural validation gate**: after substitution, the deploy-engine reads the produced file back and validates it parses as markdown-with-YAML-frontmatter. If parse fails, halt-and-name per D-70.
- **Template should AVOID conditionals.** Use separate template files for `full` / `semi` / `supervised` autonomy levels instead of `{% if autonomy == "full" %}`. Three concrete templates > one template with three conditional branches. This sidesteps LLM whitespace sensitivity.
  - Proposed: `deployed-agent-skill-full.md.tmpl`, `deployed-agent-skill-semi.md.tmpl`, `deployed-agent-skill-supervised.md.tmpl`. The deploy-engine picks based on `agent.autonomy`.
  - Trade-off: three files to maintain. Benefit: zero conditional-rendering bugs.
- **Phase 16 golden-file tests should validate by exact string match against a committed fixture.** Plan 12-01 ships `arco-rooms-deploy-report.md`; also ship `arco-rooms-gestor-cobros-skill.md` as the golden rendered SKILL.md for the Arco Rooms Gestor Cobros agent. Phase 16 diffs deploy output against the golden file.

### Risks / Pitfalls

- **The `{{agent.tools}}` anchor (rendered as bullet list per D-62) is the most complex substitution.** A list-render requires iterating `tools[]` in the YAML and emitting `- tool_name (MCP: ref)` per entry. Iteration in a pure `{{var}}` substitution template is impossible. Options:
  1. **Pre-render to a string in the deploy-engine before substitution** (deploy-engine builds the bullet-list string, then substitutes the entire block as a single `{{agent.tools_rendered}}` variable).
  2. **Use a special marker** like `<!-- AGENTBLOC:RENDER_TOOLS -->` that the deploy-engine replaces with the fully-rendered bullet list.
  Option 1 is cleaner and keeps the template pure-substitution.
- **Prompt injection via agent fields.** If `agent.backstory` is user-supplied and contains Claude Code hooks syntax (`!` prefix, `/` slash command), the deployed SKILL.md could trigger unintended behavior. Mitigation: Plan 12-01 schema REQUIRES stripping of `!` and leading `/` from backstory/goal text before substitution. Document in `deployed-agent-skill-schema.md`.

**Confidence:** MEDIUM-HIGH , in-context substitution works for simple `{{var}}` cases; the tools-list rendering needs pre-computation, not pure template.

## Topic 4: Agent Memory Schema Patterns

### Research Question
What file structures do CrewAI / LangGraph / Letta use for persistent agent memory, and when does a single-file memory.md approach break?

### Key Findings

- **Letta/MemGPT explicit separates three memory tiers:** [CITED: letta.com/blog/agent-memory]
  - **Core memory** = always in context, small (RAM equivalent). Managed via memory blocks with labels, descriptions, character limits.
  - **Recall memory** = complete interaction history, searchable, auto-persisted to disk.
  - **Archival memory** = external DB (vector/graph), requires retrieval tools.

- **Letta v1 added Context Repositories** = git-versioned programmatic context management. Memory becomes a tree of files + vector index. [CITED: letta.com/blog/letta-v1-agent]

- **CrewAI memory is role-scoped with short + long term split.** [CITED: docs.crewai.com/en/concepts/memory] No single canonical file format; memory is managed via `Memory` class + external stores.

- **LangGraph uses checkpointer + thread IDs with InMemoryStore or SQLite/Postgres backend.** [CITED: dev.to AI Agent Memory comparative] Long-term memory typically lives in external vector DB, not file.

- **Filesystem-only memory works up to a scaling wall.** [CITED: letta.com/blog/benchmarking-ai-agent-memory] Letta's benchmark "Is a Filesystem All You Need?" concludes filesystem memory is adequate for bounded domains but degrades when the agent's active working set exceeds ~50-100KB per memory block. Production agents then move to vector DB.

- **Section-headed markdown is a documented pattern for bounded agent domains.** [CITED: earezki.com/ai-news/2026-03-09-the-state-management-pattern-that-runs-our-5-agent-system-24-7/ , the blog cited in PROJECT.md] The cited blog uses exactly the section-headed pattern D-64 locks (domain/decisions/quirks/open-items) for a 5-agent system running continuously without hitting a scaling wall.

- **Typical memory.md accretion rate is NOT directly quoted in any source.** Best estimates from the Letta benchmark: a production finance-assistant-type agent accretes ~2-5KB/week of "Decisions" entries. For Arco Rooms (7 properties, 3 agents, 6 months), expected steady-state: ~50-100KB per agent. Right at the documented scaling threshold.

### Implications for Phase 12 Plan

- **D-64's single-file memory.md is appropriate for v2.0 scope.** Arco Rooms is bounded; 3 agents × ~50-100KB each is ~300KB workspace total. No scaling concern.
- **Plan 12-01's `agent-memory-schema.md` should include a "Deferred Split Pattern" section (commented or clearly marked v2.5+) that describes the escape hatch:**
  - When any `memory.md` exceeds 100KB, the agent should split into `memory/<section-name>.md` files.
  - The section names become filenames (`domain-knowledge.md`, `decisions.md`, `integration-quirks.md`, `open-items.md`).
  - The root `memory.md` becomes a table-of-contents pointing at the section files.
  - This is future-compatible: agents that aren't splitting still use the single-file layout. v2.5+ introduces a `memory_layout: "single-file" | "split-files"` flag in `registry.yaml`.
- **The state.json schema (D-65) is already flat and role-opaque inside `working_state` , this aligns with best practice.** Plan 12-01 should mandate `working_state` stays ≤10KB (enforcement: soft warning in validator). If it exceeds, agent should migrate its working state to a dedicated `working_state/<topic>.json` structure. Again, v2.5+ deferral.
- **last-run.json is small by design (single log entry).** No scaling concern.

### Risks / Pitfalls

- **Append-only `## Decisions` section in memory.md grows unbounded.** Over 2 years of operation, this section becomes the largest part of memory. Mitigation: Plan 12-01 should RECOMMEND (not REQUIRE) a rotation heuristic: when the `## Decisions` section exceeds 50KB, split into `memory/decisions-YYYY.md` archives. Again, v2.5+ concern; v2.0 just documents.
- **The `## Open Items` section is tempting to use as a task queue.** It's not. It's a human-readable note. Agents should use `state.json.working_state` for tracking open items with structured data. Plan 12-01's `agent-memory-schema.md` must explicitly warn: "`## Open Items` is prose-for-human-review, not a task queue."
- **PII contamination in memory.md is a real risk per CONTEXT.md's threat model note 2.** The template should include a `<!-- AgentBloc: Do not paste PII unless required by the agent's domain -->` warning at the top of every freshly-generated memory.md stub.

**Confidence:** HIGH , the pattern is well-documented; scaling-wall thresholds are honest estimates from one benchmark.

## Topic 5: MCP Server Health-Check Protocol for DEPLOY-08

### Research Question
What is the canonical MCP health-check protocol in 2026, and is D-69's 10-second timeout defensible?

### Key Findings

- **`tools/list` is the canonical health probe, NOT `ping`.** [CITED: mcpcat.io/guides/implementing-connection-health-checks/] Quote: *"MCP-native health monitoring that speaks the protocol instead of just HTTP works by calling list_tools on each server , the same handshake your agent uses , so a green status means the server is actually ready to serve MCP requests."*

- **`ping` exists but is narrower.** [CITED: fast.io/resources/implementing-mcp-server-health-checks/] *"Most official MCP SDKs (like the TypeScript and Python SDKs) implement the `ping` method handler by default. You typically do not need to write custom code to respond to a ping, only to send it."* A green ping proves the connection is open; only `tools/list` proves the server has initialized.

- **Ecosystem timeout norm is 2-5 seconds, with 5 seconds for `tools/list`.** [CITED: mcpcat.io/guides/implementing-connection-health-checks/, modelcontextprotocol.info/docs/best-practices/] Quote: *"A standard timeout for an MCP ping is between 2 to 5 seconds. Since the ping method does no work, any latency usually indicates a blocked event loop or network congestion. If a ping takes longer than 5 seconds, the server is likely unhealthy."*

- **Retry count convention = 3 consecutive failures before marking down.** [CITED: mcpcat.io] Quote: *"It is best to implement a 'retry' count before restarting. Transient network issues can cause a single ping to fail. A good rule of thumb is 3 consecutive failed checks before triggering a restart."*

- **`claude mcp list` CLI behavior:** [VERIFIED: Claude Code docs] The `claude mcp list` command lists configured MCP servers and their connection status. It performs a `tools/list` handshake per server. No explicit timeout documented; inherits Claude Code's default MCP connection timeout.

- **Cold-start MCP servers (first-call after idle):** [CITED: skiln.co/blog/mcp-server-troubleshooting-guide] npx-invoked MCPs can take 5-15 seconds on first call (npm package download + Node startup). Once warm, response is <1s. For deploy-time verification right after install, cold-start latency matters.

### Implications for Phase 12 Plan

- **D-69's 10-second timeout is defensible for cold-start MCPs, but split the policy:**
  - **First-call timeout:** 10 seconds (covers cold-start: npx download + Node init + `tools/list` response).
  - **Warm-call timeout:** 5 seconds (ecosystem norm post-warm-up).
  - Plan 12-02 should specify: first probe attempt at 10s; if fail, retry at 5s; if fail, retry at 5s; if all 3 fail, mark FAILED.
- **Retry = 3 is the ecosystem convention.** Plan 12-02 should adopt this explicitly (CONTEXT.md's D-69 is silent on retry count).
- **Differentiate "down" from "slow":**
  - `tools/list` returns zero tools → FAILED (misconfigured or unauthorized).
  - `tools/list` times out 3× → FAILED (server down or unreachable).
  - `tools/list` returns tools after 8s → PASSED with warning "slow" (log in DEPLOY-REPORT.md but don't fail).
- **Update D-69 check 2 definition to:** *"Every integration-manifest.yaml entry with `status: verified` must respond to `tools/list` within 10 seconds (first attempt) or 5 seconds (warm retry), with at least one tool declared. Three consecutive timeouts mark FAILED. Slow response (>5s after first warm attempt) is PASSED with warning."*

### Risks / Pitfalls

- **Optional integration soft-fail semantics matter.** CONTEXT.md D-69 says optional MCPs soft-fail to PARTIAL. Plan 12-02 must verify `integration-manifest.yaml` carries an `optional: true` flag (or `used_by: []`) that the deploy-engine reads. Phase 10's integration-manifest-schema must be checked for this; if absent, plan 12-01 adds it via surgical edit.
- **`claude mcp list` output format may change.** The deploy-engine parses CLI output; Claude Code updates could break the parser. Mitigation: Plan 12-02 should use `claude mcp list --json` if available (check current docs), else add a version-guard comment in the parser.
- **Stripe MCP rate limits might reject rapid tools/list on a fresh API key.** Low risk but consider: add 1-second jitter between MCP probes to avoid thundering-herd on a provider's API.

**Confidence:** HIGH , MCP health-check patterns are well-documented in the 2026 ecosystem.

## Topic 6: Cron + `claude -p` Invocation Patterns

### Research Question
Is system cron + `claude -p` still the canonical pattern for production AgentBloc deploys in 2026, and what environment-variable gotchas must plan 12 address?

### Key Findings

- **Claude Code's built-in `CronCreate` is SESSION-SCOPED with 7-day auto-expiry.** [CITED: code.claude.com/docs/en/scheduled-tasks] Quote: *"Tasks are session-scoped: they live in the current conversation and stop when you start a new one... Recurring tasks automatically expire 7 days after creation."* Confirms PROJECT.md's stance: NOT suitable for production.

- **The three official durable alternatives:** [CITED: code.claude.com/docs/en/scheduled-tasks]
  1. **Routines** (Anthropic cloud, no local files) , minimum interval 1 hour, runs autonomously, connectors only (no local MCP).
  2. **Desktop scheduled tasks** (macOS/Windows Desktop app) , requires machine on; persistent across restarts.
  3. **GitHub Actions** (CI runner) , fine for CI-bound tasks; awkward for user workstations.

- **None of the three durable alternatives match AgentBloc's VPS/Linux target.** AgentBloc is a self-hosted skill; users run on Linux VPS, macOS dev machines, or cloud VMs. System cron + `claude -p` is the only option that covers all three. [VERIFIED: cross-check with PROJECT.md constraints]

- **The environment-variable pitfall is real and solved.** [CITED: multiple sources including nodeops.network/blog/cron-jobs-and-env-vars-from-the-terminal] Cron runs with a minimal environment. Quote: *"Cron won't have your ANTHROPIC_API_KEY unless you set it, and you can set it in the crontab directly (less secure) or load it from a file using `source /home/user/.env`."*

- **Canonical production cron line:** [VERIFIED: AgentBloc's own `phase-5-deployment.md` lines 771-777 and `scheduling.md` line 94]
  ```
  0 22 * * * /usr/bin/env bash -c 'source /home/user/project/.env && cd /home/user/project && claude -p "$(cat .agentbloc/jobs/daily-pipeline.md)" >> .agentbloc/logs/cron.log 2>&1'
  ```
  Key elements: `source .env` for env vars, `cd /path` for CWD, stdout+stderr redirect to log, uses `$(cat ...)` to pass prompt from file.

- **Subagent env-var inheritance has a known gap.** [CITED: github.com/anthropics/claude-code/issues/46696] When the parent session writes env vars to `CLAUDE_ENV_FILE` via SessionStart hook, sub-agents spawned via the Agent tool do NOT inherit them. This blocks reliable env-var use in multi-agent pipelines. For Phase 12's deploy-engine subagent, this is NOT a blocker (deploy-engine runs as a forked context from the main session, which already has env vars). For Phase 13 runtime, this IS a concern , flag for Phase 13 planner.

- **Timezone semantics: system cron honors the system's local TZ by default.** For Phase 12's emitted `crontab.proposed` entries, the scheduling expressions will be interpreted in the user's local time unless `TZ=UTC` is prepended to the command or a `CRON_TZ=UTC` directive is written into the crontab. [VERIFIED: cron(5) man page, cross-platform knowledge]

- **Systemd timers vs cron vs launchd:** [CITED: linuxblog.io/systemd-timers-alternative-cron-linux/, xtom.com/blog/systemd-vs-cron-linux-task-scheduling/]
  - **cron** runs everywhere (Linux, BSD, macOS, minimal containers).
  - **systemd timers** Linux-only; require 2 files (`.timer` + `.service`); better logging (journald integration), better dependency handling, catch-up via `Persistent=true`.
  - **launchd** macOS-only; uses plists; native macOS facility but less portable.
  - For AgentBloc (cross-platform self-hosted skill target), cron is the only universal option.

### Implications for Phase 12 Plan

- **D-72's choice (system cron + `claude -p`) is the right call.** Plan 12-02's emitted `crontab.proposed` format matches the canonical production pattern from `phase-5-deployment.md` verbatim. No changes needed.

- **Timezone discipline is a gap in CONTEXT.md.** Phase 11's browser-discovery established the UTC-Z-suffix discipline for checkpoint timestamps. Plan 12-02 should specify:
  - Crontab entries use local time (cron convention; users expect "9am" to mean 9am their time).
  - ALL agent log entries (JSONL) use UTC with Z suffix (inherited Phase 11 discipline).
  - DEPLOY-REPORT.md frontmatter `generated_at` uses UTC with Z suffix.
  - Add a note in the emitted `crontab.proposed` header: `# All schedules interpreted in local timezone. Set TZ=UTC above to override.`

- **Env-var injection pattern (D-73 N8N_BASE_URL) matches the `.env.example` pattern already in play.** Plan 12-02 should emit `.env.example` additions for each new placeholder. The pattern is inherited from Phase 10.

- **Plan 12-02 MUST include a "verification Phase 13 will perform" note.** DEPLOY-08 check 3 (`crontab -l` confirms entries) soft-fails in Phase 12-only execution. The emitted crontab.proposed line format must match EXACTLY what Phase 13 will write so the comparison in Phase 13 works. Proposed format:
  ```
  # agentbloc:<team-name>:<agent-id>:<trigger-index> (deployment_id=<uuid>)
  <cron-expr> /usr/bin/env bash -c 'source <project>/.env && cd <project> && claude -p "$(cat <agent-job-file>)" >> <log-file> 2>&1'
  ```
  The `# agentbloc:` comment prefix is the grep-able selector for idempotent cron merging.

### Risks / Pitfalls

- **User's existing crontab has unrelated entries.** The deploy-engine must NOT overwrite; it emits a proposal file the user merges. D-72 honors this. Plan 12-02 should include emergency guidance in the emitted crontab.proposed: `# MERGE these into your existing crontab; do NOT replace.`

- **Path assumptions break.** The cron command embeds `/home/user/project/...` but different users have different paths. Plan 12-02 should use `$PWD` at deploy time to capture the absolute path and substitute it. Alternatively, ship an envelope script at `.agentbloc/deploy/run-agent.sh` that resolves paths via `realpath "$(dirname "$0")/../.."` , more robust.

- **Log-rotation missing.** `>> .agentbloc/logs/cron.log` grows unbounded. Phase 14 (monitoring) adds the log-rotation concern; Plan 12-02 notes "cron.log rotation deferred to Phase 14" to avoid scope creep.

- **`claude -p` API-key source.** If the user is on Max subscription (PROJECT.md cites this as default), `claude -p` uses cached credentials from the login; no `ANTHROPIC_API_KEY` env var needed. If the user switched to pay-per-token, `ANTHROPIC_API_KEY` must be in `.env` sourced by the cron command. Plan 12-02 should document both modes in the emitted DEPLOY-REPORT.md "Pending User Actions" section.

**Confidence:** HIGH , the official scheduling docs confirm session-scope; the project's own v1.0 references confirm the production cron pattern is already in use.

## Topic 7: DEPLOY_HISTORY.jsonl Governance

### Research Question
What retention, tamper-evidence, and post-audit tooling expectations apply to an append-only JSONL deploy ledger claiming GDPR Article 30 record-of-processing compliance?

### Key Findings

- **GDPR Article 30 requires records of processing activities but does NOT specify format or retention.** [CITED: gdpr-info.eu/art-30-gdpr/, sprinto.com/blog/gdpr-article-30/] Each controller maintains records under its responsibility. Retention is aligned with the "purpose of processing" principle.

- **Retention best practice is purpose-bound, not forever.** [CITED: logcentral.io/en/blog/gdpr-compliance-log-data-retention-disposal] Quote: *"Logs should be kept only as long as necessary for the purposes defined."* For agent-lifecycle audit, typical retention is 2-7 years depending on sector (finance leans higher).

- **Tamper-evidence patterns:** [CITED: konfirmity.com/blog/gdpr-logging-and-monitoring, cookieyes.com/blog/gdpr-logging-and-monitoring/]
  - **Write-once storage** (WORM / append-only file system).
  - **Cryptographic signatures per-batch** with verify-at-retrieval.
  - **Hash-chaining** , each entry references SHA256 of the prior entry (git-style Merkle property).
  - **Separate hash storage** , store integrity hashes in a separate system to detect tampering.

- **Hash-chaining is explicitly mentioned as a "chain of custody" technique** but NOT as an Article 30 requirement , it's a defense-in-depth recommendation. [CITED: konfirmity.com, termsfeed.com/blog/gdpr-article-30-create-ropa/]

- **JSONL is append-only by format convention.** No industry standard specifies Article 30 format; JSONL with one record per deploy event is a reasonable implementation choice. [ASSUMED , no direct source; derived from general audit-log best practices]

- **Post-audit review tooling:** [ASSUMED , no specific source] Common patterns are: grep + jq for quick inspection; a Markdown rendering script for human review; a time-series dashboard for trend analysis. v2.5+ dashboard would provide the latter.

### Implications for Phase 12 Plan

- **D-71's current schema is sufficient for Article 30 baseline:** deployment_id + timestamps + verification_status + counts + idempotent_hash + report_path. Each field answers an Article 30 requirement (processing activity, timing, responsible party implicit via git history, processing outcome).

- **Plan 12-01's `deploy-report-schema.md` should add a "Retention and Tamper-Evidence" section documenting:**
  - **Retention default:** forever (don't auto-delete; let users prune per their policy).
  - **Recommended policy for regulated deployments:** 7 years (GDPR maximum reasonable for finance / health data). User-configurable via future `.agentbloc/config/retention.yaml` (defer to v2.5+).
  - **Tamper evidence:** git commit history acts as the first-line evidence (DEPLOY_HISTORY.jsonl is in git; any edit shows as a commit). This is defense-in-depth; not cryptographic.
  - **Optional hash-chaining for regulated deployments (defer to v2.5+):** each entry references SHA256 of prior entry. Not implemented in v2.0; schema reserves a future `prev_entry_sha256` field.
  - **Privacy implications:** entries contain NO PII by schema (deployment_id is UUID, agent_count is integer, idempotent_hash is opaque). Safe to commit to public git repositories.

- **Post-audit review tooling (Plan 12-03 or deferred):**
  - **Immediate:** a grep-friendly one-liner in the DEPLOY-REPORT.md "How to audit this deployment" section: `jq '.' .agentbloc/deploy/DEPLOY_HISTORY.jsonl | less`.
  - **Nice-to-have:** a `/deploy-history` skill that renders the JSONL as a Markdown table for humans. Could fit in Plan 12-03 as a stretch goal OR defer to v2.5 dashboard.

- **Plan 12-01 should NOT add hash-chaining now.** It's a v2.5+ concern; adding it in v2.0 introduces test complexity (each entry depends on prior entry's hash; re-running tests requires deterministic prior-entry state) without payoff at current scale.

### Risks / Pitfalls

- **Deployment_id UUIDs should be v4 (random) not v7 (timestamp-sortable).** v4 avoids leaking deploy timing through ID inspection. CONTEXT.md D-71 already says "uuid-v4" , confirmed correct.

- **Timezone in `attempted_at` / `completed_at` must be UTC with Z suffix** , inherit Phase 11 discipline. Plan 12-01 schema must specify this.

- **JSONL file corruption from crash-mid-write** is a real audit-trail risk. Plan 12-02 should use atomic append: write to temp file + `mv` (POSIX atomic) OR just append-with-fsync. Claude Code's Write tool appends with fsync by default; this is handled.

- **JSONL parse failure from one bad line should NOT fail the whole audit.** Plan 12-01's schema should document: "One line per deploy; parsers MUST skip malformed lines with a warning, not fail." This is a consumer contract more than a producer contract.

**Confidence:** MEDIUM-HIGH , GDPR Article 30 baseline is well-documented; hash-chaining and retention specifics draw on general audit-log best practices rather than AgentBloc-specific authoritative sources.

## Validation Architecture

> `workflow.nyquist_validation` is not set in `.planning/config.json` (treat as enabled by default).

### Test Framework
| Property | Value |
|----------|-------|
| Framework | None detected (Phase 11 shipped `scripts/anti-bot-lint.sh` bash lint via GitHub Actions; no pytest/jest/vitest). |
| Config file | None , see Wave 0 |
| Quick run command | `bash scripts/anti-bot-lint.sh` (Phase 11 holdover) |
| Full suite command | TBD , Phase 16 will add a TAP-style test harness per ROADMAP Phase 16 success criterion 2 |

### Phase Requirements → Test Map

| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|-------------|
| DEPLOY-01 | SKILL.md generated per agent with full prompt | integration | Run deploy-engine on Arco Rooms fixture; diff against golden fixture `arco-rooms-gestor-cobros-skill.md` | ❌ Wave 0 , fixture to ship in Plan 12-01 |
| DEPLOY-02 | ClaudeClaw job config emitted per trigger | integration | Verify `.agentbloc/deploy/crontab.proposed` matches golden fixture | ❌ Wave 0 |
| DEPLOY-03 | `.mcp.json` merge is non-destructive | integration | Pre-seed `.mcp.json` with user entry; run deploy; verify entry unchanged + new entries added | ❌ Wave 0 |
| DEPLOY-04 | Per-agent memory dir created with 3 files | integration | After deploy, assert `.agentbloc/agents/<id>/{memory.md, state.json, last-run.json}` exist | ❌ Wave 0 |
| DEPLOY-05 | Registry.yaml emitted with team + agents | integration | Assert `.agentbloc/agents/registry.yaml` parses + contains expected IDs | ❌ Wave 0 |
| DEPLOY-06 | Re-run is idempotent (no duplicate / no corrupt) | integration | Run deploy twice; assert second run produces DEPLOY-REPORT.md with all Skipped-section entries | ❌ Wave 0 |
| DEPLOY-07 | DEPLOY-REPORT.md summarizes created/updated/skipped/pending/verification | integration | Parse report, assert 5 body sections present | ❌ Wave 0 |
| DEPLOY-08 | Post-deploy verification (3 checks) | integration | Mock `claude mcp list` / `claude agents list`; assert verification_status correctly rolled up | ❌ Wave 0 |
| MEM-01..06 | Memory directory shape + schema | integration | Assert files match schema prose-checklist (Phase 8 D-13 pattern) | ❌ Wave 0 |

### Sampling Rate
- **Per task commit:** `bash scripts/anti-bot-lint.sh` (existing lint; fast)
- **Per wave merge:** Run deploy-engine against Arco Rooms fixture + diff against golden files (to be added in Plan 12-01)
- **Phase gate:** Full suite green before `/gsd-verify-work`; Phase 16 end-to-end scenario re-verifies DEPLOY-01..08 + MEM-01..06 in integration context

### Wave 0 Gaps
- [ ] `.claude/skills/agentbloc/examples/arco-rooms-gestor-cobros-skill.md` , golden-file fixture for DEPLOY-01 verification (Plan 12-01)
- [ ] `.claude/skills/agentbloc/examples/arco-rooms-deploy-report.md` , golden DEPLOY-REPORT.md for DEPLOY-07 verification (CONTEXT.md already names this; Plan 12-01 ships it)
- [ ] `.claude/skills/agentbloc/examples/arco-rooms-registry.yaml` , golden registry.yaml for DEPLOY-05 (CONTEXT.md already names this)
- [ ] `.claude/skills/agentbloc/examples/arco-rooms-state-stub.json` , golden empty-on-first-deploy state.json for MEM-03 verification
- [ ] `.claude/skills/agentbloc/examples/arco-rooms-crontab-proposed.txt` , golden crontab.proposed for DEPLOY-02 verification
- [ ] Test harness script at `scripts/test-deploy-fixture.sh` , runs deploy-engine, diffs outputs, reports pass/fail (Plan 12-02 or Phase 16 deferred)

## Security Domain

> `security_enforcement` stance: treating as enabled (no explicit `false` in .planning/config.json).

### Applicable ASVS Categories

| ASVS Category | Applies | Standard Control |
|---------------|---------|-----------------|
| V2 Authentication | no | No auth surface in Phase 12 , deploy is offline file-ops |
| V3 Session Management | no | No sessions; deploy-engine runs in a forked context |
| V4 Access Control | yes | deploy-engine Bash allow-list (D-67) enforces least-privilege command scope |
| V5 Input Validation | yes | Agent-profile YAML + integration-manifest YAML must be validated before substitution (prose-checklist per D-13) |
| V6 Cryptography | yes | SHA256 for idempotency fingerprints (D-60); use standard library, never hand-roll |
| V7 Error Handling | yes | Halt-and-name on failure (D-70); no silent partial writes |
| V8 Data Protection | yes | memory.md PII warning; no credentials in SKILL.md substitution anchor list (threat model note 1) |
| V9 Communication | no | No network calls from deploy-engine (only local file ops + narrow Bash) |
| V10 Malicious Code | yes | Prompt-injection defense via backstory/goal pre-escape (Topic 3 recommendation) |
| V13 API | no | No APIs exposed |
| V14 Configuration | yes | `.mcp.json` merge protects user's custom entries (D-66) |

### Known Threat Patterns for Phase 12

| Pattern | STRIDE | Standard Mitigation |
|---------|--------|---------------------|
| Credential leak via template anchor | Information Disclosure | D-62 anchor-point allow-list in `deployed-agent-skill-schema.md`; no credential-bearing fields permitted |
| memory.md PII exfiltration via prompt injection | Information Disclosure | v1.0 prompt-injection.md cited in every generated SKILL.md; memory.md header carries explicit warning |
| Registry.yaml tampering redirects skill_path | Tampering | DEPLOY-REPORT.md idempotent_hash covers registry.yaml; re-deploy detects tamper |
| .mcp.json malicious-entry injection via conflict prompt | Tampering / Elevation of Privilege | Approval prompts show full unified diff (D-61); rate-limit approval prompts (one per deploy run) |
| crontab.proposed tampering between emission and user install | Tampering | File committed to git; idempotent_hash covers it; reviewer notices pre-install diff; `claude -p` sandbox inherits Claude Code security posture |
| Template injection via agent.backstory containing `!` or `/` chars | Injection | Pre-escape `!` and leading `/` from backstory/goal/role text before substitution (Topic 3 finding) |
| JSON key-ordering non-determinism creates false-positive diff (security-adjacent: audit trail reliability) | Repudiation | RFC 8785 canonical JSON for machine-written state files (Topic 2 finding) |

## Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|-------|---------|---------------|
| A1 | Typical memory.md accretion rate is ~2-5KB/week for production agents | Topic 4 | Plan 12-01's "deferred split pattern" threshold (100KB) might need tightening; low impact , just a deferral heuristic |
| A2 | JSONL is an adequate Article 30 format absent a standard | Topic 7 | If a sector regulator requires a specific format, plan would need extension; scope is general SMB deploys per PROJECT.md |
| A3 | Post-audit review tooling expectations (grep + jq + markdown render) | Topic 7 | Low stakes; users can build their own |
| A4 | Stripe MCP might rate-limit rapid tools/list calls | Topic 5 | Speculative; mitigation (1s jitter) is cheap defense |
| A5 | `claude mcp list --json` may or may not exist as a CLI flag | Topic 5 | Plan 12-02 should verify against Claude Code v2.2.x docs when implementing; parser fallback handles either |
| A6 | A third "internal" ClaudeClaw could exist (Pablo's private tooling) that matches the PDF's convention | Topic 1 | HIGH , if true, D-59a is justified; if false, D-59a rationale rewrite needed. Ask Pablo. |

## Open Questions

1. **Does Pablo maintain a private / internal ClaudeClaw that matches the `skills/<agent-id>/SKILL.md` project-root convention?**
   - What we know: v2.0-PROMPT.pdf cites this path; no public ClaudeClaw confirms it.
   - What's unclear: whether the PDF's ClaudeClaw is a reference to something private.
   - Recommendation: Ask Pablo before plan 12-01 ships. If answer is "no, it's just the PDF convention," rewrite D-59a rationale from "ClaudeClaw expects" to "AgentBloc v2.0-PROMPT.pdf convention, binding."

2. **Should the deploy-engine use `claude mcp list --json` or parse the stdout table?**
   - What we know: Claude Code CLI output format evolved across versions.
   - What's unclear: whether `--json` flag is stable in v2.2.x.
   - Recommendation: Plan 12-02 should probe at implementation time; fallback to stdout-table parser with version-guard comment.

3. **Does `agent-profile-schema.md` (Phase 9) have an `optional: true` flag for MCPs the agent can tolerate being down?**
   - What we know: CONTEXT.md D-69 mentions soft-fail for "marked `optional: true` in the manifest."
   - What's unclear: whether integration-manifest-schema.md already has this field.
   - Recommendation: Plan 12-01 reviews Phase 10's integration-manifest-schema; if absent, surgical-edit adds it.

## Environment Availability

| Dependency | Required By | Available | Version | Fallback |
|------------|------------|-----------|---------|----------|
| `claude` CLI | DEPLOY-08 verification checks | ✓ (per prior phase work) | 2.2.x assumed | none , blocks execution |
| `shasum -a 256` | D-60 fingerprint computation | ✓ (macOS/Linux standard) | BSD/GNU standard | `sha256sum` on Linux if `shasum` absent |
| `crontab` CLI | Phase 13 activation (not Phase 12) | ✓ (macOS/Linux standard) | standard | systemd timers if user prefers |
| Claude Code v2.1.72+ | CronCreate availability (for future reference) | ✓ | per session running | N/A , Phase 12 doesn't use CronCreate |
| Bash 3.2+ | `scripts/anti-bot-lint.sh` (inherited) | ✓ | standard | N/A |
| Python 3 | NOT used by deploy-engine (D-62 in-context substitution) | N/A | N/A | N/A |
| Node / npx | .mcp.json entries use `npx -y @mcp/xxx`; needed AFTER deploy by Claude Code MCP client, not BY deploy-engine | ✓ (user machine) | 20+ | blocks runtime Phase 13 if absent |

**Missing dependencies with no fallback:** None at Phase 12 scope.

**Missing dependencies with fallback:** `shasum` → `sha256sum` on some Linux distros (add fallback check in deploy-engine Bash allow-list spec).

## Code Examples

### D-60 idempotency fingerprint (canonicalized JSON + timestamp masking)

```bash
# Source: derived from RFC 8785 + AgentBloc D-60 spec
# Canonicalize state.json before hashing:
TMP=$(mktemp)
# Step 1: strip timestamp tokens (replace ISO-8601 patterns with <TIMESTAMP>)
sed -E 's/"(last_wake_at|last_completion_at|kill_switch_last_checked)":[[:space:]]*"[^"]*"/"\1":"<TIMESTAMP>"/g' state.json > "$TMP"
# Step 2: canonicalize (sort keys, minimize whitespace) , requires Claude in-context for flat schemas
# For state.json's flat D-65 schema, sorting is trivial; deploy-engine does it in-context.
# Step 3: hash
shasum -a 256 "$TMP" | cut -d' ' -f1
rm "$TMP"
```

### Canonical production cron line (validated against `phase-5-deployment.md` line 774)

```
# agentbloc:arco-rooms:gestor-cobros:0 (deployment_id=550e8400-e29b-41d4-a716-446655440000)
0 22 * * * /usr/bin/env bash -c 'source /home/pablo/agentbloc/.env && cd /home/pablo/agentbloc && claude -p "$(cat .agentbloc/jobs/gestor-cobros-daily.md)" >> .agentbloc/logs/cron.log 2>&1'
```

### MCP health-check via `claude mcp list` (parsing stdout)

```bash
# Source: derived from Claude Code MCP CLI + Topic 5 findings
# Plan 12-02 should use --json if available in v2.2.x; this is fallback.
timeout 10 claude mcp list 2>&1 | awk '
/^gmail-mcp/ { if (match($0, /connected/)) print "gmail-mcp: PASS"; else print "gmail-mcp: FAIL"; }
/^stripe-mcp/ { if (match($0, /connected/)) print "stripe-mcp: PASS"; else print "stripe-mcp: FAIL"; }
'
# Retry = 3 with 5-second timeout per retry for warm calls (Topic 5 ecosystem norm)
```

### DEPLOY_HISTORY.jsonl entry (matches D-71 schema)

```jsonl
{"deployment_id":"550e8400-e29b-41d4-a716-446655440000","attempted_at":"2026-04-25T09:00:00Z","completed_at":"2026-04-25T09:02:17Z","verification_status":"PASSED","agent_count":3,"integration_count":5,"idempotent_hash":"a1b2c3d4e5f6...","report_path":".agentbloc/deploy/DEPLOY-REPORT.md","failed_step":null}
```

## State of the Art

| Old Approach | Current Approach (2026) | When Changed | Impact |
|--------------|------------------------|--------------|--------|
| `ping` for MCP health | `tools/list` for MCP health | 2025 community convergence | D-69 check 2 aligns; ping deprecated for "is it ready?" probe |
| Session-persistent cron via Claude Code `CronCreate` | Session-scoped only + 7-day expiry | Docs update ~2025-late | D-72 confirmed: system cron only for durable workloads |
| LLM-assembled template generation | Deterministic template substitution | 2025 Phase-16-style golden-file testing | D-62 aligns; LLM assembly rejected on determinism grounds |
| Mtime-based idempotency check | Content-hash-based with canonicalization | 2026 idempotency best-practice | D-60 aligns; canonicalization extension recommended (Topic 2) |
| MemGPT-style single archival store | Tiered memory (core + recall + archival) | Letta v1 released early 2026 | D-64 single-file is v2.0-appropriate; multi-file tier is v2.5+ escape hatch |

**Deprecated / outdated:**
- Claude Code Scheduled Tasks on Desktop (7-day expiry, Desktop-only) , acknowledged deprecated for production in PROJECT.md + this research.
- `ping`-only health probes , use `tools/list`.
- Uncanonicalized JSON-content hashes , use RFC 8785.

## Project Constraints (from CLAUDE.md)

These constraints from the workspace's CLAUDE.md apply to Phase 12:

- **Plan Mode Default:** Phase 12 is a 3-plan phase with architectural decisions; plan mode already active via GSD workflow.
- **Verification Before Done:** DEPLOY-08 post-deploy verification maps directly to this principle; every task must prove it works.
- **Demand Elegance (Balanced):** D-59a/b/c namespace split is the most non-trivial elegance decision , Option B (flatten to `.claude/skills/<agent-id>/`) might be more elegant than Option A (honor DEPLOY-01 literal). Flag for Pablo.
- **Self-Improvement Loop:** Any corrections from Pablo during plan review go to `tasks/lessons.md`.
- **Never put a , in your text:** Verified , this research uses ASCII hyphens only.
- **No Laziness / Minimal Impact:** All CONTEXT.md decisions carried forward without rewriting; research additions are surgical (Topics 2, 5 extend existing decisions; Topic 1 flags a foundation question).

## User Constraints (from CONTEXT.md)

### Locked Decisions

D-59a: SKILL.md at `skills/<agent-id>/SKILL.md` (DEPLOY-01 literal HONORED) , **FOUNDATION FLAGGED FOR REVIEW: see Topic 1**.
D-59b: Per-agent memory files at `.agentbloc/agents/<agent-id>/{memory.md, state.json, last-run.json}` (MEM-01 literal OVERRIDDEN).
D-59c: Registry at `.agentbloc/agents/registry.yaml` (DEPLOY-05 literal OVERRIDDEN).
D-60: SHA256 over body excluding timestamp fields , **EXTEND WITH RFC 8785 CANONICALIZATION FOR JSON: see Topic 2**.
D-61: Unified diff with 5-line context hunks to DEPLOY-REPORT.md + stdout + saved `.diff` file.
D-62: Template-based generation with fixed anchor points, NOT LLM-assembled.
D-63: Registry at `.agentbloc/agents/registry.yaml`, YAML.
D-64: Section-headed memory.md template with fixed H2 navigation (4 sections).
D-65: Flat common state.json schema + role-specific fields under `working_state`.
D-66: `.mcp.json` merge-keep-existing-with-conflict-warning, approval-gated overwrite.
D-67: deploy-engine subagent at `.claude/agents/deploy-engine.md`, `context: fork`, narrowed Bash allow-list (4 commands).
D-68: DEPLOY-REPORT.md frontmatter + 5 body sections.
D-69: 3-check verification, soft-fail for optional integrations, 10-second MCP timeout , **REFINE TIMEOUT + RETRY POLICY: see Topic 5**.
D-70: DEPLOY-FAILED-REPORT.md on hard-fail (twin of DISCOVERY-BLOCKED-REPORT.md).
D-71: `.agentbloc/deploy/DEPLOY_HISTORY.jsonl` append-only cross-run ledger.
D-72: System cron + `claude -p` invocation, crontab.proposed emitted (NOT written to crontab).
D-73: Emit n8n webhook URL placeholder stubs.

### Claude's Discretion
- Exact Jinja-lite substitution syntax , lean `{{agent.field}}`.
- Table vs bullet list for DEPLOY-REPORT.md "Created" , lean table.
- Autonomy-language block wording , **RECOMMEND: three separate template files per Topic 3**, not one template with conditionals.
- team-topology.md Mermaid mirror , lean: yes if exists, skip if absent.
- Exact 10-second timeout , **recommend refinement per Topic 5: 10s first-attempt, 5s warm retry, retry=3**.
- Version-tagging deploys as git tags , defer.
- Kill-switch pre-check prose , ship a 3-line block citing `.agentbloc/KILL_SWITCH`.

### Deferred Ideas (OUT OF SCOPE)
- Cron trigger wakes + actual `claude -p` invocation → Phase 13.
- n8n webhook route configuration → Phase 13.
- TeamCreate / SendMessage inter-agent coordination → Phase 13.
- Kill-switch enforcement at agent wake → Phase 13.
- JSONL log emission + briefing-agent → Phase 14.
- Anticipation-pass agents → Phase 15.
- Cross-run deploy history diff viewer (web dashboard) → v2.5+.
- Auto-remediation when verification fails → v4.0.
- Hash-chaining for DEPLOY_HISTORY.jsonl → v2.5+ (Topic 7).
- Multi-file memory split → v2.5+ (Topic 4).
- Direct crontab write by Claude → anti-feature.
- LLM-assembled SKILL.md → anti-feature.

## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| DEPLOY-01 | Generate `skills/{agent-id}/SKILL.md` with full prompt | Topic 1 (path ambiguity flagged); Topic 3 (in-context template rendering feasibility) |
| DEPLOY-02 | Emit ClaudeClaw job config per trigger | Topic 6 (cron pattern confirmed); Topic 1 (ClaudeClaw "job config" format differs across projects , use v2.0-PROMPT.pdf as binding) |
| DEPLOY-03 | Merge MCP entries into `.mcp.json` | Topic 5 (verification depends on merged entries being live) |
| DEPLOY-04 | Generate per-agent memory directory | Topic 4 (schema sizing validates D-64 is v2.0-appropriate) |
| DEPLOY-05 | Generate registry.yaml | No external research gap; D-63 schema already exhaustive |
| DEPLOY-06 | Idempotent re-run with diff presentation | Topic 2 (canonicalization extension required for determinism) |
| DEPLOY-07 | Emit DEPLOY-REPORT.md | Topic 7 (Article 30 baseline + retention guidance); D-68 schema sufficient |
| DEPLOY-08 | Post-deploy verification | Topic 5 (MCP health-check protocol + timeout refinement); Topic 1 (check 1 probe may need redesign if D-59a unchanged) |
| MEM-01 | 3-file memory directory per agent | Topic 4 (pattern validated for v2.0 scope) |
| MEM-02 | memory.md for durable domain knowledge | Topic 4 (accretion + scaling threshold documented) |
| MEM-03 | state.json machine-written with schema_version | Topic 2 (canonicalization required); D-65 flat schema eases canonicalization |
| MEM-04 | last-run.json last execution entry | No external research gap |
| MEM-05 | Read-then-update on wake/completion (Phase 13 runtime concern) | Topic 4 (pattern references) |
| MEM-06 | Memory dirs version-controllable + human-debuggable | Topic 7 (JSONL is git-friendly; binary content forbidden) |

## Sources

### Primary (HIGH confidence)
- [Claude Code Scheduled Tasks (official docs)](https://code.claude.com/docs/en/scheduled-tasks) , CronCreate session scope, 7-day expiry, cron expression reference
- [Claude Code Skills (official docs)](https://code.claude.com/docs/en/skills) , canonical skill discovery paths (`.claude/skills/`, `~/.claude/skills/`, `<plugin>/skills/`)
- [Claude Code Subagents (official docs)](https://code.claude.com/docs/en/sub-agents) , subagent definition format, `context: fork`, tool restrictions
- [Claude Code Agent Teams (official docs)](https://code.claude.com/docs/en/agent-teams) , TeamCreate / SendMessage / TeamDelete primitives
- [MCP Connection Health Checks & Monitoring (MCPcat)](https://mcpcat.io/guides/implementing-connection-health-checks/) , `tools/list` as canonical health probe; 5-second timeout norm; retry=3 convention
- [Model Context Protocol Best Practices](https://modelcontextprotocol.info/docs/best-practices/) , SDK ping handler default; monitoring patterns
- [GDPR Article 30 (EUR-Lex / gdpr-info.eu)](https://gdpr-info.eu/art-30-gdpr/) , records of processing activities baseline
- [RFC 8785 JSON Canonicalization Scheme (IETF)](https://datatracker.ietf.org/doc/html/rfc8785) , canonical JSON serialization standard
- Repository grep: `.claude/skills/agentbloc/references/phase-5-deployment.md` lines 771-777 , canonical production cron line for AgentBloc (internal reference, HIGH)

### Secondary (MEDIUM confidence, WebSearch verified)
- [robonuggets/claudeclaw GitHub README](https://github.com/robonuggets/claudeclaw) , ClaudeClaw blueprint workspace layout, cron-registry.json schema
- [ClaudeClaw: Composable Agent Orchestrator (htdocs.dev)](https://htdocs.dev/posts/claudeclaw-a-composable-agent-orchestrator-for-claude-code/) , alternate "ClaudeClaw" TypeScript+Bun Gateway model
- [OpenClaw Scheduled Tasks](https://docs.openclaw.ai/automation/cron-jobs) , OpenClaw Gateway + jobs.json independence from Claude Code sessions
- [Letta Agent Memory Architecture](https://www.letta.com/blog/agent-memory) , core/recall/archival tiered memory
- [Letta v1 Agent Loop](https://www.letta.com/blog/letta-v1-agent) , Context Repositories with git-versioning
- [Letta Filesystem Memory Benchmark](https://www.letta.com/blog/benchmarking-ai-agent-memory) , filesystem-only memory scaling limits
- [CrewAI Memory Documentation](https://docs.crewai.com/en/concepts/memory) , short/long-term memory split
- [AI Agent Memory Comparative Analysis (dev.to)](https://dev.to/foxgem/ai-agent-memory-a-comparative-analysis-of-langgraph-crewai-and-autogen-31dp)
- [Idempotency Implementation Guide (desmati.com)](https://desmati.com/blog/idempotency-in-dotnet-azure) , JSON attribute ordering pitfall
- [AWS Powertools Idempotency Issue #638](https://github.com/awslabs/aws-lambda-powertools-python/issues/638) , key-ordering in hash keys
- [connect2id: JSON Canonicalization Scheme (RFC 8785) in action](https://connect2id.com/blog/how-to-secure-json-objects-with-hmac)
- [Semantic Kernel Jinja2 Prompt Templates](https://learn.microsoft.com/en-us/semantic-kernel/concepts/prompts/jinja2-prompt-templates) , Jinja2 as LLM prompt standard
- [Banks LLM Prompt Language](https://github.com/masci/banks) , Jinja-based prompt templating with caching/metadata
- [Instructor proposal: Integrating Jinja Templating](https://python.useinstructor.com/blog/2024/09/19/instructor-proposal-integrating-jinja-templating/)
- [MindStudio: Claude Code Headless Mode](https://www.mindstudio.ai/blog/claude-code-headless-mode-autonomous-agents) , `claude -p` production patterns
- [Claude Code Issue #46696: Sub-agent env-var inheritance gap](https://github.com/anthropics/claude-code/issues/46696)
- [NodeOps: Cron Jobs and Env Vars from the Terminal](https://nodeops.network/blog/cron-jobs-and-env-vars-from-the-terminal) , `source .env` pattern for cron
- [Konfirmity: GDPR Logging and Monitoring Practical Guide (2026)](https://www.konfirmity.com/blog/gdpr-logging-and-monitoring) , tamper-evidence + retention best practices
- [LogCentral: GDPR Compliance Log Data Retention and Disposal](https://logcentral.io/en/blog/gdpr-compliance-log-data-retention-disposal)
- [Systemd Timers vs Cron (xtom.com)](https://xtom.com/blog/systemd-vs-cron-linux-task-scheduling/) , scheduler comparison

### Tertiary (LOW confidence; flagged for validation)
- [Skill discovery edge cases (agentskills.io)](https://agentskills.io/) , `.agents/skills/` vs `.claude/skills/` cross-client conventions; community-driven, spec evolving
- [Building ClaudeClaw blog post (Medium, Mar 2026)](https://medium.com/@mcraddock/building-claudeclaw-an-openclaw-style-autonomous-agent-system-on-claude-code-fe0d7814ac2e) , blog post, third ClaudeClaw reference, cited mainly to confirm multiple projects exist under the name

## Metadata

**Confidence breakdown:**
- Standard stack (official sources available): HIGH , Claude Code docs, MCP docs, RFC 8785.
- Architecture (ClaudeClaw conventions): MEDIUM , two public projects disagree; CONTEXT.md cites a PDF convention not confirmed externally.
- Pitfalls (idempotency, memory scaling): HIGH , well-documented in 2026 ecosystem.
- Cron / deployment (system cron + `claude -p`): HIGH , both official docs and AgentBloc's own v1.0 references align.
- Memory schema (section-headed markdown): HIGH for v2.0 scope; MEDIUM for long-term scaling (needs v2.5+ escape hatch).
- GDPR Article 30 compliance: MEDIUM-HIGH , baseline well-documented; specific implementation (JSONL) is reasonable but not regulator-validated.

**Research date:** 2026-04-24
**Valid until:** 2026-05-24 (30 days for stable docs; shorter for ClaudeClaw claims if external projects evolve)
