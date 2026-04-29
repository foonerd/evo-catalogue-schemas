#!/usr/bin/env bash
# Validate a single shelf-schema TOML file.
#
# Usage:
#   ./tools/validate.sh schemas/org.evoframework/<rack>/<shelf>.v<N>.toml
#
# Requires `evo-plugin-tool` (from evo-core v0.1.12+) on PATH,
# or the path passed via $EVO_PLUGIN_TOOL environment variable.

set -euo pipefail

if [[ $# -ne 1 ]]; then
    echo "usage: $0 <path-to-schema.toml>" >&2
    exit 2
fi

schema_path="$1"

if [[ ! -f "$schema_path" ]]; then
    echo "error: schema file not found: $schema_path" >&2
    exit 1
fi

evo_plugin_tool="${EVO_PLUGIN_TOOL:-evo-plugin-tool}"

if ! command -v "$evo_plugin_tool" >/dev/null 2>&1; then
    echo "error: $evo_plugin_tool not found on PATH" >&2
    echo "       set EVO_PLUGIN_TOOL or install evo-core's evo-plugin-tool" >&2
    exit 127
fi

# Run the schema validation. validate-shelf-schema is shipped
# in evo-core v0.1.12+; older evo-core releases do not have
# this subcommand.
exec "$evo_plugin_tool" validate-shelf-schema --schema "$schema_path"
