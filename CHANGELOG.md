# Changelog

All notable changes to this repository's catalogue schemas
are documented here. Format follows
[Keep a Changelog](https://keepachangelog.com/en/1.1.0/);
versioning follows [Semver](https://semver.org).

## [Unreleased]

### Added — `audio.library` v1 scan-progress live-emission contract (v0.2.0 candidate)

- `schemas/org.evoframework/audio/library.v1.toml` — expanded the `audio_library_scan_progress` subject description with the full watcher lifecycle: initial `phase = "scanning"` frame within one poll cadence, throttled emission at ~500 ms per frame while `status.updating_db` is `Some(job_id)`, exactly one terminal `phase = "complete"` frame carrying the final counts, sibling `audio_library_sources` + `audio_library_state` republish on terminal, empty envelope after ~2 s settle. Added `phase: "scanning" | "complete"` to the per-entry shape. Added `scan-progress-watcher-emits-throttled-scanning-then-explicit-terminal-frame` acceptance row pinning the emission cadence + terminal-frame discipline (silence after a scan trigger is a substrate defect, never the healthy shape) + the singleton-watcher-gate invariant. No shape bump — additive to the v1 schema. Reference plugin: `org.evoframework.playback.mpd` in evo-device-audio (module `scan_progress.rs`).

### Added — three missing reference-distribution shelves foot-locked (v0.2.0 candidate)

- `schemas/org.evoframework/audio/terminus.v1.toml` — `audio.terminus` shelf shape 1 (respondent; request_type `get_spectrum_frame`; subject `audio_playback_spectrum_frame`). Post-mixer audio-derived signal surface. Reference plugin: `org.evoframework.audio.terminus` in evo-device-audio (ALSA loopback capture + 256-bin mel-scale FFT + peak-hold + per-band onset detection + L/R correlation; transport-and-leader-gated emission preserves audio floor invariant).
- `schemas/org.evoframework/audio/dlna.v1.toml` — `audio.dlna` shelf shape 1 (respondent; 5 request_types covering `source.dlna.refresh` / `source.dlna.list` / `source.dlna.browse` / `source.dlna.resolve` / `play_now`). UPnP AV MediaServer discovery + ContentDirectory browse + DIDL-to-stream-URI resolution. Reference plugin: `org.evoframework.source.dlna` in evo-device-audio (SSDP discovery with 10-minute grace window; persistent discovered-server state; `dlna` URI scheme owner).
- `schemas/org.evoframework/system/kiosk.v1.toml` — `system.kiosk` shelf shape 1 (respondent; 8 request_types covering display rotation / touch calibration / launch-wizard / enable / brightness / sleep-timeout / sleep-inhibit-while-playing / read-back). On-glass kiosk display controls with `system_admin`-scoped writer verbs; persist-before-apply discipline with rollback on apply failure; async wizard-launch bridge. Reference plugin: `org.evoframework.system.kiosk` in evo-device-audio.
- `schemas/org.evoframework/audio/_rack.toml` — enumerate every audio shelf schema present in the directory (queue, playlist, favourites, library, delivery, dlna, terminus) alongside the four pre-existing entries. Rack manifest was missing seven shelves it already housed schemas for.
- `schemas/org.evoframework/system/_rack.toml` — add `kiosk` alongside `power` and `notifications`.

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
