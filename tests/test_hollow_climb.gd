extends SceneTree
## Ladder zones detect the player; W/S climbs through deck/stair colliders.
## Climb-down must land on the destination deck (not fall through).


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

	var ladder: Area2D = scene.get_node("Hollow/LadderFarms") as Area2D
	var player: CharacterBody2D = scene.get_node("Player") as CharacterBody2D
	if ladder == null or player == null:
		push_error("FAIL missing ladder or player")
		quit(1)
		return

	if ladder.collision_mask != 1 or player.collision_layer != 1:
		push_error(
			"FAIL climb detection layers ladder_mask=%d player_layer=%d"
			% [ladder.collision_mask, player.collision_layer]
		)
		quit(1)
		return
	if not ladder.monitoring:
		push_error("FAIL ladder not monitoring")
		quit(1)
		return

	var col: CollisionShape2D = ladder.get_node("CollisionShape2D") as CollisionShape2D
	var rect := col.shape as RectangleShape2D
	if rect == null or rect.size.x < 28.0 or rect.size.x > 80.0:
		push_error("FAIL ladder grab width odd: %s" % str(rect.size if rect else null))
		quit(1)
		return
	# Grab zone must reach the upper-deck lip (opening start), not float only over empty shaft.
	var hit_left := ladder.global_position.x + col.position.x - rect.size.x * 0.5
	if hit_left > HollowLayout.LADDER_FARMS_OPEN_X + 1.0:
		push_error("FAIL ladder grab does not reach Farms deck lip (hit_left=%s)" % hit_left)
		quit(1)
		return
	# Hitbox must reach above deck Y so a standing player overlaps.
	var hit_top := ladder.global_position.y + col.position.y - rect.size.y * 0.5
	if hit_top > HollowLayout.FARMS_Y - 24.0:
		push_error("FAIL ladder grab zone does not cover standing player (hit_top=%s)" % hit_top)
		quit(1)
		return
	if not ladder.has_method("deck_bottom_y"):
		push_error("FAIL ladder missing deck_bottom_y")
		quit(1)
		return
	if absf(ladder.deck_bottom_y() - HollowLayout.WICK_Y) > 1.0:
		push_error(
			"FAIL LadderFarms bottom deck Y=%s expected Wick=%s"
			% [ladder.deck_bottom_y(), HollowLayout.WICK_Y]
		)
		quit(1)
		return
	print("PASS ladder Area2D setup")

	# Place player at the Farms deck lip beside the opening (solid floor + grab reach).
	var stand_farms := HollowLayout.FARMS_Y - 32.0
	var stand_wick := HollowLayout.WICK_Y - 32.0
	player.global_position = Vector2(
		HollowLayout.LADDER_FARMS_OPEN_X - 32.0,
		stand_farms
	)
	player.velocity = Vector2.ZERO
	for _i in range(5):
		await physics_frame

	if not player.is_in_climb_zone():
		push_error("FAIL player not detected in climb zone")
		quit(1)
		return
	print("PASS climb zone overlap detects player")

	var y_before := player.global_position.y
	Input.action_press("ui_down")
	for _i in range(20):
		await physics_frame
	Input.action_release("ui_down")

	if not player.is_climbing() and player.global_position.y <= y_before + 8.0:
		push_error(
			"FAIL did not climb down (y %s -> %s, climbing=%s)"
			% [y_before, player.global_position.y, player.is_climbing()]
		)
		quit(1)
		return
	if player.global_position.y < y_before + 24.0:
		push_error(
			"FAIL climb blocked by floors/stairs (y %s -> %s)"
			% [y_before, player.global_position.y]
		)
		quit(1)
		return
	print("PASS climb down through Farms deck")

	var mid_y := player.global_position.y
	Input.action_press("ui_up")
	for _i in range(20):
		await physics_frame
	Input.action_release("ui_up")

	if player.global_position.y > mid_y - 24.0:
		push_error(
			"FAIL climb up blocked (y %s -> %s)"
			% [mid_y, player.global_position.y]
		)
		quit(1)
		return
	print("PASS climb up along shaft")

	# Hop off restores world collision.
	Input.action_press("ui_accept")
	await physics_frame
	Input.action_release("ui_accept")
	await physics_frame
	if player.is_climbing():
		push_error("FAIL still climbing after hop-off")
		quit(1)
		return
	if player.collision_mask != 1:
		push_error("FAIL hop-off left collision_mask=%d" % player.collision_mask)
		quit(1)
		return
	print("PASS hop-off clears climb state")

	# --- Climb all the way down Farms → Wick and land on the deck ---
	player.global_position = Vector2(
		HollowLayout.LADDER_FARMS_OPEN_X - 32.0,
		stand_farms
	)
	player.velocity = Vector2.ZERO
	player.collision_mask = 1
	for _i in range(5):
		await physics_frame

	Input.action_press("ui_down")
	# Enough frames to traverse the 192px shaft at CLIMB_SPEED 140 (~1.4s).
	for _i in range(120):
		await physics_frame
		# Early success: landed and stopped climbing.
		if (
			not player.is_climbing()
			and player.collision_mask == 1
			and absf(player.global_position.y - stand_wick) <= 4.0
		):
			break
	Input.action_release("ui_down")

	# Settle a few frames — must stay on Wick, not fall through the pit.
	for _i in range(20):
		await physics_frame

	if player.collision_mask != 1:
		push_error(
			"FAIL climb-down-to-Wick left collision_mask=%d" % player.collision_mask
		)
		quit(1)
		return
	if player.is_climbing():
		push_error("FAIL still climbing after reaching Wick")
		quit(1)
		return
	if absf(player.global_position.y - stand_wick) > 6.0:
		push_error(
			"FAIL climb-down did not land on Wick (y=%s expected ~%s)"
			% [player.global_position.y, stand_wick]
		)
		quit(1)
		return
	if player.global_position.y > stand_wick + 16.0:
		push_error(
			"FAIL fell through Wick deck (y=%s)" % player.global_position.y
		)
		quit(1)
		return
	if not player.is_on_floor() and player.velocity.y > 200.0:
		push_error(
			"FAIL falling after climb-down (on_floor=%s vy=%s)"
			% [player.is_on_floor(), player.velocity.y]
		)
		quit(1)
		return
	print("PASS climb down Farms→Wick lands on floor")

	# Climb back up Farms and land on upper deck.
	Input.action_press("ui_up")
	for _i in range(120):
		await physics_frame
		if (
			not player.is_climbing()
			and absf(player.global_position.y - stand_farms) <= 4.0
		):
			break
	Input.action_release("ui_up")
	for _i in range(15):
		await physics_frame

	if absf(player.global_position.y - stand_farms) > 6.0:
		push_error(
			"FAIL climb-up did not land on Farms (y=%s expected ~%s)"
			% [player.global_position.y, stand_farms]
		)
		quit(1)
		return
	if player.collision_mask != 1:
		push_error("FAIL climb-up left collision_mask=%d" % player.collision_mask)
		quit(1)
		return
	print("PASS climb up Wick→Farms lands on floor")

	print("HOLLOW_CLIMB_TESTS_PASSED")
	quit(0)
