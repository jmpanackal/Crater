extends SceneTree
## Build Bible Spec 06 (Destructible Terrain + Persistence) acceptance tests.
##
## Not covered here, and why:
## - "Depletion visually matches the locked overlay principle" — the
##   MECHANICAL half (intact -> depleted state transition) is tested below
##   via get_deposit_state(); the actual overlay ART doesn't exist yet
##   (CONTEXT.md already tracks painted depletion overlays as a separate,
##   ongoing art-pipeline item, not a Spec 06 code concern).
## - The persistence REPRESENTATION (per-tile deltas vs. chunk snapshots)
##   is explicitly spike-owned per this spec's own header; save_state()'s
##   dug-cell-delta shape here is a working placeholder proving the
##   contract round-trips, not a claim that question is settled.


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var event_bus: Node = root.get_node_or_null("EventBus")
	var save_load: Node = root.get_node_or_null("SaveLoad")
	if event_bus == null or save_load == null:
		push_error("FAIL missing autoloads (EventBus / SaveLoad)")
		quit(1)
		return

	var terrain := TerrainLayer.new()
	root.add_child(terrain)
	await process_frame
	await process_frame
	terrain.clear()
	terrain.reset_all()

	# dig(position, direction) targets the cell ADJACENT to position (same
	# convention as the existing dig_in_direction()), not position's own
	# cell — origin_cell stays intact; inside_cell (origin + DOWN) is what
	# actually gets dug.
	var origin_cell := Vector2i(TerrainLayer.DIG_START_X + 2, 5)
	var inside_cell := origin_cell + Vector2i.DOWN
	var inside_world := terrain.to_global(terrain.map_to_local(origin_cell))
	var inside_cell_world := terrain.to_global(terrain.map_to_local(inside_cell))
	var outside_world := terrain.to_global(terrain.map_to_local(Vector2i(0, 6)))  # well left of DIG_START_X

	# --- 1. can_dig / dig outside the envelope fails cleanly — no mutation,
	# no crash. ---
	if terrain.can_dig(outside_world):
		push_error("FAIL can_dig reported true outside the authored envelope")
		quit(1)
		return
	var outside_result: Dictionary = terrain.dig(outside_world, Vector2i.DOWN)
	if bool(outside_result["success"]):
		push_error("FAIL dig() succeeded outside the authored envelope")
		quit(1)
		return
	if str(outside_result["reason"]) != "outside_envelope":
		push_error("FAIL dig() outside envelope gave the wrong reason: %s" % outside_result["reason"])
		quit(1)
		return
	print("PASS digging outside the authored envelope fails cleanly, no mutation")

	# --- 2. Digging within the envelope succeeds. ---
	if not terrain.can_dig(inside_world):
		push_error("FAIL can_dig reported false inside the authored envelope")
		quit(1)
		return
	# Ordinary rock is "none" before AND after digging — most rock yields
	# nothing (canon §5). The intact -> depleted transition belongs to real
	# deposits and is Spec 12's test (tests/test_deposits.gd), not this one.
	if terrain.get_deposit_state(inside_cell_world) != &"none":
		push_error("FAIL get_deposit_state expected 'none' for ordinary rock before digging")
		quit(1)
		return
	var inside_result: Dictionary = terrain.dig(inside_world, Vector2i.DOWN)
	if not bool(inside_result["success"]):
		push_error("FAIL dig() failed inside the authored envelope: %s" % inside_result)
		quit(1)
		return
	if terrain.get_deposit_state(inside_cell_world) != &"none":
		push_error("FAIL digging ordinary rock must not invent a deposit")
		quit(1)
		return
	print("PASS digging within the authored envelope succeeds; ordinary rock stays 'none' (no deposit invented)")

	# --- 3. A dig emits exactly one EventBus event, observable with no
	# direct reference to Terrain. ---
	var received: Array[Dictionary] = []
	var listener := func(cell: Vector2i, direction: Vector2i, is_firmament: bool, is_mouth: bool) -> void:
		received.append({"cell": cell, "direction": direction, "firmament": is_firmament, "mouth": is_mouth})
	event_bus.terrain_dug.connect(listener)
	var second_cell := Vector2i(TerrainLayer.DIG_START_X + 3, 6)
	var second_world := terrain.to_global(terrain.map_to_local(second_cell))
	terrain.dig(second_world, Vector2i.DOWN)
	if received.size() != 1:
		push_error("FAIL expected exactly one terrain_dug event, got %d" % received.size())
		quit(1)
		return
	event_bus.terrain_dug.disconnect(listener)
	print("PASS a dig emits exactly one EventBus event, observable with no direct Terrain reference")

	# --- 4. Digging within the envelope persists after save/load, via the
	# real SaveLoad system (register_scene_domain, not a direct call). ---
	save_load.clear_save()
	if not save_load.save_game():
		push_error("FAIL save_game")
		quit(1)
		return
	var dug_before_reload := not terrain.has_tile(inside_cell)
	terrain.reset_all()  # simulate a fresh, undug terrain before reload
	if terrain.has_tile(inside_cell) != true:
		push_error("FAIL reset_all() did not restore the tile before the reload check")
		quit(1)
		return
	if not save_load.load_game():
		push_error("FAIL load_game")
		quit(1)
		return
	if terrain.has_tile(inside_cell) == true or not dug_before_reload:
		push_error("FAIL dug cell did not persist through the real SaveLoad round-trip")
		quit(1)
		return
	print("PASS digging within the envelope persists across a real save/load round-trip")

	save_load.clear_save()
	root.remove_child(terrain)
	terrain.queue_free()
	print("TERRAIN_CONTRACT_TESTS_PASSED")
	quit(0)
