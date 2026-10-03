extends SceneTree
## HollowMap.deck_y_at(x, k) is the one way to ask where band k's deck is at x. With no per-run
## offsets authored yet it must equal the nominal band line everywhere dressing stands, so the
## refactor that routed everything through it changed no layout.


func _init() -> void:
	call_deferred("_run")


func _fail(msg: String) -> void:
	push_error("FAIL " + msg)
	quit(1)


func _run() -> void:
	var checked := 0
	for r in HollowMap.runs():
		for x in [float(r["x0"]), (float(r["x0"]) + float(r["x1"])) * 0.5, float(r["x1"])]:
			if not is_equal_approx(HollowMap.deck_y_at(x, float(r["k"])), float(r["y"])):
				_fail("deck_y_at(%s, %s) is not run %s's deck %s" % [x, r["k"], r["id"], r["y"]])
				return
			checked += 1
	var items: Array = []
	items.append_array(HollowDressing.props())
	items.append_array(HollowDressing.lamps())
	items.append_array(HollowDressing.actors())
	items.append_array(HollowDressing.stations())
	for it in items:
		var x: float = it["x"]
		if not is_equal_approx(HollowMap.deck_y_at(x, float(it["k"])), HollowMap.lvl(float(it["k"]))):
			_fail("%s at x=%d level %d: deck_y_at moved the deck off the band line" % [str(it.get("id", "?")), int(x), int(it["k"])])
			return
		checked += 1
	for b in HollowDressing.buildings():
		var mid := (float(b["x0"]) + float(b["x1"])) * 0.5
		if not is_equal_approx(HollowMap.deck_y_at(mid, float(b["k"])), HollowMap.lvl(float(b["k"]))):
			_fail("building %s: deck_y_at moved the deck off the band line" % str(b["id"]))
			return
		checked += 1
	# The Allotment Terrace: the raised stretch of band 7 reads 48 px above the band line; its neighbours do not.
	if not is_equal_approx(HollowMap.deck_y_at(100.0, 11.0), HollowMap.lvl(11.0) - 48.0):
		_fail("the Allotment Terrace deck should sit 48 px above the band line")
		return
	if not is_equal_approx(HollowMap.deck_y_at(-1000.0, 11.0), HollowMap.lvl(11.0)) or not is_equal_approx(HollowMap.deck_y_at(1000.0, 11.0), HollowMap.lvl(11.0)):
		_fail("the streets either side of the Allotment Terrace should stay on the band line")
		return
	# A band with no run at x falls back to the nominal line.
	if not is_equal_approx(HollowMap.deck_y_at(1.0e7, 7.0), HollowMap.lvl(7.0)):
		_fail("deck_y_at off the end of every run should return the band line")
		return
	print("PASS deck_y_at matches the band line for %d runs and dressing items" % checked)
	quit(0)
