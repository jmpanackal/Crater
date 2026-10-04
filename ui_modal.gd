extends Control
## The shell every opened panel shares (Standing, Rig): a soft dimmer, one iron plate centred, a title row and a close
## key. Subclasses fill `body` in _build_body() and refresh it in _refresh(). The panel closes on Esc or its own key.
## Panels are things you open; the HUD stays small (mechanics-canon section 55).

const UiStyleRef := preload("res://ui_style.gd")
const Glyph := preload("res://ui_glyph.gd")

var title_text := "Panel"
var title_glyph: StringName = &""
var toggle_action := ""
var plate_width := 460.0

var body: VBoxContainer
var _plate: PanelContainer
var _dimmer: ColorRect
var _open := false


func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	visible = false
	_dimmer = ColorRect.new()
	_dimmer.set_anchors_preset(Control.PRESET_FULL_RECT)
	_dimmer.color = Color(0.015, 0.025, 0.035, 0.5)
	_dimmer.mouse_filter = Control.MOUSE_FILTER_STOP
	_dimmer.gui_input.connect(func(e: InputEvent) -> void:
		if e is InputEventMouseButton and e.pressed:
			close())
	add_child(_dimmer)
	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(center)
	_plate = PanelContainer.new()
	_plate.custom_minimum_size = Vector2(plate_width, 0.0)
	_plate.add_theme_stylebox_override("panel", UiStyleRef.modal_panel_style())
	center.add_child(_plate)
	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 8)
	_plate.add_child(col)
	var head := HBoxContainer.new()
	head.add_theme_constant_override("separation", 8)
	if title_glyph != &"":
		var g := Control.new()
		g.set_script(Glyph)
		g.set("kind", title_glyph)
		g.custom_minimum_size = Vector2(20.0, 20.0)
		head.add_child(g)
	var t := Label.new()
	t.text = title_text.to_upper()
	UiStyleRef.apply_label(t, &"title")
	t.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	head.add_child(t)
	var key := Label.new()
	key.text = "Esc  close"
	UiStyleRef.apply_label(key, &"muted")
	head.add_child(key)
	col.add_child(head)
	col.add_child(_rule())
	body = VBoxContainer.new()
	body.add_theme_constant_override("separation", 6)
	col.add_child(body)
	_build_body()


func _rule() -> Control:
	var r := ColorRect.new()
	r.custom_minimum_size = Vector2(0.0, 1.0)
	r.color = UiStyleRef.BRASS_DIM
	r.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return r


func is_open() -> bool:
	return _open


func open() -> void:
	_open = true
	visible = true
	_fit()
	_last_sig = _signature()
	_refresh()


func close() -> void:
	_open = false
	visible = false


func toggle() -> void:
	if _open:
		close()
	else:
		open()


func _unhandled_input(event: InputEvent) -> void:
	if _open and event.is_action_pressed("ui_cancel"):
		close()
		get_viewport().set_input_as_handled()
		return
	if toggle_action != "" and InputMap.has_action(toggle_action) and event.is_action_pressed(toggle_action):
		toggle()
		get_viewport().set_input_as_handled()


## Rebuilt only when what it shows changes, never every frame (a rebuild under the mouse would eat clicks).
var _last_sig := ""


func _signature() -> String:
	return ""


func _fit() -> void:
	# a Control under a CanvasLayer has no parent Control to size against, so follow the viewport
	position = Vector2.ZERO
	size = get_viewport_rect().size


func _process(_delta: float) -> void:
	if not _open:
		return
	_fit()
	var sig := _signature()
	if sig != _last_sig:
		_last_sig = sig
		_refresh()


func _build_body() -> void:
	pass


func _refresh() -> void:
	pass


func clear_body() -> void:
	for c in body.get_children():
		c.queue_free()


static func ensure_key(action: String, keycode: Key) -> void:
	if InputMap.has_action(action):
		return
	InputMap.add_action(action)
	var ev := InputEventKey.new()
	ev.physical_keycode = keycode
	InputMap.action_add_event(action, ev)
