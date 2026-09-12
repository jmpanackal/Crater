extends Node2D
## Main play scene bootstrap: wire NPCs, dialogue, terrain notices, Esc→title.
## F11 toggles fullscreen; Esc closes Journal before returning to title.

const UiStyleRef := preload("res://ui_style.gd")
const WorkOrderTrackerScript := preload("res://work_order_tracker.gd")

@onready var _dialogue: CanvasLayer = $UI/DialoguePanel
@onready var _journal: CanvasLayer = $UI/JournalHud
@onready var _hints: Label = $UI/Hints
@onready var _npcs: Node2D = $Hollow/NPCs
@onready var _primary_hud: PanelContainer = $UI/PrimaryHud

var _hints_ttl := 8.0
var _hints_pinned := false
## "joss_offer" | "pell_help" | "" — which Yes/No prompt is open.
var _pending_choice_kind := ""


func _ready() -> void:
	var community := get_tree().root.get_node_or_null("Community")
	if community:
		community.skip_lie_prompt = false

	var terrain := get_node_or_null("Terrain")
	if terrain and terrain.has_signal("frontier_notice"):
		terrain.frontier_notice.connect(_on_frontier_notice)

	if _npcs:
		for child in _npcs.get_children():
			if child.has_signal("talk_requested"):
				child.talk_requested.connect(_on_npc_talk)

	if _dialogue and _dialogue.has_signal("choice_made"):
		_dialogue.choice_made.connect(_on_dialogue_choice)

	_ensure_work_order_tracker()
	_apply_hud_chrome()


func _ensure_work_order_tracker() -> void:
	var ui := get_node_or_null("UI")
	if ui == null:
		return
	if ui.get_node_or_null("WorkOrderTracker") != null:
		return
	var tracker := Control.new()
	tracker.name = "WorkOrderTracker"
	tracker.set_script(WorkOrderTrackerScript)
	ui.add_child(tracker)


func _apply_hud_chrome() -> void:
	if _primary_hud:
		# Quiet always-on chrome — world stays the visual hero.
		UiStyleRef.apply_panel(_primary_hud, &"copper", false, true)
		_primary_hud.modulate = Color(1.0, 1.0, 1.0, 0.72)
		_primary_hud.custom_minimum_size = Vector2(UiStyleRef.HUD_CHIP_WIDTH, 0)
	if _hints:
		UiStyleRef.apply_label(_hints, &"muted")
		_hints.modulate.a = 0.45
	var harvest := get_node_or_null("UI/HarvestLabel") as Label
	if harvest:
		UiStyleRef.apply_label(harvest, &"stat")
		harvest.modulate = Color(0.9, 0.9, 0.86, 0.92)
	var standing := get_node_or_null("UI/StandingLabel") as Label
	if standing:
		UiStyleRef.apply_label(standing, &"stat")
		standing.modulate = Color(0.9, 0.9, 0.86, 0.92)
	var meaning := get_node_or_null("UI/MeaningHint") as Label
	if meaning:
		meaning.modulate.a = 0.42
	var notice := get_node_or_null("UI/NoticeLabel") as Label
	if notice:
		UiStyleRef.apply_label(notice, &"body")
	var lie_panel := get_node_or_null("UI/LiePromptPanel") as PanelContainer
	if lie_panel:
		UiStyleRef.apply_panel(lie_panel, &"copper", true)


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
		if upgrade_panel and upgrade_panel.has_method("is_shop_open") and upgrade_panel.is_shop_open():
			upgrade_panel.close_shop()
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

	if speaker == "Joss":
		var wo := get_tree().root.get_node_or_null("WorkOrders")
		if wo and wo.has_method("get_joss_lines"):
			talk_lines = wo.get_joss_lines()
			talk_choice = wo.get_joss_choice_prompt() if wo.has_method("get_joss_choice_prompt") else ""
			if talk_choice != "":
				_pending_choice_kind = "joss_offer"
			elif wo.get_state() == wo.STATE_MATERIALS_DELIVERED:
				# Show delivery lines, then mark awaiting Harvest.
				wo.acknowledge_delivery()

	if talk_choice != "" and _pending_choice_kind == "" and speaker == "Pell":
		_pending_choice_kind = "pell_help"

	_dialogue.open_talk(speaker, talk_lines, talk_choice)


func _on_dialogue_choice(accepted: bool) -> void:
	var kind := _pending_choice_kind
	_pending_choice_kind = ""
	if kind == "joss_offer":
		var wo := get_tree().root.get_node_or_null("WorkOrders")
		var community := get_tree().root.get_node_or_null("Community")
		if accepted and wo and wo.has_method("accept_offered"):
			wo.accept_offered()
			if community and community.has_signal("notice_message"):
				community.notice_message.emit("Work Order accepted: %s" % wo.get_title())
		elif community and community.has_signal("notice_message"):
			community.notice_message.emit("You leave the Work Order with Joss for now.")
		return

	# Rare prompt from Pell: "Help with the beds?" — tiny Trust nudge if yes.
	if kind != "pell_help":
		return
	var community2 := get_tree().root.get_node_or_null("Community")
	if community2 == null:
		return
	if accepted:
		community2.set_trust(community2.get_trust() + 1)
		community2.notice_message.emit("You help in the Glowbeds. (+1 Trust)")
	else:
		community2.notice_message.emit("You make an excuse and slip away.")


func _on_frontier_notice(text: String) -> void:
	var community := get_tree().root.get_node_or_null("Community")
	if community and community.has_signal("notice_message"):
		community.notice_message.emit(text)
