extends GutTest

const HARNESS_SCRIPT := preload("res://tests/support/mouse_provider_test_harness.gd")
const SCENE := preload("res://scenes/mouse_provider_verification_harness.tscn")

func test_runtime_state_reports_hover_capture_release_and_harness_snapshot() -> void:
	var harness = HARNESS_SCRIPT.new()
	var runtime = await harness.spawn(self)
	var provider = runtime["provider"]
	var adapter = runtime["adapter"]
	var surface = runtime["surface"]

	var hover_hit := harness.build_hit(surface, Vector2(0.20, 0.20), Vector2(200.0, 200.0))
	assert_true(provider.publish_input_event(adapter, surface, harness.make_mouse_motion(Vector2(200.0, 200.0), Vector2.ZERO, 0), hover_hit, {
		"pointer_id": HARNESS_SCRIPT.POINTER_ID,
		"host_surface": "PanelInputSurface",
		"target_resolution": "rect_target_specs",
	}))

	var press_hit := harness.build_hit(surface, Vector2(0.20, 0.20), Vector2(200.0, 200.0))
	assert_true(provider.publish_input_event(adapter, surface, harness.make_mouse_button(Vector2(200.0, 200.0), true), press_hit, {
		"pointer_id": HARNESS_SCRIPT.POINTER_ID,
		"host_surface": "PanelInputSurface",
		"target_resolution": "rect_target_specs",
	}))

	var drag_hit := harness.build_hit(surface, Vector2(0.70, 0.20), Vector2(700.0, 200.0))
	assert_true(provider.publish_input_event(adapter, surface, harness.make_mouse_motion(Vector2(700.0, 200.0), Vector2(500.0, 0.0), MOUSE_BUTTON_MASK_LEFT), drag_hit, {
		"pointer_id": HARNESS_SCRIPT.POINTER_ID,
		"host_surface": "PanelInputSurface",
		"target_resolution": "rect_target_specs",
	}))

	assert_true(provider.publish_input_event(adapter, surface, harness.make_mouse_button(Vector2(700.0, 200.0), false), drag_hit, {
		"pointer_id": HARNESS_SCRIPT.POINTER_ID,
		"host_surface": "PanelInputSurface",
		"target_resolution": "rect_target_specs",
	}))

	var state: Dictionary = provider.describe_runtime_state()
	assert_eq(str(state.get("pointer_id", "")), "mouse_0")
	assert_eq(str(state.get("hover_target_path", NodePath())), "Root/SecondaryActionButton")
	assert_eq(str(state.get("capture_target_path", NodePath())), "")
	assert_true(bool(state.get("hover_active", false)))
	assert_false(bool(state.get("capture_active", true)))
	assert_false(bool(state.get("left_button_down", true)))
	assert_eq(str(state.get("last_live_target_path", NodePath())), "Root/SecondaryActionButton")
	assert_true(bool(state.get("last_surface_hover_hit", false)))
	assert_eq(str(state.get("last_release_target_path", "")), "Root/PrimaryActionButton")
	assert_string_contains(str(state.get("last_forwarded_panel_event", "")), "publish mouse release")

	var projected_data: Dictionary = state.get("last_projected_data", {})
	var raw_metadata: Dictionary = projected_data.get("raw_metadata", {})
	assert_eq(str(projected_data.get("target_path", NodePath())), "Root/PrimaryActionButton")
	assert_eq(str(raw_metadata.get("published_target_path", "")), "Root/PrimaryActionButton")
	assert_eq(str(raw_metadata.get("live_target_path", "")), "Root/SecondaryActionButton")
	assert_eq(str(raw_metadata.get("owner_target_path", "")), "Root/PrimaryActionButton")
	assert_eq(str(raw_metadata.get("host_surface", "")), "PanelInputSurface")
	assert_eq(str(raw_metadata.get("target_resolution", "")), "rect_target_specs")

	var harness_scene = SCENE.instantiate()
	add_child_autofree(harness_scene)
	await get_tree().process_frame
	await get_tree().process_frame
	assert_true(harness_scene.publish_mouse_motion(Vector2(0.20, 0.20), Vector2(200.0, 200.0)))
	assert_true(harness_scene.publish_mouse_button(Vector2(0.20, 0.20), Vector2(200.0, 200.0), true))
	assert_true(harness_scene.publish_off_surface_release(Vector2(900.0, 900.0)))
	var snapshot: Dictionary = harness_scene.describe_hud_snapshot()
	assert_eq(str(snapshot.get("provider_lane", "")), "mouse")
	assert_true(bool(snapshot.get("packaged_provider_active", false)))
	assert_eq(str(snapshot.get("provider_runtime_seam", "")), "installed_packaged_provider")
	assert_eq(str(snapshot.get("verification_status", "")), "prototype")
	assert_eq(str(snapshot.get("capture_target_path", "not-empty")), "")
	assert_eq(str(snapshot.get("last_release_target_path", "")), "Root/PrimaryActionButton")
	assert_string_contains(str(snapshot.get("last_forwarded_panel_event", "")), "publish mouse release")
