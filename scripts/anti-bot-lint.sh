#!/usr/bin/env bash
#
# anti-bot-lint.sh
#
# Purpose: Enforce the nine-package anti-bot deny-list from
# .claude/skills/agentbloc/references/browser-stack.md by grepping
# every known manifest file in the repo for deny-listed package names.
#
# Exits 1 on first match with: "DENY-LIST VIOLATION: <pkg> found in <file>"
# Exits 0 on clean scan with: "anti-bot deny-list lint: clean"
#
# Runs in CI (.github/workflows/ci.yml) on every push and pull_request to main.
# Runs BEFORE any dependency install step so a poisoned manifest is caught
# before node_modules or .venv pollution.
#
# Cross-reference: references BROWSER-05 from REQUIREMENTS.md + D-48 + D-56
# from .planning/phases/11-integration-discovery-browser-fallback/11-CONTEXT.md.
#
# NO dependencies beyond POSIX bash + grep. Do NOT add node, jq, yq, or python.
#

set -euo pipefail

DENY=(
  "playwright-extra"
  "puppeteer-extra-plugin-stealth"
  "puppeteer-extra"
  "2captcha"
  "anticaptcha"
  "deathbycaptcha"
  "capsolver"
  "puppeteer-extra-plugin-anonymize-ua"
  "puppeteer-extra-plugin-user-preferences"
)

SCAN_FILES=(
  "package.json"
  ".mcp.json"
  "pyproject.toml"
  "requirements.txt"
  "Gemfile"
)

for file in "${SCAN_FILES[@]}"; do
  [ -f "$file" ] || continue
  for pkg in "${DENY[@]}"; do
    if grep -q "\"$pkg\"\|'$pkg'\|$pkg==" "$file" 2>/dev/null; then
      echo "DENY-LIST VIOLATION: $pkg found in $file"
      exit 1
    fi
  done
done

echo "anti-bot deny-list lint: clean"
