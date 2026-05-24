extends GutTest

const HARNESS_SCRIPT := preload("res://tests/support/mouse_provider_test_harness.gd")

func test_off_surface_release_stays_tied_to_press_owner_and_clears_runtime() -> void:
	var harness = HARNESS_SCRIPT.new()
	var runtime = await harness.spawn(self)
	var provider = runtime["provider"]
	var adapter = runtime["adapter"]
	var surface = runtime["surface"]
	var events: Array = runtime["events"]

	var press_hit := harness.build_hit(surface, Vector2(0.20, 0.20), Vector2(200.0, 200.0))
	assert_true(provider.publish_input_event(adapter, surface, harness.make_mouse_motion(Vector2(200.0, 200.0)), press_hit, {
		"pointer_id": HARNESS_SCRIPT.POINTER_ID,
		"host_surface": "PanelInputSurface",
		"target_resolution": "rect_target_specs",
	}))
	assert_true(provider.publish_input_event(adapter, surface, harness.make_mouse_button(Vector2(200.0, 200.0), true), press_hit, {
		"pointer_id": HARNESS_SCRIPT.POINTER_ID,
		"host_surface": "PanelInputSurface",
		"target_resolution": "rect_target_specs",
	}))

	var off_surface_hit := harness.build_off_surface_hit(Vector2(960.0, 960.0))
	assert_true(provider.publish_input_event(adapter, surface, harness.make_mouse_motion(Vector2(960.0, 960.0), Vector2(760.0, 760.0), MOUSE_BUTTON_MASK_LEFT), off_surface_hit, {
		"pointer_id": HARNESS_SCRIPT.POINTER_ID,
		"host_surface": "PanelInputSurface",
		"target_resolution": "rect_target_specs",
	}))
	assert_true(provider.publish_input_event(adapter, surface, harness.make_mouse_button(Vector2(960.0, 960.0), false), off_surface_hit, {
		"pointer_id": HARNESS_SCRIPT.POINTER_ID,
		"host_surface": "PanelInputSurface",
		"target_resolution": "rect_target_specs",
	}))

	var press_events: Array = []
	for event in events:
		if str(event.phase) == "press_begin" or str(event.phase) == "press_end":
			press_events.append(event)
	assert_eq(press_events.size(), 2)
	assert_eq(str(press_events[0].phase), "press_begin")
	assert_eq(str(press_events[1].phase), "press_end")
	assert_eq(str(press_events[1].target_path), "Root/PrimaryActionButton")
	assert_eq(str(press_events[1].verification_status), "prototype")

	var state: Dictionary = provider.describe_runtime_state()
	assert_false(bool(state.get("left_button_down", true)))
	assert_false(bool(state.get("capture_active", true)))
	assert_false(bool(state.get("hover_active", true)))
	assert_eq(str(state.get("last_release_target_path", "")), "Root/PrimaryActionButton")

	var projected_data: Dictionary = state.get("last_projected_data", {})
	var raw_metadata: Dictionary = projected_data.get("raw_metadata", {})
	assert_true(bool(raw_metadata.get("off_surface_continuation", false)))
	assert_eq(str(raw_metadata.get("published_target_path", "")), "Root/PrimaryActionButton")
	assert_eq(str(raw_metadata.get("owner_target_path", "")), "Root/PrimaryActionButton")
