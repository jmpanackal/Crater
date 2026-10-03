extends SceneTree
## Stepped halls (HollowMap.halls()): the whole hall rect is open air (no civic rock) except the steps and
## wedges painted inside it; every hall has runs on its levels; open ends and the sloped streets exist.


func _init() -> void:
	call_deferred("_run")


func _fail(msg: String) -> void:
	push_error("FAIL " + msg)
	quit(1)


func _cell(p: Vector2) -> Vector2i:
	return Vector2i(int(floorf(p.x / 16.0)), int(floorf(p.y / 16.0)))


func _run() -> void:
	var scene: Node = (load("res://main.tscn") as PackedScene).instantiate()
	root.add_child(scene)
	await process_frame
	await process_frame
	var hollow := scene.get_node("Hollow/HollowTerrain") as TileMapLayer
	var open := 0
	for h in HollowMap.halls():
		var rect := Rect2(float(h["x0"]), HollowMap.lvl(float(h["k_top"])) - HollowMap.ROOM_HEIGHT, float(h["x1"]) - float(h["x0"]), 0.0)
		var steps_inside := 0
		for r in HollowMap.runs():
			if float(r["k"]) >= float(h["k_top"]) - 0.01 and float(r["k"]) <= float(h["k_bottom"]) + 0.01 and float(r["x0"]) < float(h["x1"]) and float(r["x1"]) > float(h["x0"]):
				steps_inside += 1
		if steps_inside < 2:
			_fail("hall %s has fewer than two runs in it" % h["id"])
			return
		# the upper part of the hall (between the top ceiling and the first deck) is open all the way across
		var y := rect.position.y + 112.0 # under any arched roof hung from the ceiling (96 px at most)
		var x := float(h["x0"]) + 24.0
		while x < float(h["x1"]) - 16.0:
			if hollow.get_cell_source_id(_cell(Vector2(x, y))) != -1:
				_fail("hall %s is blocked by rock at (%d, %d)" % [h["id"], int(x), int(y)])
				return
			open += 1
			x += 64.0
	# the sloped streets are long and shallow: pitch >= 2 with 160 px of air
	var slopes := 0
	for s in HollowMap.stairs():
		var run := absf(float(s["top_x"]) - float(s["foot_x"]))
		var rise := float(s["foot_y"]) - float(s["top_y"])
		if rise >= 384.0 - 0.5 and run >= rise * 2.0 - 0.5:
			slopes += 1
			if float(s["air"]) < 160.0:
				_fail("sloped street %s should have 160 px of air" % s["id"])
				return
	if slopes < 4:
		_fail("expected several sloped streets, found %d" % slopes)
		return
	print("PASS %d hall samples open air; %d sloped streets with 160 px of air" % [open, slopes])
	quit(0)
