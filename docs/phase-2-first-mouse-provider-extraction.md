# Phase 2 First Mouse-Provider Extraction

This repo now contains the **first real extracted mouse-provider slice** for AeroBeat spatial UI.

## What landed in this slice

The extracted runtime seam is intentionally thin but real:

- mouse-specific hover enter/exit publication for projected spatial targets
- mouse press-owner / capture continuity for projected surfaces
- mouse motion publication that preserves press ownership while hover moves independently
- duplicate-release and motion button-mask-drop handling for desktop mouse continuity
- authored-space projected-data shaping on top of `aerobeat-spatial-ui-core` helpers

## What still stays outside this repo

This slice deliberately does **not** take ownership of:

- the canonical interaction contract or event taxonomy
- the native 2D bridge path
- shared cross-provider projection / resolver / hover-capture helpers
- scene-specific proof-host composition in `aerobeat-ui-kit-community`
- world-ray acquisition itself

For the current rollout step, the host still provides the already-acquired projected hit data. This repo owns the reusable **mouse-provider publication/capture lifecycle** built on top of that hit data.

## Dependency truth

This repo now depends on:

- `aerobeat-input-core` for the canonical contract and `HybridSubViewportInputAdapter`
- `aerobeat-spatial-ui-core` for authored-space projection helpers and neutral hover/capture bookkeeping

### Phase 3 packaged resolver cutover

The provider-local rect-target lookup fallback is now retired. `AeroSpatialUiMouseProvider` resolves targets through the packaged `AeroSpatialRectTargetResolver` helper from `aerobeat-spatial-ui-core`, and the repo now validates that path through a staged installed-addon smoke pass so downstream-style consumers exercise the same packaged resolver route.

## Why this slice is the right first extraction

The current hybrid proof host in `aerobeat-ui-kit-community` still contains both:

1. host-specific world-hit acquisition, and
2. reusable mouse-provider semantics.

Only the second category belongs here right now. Pulling just that slice keeps the provider reusable without prematurely hard-coding proof-scene camera/Area3D assumptions into the package.

## Expected follow-up

The next consumer cutover should replace the proof host’s local mouse hover/capture/publication logic with `AeroSpatialUiMouseProvider`, while leaving any truly proof-specific world-hit acquisition seam explicit until a later extraction pass generalizes it further.
