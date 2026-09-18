extends Node2D
## Main play scene bootstrap: wire NPCs, dialogue, terrain notices, Esc→title.
## F11 toggles fullscreen; Esc closes Journal before returning to title.

const UiStyleRef := preload("res://ui_style.gd")

@onready var _dialogue: CanvasLayer = $UI/DialoguePanel
@onready var _journal: CanvasLayer = $UI/JournalHud
@onready var _hints: Label = $UI/Hints
@onready var _npcs: Node2D = get_node_or_null("Hollow/NPCs")
@onready var _primary_hud: PanelContainer = $UI/PrimaryHud

var _hints_ttl := 8.0
var _hints_pinned := false
## "pell_help" | "" — which Yes/No prompt is open.
var _pending_choice_kind := ""


func _ready() -> void:
	var terrain := get_node_or_null("Terrain")
	if terrain and terrain.has_signal("frontier_notice"):
		terrain.frontier_notice.connect(_on_frontier_notice)

	if _npcs:
		for child in _npcs.get_children():
			if child.has_signal("talk_requested"):
				child.talk_requested.connect(_on_npc_talk)

	if _dialogue and _dialogue.has_signal("choice_made"):
		_dialogue.choice_made.connect(_on_dialogue_choice)

	_apply_hud_chrome()


func _apply_hud_chrome() -> void:
	if _primary_hud:
		# Quiet always-on chrome — world stays the visual hero.
		UiStyleRef.apply_panel(_primary_hud, &"copper", false, true)
		_primary_hud.modulate = Color(1.0, 1.0, 1.0, 0.72)
		_primary_hud.custom_minimum_size = Vector2(UiStyleRef.HUD_CHIP_WIDTH, 0)
	if _hints:
		UiStyleRef.apply_label(_hints, &"muted")
		_hints.modulate.a = 0.45
	var cycle := get_node_or_null("UI/CycleLabel") as Label
	if cycle:
		UiStyleRef.apply_label(cycle, &"stat")
		cycle.modulate = Color(0.9, 0.9, 0.86, 0.92)
	var trust := get_node_or_null("UI/TrustLabel") as Label
	if trust:
		UiStyleRef.apply_label(trust, &"stat")
		trust.modulate = Color(0.9, 0.9, 0.86, 0.92)
	var meaning := get_node_or_null("UI/MeaningHint") as Label
	if meaning:
		meaning.modulate.a = 0.42
	var notice := get_node_or_null("UI/NoticeLabel") as Label
	if notice:
		UiStyleRef.apply_label(notice, &"body")


func _process(delta: float) -> void:
	if _hints == null or _hints_pinned:
		return
	if _hints_ttl <= 0.0:
		return
	_hints_ttl -= delta
	if _hints_ttl <= 0.0:
		_hints.visible = false


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_F11:
			_toggle_fullscreen()
			get_viewport().set_input_as_handled()
			return
		if event.keycode == KEY_H:
			_toggle_hints()
			get_viewport().set_input_as_handled()
			return

	if event.is_action_pressed("ui_cancel"):
		if _journal and _journal.has_method("is_open") and _journal.is_open():
			_journal.close()
			get_viewport().set_input_as_handled()
			return
		var upgrade_panel := get_node_or_null("UI/UpgradePanel")
		if upgrade_panel and upgrade_panel.has_method("is_requisition_open"):
			if upgrade_panel.is_requisition_open():
				upgrade_panel.close_requisition()
				get_viewport().set_input_as_handled()
				return
		var save_load := get_tree().root.get_node_or_null("SaveLoad")
		if save_load and save_load.has_method("save_game"):
			save_load.save_game()
		get_tree().change_scene_to_file("res://title_screen.tscn")
		get_viewport().set_input_as_handled()


func _toggle_fullscreen() -> void:
	var mode := DisplayServer.window_get_mode()
	if mode == DisplayServer.WINDOW_MODE_FULLSCREEN or mode == DisplayServer.WINDOW_MODE_EXCLUSIVE_FULLSCREEN:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_MAXIMIZED)
	else:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)


func _toggle_hints() -> void:
	if _hints == null:
		return
	_hints_pinned = not _hints.visible
	_hints.visible = _hints_pinned
	if _hints_pinned:
		_hints_ttl = 0.0


func _on_npc_talk(npc: Node2D, lines: PackedStringArray, choice_prompt: String) -> void:
	if _dialogue == null or not _dialogue.has_method("open_talk"):
		return
	var speaker: String = npc.name
	if "npc_name" in npc and str(npc.get("npc_name")) != "":
		speaker = str(npc.get("npc_name"))

	_pending_choice_kind = ""
	var talk_lines := lines
	var talk_choice := choice_prompt

	if talk_choice != "" and _pending_choice_kind == "" and speaker == "Pell":
		_pending_choice_kind = "pell_help"

	_dialogue.open_talk(speaker, talk_lines, talk_choice)


func _on_dialogue_choice(accepted: bool) -> void:
	var kind := _pending_choice_kind
	_pending_choice_kind = ""
	# Rare prompt from Pell: "Help with the beds?" — a small, reasoned Trust event.
	if kind != "pell_help":
		return
	if accepted:
		var trust := get_tree().root.get_node_or_null("Trust")
		if trust and trust.has_method("submit_trust_event"):
			trust.submit_trust_event(&"favor", 1.0, "Helped Pell with the Glowbeds")
		_notice("You help in the Glowbeds.")
	else:
		_notice("You make an excuse and slip away.")


func _on_frontier_notice(text: String) -> void:
	_notice(text)


## The HUD notice label is the single toast route for play-scene events.
func _notice(text: String) -> void:
	var upgrade_panel := get_node_or_null("UI/UpgradePanel")
	if upgrade_panel and upgrade_panel.has_method("show_notice"):
		upgrade_panel.show_notice(text)
