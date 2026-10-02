extends SceneTree
## Build Bible Spec 13 (Hauling + Tether + Caches) acceptance tests.
##
## Not covered here, and why:
## - Tether physics / snag handling — spike-owned per the spec's own
##   header. The trailing bundle is a readable placeholder; only the API
##   contract around it is asserted.
## - Ramps and sprinting as strenuous-while-loaded: the prototype has no
##   distinct ramp traversal and no sprint yet (see player.gd's
##   _pay_strenuous_if_loaded()); jumps and ladder grabs are the concrete
##   strenuous traversals today.


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var hauling: Node = root.get_node_or_null("Hauling")
	var stamina: Node = root.get_node_or_null("Stamina")
	var storage: Node = root.get_node_or_null("Storage")
	var save_load: Node = root.get_node_or_null("SaveLoad")
	var community: Node = root.get_node_or_null("Community")
	if hauling == null or stamina == null or storage == null or save_load == null:
		push_error("FAIL missing autoloads (Hauling / Stamina / Storage / SaveLoad)")
		quit(1)
		return
	if community:
		community.set_paused(true)
		if "skip_lie_prompt" in community:
			community.skip_lie_prompt = true
	Input.action_release("interact")
	save_load.clear_save()
	hauling.reset_all()
	storage.reset_all()
	stamina.reset_all()
	var per_unit: float = float(hauling.get_block_per_unit())
	var capacity: int = int(hauling.get_bundle_capacity())

	# --- 1. Picking up a bundle blocks the correct stamina amount; depositing
	# releases exactly that block and no other. ---
	stamina.request_block(stamina.SOURCE_RIG_STRAIN, 5.0)
	if not bool(hauling.attach(&"sutral", 2)):
		push_error("FAIL attach refused a valid 2-unit load")
		quit(1)
		return
	if not bool(hauling.is_loaded()) or not is_equal_approx(float(stamina.get_block(stamina.SOURCE_HAULING)), 2.0 * per_unit):
		push_error("FAIL hauling block should be 2 x per-unit (%s), got %s" % [2.0 * per_unit, stamina.get_block(stamina.SOURCE_HAULING)])
		quit(1)
		return
	if not is_equal_approx(float(stamina.get_total_blocked()), 5.0 + 2.0 * per_unit):
		push_error("FAIL rig_strain block was disturbed by hauling")
		quit(1)
		return
	var mult: float = float(hauling.get_movement_speed_multiplier())
	if mult >= 1.0 or mult <= 0.0:
		push_error("FAIL loaded speed multiplier should be between 0 and 1, got %s" % mult)
		quit(1)
		return
	if not bool(hauling.deposit_at_storage()):
		push_error("FAIL deposit_at_storage refused")
		quit(1)
		return
	if bool(hauling.is_loaded()) or float(stamina.get_block(stamina.SOURCE_HAULING)) != 0.0:
		push_error("FAIL deposit did not release the hauling block")
		quit(1)
		return
	if not is_equal_approx(float(stamina.get_block(stamina.SOURCE_RIG_STRAIN)), 5.0):
		push_error("FAIL deposit released a block that wasn't hauling's")
		quit(1)
		return
	if int(storage.get_material_count(&"sutral")) != 2 or not is_equal_approx(float(hauling.get_movement_speed_multiplier()), 1.0):
		push_error("FAIL deposit did not store the load / restore full speed")
		quit(1)
		return
	stamina.release_block(stamina.SOURCE_RIG_STRAIN)
	print("PASS picking up blocks the right stamina; depositing releases exactly that block and stores the load")

	# --- 2. One bundle, one type, up to capacity (G13). ---
	if not bool(hauling.attach(&"sutral", 1)):
		push_error("FAIL attach 1 refused")
		quit(1)
		return
	if bool(hauling.can_attach(&"ravelstone", 1)) or bool(hauling.attach(&"ravelstone", 1)):
		push_error("FAIL a second Material type was accepted into the one bundle")
		quit(1)
		return
	if bool(hauling.attach(&"sutral", capacity)):
		push_error("FAIL over-capacity attach was accepted")
		quit(1)
		return
	if not bool(hauling.attach(&"sutral", capacity - 1)) or int(hauling.get_load()["amount"]) != capacity:
		push_error("FAIL filling to exactly capacity failed")
		quit(1)
		return
	if bool(hauling.can_attach(&"sutral", 1)) or bool(hauling.attach(&"sporemeal", 1)):
		push_error("FAIL full bundle / retired Material name was accepted")
		quit(1)
		return
	hauling.deposit_at_storage()
	print("PASS one bundle, one type, up to capacity; retired names refused")

	# --- 3. Jumps and ladder grabs are strenuous exactly while loaded. ---
	var scene: Node = (load("res://main.tscn") as PackedScene).instantiate()
	root.add_child(scene)
	await process_frame
	await process_frame
	var player: CharacterBody2D = scene.get_node("Player") as CharacterBody2D
	var terrain: TerrainLayer = scene.get_node("Terrain") as TerrainLayer
	if player == null or terrain == null:
		push_error("FAIL Player/Terrain missing from main scene")
		quit(1)
		return
	var stand: Vector2 = HollowLayout.safe_stand_points()[0]
	player.global_position = stand
	player.velocity = Vector2.ZERO
	for _i in range(8):
		await physics_frame
	var cost: float = float(hauling.get_strenuous_action_cost())
	# Unloaded: a jump costs nothing.
	stamina.reset_all()
	var before_free: float = float(stamina.get_current())
	player.debug_set_coyote(player.COYOTE_TIME)
	player.debug_set_jump_buffer(player.JUMP_BUFFER)
	await physics_frame
	if player.velocity.y >= -50.0 or float(stamina.get_current()) < before_free - 0.5:
		push_error("FAIL unloaded jump either didn't fire or cost stamina (%s -> %s)" % [before_free, stamina.get_current()])
		quit(1)
		return
	player.global_position = stand
	player.velocity = Vector2.ZERO
	for _i in range(10):
		await physics_frame
	# Loaded: the same jump spends the strenuous cost.
	hauling.attach(&"sutral", 1)
	stamina.reset_all()
	var before_loaded: float = float(stamina.get_current())
	player.debug_set_coyote(player.COYOTE_TIME)
	player.debug_set_jump_buffer(player.JUMP_BUFFER)
	await physics_frame
	if player.velocity.y >= -50.0:
		push_error("FAIL loaded jump did not fire (should still happen, just cost stamina)")
		quit(1)
		return
	if float(stamina.get_current()) > before_loaded - cost * 0.5:
		push_error("FAIL loaded jump did not spend stamina (%s -> %s, cost %s)" % [before_loaded, stamina.get_current(), cost])
		quit(1)
		return
	player.global_position = stand
	player.velocity = Vector2.ZERO
	for _i in range(10):
		await physics_frame
	print("PASS jumps are strenuous exactly while a bundle is attached")

	# QUARANTINED (2026-09-18): "ladder grabs are strenuous exactly while
	# loaded" (loaded grab spends once; unloaded grab is free) drove
	# Hollow/LadderCistern's climb zone via HollowLayout.LADDER_CISTERN_OPEN_X
	# / LOWER_WORK_Y. main.tscn's Hollow subtree was deleted for a
	# canon-grounded rebuild (docs/hollow-level-authoring.md). This pass only
	# rebuilds Home Court + Bottom-West Dig Front; the Cistern ladder is a
	# later phase. Restore this test's real assertions once the Cistern
	# ladder is rebuilt — tracked in docs/priority-roadmap.md, not forgotten.
	hauling.deposit_at_storage()
	player.collision_mask = 1
	stamina.reset_all()

	# --- 4. Caches: a valid frontier spot works; Hollow civic space and
	# un-dug rock fail cleanly with a reason; the cache survives a real
	# save/load round-trip and can be picked back up. ---
	player.global_position = stand
	player.velocity = Vector2.ZERO
	for _i in range(5):
		await physics_frame
	terrain.reset_all()
	var cache_cell := Vector2i(586, 150)
	terrain.dig(terrain.to_global(terrain.map_to_local(cache_cell + Vector2i.UP)), Vector2i.DOWN)
	var cache_world: Vector2 = terrain.to_global(terrain.map_to_local(cache_cell))
	hauling.attach(&"ravelstone", 3)
	var civic: Dictionary = hauling.cache_at(Vector2(200.0, HollowLayout.WICK_Y))
	if bool(civic["success"]) or str(civic["reason"]) != "hollow_civic_space" or not bool(hauling.is_loaded()):
		push_error("FAIL caching inside the Hollow's civic space was not refused cleanly: %s" % [civic])
		quit(1)
		return
	var rock: Dictionary = hauling.cache_at(terrain.to_global(terrain.map_to_local(Vector2i(586, 155))))
	if bool(rock["success"]) or str(rock["reason"]) != "blocked_by_rock":
		push_error("FAIL caching inside un-dug rock was not refused cleanly: %s" % [rock])
		quit(1)
		return
	var ok: Dictionary = hauling.cache_at(cache_world)
	if not bool(ok["success"]) or bool(hauling.is_loaded()) or float(stamina.get_block(stamina.SOURCE_HAULING)) != 0.0:
		push_error("FAIL caching at a dug frontier cell failed or didn't release the load: %s" % [ok])
		quit(1)
		return
	var uid := int(ok["uid"])
	await process_frame
	var marker: Node = hauling.get_cache_node(uid)
	if marker == null or not marker.has_method("on_interact") or (marker as Node2D).global_position.distance_to(cache_world) > 1.0:
		push_error("FAIL cache marker not placed at the chosen spot")
		quit(1)
		return
	if not str(marker.get_interact_prompt()).contains("Ravelstone"):
		push_error("FAIL cache marker prompt: '%s'" % marker.get_interact_prompt())
		quit(1)
		return
	save_load.clear_save()
	if not save_load.save_game():
		push_error("FAIL save_game")
		quit(1)
		return
	hauling.reset_all()
	await process_frame
	if not (hauling.get_caches() as Array).is_empty() or hauling.get_cache_node(uid) != null:
		push_error("FAIL reset_all did not clear caches before the reload check")
		quit(1)
		return
	if not save_load.load_game():
		push_error("FAIL load_game")
		quit(1)
		return
	await process_frame
	await process_frame
	var restored: Array[Dictionary] = hauling.get_caches()
	if restored.size() != 1 or int(restored[0]["uid"]) != uid or (restored[0]["position"] as Vector2).distance_to(cache_world) > 0.5:
		push_error("FAIL cache record did not persist through save/load: %s" % [restored])
		quit(1)
		return
	var restored_marker: Node = hauling.get_cache_node(uid)
	if restored_marker == null or (restored_marker as Node2D).global_position.distance_to(cache_world) > 1.0:
		push_error("FAIL cache marker was not respawned at the same spot after reload")
		quit(1)
		return
	var picked: Dictionary = hauling.retrieve_cache(uid)
	var load: Dictionary = hauling.get_load()
	if not bool(picked["success"]) or load["material_id"] != &"ravelstone" or int(load["amount"]) != 3:
		push_error("FAIL retrieving the cache did not reload the bundle: %s %s" % [picked, load])
		quit(1)
		return
	await process_frame
	if not (hauling.get_caches() as Array).is_empty() or hauling.get_cache_node(uid) != null:
		push_error("FAIL retrieved cache still exists")
		quit(1)
		return
	print("PASS caches: valid spot works, civic space and rock refused with a reason, survives reload, retrievable")

	# --- 5. Spec 12 seam: extraction is refused, deposit left intact, when
	# the bundle can't carry the find. ---
	var pocket := Vector2i(670, 188)  # sutral x2
	terrain.dig(terrain.to_global(terrain.map_to_local(pocket + Vector2i.UP)), Vector2i.DOWN)
	var pocket_world: Vector2 = terrain.to_global(terrain.map_to_local(pocket))
	if int(terrain.complete_extraction(pocket)) != 0 or terrain.get_deposit_state(pocket_world) != &"intact":
		push_error("FAIL extraction with a Ravelstone bundle towed should be refused and leave the deposit intact")
		quit(1)
		return
	hauling.deposit_at_storage()
	if int(terrain.complete_extraction(pocket)) != 2 or hauling.get_load()["material_id"] != &"sutral" or int(hauling.get_load()["amount"]) != 2:
		push_error("FAIL extraction with an empty bundle should tow 2 Sutral")
		quit(1)
		return
	if terrain.get_deposit_state(pocket_world) != &"depleted":
		push_error("FAIL deposit not depleted after a carried extraction")
		quit(1)
		return
	print("PASS extraction refuses what the bundle can't carry and leaves the deposit intact")

	Input.action_release("interact")
	save_load.clear_save()
	hauling.reset_all()
	storage.reset_all()
	stamina.reset_all()
	print("HAULING_TESTS_PASSED")
	quit(0)
