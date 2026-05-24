extends RefCounted

const BUS_SCRIPT := preload("res://addons/aerobeat-input-core/src/ui/ui_interaction_bus.gd")
const ADAPTER_SCRIPT := preload("res://addons/aerobeat-input-core/src/ui/adapters/hybrid_subviewport_input_adapter.gd")
const SURFACE_DESCRIPTOR_SCRIPT := preload("res://addons/aerobeat-spatial-ui-core/src/helpers/surfaces/aero_spatial_surface_descriptor.gd")
const PROJECTION_HELPER_SCRIPT := preload("res://addons/aerobeat-spatial-ui-core/src/helpers/providers/aero_spatial_projection_helper.gd")
const PROVIDER_SCRIPT_PATH := "res://addons/aerobeat-spatial-ui-mouse/src/providers/mouse/aero_spatial_ui_mouse_provider.gd"
const CONFIG_SCRIPT_PATH := "res://addons/aerobeat-spatial-ui-mouse/src/providers/mouse/aero_spatial_ui_mouse_provider_config.gd"
const INTERACTION_TYPES := preload("res://addons/aerobeat-input-core/src/ui/ui_interaction_types.gd")

const SURFACE_ID: StringName = &"hybrid_mouse"
const POINTER_ID: StringName = &"mouse_0"
const PRIMARY_TARGET_PATH := NodePath("Root/PrimaryActionButton")
const SECONDARY_TARGET_PATH := NodePath("Root/SecondaryActionButton")
const PRIMARY_TARGET_RECT := Rect2(100.0, 100.0, 200.0, 200.0)
const SECONDARY_TARGET_RECT := Rect2(650.0, 100.0, 200.0, 200.0)

var _projection_helper = PROJECTION_HELPER_SCRIPT.new()

func spawn(test_case: GutTest, threshold := 12.0) -> Dictionary:
	var host := Node.new()
	host.name = "HarnessHost"
	test_case.add_child_autofree(host)
	await test_case.get_tree().process_frame
	var runtime := await attach_runtime(host, threshold)
	await test_case.get_tree().process_frame
	return runtime

func attach_runtime(host: Node, threshold := 12.0) -> Dictionary:
	var bus = BUS_SCRIPT.new()
	bus.name = "Bus"
	host.add_child(bus)
	var adapter = ADAPTER_SCRIPT.new()
	adapter.name = "Adapter"
	adapter.bus_path = NodePath("../Bus")
	adapter.surface_id = SURFACE_ID
	adapter.surface_type = INTERACTION_TYPES.SURFACE_TYPE_HYBRID_3D_GUI
	adapter.surface_pixel_size = Vector2(1000.0, 1000.0)
	adapter.drag_threshold_pixels = threshold
	host.add_child(adapter)
	await host.get_tree().process_frame

	var events: Array = []
	bus.interaction_event.connect(func(event): events.append(event))

	var config = load(CONFIG_SCRIPT_PATH).new()
	config.pointer_id = POINTER_ID
	config.drag_threshold_pixels = threshold
	config.host_surface = "PanelInputSurface"
	config.target_resolution = "rect_target_specs"
	var provider = load(PROVIDER_SCRIPT_PATH).new(config)
	return {
		"host": host,
		"bus": bus,
		"adapter": adapter,
		"provider": provider,
		"surface": _build_surface(),
		"events": events,
	}

func build_hit(surface, authored_uv: Vector2, screen_position: Vector2 = Vector2.ZERO) -> Dictionary:
	return _projection_helper.build_surface_hit(surface, authored_uv, {
		"screen_position": screen_position,
		"world_position": Vector3(authored_uv.x, authored_uv.y, 0.0),
		"world_normal": Vector3.UP,
		"world_direction": Vector3.FORWARD,
		"surface_size": surface.metadata.get("surface_size", Vector2.ZERO),
	})

func build_off_surface_hit(screen_position: Vector2 = Vector2.ZERO) -> Dictionary:
	return {
		"hit": false,
		"screen_position": screen_position,
		"world_direction": Vector3.FORWARD,
	}

func make_mouse_motion(screen_position: Vector2, relative: Vector2 = Vector2.ZERO, button_mask := 0) -> InputEventMouseMotion:
	var event := InputEventMouseMotion.new()
	event.position = screen_position
	event.relative = relative
	event.button_mask = button_mask
	return event

func make_mouse_button(screen_position: Vector2, pressed: bool, button_index := MOUSE_BUTTON_LEFT, button_mask := 0) -> InputEventMouseButton:
	var event := InputEventMouseButton.new()
	event.position = screen_position
	event.button_index = button_index
	event.pressed = pressed
	event.button_mask = button_mask
	return event

func describe_snapshot(provider, last_event = null) -> Dictionary:
	var runtime_state: Dictionary = provider.describe_runtime_state() if provider != null else {}
	return {
		"provider_lane": "mouse",
		"packaged_provider_active": provider != null,
		"provider_runtime_source": "AeroSpatialUiMouseProvider",
		"provider_runtime_seam": "installed_packaged_provider" if provider != null else "missing",
		"source_variant": str(last_event.source_variant) if last_event != null else "waiting",
		"phase": str(last_event.phase) if last_event != null else "waiting",
		"target_path": str(last_event.target_path) if last_event != null else "",
		"verification_status": str(last_event.verification_status) if last_event != null else "waiting",
		"verification_notes": str(last_event.verification_notes) if last_event != null else "No normalized interaction published yet.",
		"hover_target_path": str(runtime_state.get("hover_target_path", NodePath())),
		"capture_target_path": str(runtime_state.get("capture_target_path", NodePath())),
		"left_button_down": bool(runtime_state.get("left_button_down", false)),
		"last_live_target_path": str(runtime_state.get("last_live_target_path", NodePath())),
		"last_release_target_path": str(runtime_state.get("last_release_target_path", "")),
		"last_forwarded_panel_event": str(runtime_state.get("last_forwarded_panel_event", "waiting for projected mouse input")),
		"runtime_state": runtime_state,
	}

func _build_surface():
	var surface = SURFACE_DESCRIPTOR_SCRIPT.new()
	surface.configure({
		"surface_id": SURFACE_ID,
		"surface_path": NodePath("/root/PanelInputSurface"),
		"viewport_path": NodePath("/root/PanelViewport"),
		"surface_pixel_size": Vector2(1000.0, 1000.0),
		"authored_rect_normalized": Rect2(0.0, 0.0, 1.0, 1.0),
		"target_specs": [
			{
				"target_key": "primary",
				"target_name": "Primary Action Button",
				"target_path": PRIMARY_TARGET_PATH,
				"rect": PRIMARY_TARGET_RECT,
			},
			{
				"target_key": "secondary",
				"target_name": "Secondary Action Button",
				"target_path": SECONDARY_TARGET_PATH,
				"rect": SECONDARY_TARGET_RECT,
			}
		],
		"metadata": {
			"host_surface": "PanelInputSurface",
			"target_resolution": "rect_target_specs",
			"surface_size": Vector2(2.93, 1.577),
		},
	})
	return surface
