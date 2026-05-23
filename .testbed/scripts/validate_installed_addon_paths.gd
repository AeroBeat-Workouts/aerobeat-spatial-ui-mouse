extends SceneTree

const INSTALLED_MOUSE_PACKAGE_ROOT := "res://addons/aerobeat-spatial-ui-mouse"
const INSTALLED_MOUSE_PROVIDER_SCRIPT_PATH := INSTALLED_MOUSE_PACKAGE_ROOT + "/src/providers/mouse/aero_spatial_ui_mouse_provider.gd"
const INSTALLED_MOUSE_CONFIG_SCRIPT_PATH := INSTALLED_MOUSE_PACKAGE_ROOT + "/src/providers/mouse/aero_spatial_ui_mouse_provider_config.gd"
const INSTALLED_CORE_SURFACE_DESCRIPTOR_SCRIPT := preload("res://addons/aerobeat-spatial-ui-core/src/helpers/surfaces/aero_spatial_surface_descriptor.gd")
const INSTALLED_CORE_PROJECTION_HELPER_SCRIPT := preload("res://addons/aerobeat-spatial-ui-core/src/helpers/providers/aero_spatial_projection_helper.gd")

class AdapterRecorder:
	extends RefCounted

	var published_events: Array = []
	var published_phases: Array = []

	func publish_from_input_event(event: InputEvent, projected_data: Dictionary = {}, overrides: Dictionary = {}) -> bool:
		published_events.append({
			"event": event,
			"projected_data": projected_data.duplicate(true),
			"overrides": overrides.duplicate(true),
		})
		return true

	func publish_projected_phase(phase: StringName, pointer_id: StringName, projected_data: Dictionary = {}, overrides: Dictionary = {}) -> Dictionary:
		var record := {
			"phase": phase,
			"pointer_id": pointer_id,
			"projected_data": projected_data.duplicate(true),
			"overrides": overrides.duplicate(true),
		}
		published_phases.append(record)
		return record

func _init() -> void:
	var failures: Array[String] = []
	var required_paths := [
		INSTALLED_MOUSE_PROVIDER_SCRIPT_PATH,
		INSTALLED_MOUSE_CONFIG_SCRIPT_PATH,
	]

	for script_path in required_paths:
		if not ResourceLoader.exists(script_path):
			failures.append("missing installed addon script: %s" % script_path)
			continue
		var script = load(script_path)
		if script == null:
			failures.append("failed to load installed addon script: %s" % script_path)

	if failures.is_empty():
		var config = load(INSTALLED_MOUSE_CONFIG_SCRIPT_PATH).new()
		var provider = load(INSTALLED_MOUSE_PROVIDER_SCRIPT_PATH).new(config)
		var adapter := AdapterRecorder.new()
		var projection_helper = INSTALLED_CORE_PROJECTION_HELPER_SCRIPT.new()
		var surface = INSTALLED_CORE_SURFACE_DESCRIPTOR_SCRIPT.new().configure({
			"surface_id": &"installed_surface",
			"surface_pixel_size": Vector2(1000.0, 800.0),
			"authored_rect_normalized": Rect2(0.1, 0.2, 0.6, 0.5),
			"target_specs": [
				{
					"target_key": "primary_action",
					"target_name": "Primary Action",
					"target_path": NodePath("PreviewCenter/PrimaryActionButton"),
					"rect": Rect2(350.0, 300.0, 220.0, 120.0),
				}
			],
			"metadata": {
				"host_surface": "PanelInputSurface",
				"target_resolution": "rect_target_specs",
			}
		})
		var center_hit = projection_helper.build_surface_hit(surface, Vector2(0.5, 0.5), {
			"screen_position": Vector2(960.0, 540.0),
			"world_position": Vector3(1.0, 2.0, 3.0),
			"world_normal": Vector3(0.0, 0.0, 1.0),
			"world_direction": Vector3(0.0, 0.0, -1.0),
		})

		var motion := InputEventMouseMotion.new()
		motion.position = Vector2(960.0, 540.0)
		motion.button_mask = 0
		var press := InputEventMouseButton.new()
		press.button_index = MOUSE_BUTTON_LEFT
		press.pressed = true
		press.position = Vector2(960.0, 540.0)

		if not provider.publish_input_event(adapter, surface, motion, center_hit):
			failures.append("installed mouse provider did not publish hover motion")
		if not provider.publish_input_event(adapter, surface, press, center_hit):
			failures.append("installed mouse provider did not publish press")

		if adapter.published_events.size() < 2:
			failures.append("installed mouse provider did not publish expected event count")
		else:
			var press_projected: Dictionary = adapter.published_events[1].get("projected_data", {})
			if press_projected.get("target_path") != NodePath("PreviewCenter/PrimaryActionButton"):
				failures.append("installed mouse provider returned unexpected target path: %s" % press_projected.get("target_path"))
			if press_projected.get("raw_metadata", {}).get("matched_target_key") != "primary_action":
				failures.append("installed mouse provider did not carry packaged resolver metadata")

	if failures.is_empty():
		print("Installed-addon package smoke passed for aerobeat-spatial-ui-mouse")
		quit(0)
		return

	for failure in failures:
		push_error(failure)
	quit(1)
