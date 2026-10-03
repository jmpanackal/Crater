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
## rock brown (Firmament slightly cooler), civic cavity dark teal, the pit black, decks amber,
## stairs orange, ladders teal, gates red, growth reserves hatched grey, zone
## anchors yellow, spawn white. The image is the whole dig envelope.
func _save_png(path: String) -> void:
	var s := 0.06
	var margin := 120.0
	var env := HollowMap.env_rect()
	var x_min := env.position.x - margin / s
	var y_min := env.position.y - margin / s
	var img := Image.create(int(env.size.x * s + margin * 2.0), int(env.size.y * s + margin * 2.0), false, Image.FORMAT_RGB8)
	img.fill(Color("0b0e10"))
	var px := func(x: float) -> int: return int((x - x_min) * s)
	var py := func(y: float) -> int: return int((y - y_min) * s)
	var rect_px := func(r: Rect2, c: Color) -> void:
		img.fill_rect(Rect2i(px.call(r.position.x), py.call(r.position.y), maxi(int(r.size.x * s), 1), maxi(int(r.size.y * s), 1)), c)
	rect_px.call(env, Color("2b2622"))
	rect_px.call(Rect2(env.position.x, env.position.y, env.size.x, HollowMap.ROCK_TOP), Color("262a2c"))
	rect_px.call(HollowMap.cavity_rect(), Color("0f1a1c"))
	rect_px.call(HollowMap.pit_rect(), Color("050b0e"))
	rect_px.call(Rect2(HollowMap.MOUTH_L, HollowMap.ROCK_TOP, HollowMap.MOUTH_R - HollowMap.MOUTH_L, HollowMap.CAVITY_BOTTOM - HollowMap.ROCK_TOP), Color("050b0e"))
	for k in range(HollowMap.LEVELS):
		img.fill_rect(Rect2i(px.call(HollowMap.WEST_WALL), py.call(HollowMap.lvl(float(k))), int((HollowMap.EAST_WALL - HollowMap.WEST_WALL) * s), 1), Color("1d2a2e"))
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
