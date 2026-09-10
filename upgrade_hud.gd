extends VBoxContainer
## Hollow siphon panel: cover + compact district rates + upgrade buttons.
## Primary Harvest/Standing live on sibling StatusLabel (always visible).

signal lie_choice(lied: bool)

@onready var _cover_label: Label = $CoverLabel
@onready var _district_label: Label = $DistrictLabel
@onready var _siphon_list: VBoxContainer = $SiphonList

var _status_label: Label
var _notice_label: Label
var _lie_box: VBoxContainer
var _lie_yes: Button
var _lie_no: Button

var _upgrades: Node
var _wallet: Node
var _community: Node
var _districts: Node
var _siphon_buttons: Dictionary = {}
var _notice_ttl := 0.0
## Siphon buttons stay collapsed until U (or a click expand) — Cover/districts stay.
var _siphon_expanded := false
var _expand_hint: Label


func _ready() -> void:
	var ui := get_parent()
	if ui:
		_status_label = ui.get_node_or_null("StatusLabel") as Label
		_notice_label = ui.get_node_or_null("NoticeLabel") as Label
		_lie_box = ui.get_node_or_null("LiePrompt") as VBoxContainer
		if _lie_box:
			_lie_yes = _lie_box.get_node_or_null("YesButton") as Button
			_lie_no = _lie_box.get_node_or_null("NoButton") as Button

	_upgrades = get_tree().root.get_node_or_null("Upgrades")
	_wallet = get_tree().root.get_node_or_null("Resources")
	_community = get_tree().root.get_node_or_null("Community")
	_districts = get_tree().root.get_node_or_null("Districts")

	if _community:
		_community.skip_lie_prompt = false
		_community.harvest_timer_changed.connect(_on_harvest_timer_changed)
		_community.social_standing_changed.connect(_on_standing_changed)
		_community.harvest_completed.connect(_on_harvest_completed)
		_community.harvest_miss_prompt.connect(_on_harvest_miss_prompt)
		_community.notice_message.connect(_show_notice)

	if _upgrades:
		_upgrades.upgrade_changed.connect(_on_upgrade_changed)
		_upgrades.siphon_station_changed.connect(_on_siphon_station_changed)
		_upgrades.siphon_result.connect(_on_siphon_result)

	if _wallet:
		_wallet.resource_changed.connect(_on_resource_changed)
	if _districts:
		_districts.district_changed.connect(_on_district_changed)
		_districts.cover_changed.connect(_on_cover_changed)

	if _lie_yes:
		_lie_yes.focus_mode = Control.FOCUS_NONE
		_lie_yes.pressed.connect(func() -> void: _resolve_lie(true))
	if _lie_no:
		_lie_no.focus_mode = Control.FOCUS_NONE
		_lie_no.pressed.connect(func() -> void: _resolve_lie(false))
	if _lie_box:
		_lie_box.visible = false

	_ensure_expand_hint()
	_build_siphon_buttons()
	_refresh_status()
	_refresh()


func _ensure_expand_hint() -> void:
	if _expand_hint != null or _siphon_list == null:
		return
	_expand_hint = Label.new()
	_expand_hint.name = "SiphonExpandHint"
	_expand_hint.text = "Siphon [U]"
	_expand_hint.add_theme_font_size_override("font_size", 12)
	_expand_hint.modulate = Color(0.9, 0.82, 0.55, 0.9)
	# Insert above the button list.
	add_child(_expand_hint)
	move_child(_expand_hint, _siphon_list.get_index())


func _process(delta: float) -> void:
	if _notice_ttl > 0.0:
		_notice_ttl -= delta
		if _notice_ttl <= 0.0 and _notice_label:
			_notice_label.visible = false


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("siphon_upgrade"):
		_try_siphon_default()
		get_viewport().set_input_as_handled()


func _build_siphon_buttons() -> void:
	if _siphon_list == null or _upgrades == null:
		return
	for child in _siphon_list.get_children():
		child.queue_free()
	_siphon_buttons.clear()

	for id in _upgrades.get_upgrade_ids():
		var upgrade_id: StringName = id
		var btn := Button.new()
		btn.focus_mode = Control.FOCUS_NONE
		btn.name = String(upgrade_id)
		btn.custom_minimum_size = Vector2(0, 26)
		btn.add_theme_font_size_override("font_size", 13)
		btn.pressed.connect(_try_siphon.bind(upgrade_id))
		_siphon_list.add_child(btn)
		_siphon_buttons[upgrade_id] = btn


func _try_siphon_default() -> void:
	if _upgrades == null:
		return
	if not _siphon_expanded:
		_siphon_expanded = true
		_refresh()
	_try_siphon(_upgrades.DIG_YIELD)


func _try_siphon(upgrade_id: StringName) -> void:
	if _upgrades == null:
		return
	if not _siphon_expanded:
		_siphon_expanded = true
	_upgrades.siphon_for_upgrade(upgrade_id)
	_refresh()


func _on_upgrade_changed(_upgrade_id: StringName, _new_level: int) -> void:
	_refresh()


func _on_resource_changed(_resource_id: StringName, _new_amount: int) -> void:
	_refresh()


func _on_siphon_station_changed(_is_open: bool) -> void:
	if _upgrades and not _upgrades.is_siphon_station_open():
		_siphon_expanded = false
	_refresh()


func _on_harvest_timer_changed(_seconds: float) -> void:
	_refresh_status()


func _on_standing_changed(_value: int) -> void:
	_refresh_status()


func _on_harvest_completed(_missed: bool) -> void:
	_refresh_status()
	_refresh()


func _on_district_changed(_id: StringName) -> void:
	_refresh_districts()


func _on_cover_changed(_cover: float) -> void:
	_refresh_districts()


func _on_siphon_result(_id: StringName, noticed: bool) -> void:
	if noticed:
		return
	_show_notice("Siphon complete. Cover held.")


func _on_harvest_miss_prompt() -> void:
	if _lie_box:
		_lie_box.visible = true


func _resolve_lie(lied: bool) -> void:
	if _lie_box:
		_lie_box.visible = false
	if _community and _community.has_method("resolve_harvest_miss"):
		_community.resolve_harvest_miss(lied)
	lie_choice.emit(lied)
	_refresh_status()
	_refresh()


func _show_notice(text: String) -> void:
	if _notice_label == null:
		return
	_notice_label.text = text
	_notice_label.visible = true
	_notice_ttl = 4.5


func _refresh() -> void:
	if _upgrades == null:
		visible = false
		return

	var in_hollow: bool = _upgrades.is_siphon_station_open()
	visible = in_hollow
	if not in_hollow:
		_siphon_expanded = false
		return

	_refresh_districts()
	_refresh_siphon_buttons()
	if _siphon_list:
		_siphon_list.visible = _siphon_expanded
	if _expand_hint:
		_expand_hint.visible = not _siphon_expanded
		_expand_hint.text = "Siphon [U]"


func _refresh_status() -> void:
	if _status_label == null:
		return
	if _community == null:
		_status_label.text = "Harvest ? · Standing ?"
		return

	var lie_tag := ""
	if _community.has_pending_lie():
		lie_tag = " · lie pending"
	_status_label.text = "Harvest %ds · Standing %d/%d%s" % [
		int(ceil(_community.get_harvest_seconds_remaining())),
		_community.get_social_standing(),
		_community.SOCIAL_STANDING_MAX,
		lie_tag,
	]


func _refresh_districts() -> void:
	if _districts == null:
		if _cover_label:
			_cover_label.text = "Cover ?"
		if _district_label:
			_district_label.text = ""
		return

	var cover: float = _districts.get_cover_health()
	var notice: float = _districts.get_siphon_notice_chance()
	if _cover_label:
		_cover_label.text = "Cover %d%% · notice ~%d%%" % [
			int(round(cover * 100.0)),
			int(round(notice * 100.0)),
		]

	if _district_label:
		var parts: PackedStringArray = PackedStringArray()
		for id in _districts.get_district_ids():
			var short_name := _short_district_name(id)
			parts.append(
				"%s %.0f (%.1f/s)"
				% [short_name, _districts.get_stock(id), _districts.get_rate(id)]
			)
		_district_label.text = " · ".join(parts)


func _short_district_name(id: StringName) -> String:
	match String(id):
		"farms":
			return "Farms"
		"wickwork":
			return "Wick"
		"cistern":
			return "Cistern"
		_:
			return _districts.get_display_name(id) if _districts else String(id)


func _refresh_siphon_buttons() -> void:
	if _upgrades == null:
		return
	for id in _siphon_buttons.keys():
		var btn: Button = _siphon_buttons[id]
		var level: int = _upgrades.get_level(id)
		var cost: int = _upgrades.get_next_cost(id)
		var mark := "E" if _upgrades.is_efficiency(id) else "F"
		var suffix := ""
		if id == _upgrades.DIG_YIELD:
			suffix = " · %d/dig [U]" % _upgrades.get_dig_salvage_yield()
		btn.text = "%s %s Lv%d — %d%s" % [
			mark,
			_upgrades.get_display_name(id),
			level,
			cost,
			suffix,
		]
		btn.disabled = not _upgrades.can_siphon(id)
