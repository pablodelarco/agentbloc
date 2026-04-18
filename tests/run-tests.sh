#!/usr/bin/env bash
# tests/run-tests.sh - AgentBloc JSONL scenario test runner
# Validates scenario structure, fields, phase sequence, assertions, and SKILL.md references.
# Outputs TAP (Test Anything Protocol) format. Exit 0 = all pass, exit 1 = any failure.

set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
SCENARIOS_DIR="$SCRIPT_DIR/scenarios"

# TAP state
PASS=0
FAIL=0
TEST_NUM=0

# --- TAP helpers ---

tap_ok() {
    TEST_NUM=$((TEST_NUM + 1))
    PASS=$((PASS + 1))
    echo "ok $TEST_NUM - $1"
}

tap_not_ok() {
    TEST_NUM=$((TEST_NUM + 1))
    FAIL=$((FAIL + 1))
    echo "not ok $TEST_NUM - $1"
    if [ -n "${2:-}" ]; then
        echo "# $2"
    fi
}

# --- Validation functions ---

# Category 1: Structural - every line must be valid JSON
validate_json() {
    local file="$1"
    local name
    name="$(basename "$file")"
    local line_num=0
    local errors=0
    while IFS= read -r line; do
        line_num=$((line_num + 1))
        if ! echo "$line" | jq . > /dev/null 2>&1; then
            errors=$((errors + 1))
        fi
    done < "$file"
    if [ "$errors" -eq 0 ]; then
        tap_ok "$name: all $line_num lines are valid JSON"
    else
        tap_not_ok "$name: $errors of $line_num lines have invalid JSON"
    fi
}

# Category 2: Required fields per role
validate_fields() {
    local file="$1"
    local name
    name="$(basename "$file")"
    local errors=0
    local error_details=""
    local line_num=0
    while IFS= read -r line; do
        line_num=$((line_num + 1))
        local role
        role=$(echo "$line" | jq -r '.role // empty' 2>/dev/null)
        case "$role" in
            user|assistant)
                for field in content phase gate; do
                    if [ "$(echo "$line" | jq -r ".$field // empty" 2>/dev/null)" = "" ]; then
                        errors=$((errors + 1))
                        error_details="line $line_num missing $field"
                    fi
                done
                ;;
            assertion)
                for field in pattern context; do
                    if [ "$(echo "$line" | jq -r ".$field // empty" 2>/dev/null)" = "" ]; then
                        errors=$((errors + 1))
                        error_details="line $line_num missing $field"
                    fi
                done
                ;;
            "")
                errors=$((errors + 1))
                error_details="line $line_num missing role field"
                ;;
            *)
                errors=$((errors + 1))
                error_details="line $line_num has unknown role: $role"
                ;;
        esac
    done < "$file"
    if [ "$errors" -eq 0 ]; then
        tap_ok "$name: all required fields present"
    else
        tap_not_ok "$name: $errors field violations found" "Last issue: $error_details"
    fi
}

# Category 3: Phase sequence validation
validate_sequence() {
    local file="$1"
    local name
    name="$(basename "$file")"
    local errors=0
    local error_details=""
    local prev_phase=0
    local phases_seen=""
    local line_num=0

    while IFS= read -r line; do
        line_num=$((line_num + 1))
        local role
        role=$(echo "$line" | jq -r '.role // empty' 2>/dev/null)

        # Skip assertion lines - they don't have phase/gate
        if [ "$role" = "assertion" ]; then
            continue
        fi

        local phase
        phase=$(echo "$line" | jq -r '.phase // empty' 2>/dev/null)

        if [ -z "$phase" ]; then
            continue
        fi

        # Check non-decreasing order
        if [ "$phase" -lt "$prev_phase" ] 2>/dev/null; then
            errors=$((errors + 1))
            error_details="line $line_num: phase $phase appears after phase $prev_phase (must be non-decreasing)"
        fi

        prev_phase="$phase"

        # Track which phases we've seen
        if ! echo "$phases_seen" | grep -q "$phase"; then
            phases_seen="$phases_seen $phase"
        fi
    done < "$file"

    # Verify all 6 phases are present
    for p in 1 2 3 4 5 6; do
        if ! echo "$phases_seen" | grep -q "$p"; then
            errors=$((errors + 1))
            error_details="phase $p not found in scenario"
        fi
    done

    if [ "$errors" -eq 0 ]; then
        tap_ok "$name: phase sequence valid (1-6, non-decreasing)"
    else
        tap_not_ok "$name: phase sequence invalid" "Issue: $error_details"
    fi
}

# Category 4: Assertion pattern matching
validate_assertions() {
    local file="$1"
    local name
    name="$(basename "$file")"
    local last_assistant_content=""
    local line_num=0

    while IFS= read -r line; do
        line_num=$((line_num + 1))
        local role
        role=$(echo "$line" | jq -r '.role // empty' 2>/dev/null)

        if [ "$role" = "assistant" ]; then
            last_assistant_content=$(echo "$line" | jq -r '.content // empty' 2>/dev/null)
        elif [ "$role" = "assertion" ]; then
            local pattern context
            pattern=$(echo "$line" | jq -r '.pattern // empty' 2>/dev/null)
            context=$(echo "$line" | jq -r '.context // empty' 2>/dev/null)

            if [ -z "$pattern" ]; then
                tap_not_ok "$name: assertion at line $line_num has empty pattern"
                continue
            fi

            if echo "$last_assistant_content" | grep -qE "$pattern"; then
                tap_ok "$name: assertion \"$context\" matches"
            else
                tap_not_ok "$name: assertion \"$context\" does not match" "Expected pattern: /$pattern/"
            fi
        fi
    done < "$file"
}

# Category 5: SKILL.md reference file validation
validate_references() {
    local skill_file="$REPO_ROOT/SKILL.md"

    if [ ! -f "$skill_file" ]; then
        tap_not_ok "SKILL.md not found at $skill_file"
        return
    fi

    # Extract all relative paths matching references/*.md and examples/*.md
    local refs
    refs=$(grep -oE '(references/[a-zA-Z0-9_-]+\.md|examples/[a-zA-Z0-9_-]+\.md)' "$skill_file" | sort -u)

    if [ -z "$refs" ]; then
        tap_not_ok "SKILL.md: no reference file paths found"
        return
    fi

    while IFS= read -r ref; do
        local full_path="$REPO_ROOT/$ref"
        if [ -f "$full_path" ]; then
            tap_ok "SKILL.md ref: $ref exists"
        else
            tap_not_ok "SKILL.md ref: $ref missing" "Expected at: $full_path"
        fi
    done <<< "$refs"
}

# --- Main execution ---

echo "TAP version 13"

# Check for scenario files
scenario_files=("$SCENARIOS_DIR"/*.jsonl)
if [ ! -e "${scenario_files[0]}" ]; then
    tap_not_ok "no scenario files found in $SCENARIOS_DIR"
    echo "1..$TEST_NUM"
    exit 1
fi

# Run validations on each scenario file
for scenario in "$SCENARIOS_DIR"/*.jsonl; do
    validate_json "$scenario"
    validate_fields "$scenario"
    validate_sequence "$scenario"
    validate_assertions "$scenario"
done

# Run SKILL.md reference validation
validate_references

# Emit TAP plan at the end (allows dynamic count)
echo "1..$TEST_NUM"

# Summary as diagnostic
echo "# Tests: $TEST_NUM, Passed: $PASS, Failed: $FAIL"

# Exit code
if [ "$FAIL" -gt 0 ]; then
    exit 1
fi
exit 0
