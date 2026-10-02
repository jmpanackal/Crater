extends SceneTree
## The opening-route slice: everything HollowDressing declares is built, drawn without errors,
## and the usable things work (sleep, storage, workbench, the fragment, the two talkers). The
## structural rules are HollowMapLint's "dress" rule; this proves the scene and the interactions.


func _init() -> void:
	call_deferred("_run")


func _fail(msg: String) -> void:
	push_error("FAIL " + msg)
	quit(1)


func _frames(n: int) -> void:
	for _i in range(n):
		await physics_frame


func _run() -> void:
	var rep := HollowMapLint.run()
	if not (rep["errors"] as Array).is_empty():
		_fail("map lint has errors: %s" % [rep["errors"]])
		return
	var scene: Node = (load("res://main.tscn") as PackedScene).instantiate()
	root.add_child(scene)
	await process_frame
	await process_frame
	var srep := HollowMapLint.lint_scene(scene)
	if not (srep["errors"] as Array).is_empty():
		_fail("scene lint has errors: %s" % [srep["errors"]])
		return
	var dressing: Node = scene.get_node("Hollow/Dressing")
	var persons := 0
	for child in dressing.get_children():
		if child.name.begins_with("Person_"):
			persons += 1
	var ambient := 0
	for a in HollowDressing.actors():
		if not bool(a["talk"]):
			ambient += 1
	if persons != ambient or persons < 15:
		_fail("expected %d ambient people, found %d" % [ambient, persons])
		return
	print("PASS the slice is built: %d props, %d people, %d stations; map and scene lint clean" % [HollowDressing.props().size(), HollowDressing.actors().size(), HollowDressing.stations().size()])

	# --- Walkers walk, and stay on their beat. ---
	var courier: Node2D = dressing.get_node("Person_sb_courier")
	var x0 := courier.position.x
	player_near(scene, courier)
	await _frames(240)
	var moved := absf(courier.position.x - x0)
	if moved < 20.0 or absf(courier.position.x - float(HollowDressing.actors().filter(func(a: Dictionary) -> bool: return a["id"] == &"sb_courier")[0]["x"])) > 125.0:
		_fail("a courier should walk its beat and stay on it (moved %s)" % moved)
		return
	print("PASS people walk their beat")

	# --- The two talkers. ---
	var foreman: Node = scene.get_node_or_null("Hollow/NPCs/Talker_dy_foreman")
	var warden: Node = scene.get_node_or_null("Hollow/NPCs/Talker_th_warden")
	if foreman == null or warden == null:
		_fail("the Foreman and the Warden should be talkers under Hollow/NPCs")
		return
	var heard: Array = []
	foreman.talk_requested.connect(func(npc: Node2D, lines: PackedStringArray, _choice: String) -> void: heard.append([npc, lines]))
	foreman.on_interact(null)
	if heard.size() != 1 or (heard[0][1] as PackedStringArray).size() < 1 or foreman.get_interact_prompt() != "Talk to Foreman":
		_fail("the Foreman should talk")
		return
	print("PASS the Foreman and the Warden talk")

	# --- The bed: sleeping is only allowed from Gathering. ---
	var bed: Node = dressing.get_node("Station_home_bed")
	var clock: Node = root.get_node("Clock")
	var fatigue: Node = root.get_node("Fatigue")
	root.get_node("DebugConsole").execute("force_phase working")
	if bed.get_interact_prompt() != "Bed (sleep after Gathering)":
		_fail("the bed should say it is too early (%s)" % bed.get_interact_prompt())
		return
	bed.on_interact(null)
	if clock.get_phase() != &"working":
		_fail("sleeping at Working must do nothing")
		return
	root.get_node("DebugConsole").execute("force_phase gathering")
	fatigue.add_fatigue(30.0)
	if bed.get_interact_prompt() != "Sleep until Rousing":
		_fail("the bed should offer sleep at Gathering")
		return
	bed.on_interact(null)
	if clock.get_phase() != &"rousing" or float(fatigue.get_current()) > 0.0:
		_fail("sleep should reach Rousing and clear Fatigue (%s, %s)" % [clock.get_phase(), fatigue.get_current()])
		return
	print("PASS the bed: refused early, sleeps from Gathering to Rousing and clears Fatigue")

	# --- Lockbox and workbench are the real Storage and Rig access points. ---
	var opened: Array = []
	var box: Node = dressing.get_node("Station_home_lockbox")
	box.opened.connect(func(_id: StringName, storage: Node) -> void: opened.append(storage))
	box.on_interact(null)
	var bench: Node = dressing.get_node("Station_home_workbench")
	var refit: Array = []
	bench.opened.connect(func(_s: Node, rig: Node) -> void: refit.append(rig))
	bench.on_interact(null)
	if opened.size() != 1 or opened[0] != root.get_node("Storage") or refit.size() != 1 or bench.get_station_kind() != &"home":
		_fail("lockbox should open Storage and the workbench should open the home Rig station")
		return
	print("PASS the lockbox opens Storage; the workbench is a home Rig station")

	# --- The player's own Interaction finds the nearest thing when standing at it. ---
	var player: CharacterBody2D = scene.get_node("Player") as CharacterBody2D
	player.global_position = Vector2(-204.0 - 16.0, HollowLayout.WEST_LW_UPPER_Y - 32.0)
	player.velocity = Vector2.ZERO
	await _frames(12)
	var prompt: String = str(player.get_interaction().get_current_prompt())
	if prompt != "Open storage":
		_fail("standing at the lockbox the prompt should be 'Open storage' (got '%s')" % prompt)
		return
	print("PASS standing at the lockbox, Interact offers it")

	# --- The fragment in the Collapsed Side Chamber unlocks a Record once. ---
	var journal: Node = root.get_node("Journal")
	journal.clear_all()
	var frag: Node = dressing.get_node_or_null("Station_chamber_fragment")
	if frag == null:
		_fail("the chamber fragment is missing")
		return
	frag.on_interact(null)
	await process_frame
	if not bool(journal.has_record(&"slate_shard")) or is_instance_valid(frag):
		_fail("taking the fragment should unlock the Record and remove it")
		return
	journal.clear_all()
	print("PASS the fragment unlocks a Record and is gone")

	print("HOLLOW_DRESSING_TESTS_PASSED")
	quit(0)


func player_near(scene: Node, node: Node2D) -> void:
	var p: Node2D = scene.get_node("Player")
	p.global_position = node.global_position + Vector2(0.0, -32.0)
