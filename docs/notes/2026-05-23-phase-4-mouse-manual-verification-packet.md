# Phase 4 Mouse Manual-Verification Packet

Date: 2026-05-23

This note defines the next honest execution slice for the extracted mouse lane **after** the Phase 3 packaged-resolver baseline.

The current baseline is good at proving provider structure and several key lifecycle semantics in code, but it is **not yet a durable human-verifiable packet**. The missing piece is not another ownership reshuffle. The missing piece is a stable verification packet that lets Derrick confirm, in a running scene, that the installed packaged mouse provider is the code path driving the hybrid proof and that its runtime state stays truthful while interacting with the surface.

## Baseline truth at the start of this packet

Today the lane already proves these things:

- `aerobeat-spatial-ui-mouse` owns reusable mouse hover/press/capture publication logic.
- `aerobeat-input-core` still owns the canonical interaction contract and `verification_status` truth.
- `aerobeat-spatial-ui-core` still owns shared resolver/projection/hover-capture helpers.
- `aerobeat-ui-kit-community` still owns world-ray acquisition and proof-scene composition.
- consumer tests in `aerobeat-ui-kit-community` already prove a packaged mouse-provider path can toggle the primary action in the hybrid proof scene.

What is still missing is a **durable human + test packet** that exposes enough live provider truth to validate the packaged provider beyond repo-local unit assertions.

## The next truthful provider-owned completion gap

The next truthful mouse-lane gap is:

**provider-readable live runtime diagnostics plus a provider-local verification harness that can be reused without taking ownership of world-hit acquisition or proof-scene composition.**

That gap is truthful because:

1. the provider already has a runtime description seam (`describe_runtime_state()`), but the lane does not yet have a durable verification packet that treats that seam as the primary live-debug truth source;
2. the downstream proof scene currently exercises the provider, but it does not yet surface a complete verification-oriented mouse packet for humans;
3. there is still no reusable mouse-specific verification harness owned by the provider repo itself that can be used to check hover/owner/release continuity without dragging scene-specific world-ray logic into this package.

## Exact proposed next slice

The next executable slice should be:

**Phase 4 — mouse verification harness + downstream packaged-provider proof HUD**

That slice should contain two tightly-scoped parts.

### A. Provider-repo slice (`aerobeat-spatial-ui-mouse`)

Add a provider-owned reusable verification harness in this repo’s hidden `.testbed` that:

- instantiates `AeroSpatialUiMouseProvider` directly;
- uses a synthetic/configured `AeroSpatialSurfaceDescriptor` instead of any real 3D world-ray acquisition;
- feeds the provider projected hits and raw mouse events;
- exposes provider runtime truth in a stable readout driven by `describe_runtime_state()`;
- demonstrates hover target, capture owner, last live target, last release target, and last forwarded event text;
- preserves `verification_status` truth from the contract path as `prototype` / `unverified` according to upstream rules rather than promoting anything locally.

This harness is not a replacement for the hybrid proof scene. It is the provider-lane’s reusable semantic test bench.

### B. Consumer proof slice (`aerobeat-ui-kit-community`)

Update the existing hybrid proof scene so a human can verify that the **installed packaged mouse provider** is the runtime path in use and can read enough live state to confirm behavior while interacting with the 3D surface.

That means the proof scene should expose, at minimum:

- source variant
- phase
- target path
- verification status
- verification notes
- mouse provider runtime snapshot fields:
  - `hover_target_path`
  - `capture_target_path`
  - `left_button_down`
  - `last_live_target_path`
  - `last_release_target_path`
  - `last_forwarded_panel_event`
- an explicit indicator that the scene is reading from the packaged provider runtime seam instead of rebuilding the logic locally

## What must remain outside the provider repo

The following seams should remain outside `aerobeat-spatial-ui-mouse` in this slice:

1. **Canonical contract ownership**
   - stays in `aerobeat-input-core`
   - includes event taxonomy, adapter meaning, and `verification_status` truth

2. **Shared helper ownership**
   - stays in `aerobeat-spatial-ui-core`
   - includes projection helpers, rect-target resolution helpers, and reusable hover/capture policy helpers

3. **World-hit acquisition**
   - stays outside the provider repo
   - includes camera ray creation, physics queries, Area3D hit collection, and conversion from world hit to provider input hit

4. **Hybrid proof-scene composition**
   - stays in `aerobeat-ui-kit-community`
   - includes the glass panel scene, world-space camera layout, panel mesh composition, and test-scene UX/presentation

5. **Any verification promotion to `verified`**
   - stays out of this slice until live validation changes upstream truth
   - `screen_mouse + hybrid_3d_gui` should remain whatever `aerobeat-input-core` truthfully seeds today unless that upstream truth is explicitly changed

## Test-scene ownership split

This is the clean ownership split for new reusable mouse test scenes.

### Owned by `aerobeat-spatial-ui-mouse`

Add a **provider-local reusable verification harness scene** under the hidden `.testbed`.

Purpose:
- verify provider lifecycle semantics without depending on a 3D world scene
- provide a reusable lane-owned debugging surface for future mouse regressions
- keep provider runtime inspection close to the provider implementation

Recommended shape:
- `.testbed/scenes/mouse_provider_verification_harness.tscn`
- `.testbed/scripts/mouse_provider_verification_harness.gd`

This harness should operate on synthetic/projected hit dictionaries and a configured `AeroSpatialSurfaceDescriptor`, not on real world rays.

### Owned by `aerobeat-ui-kit-community`

Keep the **hybrid world proof scene** as the place where the real 3D panel composition is verified.

Purpose:
- prove the packaged provider is actually installed and used downstream
- prove host-owned world-hit acquisition still composes correctly into the packaged provider
- prove the actual proof scene’s button behavior, hover behavior, and release behavior in context

That means new human-proof UI and downstream assertions belong on the existing hybrid proof scene rather than being moved into the provider repo.

## Downstream proof-scene changes that belong in `aerobeat-ui-kit-community`

The following changes belong downstream, not in the provider repo:

1. **Expand the current input-debug HUD into a verification HUD**
   - show contract phase / target / source variant / verification status / notes
   - show packaged provider runtime snapshot fields
   - keep the readout human-readable, not just test-only

2. **Add a clear packaged-provider truth indicator**
   - the scene should explicitly say the mouse lane is being driven by `AeroSpatialUiMouseProvider`
   - this should read from the installed provider/runtime seam, not from duplicated local state

3. **Add proof-scene affordances for off-target and off-surface release behavior**
   - enough space and labeling to let a human intentionally press on the button, drag away, and release either off-target or off-surface
   - this belongs in the proof scene because the proof scene owns actual world-hit routing

4. **Keep compatibility wrappers only as thin consumer glue**
   - wrappers like `_screen_position_to_panel_hit(...)` remain local
   - they must not regrow mouse-provider lifecycle ownership

## Exact human verification steps the scene should enable

The downstream hybrid proof should support this exact manual pass.

### Setup

1. open `aerobeat-ui-kit-community/.testbed` in Godot
2. load the hybrid glass proof scene
3. ensure the installed addon path for `aerobeat-spatial-ui-mouse` is present under `res://addons/...`
4. confirm the debug HUD shows:
   - provider lane = mouse
   - packaged provider active
   - `source_variant` updates during interaction
   - `verification_status` remains truthful

### Verification pass 1 — hover truth

1. move the mouse onto `PrimaryActionButton`
2. confirm the HUD shows:
   - target path ending in `PrimaryActionButton`
   - hover state / `hover_enter` or `hover_move`
   - provider runtime `hover_target_path` = `PrimaryActionButton`
   - no capture owner yet

### Verification pass 2 — press ownership

1. press and hold left mouse on `PrimaryActionButton`
2. confirm the HUD shows:
   - contract phase `press_begin`
   - provider runtime `capture_target_path` = `PrimaryActionButton`
   - `left_button_down == true`
   - `last_live_target_path` still points at the hovered button

### Verification pass 3 — drag away while captured

1. keep holding the mouse button
2. drag away from the button but stay on the panel surface
3. confirm the HUD shows:
   - live hover may leave the button
   - capture owner stays on `PrimaryActionButton`
   - provider continues publishing with the press owner target
   - no fake cancel or target-owner swap occurs

### Verification pass 4 — release completion

1. release while still away from the button but after starting the press on it
2. confirm the HUD shows:
   - `press_end`
   - `last_release_target_path` = `PrimaryActionButton`
   - capture clears after release
   - the proof button toggles/completes exactly once

### Verification pass 5 — off-surface continuity

1. press on `PrimaryActionButton`
2. drag off the interactive panel surface entirely
3. release
4. confirm the HUD shows:
   - the release still resolves against the press owner
   - provider runtime clears `left_button_down`
   - capture clears
   - no duplicate release or stuck pressed state remains

### Verification pass 6 — duplicate-release safety

1. after a completed release, trigger an extra release or motion-without-button state
2. confirm the HUD shows:
   - no second activation
   - no stuck capture
   - provider runtime remains idle/cleared

### Verification truth rule

During all passes:

- `verification_status` must **not** be promoted beyond current upstream truth by this slice alone
- if the bus still seeds `screen_mouse + hybrid_3d_gui` as `prototype`, the scene must continue to show `prototype`
- if upstream later changes that truth, the scene should reflect the upstream change rather than a local override here

## Automated tests that should accompany this scene work

The next slice should add tests in **both repos**, with responsibilities split by ownership.

### Provider-repo tests (`aerobeat-spatial-ui-mouse`)

Add or extend tests for:

1. `.testbed/tests/test_mouse_provider_runtime_state.gd`
   - asserts `describe_runtime_state()` truth after hover, press, drag, release
   - checks `hover_target_path`, `capture_target_path`, `left_button_down`, `last_release_target_path`

2. `.testbed/tests/test_mouse_provider_off_surface_release.gd`
   - press on a valid target
   - release with `hit == false` while capture is active
   - assert release stays tied to owner and capture clears

3. `.testbed/tests/test_mouse_provider_dependency_boundary.gd`
   - assert provider still composes through `aerobeat-input-core` and `aerobeat-spatial-ui-core`
   - assert provider does not claim world-hit or contract ownership

4. `.testbed/tests/test_mouse_provider_verification_truth.gd`
   - assert provider/harness output does not silently promote verification truth
   - keep `verification_status` aligned with upstream bus rules

### Downstream tests (`aerobeat-ui-kit-community`)

Add or extend tests for:

1. `.testbed/tests/test_hybrid_mouse_release_path.gd`
   - keep the existing packaged-provider release proof
   - expand assertions for runtime snapshot fields exposed by the scene

2. `.testbed/tests/test_hybrid_packaged_mouse_provider_flow.gd`
   - assert installed provider source is read from `res://addons/aerobeat-spatial-ui-mouse/...`
   - assert the runtime scene is using the packaged provider describe seam
   - assert press/drag/release flows report the expected provider runtime truth

3. `.testbed/tests/test_hybrid_mouse_off_surface_release_path.gd`
   - derive a start point on the primary button
   - drive a press, move off-surface, and release
   - assert button completion and provider runtime clearing

4. `.testbed/tests/test_hybrid_mouse_verification_hud.gd`
   - assert the HUD exposes source variant, phase, target path, verification status, and provider runtime fields needed for manual QA

## Acceptance criteria for the next slice

This packet should be considered complete only if all of the following are true:

1. `aerobeat-spatial-ui-mouse` has a reusable provider-local verification harness scene that does **not** own world-hit acquisition
2. the provider repo has explicit automated coverage for runtime state and off-surface release semantics
3. `aerobeat-ui-kit-community` exposes a human-readable verification HUD for the packaged mouse provider
4. downstream tests prove the hybrid proof is using the installed packaged provider path
5. world-hit acquisition remains in `aerobeat-ui-kit-community`
6. shared helper ownership remains in `aerobeat-spatial-ui-core`
7. contract ownership remains in `aerobeat-input-core`
8. `verification_status` remains truthful and unpromoted by this slice alone

## Risks and decision points

### 1. Provider-scene drift risk

If the provider repo tries to host the real hybrid 3D proof scene, it will silently re-own proof-scene composition and start dragging world-hit concerns into the package.

Decision: **do not do that.** Keep the provider scene synthetic/projected-only.

### 2. False verification-promotion risk

A prettier HUD may tempt downstream code to label the path as verified.

Decision: keep `verification_status` driven by upstream contract truth only.

### 3. Local-state shadowing risk

If `aerobeat-ui-kit-community` derives its own mouse owner/hover/release debug state instead of reading the provider seam, the human proof becomes less honest.

Decision: prefer the provider’s `describe_runtime_state()` as the debug truth source for mouse-runtime details.

### 4. Off-surface ambiguity risk

Off-surface release behavior is easy to think is covered when only same-surface off-target release was tested.

Decision: explicitly add both provider-local and downstream off-surface release checks.

## Recommended execution order

1. add the provider-local verification harness scene in `aerobeat-spatial-ui-mouse`
2. add provider tests for runtime state, dependency boundary, verification truth, and off-surface release
3. expand the downstream hybrid proof HUD in `aerobeat-ui-kit-community`
4. add downstream packaged-provider and off-surface-release tests
5. run manual verification in the hybrid proof scene without changing verification truth labels

## Bottom line

The next honest mouse slice is **not more extraction theory** and **not world-hit migration into the provider repo**.

It is a two-part verification packet:

- a **provider-owned reusable verification harness** in `aerobeat-spatial-ui-mouse`
- a **downstream packaged-provider verification HUD + proof tests** in `aerobeat-ui-kit-community`

That is the smallest durable slice that lets Derrick verify the mouse provider works beyond pure code tests while keeping ownership boundaries truthful.
