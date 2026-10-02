extends SceneTree
## Prints the HollowMapLint report and writes docs/refs/hollow-map.png.
## Run: godot --headless --path . --script res://tools/hollow_map_report.gd
## Add `-- scene` to also instantiate main.tscn and run the scene checks (slower).


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var rep := HollowMapLint.run()
	var errors: Array = rep["errors"].duplicate()
	for key in ["errors", "warnings", "info"]:
		for line in rep[key]:
			print("[%s] %s" % [key.to_upper(), line])
	if OS.get_cmdline_user_args().has("scene"):
		var scene: Node = load("res://main.tscn").instantiate()
		root.add_child(scene)
		await process_frame
		await process_frame
		var srep := HollowMapLint.lint_scene(scene)
		for key in ["errors", "warnings", "info"]:
			for line in srep[key]:
				print("[SCENE %s] %s" % [key.to_upper(), line])
		errors.append_array(srep["errors"])
	print("pieces: %d, errors: %d" % [rep["pieces"].size(), errors.size()])
	_save_png("res://docs/refs/hollow-map.png")
	quit(0)


## No text (headless has no font): level rows are the grid lines. Colours:
## rock brown, Mouth black, decks amber, stairs orange, ladders teal, lifts blue,
## gates red, growth reserves hatched grey, zone anchors yellow, spawn white.
func _save_png(path: String) -> void:
	var s := 0.1
	var x_min := -6400.0
	var y_min := -400.0
	var img := Image.create(int(19200.0 * s), int(8200.0 * s), false, Image.FORMAT_RGB8)
	img.fill(Color("14181a"))
	var px := func(x: float) -> int: return int((x - x_min) * s)
	var py := func(y: float) -> int: return int((y - y_min) * s)
	var rock := Color("2b2622")
	img.fill_rect(Rect2i(px.call(HollowMap.WEST_FLANK_LEFT - 320.0), py.call(0.0), int((HollowMap.WEST_WALL - HollowMap.WEST_FLANK_LEFT + 320.0) * s), int(7700.0 * s)), rock)
	img.fill_rect(Rect2i(px.call(HollowMap.EAST_WALL), py.call(0.0), int((12800.0 - HollowMap.EAST_WALL) * s), int(7700.0 * s)), rock)
	img.fill_rect(Rect2i(px.call(HollowMap.MOUTH_L), 0, int((HollowMap.MOUTH_R - HollowMap.MOUTH_L) * s), img.get_height()), Color("050b0e"))
	for k in range(12):
		img.fill_rect(Rect2i(0, py.call(HollowMap.lvl(float(k))), img.get_width(), 1), Color("2a3438"))
	for z in HollowMap.zones():
		if z.get("volume", false):
			continue
		var r: Rect2 = z["rect"]
		var c := Color("3a4a4f")
		img.fill_rect(Rect2i(px.call(r.position.x), py.call(r.position.y), maxi(int(r.size.x * s), 1), 1), c)
		img.fill_rect(Rect2i(px.call(r.position.x), py.call(r.end.y) - 1, maxi(int(r.size.x * s), 1), 1), c)
		img.fill_rect(Rect2i(px.call(r.position.x), py.call(r.position.y), 1, maxi(int(r.size.y * s), 1)), c)
		img.fill_rect(Rect2i(px.call(r.end.x) - 1, py.call(r.position.y), 1, maxi(int(r.size.y * s), 1)), c)
	for rs in HollowMap.reserves():
		var rr: Rect2 = rs["rect"]
		for yy in range(py.call(rr.position.y), py.call(rr.end.y), 3):
			img.fill_rect(Rect2i(px.call(rr.position.x), yy, maxi(int(rr.size.x * s), 1), 1), Color("55606a"))
	for w in HollowMap.wall_rects():
		img.fill_rect(Rect2i(px.call(w.position.x), py.call(w.position.y), maxi(int(w.size.x * s), 1), maxi(int(w.size.y * s), 1)), Color("6b5a4a"))
	for p in HollowMap.deck_pieces():
		img.fill_rect(Rect2i(px.call(p["x0"]), py.call(p["y"]) - 1, maxi(int((float(p["x1"]) - float(p["x0"])) * s), 1), 3), Color("e0a060"))
	for st in HollowMap.stairs():
		var n := int(absf(float(st["top_x"]) - float(st["foot_x"])) * s)
		for i in range(n + 1):
			var t := float(i) / float(maxi(n, 1))
			var sx: float = lerpf(float(st["foot_x"]), float(st["top_x"]), t)
			var sy: float = lerpf(float(st["foot_y"]), float(st["top_y"]), t)
			img.fill_rect(Rect2i(px.call(sx), py.call(sy) - 1, 2, 3), Color("ff7a2e"))
	for l in HollowMap.ladders():
		var lx: float = float(l["open_x"]) + 32.0
		img.fill_rect(Rect2i(px.call(lx) - 1, py.call(l["top_y"]), 3, int((float(l["bottom_y"]) - float(l["top_y"])) * s)), Color("7fd1b9"))
	for lf in HollowMap.lifts():
		var ys: Array = lf["stops"]
		var lx2: float = float(lf["open_x"]) + 32.0
		img.fill_rect(Rect2i(px.call(lx2) - 2, py.call(ys[0]), 5, int((float(ys[ys.size() - 1]) - float(ys[0])) * s)), Color("4aa3ff"))
		for y in ys:
			img.fill_rect(Rect2i(px.call(lx2) - 4, py.call(y) - 2, 9, 5), Color("a8d4ff"))
	for g in HollowMap.gates():
		var gr := HollowMap.run_by_id(g["run"])
		if gr.is_empty():
			continue
		img.fill_rect(Rect2i(px.call(g["x"]) - 1, py.call(gr["y"]) - 14, 3, 14), Color("ff3030"))
	for z in HollowMap.zones():
		var a: Vector2 = z["anchor"]
		img.fill_rect(Rect2i(px.call(a.x) - 3, py.call(a.y) - 9, 6, 6), Color("f2d16b"))
	var sp := HollowLayout.player_spawn_point()
	img.fill_rect(Rect2i(px.call(sp.x) - 5, py.call(sp.y + 32.0) - 14, 10, 10), Color.WHITE)
	img.save_png(ProjectSettings.globalize_path(path))
