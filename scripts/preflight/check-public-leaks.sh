#!/usr/bin/env bash
#
# check-public-leaks.sh — fail-fast guard against journal-voice leaks
# in evo-catalogue-schemas source. Same discipline as evo-core-eng
# and evo-device-audio, adapted to this repo's data-only layout
# (schemas/ + tools/ + top-level docs).

set -eo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "${REPO_ROOT}"

SCAN_PATHS=("schemas" "tools" "scripts")
SCAN_EXTS=("*.toml" "*.md" "*.sh" "*.json" "*.yaml" "*.yml")

INCLUDE_ARGS=()
for ext in "${SCAN_EXTS[@]}"; do
    INCLUDE_ARGS+=(--include="${ext}")
done

# The preflight script itself encodes the patterns it scans for;
# excluding it is the only way the script can co-exist with the gate.
EXCLUDE_ARGS=(
    "--exclude-dir=node_modules"
    "--exclude=check-public-leaks.sh"
)

EXISTING_PATHS=()
for path in "${SCAN_PATHS[@]}"; do
    if [[ -e "${path}" ]]; then
        EXISTING_PATHS+=("${path}")
    fi
done

# Also scan top-level docs.
TOP_LEVEL=("README.md" "CHANGELOG.md" "CONTRIBUTING.md")
for f in "${TOP_LEVEL[@]}"; do
    if [[ -f "${f}" ]]; then
        EXISTING_PATHS+=("${f}")
    fi
done

FAILURES=()

scan_pattern() {
    local label="$1" pattern="$2" matches
    matches=$(grep -rnE "${INCLUDE_ARGS[@]}" "${EXCLUDE_ARGS[@]}" "${pattern}" "${EXISTING_PATHS[@]}" 2>/dev/null || true)
    if [[ -n "${matches}" ]]; then
        FAILURES+=("=== ${label} ===")
        FAILURES+=("${matches}")
        FAILURES+=("")
    fi
}

scan_pattern "ADR identifiers in source (rewrite descriptively)" '\bADR-[0-9]{3,}\b'
scan_pattern "Engineering-side document filenames in source" '\b(SESSION_LOG|RISKS|PARKED_DECISIONS|V0\.[0-9]+\.[0-9]+_SCOPE|VENDOR_EXTENSION_OPTIONS)\b'
scan_pattern "Release-prep narrative term 'closure-debt' in source" 'closure-debt|closure debt'
scan_pattern "Buildout-phase identifiers (Phase X.Y) in source" 'Phase [0-9]+\.[A-Za-z0-9]+|Phase [A-Z]\.[0-9]+'
scan_pattern "Parked-decision identifiers (PD-NNN) in source" '\bPD-[0-9]+\b'
scan_pattern "Risk-register identifiers (R-NNN) in source" '\bR-[0-9]{3,}\b'
scan_pattern "GAPS document references in source" '\bGAPS\b'

if [[ ${#FAILURES[@]} -eq 0 ]]; then
    echo "public-leak check: clean."
    exit 0
fi

echo "PUBLIC-LEAK CHECK FAILED."
echo
printf '%s\n' "${FAILURES[@]}"
echo
echo "Run again after rewriting; the gate exits 0 only when zero hits."
exit 1
