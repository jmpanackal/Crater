extends PanelContainer
## Slim Hollow chip (Cover + shop affordance). Theft upgrades live in a bottom-sheet modal.
## Primary Materials / Harvest / Trust live as separate always-visible rows above.

signal lie_choice(lied: bool)

const UiStyleRef := preload("res://ui_style.gd")

@onready var _content: VBoxContainer = $Margin/Content
@onready var _cover_label: Label = $Margin/Content/CoverLabel

var _harvest_label: Label
var _standing_label: Label
var _notice_label: Label
var _lie_box: VBoxContainer
var _lie_panel: PanelContainer
var _lie_dimmer: ColorRect
var _lie_yes: Button
var _lie_no: Button
var _lie_label: Label

var _upgrades: Node
var _wallet: Node
var _community: Node
var _districts: Node
var _siphon_buttons: Dictionary = {}
var _notice_ttl := 0.0
## Shop modal starts closed — never dump upgrade rows over the pit.
var _siphon_expanded := false
var _district_expanded := false
var _shop_open_btn: Button
var _district_toggle: Button
var _shop_dimmer: ColorRect
var _shop_panel: PanelContainer
var _shop_title: Label
var _shop_cover: Label
var _district_label: Label
var _siphon_list: VBoxContainer
var _shop_close: Button
var _pulse_t := 0.0
var _last_standing := -1
var _standing_flash_ttl := 0.0
var _standing_delta := 0
var _last_notice_tone: StringName = &"neutral"


func _ready() -> void:
	var ui := get_parent()
	if ui:
		_harvest_label = ui.get_node_or_null("HarvestLabel") as Label
		_standing_label = ui.get_node_or_null("StandingLabel") as Label
		_notice_label = ui.get_node_or_null("NoticeLabel") as Label
		_lie_box = ui.get_node_or_null("LiePrompt") as VBoxContainer
		_lie_panel = ui.get_node_or_null("LiePromptPanel") as PanelContainer
		_lie_dimmer = ui.get_node_or_null("LieDimmer") as ColorRect
		if _lie_box:
			_lie_yes = _lie_box.get_node_or_null("YesButton") as Button
			_lie_no = _lie_box.get_node_or_null("NoButton") as Button
			_lie_label = _lie_box.get_node_or_null("LieLabel") as Label

	_upgrades = get_tree().root.get_node_or_null("Upgrades")
	_wallet = get_tree().root.get_node_or_null("Resources")
	_community = get_tree().root.get_node_or_null("Community")
	_districts = get_tree().root.get_node_or_null("Districts")

	_ensure_shop_modal()
	_apply_chrome()

	if _community:
		_community.skip_lie_prompt = false
		_community.harvest_timer_changed.connect(_on_harvest_timer_changed)
		_community.trust_changed.connect(_on_trust_changed)
		_community.harvest_completed.connect(_on_harvest_completed)
		_community.harvest_miss_prompt.connect(_on_harvest_miss_prompt)
		_community.notice_message.connect(_show_notice)

	if _upgrades:
		_upgrades.upgrade_changed.connect(_on_upgrade_changed)
		_upgrades.theft_station_changed.connect(_on_theft_station_changed)
		_upgrades.theft_result.connect(_on_theft_result)
	var journal := get_tree().root.get_node_or_null("Journal")
	if journal and journal.has_signal("records_changed"):
		journal.records_changed.connect(_on_records_changed)

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
	if _lie_panel:
		_lie_panel.visible = false
		UiStyleRef.apply_panel(_lie_panel, &"copper", true)
	if _lie_dimmer:
		_lie_dimmer.visible = false

	_ensure_shop_open_btn()
	_build_siphon_buttons()
	if _community:
		_last_standing = _community.get_trust()
	_refresh_status()
	_refresh()


func _ensure_shop_modal() -> void:
	var ui := get_parent()
	if ui == null:
		return

	_shop_dimmer = ui.get_node_or_null("SiphonShopDimmer") as ColorRect
	_shop_panel = ui.get_node_or_null("SiphonShopPanel") as PanelContainer
	if _shop_panel == null:
		push_error("UpgradeHud: SiphonShopPanel missing from UI")
		return

	_shop_title = _shop_panel.get_node_or_null("Margin/VBox/Title") as Label
	_shop_cover = _shop_panel.get_node_or_null("Margin/VBox/ShopCover") as Label
	_district_toggle = _shop_panel.get_node_or_null("Margin/VBox/DistrictToggle") as Button
	_district_label = _shop_panel.get_node_or_null("Margin/VBox/DistrictLabel") as Label
	_siphon_list = _shop_panel.get_node_or_null("Margin/VBox/SiphonList") as VBoxContainer
	_shop_close = _shop_panel.get_node_or_null("Margin/VBox/CloseButton") as Button

	if _shop_dimmer and not _shop_dimmer.gui_input.is_connected(_on_shop_dimmer_input):
		_shop_dimmer.gui_input.connect(_on_shop_dimmer_input)
	if _district_toggle and not _district_toggle.pressed.is_connected(_toggle_districts):
		_district_toggle.focus_mode = Control.FOCUS_NONE
		_district_toggle.pressed.connect(_toggle_districts)
	if _shop_close and not _shop_close.pressed.is_connected(close_shop):
		_shop_close.focus_mode = Control.FOCUS_NONE
		_shop_close.pressed.connect(close_shop)

	_set_shop_visible(false)


func _apply_chrome() -> void:
	# Slim Hollow chip — quieter than shop modal, secondary to the cavern.
	UiStyleRef.apply_panel(self, &"teal", false, true)
	custom_minimum_size = Vector2(UiStyleRef.HUD_CHIP_WIDTH, 0)
	modulate = Color(1.0, 1.0, 1.0, 0.7)
	if _content:
		_content.add_theme_constant_override("separation", 2)
	var margin := get_node_or_null("Margin") as MarginContainer
	if margin:
		margin.add_theme_constant_override("margin_left", 6)
		margin.add_theme_constant_override("margin_top", 4)
		margin.add_theme_constant_override("margin_right", 6)
		margin.add_theme_constant_override("margin_bottom", 4)
	UiStyleRef.apply_label(_cover_label, &"teal")
	if _cover_label:
		_cover_label.modulate.a = 0.9
	UiStyleRef.tip(
		_cover_label,
		"How hidden your theft is. Higher Cover = safer diversion of District production."
	)
	if _harvest_label:
		UiStyleRef.apply_label(_harvest_label, &"stat")
		UiStyleRef.tip(
			_harvest_label,
			"Return for the communal gathering before the clock runs out."
		)
	if _standing_label:
		UiStyleRef.apply_label(_standing_label, &"stat")
		UiStyleRef.tip(_standing_label, "How trusted you are in the Hollow.")
	if _notice_label:
		UiStyleRef.apply_label(_notice_label, &"body")
	if _lie_label:
		UiStyleRef.apply_label(_lie_label, &"body")
	UiStyleRef.apply_button(_lie_yes)
	UiStyleRef.apply_button(_lie_no)
	if _shop_panel:
		UiStyleRef.apply_panel(_shop_panel, &"copper", true)
	if _shop_title:
		UiStyleRef.apply_label(_shop_title, &"accent")
		_shop_title.text = "Steal from production"
	if _shop_cover:
		UiStyleRef.apply_label(_shop_cover, &"teal")
		UiStyleRef.tip(
			_shop_cover,
			"How hidden your theft is. Higher Cover = safer diversion of District production."
		)
	if _district_label:
		UiStyleRef.apply_label(_district_label, &"muted")
		UiStyleRef.tip(
			_district_label,
			"District production by named good. Materials queue output for the next Harvest."
		)
	if _district_toggle:
		UiStyleRef.apply_button(_district_toggle, true)
		UiStyleRef.tip(_district_toggle, "District production — amount, reserve, capacity, Next Harvest.")
	if _shop_close:
		UiStyleRef.apply_button(_shop_close, true)


func _ensure_shop_open_btn() -> void:
	if _content == null:
		return
	_shop_open_btn = _content.get_node_or_null("SiphonExpandHint") as Button
	if _shop_open_btn == null:
		_shop_open_btn = Button.new()
		_shop_open_btn.name = "SiphonExpandHint"
		_content.add_child(_shop_open_btn)
	_shop_open_btn.focus_mode = Control.FOCUS_NONE
	_shop_open_btn.text = "Shop  [U]"
	_shop_open_btn.custom_minimum_size = Vector2(0, 22)
	UiStyleRef.apply_button(_shop_open_btn, true)
	UiStyleRef.tip(
		_shop_open_btn,
		"Turn in Materials and steal District production. Forbidden options risk Trust if Cover is thin."
	)
	if not _shop_open_btn.pressed.is_connected(open_shop):
		_shop_open_btn.pressed.connect(open_shop)


func is_shop_open() -> bool:
	return _siphon_expanded and _shop_panel != null and _shop_panel.visible


func open_shop() -> void:
	if _upgrades == null or not _upgrades.is_theft_station_open():
		return
	_siphon_expanded = true
	_refresh()


func close_shop() -> void:
	_siphon_expanded = false
	_district_expanded = false
	_refresh()


func _toggle_districts() -> void:
	_district_expanded = not _district_expanded
	_refresh_districts()


func _on_shop_dimmer_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		close_shop()


func _process(delta: float) -> void:
	_pulse_t += delta
	if _standing_flash_ttl > 0.0:
		_standing_flash_ttl = maxf(0.0, _standing_flash_ttl - delta)
	if _notice_ttl > 0.0:
		_notice_ttl -= delta
		if _notice_ttl <= 0.0 and _notice_label:
			_notice_label.visible = false
	_refresh_status()


func _unhandled_input(event: InputEvent) -> void:
	if _lie_box != null and _lie_box.visible and event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_Y:
			_resolve_lie(true)
			get_viewport().set_input_as_handled()
			return
		if event.keycode == KEY_N:
			_resolve_lie(false)
			get_viewport().set_input_as_handled()
			return

	if is_shop_open() and event.is_action_pressed("ui_cancel"):
		close_shop()
		get_viewport().set_input_as_handled()
		return

	if event.is_action_pressed("steal_upgrade"):
		if _upgrades == null or not _upgrades.is_theft_station_open():
			return
		if is_shop_open():
			close_shop()
		else:
			open_shop()
		get_viewport().set_input_as_handled()
		return

	if event.is_action_pressed("interact"):
		if _upgrades == null or not _upgrades.is_theft_station_open():
			return
		var prefer_tallies := Input.is_key_pressed(KEY_SHIFT)
		_try_turn_in_materials(prefer_tallies)
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
		btn.custom_minimum_size = Vector2(0, 24)
		btn.alignment = HORIZONTAL_ALIGNMENT_LEFT
		UiStyleRef.apply_button(btn, true)
		btn.pressed.connect(_try_siphon.bind(upgrade_id))
		_siphon_list.add_child(btn)
		_siphon_buttons[upgrade_id] = btn


func _try_siphon(upgrade_id: StringName) -> void:
	if _upgrades == null:
		return
	if not _siphon_expanded:
		open_shop()
	_upgrades.steal_for_upgrade(upgrade_id)
	_refresh()


func _on_upgrade_changed(_upgrade_id: StringName, _new_level: int) -> void:
	_refresh()


func _on_resource_changed(_resource_id: StringName, _new_amount: int) -> void:
	_refresh()


func _on_theft_station_changed(_is_open: bool) -> void:
	if _upgrades and not _upgrades.is_theft_station_open():
		_siphon_expanded = false
		_district_expanded = false
	_refresh()


func _on_harvest_timer_changed(_seconds: float) -> void:
	_refresh_status()


func _on_trust_changed(value: int) -> void:
	if _last_standing >= 0 and value != _last_standing:
		_standing_delta = value - _last_standing
		_standing_flash_ttl = 0.95
	_last_standing = value
	_refresh_status()


func _on_harvest_completed(_missed: bool) -> void:
	_refresh_status()
	_refresh()


func _on_district_changed(_id: StringName) -> void:
	_refresh_districts()


func _on_cover_changed(_cover: float) -> void:
	_refresh_districts()


func _on_theft_result(_id: StringName, noticed: bool) -> void:
	if noticed:
		return
	_show_notice("Theft complete. Cover held.")


func _on_records_changed() -> void:
	_refresh()


func _on_harvest_miss_prompt() -> void:
	close_shop()
	if _lie_dimmer:
		_lie_dimmer.visible = true
	if _lie_panel:
		_lie_panel.visible = true
	if _lie_box:
		_lie_box.visible = true
	_show_notice("Harvest missed — choose carefully.")


func _resolve_lie(lied: bool) -> void:
	if _lie_box:
		_lie_box.visible = false
	if _lie_panel:
		_lie_panel.visible = false
	if _lie_dimmer:
		_lie_dimmer.visible = false
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
	_last_notice_tone = notice_tone_for(text)
	_notice_label.modulate = notice_color_for(_last_notice_tone)


## Classifies social toast copy for restrained color (tests + HUD).
static func notice_tone_for(text: String) -> StringName:
	var lower := text.to_lower()
	# Gains first — "(+1 Trust)" must not match loss "trust)" heuristics.
	if "+1 trust" in lower or "help in the glowbeds" in lower:
		return &"gain"
	if "lied about" in lower or "choose carefully" in lower:
		return &"caution"
	if (
		"−" in text
		or "(-" in text
		or "missed harvest" in lower
		or "people noticed" in lower
		or "someone noticed" in lower
		or "caught digging" in lower
		or "lie cracked" in lower
		or "came apart" in lower
		or "materials going missing" in lower
	):
		return &"loss"
	return &"neutral"


static func notice_color_for(tone: StringName) -> Color:
	match tone:
		&"loss":
			return Color(1.0, 0.7, 0.55, 1.0)
		&"gain":
			return Color(0.72, 0.9, 0.78, 1.0)
		&"caution":
			return Color(0.95, 0.84, 0.62, 1.0)
		_:
			return Color(0.9, 0.88, 0.8, 1.0)


func _refresh() -> void:
	if _upgrades == null:
		visible = false
		_set_shop_visible(false)
		return

	var in_hollow: bool = _upgrades.is_theft_station_open()
	visible = in_hollow
	if not in_hollow:
		_siphon_expanded = false
		_district_expanded = false
		_set_shop_visible(false)
		return

	_refresh_districts()
	_refresh_siphon_buttons()
	_set_shop_visible(_siphon_expanded)
	if _shop_open_btn:
		_shop_open_btn.visible = true
		_shop_open_btn.text = "Close shop  [U]" if _siphon_expanded else "Shop  [U]"
	call_deferred("_fit_to_content")


func _set_shop_visible(open_: bool) -> void:
	if _shop_dimmer:
		_shop_dimmer.visible = open_
	if _shop_panel:
		_shop_panel.visible = open_


func _fit_to_content() -> void:
	if _content == null or not visible:
		return
	var width := UiStyleRef.HUD_CHIP_WIDTH
	var margins := 14.0
	var needed: float = _content.get_combined_minimum_size().y + margins
	size = Vector2(width, maxf(needed, 40.0))
	offset_right = offset_left + width
	offset_bottom = offset_top + size.y


func _refresh_status() -> void:
	if _harvest_label == null and _standing_label == null:
		return
	if _community == null:
		if _harvest_label:
			_harvest_label.text = "Harvest ?"
			_harvest_label.modulate = UiStyleRef.TEXT_MUTED
		if _standing_label:
			_standing_label.text = "Trust ?"
			_standing_label.modulate = UiStyleRef.TEXT_MUTED
		return

	var remaining: float = _community.get_harvest_seconds_remaining()
	var lie_tag := ""
	if _community.has_pending_lie():
		lie_tag = "  · lie pending"
	var standing_tag := ""
	if _standing_flash_ttl > 0.0 and _standing_delta != 0:
		standing_tag = " (%+d)" % _standing_delta

	if _harvest_label:
		_harvest_label.text = "Harvest %ds%s" % [int(ceil(remaining)), lie_tag]
		# Soft urgency — social clock pulse when low, not arcade alarm.
		if remaining <= 10.0:
			var pulse := 0.78 + 0.22 * (0.5 + 0.5 * sin(_pulse_t * 3.6))
			_harvest_label.modulate = Color(1.0, 0.72, 0.42, pulse)
		elif remaining <= 20.0:
			_harvest_label.modulate = Color(0.98, 0.9, 0.7, 0.95)
		elif lie_tag != "":
			_harvest_label.modulate = Color(0.95, 0.82, 0.7, 0.95)
		else:
			_harvest_label.modulate = UiStyleRef.TEXT_PRIMARY

	if _standing_label:
		_standing_label.text = "Trust %d/%d%s" % [
			_community.get_trust(),
			_community.TRUST_MAX,
			standing_tag,
		]
		if _standing_flash_ttl > 0.0 and _standing_delta < 0:
			_standing_label.modulate = Color(1.0, 0.78, 0.62, 1.0)
		elif _standing_flash_ttl > 0.0 and _standing_delta > 0:
			_standing_label.modulate = Color(0.78, 0.92, 0.8, 1.0)
		else:
			_standing_label.modulate = UiStyleRef.TEXT_PRIMARY


## Test helper — true when harvest urgency pulse band is active.
func is_harvest_urgent() -> bool:
	if _community == null:
		return false
	return _community.get_harvest_seconds_remaining() <= 10.0


func debug_notice_tone() -> StringName:
	return _last_notice_tone


func _refresh_districts() -> void:
	var cover_text := "Cover ?"
	if _districts != null:
		var cover: float = _districts.get_cover_health()
		var notice: float = _districts.get_theft_notice_chance()
		cover_text = "Cover %d%%  ·  notice ~%d%%" % [
			int(round(cover * 100.0)),
			int(round(notice * 100.0)),
		]

	if _cover_label:
		_cover_label.text = cover_text
	if _shop_cover:
		_shop_cover.text = cover_text

	if _district_toggle:
		_district_toggle.text = "District production ▾" if _district_expanded else "District production ▸"
		_district_toggle.visible = _siphon_expanded

	if _district_label:
		_district_label.visible = _siphon_expanded and _district_expanded
		if _district_expanded and _districts != null:
			var lines: PackedStringArray = PackedStringArray()
			for id in _districts.get_district_ids():
				lines.append(_districts.get_display_name(id))
				for good_id in _districts.get_goods_for_district(id):
					var amt: int = _districts.get_good_amount(good_id)
					var queued: int = _districts.get_queued(good_id)
					var forecast: int = _districts.get_next_harvest_forecast(good_id)
					var reserve: int = _districts.PROTECTED_RESERVE
					var capacity: int = _districts.CAPACITY
					var thin := "  · thin" if _districts.is_production_thin(good_id) else ""
					var queue_tag := ""
					if queued > 0:
						queue_tag = "  (+%d queued)" % queued
					lines.append(
						"  %s %d/%d (reserve %d) · Next Harvest %d%s%s"
						% [
							_districts.get_good_display_name(good_id),
							amt,
							capacity,
							reserve,
							forecast,
							queue_tag,
							thin,
						]
					)
			lines.append(_materials_turn_in_summary())
			_district_label.text = "\n".join(lines)


func _materials_turn_in_summary() -> String:
	if _wallet == null or _districts == null:
		return ""
	var parts: PackedStringArray = PackedStringArray()
	var mats: Array[StringName] = [
		_wallet.SPOREMEAL,
		_wallet.LAMPWICK,
		_wallet.BRINECRYSTAL,
		_wallet.VERDIGRIS,
	]
	for mat_id in mats:
		var n: int = _wallet.get_amount(mat_id)
		if n > 0:
			parts.append("%s×%d" % [_wallet.get_material_display_name(mat_id), n])
	var tallies: int = _wallet.get_amount(_wallet.TALLIES)
	var head := "Materials: none"
	if not parts.is_empty():
		head = "Materials: " + ", ".join(parts)
	return "%s  ·  Tallies %d\n[E] turn in / Verdigris: hold Shift+[E] for Mid Heart Tallies" % [
		head,
		tallies,
	]


func _short_district_name(id: StringName) -> String:
	match String(id):
		"farms":
			return "Glowbeds"
		"wickwork":
			return "Wick"
		"cistern":
			return "Cistern"
		_:
			return _districts.get_display_name(id) if _districts else String(id)


func _try_turn_in_materials(prefer_tallies: bool = false) -> void:
	if _districts == null or _wallet == null:
		return
	if prefer_tallies and _wallet.get_amount(_wallet.VERDIGRIS) > 0:
		if _districts.turn_in_verdigris_for_tallies():
			_show_notice("Turned in Verdigris at Mid Heart (+3 Tallies).")
			_refresh()
			return
	var order: Array[StringName] = [
		_wallet.SPOREMEAL,
		_wallet.LAMPWICK,
		_wallet.BRINECRYSTAL,
		_wallet.VERDIGRIS,
	]
	for mat_id in order:
		if _wallet.get_amount(mat_id) <= 0:
			continue
		if _districts.queue_material(mat_id):
			_show_notice(
				"Queued %s for next Harvest." % _wallet.get_material_display_name(mat_id)
			)
			_refresh()
			return
	_show_notice("No Materials to turn in.")


func _refresh_siphon_buttons() -> void:
	if _upgrades == null:
		return
	for id in _siphon_buttons.keys():
		var btn: Button = _siphon_buttons[id]
		var kind := "Safe" if _upgrades.is_efficiency(id) else "Secret"
		var def: Dictionary = _upgrades.get_def(id) if _upgrades.has_method("get_def") else {}
		var blurb := str(def.get("blurb", ""))
		if blurb != "":
			btn.tooltip_text = blurb
		if _upgrades.has_method("is_unlocked") and not _upgrades.is_unlocked(id):
			btn.text = "%s  %s — locked" % [kind, _upgrades.get_display_name(id)]
			btn.disabled = true
			continue
		var level: int = _upgrades.get_level(id)
		var cost: int = _upgrades.get_next_cost(id)
		var cost_label := "%d" % cost
		if _upgrades.is_forbidden(id) and _districts != null:
			var good_id: StringName = _upgrades.get_divert_good(id)
			cost_label = "%d %s" % [cost, _districts.get_good_display_name(good_id)]
			if _districts.is_production_thin(good_id):
				btn.tooltip_text = (
					"%s\nProduction is thin — diversion will be noticed." % blurb
				)
		elif _upgrades.is_efficiency(id):
			cost_label = "%d Salvage" % cost
		var suffix := ""
		if id == _upgrades.DIG_YIELD:
			suffix = "  ·  %d/dig" % _upgrades.get_dig_salvage_yield()
		btn.text = "%s  %s  Lv%d — %s%s" % [
			kind,
			_upgrades.get_display_name(id),
			level,
			cost_label,
			suffix,
		]
		btn.disabled = not _upgrades.can_steal(id)
