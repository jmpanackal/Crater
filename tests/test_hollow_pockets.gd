extends SceneTree
## The civic cavity is solid rock except the rooms, flights, shafts, domes and the Mouth: rooms are air,
## the slab between two rooms is solid, the rock is not diggable (it is not on the dig Terrain layer), and
## a ladder shaft is open from its top deck to its bottom deck.


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
	var dig := scene.get_node("Terrain") as TileMapLayer
	var rooms := 0
	for r in HollowMap.runs():
		if HollowMap.is_heart_zone(r["zone"]) or bool(r["landing"]) or HollowMap.in_flank(float(r["x0"])) or HollowMap.in_flank(float(r["x1"])):
			continue
		# a Mouth ledge hangs out over the void: look at the part of the room that is inside the cliff
		var span_x0: float = maxf(float(r["x0"]), HollowMap.MOUTH_R) if r["l"] == HollowMap.END_LEDGE else float(r["x0"])
		var span_x1: float = minf(float(r["x1"]), HollowMap.MOUTH_L) if r["r"] == HollowMap.END_LEDGE else float(r["x1"])
		var x := (float(r["x0"]) + float(r["x1"])) * 0.5
		if x > HollowMap.MOUTH_L and x < HollowMap.MOUTH_R:
			x = (span_x0 + span_x1) * 0.5
		var y: float = r["y"]
		if hollow.get_cell_source_id(_cell(Vector2(x, y - 64.0))) != -1:
			_fail("room %s is not open air at its middle" % r["id"])
			return
		# the slab under the deck is rock (the deck row itself sits on the one-way layer)
		var below := Vector2(x, y + 48.0)
		var in_dig_shell := below.y >= HollowMap.CAVITY_BOTTOM # the bottom level sits on the diggable floor slab
		if not in_dig_shell and hollow.get_cell_source_id(_cell(below)) == -1 and not _under_connector(x, y + 48.0):
			_fail("no rock under room %s's deck" % r["id"])
			return
		rooms += 1
	# Rock between districts: a point in the solid civic rock above the first room is painted, and is not on the dig layer.
	var probe := Vector2(-1000.0, HollowMap.lvl(0.0))
	if hollow.get_cell_source_id(_cell(probe)) == -1:
		_fail("the top, unbuilt levels should be solid civic rock")
		return
	if dig.get_cell_source_id(_cell(probe)) != -1:
		_fail("civic rock must not be on the diggable layer")
		return
	# the Mouth stays open down the middle
	if hollow.get_cell_source_id(_cell(Vector2(HollowMap.HEART_X, HollowMap.lvl(2.0)))) != -1:
		_fail("the Mouth must stay open")
		return
	# every ladder shaft is open top to bottom
	for l in HollowMap.ladders():
		if HollowMap.in_flank(float(l["open_x"])):
			continue
		var lx := float(l["open_x"]) + 32.0
		var y := float(l["top_y"]) + 40.0
		while y < float(l["bottom_y"]) - 8.0:
			if hollow.get_cell_source_id(_cell(Vector2(lx, y))) != -1:
				_fail("ladder %s is blocked by rock at y=%d" % [l["id"], int(y)])
				return
			y += 32.0
	print("PASS %d rooms are open air over solid rock; the unbuilt levels are rock, not diggable; the Mouth and every ladder shaft are open" % rooms)
	quit(0)


func _under_connector(x: float, y: float) -> bool:
	for rc in HollowMap.air_rects():
		if rc.has_point(Vector2(x, y)):
			return true
	return false
