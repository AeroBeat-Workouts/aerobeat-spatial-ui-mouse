extends Control

const HARNESS_SCRIPT := preload("res://tests/support/mouse_provider_test_harness.gd")

@onready var status_label: RichTextLabel = get_node_or_null("Margin/Content/Status") as RichTextLabel

var _harness = HARNESS_SCRIPT.new()
var _runtime: Dictionary = {}
var _last_event = null

func _ready() -> void:
	await _boot_runtime()
	_refresh_status()

func _boot_runtime() -> void:
	_runtime = await _harness.attach_runtime(self)
	var bus = _runtime.get("bus")
	if bus != null and not bus.interaction_event.is_connected(_on_interaction_event):
		bus.interaction_event.connect(_on_interaction_event)

func describe_hud_snapshot() -> Dictionary:
	var provider = _runtime.get("provider", null)
	return _harness.describe_snapshot(provider, _last_event)

func publish_mouse_motion(surface_uv: Vector2, screen_position: Vector2, relative: Vector2 = Vector2.ZERO, button_mask := 0) -> bool:
	return _publish_event(
		_harness.make_mouse_motion(screen_position, relative, button_mask),
		_harness.build_hit(_runtime.get("surface"), surface_uv, screen_position)
	)

func publish_mouse_button(surface_uv: Vector2, screen_position: Vector2, pressed: bool, button_mask := 0) -> bool:
	return _publish_event(
		_harness.make_mouse_button(screen_position, pressed, MOUSE_BUTTON_LEFT, button_mask),
		_harness.build_hit(_runtime.get("surface"), surface_uv, screen_position)
	)

func publish_off_surface_release(screen_position: Vector2) -> bool:
	return _publish_event(
		_harness.make_mouse_button(screen_position, false, MOUSE_BUTTON_LEFT),
		_harness.build_off_surface_hit(screen_position)
	)

func _publish_event(event: InputEvent, projected_hit: Dictionary) -> bool:
	var provider = _runtime.get("provider", null)
	var adapter = _runtime.get("adapter", null)
	var surface = _runtime.get("surface", null)
	if provider == null or adapter == null or surface == null:
		return false
	var published: bool = provider.publish_input_event(adapter, surface, event, projected_hit, {
		"pointer_id": HARNESS_SCRIPT.POINTER_ID,
		"host_surface": "PanelInputSurface",
		"target_resolution": "rect_target_specs",
	})
	_refresh_status()
	return published

func _on_interaction_event(event) -> void:
	_last_event = event
	_refresh_status()

func _refresh_status() -> void:
	if status_label == null:
		return
	var snapshot := describe_hud_snapshot()
	var lines := [
		"[b]Mouse provider verification harness[/b]",
		"[color=#cbd5e1]provider lane:[/color] %s" % snapshot.get("provider_lane", "mouse"),
		"[color=#cbd5e1]packaged provider seam:[/color] %s" % snapshot.get("provider_runtime_source", "missing"),
		"[color=#cbd5e1]source variant:[/color] %s" % snapshot.get("source_variant", "waiting"),
		"[color=#cbd5e1]phase:[/color] %s" % snapshot.get("phase", "waiting"),
		"[color=#cbd5e1]target path:[/color] %s" % _path_label(snapshot.get("target_path", "")),
		"[color=#cbd5e1]verification status:[/color] %s" % snapshot.get("verification_status", "waiting"),
		"[color=#cbd5e1]verification notes:[/color] %s" % snapshot.get("verification_notes", "No normalized interaction published yet."),
		"",
		"[b]mouse runtime snapshot[/b]",
		"hover_target_path = %s" % _path_label(snapshot.get("hover_target_path", "")),
		"capture_target_path = %s" % _path_label(snapshot.get("capture_target_path", "")),
		"left_button_down = %s" % str(snapshot.get("left_button_down", false)),
		"last_live_target_path = %s" % _path_label(snapshot.get("last_live_target_path", "")),
		"last_release_target_path = %s" % _path_label(snapshot.get("last_release_target_path", "")),
		"last_forwarded_panel_event = %s" % snapshot.get("last_forwarded_panel_event", "waiting for projected mouse input"),
	]
	status_label.text = "
".join(lines)

func _path_label(path: Variant) -> String:
	var path_text := str(path)
	if path_text == "":
		return "none"
	if path is NodePath and path == NodePath():
		return "none"
	return path_text
