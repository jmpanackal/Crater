extends SceneTree
## Uniform west stack: 6 sections × 2 equidistant levels, ladder bottom↔top,
## Mid Heart reachable from Wickwork, dig fronts open into west dig rock.


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var scene: Node2D = load("res://main.tscn").instantiate()
	root.add_child(scene)
	await process_frame
	await process_frame

	var levels: Array[float] = HollowLayout.west_stack_level_ys()
	if levels.size() != 12:
		push_error("FAIL west stack must expose exactly 12 levels (6×2), got %s" % levels.size())
		quit(1)
		return
	var gap := HollowLayout.WEST_LEVEL_GAP
	if gap < HollowLayout.MIN_BAND_GAP - 0.5:
		push_error("FAIL WEST_LEVEL_GAP %s is below MIN_BAND_GAP" % gap)
		quit(1)
		return
	for i in range(1, levels.size()):
		var d := levels[i] - levels[i - 1]
		if absf(d - gap) > 0.5:
			push_error("FAIL west levels not equidistant at index %s: delta=%s expected=%s" % [i, d, gap])
			quit(1)
			return
	if absf(HollowLayout.WICK_Y - HollowLayout.HEART_Y) > 0.5:
		push_error("FAIL Wickwork upper must share Mid Heart elevation")
		quit(1)
		return
	if absf(levels[4] - HollowLayout.HEART_Y) > 0.5:
		push_error("FAIL 5th west level (Wickwork upper) must be Mid Heart Y")
		quit(1)
		return
	print("PASS west stack is 12 equidistant levels; Wickwork upper = Mid Heart")

	var terrain: TileMapLayer = scene.get_node("Hollow/HollowTerrain") as TileMapLayer
	var tile := 16.0
	for rect in HollowLayout.west_stack_deck_rects():
		var mid_x := int(round((rect.x + rect.y) * 0.5 / tile))
		# Prefer a sample outside the west ladder / left-lift openings.
		var sample_x := mid_x
		var open0 := int(round(HollowLayout.LADDER_WEST_OPEN_X / tile))
		var open1 := int(round(HollowLayout.ladder_west_open_end() / tile))
		if sample_x >= open0 and sample_x < open1:
			sample_x = open1 + 2
		var y := int(round(rect.z / tile))
		if terrain.get_cell_source_id(Vector2i(sample_x, y)) == -1:
			push_error("FAIL west stack deck not painted at %s (sample %s,%s)" % [rect, sample_x, y])
			quit(1)
			return
	print("PASS all west stack decks are painted")

	if not scene.has_node("Hollow/LadderWestStack"):
		push_error("FAIL LadderWestStack missing — one west shaft for section transitions")
		quit(1)
		return
	if scene.has_node("Hollow/LadderWorkerReturn") or scene.has_node("Hollow/LadderHomeToHeart"):
		push_error("FAIL redundant west ladders must be removed (WorkerReturn / HomeToHeart)")
		quit(1)
		return
	var west_ladder: Area2D = scene.get_node("Hollow/LadderWestStack") as Area2D
	if absf(west_ladder.deck_top_y() - levels[0]) > 1.0:
		push_error("FAIL LadderWestStack top must be Ashram upper")
		quit(1)
		return
	if absf(west_ladder.deck_bottom_y() - levels[levels.size() - 1]) > 1.0:
		push_error("FAIL LadderWestStack bottom must be Bottom-West lower")
		quit(1)
		return
	# Floor gaps on every west level through the shaft (no sit-on-deck prompts).
	var open_x0 := HollowLayout.LADDER_WEST_OPEN_X
	for level_y in levels:
		var row := int(round(level_y / tile))
		for x_px in [open_x0 + 16.0, open_x0 + 48.0]:
			var col := int(round(x_px / tile))
			if terrain.get_cell_source_id(Vector2i(col, row)) != -1:
				push_error("FAIL west shaft still covered at y=%s x=%s" % [level_y, x_px])
				quit(1)
				return
	print("PASS LadderWestStack spans Ashram→Bottom-West with floor gaps")

	# Mid Heart still spans the Mouth and connects from Wickwork west lip.
	if not HollowLayout.mid_heart_spans_mouth():
		push_error("FAIL Mid Heart must still span PIT_LEFT→PIT_RIGHT")
		quit(1)
		return
	var heart_west := Vector2i(
		int(round((HollowLayout.PIT_LEFT - 80.0) / tile)),
		int(round(HollowLayout.HEART_Y / tile))
	)
	var heart_mid := Vector2i(
		int(round(HollowLayout.HEART_MID_X / tile)),
		int(round(HollowLayout.HEART_Y / tile))
	)
	if terrain.get_cell_source_id(heart_west) == -1:
		push_error("FAIL Wickwork/west exchange must meet Mid Heart at Mouth west lip")
		quit(1)
		return
	if terrain.get_cell_source_id(heart_mid) == -1:
		push_error("FAIL Mid Heart Mouth span must stay painted")
		quit(1)
		return
	print("PASS Mid Heart reachable from Wickwork across the Mouth")

	# Dig fronts open into diggable rock left of western hollow.
	var dig: TileMapLayer = scene.get_node("Terrain") as TileMapLayer
	var high_open := Vector2(
		(HollowLayout.HIGH_WEST_DIG_LEFT + HollowLayout.WEST_HOLLOW_LEFT) * 0.5,
		HollowLayout.WEST_HIGH_UPPER_Y - 16.0
	)
	var bottom_open := Vector2(
		(HollowLayout.HIGH_WEST_DIG_LEFT + HollowLayout.WEST_HOLLOW_LEFT) * 0.5,
		HollowLayout.BOTTOM_WEST_UPPER_Y - 16.0
	)
	if not dig.can_dig(high_open):
		push_error("FAIL High-West Dig Front must open into diggable rock at %s" % high_open)
		quit(1)
		return
	if not dig.can_dig(bottom_open):
		push_error("FAIL Bottom-West Dig Front must open into diggable rock at %s" % bottom_open)
		quit(1)
		return
	# Civic hollow itself is not dig mass.
	var hollow_sample := Vector2(-1600.0, HollowLayout.WICK_Y - 16.0)
	if dig.can_dig(hollow_sample):
		push_error("FAIL western hollow civic air must not be diggable at %s" % hollow_sample)
		quit(1)
		return
	print("PASS dig mass left of hollow; High-West + Bottom-West fronts open")

	# Spawn still on Lower Worker Terraces (Home Court).
	var spawn := HollowLayout.player_spawn_point()
	if absf(spawn.y + 32.0 - HollowLayout.WEST_LW_UPPER_Y) > 1.0:
		push_error("FAIL spawn feet must rest on Lower Worker upper (Home Court)")
		quit(1)
		return
	var player: CharacterBody2D = scene.get_node("Player") as CharacterBody2D
	player.global_position = spawn
	player.velocity = Vector2.ZERO
	for _i in range(8):
		await physics_frame
	if absf(player.global_position.y - spawn.y) > 8.0:
		push_error("FAIL player fell through Home Court spawn deck")
		quit(1)
		return
	print("PASS Act 1 spawn rests on Lower Worker / Home Court")

	# Climb bottom → Ashram top on the west shaft.
	player.global_position = Vector2(
		HollowLayout.LADDER_WEST_X,
		levels[levels.size() - 1] - player.BODY_HEIGHT
	)
	player.velocity = Vector2.ZERO
	player.enter_climb_zone(west_ladder)
	Input.action_press("ui_up")
	var reached_top := false
	for _i in range(6000):
		await physics_frame
		if (
			player.is_on_floor()
			and not player.is_climbing()
			and absf(player.global_position.y - (levels[0] - player.BODY_HEIGHT)) < 8.0
		):
			reached_top = true
			break
	Input.action_release("ui_up")
	if not reached_top:
		push_error("FAIL could not climb west stack bottom→top (pos=%s)" % player.global_position)
		quit(1)
		return
	print("PASS west stack climb bottom→top")

	print("ALL TESTS PASSED")
	quit(0)
