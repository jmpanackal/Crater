extends SceneTree
## West stack ladder UX: mount, dismount, and airborne grab.


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var scene: Node = (load("res://main.tscn") as PackedScene).instantiate()
	root.add_child(scene)
	await process_frame
	await process_frame

	var player: CharacterBody2D = scene.get_node_or_null("Player") as CharacterBody2D
	var ladder: Area2D = scene.get_node_or_null("Hollow/LadderWestStack") as Area2D
	if player == null or ladder == null:
		push_error("FAIL Player / LadderWestStack missing")
		quit(1)
		return

	if str(ladder.get("hint_text")).to_lower().find("w/s") < 0:
		push_error("FAIL West stack hint missing W/S climb prompt")
		quit(1)
		return
	if scene.get_node_or_null("Hollow/LadderChamber") != null:
		push_error("FAIL LadderChamber leftover must be removed")
		quit(1)
		return
	if int(ladder.get("upper_land_side")) >= 0:
		push_error(
			"FAIL West stack upper_land_side=%s must prefer west landing (-1)"
			% ladder.get("upper_land_side")
		)
		quit(1)
		return
	print("PASS ladder prompts and west stack land side")

	var stand_bottom := Vector2(
		HollowLayout.LADDER_WEST_X,
		HollowLayout.WEST_LW_UPPER_Y - player.BODY_HEIGHT
	)
	player.global_position = stand_bottom
	player.velocity = Vector2.ZERO
	player.enter_climb_zone(ladder)
	for _i in range(4):
		await physics_frame
	Input.action_press("ui_up")
	for _i in range(3):
		await physics_frame
	if not player.is_climbing():
		push_error("FAIL fresh W press did not mount west stack ladder")
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

	# Auto-grab only near shaft top (Ashram upper lip).
	player.exit_climb_zone(ladder)
	player._climbing = false
	player.collision_mask = player.WORLD_COLLISION_MASK
	player.global_position = Vector2(
		HollowLayout.LADDER_WEST_X,
		HollowLayout.WEST_ASHRAM_UPPER_Y - player.BODY_HEIGHT + 8.0
	)
	player.velocity = Vector2(0.0, 120.0)
	player.enter_climb_zone(ladder)
	for _i in range(8):
		await physics_frame
		if player.is_climbing():
			break
	if not player.is_climbing():
		push_error("FAIL airborne ladder overlap did not auto-grab at Ashram lip")
		quit(1)
		return
	print("PASS airborne climb-zone overlap auto-grabs")

	Input.action_press("ui_up")
	var landed_west := false
	for _i in range(200):
		await physics_frame
		if (
			player.is_on_floor()
			and not player.is_climbing()
			and absf(player.global_position.y - (HollowLayout.WEST_ASHRAM_UPPER_Y - player.BODY_HEIGHT)) < 4.0
		):
			landed_west = player.global_position.x < HollowLayout.LADDER_WEST_OPEN_X
			break
	Input.action_release("ui_up")
	for _i in range(8):
		await physics_frame
	if not landed_west:
		push_error(
			"FAIL climb-up did not land west of shaft (pos=%s open=%s)"
			% [player.global_position, HollowLayout.LADDER_WEST_OPEN_X]
		)
		quit(1)
		return
	print("PASS climb-up lands on west Ashram deck")

	# Mid Allotments share the same shaft — can step off mid-climb.
	player.global_position = Vector2(
		HollowLayout.LADDER_WEST_X,
		HollowLayout.MID_ALLOT_Y - player.BODY_HEIGHT - 8.0
	)
	player.velocity = Vector2.ZERO
	player.enter_climb_zone(ladder)
	Input.action_press("ui_right")
	Input.action_press("ui_up")
	var stepped_mid := false
	for _i in range(400):
		await physics_frame
		if (
			player.is_on_floor()
			and not player.is_climbing()
			and absf(player.global_position.y - (HollowLayout.MID_ALLOT_Y - player.BODY_HEIGHT)) < 6.0
			and player.global_position.x >= HollowLayout.LADDER_WEST_OPEN_X + HollowLayout.LADDER_OPENING - 8.0
		):
			stepped_mid = true
			break
	Input.action_release("ui_right")
	Input.action_release("ui_up")
	if not stepped_mid:
		push_error("FAIL could not step off west shaft onto Mid Allotments")
		quit(1)
		return
	print("PASS Mid Allotments shares the west stack shaft")

	# Ashram via continuing up from Wickwork.
	player.global_position = Vector2(
		HollowLayout.LADDER_WEST_X,
		HollowLayout.WICK_Y - player.BODY_HEIGHT
	)
	player.velocity = Vector2.ZERO
	player.enter_climb_zone(ladder)
	Input.action_press("ui_up")
	var climbed_ashram := false
	for _i in range(2000):
		await physics_frame
		if (
			player.is_on_floor()
			and not player.is_climbing()
			and absf(player.global_position.y - (HollowLayout.WEST_ASHRAM_UPPER_Y - player.BODY_HEIGHT)) < 6.0
		):
			climbed_ashram = true
			break
	Input.action_release("ui_up")
	if not climbed_ashram:
		push_error("FAIL could not climb west stack to Ashram Heights")
		quit(1)
		return
	print("PASS west stack reaches Ashram Heights")

	print("ALL TESTS PASSED")
	quit(0)
