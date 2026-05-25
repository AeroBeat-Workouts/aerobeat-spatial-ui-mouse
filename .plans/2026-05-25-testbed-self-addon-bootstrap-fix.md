# AeroBeat Spatial UI Mouse

**Date:** 2026-05-25
**Status:** In Progress
**Last Updated:** 2026-05-25 19:14 EDT
**Blocked Reason:** None
**Agent:** `byte`

---

## Goal

Make the hidden `.testbed` Godot project bootstrap the current repo package from the repo root through GodotEnv so fresh sync/import/play works without relying on leftover local addon copies.

---

## Overview

The current `aerobeat-spatial-ui-mouse` testbed expects runtime/package paths under `res://addons/aerobeat-spatial-ui-mouse/...`, but `.testbed/addons.jsonc` only declares external dependencies (`aerobeat-input-core`, `aerobeat-spatial-ui-core`, and `gut`). On a fresh machine or after a clean sync, GodotEnv restores those dependencies but does not stage the current repo package into `.testbed/addons/aerobeat-spatial-ui-mouse/`, so the verification scene and installed-addon smoke path fail.

The fix should follow the existing AeroBeat pattern used by repo-owned testbeds: declare the current repo as a GodotEnv dependency mounted from the repo root, ideally via the same local-root/symlink pattern already used elsewhere in the polyrepo. After that, the repo should re-import cleanly, the packaged addon path should exist deterministically, and the repo docs should describe the canonical bootstrap path clearly enough that a fresh machine behaves the same as a warmed local checkout.

We should keep the package boundary intact: durable edits belong in the owning repo root and testbed manifest/docs, not in generated `.testbed/addons/` copies.

---

## REFERENCES

| ID | Description | Path |
| --- | --- | --- |
| `REF-01` | Current repo testbed dependency manifest missing self-mounted package entry | `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-spatial-ui-mouse/.testbed/addons.jsonc` |
| `REF-02` | Current repo README describing the installed-addon validation path and hidden testbed workflow | `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-spatial-ui-mouse/README.md` |
| `REF-03` | Existing AeroBeat example of mounting the current repo package from the repo root through GodotEnv | `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-ui-kit-community/.testbed/addons.jsonc` |
| `REF-04` | Canonical workspace helper for refreshing nested GodotEnv project roots such as `repo/.testbed` | `/home/derrick/.openclaw/workspace/scripts/godotenv-sync` |

---

## Tasks

### Task 1: Confirm the canonical self-mount pattern and exact manifest shape

**Bead ID:** `aerobeat-spatial-ui-mouse-20d`
**SubAgent:** `primary` (for `research`)
**Role:** `research`
**References:** `REF-01`, `REF-02`, `REF-03`, `REF-04`  
**Prompt:** Inspect `aerobeat-spatial-ui-mouse` and comparable AeroBeat repos, confirm the canonical GodotEnv pattern for mounting the current repo package from the repo root into the hidden testbed, and report the exact manifest entry and any supporting bootstrap/docs changes needed. Claim the bead on start and leave clear notes tying the recommendation back to the cited references.

**Folders Created/Deleted/Modified:**
- `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-spatial-ui-mouse/.plans/`

**Files Created/Deleted/Modified:**
- `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-spatial-ui-mouse/.plans/2026-05-25-testbed-self-addon-bootstrap-fix.md`

**Status:** ✅ Complete

**Results:** Confirmed the canonical self-mount shape by comparing `REF-01` against `REF-03`: add a top-level addon entry named `aerobeat-spatial-ui-mouse` with `"url": ".."`, `"source": "symlink"`, and `"subfolder": "/"` so the hidden `.testbed` installs the owning repo from the repo root into `res://addons/aerobeat-spatial-ui-mouse/`. `REF-02` already documents that installed-addon paths under `res://addons/aerobeat-spatial-ui-mouse/...` are part of the intended validation surface, so the README/bootstrap notes should explicitly say that `godotenv addons install` now restores both external dependencies and the repo’s own package mount. From `REF-04`, the relevant refresh gotcha is that `godotenv-sync` targets the nested project root containing `addons.jsonc`, so `godotenv-sync --repo aerobeat-spatial-ui-mouse` or `--repo /home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-spatial-ui-mouse/.testbed` should refresh this hidden testbed without any direct edits inside generated `.testbed/addons/` or `.testbed/.addons/` copies.

---

### Task 2: Implement the testbed self-addon bootstrap fix in the owning repo

**Bead ID:** `aerobeat-spatial-ui-mouse-x1v`
**SubAgent:** `primary` (for `coder`)
**Role:** `coder`
**References:** `REF-01`, `REF-02`, `REF-03`
**Prompt:** In `aerobeat-spatial-ui-mouse`, implement the approved GodotEnv self-mount/bootstrap fix so fresh `.testbed` installs stage the current repo package under `res://addons/aerobeat-spatial-ui-mouse/` without editing generated addon copies. Update the manifest, any repo-local bootstrap helpers/docs needed for clarity, run the relevant repo-local validation/import checks, and commit/push by default before handoff. Claim the bead on start and include validation evidence in your notes.

**Folders Created/Deleted/Modified:**
- `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-spatial-ui-mouse/.testbed/`
- `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-spatial-ui-mouse/docs/`

**Files Created/Deleted/Modified:**
- `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-spatial-ui-mouse/.testbed/addons.jsonc`
- `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-spatial-ui-mouse/README.md`
- `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-spatial-ui-mouse/docs/*`

**Status:** ✅ Complete

**Results:** Added the canonical self-mount entry to `REF-01` so `.testbed/addons.jsonc` now declares `aerobeat-spatial-ui-mouse` with `"url": ".."`, `"source": "symlink"`, and `"subfolder": "/"`, which stages the owning repo at `res://addons/aerobeat-spatial-ui-mouse/` during GodotEnv installs. Updated `REF-02` so the bootstrap flow explicitly says `godotenv addons install` restores both external dependencies and the repo’s own package mount, and documented `/home/derrick/.openclaw/workspace/scripts/godotenv-sync --repo /home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-spatial-ui-mouse/.testbed` as the canonical refresh path. Validation run: first `godotenv-sync --repo /home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-spatial-ui-mouse/.testbed` exposed an existing generated addon replacement failure (`Cannot delete modified addon aerobeat-spatial-ui-mouse`), so I cleared only the generated `.testbed/addons/aerobeat-spatial-ui-mouse` and `.testbed/.addons/aerobeat-spatial-ui-mouse` copies, reran the same canonical refresh successfully, verified `.testbed/addons/aerobeat-spatial-ui-mouse` is now a symlink to the owning repo root, then ran `godot --headless --path .testbed --import`, `godot --headless --path .testbed --script res://scripts/validate_installed_addon_paths.gd`, and `godot --headless --path .testbed --script addons/gut/gut_cmdln.gd -gdir=res://tests -ginclude_subdirs -gexit` from the repo root. Import completed, the installed-addon smoke script passed, and GUT reported 9/9 tests passed. Commit hash: `19fec92`.

---

### Task 3: Verify fresh sync/import/play behavior from the hidden testbed

**Bead ID:** `aerobeat-spatial-ui-mouse-7te`
**SubAgent:** `primary` (for `qa`)
**Role:** `qa`
**References:** `REF-01`, `REF-02`, `REF-03`
**Prompt:** Verify the `aerobeat-spatial-ui-mouse` hidden `.testbed` now bootstraps correctly from a fresh dependency state. Use the canonical GodotEnv workflow, confirm the self-mounted package appears under the installed addon path, and verify the intended test/import/play path succeeds without relying on stale local copies. Claim the bead on start and capture the exact validation evidence and any gaps.

**Folders Created/Deleted/Modified:**
- `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-spatial-ui-mouse/.testbed/`

**Files Created/Deleted/Modified:**
- `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-spatial-ui-mouse/.testbed/addons/`
- `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-spatial-ui-mouse/.testbed/.addons/`

**Status:** ⏳ Pending

**Results:** Pending.

---

### Task 4: Independently audit the ownership boundary and final validation evidence

**Bead ID:** `aerobeat-spatial-ui-mouse-ng4`
**SubAgent:** `primary` (for `auditor`)
**Role:** `auditor`
**References:** `REF-01`, `REF-02`, `REF-03`
**Prompt:** Audit the completed `aerobeat-spatial-ui-mouse` fix independently. Confirm the owning repo now declares the self-mounted package correctly, generated addon copies were not treated as source, docs still match the real workflow, and the validation evidence really proves the hidden testbed works from a fresh dependency state. Claim the bead on start and close it only if the work truly satisfies the references.

**Folders Created/Deleted/Modified:**
- `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-spatial-ui-mouse/.testbed/`

**Files Created/Deleted/Modified:**
- `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-spatial-ui-mouse/.testbed/addons.jsonc`
- `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-spatial-ui-mouse/README.md`
- `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-spatial-ui-mouse/docs/*`

**Status:** ⏳ Pending

**Results:** Pending.

---

## Final Results

**Status:** ⚠️ Partial

**What We Built:** Task 2 is complete: the hidden testbed now self-mounts the owning repo package through GodotEnv and the README/bootstrap notes describe the canonical refresh/import workflow. QA and auditor stages are still pending.

**Reference Check:** `REF-01` now includes the repo-local self-mount entry, `REF-02` now matches the real bootstrap flow, and Task 2 validation proved the installed addon path resolves under `res://addons/aerobeat-spatial-ui-mouse/...` after canonical refresh.

**Commits:**
- `19fec92` - Fix testbed self-mounted addon bootstrap

**Lessons Learned:** When a repo converts from a generated local addon copy to a local-root self-mount, stale generated addon/cache directories may need to be cleared once so GodotEnv can replace them cleanly.

---

*Completed on Pending*
