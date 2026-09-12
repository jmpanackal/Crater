extends Control
## Small separate Work Order objective tracker — not part of the main HUD strip.

const UiStyleRef := preload("res://ui_style.gd")

var _panel: PanelContainer
var _label: Label


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	anchor_left = 1.0
	anchor_top = 0.0
	anchor_right = 1.0
	anchor_bottom = 0.0
	offset_left = -280.0
	offset_top = 10.0
	offset_right = -12.0
	offset_bottom = 52.0
	grow_horizontal = Control.GROW_DIRECTION_BEGIN

	_panel = PanelContainer.new()
	_panel.name = "Panel"
	_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_panel.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	UiStyleRef.apply_panel(_panel, &"copper", true, true)
	_panel.modulate = Color(1, 1, 1, 0.78)
	add_child(_panel)

	_label = Label.new()
	_label.name = "Label"
	_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	UiStyleRef.apply_label(_label, &"muted")
	_label.add_theme_font_size_override("font_size", 12)
	_panel.add_child(_label)

	var wo := get_tree().root.get_node_or_null("WorkOrders")
	if wo:
		if wo.has_signal("work_order_changed"):
			wo.work_order_changed.connect(_refresh)
		_refresh()
	else:
		visible = false


func _refresh() -> void:
	var wo := get_tree().root.get_node_or_null("WorkOrders")
	if wo == null or not wo.has_method("get_tracker_text"):
		visible = false
		return
	var text: String = wo.get_tracker_text()
	if text == "":
		visible = false
		return
	visible = true
	if _label:
		_label.text = "Work Order\n%s" % text
