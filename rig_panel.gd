extends "res://ui_modal.gd"
## The Rig view: the player's tools (canon sections 34 to 36). Gear slots (3 now, growing toward 5) and Rig Capacity
## are separate: the sockets show what is mounted, the capacity bar shows what the Rig is asked to carry, and going past
## it is Rig Strain (a block on the stamina bar), shown in red. Mounting and unmounting only work at a proper Rig
## station (Rig enforces that itself); away from one this panel is a read-only look at the Rig and says why. Opens with
## [G], or by Interact at a station. Approved Gear only: nothing secret is listed. Reads and drives the Rig autoload.

var _message := ""
var _message_ttl := 0.0


func _init() -> void:
	title_text = "Rig"
	toggle_action = "rig_view"
	plate_width = 500.0
	ensure_key("rig_view", KEY_G)


func _ready() -> void:
	super._ready()
	# a station's Interact opens this panel (rig_station.gd emits `opened` for exactly this)
	for n in get_tree().root.find_children("*", "Area2D", true, false):
		if n.has_signal("opened") and not n.opened.is_connected(_on_station_opened):
			n.opened.connect(_on_station_opened)


func _on_station_opened(_station: Node, _rig: Node) -> void:
	open()


func _signature() -> String:
	var rig := get_node_or_null("/root/Rig")
	if rig == null:
		return "none"
	return "%s|%s|%d|%d|%s|%s" % [str(rig.get_equipped()), str(rig.get_owned_gear()), rig.get_capacity_used(), rig.get_slot_count(), str(rig.can_equip_at_current_location()), _message]


func _process(delta: float) -> void:
	if _message_ttl > 0.0:
		_message_ttl = maxf(0.0, _message_ttl - delta)
		if _message_ttl == 0.0:
			_message = ""
	super._process(delta)


func _refresh() -> void:
	clear_body()
	var rig := get_node_or_null("/root/Rig")
	if rig == null:
		var none := Label.new()
		none.text = "The Rig is not available."
		UiStyleRef.apply_label(none, &"muted")
		body.add_child(none)
		return
	var at_station: bool = rig.can_equip_at_current_location()
	var where := Label.new()
	where.text = "At a Rig station: you can refit." if at_station else "Not at a station: refits are done at home, a workbench or Wickwork."
	UiStyleRef.apply_label(where, &"teal" if at_station else &"muted")
	body.add_child(where)
	# capacity
	var used: int = rig.get_capacity_used()
	var cap: int = rig.get_capacity()
	var cap_row := HBoxContainer.new()
	cap_row.add_theme_constant_override("separation", 3)
	var cap_label := Label.new()
	cap_label.text = "Capacity  "
	UiStyleRef.apply_label(cap_label, &"accent")
	cap_row.add_child(cap_label)
	for p in range(maxi(cap, used)):
		var pip := ColorRect.new()
		pip.custom_minimum_size = Vector2(10.0, 10.0)
		pip.color = Color(0.14, 0.13, 0.11)
		if p < mini(used, cap):
			pip.color = UiStyleRef.LAMP_AMBER
		elif p >= cap and p < used:
			pip.color = UiStyleRef.ALERT_RED
		cap_row.add_child(pip)
	body.add_child(cap_row)
	if rig.get_overcapacity() > 0:
		var strain := Label.new()
		strain.text = "Over capacity: Rig Strain is blocking part of your stamina."
		strain.add_theme_color_override("font_color", UiStyleRef.ALERT_RED)
		strain.add_theme_font_size_override("font_size", 11)
		body.add_child(strain)
	# slots
	var slots_label := Label.new()
	slots_label.text = "Gear slots"
	UiStyleRef.apply_label(slots_label, &"accent")
	body.add_child(slots_label)
	var eq: Array = rig.get_equipped()
	for i in range(rig.get_slot_count()):
		var gear: StringName = eq[i] if i < eq.size() else &""
		var line := HBoxContainer.new()
		line.add_theme_constant_override("separation", 8)
		var num := Label.new()
		num.text = "%d" % (i + 1)
		UiStyleRef.apply_label(num, &"muted")
		num.custom_minimum_size = Vector2(14.0, 0.0)
		line.add_child(num)
		var name_l := Label.new()
		name_l.text = str(rig.get_gear_display_name(gear)) if gear != &"" else "empty"
		UiStyleRef.apply_label(name_l, &"body" if gear != &"" else &"muted")
		name_l.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		line.add_child(name_l)
		if gear != &"":
			var btn := Button.new()
			btn.text = "Unmount"
			btn.focus_mode = Control.FOCUS_NONE
			UiStyleRef.apply_button(btn, true)
			btn.pressed.connect(_unmount.bind(i))
			line.add_child(btn)
		body.add_child(line)
	# owned gear not mounted
	var owned: Array = rig.get_owned_gear()
	var spare: Array = []
	for g in owned:
		if not rig.is_equipped(g):
			spare.append(g)
	var owned_label := Label.new()
	owned_label.text = "Owned Gear"
	UiStyleRef.apply_label(owned_label, &"accent")
	body.add_child(owned_label)
	if spare.is_empty():
		var none2 := Label.new()
		none2.text = "Nothing waiting. Order Approved Gear with [Q]."
		UiStyleRef.apply_label(none2, &"muted")
		body.add_child(none2)
	for g in spare:
		var info: Dictionary = rig.get_gear_info(g)
		var line2 := HBoxContainer.new()
		line2.add_theme_constant_override("separation", 8)
		var n2 := Label.new()
		n2.text = "%s   (draws %d)" % [str(info.get("display_name", g)), int(info.get("capacity_cost", 0))]
		UiStyleRef.apply_label(n2, &"body")
		n2.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		n2.tooltip_text = str(info.get("description", ""))
		line2.add_child(n2)
		var mount := Button.new()
		mount.text = "Mount"
		mount.focus_mode = Control.FOCUS_NONE
		UiStyleRef.apply_button(mount, true)
		mount.pressed.connect(_mount.bind(g))
		line2.add_child(mount)
		body.add_child(line2)
	if _message != "" and _message_ttl > 0.0:
		var msg := Label.new()
		msg.text = _message
		msg.add_theme_color_override("font_color", UiStyleRef.TEXT_AMBER)
		msg.add_theme_font_size_override("font_size", 11)
		body.add_child(msg)


func _mount(gear_id: StringName) -> void:
	var rig := get_node_or_null("/root/Rig")
	if rig == null:
		return
	var eq: Array = rig.get_equipped()
	var slot := -1
	for i in range(eq.size()):
		if eq[i] == &"":
			slot = i
			break
	if slot == -1:
		_say("Every slot is taken. Unmount something first.")
		return
	var r: Dictionary = rig.equip(gear_id, slot)
	_say("" if bool(r["success"]) else _reason_text(str(r["reason"])))


func _unmount(slot: int) -> void:
	var rig := get_node_or_null("/root/Rig")
	if rig == null:
		return
	var r: Dictionary = rig.unequip(slot)
	_say("" if bool(r["success"]) else _reason_text(str(r["reason"])))


func _say(text: String) -> void:
	_message = text
	_message_ttl = 4.0
	_refresh()


func _reason_text(reason: String) -> String:
	match reason:
		"not_at_station":
			return "Refits are done at a station: home, a workbench or Wickwork."
		"not_owned":
			return "You do not own that Gear."
		"already_equipped":
			return "That Gear is already mounted."
		"slot_occupied":
			return "That slot is taken."
		_:
			return "That cannot be refitted."
