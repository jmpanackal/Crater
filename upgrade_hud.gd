extends PanelContainer
## Slim Hollow chip (District condition + Requisition). Requisition is the one
## remaining shop modal here — Approved Gear ordered with Tallies + authorized
## District Output (Orders, Build Bible Spec 23). Steal is NOT a menu:
## district_store.gd (Spec 26) is a physical hold-to-take world Interactable,
## same Interaction system as everything else — there is deliberately no
## Steal panel to rebuild here. Materials / civic-cycle phase / Trust live as
## separate always-visible rows above, refreshed by this script.
##
## Replaces the retired prototype wiring
## (docs/terminology-transition.md's migration backlog) with the real
## canon autoloads: Orders, Wallet, Trust, District, Storage, Clock.

const UiStyleRef := preload("res://ui_style.gd")

@onready var _content: VBoxContainer = $Margin/Content
@onready var _condition_label: Label = $Margin/Content/DistrictConditionLabel

var _cycle_label: Label
var _trust_label: Label
var _notice_label: Label

var _orders: Node
var _wallet: Node
var _trust: Node
var _district: Node
var _storage: Node
var _clock: Node
var _bus: Node

var _req_buttons: Dictionary = {}
var _req_expanded := false
var _req_dimmer: ColorRect
var _req_panel: PanelContainer
var _tallies_label: Label
var _req_list: VBoxContainer
var _req_close: Button
var _req_open_btn: Button

## District production browsing lives on the Requisition panel — public info.
var _district_expanded := false
var _district_toggle: Button
var _district_label: Label

var _notice_ttl := 0.0
var _pulse_t := 0.0
var _status_dirty := true ## starts true so _process() paints the initial labels
var _last_trust_standing: StringName = &""
var _trust_flash_ttl := 0.0
var _trust_delta := 0.0
var _last_notice_tone: StringName = &"neutral"


func _ready() -> void:
	var ui := get_parent()
	if ui:
		_cycle_label = ui.get_node_or_null("CycleLabel") as Label
		_trust_label = ui.get_node_or_null("TrustLabel") as Label
		_notice_label = ui.get_node_or_null("NoticeLabel") as Label

	_orders = get_tree().root.get_node_or_null("Orders")
	_wallet = get_tree().root.get_node_or_null("Wallet")
	_trust = get_tree().root.get_node_or_null("Trust")
	_district = get_tree().root.get_node_or_null("District")
	_storage = get_tree().root.get_node_or_null("Storage")
	_clock = get_tree().root.get_node_or_null("Clock")
	_bus = get_tree().root.get_node_or_null("EventBus")

	_ensure_requisition_modal()
	_apply_chrome()

	if _bus:
		_bus.trust_changed.connect(_on_trust_changed)
		_bus.tallies_changed.connect(_on_tallies_changed)
		_bus.district_changed.connect(_on_district_changed)
		_bus.storage_changed.connect(_on_storage_changed)
		_bus.phase_changed.connect(_on_phase_changed)
		_bus.gear_ordered.connect(_on_gear_ordered)

	_ensure_requisition_open_btn()
	_build_requisition_buttons()
	if _trust:
		_last_trust_standing = _trust.get_trust()
	_refresh_status()
	_refresh()


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
	# Slim Hollow chip — quieter than the shop modal, secondary to the cavern.
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
	UiStyleRef.apply_label(_condition_label, &"teal")
	if _condition_label:
		_condition_label.modulate.a = 0.9
	UiStyleRef.tip(
		_condition_label,
		"How a district's Capacity/Demand/Reserves balance is holding up right now."
	)
	if _cycle_label:
		UiStyleRef.apply_label(_cycle_label, &"stat")
		UiStyleRef.tip(_cycle_label, "The Pulse-driven civic cycle: Rousing, Working, Gathering, Ritual.")
	if _trust_label:
		UiStyleRef.apply_label(_trust_label, &"stat")
		UiStyleRef.tip(_trust_label, "How trusted you are in the Hollow.")
	if _notice_label:
		UiStyleRef.apply_label(_notice_label, &"body")

	if _req_panel:
		UiStyleRef.apply_panel(_req_panel, &"teal", true)
	if _tallies_label:
		UiStyleRef.apply_label(_tallies_label, &"teal")
		UiStyleRef.tip(_tallies_label, "Personal work pay, earned through Jobs.")
	if _district_label:
		UiStyleRef.apply_label(_district_label, &"muted")
		UiStyleRef.tip(_district_label, "District Capacity, Demand, and Reserves.")
	if _district_toggle:
		UiStyleRef.apply_button(_district_toggle, true)
		UiStyleRef.tip(_district_toggle, "District production — Capacity, Demand, Reserves, condition.")
	if _req_close:
		UiStyleRef.apply_button(_req_close, true)


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
	UiStyleRef.tip(_req_open_btn, "Order Approved Gear — spend Tallies and authorized District Output.")
	if not _req_open_btn.pressed.is_connected(open_requisition):
		_req_open_btn.pressed.connect(open_requisition)


func is_requisition_open() -> bool:
	return _req_expanded and _req_panel != null and _req_panel.visible


func open_requisition() -> void:
	_req_expanded = true
	_refresh()


func close_requisition() -> void:
	_req_expanded = false
	_district_expanded = false
	_refresh()


func _toggle_districts() -> void:
	_district_expanded = not _district_expanded
	_refresh_requisition_status()


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
	# The cycle countdown changes every frame even with no signal — poll it.
	_status_dirty = true
	if _status_dirty:
		_status_dirty = false
		_refresh_status()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel") and is_requisition_open():
		close_requisition()
		get_viewport().set_input_as_handled()
		return

	if event.is_action_pressed("requisition_upgrade"):
		if is_requisition_open():
			close_requisition()
		else:
			open_requisition()
		get_viewport().set_input_as_handled()
		return


func _build_requisition_buttons() -> void:
	if _req_list == null or _orders == null:
		return
	for child in _req_list.get_children():
		child.queue_free()
	_req_buttons.clear()

	for id: StringName in _orders.get_orderable_gear_ids():
		var btn := Button.new()
		btn.focus_mode = Control.FOCUS_NONE
		btn.name = String(id)
		btn.custom_minimum_size = Vector2(0, 24)
		btn.alignment = HORIZONTAL_ALIGNMENT_LEFT
		UiStyleRef.apply_button(btn, true)
		btn.pressed.connect(_try_order.bind(id))
		_req_list.add_child(btn)
		_req_buttons[id] = btn


func _try_order(gear_id: StringName) -> void:
	if _orders == null:
		return
	if not _req_expanded:
		open_requisition()
	var result: Dictionary = _orders.order(gear_id)
	if bool(result["success"]):
		_show_notice("Order placed.")
	else:
		_show_notice(_order_refusal_text(str(result["reason"])))
	_refresh()


func _order_refusal_text(reason: String) -> String:
	match reason:
		"trust_too_low":
			return "Order refused — not trusted enough yet."
		"insufficient_tallies":
			return "Order refused — not enough Tallies."
		"insufficient_district_output":
			return "Order refused — the district doesn't have enough on hand."
		"district_refused_for_demand":
			return "Order refused — the district needs that output for itself right now."
		"already_owned":
			return "You already own that."
		_:
			return "Order refused."


func _on_trust_changed(standing: StringName, delta: float, _reason: String) -> void:
	if _last_trust_standing != &"" and standing != _last_trust_standing:
		_trust_delta = delta
		_trust_flash_ttl = 0.95
	_last_trust_standing = standing
	_status_dirty = true


func _on_tallies_changed(_balance: int, _delta: int, _reason: String) -> void:
	_refresh_requisition_status()


func _on_district_changed(_district_id: StringName, _condition: StringName) -> void:
	_refresh_district_condition()
	_refresh_requisition_status()
	_refresh_requisition_buttons()


func _on_storage_changed(_kind: StringName, _id: StringName, _new_count: int) -> void:
	pass # Materials are shown by salvage_hud.gd; nothing here reads Storage directly yet.


func _on_phase_changed(_old_phase: StringName, _new_phase: StringName) -> void:
	_status_dirty = true


func _on_gear_ordered(_gear_id: StringName, _district_id: StringName, _tallies_spent: int, _output_drawn: float) -> void:
	_refresh()


## Public — other systems (main.gd's dialogue/frontier-notice relays) post a
## toast through here instead of the retired notice signal.
func show_notice(text: String) -> void:
	_show_notice(text)


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
	if "order placed" in lower or "ordered" in lower:
		return &"gain"
	if "refused" in lower:
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
	visible = true
	_refresh_district_condition()
	_refresh_requisition_status()
	_refresh_requisition_buttons()
	_set_requisition_visible(_req_expanded)
	if _req_open_btn:
		_req_open_btn.visible = true
		_req_open_btn.text = "Close requisition  [Q]" if _req_expanded else "Requisition  [Q]"
	call_deferred("_fit_to_content")


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
	if _cycle_label == null and _trust_label == null:
		return
	if _clock == null or _trust == null:
		if _cycle_label:
			_cycle_label.text = "Cycle ?"
			_cycle_label.modulate = UiStyleRef.TEXT_MUTED
		if _trust_label:
			_trust_label.text = "Trust ?"
			_trust_label.modulate = UiStyleRef.TEXT_MUTED
		return

	var trust_tag := ""
	if _trust_flash_ttl > 0.0 and not is_zero_approx(_trust_delta):
		trust_tag = " (%+.0f)" % _trust_delta

	if _cycle_label:
		var phase: StringName = _clock.get_phase()
		var remaining: float = _clock.get_seconds_remaining_in_phase()
		_cycle_label.text = "%s %ds" % [String(phase).capitalize(), int(ceil(remaining))]
		# Soft urgency — social clock pulse when low, not arcade alarm.
		if remaining <= 10.0:
			var pulse := 0.78 + 0.22 * (0.5 + 0.5 * sin(_pulse_t * 3.6))
			_cycle_label.modulate = Color(1.0, 0.72, 0.42, pulse)
		elif remaining <= 20.0:
			_cycle_label.modulate = Color(0.98, 0.9, 0.7, 0.95)
		else:
			_cycle_label.modulate = UiStyleRef.TEXT_PRIMARY

	if _trust_label:
		_trust_label.text = "Trust: %s%s" % [_trust.get_standing_label(), trust_tag]
		if _trust_flash_ttl > 0.0 and _trust_delta < 0.0:
			_trust_label.modulate = Color(1.0, 0.78, 0.62, 1.0)
		elif _trust_flash_ttl > 0.0 and _trust_delta > 0.0:
			_trust_label.modulate = Color(0.78, 0.92, 0.8, 1.0)
		else:
			_trust_label.modulate = UiStyleRef.TEXT_PRIMARY


## Test helper — true when the civic-cycle urgency pulse band is active.
func is_cycle_urgent() -> bool:
	if _clock == null:
		return false
	return _clock.get_seconds_remaining_in_phase() <= 10.0


func debug_notice_tone() -> StringName:
	return _last_notice_tone


## District condition chip (always visible) — worst condition across the
## known districts, human-readable label only (canon: no percentages).
func _refresh_district_condition() -> void:
	var text := "District condition ?"
	if _district != null:
		var ladder: Array = _district.get_condition_ladder()
		var worst_index := -1
		var worst_label := ""
		var worst_district := ""
		for id: StringName in _district.get_district_ids():
			var condition: StringName = _district.get_condition(id)
			for i in range(ladder.size()):
				if ladder[i]["id"] == condition and i > worst_index:
					worst_index = i
					worst_label = str(ladder[i]["label"])
					worst_district = _district.get_display_name(id)
		if worst_index >= 0:
			text = "%s: %s" % [worst_district, worst_label]
	if _condition_label:
		_condition_label.text = text


## Requisition panel: Tallies balance + the district production breakdown.
func _refresh_requisition_status() -> void:
	if _tallies_label:
		var tallies := 0
		if _wallet != null:
			tallies = _wallet.get_balance()
		_tallies_label.text = "Tallies %d" % tallies

	if _district_toggle:
		_district_toggle.text = "District production ▾" if _district_expanded else "District production ▸"
		_district_toggle.visible = _req_expanded

	if _district_label:
		_district_label.visible = _req_expanded and _district_expanded
		if _district_expanded and _district != null:
			var lines: PackedStringArray = PackedStringArray()
			for id: StringName in _district.get_district_ids():
				lines.append("%s — %s" % [_district.get_display_name(id), _district.get_condition_label(id)])
				lines.append(
					"  Capacity %.0f · Demand %.0f · Reserves %.0f/%.0f"
					% [
						_district.get_capacity(id),
						_district.get_demand(id),
						_district.get_reserves(id),
						_district.get_reserve_cap(id),
					]
				)
			_district_label.text = "\n".join(lines)


func _refresh_requisition_buttons() -> void:
	if _orders == null:
		return
	for id: StringName in _req_buttons.keys():
		var btn: Button = _req_buttons[id]
		var terms: Dictionary = _orders.get_order_terms(id)
		var check: Dictionary = _orders.can_order(id)
		var rig := get_tree().root.get_node_or_null("Rig")
		var display_name := str(rig.get_gear_display_name(id)) if rig else String(id)
		var district_name := ""
		if _district != null and terms.has("district"):
			district_name = _district.get_display_name(terms["district"])
		var cost_parts: PackedStringArray = PackedStringArray()
		if int(terms.get("tallies", 0)) > 0:
			cost_parts.append("%d Tallies" % int(terms["tallies"]))
		if float(terms.get("output", 0.0)) > 0.0:
			cost_parts.append("%.0f %s output" % [float(terms["output"]), district_name])
		btn.text = "%s — %s" % [display_name, " + ".join(cost_parts)]
		btn.disabled = not bool(check["ok"])
		if not bool(check["ok"]):
			btn.tooltip_text = _order_refusal_text(str(check["reason"]))
