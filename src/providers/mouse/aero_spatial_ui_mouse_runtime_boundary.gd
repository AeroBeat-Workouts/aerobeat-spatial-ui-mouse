class_name AeroSpatialUiMouseRuntimeBoundary
extends RefCounted

static func describe_non_goals() -> PackedStringArray:
	return PackedStringArray([
		"no canonical interaction contract types",
		"no native 2D bridge logic",
		"no world-ray acquisition ownership yet",
		"no scene-specific proof-host composition",
	])

static func describe_dependencies() -> Dictionary:
	return {
		"contract_owner_package": "aerobeat-input-core",
		"shared_helper_owner_package": "aerobeat-spatial-ui-core",
		"provider_lane": "mouse",
		"helper_dependencies": PackedStringArray([
			"AeroSpatialProjectionHelper",
			"AeroSpatialHoverCapturePolicy",
		]),
	}

static func describe_extracted_slice() -> Dictionary:
	return {
		"owns_mouse_hover_publication": true,
		"owns_mouse_capture_continuity": true,
		"owns_projected_mouse_press_release_publication": true,
		"owns_world_hit_acquisition": false,
		"owns_contract_definition": false,
		"owns_native_2d_bridge": false,
	}
