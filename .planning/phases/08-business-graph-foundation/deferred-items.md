# Phase 8 Deferred Items

## 2026-04-21 (discovered during Plan 08-02 execution)

### [Out-of-scope, pre-existing] Untracked reference + example files in .claude/skills/agentbloc/

During 08-02 post-commit `git status` check, 21 reference files and 3 example files were observed untracked in `.claude/skills/agentbloc/`, including files the Phase 1 interview's Business Graph emission protocol depends on at runtime:

- `.claude/skills/agentbloc/references/data-classification.md` (referenced by phase-1-interview.md and SKILL.md unconditional load)
- `.claude/skills/agentbloc/references/blast-radius.md`
- `.claude/skills/agentbloc/references/audit-logging.md`
- `.claude/skills/agentbloc/references/credentials.md`
- `.claude/skills/agentbloc/references/frameworks.md`
- `.claude/skills/agentbloc/references/gdpr-patterns.md`
- `.claude/skills/agentbloc/references/glossary-en.md`
- `.claude/skills/agentbloc/references/glossary-es.md`
- `.claude/skills/agentbloc/references/incident-response.md`
- `.claude/skills/agentbloc/references/phase-2-design.md`
- `.claude/skills/agentbloc/references/phase-3-integration.md`
- `.claude/skills/agentbloc/references/phase-4-confirmation.md`
- `.claude/skills/agentbloc/references/phase-5-deployment.md`
- `.claude/skills/agentbloc/references/phase-6-evolution.md`
- `.claude/skills/agentbloc/references/prompt-injection.md`
- `.claude/skills/agentbloc/references/scheduling.md`
- `.claude/skills/agentbloc/references/telegram-patterns.md`
- `.claude/skills/agentbloc/references/tenant-isolation.md`
- `.claude/skills/agentbloc/examples/arco-rooms.md`
- `.claude/skills/agentbloc/examples/ecommerce-support.md`
- `.claude/skills/agentbloc/examples/freelance-pipeline.md`

**Status:** NOT caused by 08-02 changes. Pre-existing since before 08-01 (08-01 also did not commit these). Likely artifacts from the anonymized `main` orphan commit or a historical branch reset.

**Scope decision:** Out of scope for Plan 08-02 (deviation Rule SCOPE BOUNDARY). 08-02's action was strictly to modify `phase-1-interview.md` and `SKILL.md` and emit plan metadata -- touching these files would conflate unrelated fixes into this commit.

**Impact on 08-02 correctness:** None. The two files 08-02 modified are tracked; the commit history for both is intact (visible via `git log -- <path>`). The Phase 1 unconditional load list references `data-classification.md` (untracked) -- at runtime Claude reads from disk, so the skill works. But a fresh clone of the remote would be missing these files.

**Recommended follow-up (for a future Phase 16 release-polish or a dedicated hygiene plan):**
- Decide canonical state: either commit all 21 reference + 3 example files to align tracked tree with working tree, or add them to `.gitignore` if intentionally out-of-repo (unlikely given they are part of the skill).
- Audit the 17 png screenshots and AGENTBLOC_V2_PROMPT.pdf at repo root -- likely build artifacts that should be gitignored.

**Not blocking Phase 8 verification:** Phase 8 success criteria are about the *content* of the emission wiring, not about git-tracked-ness of the broader skill tree. All four ROADMAP SCs pass (verified in 08-02-SUMMARY.md).
