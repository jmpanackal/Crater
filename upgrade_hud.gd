extends PanelContainer
## Slim Hollow chip (Shortage Risk + shop affordances). Upgrades live in two
## bottom-sheet modals: Requisition (public, Tallies) and Steal (forbidden,
## diverts District production). Primary Materials / Harvest / Trust live as
## separate always-visible rows above.

signal lie_choice(lied: bool)

const UiStyleRef := preload("res://ui_style.gd")

@onready var _content: VBoxContainer = $Margin/Content
@onready var _risk_label: Label = $Margin/Content/ShortageRiskLabel

var _harvest_label: Label
var _trust_label: Label
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

## Shop modals start closed — never dump upgrade rows over Devil's Mouth.
var _theft_buttons: Dictionary = {}
var _theft_expanded := false
var _theft_dimmer: ColorRect
var _theft_panel: PanelContainer
var _theft_title: Label
var _shop_risk: Label
var _theft_list: VBoxContainer
var _theft_close: Button
var _theft_open_btn: Button

var _req_buttons: Dictionary = {}
var _req_expanded := false
var _req_dimmer: ColorRect
var _req_panel: PanelContainer
var _tallies_label: Label
var _req_list: VBoxContainer
var _req_close: Button
var _req_open_btn: Button

## District production browsing lives on the Requisition panel only — it's
## public info and doesn't fit the Steal panel's secretive framing.
var _district_expanded := false
var _district_toggle: Button
var _district_label: Label

var _notice_ttl := 0.0
var _pulse_t := 0.0
var _status_dirty := true ## starts true so _process() paints the initial labels
var _last_trust := -1
var _trust_flash_ttl := 0.0
var _trust_delta := 0
var _last_notice_tone: StringName = &"neutral"


func _ready() -> void:
	var ui := get_parent()
	if ui:
		_harvest_label = ui.get_node_or_null("HarvestLabel") as Label
		_trust_label = ui.get_node_or_null("TrustLabel") as Label
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

	_ensure_theft_modal()
	_ensure_requisition_modal()
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
		_districts.shortage_risk_changed.connect(_on_shortage_risk_changed)

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

	_ensure_theft_open_btn()
	_ensure_requisition_open_btn()
	_build_theft_buttons()
	_build_requisition_buttons()
	if _community:
		_last_trust = _community.get_trust()
	_refresh_status()
	_refresh()


func _ensure_theft_modal() -> void:
	var ui := get_parent()
	if ui == null:
		return

	_theft_dimmer = ui.get_node_or_null("TheftShopDimmer") as ColorRect
	_theft_panel = ui.get_node_or_null("TheftShopPanel") as PanelContainer
	if _theft_panel == null:
		push_error("UpgradeHud: TheftShopPanel missing from UI")
		return

	_theft_title = _theft_panel.get_node_or_null("Margin/VBox/Title") as Label
	_shop_risk = _theft_panel.get_node_or_null("Margin/VBox/ShopShortageRisk") as Label
	_theft_list = _theft_panel.get_node_or_null("Margin/VBox/TheftList") as VBoxContainer
	_theft_close = _theft_panel.get_node_or_null("Margin/VBox/CloseButton") as Button

	if _theft_dimmer and not _theft_dimmer.gui_input.is_connected(_on_theft_dimmer_input):
		_theft_dimmer.gui_input.connect(_on_theft_dimmer_input)
	if _theft_close and not _theft_close.pressed.is_connected(close_theft_shop):
		_theft_close.focus_mode = Control.FOCUS_NONE
		_theft_close.pressed.connect(close_theft_shop)

	_set_theft_visible(false)


func _ensure_requisition_modal() -> void:
	var ui := get_parent()
	if ui == null:
		return

	_req_dimmer = ui.get_node_or_null("RequisitionDimmer") as ColorRect
	_req_panel = ui.get_node_or_null("RequisitionPanel") as PanelContainer
	if _req_panel == null:
		push_error("UpgradeHud: RequisitionPanel missing from UI")
		return

	_tallies_label = _req_panel.get_node_or_null("Margin/VBox/TalliesLabel") as Label
	_district_toggle = _req_panel.get_node_or_null("Margin/VBox/DistrictToggle") as Button
	_district_label = _req_panel.get_node_or_null("Margin/VBox/DistrictLabel") as Label
	_req_list = _req_panel.get_node_or_null("Margin/VBox/RequisitionList") as VBoxContainer
	_req_close = _req_panel.get_node_or_null("Margin/VBox/CloseButton") as Button

	if _req_dimmer and not _req_dimmer.gui_input.is_connected(_on_requisition_dimmer_input):
		_req_dimmer.gui_input.connect(_on_requisition_dimmer_input)
	if _district_toggle and not _district_toggle.pressed.is_connected(_toggle_districts):
		_district_toggle.focus_mode = Control.FOCUS_NONE
		_district_toggle.pressed.connect(_toggle_districts)
	if _req_close and not _req_close.pressed.is_connected(close_requisition):
		_req_close.focus_mode = Control.FOCUS_NONE
		_req_close.pressed.connect(close_requisition)

	_set_requisition_visible(false)


func _apply_chrome() -> void:
	# Slim Hollow chip — quieter than either shop modal, secondary to the cavern.
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
	UiStyleRef.apply_label(_risk_label, &"teal")
	if _risk_label:
		_risk_label.modulate.a = 0.9
	UiStyleRef.tip(
		_risk_label,
		"When the districts thrive, missing materials are harder to notice. Lower Shortage Risk = safer."
	)
	if _harvest_label:
		UiStyleRef.apply_label(_harvest_label, &"stat")
		UiStyleRef.tip(
			_harvest_label,
			"Return for the communal gathering before the clock runs out."
		)
	if _trust_label:
		UiStyleRef.apply_label(_trust_label, &"stat")
		UiStyleRef.tip(_trust_label, "How trusted you are in the Hollow.")
	if _notice_label:
		UiStyleRef.apply_label(_notice_label, &"body")
	if _lie_label:
		UiStyleRef.apply_label(_lie_label, &"body")
	UiStyleRef.apply_button(_lie_yes)
	UiStyleRef.apply_button(_lie_no)

	if _theft_panel:
		UiStyleRef.apply_panel(_theft_panel, &"copper", true)
	if _theft_title:
		UiStyleRef.apply_label(_theft_title, &"accent")
		_theft_title.text = "Steal from production"
	if _shop_risk:
		UiStyleRef.apply_label(_shop_risk, &"teal")
		UiStyleRef.tip(
			_shop_risk,
			"When the districts thrive, missing materials are harder to notice. Lower Shortage Risk = safer."
		)
	if _theft_close:
		UiStyleRef.apply_button(_theft_close, true)

	if _req_panel:
		UiStyleRef.apply_panel(_req_panel, &"teal", true)
	if _tallies_label:
		UiStyleRef.apply_label(_tallies_label, &"teal")
		UiStyleRef.tip(_tallies_label, "Personal work pay from public Material turn-ins.")
	if _district_label:
		UiStyleRef.apply_label(_district_label, &"muted")
		UiStyleRef.tip(
			_district_label,
			"District production by named good. Materials queue output for the next Harvest."
		)
	if _district_toggle:
		UiStyleRef.apply_button(_district_toggle, true)
		UiStyleRef.tip(_district_toggle, "District production — amount, reserve, capacity, Next Harvest.")
	if _req_close:
		UiStyleRef.apply_button(_req_close, true)


func _ensure_theft_open_btn() -> void:
	if _content == null:
		return
	_theft_open_btn = _content.get_node_or_null("TheftExpandHint") as Button
	if _theft_open_btn == null:
		_theft_open_btn = Button.new()
		_theft_open_btn.name = "TheftExpandHint"
		_content.add_child(_theft_open_btn)
	_theft_open_btn.focus_mode = Control.FOCUS_NONE
	_theft_open_btn.text = "Steal  [U]"
	_theft_open_btn.custom_minimum_size = Vector2(0, 22)
	UiStyleRef.apply_button(_theft_open_btn, true)
	UiStyleRef.tip(
		_theft_open_btn,
		"Forbidden upgrades — divert District production. Risks Trust if Shortage Risk is high."
	)
	if not _theft_open_btn.pressed.is_connected(open_theft_shop):
		_theft_open_btn.pressed.connect(open_theft_shop)


func _ensure_requisition_open_btn() -> void:
	if _content == null:
		return
	_req_open_btn = _content.get_node_or_null("RequisitionExpandHint") as Button
	if _req_open_btn == null:
		_req_open_btn = Button.new()
		_req_open_btn.name = "RequisitionExpandHint"
		_content.add_child(_req_open_btn)
	_req_open_btn.focus_mode = Control.FOCUS_NONE
	_req_open_btn.text = "Requisition  [Q]"
	_req_open_btn.custom_minimum_size = Vector2(0, 22)
	UiStyleRef.apply_button(_req_open_btn, true)
	UiStyleRef.tip(
		_req_open_btn,
		"Open, sanctioned upgrades — spend Tallies to help the districts."
	)
	if not _req_open_btn.pressed.is_connected(open_requisition):
		_req_open_btn.pressed.connect(open_requisition)


func is_theft_shop_open() -> bool:
	return _theft_expanded and _theft_panel != null and _theft_panel.visible


func is_requisition_open() -> bool:
	return _req_expanded and _req_panel != null and _req_panel.visible


func open_theft_shop() -> void:
	if _upgrades == null or not _upgrades.is_theft_station_open():
		return
	_req_expanded = false
	_theft_expanded = true
	_refresh()


func close_theft_shop() -> void:
	_theft_expanded = false
	_refresh()


func open_requisition() -> void:
	if _upgrades == null or not _upgrades.is_theft_station_open():
		return
	_theft_expanded = false
	_req_expanded = true
	_refresh()


func close_requisition() -> void:
	_req_expanded = false
	_district_expanded = false
	_refresh()


func _toggle_districts() -> void:
	_district_expanded = not _district_expanded
	_refresh_requisition_status()


func _on_theft_dimmer_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		close_theft_shop()


func _on_requisition_dimmer_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		close_requisition()


func _process(delta: float) -> void:
	_pulse_t += delta
	if _trust_flash_ttl > 0.0:
		_trust_flash_ttl = maxf(0.0, _trust_flash_ttl - delta)
		_status_dirty = true # flash color fades every frame while active
	if _notice_ttl > 0.0:
		_notice_ttl -= delta
		if _notice_ttl <= 0.0 and _notice_label:
			_notice_label.visible = false
	# _on_harvest_timer_changed/_on_trust_changed already mark this dirty
	# whenever Community actually has something new to show — this avoids
	# rebuilding the Harvest/Trust strings and re-deriving Color objects on
	# frames where nothing changed (e.g. while Community is paused, as tests
	# do via set_paused(true)).
	if _status_dirty:
		_status_dirty = false
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

	if event.is_action_pressed("ui_cancel") and (is_theft_shop_open() or is_requisition_open()):
		close_theft_shop()
		close_requisition()
		get_viewport().set_input_as_handled()
		return

	if event.is_action_pressed("steal_upgrade"):
		if _upgrades == null or not _upgrades.is_theft_station_open():
			return
		if is_theft_shop_open():
			close_theft_shop()
		else:
			open_theft_shop()
		get_viewport().set_input_as_handled()
		return

	if event.is_action_pressed("requisition_upgrade"):
		if _upgrades == null or not _upgrades.is_theft_station_open():
			return
		if is_requisition_open():
			close_requisition()
		else:
			open_requisition()
		get_viewport().set_input_as_handled()
		return

	if event.is_action_pressed("interact"):
		if _upgrades == null or not _upgrades.is_theft_station_open():
			return
		var prefer_tallies := Input.is_key_pressed(KEY_SHIFT)
		_try_turn_in_materials(prefer_tallies)
		get_viewport().set_input_as_handled()


func _build_theft_buttons() -> void:
	if _theft_list == null or _upgrades == null:
		return
	for child in _theft_list.get_children():
		child.queue_free()
	_theft_buttons.clear()

	for id in _upgrades.get_upgrade_ids():
		var upgrade_id: StringName = id
		if not _upgrades.is_forbidden(upgrade_id):
			continue
		var btn := Button.new()
		btn.focus_mode = Control.FOCUS_NONE
		btn.name = String(upgrade_id)
		btn.custom_minimum_size = Vector2(0, 24)
		btn.alignment = HORIZONTAL_ALIGNMENT_LEFT
		UiStyleRef.apply_button(btn, true)
		btn.pressed.connect(_try_steal.bind(upgrade_id))
		_theft_list.add_child(btn)
		_theft_buttons[upgrade_id] = btn


func _build_requisition_buttons() -> void:
	if _req_list == null or _upgrades == null:
		return
	for child in _req_list.get_children():
		child.queue_free()
	_req_buttons.clear()

	for id in _upgrades.get_upgrade_ids():
		var upgrade_id: StringName = id
		if not _upgrades.is_efficiency(upgrade_id):
			continue
		var btn := Button.new()
		btn.focus_mode = Control.FOCUS_NONE
		btn.name = String(upgrade_id)
		btn.custom_minimum_size = Vector2(0, 24)
		btn.alignment = HORIZONTAL_ALIGNMENT_LEFT
		UiStyleRef.apply_button(btn, true)
		btn.pressed.connect(_try_requisition.bind(upgrade_id))
		_req_list.add_child(btn)
		_req_buttons[upgrade_id] = btn


func _try_steal(upgrade_id: StringName) -> void:
	if _upgrades == null:
		return
	if not _theft_expanded:
		open_theft_shop()
	_upgrades.acquire_upgrade(upgrade_id)
	_refresh()


func _try_requisition(upgrade_id: StringName) -> void:
	if _upgrades == null:
		return
	if not _req_expanded:
		open_requisition()
	# acquire_upgrade() no longer emits theft_result for efficiency ids (see
	# upgrades.gd) — an efficiency purchase isn't a theft, so its success
	# notice is shown directly here instead of via that signal.
	if _upgrades.acquire_upgrade(upgrade_id):
		_show_notice("Requisition complete.")
	_refresh()


func _on_upgrade_changed(_upgrade_id: StringName, _new_level: int) -> void:
	_refresh()


func _on_resource_changed(_resource_id: StringName, _new_amount: int) -> void:
	_refresh()


func _on_theft_station_changed(_is_open: bool) -> void:
	if _upgrades and not _upgrades.is_theft_station_open():
		_theft_expanded = false
		_req_expanded = false
		_district_expanded = false
	_refresh()


func _on_harvest_timer_changed(_seconds: float) -> void:
	_status_dirty = true


func _on_trust_changed(value: int) -> void:
	if _last_trust >= 0 and value != _last_trust:
		_trust_delta = value - _last_trust
		_trust_flash_ttl = 0.95
	_last_trust = value
	_status_dirty = true


func _on_harvest_completed(_missed: bool) -> void:
	_refresh_status()
	_refresh()


func _on_district_changed(_id: StringName) -> void:
	_refresh_requisition_status()


func _on_shortage_risk_changed(_risk: float) -> void:
	_refresh_risk()


func _on_theft_result(_id: StringName, noticed: bool) -> void:
	if noticed:
		return
	_show_notice("Theft complete. Shortage Risk held.")


func _on_records_changed() -> void:
	_refresh()


func _on_harvest_miss_prompt() -> void:
	close_theft_shop()
	close_requisition()
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
		_set_theft_visible(false)
		_set_requisition_visible(false)
		return

	var in_hollow: bool = _upgrades.is_theft_station_open()
	visible = in_hollow
	if not in_hollow:
		_theft_expanded = false
		_req_expanded = false
		_district_expanded = false
		_set_theft_visible(false)
		_set_requisition_visible(false)
		return

	_refresh_risk()
	_refresh_requisition_status()
	_refresh_theft_buttons()
	_refresh_requisition_buttons()
	_set_theft_visible(_theft_expanded)
	_set_requisition_visible(_req_expanded)
	if _theft_open_btn:
		_theft_open_btn.visible = true
		_theft_open_btn.text = "Close steal  [U]" if _theft_expanded else "Steal  [U]"
	if _req_open_btn:
		_req_open_btn.visible = true
		_req_open_btn.text = "Close requisition  [Q]" if _req_expanded else "Requisition  [Q]"
	call_deferred("_fit_to_content")


func _set_theft_visible(open_: bool) -> void:
	if _theft_dimmer:
		_theft_dimmer.visible = open_
	if _theft_panel:
		_theft_panel.visible = open_


func _set_requisition_visible(open_: bool) -> void:
	if _req_dimmer:
		_req_dimmer.visible = open_
	if _req_panel:
		_req_panel.visible = open_


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
	if _harvest_label == null and _trust_label == null:
		return
	if _community == null:
		if _harvest_label:
			_harvest_label.text = "Harvest ?"
			_harvest_label.modulate = UiStyleRef.TEXT_MUTED
		if _trust_label:
			_trust_label.text = "Trust ?"
			_trust_label.modulate = UiStyleRef.TEXT_MUTED
		return

	var remaining: float = _community.get_harvest_seconds_remaining()
	var lie_tag := ""
	if _community.has_pending_lie():
		lie_tag = "  · lie pending"
	var trust_tag := ""
	if _trust_flash_ttl > 0.0 and _trust_delta != 0:
		trust_tag = " (%+d)" % _trust_delta

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

	if _trust_label:
		_trust_label.text = "Trust %d/%d%s" % [
			_community.get_trust(),
			_community.TRUST_MAX,
			trust_tag,
		]
		if _trust_flash_ttl > 0.0 and _trust_delta < 0:
			_trust_label.modulate = Color(1.0, 0.78, 0.62, 1.0)
		elif _trust_flash_ttl > 0.0 and _trust_delta > 0:
			_trust_label.modulate = Color(0.78, 0.92, 0.8, 1.0)
		else:
			_trust_label.modulate = UiStyleRef.TEXT_PRIMARY


## Test helper — true when harvest urgency pulse band is active.
func is_harvest_urgent() -> bool:
	if _community == null:
		return false
	return _community.get_harvest_seconds_remaining() <= 10.0


func debug_notice_tone() -> StringName:
	return _last_notice_tone


## Shortage Risk chip (always visible) + the Steal panel's own risk label.
func _refresh_risk() -> void:
	var risk_text := "Shortage Risk ?"
	if _districts != null:
		var risk: float = _districts.get_shortage_risk()
		var notice: float = _districts.get_theft_notice_chance()
		risk_text = "Shortage Risk %d%%  ·  notice ~%d%%" % [
			int(round(risk * 100.0)),
			int(round(notice * 100.0)),
		]

	if _risk_label:
		_risk_label.text = risk_text
	if _shop_risk:
		_shop_risk.text = risk_text


## Requisition panel: Tallies balance + the district production breakdown.
func _refresh_requisition_status() -> void:
	if _tallies_label:
		var tallies := 0
		if _wallet != null:
			tallies = _wallet.get_amount(_wallet.TALLIES)
		_tallies_label.text = "Tallies %d" % tallies

	if _district_toggle:
		_district_toggle.text = "District production ▾" if _district_expanded else "District production ▸"
		_district_toggle.visible = _req_expanded

	if _district_label:
		_district_label.visible = _req_expanded and _district_expanded
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


func _refresh_theft_buttons() -> void:
	if _upgrades == null:
		return
	for id in _theft_buttons.keys():
		var btn: Button = _theft_buttons[id]
		var def: Dictionary = _upgrades.get_def(id) if _upgrades.has_method("get_def") else {}
		var blurb := str(def.get("blurb", ""))
		if blurb != "":
			btn.tooltip_text = blurb
		if _upgrades.has_method("is_unlocked") and not _upgrades.is_unlocked(id):
			btn.text = "%s — locked" % _upgrades.get_display_name(id)
			btn.disabled = true
			continue
		var level: int = _upgrades.get_level(id)
		var cost: int = _upgrades.get_next_cost(id)
		var cost_label := "%d" % cost
		if _districts != null:
			var good_id: StringName = _upgrades.get_divert_good(id)
			cost_label = "%d %s" % [cost, _districts.get_good_display_name(good_id)]
			if _districts.is_production_thin(good_id):
				btn.tooltip_text = (
					"%s\nProduction is thin — diversion will be noticed." % blurb
				)
		var suffix := ""
		if id == _upgrades.DIG_YIELD:
			suffix = "  ·  %d/dig" % _upgrades.get_dig_salvage_yield()
		btn.text = "%s  Lv%d — %s%s" % [
			_upgrades.get_display_name(id),
			level,
			cost_label,
			suffix,
		]
		btn.disabled = not _upgrades.can_acquire(id)


func _refresh_requisition_buttons() -> void:
	if _upgrades == null:
		return
	for id in _req_buttons.keys():
		var btn: Button = _req_buttons[id]
		var def: Dictionary = _upgrades.get_def(id) if _upgrades.has_method("get_def") else {}
		var blurb := str(def.get("blurb", ""))
		if blurb != "":
			btn.tooltip_text = blurb
		if _upgrades.has_method("is_unlocked") and not _upgrades.is_unlocked(id):
			btn.text = "%s — locked" % _upgrades.get_display_name(id)
			btn.disabled = true
			continue
		var level: int = _upgrades.get_level(id)
		var cost: int = _upgrades.get_next_cost(id)
		var cost_label := "%d Tallies" % cost
		btn.text = "%s  Lv%d — %s" % [
			_upgrades.get_display_name(id),
			level,
			cost_label,
		]
		btn.disabled = not _upgrades.can_acquire(id)
