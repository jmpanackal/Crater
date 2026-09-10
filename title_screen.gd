extends Control
## Act 1 campaign shell — title → play. No Act 2 tease.

@onready var _continue_btn: Button = $Center/VBox/ContinueButton
@onready var _new_btn: Button = $Center/VBox/NewGameButton
@onready var _quit_btn: Button = $Center/VBox/QuitButton
@onready var _blurb: Label = $Center/VBox/Blurb

var _save_load: Node


func _ready() -> void:
	_save_load = get_tree().root.get_node_or_null("SaveLoad")
	if _blurb:
		_blurb.text = (
			"A secret dig in the Hollow.\n"
			+ "Keep Harvest. Keep Standing. Keep digging."
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
