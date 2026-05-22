class_name AeroSpatialUiMouseProvider
extends RefCounted

const PROVIDER_LANE := "mouse"
const CONTRACT_OWNER_PACKAGE := "aerobeat-input-core"
const SHARED_HELPER_OWNER_PACKAGE := "aerobeat-spatial-ui-core"

func describe_boundary() -> Dictionary:
	return {
		"provider_lane": PROVIDER_LANE,
		"contract_owner_package": CONTRACT_OWNER_PACKAGE,
		"shared_helper_owner_package": SHARED_HELPER_OWNER_PACKAGE,
		"implements_runtime_behavior": false,
		"extracts_hybrid_proof_logic": false,
		"owns_native_2d_bridge": false,
		"owns_contract_definition": false,
	}
