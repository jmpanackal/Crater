extends CanvasLayer
## Lightweight talk UI for Hollow NPCs. Most talk is line dump; rare Yes/No.

signal closed
signal choice_made(accepted: bool)

const UiStyleRef := preload("res://ui_style.gd")

@onready var _panel: PanelContainer = $Panel
@onready var _name_label: Label = $Panel/Margin/VBox/NameLabel
@onready var _body: Label = $Panel/Margin/VBox/BodyLabel
@onready var _continue: Button = $Panel/Margin/VBox/ContinueButton
@onready var _choice_row: HBoxContainer = $Panel/Margin/VBox/ChoiceRow
@onready var _yes: Button = $Panel/Margin/VBox/ChoiceRow/YesButton
@onready var _no: Button = $Panel/Margin/VBox/ChoiceRow/NoButton

var _lines: PackedStringArray = PackedStringArray()
var _index := 0
var _choice_prompt := ""
var _awaiting_choice := false


func _ready() -> void:
	visible = false
	_apply_chrome()
	if _continue:
		_continue.focus_mode = Control.FOCUS_NONE
		_continue.pressed.connect(_on_continue)
	if _yes:
		_yes.focus_mode = Control.FOCUS_NONE
		_yes.pressed.connect(func() -> void: _finish_choice(true))
	if _no:
		_no.focus_mode = Control.FOCUS_NONE
		_no.pressed.connect(func() -> void: _finish_choice(false))
	if _choice_row:
		_choice_row.visible = false


func _apply_chrome() -> void:
	UiStyleRef.apply_panel(_panel, &"copper", true)
	UiStyleRef.apply_label(_name_label, &"accent")
	UiStyleRef.apply_label(_body, &"body")
	UiStyleRef.apply_button(_continue)
	UiStyleRef.apply_button(_yes)
	UiStyleRef.apply_button(_no)


func open_talk(speaker: String, lines: PackedStringArray, choice_prompt: String = "") -> void:
	_lines = lines
	_index = 0
	_choice_prompt = choice_prompt
	_awaiting_choice = false
	visible = true
	if _name_label:
		_name_label.text = speaker
	if _choice_row:
		_choice_row.visible = false
	if _continue:
		_continue.visible = true
		_continue.text = "Continue (Space / E)"
	_show_current()


func _show_current() -> void:
	if _index >= _lines.size():
		_maybe_choice_or_close()
		return
	if _body:
		_body.text = _lines[_index]


func _on_continue() -> void:
	if _awaiting_choice:
		return
	_index += 1
	if _index >= _lines.size():
		_maybe_choice_or_close()
	else:
		_show_current()


func _maybe_choice_or_close() -> void:
	if not _choice_prompt.is_empty():
		_awaiting_choice = true
		if _body:
			_body.text = _choice_prompt
		if _continue:
			_continue.visible = false
		if _choice_row:
			_choice_row.visible = true
		if _yes:
			_yes.text = "Yes (Y)"
		if _no:
			_no.text = "No (N)"
		return
	_close()


func _finish_choice(accepted: bool) -> void:
	choice_made.emit(accepted)
	_close()


func _close() -> void:
	visible = false
	_awaiting_choice = false
	closed.emit()


func _unhandled_input(event: InputEvent) -> void:
	if not visible:
		return
	if event is InputEventKey and event.pressed and not event.echo:
		var key := event as InputEventKey
		if _awaiting_choice:
			if key.keycode == KEY_Y:
				_finish_choice(true)
				get_viewport().set_input_as_handled()
			elif key.keycode == KEY_N:
				_finish_choice(false)
				get_viewport().set_input_as_handled()
			return
		if key.keycode == KEY_SPACE or key.keycode == KEY_E:
			_on_continue()
			get_viewport().set_input_as_handled()
			return
	if not _awaiting_choice and (
		event.is_action_pressed("ui_accept") or event.is_action_pressed("interact")
	):
		_on_continue()
		get_viewport().set_input_as_handled()
