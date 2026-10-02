extends SceneTree
## Build Bible Spec 32 (Firmament Progression) acceptance tests — against
## the AI-drafted spec, pending USER review.
##
## Not covered here, and why:
## - Firmament hardness / specialised Gear requirements — canon leaves
##   them open; digging is not gated by this system.
## - The Act 1 ending beat itself — story content keyed off the
##   firmament_breached flag.


func _init() -> void:
	call_deferred("_run")


func _fail(msg: String) -> void:
	push_error("FAIL " + msg)
	quit(1)


func _run() -> void:
	var firmament: Node = root.get_node_or_null("Firmament")
	var story: Node = root.get_node_or_null("Story")
	var homes: Node = root.get_node_or_null("Homes")
	var bus: Node = root.get_node_or_null("EventBus")
	var fact_log: Node = root.get_node_or_null("FactLog")
	var save_load: Node = root.get_node_or_null("SaveLoad")
	var community: Node = root.get_node_or_null("Community")
	if firmament == null or story == null or homes == null or bus == null or fact_log == null or save_load == null:
		_fail("missing autoloads")
		return
	if community:
		community.set_paused(true)
	save_load.clear_save()
	for n in [firmament, story, homes]:
		n.reset_all()
	fact_log.clear_all()
	var changes: Array = []
	bus.firmament_stage_changed.connect(func(old: StringName, new: StringName) -> void: changes.append([old, new]))

	# --- 1. Inaccessible at start; foreshadowed by the authored flag;
	# digs before Ashram count but don't advance past Foreshadowed. ---
	if firmament.get_stage() != &"inaccessible":
		_fail("stage should start inaccessible (%s)" % firmament.get_stage())
		return
	var terrain := TerrainLayer.new()
	root.add_child(terrain)
	await process_frame
	await process_frame
	terrain.reset_all()
	terrain.dig(terrain.to_global(terrain.map_to_local(Vector2i(70, 9))), Vector2i.DOWN)  # a Firmament cell
	if int(firmament.get_progress()["cells_dug"]) != 1 or firmament.get_stage() != &"inaccessible":
		_fail("a curiosity dig should count but not advance the stage (%s, %s)" % [firmament.get_progress(), firmament.get_stage()])
		return
	story.set_flag(&"firmament_foreshadowed", "A Pulse Binder mentions what lies above the Heights")
	if firmament.get_stage() != &"foreshadowed" or changes.size() != 1:
		_fail("the foreshadow flag should make it Foreshadowed: %s %s" % [firmament.get_stage(), changes])
		return
	terrain.dig(terrain.to_global(terrain.map_to_local(Vector2i(72, 9))), Vector2i.DOWN)
	if firmament.get_stage() != &"foreshadowed":
		_fail("digging before Ashram must not start excavation")
		return
	print("PASS Inaccessible -> Foreshadowed by the story; pre-Ashram digs count but don't advance the stage")

	# --- 2. Ashram makes it Reachable; the next dig starts excavation;
	# thresholds give Partial breach then Breached (+ the story flag);
	# the stage is monotonic. ---
	homes.grant_residence(&"ashram_heights", "test")
	if firmament.get_stage() != &"excavation_started":
		# Two cells were already dug — excavation is already under way once reachable.
		_fail("with Ashram and cells dug the stage should be excavation_started (%s)" % firmament.get_stage())
		return
	var partial: int = int(firmament.get_progress()["partial_threshold"])
	var breach: int = int(firmament.get_progress()["breach_threshold"])
	var x := 74
	while int(firmament.get_progress()["cells_dug"]) < partial:
		terrain.dig(terrain.to_global(terrain.map_to_local(Vector2i(x, 9))), Vector2i.DOWN)
		x += 1
		if x >= terrain.DIG_END_X:
			x = terrain.DIG_START_X
			terrain.dig(terrain.to_global(terrain.map_to_local(Vector2i(x, 11))), Vector2i.DOWN)
	if firmament.get_stage() != &"partial_breach":
		_fail("reaching the partial threshold should give partial_breach (%s at %d cells)" % [firmament.get_stage(), firmament.get_progress()["cells_dug"]])
		return
	var row := 12
	while int(firmament.get_progress()["cells_dug"]) < breach:
		for col in range(terrain.DIG_START_X, terrain.DIG_END_X):
			if int(firmament.get_progress()["cells_dug"]) >= breach:
				break
			terrain.dig(terrain.to_global(terrain.map_to_local(Vector2i(col, row - 1))), Vector2i.DOWN)
		row += 1
	if firmament.get_stage() != &"breached" or not bool(story.has_flag(&"firmament_breached")):
		_fail("reaching the breach threshold should give breached + the story flag (%s)" % firmament.get_stage())
		return
	# Four rises: -> foreshadowed, -> excavation_started (Ashram with cells
	# already dug skips straight past reachable), -> partial, -> breached.
	if (fact_log.get_by_type(&"firmament_stage") as Array).size() != 4 or changes.size() != 4:
		_fail("each stage rise should be one fact + one event (%d facts, %d events)" % [(fact_log.get_by_type(&"firmament_stage") as Array).size(), changes.size()])
		return
	homes.reset_all()  # losing the residence never un-breaches
	if firmament.get_stage() != &"breached":
		_fail("the stage must never regress")
		return
	print("PASS Ashram makes it Reachable; digs start, partially breach and breach the Firmament, setting the story flag; monotonic")

	# --- 3. Persistence: stage + progress round-trip; a load never
	# lowers the stage. ---
	var pre: Dictionary = firmament.save_state()
	save_load.clear_save()
	if not save_load.save_game():
		_fail("save_game")
		return
	firmament.reset_all()
	if not save_load.load_game():
		_fail("load_game")
		return
	if firmament.save_state() != pre or firmament.get_stage() != &"breached":
		_fail("Firmament did not round-trip: %s vs %s" % [pre, firmament.save_state()])
		return
	print("PASS Firmament stage and progress persist")

	terrain.queue_free()
	save_load.clear_save()
	for n in [firmament, story, homes]:
		n.reset_all()
	fact_log.clear_all()
	await process_frame
	print("FIRMAMENT_TESTS_PASSED")
	quit(0)
