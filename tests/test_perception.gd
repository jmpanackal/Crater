extends SceneTree
## Build Bible Spec 17 (Perception: sight + noise + Witness) acceptance tests.
##
## Uses synthetic loaded NPC bodies (registered with Npcs under real
## schedule ids, placed by real zone anchors) so facing, distance, walls
## and zone enclosure can be controlled exactly; the last section drives
## the real path — a Firmament dig in main.tscn witnessed by the real Pell.
##
## Not covered here, and why:
## - The theft hold itself (Spec 26) — not built; its interval re-check is
##   the caller re-calling flag_witnessable(), which the "mid-hold arrival"
##   section exercises directly.
## - Forbidden Gear: excluded by having NO call path at all (Spec 20's hard
##   exclusion) — there is nothing to assert against.
## - Civic-cycle stealth conditions (crowds, post-Ritual quiet) — tuning
##   DIRECTION for later, per the spec.

const ZoneAnchorScript := preload("res://zone_anchor.gd")


class FakeBody extends Node2D:
	var facing := 1.0
	func get_facing_sign() -> float:
		return facing
	func relocate_to(p: Vector2) -> void:
		global_position = p
	func set_present(p: bool) -> void:
		visible = p


func _init() -> void:
	call_deferred("_run")


func _fail(msg: String) -> void:
	push_error("FAIL " + msg)
	quit(1)


func _make_anchor(zone_id: String, at: Vector2) -> Node2D:
	var anchor: Node2D = ZoneAnchorScript.new()
	anchor.name = "Anchor_" + zone_id
	anchor.zone_id = zone_id
	var marker := Marker2D.new()
	marker.position = at
	anchor.add_child(marker)
	root.add_child(anchor)
	return anchor


func _run() -> void:
	var perception: Node = root.get_node_or_null("Perception")
	var npcs: Node = root.get_node_or_null("Npcs")
	var zones: Node = root.get_node_or_null("Zones")
	var fact_log: Node = root.get_node_or_null("FactLog")
	var clock: Node = root.get_node_or_null("Clock")
	var save_load: Node = root.get_node_or_null("SaveLoad")
	var community: Node = root.get_node_or_null("Community")
	if perception == null or npcs == null or zones == null or fact_log == null or clock == null or save_load == null:
		_fail("missing autoloads (Perception / Npcs / Zones / FactLog / Clock / SaveLoad)")
		return
	if community:
		community.set_paused(true)
	save_load.clear_save()
	clock.reset_all()
	clock.pause("test")
	fact_log.clear_all()
	perception.clear_cooldowns()
	var sight: float = float(perception.get_sight_radius())
	var hearing: float = float(perception.get_hearing_radius())
	var enclosed_mult: float = float(perception.get_enclosed_hearing_multiplier())
	if sight <= 0.0 or hearing <= sight or enclosed_mult >= 1.0:
		_fail("tuning shape unexpected (sight %s, hearing %s, enclosed x%s)" % [sight, hearing, enclosed_mult])
		return

	# Two loaded NPCs: Pell in Glowbeds (open), Rook in Wickwork (enclosed).
	var glow_anchor := _make_anchor("glowbeds", Vector2(0, 0))
	var wick_anchor := _make_anchor("wickwork", Vector2(2000, 0))
	var pell := FakeBody.new()
	pell.name = "FakePell"
	root.add_child(pell)
	var rook := FakeBody.new()
	rook.name = "FakeRook"
	root.add_child(rook)
	npcs.register_agent(&"pell", pell)
	npcs.register_agent(&"rook", rook)
	await process_frame
	await process_frame
	if not bool(npcs.is_agent_loaded(&"pell")) or not bool(npcs.is_agent_loaded(&"rook")) or pell.global_position != Vector2(0, 0):
		_fail("fake bodies not placed/loaded by their schedules (pell at %s)" % pell.global_position)
		return
	var eye_y := -24.0  # bodies look from ~head height

	# --- 1. In sight range, clear line of sight, facing: exactly one fact,
	# tagged with that NPC. ---
	pell.facing = 1.0
	var seen: Array[StringName] = perception.flag_witnessable("t1", Vector2(100, eye_y), &"excavated_restricted_wall", {"cell": [1, 2]})
	var facts: Array = fact_log.get_by_type(&"excavated_restricted_wall")
	if seen != [&"pell"] or facts.size() != 1:
		_fail("expected exactly one sight fact by pell, got %s / %d facts" % [seen, facts.size()])
		return
	var fact: Dictionary = facts[0]
	var ctx: Dictionary = fact["context"]
	if (fact["witnesses"] as Array) != ["pell"] or str(ctx.get("sense", "")) != "sight" or fact["location"] != &"glowbeds" or str(ctx.get("source_id", "")) != "t1" or int((ctx.get("cell", []) as Array)[1]) != 2:
		_fail("fact shape wrong: %s" % [fact])
		return
	print("PASS a witnessed restricted action logs exactly one fact tagged with the witnessing NPC")

	# --- 2. Nobody loaded nearby: the check runs, finds nothing, writes
	# nothing. ---
	var nobody: Array[StringName] = perception.flag_witnessable("t2", Vector2(9000, 9000), &"excavated_restricted_wall")
	if not nobody.is_empty() or (fact_log.get_by_type(&"excavated_restricted_wall") as Array).size() != 1:
		_fail("an action with nobody nearby produced a fact")
		return
	print("PASS no loaded NPC nearby logs nothing")

	# --- 3. Per-(NPC, source) cooldown: a sustained action re-flagged by
	# the same source logs no duplicate until the cooldown is cleared. ---
	var again: Array[StringName] = perception.flag_witnessable("t1", Vector2(100, eye_y), &"excavated_restricted_wall")
	if not again.is_empty() or (fact_log.get_by_type(&"excavated_restricted_wall") as Array).size() != 1:
		_fail("duplicate fact within the cooldown window: %s" % [again])
		return
	perception.clear_cooldowns("t1")
	var after: Array[StringName] = perception.flag_witnessable("t1", Vector2(100, eye_y), &"excavated_restricted_wall")
	if after != [&"pell"] or (fact_log.get_by_type(&"excavated_restricted_wall") as Array).size() != 2:
		_fail("after losing/regaining, the same NPC should log a fresh fact")
		return
	print("PASS the same NPC logs one fact per sustained action, not one per tick")

	# --- 4. Facing away: no SIGHT witness, but sound still registers within
	# hearing radius; facing away AND out of (enclosed) hearing: nothing. ---
	pell.facing = -1.0
	var heard: Array[StringName] = perception.flag_witnessable("t4", Vector2(100, eye_y), &"excavated_restricted_wall")
	var heard_facts: Array = fact_log.get_by_type(&"excavated_restricted_wall")
	if heard != [&"pell"] or str((heard_facts[-1]["context"] as Dictionary).get("sense", "")) != "sound":
		_fail("NPC facing away should still hear (got %s, sense %s)" % [heard, (heard_facts[-1]["context"] as Dictionary).get("sense", "")])
		return
	# Rook: Wickwork is enclosed, so hearing is hearing * multiplier.
	var rook_hearing: float = float(perception.get_effective_hearing_radius(&"rook"))
	if not is_equal_approx(rook_hearing, hearing * enclosed_mult) or not is_equal_approx(float(perception.get_effective_hearing_radius(&"pell")), hearing):
		_fail("enclosed zone did not shrink hearing (rook %s, pell %s)" % [rook_hearing, perception.get_effective_hearing_radius(&"pell")])
		return
	var d := (rook_hearing + sight) * 0.5  # inside sight, outside enclosed hearing
	rook.facing = -1.0
	var rook_away: Array[StringName] = perception.flag_witnessable("t4b", rook.global_position + Vector2(d, eye_y), &"excavated_restricted_wall")
	if not rook_away.is_empty():
		_fail("Rook facing away and beyond enclosed hearing still witnessed: %s" % [rook_away])
		return
	rook.facing = 1.0
	var rook_toward: Array[StringName] = perception.flag_witnessable("t4c", rook.global_position + Vector2(d, eye_y), &"excavated_restricted_wall")
	if rook_toward != [&"rook"] or str(((fact_log.get_by_type(&"excavated_restricted_wall") as Array)[-1]["context"] as Dictionary).get("sense", "")) != "sight":
		_fail("Rook facing toward the action at sight range should see it: %s" % [rook_toward])
		return
	# The same distance in Pell's OPEN zone is heard even facing away.
	var pell_open: Array[StringName] = perception.flag_witnessable("t4d", pell.global_position + Vector2(d, eye_y), &"excavated_restricted_wall")
	if pell_open != [&"pell"] or str(((fact_log.get_by_type(&"excavated_restricted_wall") as Array)[-1]["context"] as Dictionary).get("sense", "")) != "sound":
		_fail("open-zone hearing at the same distance should catch it: %s" % [pell_open])
		return
	print("PASS facing away blocks sight but not sound; an enclosed zone shrinks hearing")

	# --- 5. Line of sight: a wall between NPC and action blocks sight
	# (sound still carries), removing it restores sight. ---
	pell.facing = 1.0
	var wall := StaticBody2D.new()
	wall.collision_layer = 1
	wall.collision_mask = 0
	var wall_shape := CollisionShape2D.new()
	var wall_rect := RectangleShape2D.new()
	wall_rect.size = Vector2(8, 96)
	wall_shape.shape = wall_rect
	wall.add_child(wall_shape)
	wall.global_position = Vector2(50, eye_y)
	root.add_child(wall)
	for _i in range(3):
		await physics_frame
	if bool(perception.has_line_of_sight(Vector2(0, eye_y), Vector2(100, eye_y))):
		_fail("raycast did not see the wall")
		return
	var blocked: Array[StringName] = perception.flag_witnessable("t5", Vector2(100, eye_y), &"excavated_restricted_wall")
	if blocked != [&"pell"] or str(((fact_log.get_by_type(&"excavated_restricted_wall") as Array)[-1]["context"] as Dictionary).get("sense", "")) != "sound":
		_fail("with a wall in the way the witness should be by sound only: %s" % [blocked])
		return
	wall.queue_free()
	for _i in range(3):
		await physics_frame
	var clear: Array[StringName] = perception.flag_witnessable("t5b", Vector2(100, eye_y), &"excavated_restricted_wall")
	if clear != [&"pell"] or str(((fact_log.get_by_type(&"excavated_restricted_wall") as Array)[-1]["context"] as Dictionary).get("sense", "")) != "sight":
		_fail("with the wall gone the witness should be by sight: %s" % [clear])
		return
	print("PASS a wall blocks sight (sound still carries); clear line of sight restores it")

	# --- 6. Mid-hold arrival: a sustained action begun with nobody nearby
	# stays unwitnessed until an interval re-check finds someone who
	# arrived. ---
	var hold_pos := Vector2(5000, eye_y)
	var start: Array[StringName] = perception.flag_witnessable("hold1", hold_pos, &"theft_witnessed")
	if not start.is_empty():
		_fail("hold started with nobody nearby was witnessed")
		return
	pell.global_position = Vector2(4900, 0)  # walks in mid-hold
	pell.facing = 1.0
	var tick: Array[StringName] = perception.flag_witnessable("hold1", hold_pos, &"theft_witnessed")
	if tick != [&"pell"] or (fact_log.get_by_type(&"theft_witnessed") as Array).size() != 1:
		_fail("interval re-check did not catch the NPC who arrived mid-hold: %s" % [tick])
		return
	print("PASS a held action stays unwitnessed until an interval re-check finds someone newly in range")

	# --- 7. An off-screen NPC never perceives. ---
	zones.unregister_loaded_zone("glowbeds")
	await process_frame
	if bool(npcs.is_agent_loaded(&"pell")):
		_fail("pell should be off-screen once Glowbeds unloads")
		return
	var offscreen: Array[StringName] = perception.flag_witnessable("t7", Vector2(4900, eye_y), &"excavated_restricted_wall")
	if not offscreen.is_empty():
		_fail("an off-screen NPC ran a live perception check")
		return
	print("PASS off-screen NPCs never perceive")

	# --- 8. QUARANTINED (2026-09-18): the "real path" section covered a real
	# Firmament dig in main.tscn witnessed by the real Pell (Hollow/NPCs/Pell)
	# beside Glowbeds' idle point (Hollow/Zones/Glowbeds/Idle1), plus proof an
	# ordinary civic dig is never flagged. main.tscn's Hollow subtree was
	# deleted for a canon-grounded rebuild (docs/hollow-level-authoring.md).
	# This pass only rebuilds Home Court + Bottom-West Dig Front; Glowbeds and
	# its NPC are a later phase. Restore this test's real assertions once
	# Glowbeds is rebuilt — tracked in docs/priority-roadmap.md, not
	# forgotten.
	npcs.unregister_agent(&"pell")
	npcs.unregister_agent(&"rook")
	pell.queue_free()
	rook.queue_free()
	glow_anchor.queue_free()
	wick_anchor.queue_free()
	await process_frame

	fact_log.clear_all()
	perception.clear_cooldowns()
	save_load.clear_save()
	clock.reset_all()
	print("PERCEPTION_TESTS_PASSED")
	quit(0)
