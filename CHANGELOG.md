# Changelog

All notable changes to this repository's catalogue schemas
are documented here. Format follows
[Keep a Changelog](https://keepachangelog.com/en/1.1.0/);
versioning follows [Semver](https://semver.org).

## [Unreleased]

(Pending changes accumulate here until a maintainer tags a
release.)

## [0.1.0] — 2026-04-29

### Added

- Worked-example schema `schemas/org.evoframework/example/echo.v1.toml`
  describing the `example.echo` shelf shape v1: request type
  `echo`, opaque-bytes payload roundtrip, three acceptance
  criteria (roundtrip, empty-payload handling, manifest
  request_types allowlist discipline). This is the same
  worked-example the evo framework's in-tree skeleton at
  `dist/catalogue/schemas/example/` uses; both copies are
  kept in lockstep until a future minor release of this
  repository diverges them.

## [0.0.0] — 2026-04-29

### Added

- Repository scaffolding: README, LICENSE (Apache-2.0),
  CONTRIBUTING governance, this CHANGELOG, the
  `schemas/org.evoframework/` namespace directory, the
  `tools/` directory with `validate.sh` and `lint-all.sh`
  helpers, and the `.github/workflows/validate.yml` CI
  workflow.

[Unreleased]: https://github.com/foonerd/evo-catalogue-schemas/compare/v0.1.0...HEAD
[0.1.0]: https://github.com/foonerd/evo-catalogue-schemas/releases/tag/v0.1.0
[0.0.0]: https://github.com/foonerd/evo-catalogue-schemas/releases/tag/v0.0.0
