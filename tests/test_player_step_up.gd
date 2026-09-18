extends SceneTree
## Player QOL: walking into a ledge exactly one tile (16px) higher than the
## current stand auto-climbs it, so a single stair riser never needs a jump.
## A taller wall (2+ tiles) must NOT auto-climb — only a genuine single-step
## rise counts. Built on a standalone hollow_terrain.gd rig (not main.tscn's
## opening-route geometry) so this test doesn't drift if that layout changes.


func _init() -> void:
	call_deferred("_run")


func _spawn_player(pos: Vector2) -> CharacterBody2D:
	var player_script := load("res://player.gd")
	var player: CharacterBody2D = player_script.new()
	player.name = "Player"
	player.add_to_group("player")
	player.collision_layer = 1
	player.collision_mask = 1
	var sprite := AnimatedSprite2D.new()
	sprite.name = "AnimatedSprite2D"
	player.add_child(sprite)
	var col := CollisionShape2D.new()
	var shape := RectangleShape2D.new()
	shape.size = Vector2(32, 32)
	col.shape = shape
	col.position = Vector2(16, 16)
	player.add_child(col)
	player.position = pos
	root.add_child(player)
	return player


func _run() -> void:
	var terrain_script := load("res://hollow_terrain.gd")
	var terrain: TileMapLayer = terrain_script.new()
	terrain.name = "StepTerrain"
	root.add_child(terrain)
	await process_frame

	# --- 1. A single 16px riser auto-climbs. ---
	# Lower deck y=96 (x 0-96), then one tile higher (y=80) starting at x=96.
	terrain.paint_floor(0.0, 96.0, 96.0)
	terrain.paint_floor(96.0, 224.0, 80.0)
	await physics_frame

	var player := _spawn_player(Vector2(32.0, 96.0 - 32.0))
	await process_frame
	await process_frame

	Input.action_press("ui_right")
	for _i in range(60):
		await physics_frame
		if player.global_position.x > 110.0 and absf(player.global_position.y - (80.0 - 32.0)) < 4.0:
			break
	Input.action_release("ui_right")
	for _i in range(5):
		await physics_frame

	if absf(player.global_position.y - (80.0 - 32.0)) > 4.0:
		push_error(
			"FAIL a 1-tile riser did not auto-climb (feet-y=%s, expected ~%s)"
			% [player.global_position.y + 32.0, 80.0]
		)
		quit(1)
		return
	print("PASS a single 16px riser auto-climbs without a jump")

	player.queue_free()
	await process_frame

	# --- 2. A taller wall (32px, 2 tiles) does NOT auto-climb — the player
	# stays blocked at the lower deck instead of silently teleporting up a
	# wall that isn't a stair riser. ---
	terrain.paint_floor(224.0, 320.0, 96.0)
	terrain.paint_floor(320.0, 448.0, 64.0) # 32px higher — a wall, not a step
	await physics_frame

	var player2 := _spawn_player(Vector2(256.0, 96.0 - 32.0))
	await process_frame
	await process_frame

	Input.action_press("ui_right")
	for _i in range(60):
		await physics_frame
	Input.action_release("ui_right")
	for _i in range(5):
		await physics_frame

	if absf(player2.global_position.y - (64.0 - 32.0)) < 4.0:
		push_error("FAIL a 2-tile wall auto-climbed — step-up should only handle a single riser")
		quit(1)
		return
	if absf(player2.global_position.y - (96.0 - 32.0)) > 4.0:
		push_error(
			"FAIL player unexpectedly left the lower deck without climbing (feet-y=%s)"
			% [player2.global_position.y + 32.0]
		)
		quit(1)
		return
	print("PASS a 2-tile wall stays a real obstacle, not an auto-climb")

	print("PLAYER_STEP_UP_TESTS_PASSED")
	quit(0)
