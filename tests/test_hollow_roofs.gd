extends SceneTree
## Arched roofs (HollowMap.roofs()) are real rock: solid across every block, the deepest band reaches the
## declared depth, and the walking air under the deepest band is still at least 160 px.


func _init() -> void:
	call_deferred("_run")


func _fail(msg: String) -> void:
	push_error("FAIL " + msg)
	quit(1)


func _run() -> void:
	var scene: Node = (load("res://main.tscn") as PackedScene).instantiate()
	root.add_child(scene)
	await process_frame
	await process_frame
	var layer := scene.get_node("Hollow/HollowTerrain") as TileMapLayer
	var blocks := 0
	for roof in HollowMap.roofs():
		var deck := HollowMap.lvl(float(roof["k"]))
		var deepest := 0.0
		for b in HollowMap.roof_blocks(roof):
			var cell := Vector2i(int((b.position.x + b.size.x * 0.5) / 16.0), int((b.position.y + b.size.y - 8.0) / 16.0))
			if layer.get_cell_source_id(cell) == -1:
				_fail("%s: roof block at %s is not solid" % [roof["id"], str(b.position)])
				return
			deepest = maxf(deepest, b.size.y)
			blocks += 1
		if not is_equal_approx(deepest, float(roof["depth"])):
			_fail("%s: deepest band is %s, declared %s" % [roof["id"], deepest, roof["depth"]])
			return
		if HollowMap.ROOM_HEIGHT - deepest < 160.0:
			_fail("%s leaves under 160 px of air over the deck at %s" % [roof["id"], deck])
			return
	print("PASS %d roof blocks are solid rock with 160+ px of air under them" % blocks)
	quit(0)
