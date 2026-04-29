#!/usr/bin/env bash
# Validate every shelf-schema TOML file in this repository.
#
# Used by CI (.github/workflows/validate.yml) and as a
# pre-merge sanity check.

set -euo pipefail

repo_root="$(cd "$(dirname "$0")/.." && pwd)"
schemas_dir="$repo_root/schemas/org.evoframework"

if [[ ! -d "$schemas_dir" ]]; then
    echo "error: schemas directory not found: $schemas_dir" >&2
    exit 1
fi

# Find every shape-schema file (excludes _rack.toml metadata
# files, which have a different shape).
mapfile -t schema_files < <(find "$schemas_dir" -type f -name '*.v*.toml' | sort)

if [[ ${#schema_files[@]} -eq 0 ]]; then
    echo "warning: no schema files found under $schemas_dir" >&2
    echo "         this is expected at v0.0.0 scaffolding;" >&2
    echo "         a minor release adds the worked-example schema" >&2
    exit 0
fi

failures=0
for schema in "${schema_files[@]}"; do
    rel="${schema#$repo_root/}"
    if "$repo_root/tools/validate.sh" "$schema"; then
        echo "ok: $rel"
    else
        echo "FAIL: $rel" >&2
        failures=$((failures + 1))
    fi
done

if [[ $failures -gt 0 ]]; then
    echo "" >&2
    echo "$failures schema file(s) failed validation" >&2
    exit 1
fi

echo ""
echo "all ${#schema_files[@]} schema file(s) validated successfully"
