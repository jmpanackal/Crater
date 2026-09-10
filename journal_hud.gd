extends CanvasLayer
## Modal Journal for unlocked Records (toggle with J / Esc to close).

@onready var _dimmer: ColorRect = $Dimmer
@onready var _panel: PanelContainer = $Panel
@onready var _list: VBoxContainer = $Panel/Margin/VBox/List
@onready var _empty: Label = $Panel/Margin/VBox/EmptyLabel
@onready var _close_btn: Button = $Panel/Margin/VBox/CloseButton

var _journal: Node


func _ready() -> void:
	_journal = get_tree().root.get_node_or_null("Journal")
	_set_open(false)
	if _close_btn:
		_close_btn.focus_mode = Control.FOCUS_NONE
		_close_btn.pressed.connect(close)
	if _dimmer:
		_dimmer.gui_input.connect(_on_dimmer_input)
	if _journal:
		_journal.records_changed.connect(_refresh)
		_journal.record_unlocked.connect(_on_unlocked)
	_refresh()


func is_open() -> bool:
	return _panel != null and _panel.visible


func close() -> void:
	_set_open(false)


func open() -> void:
	_set_open(true)
	_refresh()


func _set_open(open_: bool) -> void:
	if _panel:
		_panel.visible = open_
	if _dimmer:
		_dimmer.visible = open_
	_set_world_chrome_visible(not open_)


func _set_world_chrome_visible(chrome_visible: bool) -> void:
	for node in get_tree().get_nodes_in_group("world_chrome"):
		if node is CanvasItem:
			(node as CanvasItem).visible = chrome_visible


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("toggle_journal") or (
		event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_J
	):
		if is_open():
			close()
		else:
			open()
		get_viewport().set_input_as_handled()
		return

	if is_open() and event.is_action_pressed("ui_cancel"):
		close()
		get_viewport().set_input_as_handled()


func _on_dimmer_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		close()


func _on_unlocked(_id: StringName) -> void:
	open()


func _refresh() -> void:
	if _list == null:
		return
	for child in _list.get_children():
		child.queue_free()

	if _journal == null:
		if _empty:
			_empty.visible = true
			_empty.text = "Journal unavailable."
		return

	var ids: Array = _journal.get_unlocked_ids()
	if _empty:
		_empty.visible = ids.is_empty()
		_empty.text = "No Records yet. Dig — especially toward the Cap."

	for id in ids:
		var def: Dictionary = _journal.get_def(id)
		var title := Label.new()
		title.text = str(def.get("title", id))
		title.add_theme_font_size_override("font_size", 15)
		_list.add_child(title)
		var body := Label.new()
		body.text = str(def.get("text", ""))
		body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		body.add_theme_font_size_override("font_size", 12)
		body.modulate = Color(0.9, 0.9, 0.9, 0.9)
		_list.add_child(body)
