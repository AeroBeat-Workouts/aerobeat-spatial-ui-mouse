class_name AeroSpatialUiMouseProvider
extends RefCounted

const PROJECTION_HELPER_SCRIPT := preload("res://addons/aerobeat-spatial-ui-core/src/helpers/providers/aero_spatial_projection_helper.gd")
const HOVER_CAPTURE_POLICY_SCRIPT := preload("res://addons/aerobeat-spatial-ui-core/src/helpers/policies/aero_spatial_hover_capture_policy.gd")
const RECT_TARGET_RESOLVER_SCRIPT_PATH := "res://addons/aerobeat-spatial-ui-core/src/helpers/providers/aero_spatial_rect_target_resolver.gd"
const INTERACTION_TYPES := preload("res://addons/aerobeat-input-core/src/ui/ui_interaction_types.gd")

const PROVIDER_LANE := "mouse"
const CONTRACT_OWNER_PACKAGE := "aerobeat-input-core"
const SHARED_HELPER_OWNER_PACKAGE := "aerobeat-spatial-ui-core"
const DEFAULT_POINTER_ID: StringName = &"mouse_0"
const DEFAULT_DRAG_THRESHOLD_PIXELS := 12.0

var pointer_id: StringName = DEFAULT_POINTER_ID
var drag_threshold_pixels := DEFAULT_DRAG_THRESHOLD_PIXELS
var host_surface := ""
var target_resolution := "rect_target_specs"

var _projection_helper = PROJECTION_HELPER_SCRIPT.new()
var _hover_capture_policy = HOVER_CAPTURE_POLICY_SCRIPT.new()
var _target_resolver = null
var _pointer_state: Dictionary = {}
var _left_button_down := false
var _last_projected_data: Dictionary = {}
var _last_live_target_path: NodePath = NodePath()
var _last_surface_hover_hit := false
var _last_release_target_path := ""
var _last_forwarded_panel_event := ""

func _init(config = null) -> void:
	_target_resolver = _build_target_resolver()
	_pointer_state = _hover_capture_policy.build_pointer_state()
	if config != null:
		apply_config(config)

func apply_config(config) -> void:
	if config == null:
		return
	pointer_id = config.pointer_id
	drag_threshold_pixels = config.drag_threshold_pixels
	host_surface = config.host_surface
	target_resolution = config.target_resolution

func describe_boundary() -> Dictionary:
	return {
		"provider_lane": PROVIDER_LANE,
		"contract_owner_package": CONTRACT_OWNER_PACKAGE,
		"shared_helper_owner_package": SHARED_HELPER_OWNER_PACKAGE,
		"implements_runtime_behavior": true,
		"extracts_mouse_provider_runtime": true,
		"extracts_hybrid_proof_logic": true,
		"owns_world_hit_acquisition": false,
		"owns_native_2d_bridge": false,
		"owns_contract_definition": false,
	}

func describe_runtime_state() -> Dictionary:
	return {
		"pointer_id": pointer_id,
		"hover_target_path": _pointer_state.get("hover_target_path", NodePath()),
		"capture_target_path": _pointer_state.get("capture_target_path", NodePath()),
		"hover_active": bool(_pointer_state.get("hover_active", false)),
		"capture_active": bool(_pointer_state.get("capture_active", false)),
		"left_button_down": _left_button_down,
		"last_live_target_path": _last_live_target_path,
		"last_surface_hover_hit": _last_surface_hover_hit,
		"last_release_target_path": _last_release_target_path,
		"last_forwarded_panel_event": _last_forwarded_panel_event,
		"last_projected_data": _last_projected_data.duplicate(true),
	}

func reset_runtime_state() -> void:
	_pointer_state = _hover_capture_policy.build_pointer_state()
	_left_button_down = false
	_last_projected_data = {}
	_last_live_target_path = NodePath()
	_last_surface_hover_hit = false
	_last_release_target_path = ""
	_last_forwarded_panel_event = ""

func publish_input_event(
	adapter,
	surface,
	event: InputEvent,
	projected_hit: Dictionary,
	context: Dictionary = {}
) -> bool:
	if adapter == null or surface == null or event == null or not surface.is_configured():
		return false

	if event is InputEventMouseButton:
		return _publish_mouse_button_event(adapter, surface, event, projected_hit, context)
	if event is InputEventMouseMotion:
		return _publish_mouse_motion_event(adapter, surface, event, projected_hit, context)
	return false

func _publish_mouse_button_event(
	adapter,
	surface,
	event: InputEventMouseButton,
	projected_hit: Dictionary,
	context: Dictionary
) -> bool:
	var has_hit: bool = bool(projected_hit.get("hit", false))
	var target_resolution_result: Dictionary = _resolve_target_for_hit(surface, projected_hit)
	var live_target_path: NodePath = target_resolution_result.get("target_path", NodePath()) if has_hit else NodePath()
	var resolution_metadata: Dictionary = target_resolution_result.get("raw_metadata", {}).duplicate(true) if has_hit else {}
	_last_surface_hover_hit = has_hit
	_last_live_target_path = live_target_path

	if event.pressed and not has_hit:
		return false
	if not event.pressed and not has_hit and not bool(_pointer_state.get("capture_active", false)):
		return false
	if event.button_index == MOUSE_BUTTON_LEFT and not event.pressed and not _left_button_down:
		_last_forwarded_panel_event = "ignore duplicate mouse release"
		return has_hit

	_update_mouse_hover_target(adapter, surface, event.position, projected_hit, live_target_path, resolution_metadata, context)

	var published_target_path := live_target_path
	if event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		_left_button_down = true
		_hover_capture_policy.begin_capture(_pointer_state, live_target_path)
		published_target_path = _pointer_state.get("capture_target_path", NodePath())
	elif bool(_pointer_state.get("capture_active", false)):
		published_target_path = _pointer_state.get("capture_target_path", NodePath())

	if not event.pressed and event.button_index == MOUSE_BUTTON_LEFT and not bool(_pointer_state.get("capture_active", false)) and published_target_path == NodePath():
		_last_forwarded_panel_event = "surface release with no owner"
		return has_hit

	var projected_data := _build_projected_data(surface, projected_hit, published_target_path, live_target_path, resolution_metadata, context)
	adapter.publish_from_input_event(event, projected_data, {"pointer_id": _resolve_pointer_id(context)})
	_last_projected_data = projected_data

	if not event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		_left_button_down = false
		_last_release_target_path = str(projected_data.get("target_path", NodePath()))
		_hover_capture_policy.release_capture(_pointer_state)
		if not has_hit:
			_update_mouse_hover_target(adapter, surface, event.position, {}, NodePath(), {}, context)

	_last_forwarded_panel_event = "publish mouse %s -> %.0f, %.0f • %s" % [
		"press" if event.pressed else "release",
		Vector2(projected_data.get("surface_position", Vector2.ZERO)).x,
		Vector2(projected_data.get("surface_position", Vector2.ZERO)).y,
		_path_label(projected_data.get("target_path", NodePath()))
	]
	return true

func _publish_mouse_motion_event(
	adapter,
	surface,
	event: InputEventMouseMotion,
	projected_hit: Dictionary,
	context: Dictionary
) -> bool:
	var has_hit: bool = bool(projected_hit.get("hit", false))
	var target_resolution_result: Dictionary = _resolve_target_for_hit(surface, projected_hit)
	var live_target_path: NodePath = target_resolution_result.get("target_path", NodePath()) if has_hit else NodePath()
	var resolution_metadata: Dictionary = target_resolution_result.get("raw_metadata", {}).duplicate(true) if has_hit else {}
	_last_surface_hover_hit = has_hit
	_last_live_target_path = live_target_path

	if _left_button_down and (event.button_mask & MOUSE_BUTTON_MASK_LEFT) == 0:
		_publish_mouse_release_from_motion(adapter, surface, event, projected_hit, context)
		has_hit = bool(projected_hit.get("hit", false))
		target_resolution_result = _resolve_target_for_hit(surface, projected_hit)
		live_target_path = target_resolution_result.get("target_path", NodePath()) if has_hit else NodePath()
		resolution_metadata = target_resolution_result.get("raw_metadata", {}).duplicate(true) if has_hit else {}
		_last_surface_hover_hit = has_hit
		_last_live_target_path = live_target_path

	if not has_hit and not bool(_pointer_state.get("capture_active", false)) and _pointer_state.get("hover_target_path", NodePath()) == NodePath():
		return false

	_update_mouse_hover_target(adapter, surface, event.position, projected_hit, live_target_path, resolution_metadata, context)

	if not bool(_pointer_state.get("capture_active", false)) and live_target_path == NodePath():
		_last_forwarded_panel_event = "surface motion -> no interactive target"
		return has_hit or bool(_pointer_state.get("hover_active", false))

	var published_target_path: NodePath = _hover_capture_policy.resolve_published_target_path(_pointer_state, live_target_path)
	var projected_data := _build_projected_data(surface, projected_hit, published_target_path, live_target_path, resolution_metadata, context)
	adapter.publish_from_input_event(event, projected_data, {"pointer_id": _resolve_pointer_id(context)})
	_last_projected_data = projected_data
	_last_forwarded_panel_event = "publish mouse motion -> %.0f, %.0f • hover %s • owner %s%s" % [
		Vector2(projected_data.get("surface_position", Vector2.ZERO)).x,
		Vector2(projected_data.get("surface_position", Vector2.ZERO)).y,
		_path_label(live_target_path),
		_path_label(_pointer_state.get("capture_target_path", NodePath())),
		" (captured)" if bool(_pointer_state.get("capture_active", false)) else ""
	]
	return true

func _publish_mouse_release_from_motion(
	adapter,
	surface,
	event: InputEventMouseMotion,
	projected_hit: Dictionary,
	context: Dictionary
) -> void:
	var synthetic_release := InputEventMouseButton.new()
	synthetic_release.button_index = MOUSE_BUTTON_LEFT
	synthetic_release.pressed = false
	synthetic_release.position = event.position
	synthetic_release.button_mask = event.button_mask
	_publish_mouse_button_event(adapter, surface, synthetic_release, projected_hit, context)
	_last_forwarded_panel_event = "publish mouse release (motion button mask drop) -> %.0f, %.0f • hover %s • owner %s" % [
		Vector2(projected_hit.get("authored_viewport_position", projected_hit.get("viewport_position", _last_projected_data.get("surface_position", Vector2.ZERO)))).x,
		Vector2(projected_hit.get("authored_viewport_position", projected_hit.get("viewport_position", _last_projected_data.get("surface_position", Vector2.ZERO)))).y,
		_path_label(_last_live_target_path),
		_path_label(_pointer_state.get("capture_target_path", NodePath()))
	]

func _update_mouse_hover_target(
	adapter,
	surface,
	screen_position: Vector2,
	projected_hit: Dictionary,
	new_target_path: NodePath,
	resolution_metadata: Dictionary,
	context: Dictionary
) -> void:
	var current_target_path: NodePath = _pointer_state.get("hover_target_path", NodePath())
	if current_target_path == new_target_path:
		_pointer_state["hover_active"] = new_target_path != NodePath()
		return

	var next_state: Dictionary = _pointer_state.duplicate(true)
	var transition: Dictionary = _hover_capture_policy.update_hover_target(next_state, new_target_path)
	var previous_target_path: NodePath = transition.get("previous_target_path", NodePath())
	if previous_target_path != NodePath():
		_publish_hover_phase(
			adapter,
			surface,
			INTERACTION_TYPES.PHASE_HOVER_EXIT,
			screen_position,
			projected_hit,
			_last_projected_data,
			previous_target_path,
			new_target_path,
			resolution_metadata,
			context
		)
	if new_target_path != NodePath():
		_publish_hover_phase(
			adapter,
			surface,
			INTERACTION_TYPES.PHASE_HOVER_ENTER,
			screen_position,
			projected_hit,
			_last_projected_data,
			new_target_path,
			new_target_path,
			resolution_metadata,
			context
		)
	_pointer_state = next_state

func _publish_hover_phase(
	adapter,
	surface,
	phase: StringName,
	screen_position: Vector2,
	projected_hit: Dictionary,
	previous_projected: Dictionary,
	target_path: NodePath,
	live_target_path: NodePath,
	resolution_metadata: Dictionary,
	context: Dictionary
) -> void:
	var projected_data := _build_projected_data(
		surface,
		projected_hit,
		target_path,
		live_target_path,
		resolution_metadata,
		context,
		previous_projected
	)
	adapter.publish_projected_phase(phase, _resolve_pointer_id(context), projected_data, {
		"source_type": INTERACTION_TYPES.SOURCE_TYPE_MOUSE,
		"source_variant": INTERACTION_TYPES.SOURCE_VARIANT_SCREEN_MOUSE,
		"button": INTERACTION_TYPES.BUTTON_PRIMARY,
		"primary": true,
		"pressed": false,
		"raw_event_class": &"AeroSpatialUiMouseHoverProjection",
		"raw_metadata": {
			"host_phase": str(phase),
			"hover_continuity": "world_ray_projection",
			"live_target_path": str(live_target_path),
			"published_target_path": str(target_path),
		}
	})

func _build_target_resolver():
	var resolver_script = load(RECT_TARGET_RESOLVER_SCRIPT_PATH)
	if resolver_script == null:
		push_error("AeroSpatialUiMouseProvider could not load packaged rect-target resolver: %s" % RECT_TARGET_RESOLVER_SCRIPT_PATH)
		return null
	return resolver_script.new()

func _resolve_target_for_hit(surface, projected_hit: Dictionary) -> Dictionary:
	if _target_resolver == null:
		return {"target_path": NodePath(), "raw_metadata": {"resolution_mode": "rect_target_specs"}}
	var resolution_result = _target_resolver.resolve_target(surface, projected_hit)
	if resolution_result == null:
		return {"target_path": NodePath(), "raw_metadata": {"resolution_mode": "rect_target_specs"}}
	return {
		"target_path": resolution_result.target_path,
		"raw_metadata": resolution_result.raw_metadata.duplicate(true),
	}

func _build_projected_data(
	surface,
	projected_hit: Dictionary,
	published_target_path: NodePath,
	live_target_path: NodePath,
	resolution_metadata: Dictionary,
	context: Dictionary,
	previous_projected: Dictionary = {}
) -> Dictionary:
	var extra_raw_metadata := resolution_metadata.duplicate(true)
	extra_raw_metadata["host_surface"] = _resolve_host_surface(surface, context)
	extra_raw_metadata["target_resolution"] = _resolve_target_resolution(surface, context)
	extra_raw_metadata["live_target_path"] = str(live_target_path)
	extra_raw_metadata["published_target_path"] = str(published_target_path)
	extra_raw_metadata["hover_target_path"] = str(_pointer_state.get("hover_target_path", NodePath()))
	extra_raw_metadata["owner_target_path"] = str(_pointer_state.get("capture_target_path", NodePath()))
	return _projection_helper.build_projected_data(
		surface,
		projected_hit,
		previous_projected if not previous_projected.is_empty() else _last_projected_data,
		published_target_path,
		live_target_path,
		extra_raw_metadata
	)

func _resolve_pointer_id(context: Dictionary) -> StringName:
	return StringName(context.get("pointer_id", pointer_id))

func _resolve_host_surface(surface, context: Dictionary) -> String:
	if context.has("host_surface"):
		return str(context.get("host_surface", ""))
	if host_surface != "":
		return host_surface
	return str(surface.metadata.get("host_surface", ""))

func _resolve_target_resolution(surface, context: Dictionary) -> String:
	if context.has("target_resolution"):
		return str(context.get("target_resolution", ""))
	if target_resolution != "":
		return target_resolution
	return str(surface.metadata.get("target_resolution", "rect_target_specs"))

func _path_label(path: Variant) -> String:
	if path is NodePath and path == NodePath():
		return "none"
	var path_text := str(path)
	if path_text == "":
		return "none"
	return path_text.get_file()
