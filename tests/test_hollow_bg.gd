extends SceneTree
## Hollow backdrop: readable cliffs + pit void (no fake city panels).


func _init() -> void:
	call_deferred("_run_tests")


func _run_tests() -> void:
	var scene: Node = (load("res://main.tscn") as PackedScene).instantiate()
	root.add_child(scene)
	await process_frame
	await process_frame

	# City concept panels must not fight walkable geometry.
	if scene.get_node_or_null("Hollow/BackdropLeft") != null:
		push_error("FAIL city BackdropLeft still present")
		quit(1)
		return
	if scene.get_node_or_null("Hollow/BackdropRight") != null:
		push_error("FAIL city BackdropRight still present")
		quit(1)
		return
	if scene.get_node_or_null("Hollow/Backdrop") != null:
		push_error("FAIL city Backdrop still present")
		quit(1)
		return
	print("PASS no hollow_bg city panels in scene")

	var cliff_l: ColorRect = scene.get_node_or_null("Hollow/CliffLeft") as ColorRect
	var cliff_r: ColorRect = scene.get_node_or_null("Hollow/CliffRight") as ColorRect
	if cliff_l == null or cliff_r == null:
		push_error("FAIL cliff silhouettes missing")
		quit(1)
		return
	if cliff_l.color.a < 0.95 or cliff_r.color.a < 0.95:
		push_error("FAIL cliffs must be solid ambient (not transparent zones)")
		quit(1)
		return
	print("PASS solid cliff silhouettes")

	if scene.get_node_or_null("Hollow/PitVoid") == null:
		push_error("FAIL PitVoid missing")
		quit(1)
		return
	print("PASS pit void present")

	# Bug-like decorative rects removed.
	for bad in ["LanternFarms", "LanternWick", "LanternBridge", "LanternCistern", "WarmFarms", "WarmWick", "WarmCistern", "BridgePlanks", "LadderFarmsVisual", "LadderCisternVisual"]:
		if scene.get_node_or_null("Hollow/%s" % bad) != null:
			push_error("FAIL decorative bug-rect still present: %s" % bad)
			quit(1)
			return
	print("PASS lantern/warm/plank bug-rects removed")

	# Production stubs sit on decks (opaque).
	for prop_name in ["PropFarms", "PropWick", "PropCistern"]:
		var prop: ColorRect = scene.get_node_or_null("Hollow/%s" % prop_name) as ColorRect
		if prop == null:
			push_error("FAIL %s missing" % prop_name)
			quit(1)
			return
		if prop.color.a < 0.95:
			push_error("FAIL %s must be solid stub, got a=%s" % [prop_name, prop.color.a])
			quit(1)
			return
	print("PASS solid district props on decks")

	var ladder_f: Area2D = scene.get_node_or_null("Hollow/LadderFarms") as Area2D
	var ladder_c: Area2D = scene.get_node_or_null("Hollow/LadderCistern") as Area2D
	if ladder_f == null or ladder_c == null:
		push_error("FAIL climb ladders missing")
		quit(1)
		return
	if ladder_f.get_script() == null or ladder_c.get_script() == null:
		push_error("FAIL climb ladder script missing")
		quit(1)
		return
	print("PASS climb ladders present")

	if scene.get_node_or_null("Hollow/NPCs/Pell") == null:
		push_error("FAIL Hollow NPCs missing")
		quit(1)
		return
	if scene.get_node_or_null("Hollow/DistrictFarms") == null:
		push_error("FAIL district labels missing")
		quit(1)
		return
	print("PASS Hollow districts + NPCs present")

	if scene.get_node_or_null("Hollow/HollowZone") == null:
		push_error("FAIL HollowZone missing")
		quit(1)
		return
	if scene.get_node_or_null("Hollow/Floor/CollisionShape2D") == null:
		push_error("FAIL Hollow floor collision missing")
		quit(1)
		return
	if scene.get_node_or_null("Hollow/FloorVisual") == null:
		push_error("FAIL FloorVisual missing")
		quit(1)
		return
	print("PASS Hollow zone + collision + floor tiles still present")

	if scene.get_node_or_null("Hollow/PitFogHigh") == null and scene.get_node_or_null("Hollow/AmbianceLights") == null:
		push_error("FAIL hollow ambiance (fog/lights) missing")
		quit(1)
		return
	if scene.get_node_or_null("Hollow/TerraceBandFarmsL") == null:
		push_error("FAIL terrace cliff bands missing")
		quit(1)
		return
	print("PASS hollow ambiance livability nodes")

	print("HOLLOW_BG_TESTS_PASSED")
	quit(0)
