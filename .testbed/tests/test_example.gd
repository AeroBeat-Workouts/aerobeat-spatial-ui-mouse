extends GutTest

const PROVIDER_SCRIPT_PATH := "res://addons/aerobeat-spatial-ui-mouse/src/providers/mouse/aero_spatial_ui_mouse_provider.gd"
const PROVIDER_CONFIG_SCRIPT_PATH := "res://addons/aerobeat-spatial-ui-mouse/src/providers/mouse/aero_spatial_ui_mouse_provider_config.gd"
const RUNTIME_BOUNDARY_SCRIPT_PATH := "res://addons/aerobeat-spatial-ui-mouse/src/providers/mouse/aero_spatial_ui_mouse_runtime_boundary.gd"
const BOUNDARY_DOC_PATH := "res://../docs/phase-1-boundary-freeze.md"
const EXTRACTION_DOC_PATH := "res://../docs/phase-2-first-mouse-provider-extraction.md"
const SURFACE_DESCRIPTOR_SCRIPT := preload("res://addons/aerobeat-spatial-ui-core/src/helpers/surfaces/aero_spatial_surface_descriptor.gd")
const PROJECTION_HELPER_SCRIPT := preload("res://addons/aerobeat-spatial-ui-core/src/helpers/providers/aero_spatial_projection_helper.gd")
const INTERACTION_TYPES := preload("res://addons/aerobeat-input-core/src/ui/ui_interaction_types.gd")

class AdapterRecorder:
	extends RefCounted

	var published_events: Array = []
	var published_phases: Array = []

	func publish_from_input_event(event: InputEvent, projected_data: Dictionary = {}, overrides: Dictionary = {}) -> bool:
		published_events.append({
			"event": event,
			"projected_data": projected_data.duplicate(true),
			"overrides": overrides.duplicate(true),
		})
		return true

	func publish_projected_phase(phase: StringName, pointer_id: StringName, projected_data: Dictionary = {}, overrides: Dictionary = {}) -> Dictionary:
		var record := {
			"phase": phase,
			"pointer_id": pointer_id,
			"projected_data": projected_data.duplicate(true),
			"overrides": overrides.duplicate(true),
		}
		published_phases.append(record)
		return record

func before_all():
	gut.p("Starting Spatial UI Mouse Tests...")

func after_all():
	gut.p("Finished Spatial UI Mouse Tests.")

func test_plugin_manifest_structure():
	var manifest_path = "res://../plugin.cfg"
	assert_true(FileAccess.file_exists(manifest_path), "plugin.cfg should exist at the repo root")

	var config = ConfigFile.new()
	assert_eq(config.load(manifest_path), OK, "plugin.cfg should load")
	assert_eq(
		config.get_value("plugin", "name", ""),
		"AeroBeat Spatial UI Mouse",
		"plugin name should match the repo role"
	)
	assert_eq(
		config.get_value("plugin", "description", ""),
		"Mouse-driven spatial UI provider addon for AeroBeat.",
		"plugin description should match the repo role"
	)

func test_provider_boundary_and_config_now_describe_real_phase_3_slice():
	assert_true(FileAccess.file_exists(PROVIDER_SCRIPT_PATH), "provider script should exist")

	var config = load(PROVIDER_CONFIG_SCRIPT_PATH).new()
	var snapshot: Dictionary = config.to_boundary_snapshot()
	assert_eq(snapshot.get("provider_lane"), "mouse", "config should identify the mouse lane")
	assert_eq(snapshot.get("extraction_phase"), "phase_3_packaged_rect_target_resolver_cutover", "config should record the Phase 3 packaged resolver cutover")
	assert_eq(snapshot.get("pointer_id"), &"mouse_0", "config should keep the canonical default pointer id")
	assert_eq(snapshot.get("target_resolution"), "rect_target_specs", "config should point at rect-target resolution by default")

	var provider = load(PROVIDER_SCRIPT_PATH).new(config)
	var boundary: Dictionary = provider.describe_boundary()
	assert_eq(boundary.get("provider_lane"), "mouse", "provider lane should stay mouse")
	assert_eq(boundary.get("contract_owner_package"), "aerobeat-input-core", "input-core should remain the contract owner")
	assert_eq(boundary.get("shared_helper_owner_package"), "aerobeat-spatial-ui-core", "spatial-ui-core should remain the helper-layer owner")
	assert_true(boundary.get("implements_runtime_behavior", false), "Phase 2 should add real provider runtime behavior")
	assert_true(boundary.get("extracts_mouse_provider_runtime", false), "Phase 2 should extract reusable mouse provider runtime")
	assert_true(boundary.get("extracts_hybrid_proof_logic", false), "Phase 2 should extract a real slice from the proof host")
	assert_false(boundary.get("owns_world_hit_acquisition", true), "world-hit acquisition should remain outside this slice for now")
	assert_false(boundary.get("owns_native_2d_bridge", true), "native 2D bridge ownership must stay outside this repo")
	assert_false(boundary.get("owns_contract_definition", true), "contract ownership must stay outside this repo")

func test_runtime_boundary_and_docs_state_phase_3_scope_explicitly():
	var runtime_boundary_script = load(RUNTIME_BOUNDARY_SCRIPT_PATH)
	var extracted_slice: Dictionary = runtime_boundary_script.describe_extracted_slice()
	assert_true(extracted_slice.get("owns_mouse_hover_publication", false), "runtime boundary should include hover publication")
	assert_true(extracted_slice.get("owns_mouse_capture_continuity", false), "runtime boundary should include capture continuity")
	assert_false(extracted_slice.get("owns_world_hit_acquisition", true), "runtime boundary should exclude world-hit acquisition")

	var dependencies: Dictionary = runtime_boundary_script.describe_dependencies()
	assert_true(PackedStringArray(dependencies.get("helper_dependencies", PackedStringArray())).has("AeroSpatialRectTargetResolver"), "runtime boundary should advertise the packaged rect-target resolver dependency")

	var non_goals: PackedStringArray = runtime_boundary_script.describe_non_goals()
	assert_true(non_goals.has("no canonical interaction contract types"), "boundary should forbid local contract ownership")
	assert_true(non_goals.has("no native 2D bridge logic"), "boundary should forbid native 2D bridge logic")
	assert_true(non_goals.has("no world-ray acquisition ownership yet"), "boundary should keep world-ray acquisition outside this slice")

	assert_true(FileAccess.file_exists(BOUNDARY_DOC_PATH), "Phase 1 boundary doc should exist")
	assert_true(FileAccess.file_exists(EXTRACTION_DOC_PATH), "Phase 2 extraction doc should exist")

	var boundary_doc := FileAccess.get_file_as_string(BOUNDARY_DOC_PATH)
	assert_string_contains(boundary_doc, "Phase 2")
	assert_string_contains(boundary_doc, "scene-specific proof-host composition")

	var extraction_doc := FileAccess.get_file_as_string(EXTRACTION_DOC_PATH)
	assert_string_contains(extraction_doc, "mouse-specific hover enter/exit publication")
	assert_string_contains(extraction_doc, "world-ray acquisition itself")
	assert_string_contains(extraction_doc, "mouse-provider publication/capture lifecycle")
	assert_string_contains(extraction_doc, "provider-local rect-target lookup fallback is now retired")
	assert_string_contains(extraction_doc, "packaged `AeroSpatialRectTargetResolver` helper")

func test_provider_publishes_hover_press_motion_and_release_with_capture_continuity():
	var provider = load(PROVIDER_SCRIPT_PATH).new()
	var adapter := AdapterRecorder.new()
	var projection_helper = PROJECTION_HELPER_SCRIPT.new()
	var surface = _build_surface_descriptor()
	var center_hit = projection_helper.build_surface_hit(surface, Vector2(0.5, 0.5), {
		"screen_position": Vector2(960.0, 540.0),
		"world_position": Vector3(1.0, 2.0, 3.0),
		"world_normal": Vector3(0.0, 0.0, 1.0),
		"world_direction": Vector3(0.0, 0.0, -1.0),
		"local_hit": Vector3.ZERO,
	})
	var off_target_hit = projection_helper.build_surface_hit(surface, Vector2(0.85, 0.85), {
		"screen_position": Vector2(1140.0, 720.0),
		"world_position": Vector3(1.0, 2.1, 3.0),
		"world_normal": Vector3(0.0, 0.0, 1.0),
		"world_direction": Vector3(0.0, 0.0, -1.0),
		"local_hit": Vector3(0.2, -0.3, 0.0),
	})

	var motion_in := InputEventMouseMotion.new()
	motion_in.position = Vector2(960.0, 540.0)
	motion_in.relative = Vector2(4.0, 2.0)
	motion_in.button_mask = 0

	var press := InputEventMouseButton.new()
	press.button_index = MOUSE_BUTTON_LEFT
	press.pressed = true
	press.position = Vector2(960.0, 540.0)

	var motion_captured := InputEventMouseMotion.new()
	motion_captured.position = Vector2(1140.0, 720.0)
	motion_captured.relative = Vector2(120.0, 120.0)
	motion_captured.button_mask = MOUSE_BUTTON_MASK_LEFT

	var release := InputEventMouseButton.new()
	release.button_index = MOUSE_BUTTON_LEFT
	release.pressed = false
	release.position = Vector2(1140.0, 720.0)

	assert_true(provider.publish_input_event(adapter, surface, motion_in, center_hit), "hover motion on a valid target should publish")
	assert_eq(adapter.published_phases.size(), 1, "hovering a fresh target should publish hover_enter")
	assert_eq(adapter.published_phases[0].get("phase"), INTERACTION_TYPES.PHASE_HOVER_ENTER)

	assert_true(provider.publish_input_event(adapter, surface, press, center_hit), "mouse press on a valid target should publish")
	assert_eq(adapter.published_events.size(), 2, "initial hover motion and press should both publish adapter events")
	assert_eq(adapter.published_events[1].get("projected_data", {}).get("target_path"), NodePath("PreviewCenter/PrimaryActionButton"))
	assert_eq(adapter.published_events[1].get("projected_data", {}).get("raw_metadata", {}).get("matched_target_key"), "primary_action", "press should carry metadata from the packaged resolver")

	assert_true(provider.publish_input_event(adapter, surface, motion_captured, off_target_hit), "captured motion should continue publishing even after hover leaves the original target")
	assert_eq(adapter.published_phases.size(), 2, "moving off the target should publish hover_exit")
	assert_eq(adapter.published_phases[1].get("phase"), INTERACTION_TYPES.PHASE_HOVER_EXIT)
	assert_eq(adapter.published_events.size(), 3, "captured motion should still publish through the adapter")
	assert_eq(adapter.published_events[2].get("projected_data", {}).get("target_path"), NodePath("PreviewCenter/PrimaryActionButton"), "captured motion should keep publishing to the press owner")
	assert_true(adapter.published_events[2].get("projected_data", {}).get("raw_metadata", {}).get("off_surface_continuation", false) == false, "same-surface captured motion should not mark off-surface continuation")

	assert_true(provider.publish_input_event(adapter, surface, release, off_target_hit), "release after capture should publish")
	assert_eq(adapter.published_events.size(), 4, "release should publish through the adapter")
	assert_eq(adapter.published_events[3].get("projected_data", {}).get("target_path"), NodePath("PreviewCenter/PrimaryActionButton"), "release should stay tied to the press owner")

	var runtime_state: Dictionary = provider.describe_runtime_state()
	assert_false(runtime_state.get("capture_active", true), "capture should be released after mouse-up")
	assert_eq(runtime_state.get("last_release_target_path"), "PreviewCenter/PrimaryActionButton", "release snapshot should record the press owner path")

func test_provider_synthesizes_release_when_motion_button_mask_drops():
	var provider = load(PROVIDER_SCRIPT_PATH).new()
	var adapter := AdapterRecorder.new()
	var projection_helper = PROJECTION_HELPER_SCRIPT.new()
	var surface = _build_surface_descriptor()
	var center_hit = projection_helper.build_surface_hit(surface, Vector2(0.5, 0.5), {
		"screen_position": Vector2(960.0, 540.0),
		"world_position": Vector3(1.0, 2.0, 3.0),
		"world_normal": Vector3(0.0, 0.0, 1.0),
		"world_direction": Vector3(0.0, 0.0, -1.0),
	})

	var press := InputEventMouseButton.new()
	press.button_index = MOUSE_BUTTON_LEFT
	press.pressed = true
	press.position = Vector2(960.0, 540.0)
	assert_true(provider.publish_input_event(adapter, surface, press, center_hit), "press should establish capture state")

	var motion_drop := InputEventMouseMotion.new()
	motion_drop.position = Vector2(980.0, 560.0)
	motion_drop.relative = Vector2(20.0, 20.0)
	motion_drop.button_mask = 0
	assert_true(provider.publish_input_event(adapter, surface, motion_drop, center_hit), "motion after button-mask drop should still publish after synthesizing release")

	assert_true(adapter.published_events.size() >= 3, "press, synthetic release, and follow-up hover/motion should all be recorded")
	var synthetic_release_record: Dictionary = adapter.published_events[1]
	var synthetic_event: InputEventMouseButton = synthetic_release_record.get("event")
	assert_false(synthetic_event.pressed, "second published event should be the synthesized release")
	assert_eq(synthetic_release_record.get("projected_data", {}).get("target_path"), NodePath("PreviewCenter/PrimaryActionButton"), "synthetic release should stay tied to the captured owner")

	var runtime_state: Dictionary = provider.describe_runtime_state()
	assert_false(runtime_state.get("left_button_down", true), "synthetic release should clear left-button runtime state")
	assert_string_contains(str(runtime_state.get("last_forwarded_panel_event", "")), "publish mouse motion", "provider should resume ordinary motion publication after the synthetic release")

func _build_surface_descriptor() -> AeroSpatialSurfaceDescriptor:
	return SURFACE_DESCRIPTOR_SCRIPT.new().configure({
		"surface_id": &"hybrid_glass_panel",
		"surface_pixel_size": Vector2(1000.0, 800.0),
		"authored_rect_normalized": Rect2(0.1, 0.2, 0.6, 0.5),
		"target_specs": [
			{
				"target_key": "primary_action",
				"target_name": "Primary Action",
				"target_path": NodePath("PreviewCenter/PrimaryActionButton"),
				"rect": Rect2(350.0, 300.0, 220.0, 120.0),
			}
		],
		"metadata": {
			"host_surface": "PanelInputSurface",
			"target_resolution": "rect_target_specs",
		}
	})
