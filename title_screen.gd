extends Control
## Act 1 campaign shell — title → play. No Act 2 tease.
## Quiet INMOST-leaning presentation: ink void, lantern warmth, soft vignette.

const UiStyleRef := preload("res://ui_style.gd")

@onready var _continue_btn: Button = $Center/VBox/ContinueButton
@onready var _new_btn: Button = $Center/VBox/NewGameButton
@onready var _quit_btn: Button = $Center/VBox/QuitButton
@onready var _blurb: Label = $Center/VBox/Blurb
@onready var _title: Label = $Center/VBox/Title
@onready var _subtitle: Label = $Center/VBox/Subtitle

var _save_load: Node
var _breathe_t := 0.0


func _ready() -> void:
	_save_load = get_tree().root.get_node_or_null("SaveLoad")
	_ensure_quiet_atmosphere()
	_apply_chrome()
	if _blurb:
		_blurb.text = (
			"A secret dig in the Hollow.\n"
			+ "Climb the terraces (W/S). Keep Harvest. Keep Trust."
		)
	if _continue_btn:
		_continue_btn.focus_mode = Control.FOCUS_ALL
		_continue_btn.pressed.connect(_on_continue)
		_continue_btn.disabled = _save_load == null or not _save_load.has_save()
	if _new_btn:
		_new_btn.focus_mode = Control.FOCUS_ALL
		_new_btn.pressed.connect(_on_new_game)
	if _quit_btn:
		_quit_btn.focus_mode = Control.FOCUS_ALL
		_quit_btn.pressed.connect(func() -> void: get_tree().quit())


func _apply_chrome() -> void:
	if _title:
		_title.add_theme_font_size_override("font_size", 52)
		_title.add_theme_color_override("font_color", Color(0.88, 0.9, 0.86, 0.96))
	if _subtitle:
		UiStyleRef.apply_label(_subtitle, &"teal")
		_subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	if _blurb:
		UiStyleRef.apply_label(_blurb, &"muted")
		_blurb.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	for btn in [_continue_btn, _new_btn, _quit_btn]:
		UiStyleRef.apply_button(btn)
		if btn:
			btn.custom_minimum_size = Vector2(240, 38)


func _process(delta: float) -> void:
	_breathe_t += delta
	var glow := get_node_or_null("WarmGlow") as ColorRect
	if glow:
		# Barely-there lantern breathe — presence, not sparkle.
		glow.color.a = 0.14 + 0.05 * (0.5 + 0.5 * sin(_breathe_t * 0.7))


func _ensure_quiet_atmosphere() -> void:
	var backdrop := get_node_or_null("Backdrop") as ColorRect
	if backdrop:
		backdrop.color = Color(0.04, 0.07, 0.08, 1.0)

	var glow := get_node_or_null("WarmGlow") as ColorRect
	if glow:
		glow.color = Color(0.45, 0.26, 0.1, 0.16)
		glow.offset_left = 120.0
		glow.offset_top = 240.0
		glow.offset_right = 400.0
		glow.offset_bottom = 480.0

	if get_node_or_null("PitHint") == null:
		var pit := ColorRect.new()
		pit.name = "PitHint"
		pit.set_anchors_preset(Control.PRESET_FULL_RECT)
		pit.offset_left = 420.0
		pit.offset_top = 80.0
		pit.offset_right = -80.0
		pit.offset_bottom = -40.0
		pit.color = Color(0.01, 0.02, 0.03, 0.55)
		pit.mouse_filter = Control.MOUSE_FILTER_IGNORE
		pit.z_index = -1
		add_child(pit)
		move_child(pit, 1)

	# Soft edge ink only — keep title readable (no full-screen wash).
	if get_node_or_null("EdgeInkTop") == null:
		for spec in [
			["EdgeInkTop", Vector2(0, 0), Vector2(1, 0), Vector2(0, 0), Vector2(0, 70)],
			["EdgeInkBottom", Vector2(0, 1), Vector2(1, 1), Vector2(0, -90), Vector2(0, 0)],
		]:
			var edge := ColorRect.new()
			edge.name = str(spec[0])
			edge.anchor_left = (spec[1] as Vector2).x
			edge.anchor_top = (spec[1] as Vector2).y
			edge.anchor_right = (spec[2] as Vector2).x
			edge.anchor_bottom = (spec[2] as Vector2).y
			edge.offset_left = (spec[3] as Vector2).x
			edge.offset_top = (spec[3] as Vector2).y
			edge.offset_right = (spec[4] as Vector2).x
			edge.offset_bottom = (spec[4] as Vector2).y
			edge.color = Color(0.0, 0.0, 0.0, 0.35)
			edge.mouse_filter = Control.MOUSE_FILTER_IGNORE
			edge.z_index = -1
			add_child(edge)
			move_child(edge, 1)


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_F11:
		var mode := DisplayServer.window_get_mode()
		if mode == DisplayServer.WINDOW_MODE_FULLSCREEN or mode == DisplayServer.WINDOW_MODE_EXCLUSIVE_FULLSCREEN:
			DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_MAXIMIZED)
		else:
			DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
		get_viewport().set_input_as_handled()


func _on_continue() -> void:
	if _save_load:
		_save_load.load_game()
	get_tree().change_scene_to_file("res://main.tscn")


func _on_new_game() -> void:
	if _save_load and _save_load.has_method("new_game"):
		_save_load.new_game()
	get_tree().change_scene_to_file("res://main.tscn")


## Test helper — quiet atmosphere nodes present.
func has_quiet_atmosphere() -> bool:
	return (
		get_node_or_null("PitHint") != null
		and get_node_or_null("EdgeInkTop") != null
		and get_node_or_null("EdgeInkBottom") != null
	)
