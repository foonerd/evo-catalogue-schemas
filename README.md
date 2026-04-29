# evo-catalogue-schemas

Versioned catalogue schemas for the evo framework's brand-neutral
shelves under the `org.evoframework.*` namespace.

## What this repository is

The evo framework's catalogue document declares racks, shelves,
subject types, and cardinality. Each shelf carries a **shape** —
the request types, payload shape, and acceptance criteria a
plugin satisfies when claiming to implement that shelf. This
repository hosts the per-shelf shape schemas as versioned TOML
files.

The framework's admission gate validates a plugin's manifest
against the catalogue document; the schemas in this repository
are what a plugin author reads to know what code contract that
admission gate translates to.

Schemas evolve at their own cadence — independent of the
framework's release cycle — so distributions and plugin
authors can pin a specific schemas version against their builds.

## Scope: brand-neutral framework-tier shelves only

This repository hosts schemas under the
**`org.evoframework.*`** namespace only. Distribution-specific
shelves (`com.<vendor>.*`) live in each distribution's own
schemas publication, not here. Brand-neutral shelves are
contracts shared across distributions: any audio reference,
any vendor distribution, any third-party plugin author can
implement them and expect the same admission semantics.

## Layout

```text
schemas/
└── org.evoframework/
    ├── <rack>/
    │   ├── _rack.toml                  # rack-level metadata (name, description, version)
    │   ├── <shelf>.v<N>.toml           # shape-N schema for this shelf
    │   └── <shelf>.v<N>.changes.md     # optional change-history pointer
    └── example/
        └── echo.v1.toml                # the worked-example reference
```

The `<rack>/<shelf>.v<N>.toml` naming convention matches the
naming the evo framework's `dist/catalogue/schemas/`
in-tree skeleton uses. See the schema files themselves for the
authoring conventions per shape.

## Versioning

Semver on the repository as a whole. One version line; the
repository is one product.

| Bump kind | When |
| --- | --- |
| Patch (vX.Y.z) | Additive: new shelves added; new acceptance criteria added to existing shapes. Acceptance criteria are documentation, not enforced; additions are non-breaking. |
| Minor (vX.y.0) | New shape versions added. Existing shapes stay present via the `shape_supports` discipline so plugins targeting the older shape continue to admit. |
| Major (vx.0.0) | A shape's semantic contract changes incompatibly. Rare; see CONTRIBUTING.md for the per-shape discussion process. |

CHANGELOG.md tracks the per-version log of changes.

## Consuming the schemas

### Plugin authors

Reference this repository's URL in your plugin's README; pin a
specific tag in your CI; validate your plugin locally before
shipping:

```sh
# Clone (or check out a pinned tag) into a known location.
git clone -b v0.1.0 https://github.com/foonerd/evo-catalogue-schemas /path/to/schemas

# Validate your plugin against the schemas (evo-plugin-tool from evo-core v0.1.12+).
evo-plugin-tool validate-shelf-schema \
  --schemas-path=/path/to/schemas/schemas \
  --plugin=path/to/your/plugin.toml
```

### Distribution packagers

Vendor distributions ship a separate package that installs the
schemas under `/usr/share/evo-catalogue-schemas/`. Example
Debian package recipe outline:

```text
Source:    evo-catalogue-schemas
Build:     cp -r schemas/ debian/<package>/usr/share/evo-catalogue-schemas/
Depends:   evo-core (>= <minimum-compatible-version>)
```

Consumers on the device then resolve the schemas via the
default `--schemas-path` cascade:

1. `--schemas-path` flag if passed
2. `$EVO_SCHEMAS_DIR` environment variable if set
3. `/usr/share/evo-catalogue-schemas/` if present
4. Error with guidance to install a schemas package or pass `--schemas-path`

### evo-core CI

evo-core's CI references this repository as a git submodule
pinned to the minimum-compatible version; runs
`evo-plugin-tool validate-shelf-schema` against the in-tree
worked-example to verify tool + schema agreement before
release.

## Repository governance

See [CONTRIBUTING.md](CONTRIBUTING.md) for:

- How to propose a new shelf shape.
- How to bump an existing shelf's shape version.
- The review process for additions and shape changes.
- Namespace ownership rules.

## License

Apache 2.0. See [LICENSE](LICENSE).
