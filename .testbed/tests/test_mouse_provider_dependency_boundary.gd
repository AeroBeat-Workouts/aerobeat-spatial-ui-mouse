extends GutTest

const PROVIDER_SCRIPT_PATH := "res://addons/aerobeat-spatial-ui-mouse/src/providers/mouse/aero_spatial_ui_mouse_provider.gd"
const CONFIG_SCRIPT_PATH := "res://addons/aerobeat-spatial-ui-mouse/src/providers/mouse/aero_spatial_ui_mouse_provider_config.gd"
const RUNTIME_BOUNDARY_SCRIPT_PATH := "res://addons/aerobeat-spatial-ui-mouse/src/providers/mouse/aero_spatial_ui_mouse_runtime_boundary.gd"

func test_mouse_provider_boundary_and_runtime_boundary_preserve_upstream_owners() -> void:
	var provider = load(PROVIDER_SCRIPT_PATH).new()
	var config = load(CONFIG_SCRIPT_PATH).new()
	var boundary: Dictionary = provider.describe_boundary()
	var snapshot: Dictionary = config.to_boundary_snapshot()
	var runtime_boundary_script = load(RUNTIME_BOUNDARY_SCRIPT_PATH)
	var extracted_slice: Dictionary = runtime_boundary_script.describe_extracted_slice()
	var dependencies: Dictionary = runtime_boundary_script.describe_dependencies()
	var non_goals: PackedStringArray = runtime_boundary_script.describe_non_goals()

	assert_true(boundary.get("implements_runtime_behavior", false))
	assert_true(boundary.get("extracts_mouse_provider_runtime", false))
	assert_true(boundary.get("extracts_hybrid_proof_logic", false))
	assert_false(boundary.get("owns_world_hit_acquisition", true))
	assert_false(boundary.get("owns_native_2d_bridge", true))
	assert_false(boundary.get("owns_contract_definition", true))
	assert_eq(boundary.get("provider_lane"), "mouse")
	assert_eq(boundary.get("contract_owner_package"), "aerobeat-input-core")
	assert_eq(boundary.get("shared_helper_owner_package"), "aerobeat-spatial-ui-core")

	assert_eq(snapshot.get("provider_lane"), "mouse")
	assert_eq(snapshot.get("contract_owner_package"), "aerobeat-input-core")
	assert_eq(snapshot.get("shared_helper_owner_package"), "aerobeat-spatial-ui-core")
	assert_eq(snapshot.get("target_resolution"), "rect_target_specs")

	assert_true(extracted_slice.get("owns_mouse_hover_publication", false))
	assert_true(extracted_slice.get("owns_mouse_capture_continuity", false))
	assert_true(extracted_slice.get("owns_projected_mouse_press_release_publication", false))
	assert_false(extracted_slice.get("owns_world_hit_acquisition", true))
	assert_false(extracted_slice.get("owns_contract_definition", true))
	assert_false(extracted_slice.get("owns_native_2d_bridge", true))

	var helpers := PackedStringArray(dependencies.get("helper_dependencies", PackedStringArray()))
	assert_true(helpers.has("AeroSpatialProjectionHelper"))
	assert_true(helpers.has("AeroSpatialHoverCapturePolicy"))
	assert_true(helpers.has("AeroSpatialRectTargetResolver"))
	assert_eq(dependencies.get("contract_owner_package"), "aerobeat-input-core")
	assert_eq(dependencies.get("shared_helper_owner_package"), "aerobeat-spatial-ui-core")

	assert_true(non_goals.has("no canonical interaction contract types"))
	assert_true(non_goals.has("no native 2D bridge logic"))
	assert_true(non_goals.has("no world-ray acquisition ownership yet"))
	assert_true(non_goals.has("no scene-specific proof-host composition"))
