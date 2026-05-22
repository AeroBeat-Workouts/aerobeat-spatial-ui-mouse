# AeroBeat Input Driver Template

This is the official template for creating an **Input Driver** repository within the AeroBeat ecosystem.

An **Input Driver** turns device-specific signals into AeroBeat's shared input-lane contract. For the current AeroBeat v1 slice, the official gameplay path is **camera-first** for **Boxing** and **Flow**. Other device paths may still be worth preserving, but they should be documented truthfully as future/deprioritized work unless the specific repo is intentionally part of the live camera path.

## Current product truth

Use this template against the locked AeroBeat v1 scope:

- **official v1 gameplay:** Boxing and Flow
- **official v1 gameplay input:** camera only
- **current active input lane:** MediaPipe / camera-first
- **non-camera gameplay inputs:** future work, not current parity promises
- **mouse/touch:** valid for UI navigation, not gameplay parity claims

This template stays intentionally bounded to the input-driver contract itself. It should teach downstream repos to declare the lane-specific shared addon they actually build against instead of implying one broad “AeroBeat Core contract” or equal-status device parity across webcams, controllers, wearables, and XR.

## 📋 Repository Details

*   **Type:** Input Driver
*   **License:** **Mozilla Public License 2.0 (MPL 2.0)**
*   **Current baseline dependencies:**
    *   `aerobeat-input-core` (Canonical shared input contract)
    *   `gut` (Repo-local validation)
*   **Optional additions:**
    *   `aerobeat-vendor-*` or device-specific support packages when the concrete driver actually needs them

## GodotEnv development flow

This repo uses the AeroBeat GodotEnv package convention.

- Canonical dev/test manifest: `.testbed/addons.jsonc`
- Installed dev/test addons: `.testbed/addons/`
- GodotEnv cache: `.testbed/.addons/`
- Hidden workbench project: `.testbed/project.godot`
- Repo-local unit tests: `.testbed/tests/`

The repo root remains the package/published boundary for downstream consumers. Day-to-day development, debugging, and validation happen from the hidden `.testbed/` workbench using the pinned OpenClaw toolchain: Godot `4.6.2 stable standard`.

### Restore dev/test dependencies

From the repo root:

```bash
cd .testbed
godotenv addons install
```

That restores this repo's current dev/test manifest into `.testbed/addons/`. In the current lane-based architecture, input repos should describe their shared contract as `aerobeat-input-core`, not the older transition-era `aerobeat-core` key.

### Open the workbench

From the repo root:

```bash
godot --editor --path .testbed
```

Use this `.testbed/` project as the canonical direct-development and bugfinding surface for input-driver work.

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

### Validation notes

- `.testbed/addons.jsonc` is the committed dev/test dependency contract.
- The current template baseline intentionally pins only the lane-scoped shared contract needed for generic input-driver work: `aerobeat-input-core@v0.1.0` plus GUT `main`.
- Repo-local unit tests live under `.testbed/tests/`; this repo's current package payload is rooted at `/`, so the workbench does not ship a `.testbed/src` bridge for this subset.
- The current package shape is consumed from the repo root (`subfolder: "/"`) for downstream installs.
- Keep product wording truthful: the template may be reused for future/non-camera drivers, but official v1 gameplay input remains camera-only.
