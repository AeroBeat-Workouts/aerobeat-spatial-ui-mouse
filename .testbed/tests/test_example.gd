extends GutTest

const PROVIDER_SCRIPT := "res://../src/providers/mouse/aero_spatial_ui_mouse_provider.gd"
const PROVIDER_CONFIG_SCRIPT := "res://../src/providers/mouse/aero_spatial_ui_mouse_provider_config.gd"
const RUNTIME_BOUNDARY_SCRIPT := "res://../src/providers/mouse/aero_spatial_ui_mouse_runtime_boundary.gd"
const BOUNDARY_DOC_PATH := "res://../docs/phase-1-boundary-freeze.md"

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

func test_provider_placeholder_encodes_dependency_truth():
	var provider_script := load(PROVIDER_SCRIPT)
	assert_true(provider_script != null, "provider placeholder should load")

	var provider = provider_script.new()
	var boundary: Dictionary = provider.describe_boundary()
	assert_eq(boundary.get("provider_lane"), "mouse", "provider lane should stay mouse")
	assert_eq(boundary.get("contract_owner_package"), "aerobeat-input-core", "input-core should remain the contract owner")
	assert_eq(boundary.get("shared_helper_owner_package"), "aerobeat-spatial-ui-core", "spatial-ui-core should remain the helper-layer owner")
	assert_false(boundary.get("implements_runtime_behavior", true), "Phase 1 should not add real provider behavior")
	assert_false(boundary.get("extracts_hybrid_proof_logic", true), "Phase 1 should not extract hybrid proof logic")
	assert_false(boundary.get("owns_native_2d_bridge", true), "native 2D bridge ownership must stay outside this repo")
	assert_false(boundary.get("owns_contract_definition", true), "contract ownership must stay outside this repo")

func test_provider_config_and_runtime_boundary_stay_scaffolding_only():
	var config_script := load(PROVIDER_CONFIG_SCRIPT)
	var runtime_boundary_script := load(RUNTIME_BOUNDARY_SCRIPT)
	assert_true(config_script != null, "provider config placeholder should load")
	assert_true(runtime_boundary_script != null, "runtime boundary placeholder should load")

	var config = config_script.new()
	var snapshot: Dictionary = config.to_boundary_snapshot()
	assert_eq(snapshot.get("provider_lane"), "mouse", "config should identify the mouse lane")
	assert_eq(snapshot.get("extraction_phase"), "phase_1_boundary_freeze", "config should record the boundary-freeze phase")
	assert_eq(snapshot.get("contract_owner_package"), "aerobeat-input-core", "config should point back to the contract owner")
	assert_eq(snapshot.get("shared_helper_owner_package"), "aerobeat-spatial-ui-core", "config should point back to the helper-layer owner")

	var non_goals: PackedStringArray = runtime_boundary_script.describe_non_goals()
	assert_true(non_goals.has("no canonical interaction contract types"), "boundary should forbid local contract ownership")
	assert_true(non_goals.has("no native 2D bridge logic"), "boundary should forbid native 2D bridge logic")
	assert_true(non_goals.has("no extracted hybrid proof implementation yet"), "boundary should forbid hybrid proof extraction")

func test_phase_1_boundary_doc_exists_and_states_repo_role():
	assert_true(FileAccess.file_exists(BOUNDARY_DOC_PATH), "Phase 1 boundary doc should exist")

	var doc_text := FileAccess.get_file_as_string(BOUNDARY_DOC_PATH)
	assert_string_contains(doc_text, "mouse-driven spatial UI provider lane", "doc should name the repo role clearly")
	assert_string_contains(doc_text, "aerobeat-input-core", "doc should identify the contract owner dependency")
	assert_string_contains(doc_text, "aerobeat-spatial-ui-core", "doc should identify the shared helper dependency")
	assert_string_contains(doc_text, "does **not** own", "doc should explicitly call out non-ownership boundaries")
