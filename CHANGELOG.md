# Changelog

All notable changes to this repository's catalogue schemas
are documented here. Format follows
[Keep a Changelog](https://keepachangelog.com/en/1.1.0/);
versioning follows [Semver](https://semver.org).

## [Unreleased]

### Changed — artwork server ownership and the `artwork_url` scheme (v0.2.0 candidate)

- `schemas/org.evoframework/audio/playback.v1.toml` — the
  `now-playing-track-carries-artwork-url` row described the resolve
  endpoint as the framework's. It is a distribution HTTP surface,
  mounted by the distribution that ships artwork. The path is
  unchanged (`/api/v1/audio/artwork`), the dispatch-via-shelf and
  302-to-content-hash behaviour is unchanged; only the owner named in
  the contract is corrected.
- `schemas/org.evoframework/audio/library.v1.toml`,
  `playlist.v1.toml`, `favourites.v1.toml`, `queue.v1.toml` — these
  required `artwork_url` to be `scheme=mpd-path`. The shape is
  `scheme=<scheme>&value=<value>`: the scheme is envelope data chosen
  by the publisher, not a schema constant. `mpd-path` stays as the
  common example. Consumers MUST read the scheme from the URL rather
  than assume it. This makes the contract match shipped behaviour —
  publishers already emit other schemes for artist and directory
  targets, which the old MUST contradicted.
- `schemas/org.evoframework/artwork/providers.v1.toml` — stopped
  freezing `target.scheme` to `mpd-path` in the request shape; it is
  caller data, with an unrecognised scheme handled as a miss rather
  than an error. The content-hash GET
  (`/api/v1/audio/artwork/<content_hash>`) is named as a distribution
  contract rather than a framework endpoint; the hash itself is what
  this schema pins.

No shape bump — every change is to contract prose, not to any
declared envelope, request_type, or subject.


### Added — `audio.terminus` v1 spectrum-demand control plane (v0.2.0 candidate)

- `schemas/org.evoframework/audio/terminus.v1.toml` — declared the `audio.spectrum.set_demand` request-type + the `audio_playback_spectrum_demand` subject (addressing `evo.audio.playback:spectrum_demand`) + the `spectrum-demand-drives-producer-park-and-shape` acceptance row. The demand subject is the sole production-truth surface for the terminus producer; `enabled=false` MUST close the plugin's ALSA capture PCM (rig-verifiable via `lsof -p <pid>`), idle the outer capture loop, and stop `emit_frame`. Renderer-only fields (`preset`, `palette`, `color_mode`, `sensitivity_db`) MUST NOT reach the demand subject; the UI folds `preset=off` into `enabled=false` at the settings layer so `enabled` is the single production-truth field. `bins ∈ {32, 64, 128, 256}` and `channels ∈ {1, 2}` enums refused with structured Permanent outside the enum. `rate_hz_target` clamped `[1, 60]`. Apply path is the F1-A runtime bridge: evo-ui-runtime derives the demand-write from any `ui.visualizer.{enabled, bin_count, channel_mode}` settings patch and calls the verb — every settings origin inherits the demand-write by construction. No shape bump — additive to the v1 schema. Reference plugin: `org.evoframework.audio.terminus` in evo-device-audio (module `demand.rs` + living inventory `plugins/org.evoframework.audio.terminus/docs/SPECTRUM-DEMAND.md`).

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
