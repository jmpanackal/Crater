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

	# --- 2-4. QUARANTINED (2026-09-18): these covered real-scene NPC
	# placement/movement across phase transitions, an NPC going absent when
	# its zone unloads and returning when it reloads, and loaded zones/bodies
	# clearing when the scene unloads — all driven by main.tscn's old
	# district NPCs (Pell/Sila/Joss/Rook) and zone anchors (glowbeds,
	# wickwork, mid_heart, cistern). main.tscn's Hollow subtree was deleted
	# for a canon-grounded rebuild (docs/hollow-level-authoring.md). This pass
	# only rebuilds Home Court + Bottom-West Dig Front; those NPCs and
	# districts are a later phase. Restore these tests' real assertions once
	# NPCs are rebuilt into the new districts — tracked in
	# docs/priority-roadmap.md, not forgotten.

	save_load.clear_save()
	clock.reset_all()
	print("NPCS_TESTS_PASSED")
	quit(0)
