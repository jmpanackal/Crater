extends Control
## The always-on HUD, laid out the way the best side-view games lay theirs out and sized by the canon's rule that the
## world speaks first (mechanics-canon section 55). Persistent information lives in the corners, the thing you carry
## sits at the bottom-centre, and anything momentary appears beside the thing it is about. See docs/ui-reference.md.
##   top-left      your vital: the stamina gauge, with a load chip beneath it only while you are hauling
##   top-right     the corner map, and under it the Pulse's four lamps with the phase name and time left
##   bottom-centre the Rig's Gear sockets as a hotbar, with capacity pips
##   over a thing  the Interact prompt, in a bubble above whatever you stand beside
## Everything else (Standing, the Rig, Approved Gear orders, the Journal, the full map) is a panel you open.
## Display only.

const PulseLamps := preload("res://ui_pulse_lamps.gd")
const StaminaBar := preload("res://ui_stamina_bar.gd")
const Hotbar := preload("res://ui_hotbar.gd")
const Glyph := preload("res://ui_glyph.gd")
const UiStyleRef := preload("res://ui_style.gd")

const MARGIN := 18.0

var _vitals: Control
var _load_chip: Control
var _load_label: Label
var _clock: Control
var _phase_label: Label
var _hotbar: Control
var _prompt: Control
var _prompt_label: Label


func _ready() -> void:
	name = "Hud"
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_build_vitals()
	_build_clock()
	_build_hotbar()
	_build_prompt()
	set_process(true)


func _build_vitals() -> void:
	_vitals = Control.new()
	_vitals.name = "Vitals"
	_vitals.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_vitals.position = Vector2(MARGIN, MARGIN)
	add_child(_vitals)
	var emblem := Control.new()
	emblem.name = "Emblem"
	emblem.set_script(Glyph)
	emblem.set("kind", &"bolt")
	emblem.custom_minimum_size = Vector2(34.0, 34.0)
	emblem.size = Vector2(34.0, 34.0)
	_vitals.add_child(emblem)
	var bar := Control.new()
	bar.name = "Stamina"
	bar.set_script(StaminaBar)
	bar.position = Vector2(42.0, 10.0)
	bar.size = Vector2(230.0, 14.0)
	_vitals.add_child(bar)
	# the load chip: only while hauling
	_load_chip = Control.new()
	_load_chip.name = "LoadChip"
	_load_chip.visible = false
	_load_chip.position = Vector2(42.0, 30.0)
	_load_chip.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var ore := Control.new()
	ore.set_script(Glyph)
	ore.set("kind", &"ore")
	_load_chip.add_child(ore)
	_load_label = Label.new()
	_load_label.position = Vector2(20.0, -2.0)
	UiStyleRef.apply_label(_load_label, &"stat")
	_load_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_load_chip.add_child(_load_label)
	_vitals.add_child(_load_chip)


## The civic phase: a small Pulse mark, its four lamps and the phase name, top-centre. The time left is on hover, not a
## bar: a bar next to the stamina gauge read as a second meter.
func _build_clock() -> void:
	_clock = Control.new()
	_clock.name = "Clock"
	_clock.mouse_filter = Control.MOUSE_FILTER_PASS
	_clock.size = Vector2(190.0, 20.0)
	add_child(_clock)
	var mark := Control.new()
	mark.name = "PulseMark"
	mark.set_script(Glyph)
	mark.set("kind", &"pulse")
	mark.custom_minimum_size = Vector2(18.0, 18.0)
	mark.size = Vector2(18.0, 18.0)
	_clock.add_child(mark)
	var lamps := Control.new()
	lamps.name = "PulseLamps"
	lamps.set_script(PulseLamps)
	lamps.position = Vector2(26.0, 1.0)
	_clock.add_child(lamps)
	_phase_label = Label.new()
	_phase_label.name = "PhaseName"
	_phase_label.position = Vector2(108.0, -3.0)
	UiStyleRef.apply_label(_phase_label, &"stat")
	_phase_label.add_theme_color_override("font_color", UiStyleRef.TEXT_AMBER)
	_phase_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_clock.add_child(_phase_label)


func _build_hotbar() -> void:
	_hotbar = Control.new()
	_hotbar.name = "Hotbar"
	_hotbar.set_script(Hotbar)
	add_child(_hotbar)


## The Interact prompt as a bubble over the thing it is about (Hollow Knight, Ori, Hades): a key cap and the verb, with
## a small pointer, instead of a line stuck to the bottom of the screen.
func _build_prompt() -> void:
	_prompt = Control.new()
	_prompt.name = "Prompt"
	_prompt.visible = false
	_prompt.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var plate := PanelContainer.new()
	plate.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var small := UiStyleRef.quiet_panel_style()
	small.content_margin_left = 4.0
	small.content_margin_right = 5.0
	small.content_margin_top = 1.0
	small.content_margin_bottom = 1.0
	small.set("rivets", false)
	plate.add_theme_stylebox_override("panel", small)
	plate.modulate = Color(1, 1, 1, 0.82)
	plate.name = "Plate"
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 5)
	var key := Label.new()
	key.text = "E"
	UiStyleRef.apply_label(key, &"stat")
	key.add_theme_font_size_override("font_size", 9)
	key.custom_minimum_size = Vector2(12.0, 0.0)
	key.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	key.add_theme_color_override("font_color", Color(0.1, 0.07, 0.03))
	var key_style := StyleBoxFlat.new()
	key_style.bg_color = Color(1.0, 0.8, 0.46)
	key_style.set_corner_radius_all(3)
	key.add_theme_stylebox_override("normal", key_style)
	row.add_child(key)
	_prompt_label = Label.new()
	UiStyleRef.apply_label(_prompt_label, &"stat")
	_prompt_label.add_theme_font_size_override("font_size", 9)
	_prompt_label.add_theme_color_override("font_color", UiStyleRef.TEXT_PRIMARY)
	row.add_child(_prompt_label)
	plate.add_child(row)
	_prompt.add_child(plate)
	var pointer := Label.new()
	pointer.name = "Pointer"
	pointer.text = "▼"
	pointer.add_theme_font_size_override("font_size", 8)
	pointer.add_theme_color_override("font_color", Color(0.62, 0.47, 0.27, 0.95))
	pointer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_prompt.add_child(pointer)
	add_child(_prompt)


func _process(_delta: float) -> void:
	# a Control under a CanvasLayer has no parent Control to size against, so follow the viewport
	position = Vector2.ZERO
	size = get_viewport_rect().size
	var vp := size
	_clock.position = Vector2((vp.x - _clock.size.x) * 0.5, 12.0)
	_hotbar.position = Vector2((vp.x - _hotbar.size.x) * 0.5, vp.y - 82.0)
	var clock := get_node_or_null("/root/Clock")
	if clock != null and clock.has_method("get_phase"):
		var phase := str(clock.get_phase())
		_phase_label.text = phase.capitalize()
		_clock.tooltip_text = "%s: %d s left. The Pulse sets the civic cycle." % [phase.capitalize(), int(clock.get_seconds_remaining_in_phase())]
	var hauling := get_node_or_null("/root/Hauling")
	if hauling != null and hauling.has_method("is_loaded"):
		var loaded: bool = hauling.is_loaded()
		_load_chip.visible = loaded
		if loaded:
			var l: Dictionary = hauling.get_load()
			_load_label.text = "%s x%d" % [str(l["material_id"]).capitalize(), int(l["amount"])]
	_update_prompt()


func _update_prompt() -> void:
	var target := _current_target()
	var text := ""
	if target != null and target.has_method("get_interact_prompt"):
		text = str(target.get_interact_prompt())
	_prompt.visible = text != "" and not _modal_open()
	if not _prompt.visible:
		return
	_prompt_label.text = text
	var plate := _prompt.get_node("Plate") as Control
	plate.reset_size()
	var pointer := _prompt.get_node("Pointer") as Control
	# above the thing, in screen space (the canvas transform carries the camera)
	var world: Vector2 = (target as Node2D).global_position if target is Node2D else Vector2.ZERO
	var screen := get_viewport().get_canvas_transform() * world
	var w := plate.size.x
	_prompt.position = Vector2(clampf(screen.x - w * 0.5, 8.0, size.x - w - 8.0), clampf(screen.y - 58.0, 8.0, size.y - 60.0))
	pointer.position = Vector2(w * 0.5 - 5.0, plate.size.y - 2.0)


func _current_target() -> Node:
	var player := get_tree().get_first_node_in_group("player")
	if player == null:
		return null
	var inter := player.get_node_or_null("Interaction")
	if inter == null or not inter.has_method("get_current_target"):
		return null
	return inter.get_current_target()


## A panel you opened owns the screen: the Interact prompt steps aside while Standing, the Rig, Approved Gear orders, the
## Journal or a conversation is open.
func _modal_open() -> bool:
	var ui := get_parent()
	if ui == null:
		return false
	for name in ["StandingPanel", "RigPanel"]:
		var p := ui.get_node_or_null(name)
		if p != null and p.has_method("is_open") and p.is_open():
			return true
	var orders := ui.get_node_or_null("UpgradePanel")
	if orders != null and orders.has_method("is_requisition_open") and orders.is_requisition_open():
		return true
	var journal := ui.get_node_or_null("JournalHud")
	if journal != null and journal.has_method("is_open") and journal.is_open():
		return true
	var talk := ui.get_node_or_null("DialoguePanel") as CanvasLayer
	return talk != null and talk.visible
