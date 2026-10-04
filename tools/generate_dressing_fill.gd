extends SceneTree
## Spreads placeholder dressing evenly over every district (USER 2026-10-04: an even smattering of structures across
## the map, not one big set piece in the Cistern and bare rock elsewhere). Writes hollow_dressing_fill.gd: plain data
## (props, lamps, buildings) that HollowDressing appends to its hand-authored lists, derived from the map and the
## zone themes below, never hand-edited. Placeholder greybox like the rest of the dressing: it is replaced by real
## art later. Deterministic (seeded per run), and every item is checked against the same conflicts the `dress` lint
## uses, so it never lands on a stair, ladder, gate, lift shaft or door.
## Run: godot --headless --path . --script res://tools/generate_dressing_fill.gd

const OUT := "res://hollow_dressing_fill.gd"
const FULL := 256.0

## theme -> {props: [[kind, weight, y_off, extra]], tones: lamp tones, per_k: props per 1000 px, lamp_k: lamps per
## 1000 px, building: kind or "", building_k: buildings per 1000 px}
const THEMES := {
	&"residence": {
		"props": [[&"pot", 3, 0.0], [&"herbs", 3, 0.0], [&"bench", 2, 0.0], [&"niche", 2, 0.0], [&"crystal", 1, 0.0], [&"basin", 1, 0.0], [&"awning", 1, 150.0], [&"notice", 1, 60.0]],
		"tones": [&"warm", &"warm", &"cool"], "per_k": 6.0, "lamp_k": 2.4, "building": &"unit", "building_k": 1.4,
	},
	&"homes": {
		"props": [[&"laundry", 2, 0.0], [&"pot", 3, 0.0], [&"bench", 2, 0.0], [&"stove", 1, 0.0], [&"crate", 2, 0.0], [&"basin", 1, 0.0], [&"fungal_mat", 2, 0.0], [&"notice", 1, 60.0]],
		"tones": [&"warm", &"warm", &"cool"], "per_k": 6.0, "lamp_k": 2.4, "building": &"facade", "building_k": 1.4,
	},
	&"allotment": {
		"props": [[&"laundry", 2, 0.0], [&"stove", 1, 0.0], [&"workbench", 2, 0.0], [&"crate", 2, 0.0], [&"barrel", 2, 0.0], [&"bench", 1, 0.0], [&"notice", 1, 60.0], [&"rack", 1, 0.0]],
		"tones": [&"warm", &"cool", &"warm"], "per_k": 6.0, "lamp_k": 2.4, "building": &"facade", "building_k": 1.2,
	},
	&"works": {
		"props": [[&"workbench", 2, 0.0], [&"rack", 2, 0.0], [&"beam_stack", 1, 0.0], [&"pipe", 1, 120.0], [&"turntable", 1, 0.0], [&"crate", 1, 0.0], [&"barrel", 1, 0.0], [&"gauge", 1, 70.0], [&"furnace", 3, 0.0], [&"anvil", 2, 0.0], [&"forge_wheel", 2, 0.0], [&"smokestack", 2, 0.0]],
		"tones": [&"cool", &"amber", &"cool"], "per_k": 6.0, "lamp_k": 2.4, "building": &"facade", "building_k": 0.9,
	},
	&"market": {
		"props": [[&"awning", 2, 150.0], [&"crate", 2, 0.0], [&"barrel", 2, 0.0], [&"cart", 2, 0.0], [&"scale", 1, 0.0], [&"notice", 2, 60.0], [&"sort_table", 2, 0.0], [&"supply_rack", 1, 0.0], [&"bench", 1, 0.0]],
		"tones": [&"warm", &"warm", &"cool"], "per_k": 6.0, "lamp_k": 2.4, "building": &"facade", "building_k": 1.2,
	},
	&"garden": {
		"props": [[&"planter", 4, 0.0], [&"glow_fungi", 3, 0.0], [&"fiber_rack", 2, 0.0], [&"harvest_basket", 2, 0.0], [&"culture_shelf", 2, 0.0], [&"herbs", 2, 0.0], [&"fungal_mat", 2, 0.0], [&"basin", 1, 0.0], [&"bench", 1, 0.0], [&"niche", 1, 0.0]],
		"tones": [&"cool", &"cool", &"warm"], "per_k": 6.0, "lamp_k": 2.4, "building": &"nook", "building_k": 0.6,
	},
	&"freight": {
		"props": [[&"cart", 2, 0.0], [&"crate", 3, 0.0], [&"barrel", 2, 0.0], [&"supply_rack", 2, 0.0], [&"notice", 1, 60.0], [&"scale", 1, 0.0], [&"sort_table", 1, 0.0], [&"pipe", 1, 110.0]],
		"tones": [&"cool", &"amber", &"cool"], "per_k": 6.0, "lamp_k": 2.4, "building": &"", "building_k": 0.0,
	},
	&"dig_front": {
		"props": [[&"supply_rack", 2, 0.0], [&"crate", 2, 0.0], [&"barrel", 1, 0.0], [&"cart", 2, 0.0], [&"ore_pile", 2, 0.0], [&"rubble", 2, 0.0], [&"warning_sign", 1, 0.0], [&"beam_stack", 1, 0.0], [&"fracture", 1, 0.0]],
		"tones": [&"amber", &"cool", &"amber"], "per_k": 6.0, "lamp_k": 2.4, "building": &"", "building_k": 0.0,
	},
}

## zone id (or prefix) -> theme. Zones with no entry get no fill (Mid Heart has its own structure view).
const ZONE_THEMES := {
	"ashram_": &"residence",
	"high_west_": &"dig_front",
	"bottom_west": &"dig_front",
	"first_expansion": &"dig_front",
	"collapsed_side": &"dig_front",
	"mid_east_dig": &"dig_front",
	"mid_east_": &"market",
	"glowbeds": &"garden",
	"mid_allotments": &"allotment",
	"wickwork": &"works",
	"lower_east_homes": &"homes",
	"lower_east_services": &"freight",
	"lower_rows_": &"homes",
	"east_rows_": &"homes",
	"worker_return": &"works",
	"lower_lift": &"freight",
	"cistern_freight": &"freight",
	"cistern_intake": &"freight",
}

var _rng := RandomNumberGenerator.new()
var _spans: Dictionary = {} ## k -> Array[Vector2] of occupied prop spans
var _bspans: Dictionary = {} ## k -> Array[Vector2] of occupied building spans
var _props: Array[Dictionary] = []
var _lamps: Array[Dictionary] = []
var _buildings: Array[Dictionary] = []
var _existing_by_zone: Dictionary = {}
var _len_by_zone: Dictionary = {}


func _init() -> void:
	call_deferred("_run")


func _theme_for(zone: StringName) -> StringName:
	var z := str(zone)
	var best := ""
	for key in ZONE_THEMES.keys():
		if z.begins_with(str(key)) and str(key).length() > best.length():
			best = str(key)
	return ZONE_THEMES[best] if best != "" else &""


func _prop_size(kind: StringName) -> Vector2:
	return HollowDressing.size_of(kind)


func _free(spans: Array, a: float, b: float, gap: float) -> bool:
	for sp in spans:
		if a < (sp as Vector2).y + gap and b > (sp as Vector2).x - gap:
			return false
	return true


func _ok_span(r: Dictionary, a: float, b: float, allow_shaft: bool) -> bool:
	var k := int(r["k"])
	if a < float(r["x0"]) + 64.0 or b > float(r["x1"]) - 64.0:
		return false
	if HollowMapLint._dress_conflict(Vector2(a, b), k, allow_shaft) != "":
		return false
	var y: float = r["y"]
	for lf in HollowMap.lifts():
		if (lf["stops"] as Array).has(y) and a < float(lf["open_x"]) + float(lf["width"]) + 48.0 and b > float(lf["open_x"]) - 48.0:
			return false
	for d in HollowMap.doors():
		var dr := HollowMap.run_by_id(d["run"])
		if not dr.is_empty() and absf(float(dr["y"]) - y) < 0.5 and a < float(d["x"]) + 72.0 and b > float(d["x"]) - 72.0:
			return false
	var mid := (a + b) * 0.5
	if HollowMapLint.zone_of(Vector2(mid, y - 32.0)) != r["zone"]:
		return false
	if HollowMapLint.zone_of(Vector2(a + 4.0, y - 32.0)) != r["zone"] or HollowMapLint.zone_of(Vector2(b - 4.0, y - 32.0)) != r["zone"]:
		return false
	return true


func _pick(props: Array) -> Array:
	var total := 0
	for p in props:
		total += int(p[1])
	var roll := _rng.randi_range(1, total)
	for p in props:
		roll -= int(p[1])
		if roll <= 0:
			return p
	return props[0]


func _run() -> void:
	# what the hand-authored dressing already holds, per zone
	for p in HollowDressing.authored_props():
		_existing_by_zone[p["zone"]] = int(_existing_by_zone.get(p["zone"], 0)) + 1
		_mark(_spans, int(p["k"]), float(p["x"]) - float(p["w"]) * 0.5, float(p["x"]) + float(p["w"]) * 0.5)
	for b in HollowDressing.authored_buildings():
		_mark(_bspans, int(b["k"]), float(b["x0"]), float(b["x1"]))
	for r in HollowMap.runs():
		if _flat_ok(r):
			var zid := HollowMapLint.zone_of(Vector2((float(r["x0"]) + float(r["x1"])) * 0.5, float(r["y"]) - 32.0))
			_len_by_zone[zid] = float(_len_by_zone.get(zid, 0.0)) + float(r["x1"]) - float(r["x0"])
	var runs: Array = HollowMap.runs().duplicate()
	for r0 in runs:
		if not _flat_ok(r0):
			continue
		# a run's own zone id may be a district name (mid_east); dressing belongs to the zone rect that holds it
		var r: Dictionary = r0.duplicate()
		r["zone"] = HollowMapLint.zone_of(Vector2((float(r["x0"]) + float(r["x1"])) * 0.5, float(r["y"]) - 32.0))
		if r["zone"] == &"":
			continue
		var theme_id := _theme_for(r["zone"])
		if theme_id == &"":
			continue
		var theme: Dictionary = THEMES[theme_id]
		_rng.seed = hash(str(r["id"]))
		var zone: StringName = r["zone"]
		# zones that already hold their share (the opening slice, the Cistern) get proportionally less
		var have := float(_existing_by_zone.get(zone, 0)) / maxf(float(_len_by_zone.get(zone, 1.0)) / 1000.0, 0.001)
		var share := clampf(1.0 - have / float(theme["per_k"]), 0.0, 1.0)
		if share <= 0.05:
			continue
		_fill_run(r, theme, share)
	_write()
	_report()
	quit(0)


func _flat_ok(r: Dictionary) -> bool:
	if HollowMap.is_heart_zone(r["zone"]) or bool(r["landing"]) or absf(float(r["dy"])) > 0.5:
		return false
	if absf(float(r["k"]) - roundf(float(r["k"]))) > 0.01:
		return false
	return float(r["x1"]) - float(r["x0"]) >= 224.0


func _mark(spans: Dictionary, k: int, a: float, b: float) -> void:
	if not spans.has(k):
		spans[k] = []
	(spans[k] as Array).append(Vector2(a, b))


func _fill_run(r: Dictionary, theme: Dictionary, share: float) -> void:
	var k := int(r["k"])
	var x0: float = r["x0"]
	var x1: float = r["x1"]
	var zone: StringName = r["zone"]
	if not _spans.has(k):
		_spans[k] = []
	if not _bspans.has(k):
		_bspans[k] = []
	# buildings first (backdrop), then props in front, then lamps overhead
	if theme["building"] != &"" and float(theme["building_k"]) > 0.0:
		var gap_b := 1000.0 / (float(theme["building_k"]) * share)
		var x := x0 + 96.0 + _rng.randf_range(0.0, gap_b * 0.5)
		while x < x1 - 200.0:
			var w := float(_rng.randi_range(10, 18)) * 16.0
			if _ok_span(r, x, x + w, true) and _free(_bspans[k], x, x + w, 64.0):
				_add_building(r, theme["building"], x, x + w)
				_mark(_bspans, k, x, x + w)
			x += w + gap_b * _rng.randf_range(0.7, 1.3)
	var gap := 1000.0 / (float(theme["per_k"]) * share)
	var px := x0 + 80.0 + _rng.randf_range(0.0, gap * 0.5)
	while px < x1 - 80.0:
		var pick := _pick(theme["props"])
		var kind: StringName = pick[0]
		var size := _prop_size(kind)
		var wd := size.x
		if _ok_span(r, px - wd * 0.5, px + wd * 0.5, false) and _free(_spans[k], px - wd * 0.5, px + wd * 0.5, 12.0):
			var y_off := float(pick[2])
			if y_off + size.y <= FULL - 24.0:
				_add_prop(zone, kind, px, k, y_off, size)
				_mark(_spans, k, px - wd * 0.5, px + wd * 0.5)
		px += gap * _rng.randf_range(0.7, 1.3) + wd * 0.5
	var lgap := 1000.0 / (float(theme["lamp_k"]) * share)
	var lx := x0 + 120.0 + _rng.randf_range(0.0, lgap * 0.5)
	while lx < x1 - 100.0:
		if _ok_span(r, lx - 12.0, lx + 12.0, false):
			var tones: Array = theme["tones"]
			_lamps.append({"zone": zone, "x": lx, "k": k, "y_off": float(_rng.randi_range(11, 15)) * 10.0, "tone": tones[_rng.randi_range(0, tones.size() - 1)]})
		lx += lgap * _rng.randf_range(0.8, 1.2)


func _add_prop(zone: StringName, kind: StringName, x: float, k: int, y_off: float, size: Vector2) -> void:
	_props.append({"zone": zone, "kind": kind, "x": snappedf(x, 2.0), "k": k, "y_off": y_off, "w": size.x, "h": size.y, "layer": &"back", "flip": 1.0 if _rng.randf() < 0.5 else -1.0})


func _add_building(r: Dictionary, kind: StringName, x0: float, x1: float) -> void:
	var doors: Array = []
	var windows: Array = []
	var w := x1 - x0
	doors.append(snappedf(x0 + w * _rng.randf_range(0.25, 0.4), 2.0))
	if w >= 200.0 and _rng.randf() < 0.5:
		doors.append(snappedf(x0 + w * _rng.randf_range(0.7, 0.85), 2.0))
	windows.append(snappedf(x0 + w * 0.6, 2.0))
	var b := {"id": StringName("fill_%s_%d" % [str(r["id"]), int(x0)]), "zone": r["zone"], "kind": kind, "x0": snappedf(x0, 2.0), "x1": snappedf(x1, 2.0), "k": int(r["k"]),
		"height": (FULL if not (HollowMap.in_flank(x0) or HollowMap.in_flank(x1)) else HollowMap.FLANK_CLEAR - 8.0) if kind != &"nook" else 120.0, "doors": doors, "windows": windows, "y_off": 0.0}
	if kind == &"facade":
		b["homely"] = true
	if kind == &"unit":
		b["warm"] = 1.0
	_buildings.append(b)


func _lit(v: Variant) -> String:
	match typeof(v):
		TYPE_STRING_NAME:
			return "&\"%s\"" % str(v)
		TYPE_STRING:
			return "\"%s\"" % str(v)
		TYPE_FLOAT:
			return str(snappedf(float(v), 0.01))
		TYPE_INT:
			return str(int(v))
		TYPE_ARRAY:
			var parts: Array[String] = []
			for e in v:
				parts.append(_lit(e))
			return "[" + ", ".join(parts) + "]"
		TYPE_BOOL:
			return "true" if v else "false"
	return str(v)


func _dict_lit(d: Dictionary) -> String:
	var parts: Array[String] = []
	for key in d.keys():
		parts.append("\"%s\": %s" % [str(key), _lit(d[key])])
	return "{" + ", ".join(parts) + "}"


func _write() -> void:
	var f := FileAccess.open(OUT, FileAccess.WRITE)
	f.store_string("## GENERATED by tools/generate_dressing_fill.gd from the map and the zone themes: do not hand-edit.\n")
	f.store_string("## An even spread of placeholder dressing over every district (USER 2026-10-04). Plain data that\n")
	f.store_string("## HollowDressing appends to its hand-authored lists; replaced by real art later.\n")
	f.store_string("extends RefCounted\n\n")
	f.store_string("const PROPS: Array[Dictionary] = [\n")
	for p in _props:
		f.store_string("\t%s,\n" % _dict_lit(p))
	f.store_string("]\n\nconst LAMPS: Array[Dictionary] = [\n")
	for l in _lamps:
		f.store_string("\t%s,\n" % _dict_lit(l))
	f.store_string("]\n\nconst BUILDINGS: Array[Dictionary] = [\n")
	for b in _buildings:
		f.store_string("\t%s,\n" % _dict_lit(b))
	f.store_string("]\n")
	f.close()


func _report() -> void:
	var per_zone: Dictionary = {}
	for p in _props:
		per_zone[p["zone"]] = int(per_zone.get(p["zone"], 0)) + 1
	print("fill: %d props, %d lamps, %d buildings" % [_props.size(), _lamps.size(), _buildings.size()])
	for z in per_zone.keys():
		var len_k := float(_len_by_zone.get(z, 1.0)) / 1000.0
		var total := int(per_zone[z]) + int(_existing_by_zone.get(z, 0))
		print("  %-26s +%3d props (now %.1f per 1000 px over %d px)" % [str(z), int(per_zone[z]), float(total) / maxf(len_k, 0.001), int(len_k * 1000.0)])
