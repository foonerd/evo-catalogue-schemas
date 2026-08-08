# Changelog

All notable changes to this repository's catalogue schemas
are documented here. Format follows
[Keep a Changelog](https://keepachangelog.com/en/1.1.0/);
versioning follows [Semver](https://semver.org).

## [Unreleased]

### Added — `audio.library` v1 triage substrate (v0.2.0 candidate)

- `schemas/org.evoframework/audio/library.v1.toml` — added two `library.get_triage` / `library.reconcile_triage` request declarations, the `audio_library_triage` subject declaration under `[[subjects]]` with the full envelope + TriageFinding shape + wave-1 class-key catalogue, and one `library-triage-subject-published-on-load-and-every-sweep` acceptance row. No shape bump — additive to the v1 schema. Reference plugin: `org.evoframework.playback.mpd` in evo-device-audio (module `library_triage.rs` + living inventory `plugins/org.evoframework.playback.mpd/docs/LIBRARY-TRIAGE.md`).

### Filled in — `audio.playback` v1 contract closures (v0.2.0 candidate)

- `schemas/org.evoframework/audio/playback.v1.toml` — replaced the earlier `course_correct_verbs = ["tbd-review"]` placeholder with the documented contract from the reference plugin `org.evoframework.playback.mpd`: seven verbs (`play`, `pause`, `stop`, `next`, `previous`, `seek`, `set_volume`) with per-verb `payload_in` / `payload_out` shapes, plus two additional acceptance criteria covering payload-versioning-by-encoding and set_volume clamping. No shape bump — the v1 schema's verb list and payload contracts were always meant to be filled in once the reference plugin's contract stabilised; this is the closure of that placeholder.

### Added — `audio.composition` shape 2 (v0.2.0 candidate)

- `schemas/org.evoframework/audio/composition.v2.toml` — `audio.composition` shelf shape 2 (respondent; request_type `composition.select_mode`). Aligns the shelf-of-record with the framework's audio data plane: typed `[capabilities.composition]` declaration with `input_kind` / `output_kind` / `modes` / `default_mode`, `LoadContext::audio_routing` consumption for substrate-configured `CompositionEndpoints`, `RouteChangeCallback` reaction to topology rewires, mode-aware `preserves_bit_perfect` gating. Reference plugin: `org.evoframework.composition.alsa` in evo-device-audio (passthrough mode against ALSA loopback). Shape 1's `alsa.pipeline.compose` string-templating contract was an earlier abstraction superseded by the typed audio data plane; shape 1 remains historically published but is no longer the current shape.
- `schemas/org.evoframework/audio/_rack.toml` — `audio.composition` `current_shape` bumped from 1 to 2.

### Added — framework-tier shelves (v0.2.0 candidate)

- `schemas/org.evoframework/audio/_rack.toml` — audio rack metadata.
- `schemas/org.evoframework/audio/composition.v1.toml` — `audio.composition` shelf shape 1 (respondent; request_type `alsa.pipeline.compose`). Reference plugin: `org.evoframework.composition.alsa` in evo-device-audio.
- `schemas/org.evoframework/audio/playback.v1.toml` — `audio.playback` shelf shape 1 (warden; `course_correct_verbs` TBD pending plugin-author review). Reference plugin: `org.evoframework.playback.mpd`.
- `schemas/org.evoframework/artwork/_rack.toml` — artwork rack metadata.
- `schemas/org.evoframework/artwork/providers.v1.toml` — `artwork.providers` shelf shape 1 (respondent; request_type `artwork.resolve`). Reference plugin: `org.evoframework.artwork.local`.
- `schemas/org.evoframework/metadata/_rack.toml` — metadata rack metadata.
- `schemas/org.evoframework/metadata/providers.v1.toml` — `metadata.providers` shelf shape 1 (respondent; request_type `metadata.query`). Reference plugin: `org.evoframework.metadata.local`.
- `schemas/org.evoframework/networking/_rack.toml` — networking rack metadata.
- `schemas/org.evoframework/networking/link.v1.toml` — `networking.link` shelf shape 1 (respondent; 13 request_types covering status, scan, intent, captive-portal, security, flight-mode). Reference plugin: `org.evoframework.network.nm`.

### Notes

- All new shelves' `payload_in` / `payload_out` fields are marked `tbd-review` pending plugin-author review of each reference plugin's wire contract. The schemas declare the request_type / verb sets and acceptance criteria authoritatively; payload shapes refine in a v0.2.0 follow-up.
- These shelves correspond to the reference plugins shipped in evo-device-audio. The schemas-repo foot-locks to evo-core releases: every release that lands a new shelf MUST land its schema here.

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
