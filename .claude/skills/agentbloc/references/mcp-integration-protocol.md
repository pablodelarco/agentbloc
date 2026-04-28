# MCP Integration Protocol

> Loaded by SKILL.md at Phase 3 entry alongside [phase-3-integration.md](phase-3-integration.md), [mcp-ecosystem-registry.md](mcp-ecosystem-registry.md), and [inventory-schema.md](inventory-schema.md). Defines the 4-step MCP search (existing `.mcp.json` -> ecosystem registry -> wrapper generation -> browser fallback) that Phase 3 walks for every tool entry in `.agentbloc/team/agent-profiles.yaml`, plus the three-check verification loop and halt-and-name protocol. Per v2.0 positioning (PROJECT.md Constraints), every external integration goes through an MCP server. Official-API direct calls are a fallback in [phase-3-integration.md](phase-3-integration.md), not the primary path.

## Table of Contents

- [When This Applies](#when-this-applies)
- [Step 1: Check Existing .mcp.json](#step-1-check-existing-mcpjson)
- [Step 2: Query Ecosystem Registry](#step-2-query-ecosystem-registry)
- [Step 3: Generate Wrapper via mcp-builder](#step-3-generate-wrapper-via-mcp-builder)
- [Step 4: Browser Fallback (Phase 11 Scope)](#step-4-browser-fallback-phase-11-scope)
- [Verification Loop](#verification-loop)
- [Halt-and-Name Protocol](#halt-and-name-protocol)
- [Evidence Protocol](#evidence-protocol)
- [Quick Reference](#quick-reference)

## When This Applies

Claude loads this file at Phase 3 entry (see SKILL.md Phase 3). For each tool declared in an agent's `tools[]` array in `.agentbloc/team/agent-profiles.yaml`, Claude walks Steps 1 through 4 in order, stops on the first method that resolves, and then runs the Verification Loop. The output is one entry per tool in `.agentbloc/integrations/inventory.yaml` (schema in [inventory-schema.md](inventory-schema.md)). Specific sections are referenced based on the tool's resolution state:

- **Fresh tool (first Phase 3 run):** walk Steps 1-4 in order; stop at first method that resolves.
- **Re-verification:** read existing manifest; re-run Verification Loop on every entry with `status != verified`.
- **Failed verification:** apply the Halt-and-Name Protocol; write `.agentbloc/integrations/<tool-id>/VERIFICATION-FAILED.md` per D-35; block Phase 3 gate until user resolves.

This file is imperative (step-by-step flow Claude follows); the registry ([mcp-ecosystem-registry.md](mcp-ecosystem-registry.md)) is declarative (lookup table Claude consults in Step 2); the schema ([inventory-schema.md](inventory-schema.md)) is the output contract. The three files together cover Phase 3 top to bottom.

## Flow Diagram

```
                           tool entry from agent-profiles.yaml
                                         │
                                         ▼
          ┌────────────────────────────────────────────────────┐
          │  Step 1: tool in .mcp.json?                        │
          │    YES ──────────────────────────┐                 │
          │    NO  ──► Step 2                │                 │
          └──────────────────────────────────┼─────────────────┘
                             │               │
                             ▼               │
          ┌──────────────────────────────────┼─────────────────┐
          │  Step 2: registry entry?         │                 │
          │    YES ──► propose npx           │                 │
          │            user approves ────────┤                 │
          │    NO  ──► Step 3                │                 │
          └──────────────────────────────────┼─────────────────┘
                             │               │
                             ▼               │
          ┌──────────────────────────────────┼─────────────────┐
          │  Step 3: mcp-builder wrap?       │                 │
          │    OK   ──► .mcp/generated/... ──┤                 │
          │    FAIL ──► Step 4 (Phase 11)    │                 │
          └──────────────────────────────────┼─────────────────┘
                                             │
                                             ▼
          ┌────────────────────────────────────────────────────┐
          │  Verification Loop (D-34)                          │
          │    Check 1 Ping        ─► FAIL ─► Halt-and-Name    │
          │    Check 2 Scope match ─► FAIL ─► Halt-and-Name    │
          │    Check 3 Shape probe ─► FAIL ─► Halt-and-Name    │
          │    All PASS ─► status: verified + healthcheck_at   │
          └────────────────────────────────────────────────────┘
                                             │
                                             ▼
                  .agentbloc/integrations/inventory.yaml
                                             │
                                             ▼
                        Phase 4 Precondition: every entry verified
```

Note on emission: use ASCII box characters (`┌ ┐ └ ┘ │ ─ ► ▼`) not Unicode em-dashes. The diagram must render correctly in a plain-text markdown viewer.

## Step 1: Check Existing .mcp.json

**Action:** Read `.mcp.json` (if present) and look for a top-level `mcpServers` entry whose key matches the agent's tool name (case-insensitive, hyphen/underscore normalized).

**Input:** `tools[].entry` from `.agentbloc/team/agent-profiles.yaml` (e.g., `playwright-mcp`, `google-workspace-mcp`).

**If found:**
- Write the manifest entry with `resolution_method: existing` per [inventory-schema.md](inventory-schema.md) Resolution Method Bounded Enum.
- Populate `mcp_server.package` from the `.mcp.json` entry's `command` or `args`; `installed_via: ".mcp.json existing"`.
- Skip directly to the Verification Loop below. Do NOT re-query the ecosystem registry or generate a wrapper.

**If not found:**
- Proceed to Step 2.

**Arco Rooms example:** `playwright-mcp` is already present in `.mcp.json` because gstack ships it. Phase 3 skips to verification for this tool.

**Rationale (D-31 + INTEG-01):** Steps 1-4 are ordered cheapest-to-most-expensive. Step 1 is free (a single file read). Always check before spending an ecosystem lookup or a wrapper generation.

## Step 2: Query Ecosystem Registry

**Action:** Consult [mcp-ecosystem-registry.md](mcp-ecosystem-registry.md) for an entry matching the agent's tool name. The registry is a curated list with trust tiers pre-computed per v1.0 INTG-04.

**Input:** Same tool name from Step 1 that did NOT resolve.

**If found in registry:**
1. Compute the `npx -y <package>` install command from the registry entry.
2. Present the command + trust_tier + evidence (URL, last_commit, publisher) to the user in the conversation.
3. Wait for explicit user approval ("yes" / "install" / "adelante").
4. On approval, write the MCP entry into `.mcp.json` via the Edit tool. Claude does NOT execute `npx` itself (D-37).
5. Tell the user: "Run this command in your shell: `npx -y <package>`, then say `installed` when done."
6. On user confirmation, write the manifest entry with `resolution_method: ecosystem`, `mcp_server.installed_via: "npx -y <package>"`, and proceed to the Verification Loop.

**If not found in registry:**
- Proceed to Step 3.

**Arco Rooms example:** `gmail-mcp` resolves to `@smithery-ai/gmail-mcp` in the registry; user approves the install; manifest entry records `resolution_method: ecosystem`.

**Rationale (D-37):** Claude never runs `npx` because arbitrary install scripts are a real supply-chain attack surface. `.mcp.json` is declarative config - safe for Claude to edit. The user runs the actual install in their own shell, preserving the auditable boundary.

## Step 3: Generate Wrapper via mcp-builder

**Action:** Invoke the `mcp-builder` skill (top-level skill at `.claude/skills/mcp-builder/`) with (a) the calling agent's `tools[].entry` + `outputs.schema` from `agent-profiles.yaml`, and (b) a public API spec URL or OpenAPI document the user provides.

**Input:** Tool name from Step 2 that did NOT resolve + URL of the target service's public API documentation.

**Process:**
1. mcp-builder reads the agent's tool entry and output schema to determine the minimum viable tool surface needed (D-33b least-privilege posture).
2. mcp-builder fetches the API spec via WebFetch and generates three files under `.mcp/generated/<tool-id>/`:
   - `package.json` (name + version + deps limited to `@modelcontextprotocol/sdk`)
   - `index.ts` (MCP server implementation with 1-N tool handlers matching the agent's needs)
   - `README.md` (what API it wraps, required env vars, tool surface documented inline)
3. mcp-builder returns the generated path + tool surface summary to the main session.
4. User runs `bun install` in `.mcp/generated/<tool-id>/` in their own shell.
5. Claude writes the manifest entry with `resolution_method: wrapper`, `mcp_server.package: ".mcp/generated/<tool-id>/"`, `mcp_server.installed_via: "wrapper"`, and proceeds to the Verification Loop.

**If mcp-builder fails** (API spec unresolvable, schema insufficient, forbidden scope):
- Proceed to Step 4.

**Arco Rooms example:** `bbva-mcp` has no ecosystem entry; mcp-builder generates a PSD2 wrapper at `.mcp/generated/bbva-mcp/` exposing exactly `list_transactions(since_iso)` and `get_balance()` - the only two calls Gestor Cobros needs. Full BBVA API surface is NOT exposed.

**Rationale (D-33 + D-33b):** TypeScript + `@modelcontextprotocol/sdk` + Bun matches ClaudeClaw runtime (PROJECT.md Constraints). Least-privilege tool surface means less attack surface and testable verification in Phase 10 (you can probe one tool; you cannot probe every API endpoint).

## Step 4: Browser Fallback (Phase 11 Scope)

**Action:** STUB - the browser-fallback subagent at `.claude/agents/browser-discovery.md` is Phase 11 (BROWSER-01..12) work. Phase 10 records the resolution_method enum value `browser-fallback` in [inventory-schema.md](inventory-schema.md) for forward compatibility, but the actual Playwright + Patchright + HAR capture + injection detector + PII redaction flow is NOT implemented here.

**If Steps 1-3 all failed:**
- Phase 10 treats this as a halt condition (no browser fallback yet).
- Write the manifest entry with `resolution_method: failed`, `status: failed`, `failure_reason: "browser-fallback (Phase 11) not yet available"`.
- Apply the Halt-and-Name Protocol below.
- The user can either (a) wait for Phase 11 to ship, (b) manually craft a wrapper and place it at `.mcp/generated/<tool-id>/`, or (c) remove the tool from the agent's `tools[]` and re-run Phase 2 Designer editing.

**Forward reference:** See [references/browser-fallback.md](browser-fallback.md) (forthcoming Phase 11) for the full protocol. This link is broken in Phase 10 - Phase 11 will create the file.

**Rationale (Phase boundary):** Scope lock per 10-CONTEXT.md § Out of scope. Browser-fallback is deferred explicitly; Phase 10 ships the 3 MCP paths plus a stub slot so Phase 11 can add the fourth without schema migration.

## Verification Loop

After a tool resolves via Step 1, 2, or 3, Claude runs three prose checks before stamping `status: verified` on the manifest entry. All three must PASS. Any FAIL triggers the Halt-and-Name Protocol.

**Check 1 - Ping (liveness)**
- Call `tools/list` on the MCP server. Confirm the server responds and declares at least one tool.
- FAIL: Set `status: failed`, `failure_reason: "server does not respond to tools/list"`, write VERIFICATION-FAILED.md per D-35.

**Check 2 - Scope match (authorization)**
- Confirm (a) the declared `tools_declared[]` intersects the agent's `tools[]` entry - the server exposes at least one tool the agent will actually use; AND (b) every required credential scope in `required_scopes[]` is present in `.env` OR the scope stub exists in `.env.example`.
- FAIL on missing scope: Auto-append the env var name to `.env.example` per D-38 with comment `# required by <agent-id> for <mcp-server> scope <scope-name>`, then halt with the specific missing var named in the conversation.
- FAIL on missing tool overlap: Surface "The <package> MCP does not expose the tool <agent-id> needs - proposed tools are <tools_declared>" and propose either reducing the agent's tool list or switching to Step 3 (wrapper) for the missing tool.
- Credential scope conventions live in [credentials.md](credentials.md).

**Check 3 - Shape probe (correctness)**
- Call the target tool with a dry-run argument set (a minimal argument the server will accept).
- Compare the response shape to the agent's `outputs.schema` in agent-profiles.yaml.
- FAIL: Surface BOTH shapes (declared vs observed) side-by-side in the conversation with the specific field mismatches quoted. Do not silently degrade.

**All three PASS:**
- Stamp `evidence.healthcheck_at` with the current ISO-8601 timestamp.
- Populate `evidence.tools_declared[]` from the `tools/list` result.
- Populate `evidence.required_scopes[]` from the server's README or declared metadata.
- Set `status: verified` on the manifest entry.
- Move to the next tool in the agent's `tools[]` array.

## Halt-and-Name Protocol

When any Verification Loop check FAILS, Claude does the following in one turn:

1. Write `.agentbloc/integrations/<tool-id>/VERIFICATION-FAILED.md` with the failing check number, the quoted failure, and a one-paragraph recommended fix.
2. Update the manifest entry to `status: failed` and `failure_reason: <specific-check>` (e.g., `"Check 2: scope gmail.modify missing from GOOGLE_OAUTH_TOKEN"`).
3. Block the Phase 3 gate - set the state bar's gate field to `blocked` until the failure is resolved.
4. Surface a targeted conversation to the user naming the specific gap. Template:

> "The `<package>` server is installed but Check <N> failed: `<specific-failure>`. To resolve: (a) <primary-fix>, or (b) <alternative-fix>. Which do you prefer?"

**Example - scope missing:** "The `gmail-mcp` server is installed but the `GOOGLE_OAUTH_TOKEN` scope is missing `gmail.modify`. To resolve: (a) add that scope to your Google OAuth consent screen, or (b) reduce the agent's tool scope to read-only by removing `send_message` from `recepcionista.tools[]`. Which do you prefer?"

**Example - credential missing:** "The `bbva-mcp` wrapper needs `BBVA_PSD2_CLIENT_ID` and `BBVA_PSD2_CLIENT_SECRET` in your `.env` file. I've appended them to `.env.example` with inline comments. Add the real values and say `credentials added`, then I will re-run verification."

**Pipeline behavior:** The pipeline does NOT silently degrade or proceed with a partially-verified integration. The file at `VERIFICATION-FAILED.md` gives the user a paper trail they can share when asking support for help. Per INTEG-05, verification failures surface with the specific gap named.

**Resuming:** After the user resolves the gap (adds scope, adds credential, edits tool list), the main session re-runs the Verification Loop for just that tool. Other already-verified tools are NOT re-verified.

## Evidence Protocol

Every manifest entry must carry the v1.0 evidence record (INTG-03) plus four v2.0 MCP-specific fields (D-39). The v1.0 record is inherited verbatim from [phase-3-integration.md](phase-3-integration.md) Step 3; the v2.0 extensions are captured during the Verification Loop above.

**v1.0 record (inherited from INTG-03):**
- `evidence.url` - GitHub / npm / official docs URL for the MCP server
- `mcp_server.version` - package version or wrapper commit SHA
- `evidence.last_commit` - ISO-8601 date of the most recent repo commit
- `evidence.publisher` - npm publisher name, GitHub org, or vendor name
- `evidence.trust_tier` - HIGH / MEDIUM / LOW per v1.0 INTG-04 (criteria in [mcp-ecosystem-registry.md](mcp-ecosystem-registry.md) Trust Tier Criteria)

**v2.0 MCP-specific extensions (D-39):**
- `evidence.tools_declared[]` - result of the Check 1 `tools/list` probe
- `evidence.required_scopes[]` - credential scopes declared by the server or inferred from its README
- `evidence.healthcheck_at` - ISO-8601 timestamp when the three-check loop last passed
- `mcp_server.installed_via` - the `npx -y <package>` command (ecosystem), the path under `.mcp/generated/<tool-id>/` (wrapper), or `.mcp.json existing` (existing)

**Missing any REQUIRED field:**
- Mark the entry `[UNVERIFIED]` per v1.0 INTG-06 (inherited).
- `[UNVERIFIED]` entries can still be accepted if the user explicitly overrides.
- The manifest carries the `[UNVERIFIED]` flag forward so Phase 12 Deploy Pipeline surfaces it in `DEPLOY-REPORT.md`.

**Evidence protocol rules:**
- Never silently omit a field. Missing evidence is a data point the user needs to see.
- Trust tier drift is real. An MCP that was HIGH at verification time might drop to MEDIUM 6 months later; `healthcheck_at` + `trust_tier` give Phase 6 Evolution a signal to re-verify on cadence.
- The evidence record is the contract with Phase 12 (Deploy Pipeline). Phase 12's quality ceiling is determined by how complete this record is - every field is load-bearing.

## Quick Reference

- **Step 1:** existing `.mcp.json` entry - cheapest, check first.
- **Step 2:** ecosystem registry - user-approved `npx -y <package>` install; Claude edits `.mcp.json`, user runs the shell command (D-37).
- **Step 3:** wrapper via mcp-builder skill - TypeScript + `@modelcontextprotocol/sdk` + Bun, output at `.mcp/generated/<tool-id>/` with minimum viable tool surface (D-33b).
- **Step 4:** browser-fallback - Phase 11 scope; Phase 10 stubs the enum value and halts cleanly.
- **Verification (D-34):** three checks - Ping / Scope match / Shape probe. All must PASS before `status: verified`.
- **On failure (D-35):** write VERIFICATION-FAILED.md, block Phase 3 gate, name the specific gap in the conversation. No silent degradation (INTEG-05).
- **Evidence (D-39 extending INTG-03):** URL + version + last_commit + publisher + trust_tier + tools_declared + required_scopes + healthcheck_at. Missing any = `[UNVERIFIED]`.
- **Default on ambiguity:** `ecosystem` (Step 2). Ecosystem lookup is cheaper than wrapper generation.
- **Rule:** MCP-first (PROJECT.md Constraints). Every external integration goes through an MCP server; official-API direct calls are a fallback in [phase-3-integration.md](phase-3-integration.md), not the primary path.
- **Cross-reference:** Downstream consumers of `.agentbloc/integrations/inventory.yaml` are the Phase 12 Deploy Pipeline (renders the manifest into `.mcp.json` merges + ClaudeClaw job configs) and the Phase 16 TAP end-to-end tests (replays the Arco Rooms fixture). Both read from the same schema defined in [inventory-schema.md](inventory-schema.md).
