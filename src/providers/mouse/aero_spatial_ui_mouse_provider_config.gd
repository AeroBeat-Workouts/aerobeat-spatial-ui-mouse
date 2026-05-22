class_name AeroSpatialUiMouseProviderConfig
extends RefCounted

const DEFAULT_PROVIDER_LANE := "mouse"

var contract_owner_package := "aerobeat-input-core"
var shared_helper_owner_package := "aerobeat-spatial-ui-core"
var extraction_phase := "phase_1_boundary_freeze"

func to_boundary_snapshot() -> Dictionary:
	return {
		"provider_lane": DEFAULT_PROVIDER_LANE,
		"contract_owner_package": contract_owner_package,
		"shared_helper_owner_package": shared_helper_owner_package,
		"extraction_phase": extraction_phase,
	}
