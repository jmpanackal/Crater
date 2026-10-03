extends SceneTree
## Mouth ledges reach out over the Mouth by at most LEDGE_MAX and nothing but Mid Heart spans it; a door is
## solid rock from the ceiling down to its opening, with the doorway open above the deck.


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
	var decks: TileMapLayer = hollow.deck_layer()
	var ledges := 0
	for r in HollowMap.runs():
		if r["zone"] == &"mid_heart":
			continue
		if r["r"] == HollowMap.END_LEDGE:
			var reach := float(r["x1"]) - HollowMap.MOUTH_L
			if reach <= 0.0 or reach > HollowMap.LEDGE_MAX:
				_fail("ledge %s reaches %d px (max %d)" % [r["id"], int(reach), int(HollowMap.LEDGE_MAX)])
				return
			# the deck is painted out over the Mouth, and the Mouth beyond it is still open
			if decks.get_cell_source_id(_cell(Vector2(HollowMap.MOUTH_L + reach - 8.0, float(r["y"]) + 8.0))) == -1:
				_fail("ledge %s has no deck over the Mouth" % r["id"])
				return
			if hollow.get_cell_source_id(_cell(Vector2(HollowMap.MOUTH_L + reach + 48.0, float(r["y"]) - 64.0))) != -1:
				_fail("the Mouth is not open past ledge %s" % r["id"])
				return
			ledges += 1
	if ledges == 0:
		_fail("expected at least one ledge")
		return
	var doors := 0
	for d in HollowMap.doors():
		var run := HollowMap.run_by_id(d["run"])
		var x: float = d["x"]
		var y: float = run["y"]
		var lintel := HollowMap.DOOR_OPENING + (48.0 if d.get("kind", &"door") == &"arch" else 16.0) # an arch is one tile taller in the middle
		if hollow.get_cell_source_id(_cell(Vector2(x, y - lintel))) == -1:
			_fail("door %s is not solid above its opening" % d["id"])
			return
		if hollow.get_cell_source_id(_cell(Vector2(x, y - HollowMap.DOOR_OPENING + 16.0))) != -1:
			_fail("door %s has no doorway" % d["id"])
			return
		if hollow.get_cell_source_id(_cell(Vector2(x, y - 24.0))) != -1:
			_fail("door %s blocks the floor" % d["id"])
			return
		doors += 1
	print("PASS %d ledge(s) within %d px of the lip, %d door(s) solid above a clear doorway" % [ledges, int(HollowMap.LEDGE_MAX), doors])
	quit(0)
