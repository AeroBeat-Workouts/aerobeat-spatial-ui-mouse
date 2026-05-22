# AeroBeat Spatial UI Mouse

`aerobeat-spatial-ui-mouse` is the AeroBeat repo for the **mouse-driven spatial UI provider** lane.

This package is planned to be the first concrete `aerobeat-spatial-ui-*` provider. Its long-term role is to turn desktop mouse interaction on projected/world-space UI surfaces into the shared AeroBeat UI interaction contract without redefining that contract.

## Phase 0 status

This repository is currently in **bootstrap cleanup**.

That means the repo identity, metadata, and testbed scaffolding have been aligned with the planned `spatial-ui-mouse` role, but the actual provider implementation is intentionally still pending.

Current non-goals for this phase:

- no feature extraction yet
- no world-hit / projection implementation yet
- no contract-bridge behavior yet
- no new provider logic yet

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
- a grab-bag template for general gameplay input drivers

## Repository details

- **Type:** Spatial UI provider
- **License:** Mozilla Public License 2.0 (MPL 2.0)
- **Planned shared dependencies:**
  - `aerobeat-input-core` for the canonical UI interaction contract
  - `aerobeat-spatial-ui-core` for shared spatial-provider helpers
  - `gut` for repo-local validation

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
- This Phase 0 slice only aligns naming, metadata, and testbed identity with the planned spatial UI mouse role.
- Follow-up implementation work should add actual provider code only after the broader architecture rollout proceeds beyond bootstrap cleanup.
