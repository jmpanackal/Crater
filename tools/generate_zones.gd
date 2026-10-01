extends SceneTree
## Regenerates content/zones/*.tres from HollowMap.zones(): rects, anchors, flags, and the
## reciprocal seam graph derived from what actually connects (touching decks, stairs, ladders,
## lifts). Zones are data derived from the map, never hand-edited.
## Run: godot --headless --path . --script res://tools/generate_zones.gd

const DIR := "res://content/zones/"


func _init() -> void:
	call_deferred("_run")


func _zone_at(p: Vector2) -> StringName:
	for z in HollowMap.zones():
		if not z.get("volume", false) and (z["rect"] as Rect2).has_point(p):
			return z["id"]
	return &""


func _run() -> void:
	var seams: Dictionary = {} # zone id -> Array[Dictionary]
	for z in HollowMap.zones():
		seams[z["id"]] = []
	var add_seam := func(a: StringName, edge_a: String, b: StringName, edge_b: String, pos: float) -> void:
		if a == &"" or b == &"" or a == b:
			return
		var ka := {"edge": edge_a, "neighbor": str(b), "position": int(pos)}
		var kb := {"edge": edge_b, "neighbor": str(a), "position": int(pos)}
		if not (seams[a] as Array).has(ka):
			seams[a].append(ka)
		if not (seams[b] as Array).has(kb):
			seams[b].append(kb)
	# Vertical links: the zone above gets "south", the zone below gets "north"; position = lower deck y.
	var link_vertical := func(upper_pt: Vector2, lower_pt: Vector2) -> void:
		var up := _zone_at(upper_pt)
		var low := _zone_at(lower_pt)
		add_seam.call(up, "south", low, "north", lower_pt.y + 32.0)
	for l in HollowMap.ladders():
		var lx: float = float(l["open_x"]) + 32.0
		link_vertical.call(Vector2(lx - 96.0, float(l["top_y"]) - 32.0), Vector2(lx - 96.0, float(l["bottom_y"]) - 32.0))
		link_vertical.call(Vector2(lx + 96.0, float(l["top_y"]) - 32.0), Vector2(lx + 96.0, float(l["bottom_y"]) - 32.0))
	for s in HollowMap.stairs():
		var dir := float(s["dir"])
		var foot := Vector2(float(s["foot_x"]) - dir * 48.0, float(s["foot_y"]) - 32.0)
		var top := Vector2(float(s["top_x"]) + dir * 48.0, float(s["top_y"]) - 32.0)
		link_vertical.call(top, foot)
		# the street over the flight's last stretch drops onto it
		var over := Vector2(float(s["top_x"]) - dir * 48.0, float(s["top_y"]) - 32.0)
		link_vertical.call(over, foot)
	for lf in HollowMap.lifts():
		var stops: Array = lf["stops"]
		for i in range(stops.size() - 1):
			for side in [-96.0, 96.0]:
				var px: float = float(lf["open_x"]) + 32.0 + side
				link_vertical.call(Vector2(px, float(stops[i]) - 32.0), Vector2(px, float(stops[i + 1]) - 32.0))
	# Same-level neighbours: touching zone rects with continuous deck across the boundary.
	var zs := HollowMap.zones()
	for a in zs:
		for b in zs:
			if a.get("volume", false) or b.get("volume", false) or a["id"] == b["id"]:
				continue
			var ra: Rect2 = a["rect"]
			var rb: Rect2 = b["rect"]
			if absf(ra.end.x - rb.position.x) > 1.0:
				continue
			for y in HollowMap.level_ys() + [HollowLayout.RITUAL_Y, HollowLayout.FREIGHT_TIER_Y]:
				if y - 32.0 < maxf(ra.position.y, rb.position.y) or y - 32.0 > minf(ra.end.y, rb.end.y):
					continue
				var left_ok := _deck_at(Vector2(ra.end.x - 16.0, y))
				var right_ok := _deck_at(Vector2(rb.position.x + 16.0, y))
				if left_ok and right_ok:
					add_seam.call(a["id"], "east", b["id"], "west", ra.end.x)
					break
	# Write the files; drop zones that no longer exist (never touching test fixtures).
	var keep: Array[String] = []
	for z in zs:
		keep.append("%s.tres" % str(z["id"]))
		_write(z, seams[z["id"]] if seams.has(z["id"]) else [])
	var dir := DirAccess.open(DIR)
	for f in dir.get_files():
		if f.ends_with(".tres") and not f.begins_with("test_") and not keep.has(f):
			dir.remove(f)
			print("removed stale zone ", f)
	print("wrote %d zones" % zs.size())
	quit(0)


func _deck_at(p: Vector2) -> bool:
	for piece in HollowMap.deck_pieces():
		if absf(float(piece["y"]) - p.y) < 0.5 and p.x >= float(piece["x0"]) - 0.5 and p.x <= float(piece["x1"]) + 0.5:
			return true
	return false


func _write(z: Dictionary, zone_seams: Array) -> void:
	var rect: Rect2 = z["rect"]
	var anchor: Vector2 = z["anchor"]
	var lines: Array[String] = []
	lines.append('[gd_resource type="Resource" script_class="" load_steps=2 format=3]')
	lines.append("")
	lines.append('[ext_resource type="Script" path="res://content/zone_definition.gd" id="1"]')
	lines.append("")
	lines.append("[resource]")
	lines.append('script = ExtResource("1")')
	lines.append('zone_id = &"%s"' % str(z["id"]))
	lines.append('display_name = "%s"' % str(z["display"]))
	lines.append("world_origin = Vector2(%d, %d)" % [int(anchor.x), int(anchor.y)])
	if zone_seams.is_empty():
		lines.append("seams = []")
	else:
		var parts: Array[String] = []
		for sm in zone_seams:
			parts.append('{\n"edge": "%s",\n"neighbor": "%s",\n"position": %d\n}' % [sm["edge"], sm["neighbor"], sm["position"]])
		lines.append("seams = [" + ", ".join(parts) + "]")
	lines.append("enclosed = %s" % ("true" if z["enclosed"] else "false"))
	lines.append("world_rect = Rect2(%d, %d, %d, %d)" % [int(rect.position.x), int(rect.position.y), int(rect.size.x), int(rect.size.y)])
	lines.append("restricted = %s" % ("true" if z["restricted"] else "false"))
	var f := FileAccess.open(DIR + "%s.tres" % str(z["id"]), FileAccess.WRITE)
	f.store_string("\n".join(lines) + "\n")
	f.close()
