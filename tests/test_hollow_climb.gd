extends SceneTree
## Worker Return + shared ladder UX: mount, dismount, and airborne grab.


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var scene: Node = (load("res://main.tscn") as PackedScene).instantiate()
	root.add_child(scene)
	await process_frame
	await process_frame

	var player: CharacterBody2D = scene.get_node_or_null("Player") as CharacterBody2D
	var ladder: Area2D = scene.get_node_or_null("Hollow/LadderWorkerReturn") as Area2D
	var chamber: Area2D = scene.get_node_or_null("Hollow/LadderChamber") as Area2D
	if player == null or ladder == null:
		push_error("FAIL Player / LadderWorkerReturn missing")
		quit(1)
		return

	# Shared ladder contract: every climb zone uses the same prompt + west/east land bias.
	if str(ladder.get("hint_text")).to_lower().find("w/s") < 0:
		push_error("FAIL Worker Return hint missing W/S climb prompt")
		quit(1)
		return
	if chamber != null and str(chamber.get("hint_text")).to_lower().find("w/s") < 0:
		push_error("FAIL Chamber ladder hint missing W/S climb prompt")
		quit(1)
		return
	if int(ladder.get("upper_land_side")) >= 0:
		push_error(
			"FAIL Worker Return upper_land_side=%s must prefer west spur (-1)"
			% ladder.get("upper_land_side")
		)
		quit(1)
		return
	print("PASS ladder prompts and Worker Return land side")

	# Floor mount requires a fresh W/S press — held dig-aim W must not sticky-grab.
	var stand_bottom := Vector2(
		HollowLayout.LADDER_RETURN_X,
		HollowLayout.LOWER_WORK_Y - player.BODY_HEIGHT
	)
	player.global_position = stand_bottom
	player.velocity = Vector2.ZERO
	player.enter_climb_zone(ladder)
	for _i in range(4):
		await physics_frame
	Input.action_press("ui_up")
	for _i in range(3):
		await physics_frame
	# Simulate "already held" by clearing just_pressed semantics: release and...
	# First frames after press SHOULD mount. Verify mount happened, then stop.
	if not player.is_climbing():
		push_error("FAIL fresh W press did not mount Worker Return ladder")
		Input.action_release("ui_up")
		quit(1)
		return
	Input.action_release("ui_up")
	for _i in range(4):
		await physics_frame
	# Return to the lower deck, leave the zone, then re-enter with W already held
	# (dig-aim) — must not sticky-mount without a fresh press after enter.
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

	# Airborne overlap auto-grabs so walking into the upper opening never free-falls past.
	player.exit_climb_zone(ladder)
	player._climbing = false
	player.collision_mask = player.WORLD_COLLISION_MASK
	player.global_position = Vector2(
		HollowLayout.LADDER_RETURN_X,
		HollowLayout.HEART_Y - player.BODY_HEIGHT + 8.0
	)
	player.velocity = Vector2(0.0, 120.0)
	player.enter_climb_zone(ladder)
	for _i in range(8):
		await physics_frame
		if player.is_climbing():
			break
	if not player.is_climbing():
		push_error("FAIL airborne ladder overlap did not auto-grab")
		quit(1)
		return
	print("PASS airborne climb-zone overlap auto-grabs")

	# Climb up and dismount onto the west spur (not into the open shaft).
	Input.action_press("ui_up")
	var landed_west := false
	for _i in range(1200): ## World-scale pass (2026-09-19): x5 — shaft is 5x taller now
		await physics_frame
		if (
			player.is_on_floor()
			and not player.is_climbing()
			and absf(player.global_position.y - (HollowLayout.HEART_Y - player.BODY_HEIGHT)) < 4.0
		):
			landed_west = player.global_position.x < HollowLayout.LADDER_RETURN_OPEN_X
			break
	Input.action_release("ui_up")
	for _i in range(8):
		await physics_frame
	if not landed_west:
		push_error(
			"FAIL Worker Return top dismount landed at %s (expected west of opening %s)"
			% [player.global_position, HollowLayout.LADDER_RETURN_OPEN_X]
		)
		quit(1)
		return
	print("PASS Worker Return dismounts onto west spur")

	# Mid Allotments share the same shaft — hop off mid-climb onto the east pad.
	player.global_position = Vector2(
		HollowLayout.LADDER_RETURN_X,
		HollowLayout.MID_ALLOT_Y - player.BODY_HEIGHT - 8.0
	)
	player.velocity = Vector2.ZERO
	player.enter_climb_zone(ladder)
	player._climbing = true
	player.collision_mask = 0
	Input.action_press("ui_accept")
	Input.action_press("ui_right")
	var landed_mid := false
	for _i in range(90):
		await physics_frame
		if (
			player.is_on_floor()
			and not player.is_climbing()
			and absf(player.global_position.y - (HollowLayout.MID_ALLOT_Y - player.BODY_HEIGHT)) < 6.0
			and player.global_position.x >= HollowLayout.LADDER_RETURN_OPEN_X + HollowLayout.LADDER_OPENING - 8.0
		):
			landed_mid = true
			break
	Input.action_release("ui_accept")
	Input.action_release("ui_right")
	for _i in range(8):
		await physics_frame
	if not landed_mid:
		push_error(
			"FAIL mid-shaft hop did not land on Mid Allotments at %s"
			% player.global_position
		)
		quit(1)
		return
	print("PASS Mid Allotments reachable from the shared Worker Return shaft")

	# East stack: Mid-East Landing mounts and climbs to Ashram (top of shaft).
	var east: Area2D = scene.get_node_or_null("Hollow/LadderEastStack") as Area2D
	if east == null:
		push_error("FAIL LadderEastStack missing")
		quit(1)
		return
	if int(east.get("upper_land_side")) <= 0:
		push_error(
			"FAIL LadderEastStack upper_land_side=%s must prefer east pad (1)"
			% east.get("upper_land_side")
		)
		quit(1)
		return
	var stand_mid_east := Vector2(
		HollowLayout.LADDER_EAST_X,
		HollowLayout.HEART_Y - player.BODY_HEIGHT
	)
	player._stop_climbing(false)
	player.exit_climb_zone(ladder)
	player.exit_climb_zone(east)
	player.collision_mask = player.WORLD_COLLISION_MASK
	player.global_position = stand_mid_east
	player.velocity = Vector2.ZERO
	player.enter_climb_zone(east)
	for _i in range(4):
		await physics_frame
	Input.action_press("ui_up")
	var climbed_ashram := false
	for _i in range(2400): ## World-scale pass (2026-09-19): x5 — shaft is 5x taller now
		await physics_frame
		if (
			player.is_on_floor()
			and not player.is_climbing()
			and absf(player.global_position.y - (HollowLayout.UPPER_RES_Y - player.BODY_HEIGHT)) < 6.0
			and player.global_position.x >= HollowLayout.ladder_east_open_end() - 8.0
		):
			climbed_ashram = true
			break
	Input.action_release("ui_up")
	for _i in range(8):
		await physics_frame
	if not climbed_ashram:
		push_error(
			"FAIL east stack climb from Mid-East did not land on Ashram east at %s"
			% player.global_position
		)
		quit(1)
		return
	print("PASS LadderEastStack climbs Mid-East to Ashram east")

	# Mid landings share the shaft — hop off onto Glowbeds hang east pad.
	player.global_position = Vector2(
		HollowLayout.LADDER_EAST_X,
		HollowLayout.GLOW_SUB_Y - player.BODY_HEIGHT - 8.0
	)
	player.velocity = Vector2.ZERO
	player.enter_climb_zone(east)
	player._climbing = true
	player.collision_mask = 0
	Input.action_press("ui_accept")
	Input.action_press("ui_right")
	var landed_hang := false
	for _i in range(90):
		await physics_frame
		if (
			player.is_on_floor()
			and not player.is_climbing()
			and absf(player.global_position.y - (HollowLayout.GLOW_SUB_Y - player.BODY_HEIGHT)) < 6.0
			and player.global_position.x >= HollowLayout.ladder_east_open_end() - 8.0
		):
			landed_hang = true
			break
	Input.action_release("ui_accept")
	Input.action_release("ui_right")
	for _i in range(8):
		await physics_frame
	if not landed_hang:
		push_error(
			"FAIL mid-shaft hop did not land on Glowbeds hang at %s"
			% player.global_position
		)
		quit(1)
		return
	print("PASS Glowbeds hang reachable from the shared east shaft")

	print("HOLLOW_CLIMB_TESTS_PASSED")
	scene.queue_free()
	await process_frame
	quit(0)
