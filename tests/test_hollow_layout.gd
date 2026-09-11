extends SceneTree
## Pit-centered Hollow: void, terrace elevations, bridge, camera verticality.


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var scene: Node = (load("res://main.tscn") as PackedScene).instantiate()
	root.add_child(scene)
	await process_frame
	await process_frame

	var pit: ColorRect = scene.get_node_or_null("Hollow/PitVoid") as ColorRect
	if pit == null:
		push_error("FAIL PitVoid missing")
		quit(1)
		return
	if pit.offset_left > HollowLayout.PIT_LEFT + 1.0 or pit.offset_right < HollowLayout.PIT_RIGHT - 1.0:
		push_error("FAIL PitVoid bounds %s–%s" % [pit.offset_left, pit.offset_right])
		quit(1)
		return
	print("PASS central PitVoid present")

	var farms: Label = scene.get_node("Hollow/DistrictFarms") as Label
	var wick: Label = scene.get_node("Hollow/DistrictWickwork") as Label
	var cistern: Label = scene.get_node("Hollow/DistrictCistern") as Label
	if farms.position.y >= wick.position.y or wick.position.y >= cistern.position.y:
		push_error(
			"FAIL district elevations farms=%s wick=%s cistern=%s"
			% [farms.position.y, wick.position.y, cistern.position.y]
		)
		quit(1)
		return
	print("PASS districts on distinct elevations")

	var floor_body: StaticBody2D = scene.get_node("Hollow/Floor") as StaticBody2D
	var shapes := 0
	for child in floor_body.get_children():
		if child is CollisionShape2D:
			shapes += 1
	if shapes < 6:
		push_error("FAIL expected multi-deck floor collisions, got %d" % shapes)
		quit(1)
		return
	if floor_body.get_node_or_null("MidBridge") == null:
		push_error("FAIL MidBridge collision missing")
		quit(1)
		return
	if (
		floor_body.get_node_or_null("WickRightWest") == null
		or floor_body.get_node_or_null("WickRightEast") == null
	):
		push_error("FAIL Wick right deck not split around ladder opening")
		quit(1)
		return
	if floor_body.get_node_or_null("CisternRight") == null:
		push_error("FAIL Cistern landing deck missing")
		quit(1)
		return
	print("PASS terraces + bridge + ladder openings")

	var ladder_f: Area2D = scene.get_node_or_null("Hollow/LadderFarms") as Area2D
	var ladder_c: Area2D = scene.get_node_or_null("Hollow/LadderCistern") as Area2D
	if ladder_f == null or ladder_c == null:
		push_error("FAIL climb ladders missing")
		quit(1)
		return
	if absf(ladder_f.position.y - HollowLayout.FARMS_Y) > 1.0:
		push_error("FAIL Farms ladder not starting at Farms deck")
		quit(1)
		return
	if absf(ladder_c.position.y - HollowLayout.WICK_Y) > 1.0:
		push_error("FAIL Cistern ladder not starting at Wick deck")
		quit(1)
		return
	# Ladders must sit inside the tile-aligned deck openings.
	if (
		ladder_f.position.x < HollowLayout.LADDER_FARMS_OPEN_X - 0.5
		or ladder_f.position.x + HollowLayout.LADDER_WIDTH
		> HollowLayout.ladder_farms_open_end() + 0.5
	):
		push_error("FAIL Farms ladder not centered in deck opening")
		quit(1)
		return
	if (
		ladder_c.position.x < HollowLayout.LADDER_CISTERN_OPEN_X - 0.5
		or ladder_c.position.x + HollowLayout.LADDER_WIDTH
		> HollowLayout.ladder_cistern_open_end() + 0.5
	):
		push_error("FAIL Cistern ladder not centered in deck opening")
		quit(1)
		return
	print("PASS climb shafts Farms↔Wick and Wick↔Cistern")

	var pell: Node2D = scene.get_node("Hollow/NPCs/Pell") as Node2D
	var rook: Node2D = scene.get_node("Hollow/NPCs/Rook") as Node2D
	var sila: Node2D = scene.get_node("Hollow/NPCs/Sila") as Node2D
	if absf(pell.position.y - HollowLayout.FARMS_Y) > 8.0:
		push_error("FAIL Pell not on Farms deck")
		quit(1)
		return
	if absf(rook.position.y - HollowLayout.WICK_Y) > 8.0:
		push_error("FAIL Rook not on Wickwork deck")
		quit(1)
		return
	if absf(sila.position.y - HollowLayout.CISTERN_Y) > 8.0:
		push_error("FAIL Sila not on Cistern deck")
		quit(1)
		return
	print("PASS NPCs on multiple decks")

	var cam: Camera2D = scene.get_node("Player/Camera2D") as Camera2D
	if cam.limit_top > -200 or cam.limit_bottom < 700:
		push_error("FAIL camera limits lack vertical room top=%d bottom=%d" % [cam.limit_top, cam.limit_bottom])
		quit(1)
		return
	if not cam.drag_vertical_enabled or cam.position_smoothing_speed > 7.0:
		push_error("FAIL camera missing soft follow / deadzone polish")
		quit(1)
		return
	print("PASS camera vertical limits")

	var player: Node2D = scene.get_node("Player") as Node2D
	if player.position.x > HollowLayout.PIT_LEFT:
		push_error("FAIL player spawn not on left terraces")
		quit(1)
		return
	print("PASS spawn on left terraces")

	# Dig site still past EXIT_RIGHT / DIG_START_X with no Hollow bleed.
	if TerrainLayer.DIG_START_X * TerrainLayer.TILE_SIZE < int(HollowLayout.EXIT_RIGHT):
		push_error("FAIL dig starts before Hollow exit")
		quit(1)
		return
	print("PASS dig site past Hollow exit ledge")

	print("HOLLOW_LAYOUT_TESTS_PASSED")
	quit(0)
