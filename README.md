# AeroBeat Spatial UI Mouse

`aerobeat-spatial-ui-mouse` is the AeroBeat repo for the **mouse-driven spatial UI provider** lane.

This package is the first concrete `aerobeat-spatial-ui-*` provider lane, but it is still in a **Phase 1 boundary-freeze** state. The current goal is to make the ownership line obvious in package structure, docs, and tests before any real provider behavior gets extracted.

## Phase 1 status

This repository now includes the minimal scaffolding needed to freeze its ownership boundary in code.

That currently means:

- explicit provider-lane placeholder classes under `src/providers/mouse/`
- docs that pin `aerobeat-input-core` as the contract owner
- docs and tests that pin `aerobeat-spatial-ui-core` as the shared helper-layer owner
- repo-local validation that guards against premature drift into contract ownership or native 2D bridge logic

Current non-goals for this phase:

- no extracted world-hit / raycast behavior yet
- no projected coordinate mapping implementation yet
- no hybrid proof extraction yet
- no canonical interaction contract definitions here
- no native 2D bridge logic here

## Planned responsibility boundary

`aerobeat-spatial-ui-mouse` is intended to own mouse-specific spatial UI provider behavior such as:

- desktop mouse source integration for spatial UI
- world-hit / raycast driven target resolution
- projected surface coordinate mapping
- hover ownership, press ownership, and drag behavior for spatial UI surfaces
- publishing normalized interaction semantics into the existing input contract

It is **not** intended to become:

- a second contract-definition repo
- the owner of the canonical interaction taxonomy
- the home of the native 2D bridge path
- the owner of shared cross-provider spatial helpers
- a grab-bag template for general gameplay input drivers

## Repository details

- **Type:** Spatial UI provider
- **License:** Mozilla Public License 2.0 (MPL 2.0)
- **Dependency truth:**
  - `aerobeat-input-core` owns the canonical UI interaction contract
  - `aerobeat-spatial-ui-core` owns shared spatial-provider helper scaffolding
  - `gut` drives repo-local validation

## Runtime scaffolding added in Phase 1

The current placeholder runtime surface lives under:

- `src/providers/mouse/aero_spatial_ui_mouse_provider.gd`
- `src/providers/mouse/aero_spatial_ui_mouse_provider_config.gd`
- `src/providers/mouse/aero_spatial_ui_mouse_runtime_boundary.gd`

These files exist to freeze the repo boundary only. They do **not** implement the real mouse provider yet.

## GodotEnv development flow

This repo follows the AeroBeat GodotEnv package convention.

- Canonical dev/test manifest: `.testbed/addons.jsonc`
- Installed dev/test addons: `.testbed/addons/`
- GodotEnv cache: `.testbed/.addons/`
- Hidden workbench project: `.testbed/project.godot`
- Repo-local unit tests: `.testbed/tests/`

The repo root remains the package boundary for downstream consumers. Direct development, smoke checks, and unit validation happen from the hidden `.testbed/` workbench.

### Restore dev/test dependencies

From the repo root:

```bash
cd .testbed
godotenv addons install
```

### Open the workbench

From the repo root:

```bash
godot --editor --path .testbed
```

### Import smoke check

From the repo root:

```bash
godot --headless --path .testbed --import
```

### Run unit tests

From the repo root:

```bash
godot --headless --path .testbed --script addons/gut/gut_cmdln.gd \
  -gdir=res://tests \
  -ginclude_subdirs \
  -gexit
```

## Validation notes

- `.testbed/addons.jsonc` is the committed dev/test dependency manifest.
- `docs/phase-1-boundary-freeze.md` is the repo-local boundary note for this slice.
- Follow-up implementation work should add actual provider behavior only after the broader architecture rollout proceeds beyond the boundary-freeze phase.
