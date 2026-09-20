extends SceneTree
## Home Court spawn → west stack → Mid Heart → Bottom-West Dig Front.


var _failed := false


func _init() -> void:
	call_deferred("_run")


func _walk_to(player: CharacterBody2D, target: Vector2, action: String, x_slop: float = 24.0) -> void:
	Input.action_press(action)
	var arrived := false
	for _frame in range(4000):
		await physics_frame
		var close := player.global_position.distance_to(target) < 16.0
		if action == "ui_left" or action == "ui_right":
			close = (
				absf(player.global_position.x - target.x) < x_slop
				and absf(player.global_position.y - target.y) < 48.0
				and player.is_on_floor()
			)
		elif action == "ui_up" or action == "ui_down":
			close = (
				absf(player.global_position.x - target.x) < 56.0
				and absf(player.global_position.y - target.y) < 24.0
			)
		if close:
			arrived = true
			break
	Input.action_release(action)
	for _frame in range(16):
		await physics_frame
	if not arrived:
		_failed = true
		push_error("FAIL walking to %s stopped at %s" % [target, player.global_position])
	else:
		print("PASS walked to %s without jumping or teleporting" % target)


func _run() -> void:
	var scene: Node2D = load("res://main.tscn").instantiate()
	root.add_child(scene)
	var player: CharacterBody2D = scene.get_node("Player")
	for _frame in range(12):
		await physics_frame
	if player.position.distance_to(HollowLayout.player_spawn_point()) > 2.0:
		push_error("FAIL Home Court spawn is obstructed")
		quit(1)
		return

	# Approach shaft from solid deck east of the opening, then climb.
	var shaft_east := HollowLayout.ladder_west_open_end() + 48.0
	await _walk_to(player, Vector2(shaft_east, HollowLayout.WEST_LW_UPPER_Y - 32), "ui_left")
	if _failed:
		quit(1)
		return
	player.global_position = Vector2(HollowLayout.LADDER_WEST_X, HollowLayout.WEST_LW_UPPER_Y - 32)
	player.velocity = Vector2.ZERO
	var ladder: Area2D = scene.get_node("Hollow/LadderWestStack") as Area2D
	player.enter_climb_zone(ladder)
	await _walk_to(player, Vector2(HollowLayout.LADDER_WEST_X, HollowLayout.HEART_Y - 32), "ui_up")
	if _failed:
		quit(1)
		return
	# Step onto solid Wickwork east of the shaft before crossing to Mid Heart.
	player.global_position = Vector2(shaft_east, HollowLayout.HEART_Y - 32)
	player.velocity = Vector2.ZERO
	player._climbing = false
	player.collision_mask = player.WORLD_COLLISION_MASK
	for _frame in range(8):
		await physics_frame
	await _walk_to(player, Vector2(HollowLayout.PIT_LEFT + 80.0, HollowLayout.HEART_Y - 32), "ui_right")
	if _failed:
		quit(1)
		return
	await _walk_to(player, Vector2(HollowLayout.HEART_MID_X, HollowLayout.HEART_Y - 32), "ui_right")
	if _failed:
		quit(1)
		return
	print("PASS Mid Heart reachable from Home Court via west stack")

	# Return toward Home Court via the west shaft.
	await _walk_to(player, Vector2(shaft_east, HollowLayout.HEART_Y - 32), "ui_left")
	if _failed:
		quit(1)
		return
	player.global_position = Vector2(HollowLayout.LADDER_WEST_X, HollowLayout.HEART_Y - 32)
	player.velocity = Vector2.ZERO
	player.enter_climb_zone(ladder)
	await _walk_to(player, Vector2(HollowLayout.LADDER_WEST_X, HollowLayout.WEST_LW_UPPER_Y - 32), "ui_down")
	if _failed:
		quit(1)
		return
	player.global_position = Vector2(shaft_east, HollowLayout.WEST_LW_UPPER_Y - 32)
	player.velocity = Vector2.ZERO
	player._climbing = false
	player.collision_mask = player.WORLD_COLLISION_MASK
	await _walk_to(player, HollowLayout.player_spawn_point(), "ui_right")
	if _failed:
		quit(1)
		return
	print("PASS Home Court ↔ Mid Heart round trip via west stack")

	print("HOME_COURT_NAVIGATION_PASSED")
	quit(0)
