extends GutTest

const HARNESS_SCRIPT := preload("res://tests/support/mouse_provider_test_harness.gd")
const VERIFICATION_STATUS := preload("res://addons/aerobeat-input-core/src/ui/ui_verification_status.gd")

func test_mouse_provider_runtime_keeps_contract_verification_truth_unpromoted() -> void:
	var harness = HARNESS_SCRIPT.new()
	var runtime = await harness.spawn(self)
	var provider = runtime["provider"]
	var adapter = runtime["adapter"]
	var surface = runtime["surface"]
	var bus = runtime["bus"]
	var events: Array = runtime["events"]

	var seeded: Dictionary = bus.get_source_verification(&"screen_mouse", &"hybrid_3d_gui")
	assert_eq(StringName(seeded.get("status", StringName())), VERIFICATION_STATUS.PROTOTYPE)
	assert_string_contains(str(seeded.get("notes", "")), "not fully proven")

	var hover_hit := harness.build_hit(surface, Vector2(0.20, 0.20), Vector2(200.0, 200.0))
	assert_true(provider.publish_input_event(adapter, surface, harness.make_mouse_motion(Vector2(200.0, 200.0)), hover_hit, {
		"pointer_id": HARNESS_SCRIPT.POINTER_ID,
		"host_surface": "PanelInputSurface",
		"target_resolution": "rect_target_specs",
	}))
	assert_true(provider.publish_input_event(adapter, surface, harness.make_mouse_button(Vector2(200.0, 200.0), true), hover_hit, {
		"pointer_id": HARNESS_SCRIPT.POINTER_ID,
		"host_surface": "PanelInputSurface",
		"target_resolution": "rect_target_specs",
	}))
	assert_true(provider.publish_input_event(adapter, surface, harness.make_mouse_button(Vector2(900.0, 900.0), false), harness.build_off_surface_hit(Vector2(900.0, 900.0)), {
		"pointer_id": HARNESS_SCRIPT.POINTER_ID,
		"host_surface": "PanelInputSurface",
		"target_resolution": "rect_target_specs",
	}))

	assert_true(events.size() >= 3)
	for event in events:
		assert_eq(str(event.source_variant), "screen_mouse")
		assert_eq(str(event.surface_type), "hybrid_3d_gui")
		assert_eq(StringName(event.verification_status), VERIFICATION_STATUS.PROTOTYPE)
		assert_false(str(event.verification_status) == "verified")

	var projected_data: Dictionary = provider.describe_runtime_state().get("last_projected_data", {})
	assert_false(projected_data.has("verification_status"))
	assert_false(projected_data.has("verification_notes"))
