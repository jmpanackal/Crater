extends SceneTree
## Ladder UX on a Hollow ladder (Wickwork's LAD_WK5): mount, dismount, airborne grab.


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var scene: Node = (load("res://main.tscn") as PackedScene).instantiate()
	root.add_child(scene)
	await process_frame
	await process_frame

	var player: CharacterBody2D = scene.get_node_or_null("Player") as CharacterBody2D
	var ladder: Area2D = scene.get_node_or_null("Hollow/Structures/LAD_WK5") as Area2D
	if player == null or ladder == null:
		push_error("FAIL Player / LAD_WK5 missing")
		quit(1)
		return
	var open_x: float = -640.0
	var ladder_x: float = open_x + (HollowLayout.LADDER_OPENING - HollowLayout.LADDER_WIDTH) * 0.5
	var top_y: float = HollowLayout.WICK_Y
	var bottom_y: float = HollowLayout.WICK_LOWER_Y

	if str(ladder.get("hint_text")).to_lower().find("w/s") < 0:
		push_error("FAIL ladder hint missing W/S climb prompt")
		quit(1)
		return
	if absf(ladder.deck_top_y() - top_y) > 1.0 or absf(ladder.deck_bottom_y() - bottom_y) > 1.0:
		push_error("FAIL LAD_WK5 should span Wickwork street to the lower repair bays")
		quit(1)
		return
	print("PASS ladder prompt and span")

	var stand_bottom := Vector2(ladder_x, bottom_y - player.BODY_HEIGHT)
	player.global_position = stand_bottom
	player.velocity = Vector2.ZERO
	player.enter_climb_zone(ladder)
	for _i in range(4):
		await physics_frame
	Input.action_press("ui_up")
	for _i in range(3):
		await physics_frame
	if not player.is_climbing():
		push_error("FAIL fresh W press did not mount the ladder")
		Input.action_release("ui_up")
		quit(1)
		return
	Input.action_release("ui_up")
	for _i in range(4):
		await physics_frame
	player._stop_climbing(false)
	player.exit_climb_zone(ladder)
	player.collision_mask = player.WORLD_COLLISION_MASK
	player.global_position = stand_bottom
	player.velocity = Vector2.ZERO
	for _i in range(6):
		await physics_frame
	Input.action_press("ui_up")
	await physics_frame
	await physics_frame
	player.enter_climb_zone(ladder)
	for _i in range(8):
		await physics_frame
	if player.is_climbing():
		push_error("FAIL held dig-aim W sticky-mounted on floor re-enter")
		Input.action_release("ui_up")
		quit(1)
		return
	Input.action_release("ui_up")
	print("PASS floor mount needs fresh W/S (no sticky held-W grab)")

	# Auto-grab only near the shaft top (the street's lip).
	player.exit_climb_zone(ladder)
	player._climbing = false
	player.collision_mask = player.WORLD_COLLISION_MASK
	player.global_position = Vector2(ladder_x, top_y - player.BODY_HEIGHT + 8.0)
	player.velocity = Vector2(0.0, 120.0)
	player.enter_climb_zone(ladder)
	for _i in range(8):
		await physics_frame
		if player.is_climbing():
			break
	if not player.is_climbing():
		push_error("FAIL airborne ladder overlap did not auto-grab at the street lip")
		quit(1)
		return
	print("PASS airborne climb-zone overlap auto-grabs")

	Input.action_press("ui_up")
	var landed := false
	for _i in range(300):
		await physics_frame
		if (
			player.is_on_floor()
			and not player.is_climbing()
			and absf(player.global_position.y - (top_y - player.BODY_HEIGHT)) < 4.0
		):
			landed = true
			break
	Input.action_release("ui_up")
	for _i in range(8):
		await physics_frame
	if not landed:
		push_error("FAIL climb-up did not land on the street deck (pos=%s)" % player.global_position)
		quit(1)
		return
	print("PASS climb-up lands straight on the deck (one-way decks: no hatch to land beside)")

	print("ALL TESTS PASSED")
	quit(0)
