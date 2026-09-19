extends SceneTree
## Playable expansion off the opening corridor: Worker Return Ascent, Mid Heart
## decks, and Mid-East Landing. Asserts new walkable places — not Switchback dips.


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var scene: Node2D = load("res://main.tscn").instantiate()
	root.add_child(scene)
	await process_frame
	await process_frame

	var terrain: TileMapLayer = scene.get_node("Hollow/HollowTerrain") as TileMapLayer
	var tile := 16.0

	# Opening corridor must stay flat — no Switchback dip / Dispatch podium clutter.
	if HollowLayout.SWITCHBACK_FLOOR.z != HollowLayout.LOWER_WORK_Y:
		push_error("FAIL Switchback must remain a flat lower-work corridor")
		quit(1)
		return
	if HollowLayout.WEST_DISPATCH_YARD.z != HollowLayout.LOWER_WORK_Y:
		push_error("FAIL West Dispatch must remain a flat apron")
		quit(1)
		return
	if HollowLayout.SWITCHBACK_LEFT != -160.0:
		push_error("FAIL Switchback west seam drifted from the clean corridor width")
		quit(1)
		return
	print("PASS opening corridor Switchback/Dispatch stay flat")

	for rect in HollowLayout.expansion_deck_rects():
		var mid_x := int(round((rect.x + rect.y) * 0.5 / tile))
		var y := int(round(rect.z / tile))
		if terrain.get_cell_source_id(Vector2i(mid_x, y)) == -1:
			push_error("FAIL expansion deck %s is not painted" % [rect])
			quit(1)
			return
	print("PASS worker return / Mid Heart / Mid-East decks are painted")

	for stair in HollowLayout.expansion_stair_rects():
		var sx0 := int(round(stair.x / tile))
		var sy0 := int(round(stair.y / tile))
		if terrain.get_cell_source_id(Vector2i(sx0, sy0)) == -1:
			push_error("FAIL expansion stair %s is not painted" % [stair])
			quit(1)
			return
	print("PASS Home landing flight into Mid Heart is painted")

	# Lower corridor under the west spur must stay walkable.
	var underpass := Vector2i(int(round(-112.0 / tile)), int(round(HollowLayout.LOWER_WORK_Y / tile)))
	if terrain.get_cell_source_id(underpass) == -1:
		push_error("FAIL Switchback floor under the west spur was erased")
		quit(1)
		return
	# Spur is Heart-height floor paint only — must not fill stair mass into the corridor.
	var spur_column := Vector2i(int(round(-300.0 / tile)), int(round((HollowLayout.LOWER_WORK_Y - 48.0) / tile)))
	if terrain.get_cell_source_id(spur_column) != -1:
		push_error("FAIL west spur must not drop solid fill into the opening corridor")
		quit(1)
		return
	print("PASS flat Switchback remains clear under the Heart-height spur")

	var zones: Node = root.get_node("Zones")
	if zones.get_zone_at(Vector2(-304, HollowLayout.HEART_Y)) != "worker_return_ascent":
		push_error("FAIL worker_return_ascent does not cover the west spur")
		quit(1)
		return
	if zones.get_zone_at(Vector2(536, HollowLayout.HEART_Y)) != "mid_heart":
		push_error("FAIL mid_heart does not cover the Heart decks")
		quit(1)
		return
	if zones.get_zone_at(Vector2(944, HollowLayout.HEART_Y)) != "mid_east_landing":
		push_error("FAIL mid_east_landing does not cover the east landing")
		quit(1)
		return
	var problems: Array = zones.validate_seams()
	if not problems.is_empty():
		push_error("FAIL expansion seams invalid: %s" % [problems])
		quit(1)
		return
	if not scene.has_node("Hollow/Zones/WorkerReturnAscent"):
		push_error("FAIL WorkerReturnAscent zone anchor missing from main.tscn")
		quit(1)
		return
	if not scene.has_node("Hollow/Zones/MidHeart") or not scene.has_node("Hollow/Zones/MidEastLanding"):
		push_error("FAIL Mid Heart / Mid-East zone anchors missing from main.tscn")
		quit(1)
		return
	if not scene.has_node("Hollow/LadderWorkerReturn"):
		push_error("FAIL LadderWorkerReturn missing from main.tscn")
		quit(1)
		return
	var ladder: Area2D = scene.get_node("Hollow/LadderWorkerReturn") as Area2D
	if absf(ladder.deck_top_y() - HollowLayout.HEART_Y) > 1.0:
		push_error("FAIL worker return ladder top is not at Mid Heart height")
		quit(1)
		return
	if absf(ladder.deck_bottom_y() - HollowLayout.LOWER_WORK_Y) > 1.0:
		push_error("FAIL worker return ladder bottom is not at lower-work height")
		quit(1)
		return
	print("PASS worker return ladder spans Switchback to the west spur")

	print("PLAYABLE_EXPANSION_TESTS_PASSED")
	scene.queue_free()
	await process_frame
	quit(0)
