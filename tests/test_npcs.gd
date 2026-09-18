extends SceneTree
## Build Bible Spec 16 (NPC Agents + Schedules + Navigation) acceptance tests.
##
## Not covered here, and why:
## - Navigation between zones through player-changed terrain — spike-owned
##   per the spec's own header; relocation at a phase boundary is a direct
##   placement until the spike lands.
## - Idle behavior (wander, bob, facing) — reused from the prototype
##   unchanged and already covered by tests/test_feel_feedback.gd.
## - Chunk unloading mid-interaction — a non-issue under Spec 05's "no
##   streaming" choice, as the spec says; the "zone not loaded" path is
##   exercised here by unregistering an anchor directly.


func _init() -> void:
	call_deferred("_run")


func _fail(msg: String) -> void:
	push_error("FAIL " + msg)
	quit(1)


func _near_any(pos: Vector2, points: Array[Vector2], tolerance: float) -> bool:
	for p: Vector2 in points:
		# hollow_npc wanders +-10px in x around its origin; y is exact.
		if absf(pos.y - p.y) <= 0.5 and absf(pos.x - p.x) <= tolerance:
			return true
	return false


func _run() -> void:
	var npcs: Node = root.get_node_or_null("Npcs")
	var zones: Node = root.get_node_or_null("Zones")
	var clock: Node = root.get_node_or_null("Clock")
	var console: Node = root.get_node_or_null("DebugConsole")
	var save_load: Node = root.get_node_or_null("SaveLoad")
	var community: Node = root.get_node_or_null("Community")
	if npcs == null or zones == null or clock == null or console == null or save_load == null:
		_fail("missing autoloads (Npcs / Zones / Clock / DebugConsole / SaveLoad)")
		return
	if community:
		community.set_paused(true)
	save_load.clear_save()
	clock.reset_all()
	clock.pause("test")

	# --- 1. Schedules are content naming zones; "was anyone scheduled at
	# [zone] during [phase]" is answered from data alone — no scene is
	# loaded yet, so every zone here is one that was never loaded. ---
	for id: StringName in [&"pell", &"rook", &"sila", &"joss"]:
		if not bool(npcs.is_known_npc(id)):
			_fail("NPC '%s' not loaded from content/npcs/" % id)
			return
	for zone_id: String in ["home_court", "glowbeds", "wickwork", "mid_heart", "cistern"]:
		if not bool(zones.has_zone(zone_id)):
			_fail("zone '%s' not loaded from content/zones/" % zone_id)
			return
		if bool(zones.is_zone_loaded(zone_id)):
			_fail("zone '%s' reports loaded with no scene in the tree" % zone_id)
			return
	if str(npcs.get_scheduled_zone(&"pell", &"working")) != "glowbeds" or str(npcs.get_scheduled_zone(&"pell", &"ritual")) != "mid_heart":
		_fail("Pell's schedule did not load (%s / %s)" % [npcs.get_scheduled_zone(&"pell", &"working"), npcs.get_scheduled_zone(&"pell", &"ritual")])
		return
	if str(npcs.get_scheduled_zone(&"nobody", &"working")) != "":
		_fail("unknown NPC has a scheduled zone")
		return
	var at_cistern: Array[StringName] = npcs.get_scheduled_npcs_at("cistern", &"working")
	if at_cistern != [&"sila"]:
		_fail("cistern during working should be exactly Sila, got %s" % [at_cistern])
		return
	if not (npcs.get_scheduled_npcs_at("cistern", &"ritual") as Array).is_empty():
		_fail("cistern during ritual should be empty (everyone is at Mid Heart)")
		return
	var at_ritual: Array[StringName] = npcs.get_scheduled_npcs_at("mid_heart", &"ritual")
	if at_ritual != [&"joss", &"pell", &"rook", &"sila"]:
		_fail("mid_heart during ritual should be all four (sorted), got %s" % [at_ritual])
		return
	var answer: String = console.execute("scheduled_at wickwork working")
	if not answer.contains("rook"):
		_fail("scheduled_at debug command wrong: '%s'" % answer)
		return
	if bool(npcs.is_agent_loaded(&"sila")) or not (npcs.get_loaded_agents() as Array).is_empty():
		_fail("agents reported loaded with no scene")
		return
	print("PASS schedules load as content; off-screen presence is queryable for zones never loaded")

	# --- 2. In the real scene, each body sits at an idle point of its
	# scheduled zone, and a phase transition (a real Clock event) moves
	# everyone to their next zone. ---
	var scene: Node = (load("res://main.tscn") as PackedScene).instantiate()
	root.add_child(scene)
	await process_frame
	await process_frame
	await process_frame
	var loaded_ids: Array[String] = zones.get_loaded_zone_ids()
	var expected_ids: Array[String] = [
		"bottom_west_approach",
		"bottom_west_threshold",
		"cistern",
		"collapsed_side_chamber",
		"first_expansion_gallery",
		"glowbeds",
		"home_court",
		"lower_switchback",
		"mid_heart",
		"west_dispatch_yard",
		"wickwork",
	]
	if loaded_ids != expected_ids:
		_fail("main.tscn zone anchors not registered: %s" % [loaded_ids])
		return
	var pell: Node2D = scene.get_node("Hollow/NPCs/Pell") as Node2D
	var sila: Node2D = scene.get_node("Hollow/NPCs/Sila") as Node2D
	var joss: Node2D = scene.get_node("Hollow/NPCs/Joss") as Node2D
	if clock.get_phase() != &"rousing":
		_fail("clock not at rousing at scene start")
		return
	if not _near_any(pell.global_position, zones.get_idle_points("glowbeds"), 12.0):
		_fail("Pell not at a Glowbeds idle point during rousing: %s" % pell.global_position)
		return
	if not _near_any(sila.global_position, zones.get_idle_points("cistern"), 12.0):
		_fail("Sila not at a Cistern idle point during rousing: %s" % sila.global_position)
		return
	if not bool(npcs.is_agent_loaded(&"pell")) or (npcs.get_loaded_agents() as Array).size() != 4:
		_fail("all four bodies should be loaded in main.tscn (%d)" % (npcs.get_loaded_agents() as Array).size())
		return
	console.execute("force_phase ritual")  # rousing -> ... -> ritual: real phase_changed events
	await process_frame
	var heart_points: Array[Vector2] = zones.get_idle_points("mid_heart")
	for body: Node2D in [pell, sila, joss, scene.get_node("Hollow/NPCs/Rook") as Node2D]:
		if not _near_any(body.global_position, heart_points, 12.0) or not body.visible:
			_fail("%s not at a Mid Heart idle point during ritual: %s" % [body.name, body.global_position])
			return
	# Four bodies, four points — nobody stacked on the same spot.
	var used: Array = []
	for body: Node2D in [pell, sila, joss, scene.get_node("Hollow/NPCs/Rook") as Node2D]:
		var key := int(round((body.global_position.x + 5.0) / 10.0))  # coarse, wander-tolerant
		if used.has(key):
			_fail("two NPCs placed on the same Mid Heart idle point")
			return
		used.append(key)
	console.execute("force_advance 1")  # ritual -> rousing
	await process_frame
	if not _near_any(pell.global_position, zones.get_idle_points("glowbeds"), 12.0) or not _near_any(sila.global_position, zones.get_idle_points("cistern"), 12.0):
		_fail("bodies did not return to their districts at rousing")
		return
	if str(npcs.get_current_zone(&"joss")) != "mid_heart" or not _near_any(joss.global_position, heart_points, 12.0):
		_fail("Joss should stay at Mid Heart every phase")
		return
	print("PASS bodies match their schedule for the current phase, and follow real phase transitions")

	# --- 3. A body whose scheduled zone is NOT loaded is absent (hidden,
	# not interactable) but still scheduled/queryable; it returns when the
	# zone loads again. ---
	var cistern_anchor: Node = scene.get_node("Hollow/Zones/Cistern")
	zones.unregister_loaded_zone("cistern")
	await process_frame
	if bool(zones.is_zone_loaded("cistern")) or bool(npcs.is_agent_loaded(&"sila")) or sila.visible:
		_fail("Sila should be absent while the Cistern zone is unloaded (loaded=%s visible=%s)" % [npcs.is_agent_loaded(&"sila"), sila.visible])
		return
	var relay: Area2D = sila.get_node_or_null("InteractableRelay") as Area2D
	if relay == null or relay.monitorable:
		_fail("absent NPC is still interactable")
		return
	if (npcs.get_scheduled_npcs_at("cistern", &"rousing") as Array) != [&"sila"] or str(npcs.get_current_zone(&"sila")) != "cistern":
		_fail("off-screen Sila lost her schedule")
		return
	if (npcs.get_loaded_agents() as Array).size() != 3:
		_fail("loaded agents should be 3 with Sila off-screen")
		return
	var where: String = console.execute("where_is sila")
	if not where.contains("off-screen"):
		_fail("where_is did not report off-screen: '%s'" % where)
		return
	zones.register_loaded_zone("cistern", cistern_anchor)
	await process_frame
	if not bool(npcs.is_agent_loaded(&"sila")) or not sila.visible or not relay.monitorable:
		_fail("Sila did not return when the Cistern zone loaded again")
		return
	if not _near_any(sila.global_position, zones.get_idle_points("cistern"), 12.0):
		_fail("returned Sila not at a Cistern idle point")
		return
	print("PASS an NPC whose zone isn't loaded is absent but still scheduled; returns when it loads")

	# --- 4. Unloading the scene clears loaded zones and bodies (live state,
	# never saved). ---
	scene.queue_free()
	await process_frame
	await process_frame
	if not (zones.get_loaded_zone_ids() as Array).is_empty() or not (npcs.get_loaded_agents() as Array).is_empty():
		_fail("loaded zones/bodies survived the scene leaving the tree: %s" % [zones.get_loaded_zone_ids()])
		return
	if not (npcs.save_state() as Dictionary).is_empty():
		_fail("Npcs should own no saved state")
		return
	print("PASS loaded zones and bodies are live scene state that clears with the scene")

	save_load.clear_save()
	clock.reset_all()
	print("NPCS_TESTS_PASSED")
	quit(0)
