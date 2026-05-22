class_name AeroSpatialUiMouseRuntimeBoundary
extends RefCounted

static func describe_non_goals() -> PackedStringArray:
	return PackedStringArray([
		"no canonical interaction contract types",
		"no native 2D bridge logic",
		"no concrete world-hit or projection behavior yet",
		"no extracted hybrid proof implementation yet",
	])

static func describe_dependencies() -> Dictionary:
	return {
		"contract_owner_package": "aerobeat-input-core",
		"shared_helper_owner_package": "aerobeat-spatial-ui-core",
		"provider_lane": "mouse",
	}
