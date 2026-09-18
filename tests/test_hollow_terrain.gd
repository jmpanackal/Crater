extends SceneTree
## Smoke test for hollow_terrain.gd — the single-source-of-truth tile+collision
## system (docs/hollow-level-authoring.md Rule 1). A painted tile must carry real
## collision; nothing unpainted should collide. This is the exact bug class the old
## hollow_decks.gd/hollow_floor.gd split allowed (a ramp with collision but no
## painted tile under it) — this test exists so it can't silently recur.


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var HollowTerrainScript := load("res://hollow_terrain.gd")
	var terrain: TileMapLayer = HollowTerrainScript.new()
	root.add_child(terrain)
	await process_frame

	terrain.paint_floor(0.0, 64.0, 96.0)
	terrain.paint_stairs(64.0, 96.0, 128.0, 112.0)
	await physics_frame
	await physics_frame

	if terrain.painted_cell_count() < 4:
		push_error("FAIL expected painted floor + stair cells, got %d" % terrain.painted_cell_count())
		quit(1)
		return
	print("PASS floor + stairs painted (%d cells)" % terrain.painted_cell_count())

	var space := terrain.get_world_2d().direct_space_state

	# A painted floor tile (world x0-64, y=96) must have real collision under it.
	var hit := space.intersect_ray(PhysicsRayQueryParameters2D.create(Vector2(16, 60), Vector2(16, 160)))
	if hit.is_empty():
		push_error("FAIL raycast through a painted floor tile found no collision")
		quit(1)
		return
	print("PASS painted tile has real collision (visual and collision are the same tile)")

	# An unpainted region must have no collision at all.
	var miss := space.intersect_ray(PhysicsRayQueryParameters2D.create(Vector2(800, 60), Vector2(800, 160)))
	if not miss.is_empty():
		push_error("FAIL raycast through an unpainted region found unexpected collision: %s" % [miss])
		quit(1)
		return
	print("PASS unpainted region has no collision")

	print("HOLLOW_TERRAIN_TESTS_PASSED")
	quit(0)
