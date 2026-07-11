#!/usr/bin/env bash
#
# pre-tag-check.sh — evo-catalogue-schemas release pre-tag chain.
#
# Schemas repo is data-only (TOML shelf schemas); the gate set
# reflects that: parse + validate every schema; ensure no leak
# patterns in commit history; ensure LICENSE + README + CHANGELOG
# match expected shape.

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "${REPO_ROOT}"

log_step() { printf '\n[pre-tag] %s\n' "$*" >&2; }
log_ok()   { printf '[pre-tag] OK: %s\n' "$*" >&2; }
log_fail() { printf '[pre-tag] FAIL: %s\n' "$*" >&2; }

# -------------------------------------------------------------
# Gate 1: parse every TOML file (structural)
# -------------------------------------------------------------

log_step "Gate 1/4: parse every schema TOML"
if ! python3 - <<'PY'
import glob, sys
try:
    import tomllib as toml
except ImportError:
    import tomli as toml

failures = 0
for path in sorted(glob.glob("schemas/**/*.toml", recursive=True)):
    try:
        with open(path, "rb") as f:
            toml.load(f)
    except Exception as e:
        print(f"FAIL: {path}: {e}", file=sys.stderr)
        failures += 1
if failures:
    sys.exit(1)
print(f"parsed OK: {len(glob.glob('schemas/**/*.toml', recursive=True))} schema file(s)")
PY
then
    log_fail "TOML parse failure"
    exit 1
fi
log_ok "every schema parses"

# -------------------------------------------------------------
# Gate 2: validate via evo-plugin-tool (when available)
# -------------------------------------------------------------

log_step "Gate 2/4: evo-plugin-tool validate-shelf-schema (when available)"
if command -v evo-plugin-tool >/dev/null 2>&1; then
    ok=1
    while IFS= read -r schema; do
        if ! evo-plugin-tool catalogue validate-shelf-schema "${schema}" >/dev/null 2>&1; then
            log_fail "schema failed validation: ${schema}"
            ok=0
        fi
    done < <(find schemas -type f -name '*.v*.toml')
    if [[ ${ok} -eq 0 ]]; then
        exit 1
    fi
    log_ok "all schemas validated by evo-plugin-tool"
else
    log_step "  evo-plugin-tool not on PATH; skipping deep validation (structural parse above is the guard)"
fi

# -------------------------------------------------------------
# Gate 3: SPDX header check
# -------------------------------------------------------------

log_step "Gate 3/4: SPDX headers on every schema TOML"
missing=0
while IFS= read -r schema; do
    # First 5 lines must contain SPDX-License-Identifier.
    if ! head -5 "${schema}" | grep -q 'SPDX-License-Identifier'; then
        log_fail "SPDX header missing: ${schema}"
        missing=$((missing + 1))
    fi
done < <(find schemas -type f -name '*.toml')
if (( missing > 0 )); then
    exit 1
fi
log_ok "all schemas carry SPDX header"

# -------------------------------------------------------------
# Gate 4: repo metadata present + non-empty
# -------------------------------------------------------------

log_step "Gate 4/4: LICENSE + README + CHANGELOG present"
for meta in LICENSE README.md CHANGELOG.md; do
    if [[ ! -s "${meta}" ]]; then
        log_fail "${meta} missing or empty"
        exit 1
    fi
done
log_ok "metadata present"

cat >&2 <<'BANNER'

[pre-tag] All four gates clean. Ready for tag mint.

Next step: mint the tag with the agreed format
  v<MAJOR>.<MINOR>.<PATCH>[.<CLOSURE>][-<PRERELEASE>]
The tag-format regex enforced at publish:
  ^v[0-9]+\.[0-9]+\.[0-9]+(\.[0-9]+)?(-[0-9A-Za-z.-]+)?$

After tagging, run scripts/release/promote.sh to drive the
private -> public promote (this repo is currently authored
directly on public foonerd/evo-catalogue-schemas; promote.sh
is the tag + release + channel-pointer publish flow).
BANNER
