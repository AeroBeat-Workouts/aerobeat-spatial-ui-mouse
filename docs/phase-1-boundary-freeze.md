# Phase 1 Boundary Freeze

This repo is now frozen as the **mouse-driven spatial UI provider lane** in the AeroBeat spatial UI family.

## What this repo owns

`aerobeat-spatial-ui-mouse` is the home of the future concrete provider layer for desktop mouse interaction on projected/world-space UI surfaces.

That concrete provider lane is expected to own:

- mouse-source integration for spatial UI hosts
- world-hit / raycast target resolution for projected surfaces
- projected coordinate mapping into UI-space
- hover ownership, press ownership, and drag ownership for mouse-driven spatial surfaces
- publication into the existing AeroBeat UI interaction contract

## What this repo does **not** own

This Phase 1 slice explicitly prevents the repo from drifting into other ownership lanes.

It does **not** own:

- the canonical interaction contract
- event taxonomy, event classes, or the interaction bus
- the native 2D bridge path
- shared cross-provider spatial helper ownership
- extracted proof-scene implementation from `aerobeat-ui-kit-community`

## Dependency truth

This repo sits on top of:

- `aerobeat-input-core` — canonical contract owner
- `aerobeat-spatial-ui-core` — shared helper-layer owner

Those dependencies are represented in `.testbed/addons.jsonc`, while the runtime placeholder classes in `src/providers/mouse/` establish the concrete provider boundary without implementing real provider behavior yet.

## Phase 1 deliverables in this repo

This boundary-freeze slice adds only:

- placeholder mouse-provider classes
- explicit boundary documentation
- repo-local tests that guard the ownership line

It intentionally does **not** add extracted runtime behavior, hybrid proof logic, or native 2D bridge code.

## Follow-up phase

Real provider extraction belongs to the later implementation phase after the repo-family ownership boundary is fully frozen across the related repos.
