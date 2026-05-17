# `audio.composition` shape bump v1 → v2

## What couldn't be expressed in v1

Shape v1 modelled composition as a pure compose-and-emit
respondent: the plugin received a JSON pipeline description
(modules + templates), rendered them into an `asound.conf`
string, and returned the rendered text plus an MPD
`audio_output` snippet. The plugin never opened audio
endpoints; the framework never wired the rendered config
into a running pipeline. Shape v1 captured a Volumio-era
"compose and let someone else apply" division of work.

The framework's audio data plane has since taken substrate
ownership: composition plugins receive a typed
`CompositionEndpoints { input: ReadEndpoint, output: WriteEndpoint }`
pair via `LoadContext::audio_routing`, declare typed mode
lists with bit-perfect flags, and react to topology rewires
through a registered `RouteChangeCallback`. Audio bytes flow
through OS-native primitives (ALSA loopback, named pipe,
shared-memory region, JACK port) the framework selects per
topology — bytes never traverse SDK callbacks or wire
protocol.

Shape v1's contract has no surface for any of this: no mode
declaration, no endpoint surface, no route-change reaction,
no typed format negotiation. A plugin claiming v1 cannot
honour the framework's substrate; a plugin honouring the
substrate cannot describe itself in v1's vocabulary.

## What v2 adds

v2 aligns the shelf-of-record with the substrate the
framework already implements. Shape v2 plugins:

- declare `[capabilities.composition]` with `input_kind`,
  `output_kind`, a non-empty `modes` list, and a `default_mode`
- consume `LoadContext::audio_routing` at load time; refuse
  load loudly when the handle is `None`
- register a `RouteChangeCallback` and reopen endpoints on
  every framework-fired topology rewire
- expose one request type, `composition.select_mode`, that
  rotates the active composition mode against the declared
  list
- never serialise audio bytes onto SDK callbacks, request
  responses, or wire transports — bytes flow exclusively
  through the OS-native primitive identified by
  `composition_endpoints()`

The respondent surface stays narrow on purpose: the plugin's
primary work is the implicit byte-flow worker driving the
endpoints, not request/response chatter. The
`composition.select_mode` request exists so the framework's
reconciliation engine can tell the plugin which mode the
chain has selected; everything else is substrate-driven.

## Migration guidance

Plugins targeting v1 today emit `asound.conf` text. They
have no concept of mode declarations, no endpoint
consumption, and no route-change reaction. Migration is not
mechanical — it is a structural rewrite against the audio
data plane:

1. Replace the `request_types = ["alsa.pipeline.compose"]`
   declaration with `request_types = ["composition.select_mode"]`
   plus a `[capabilities.composition]` block declaring at
   least one mode (typically `passthrough` with
   `preserves_bit_perfect = true`).
2. Replace the JSON-pipeline-rendering request handler with
   a `composition.select_mode` validator that rotates the
   plugin's active mode and a worker task that drives the
   `composition_endpoints()` substrate.
3. Refuse load when `LoadContext::audio_routing` is `None`
   — composition plugins MUST receive an audio_routing
   handle, and absence indicates a manifest / trust
   misconfiguration.
4. Register a `RouteChangeCallback` in `load`; on every
   route change, close the old endpoints and reopen the new
   pair from `composition_endpoints()` at the new format.
5. Drop the `mpd_audio_output` projection — delivery is no
   longer a string the composition plugin emits; it is a
   downstream stage the framework configures per topology.

The reference plugin
`org.evoframework.composition.alsa` in evo-device-audio
ships the migrated shape against shape v2.

## Deprecation timeline

Shape v1 stays admittable through the catalogue's
`shape_supports` window for one minor release of evo-core
after v2 lands, then closes. Shape v1 ships no production
plugins outside the earlier reference; the migration
window exists for documentation completeness rather than
real-world plugin churn.
