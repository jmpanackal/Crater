extends SceneTree
## Coyote time, jump buffer, and pit-void soft respawn.


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var community: Node = root.get_node_or_null("Community")
	var save_load: Node = root.get_node_or_null("SaveLoad")
	if community:
		community.set_paused(true)
		if "skip_lie_prompt" in community:
			community.skip_lie_prompt = true
	if save_load:
		save_load.clear_save()

	var scene: Node = (load("res://main.tscn") as PackedScene).instantiate()
	root.add_child(scene)
	await process_frame
	await process_frame

	var player: CharacterBody2D = scene.get_node("Player") as CharacterBody2D
	if player == null:
		push_error("FAIL missing player")
		quit(1)
		return

	# Constants present and in the intended fairness band.
	if absf(player.COYOTE_TIME - 0.10) > 0.001 or absf(player.JUMP_BUFFER - 0.12) > 0.001:
		push_error(
			"FAIL coyote/buffer constants coyote=%s buffer=%s"
			% [player.COYOTE_TIME, player.JUMP_BUFFER]
		)
		quit(1)
		return
	print("PASS coyote/buffer constants")

	# --- Coyote: airborne with grace remaining, buffered jump fires ---
	var stand := HollowLayout.safe_stand_points()[0]
	player.global_position = stand
	player.velocity = Vector2.ZERO
	for _i in range(8):
		await physics_frame
	if not player.is_on_floor():
		push_error("FAIL coyote setup not on floor at %s" % player.global_position)
		quit(1)
		return

	player.global_position.y -= 12.0
	player.velocity = Vector2.ZERO
	player.debug_set_coyote(player.COYOTE_TIME)
	player.debug_set_jump_buffer(player.JUMP_BUFFER)
	await physics_frame
	if player.velocity.y >= -50.0:
		push_error(
			"FAIL coyote jump did not fire (vy=%s coyote=%s)"
			% [player.velocity.y, player.debug_coyote()]
		)
		quit(1)
		return
	print("PASS coyote jump after leaving floor")

	# --- Buffer: press early while falling, consume on land ---
	player.global_position = Vector2(stand.x, stand.y - 100.0)
	player.velocity = Vector2(0, 320)
	player.debug_set_coyote(0.0)
	player.debug_set_jump_buffer(player.JUMP_BUFFER)
	var saw_buffer_jump := false
	for _i in range(45):
		await physics_frame
		if player.velocity.y < -50.0:
			saw_buffer_jump = true
			break
		# Keep buffer alive until we land (simulates holding the early press window).
		if not player.is_on_floor() and player.debug_jump_buffer() <= 0.0:
			player.debug_set_jump_buffer(player.JUMP_BUFFER)
	if not saw_buffer_jump:
		push_error("FAIL jump buffer did not consume on land")
		quit(1)
		return
	print("PASS jump buffer on land")

	# --- Pit void soft respawn ---
	player.global_position = stand
	player.velocity = Vector2.ZERO
	for _i in range(6):
		await physics_frame
	var safe_before := player.global_position

	player.global_position = Vector2(400.0, player.VOID_FALL_Y + 40.0)
	player.velocity = Vector2(0, 500)
	for _i in range(8):
		await physics_frame

	if player.global_position.y >= player.VOID_FALL_Y:
		push_error("FAIL still in void after respawn y=%s" % player.global_position.y)
		quit(1)
		return
	if player.global_position.distance_to(safe_before) > 48.0:
		# Last safe or nearest deck — must be on a known stand.
		var near_deck := false
		for p in HollowLayout.safe_stand_points():
			if player.global_position.distance_to(p) <= 48.0:
				near_deck = true
				break
		if not near_deck:
			push_error("FAIL respawn not on safe deck at %s" % player.global_position)
			quit(1)
			return
	print("PASS pit void soft respawn")

	# Nearest-deck helper sanity.
	var near_cistern := HollowLayout.nearest_safe_stand(Vector2(800, 900))
	if near_cistern.y > HollowLayout.CISTERN_Y:
		push_error("FAIL nearest_safe_stand below cistern: %s" % near_cistern)
		quit(1)
		return
	print("PASS nearest_safe_stand helper")

	print("PLAYER_FEEL_TESTS_PASSED")
	quit(0)
