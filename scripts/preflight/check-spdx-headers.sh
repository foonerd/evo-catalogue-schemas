#!/usr/bin/env bash
#
# check-spdx-headers.sh — preflight guard for the evo-catalogue-schemas
# IP posture. Refuses any committed schema TOML file lacking an
# SPDX-License-Identifier in the first five lines. Every schema
# in this repo is Apache-2.0 licensed.

set -euo pipefail

REPO_ROOT="${REPO_ROOT:-$(git rev-parse --show-toplevel)}"
cd "$REPO_ROOT"

readonly ALLOWED_LICENSE="Apache-2.0"

VIOLATIONS=()

while IFS= read -r f; do
    [[ -z "$f" ]] && continue
    [[ -f "$f" ]] || continue
    spdx=$(head -5 "$f" | grep -oE 'SPDX-License-Identifier: \S+' | head -1 | sed 's/^SPDX-License-Identifier: //' || true)
    if [[ -z "$spdx" ]]; then
        VIOLATIONS+=("MISSING_SPDX: $f")
        continue
    fi
    if [[ "$spdx" != "$ALLOWED_LICENSE" ]]; then
        VIOLATIONS+=("UNKNOWN_LICENSE: $f carries SPDX '$spdx' (allowed: $ALLOWED_LICENSE)")
    fi
done < <(git ls-files 'schemas/**/*.toml' 2>/dev/null || true)

if [[ ${#VIOLATIONS[@]} -eq 0 ]]; then
    echo "check-spdx-headers.sh: OK (no SPDX-header violations across schemas/)"
    exit 0
fi

echo "check-spdx-headers.sh: FAIL"
echo "Punch list (first 50):"
for v in "${VIOLATIONS[@]:0:50}"; do
    echo "  - $v"
done
if [[ ${#VIOLATIONS[@]} -gt 50 ]]; then
    echo "  ... and $((${#VIOLATIONS[@]} - 50)) more"
fi
echo
echo "Remediation:"
echo "  Prepend to the first line of each file:"
echo "    # SPDX-License-Identifier: Apache-2.0"
echo "    # Copyright (c) 2026 Just a Nerd"
echo "  Then re-run this preflight."

exit 1
