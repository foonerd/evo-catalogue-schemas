# Contributing to evo-catalogue-schemas

Thank you for your interest in contributing. This repository
hosts the brand-neutral catalogue schemas for the evo framework
under the `org.evoframework.*` namespace. Contributions to the
schemas — additions, shape bumps, acceptance-criteria edits —
follow the process below.

## Scope check before opening a PR

This repository accepts contributions only for the
`org.evoframework.*` namespace. Schemas for distribution-specific
namespaces (`com.<vendor>.*`) belong in the relevant
distribution's own schemas publication, not here. If you are
unsure whether a shelf is brand-neutral or vendor-specific,
open an issue describing the shelf's intended consumers
before authoring the schema PR.

## Types of contributions

### 1. Adding a new shelf shape

A new shelf — one that does not yet have a schema in this
repository — needs an initial v1 schema. The PR includes:

1. A new file at `schemas/org.evoframework/<rack>/<shelf>.v1.toml`.
2. A `_rack.toml` for the rack if one does not already exist.
3. A line in CHANGELOG.md under the next minor version's heading.
4. Optional: a `<shelf>.v1.changes.md` describing the design
   rationale (how the shape was derived, what alternatives
   were considered, why this contract).

The PR description must include:

- The intended consumer of the shelf (which distribution(s)
  expect to admit plugins claiming this shape).
- A reference to any prior public discussion of the shape
  (issue number, RFC, or similar).
- Examples of plugins that would implement this shape.

The reviewer's checklist:

- Schema follows the conventions in `tools/validate.sh`.
- `evo-plugin-tool catalogue lint` passes.
- Acceptance criteria are testable (each criterion describes
  observable behaviour, not implementation detail).
- Request types and payload shapes are defined precisely.

### 2. Bumping an existing shelf's shape version

When a shelf's shape needs an incompatible change (a new
required field, a removed field, a changed payload semantics),
add a NEW version file rather than editing the existing one:

```text
schemas/org.evoframework/<rack>/<shelf>.v2.toml    # NEW
schemas/org.evoframework/<rack>/<shelf>.v1.toml    # PRESERVED
schemas/org.evoframework/<rack>/<shelf>.v2.changes.md  # rationale
```

The catalogue's `shape_supports` discipline keeps the older
shape admittable during the migration window; consumers of the
older shape continue to admit. See the framework documentation
for the migration discipline (`CATALOGUE.md` §4.2 in evo-core).

The PR description must include:

- The reason for the shape bump (what couldn't be expressed
  in the older shape).
- Migration guidance for plugins targeting the older shape.
- The intended deprecation timeline (when does v1 stop being
  supported by the framework's `shape_supports` window).

### 3. Adding acceptance criteria to an existing shape

Adding a NEW acceptance criterion to an existing shape is
non-breaking: acceptance criteria are documentation; they are
not enforced at admission. Edit the existing
`<shelf>.v<N>.toml`, append the new `[[acceptance]]` block,
add a CHANGELOG.md entry under the next patch version's
heading.

Removing or modifying existing acceptance criteria is
breaking: it is a shape bump (case 2 above).

### 4. Repository hygiene

- Typo fixes, formatting corrections, README clarifications,
  CONTRIBUTING updates, CI workflow improvements — open a
  PR; reviewers move quickly on these.

## Versioning rules

This repository uses semver on the repo as a whole:

| Change | Version bump |
| --- | --- |
| Add a new shelf | Patch (vX.Y.z+1) |
| Add a new acceptance criterion to existing shape | Patch |
| Add a new shape version (v2 alongside v1) | Minor (vX.y+1.0) |
| Remove or incompatibly change an existing shape | Major (vx+1.0.0); rare |
| Documentation / CI / README changes only | Patch |

Tags are applied by maintainers after PR merge; do not include
tag bumps in the PR itself.

## Review process

1. Open the PR. CI runs `evo-plugin-tool catalogue lint` plus
   the per-shape validation pass against every changed file.
   PR cannot merge until CI passes.
2. At least one maintainer reviews. For new shelves and shape
   bumps, two maintainer approvals are recommended.
3. Maintainer rebases or squashes as appropriate.
4. After merge, a maintainer tags the next version per the
   table above and updates CHANGELOG.md if not already done
   in the PR.

## CI validation

The repository's CI (`.github/workflows/validate.yml`) runs:

```sh
./tools/lint-all.sh
```

which iterates every schema file and validates it via
`evo-plugin-tool`. PRs cannot merge if any schema fails
validation.

To validate locally before pushing:

```sh
./tools/validate.sh schemas/org.evoframework/<rack>/<shelf>.v<N>.toml
```

## Namespace ownership

The `org.evoframework.*` namespace is the brand-neutral
contract layer. Maintainers approve additions to this
namespace; vendor-specific schemas use the vendor's own
namespace and the vendor's own repository. If a shelf evolves
over time from vendor-specific to brand-neutral (multiple
distributions adopt it independently), the migration path is:

1. Open a discussion issue here proposing brand-neutral
   adoption.
2. Maintainers and adopting distributions discuss the contract
   shape.
3. A new schema PR adds the shelf under
   `org.evoframework.<rack>.<shelf>` (potentially with a
   different name / shape than the vendor original).
4. Vendor distributions update their plugins to target the
   new brand-neutral shelf at their own pace.

## License

By contributing to this repository, you agree that your
contributions are licensed under Apache-2.0, matching the
repository's [LICENSE](LICENSE).
