extends SceneTree
## Local emergency ladder (Lower work↔Cistern) — climb zones; lifts are primary spine.


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

	var ladder: Area2D = scene.get_node("Hollow/LadderCistern") as Area2D
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
	var hit_left := ladder.global_position.x + col.position.x - rect.size.x * 0.5
	if hit_left > HollowLayout.LADDER_CISTERN_OPEN_X + 1.0:
		push_error("FAIL ladder grab does not reach deck lip (hit_left=%s)" % hit_left)
		quit(1)
		return
	var hit_top := ladder.global_position.y + col.position.y - rect.size.y * 0.5
	if hit_top > HollowLayout.LOWER_WORK_Y - 24.0:
		push_error("FAIL ladder grab zone does not cover standing player (hit_top=%s)" % hit_top)
		quit(1)
		return
	if not ladder.has_method("deck_bottom_y"):
		push_error("FAIL ladder missing deck_bottom_y")
		quit(1)
		return
	if absf(ladder.deck_bottom_y() - HollowLayout.CISTERN_Y) > 1.0:
		push_error(
			"FAIL LadderCistern bottom deck Y=%s expected Cistern=%s"
			% [ladder.deck_bottom_y(), HollowLayout.CISTERN_Y]
		)
		quit(1)
		return
	if absf(float(ladder.get("shaft_size").y) - HollowLayout.ladder_cistern_shaft_height()) > 1.0:
		push_error("FAIL LadderCistern visual shaft shorter than deck gap")
		quit(1)
		return
	var wood := ladder.get_node_or_null("WoodBack") as ColorRect
	if wood == null or absf(wood.size.y - float(ladder.get("shaft_size").y)) > 1.0:
		push_error("FAIL ladder visual not full shaft height")
		quit(1)
		return
	print("PASS ladder Area2D setup")

	var stand_upper := HollowLayout.LOWER_WORK_Y - 32.0
	var stand_cistern := HollowLayout.CISTERN_Y - 32.0
	player.global_position = Vector2(
		HollowLayout.LADDER_CISTERN_OPEN_X - 32.0,
		stand_upper
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
	print("PASS climb down through lower-work deck")

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

	player.global_position = Vector2(
		HollowLayout.LADDER_CISTERN_OPEN_X - 32.0,
		stand_upper
	)
	player.velocity = Vector2.ZERO
	player.collision_mask = 1
	for _i in range(5):
		await physics_frame

	Input.action_press("ui_down")
	for _i in range(120):
		await physics_frame
		if (
			not player.is_climbing()
			and player.collision_mask == 1
			and absf(player.global_position.y - stand_cistern) <= 4.0
		):
			break
	Input.action_release("ui_down")

	for _i in range(20):
		await physics_frame

	if player.collision_mask != 1:
		push_error(
			"FAIL climb-down-to-Cistern left collision_mask=%d" % player.collision_mask
		)
		quit(1)
		return
	if player.is_climbing():
		push_error("FAIL still climbing after reaching Cistern")
		quit(1)
		return
	if absf(player.global_position.y - stand_cistern) > 6.0:
		push_error(
			"FAIL climb-down did not land on Cistern (y=%s expected ~%s)"
			% [player.global_position.y, stand_cistern]
		)
		quit(1)
		return
	print("PASS climb down Lower→Cistern lands on floor")

	Input.action_press("ui_up")
	for _i in range(120):
		await physics_frame
		if (
			not player.is_climbing()
			and absf(player.global_position.y - stand_upper) <= 4.0
		):
			break
	Input.action_release("ui_up")
	for _i in range(15):
		await physics_frame

	if absf(player.global_position.y - stand_upper) > 6.0:
		push_error(
			"FAIL climb-up did not land on lower work (y=%s expected ~%s)"
			% [player.global_position.y, stand_upper]
		)
		quit(1)
		return
	print("PASS climb up Cistern→Lower work lands on floor")

	print("HOLLOW_CLIMB_TESTS_PASSED")
	quit(0)
