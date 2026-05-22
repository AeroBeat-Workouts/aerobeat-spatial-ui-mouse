class_name AeroSpatialUiMouseProviderConfig
extends RefCounted

const DEFAULT_PROVIDER_LANE := "mouse"
const DEFAULT_POINTER_ID: StringName = &"mouse_0"
const DEFAULT_DRAG_THRESHOLD_PIXELS := 12.0

var contract_owner_package := "aerobeat-input-core"
var shared_helper_owner_package := "aerobeat-spatial-ui-core"
var extraction_phase := "phase_2_first_mouse_provider_extraction"
var pointer_id: StringName = DEFAULT_POINTER_ID
var drag_threshold_pixels := DEFAULT_DRAG_THRESHOLD_PIXELS
var host_surface := ""
var target_resolution := "rect_target_specs"

func to_boundary_snapshot() -> Dictionary:
	return {
		"provider_lane": DEFAULT_PROVIDER_LANE,
		"contract_owner_package": contract_owner_package,
		"shared_helper_owner_package": shared_helper_owner_package,
		"extraction_phase": extraction_phase,
		"pointer_id": pointer_id,
		"drag_threshold_pixels": drag_threshold_pixels,
		"host_surface": host_surface,
		"target_resolution": target_resolution,
	}

func to_runtime_context() -> Dictionary:
	return {
		"pointer_id": pointer_id,
		"drag_threshold_pixels": drag_threshold_pixels,
		"host_surface": host_surface,
		"target_resolution": target_resolution,
	}
