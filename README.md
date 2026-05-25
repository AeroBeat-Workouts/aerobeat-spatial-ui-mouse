# AeroBeat Spatial UI Mouse

`aerobeat-spatial-ui-mouse` is the AeroBeat repo for the **mouse-driven spatial UI provider** lane.

This package is the first concrete `aerobeat-spatial-ui-*` provider lane. It has now advanced past pure placeholder scaffolding into a **Phase 3 packaged-resolver slice**: reusable mouse hover/capture/publication logic for projected spatial surfaces wired to the shared packaged rect-target resolver.

## Current status

This repository now contains:

- explicit provider-lane runtime under `src/providers/mouse/`
- real mouse-provider lifecycle extraction for projected hover/press/capture continuity
- packaged `AeroSpatialRectTargetResolver` usage from `aerobeat-spatial-ui-core` with no provider-local rect fallback
- docs that pin `aerobeat-input-core` as the contract owner
- docs and runtime usage that pin `aerobeat-spatial-ui-core` as the shared helper-layer owner
- repo-local validation that guards against drift into contract ownership or native 2D bridge logic

The current extracted slice is intentionally narrow:

- **included now:** projected-target hover publication, mouse press ownership, capture continuity, and motion/release handling
- **still deferred:** world-ray acquisition ownership, native 2D bridge behavior, and scene-specific proof-host composition

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

## Runtime files

The current provider surface lives under:

- `src/providers/mouse/aero_spatial_ui_mouse_provider.gd`
- `src/providers/mouse/aero_spatial_ui_mouse_provider_config.gd`
- `src/providers/mouse/aero_spatial_ui_mouse_runtime_boundary.gd`

Key repo-local docs:

- `docs/phase-1-boundary-freeze.md`
- `docs/phase-2-first-mouse-provider-extraction.md`

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

This bootstrap step now restores both:

- external dependencies (`aerobeat-input-core`, `aerobeat-spatial-ui-core`, `gut`)
- this repo's own package mount under `res://addons/aerobeat-spatial-ui-mouse/` via the local-root GodotEnv symlink entry in `.testbed/addons.jsonc`

If you want the canonical workspace refresh path instead of calling `godotenv` directly, run:

```bash
/home/derrick/.openclaw/workspace/scripts/godotenv-sync --repo /home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-spatial-ui-mouse/.testbed
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

- `.testbed/addons.jsonc` is the committed dev/test dependency manifest, including the repo's own local-root self-mount entry for `aerobeat-spatial-ui-mouse`.
- `docs/phase-1-boundary-freeze.md` records the ownership line.
- `docs/phase-2-first-mouse-provider-extraction.md` records the first real extracted provider seam.
- Follow-up implementation work should cut current proof/reference hosts over to this provider instead of letting long-term mouse provider ownership remain in `aerobeat-ui-kit-community`.
- To catch installed-addon path regressions, refresh the hidden testbed from the manifest, verify `.testbed/addons/aerobeat-spatial-ui-mouse/` exists, then run the installed-addon smoke script so the packaged provider path is exercised end-to-end.
