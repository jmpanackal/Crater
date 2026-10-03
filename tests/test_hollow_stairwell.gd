extends SceneTree
## Every stair that sits in a room gets a stairwell view (carved back wall + ceiling); Mid Heart's open
## treads over the Mouth do not. The outline never rises above the underside of the street slab it
## meets, and stays attached to the tread.


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
	var dressing: Node = scene.get_node("Hollow/Dressing")
	var expected := 0
	for st in HollowMap.stairs():
		var node := dressing.get_node_or_null("Stairwell_%s" % str(st["id"]))
		if st["zone"] == &"mid_heart" or HollowMap.is_step(st):
			if node != null:
				_fail("%s is an open Mid Heart flight or a terrace step and should have no stairwell" % st["id"])
				return
			continue
		expected += 1
		if node == null:
			_fail("%s has no stairwell view" % st["id"])
			return
		var e := HollowStairwellView.edges(st)
		var tread: PackedVector2Array = e["tread"]
		var ceiling: PackedVector2Array = e["ceiling"]
		if tread.size() < 2 or tread.size() != ceiling.size():
			_fail("%s outline is malformed" % st["id"])
			return
		for i in range(tread.size()):
			if ceiling[i].y > tread[i].y + 0.01:
				_fail("%s ceiling dips below its tread at column %d" % [st["id"], i])
				return
			if ceiling[i].y < float(st["top_y"]) + 16.0 - 0.01 and ceiling[i].y < tread[i].y - 0.01:
				_fail("%s ceiling rises above the street slab at column %d" % [st["id"], i])
				return
		if not is_equal_approx(tread[0].y, float(st["foot_y"])) or not is_equal_approx(tread[tread.size() - 1].y, float(st["top_y"])):
			_fail("%s tread does not run foot to top" % st["id"])
			return
	print("PASS %d stairwells built, outlines attached to their treads" % expected)
	quit(0)
