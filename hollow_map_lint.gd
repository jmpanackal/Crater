class_name HollowMapLint
extends Object
## Structural lint for the Hollow map. Judges HollowMap's data (and, for lint_scene, the real
## instanced scene) as a graph, so the mistakes an author makes by eye are caught by a test.
## Rules (details in docs/hollow-map-spec.md):
##   grid       every deck is on the level grid (Mid Heart's two half levels excepted)
##   stack      decks that overlap in x are at least half a level apart; runs never overlap
##   end        every run end is a wall, a Mouth lip, rock, a stair foot/top, or a Mouth join,
##              and the stair it names really is there
##   stair      foot on a run end, top on a deck, wedge clear of every other deck
##   ladder     a deck covers the shaft at its top and at its bottom
##   gate       gates sit on a run, away from ladders
##   mouth      only Mid Heart touches the Mouth
##   reserve    growth footprints are empty, rock-backed and touch their own district
##   zone       zones never overlap, anchors stand on decks, every deck belongs to a zone
##   reach      with all gates open every deck is reachable from spawn (and can get back);
##              with the start-closed gates shut every early zone is still reachable
##   space      the two walls carry comparable walkable length
##   shell      the Hollow is encased in rock: Firmament above, deep flanks, a floor slab, the pit open
##   dress      dressing (props, buildings, people, lamps, stations) stands on a deck in its own zone,
##              clear of stairs, shafts and gates, under the ceiling, and no slice zone is left thin
## Scene rules: structures instanced to match, walls and treads painted, headroom above every
## deck and tread, rock beyond flank ends.

const EPS := 0.5
const MIN_PIECE := 96.0
## Smallest vertical separation between decks that overlap in x (half a level: Mid Heart's tiers).
const MIN_STACK := HollowMap.LEVEL_GAP * 0.5
## Rock that must remain past the end of an authored dig gallery, so the player can dig on.
const MIN_FLANK_BEYOND := 1600.0
## Thinnest acceptable Firmament and floor slab.
const MIN_FIRMAMENT := 1024.0
const MIN_SLAB := 512.0
## Longest unbroken walk (px) before the `flat` warning: about eight seconds at walking pace. A run is
## already split wherever a step or landing breaks it, so its length is its flat stretch.
const MAX_FLAT := 1600.0


## {"errors", "warnings", "info": Array[String], "pieces": Array[Dictionary], "reach": Dictionary}
static func run() -> Dictionary:
	var rep := {"errors": [] as Array[String], "warnings": [] as Array[String], "info": [] as Array[String]}
	rep["pieces"] = HollowMap.deck_pieces()
	_check_grid_and_stack(rep)
	_check_flat(rep)
	_check_roofs(rep)
	_check_domes(rep)
	_check_doors(rep)
	_check_halls(rep)
	_check_ends(rep)
	_check_stairs(rep)
	_check_ladders(rep)
	_check_lifts(rep)
	_check_gates(rep)
	_check_lift_only(rep)
	_check_mouth(rep)
	_check_cliff(rep)
	_check_reserves(rep)
	_check_zones(rep)
	_check_reach(rep)
	_space_report(rep)
	_check_shell(rep)
	_check_dressing(rep)
	return rep


static func _err(rep: Dictionary, msg: String) -> void:
	rep["errors"].append(msg)


static func run_label(r: Dictionary) -> String:
	return "run %s (y=%d x=%d..%d)" % [str(r["id"]), int(r["y"]), int(r["x0"]), int(r["x1"])]


## A terrace offset: a whole number of tiles, between one tile and six (96 px), per the variety-pass
## decision (small offsets only). The step stairs at its ends are checked by the end and stair rules.
const TERRACE_MIN := 16.0
const TERRACE_MAX := 96.0


static func _on_grid(y: float, half_ok: bool) -> bool:
	var step := HollowMap.LEVEL_GAP * (0.5 if half_ok else 1.0)
	var k := (y - HollowMap.LEVEL_ORIGIN) / step
	return absf(k - roundf(k)) * step < EPS


static func _check_grid_and_stack(rep: Dictionary) -> void:
	var runs := HollowMap.runs()
	for r in runs:
		var half_ok: bool = HollowMap.is_heart_zone(r["zone"]) or bool(r["landing"])
		var dy: float = r["dy"]
		if absf(dy) > EPS and (half_ok or absf(dy) < TERRACE_MIN - EPS or absf(dy) > TERRACE_MAX + EPS or absf(fposmod(absf(dy), 16.0)) > EPS):
			_err(rep, "grid: %s has terrace offset %d (whole tiles, %d..%d px, never on Mid Heart or a landing)" % [run_label(r), int(dy), int(TERRACE_MIN), int(TERRACE_MAX)])
		if not _on_grid(float(r["y"]) - dy, half_ok):
			_err(rep, "grid: %s is off the %dpx level grid" % [run_label(r), int(HollowMap.LEVEL_GAP)])
		if float(r["x1"]) - float(r["x0"]) < MIN_PIECE:
			_err(rep, "end: %s is shorter than %dpx" % [run_label(r), int(MIN_PIECE)])
		if fposmod(float(r["x0"]), 16.0) > EPS or fposmod(float(r["x1"]), 16.0) > EPS:
			_err(rep, "tile: %s has an end that is not on a 16px tile (the rock between rooms is painted by tile)" % run_label(r))
	for i in runs.size():
		for j in range(i + 1, runs.size()):
			var a: Dictionary = runs[i]
			var b: Dictionary = runs[j]
			if not (a["x0"] < b["x1"] - EPS and b["x0"] < a["x1"] - EPS):
				continue
			var d := absf(float(a["y"]) - float(b["y"]))
			if d < EPS:
				_err(rep, "stack: %s and %s overlap on the same level" % [run_label(a), run_label(b)])
			elif d < MIN_STACK - EPS:
				_err(rep, "stack: %s and %s overlap in x only %dpx apart (min %d)" % [run_label(a), run_label(b), int(d), int(MIN_STACK)])
	for p in HollowMap.deck_pieces():
		if float(p["x1"]) - float(p["x0"]) < MIN_PIECE:
			_err(rep, "end: deck piece y=%d x=%d..%d on %s is only %dpx" % [int(p["y"]), int(p["x0"]), int(p["x1"]), str(p["run"]), int(float(p["x1"]) - float(p["x0"]))])


static func _stair_at_foot(x: float, y: float, dir: int) -> bool:
	for s in HollowMap.stairs():
		if absf(float(s["foot_x"]) - x) < EPS and absf(float(s["foot_y"]) - y) < EPS and int(s["dir"]) == dir:
			return true
	return false


static func _stair_at_top(x: float, y: float, dir: int) -> bool:
	for s in HollowMap.stairs():
		if absf(float(s["top_x"]) - x) < EPS and absf(float(s["top_y"]) - y) < EPS and int(s["dir"]) == dir:
			return true
	return false


static func _joined(run: Dictionary, x: float) -> bool:
	for o in HollowMap.runs():
		if o["id"] == run["id"] or absf(float(o["y"]) - float(run["y"])) > EPS:
			continue
		if absf(float(o["x0"]) - x) < EPS or absf(float(o["x1"]) - x) < EPS:
			return true
	return false


## Stepped halls: whole tiles, inside the civic cavity and clear of the Mouth, and nothing from a level above the
## hall's top level reaches down into it. The steps inside are ordinary runs and stairs the other rules check.
static func _check_halls(rep: Dictionary) -> void:
	for h in HollowMap.halls():
		var id := str(h["id"])
		var x0: float = h["x0"]
		var x1: float = h["x1"]
		var kt: float = h["k_top"]
		var kb: float = h["k_bottom"]
		if kb <= kt:
			_err(rep, "hall: %s must reach at least one level down" % id)
		if fposmod(x0, 16.0) > EPS or fposmod(x1, 16.0) > EPS:
			_err(rep, "hall: %s is not on 16px tiles" % id)
		if x0 < HollowMap.WEST_WALL + EPS or x1 > HollowMap.EAST_WALL - EPS:
			_err(rep, "hall: %s is not wholly inside the civic cavity" % id)
		if x1 > HollowMap.MOUTH_L + EPS and x0 < HollowMap.MOUTH_R - EPS:
			_err(rep, "hall: %s overlaps the Mouth" % id)
		if not HollowMap.nothing_above(kt, x0, x1):
			_err(rep, "hall: %s has a street directly above it; a hall needs solid rock above its ceiling" % id)
		var inside := 0
		for r in HollowMap.runs():
			if float(r["k"]) >= kt - 0.01 and float(r["k"]) <= kb + 0.01 and float(r["x0"]) < x1 and float(r["x1"]) > x0:
				inside += 1
		if inside < 2:
			_err(rep, "hall: %s has no steps in it (needs at least two runs on its levels)" % id)


## Doors: on a dy-0 piece of an existing run, inside it (not at an end), clear of flights, shafts and gates.
static func _check_doors(rep: Dictionary) -> void:
	for d in HollowMap.doors():
		var id := str(d["id"])
		var x: float = d["x"]
		var r := HollowMap.run_by_id(d["run"])
		if r.is_empty():
			_err(rep, "door: %s is on unknown run %s" % [id, str(d["run"])])
			continue
		if absf(float(r["dy"])) > EPS:
			_err(rep, "door: %s is on terrace piece %s; doors go on band-line pieces" % [id, str(d["run"])])
		if x < float(r["x0"]) + 96.0 or x > float(r["x1"]) - 96.0:
			_err(rep, "door: %s at x=%d is too close to the end of %s" % [id, int(x), str(d["run"])])
		if fposmod(x, 16.0) > EPS:
			_err(rep, "door: %s at x=%d is not on a tile" % [id, int(x)])
		var y: float = r["y"]
		for s in HollowMap.stairs():
			if absf(float(s["foot_y"]) - y) < EPS or absf(float(s["top_y"]) - y) < EPS:
				var lo := minf(float(s["foot_x"]), float(s["top_x"])) - 128.0
				var hi := maxf(float(s["foot_x"]), float(s["top_x"])) + 128.0
				if x > lo and x < hi:
					_err(rep, "door: %s at x=%d is too near stair %s" % [id, int(x), str(s["id"])])
		for l in HollowMap.ladders():
			if (absf(float(l["top_y"]) - y) < EPS or absf(float(l["bottom_y"]) - y) < EPS) and absf(float(l["open_x"]) + 32.0 - x) < 96.0:
				_err(rep, "door: %s at x=%d stands in ladder %s's shaft" % [id, int(x), str(l["id"])])
		for lf in HollowMap.lifts():
			if (lf["stops"] as Array).has(y) and x > float(lf["open_x"]) - 96.0 and x < float(lf["open_x"]) + float(lf["width"]) + 96.0:
				_err(rep, "door: %s at x=%d stands in lift %s's shaft" % [id, int(x), str(lf["id"])])
		for g in HollowMap.gates():
			if g["run"] == d["run"] and absf(float(g["x"]) - x) < 96.0:
				_err(rep, "door: %s at x=%d is on top of gate %s" % [id, int(x), str(g["id"])])


## Domes: carved up into the rock over one room, whole tiles, and only where nothing is built above the room
## in that stretch (the dome reaches up to 192 px past the ceiling, into the level above's floor).
static func _check_domes(rep: Dictionary) -> void:
	for dome in HollowMap.domes():
		var id := str(dome["id"])
		var k: float = dome["k"]
		var x0: float = dome["x0"]
		var x1: float = dome["x1"]
		var bands := 2 * int(dome["n"]) - 1
		var band_w := (x1 - x0) / float(bands)
		var h: float = dome["height"]
		# a dome may rise until 96 px of rock is left under the nearest street above it (192 px when that is far)
		var base_y := HollowMap.lvl(k) - HollowMap.ROOM_HEIGHT
		var cap := 192.0
		var lowest_underside := -1.0e9
		for r in HollowMap.runs():
			if float(r["k"]) < k - 0.01 and float(r["x0"]) < x1 and float(r["x1"]) > x0:
				lowest_underside = maxf(lowest_underside, float(r["y"]) + HollowMap.FLOOR_THICK)
		if lowest_underside > -1.0e8:
			var room := base_y - lowest_underside - 96.0
			cap = minf(384.0, room) if room >= 192.0 else room
		if h < 16.0 or h > cap or fposmod(h / float(dome["n"]), 16.0) > EPS:
			_err(rep, "dome: %s height %d must be 16-%d px in whole tiles per step (96 px of rock must stay under the street above)" % [id, int(h), int(cap)])
		if fposmod(band_w, 16.0) > EPS or fposmod(x0, 16.0) > EPS:
			_err(rep, "dome: %s bands are %.1fpx wide; they must be whole tiles" % [id, band_w])
		if not _covered_by_pieces(k, x0, x1):
			_err(rep, "dome: %s is not wholly over the street of level %d" % [id, int(k)])
		if not HollowMap.nothing_above(k, x0, x1):
			_err(rep, "dome: %s has a street above it; a dome needs solid rock to rise into" % id)
		if HollowMap.lvl(k) - HollowMap.ROOM_HEIGHT - h < MIN_FIRMAMENT:
			_err(rep, "dome: %s leaves the Firmament under %d px thick" % [id, int(MIN_FIRMAMENT)])


## True when the pieces of band k together cover x0..x1 with no gap wider than a flight (<= 96 px).
static func _covered_by_pieces(k: float, x0: float, x1: float) -> bool:
	var spans: Array = []
	for r in HollowMap.runs():
		if float(r["k"]) == k and not bool(r["landing"]):
			spans.append([float(r["x0"]), float(r["x1"])])
	spans.sort_custom(func(a, b): return a[0] < b[0])
	var cur := x0
	for sp in spans:
		if sp[1] <= cur:
			continue
		if sp[0] > cur + 96.0:
			return false
		cur = maxf(cur, sp[1])
		if cur >= x1:
			return true
	return cur >= x1


## Arched roofs: shallow enough to leave 160 px of air, whole tiles, over a band-line deck in a civic room,
## and clear of every shaft and flight that passes through the room.
static func _check_roofs(rep: Dictionary) -> void:
	for roof in HollowMap.roofs():
		var id := str(roof["id"])
		var k: float = roof["k"]
		var x0: float = roof["x0"]
		var x1: float = roof["x1"]
		var depth: float = roof["depth"]
		var bands := 2 * int(roof["n"]) - 1
		var band_w := (x1 - x0) / float(bands)
		if depth < 16.0 or depth > HollowMap.ROOM_HEIGHT - 160.0 + EPS or fposmod(depth, 16.0) > EPS or fposmod(depth * 1.0 / float(roof["n"]), 16.0) > EPS:
			_err(rep, "roof: %s depth %d must be whole tiles per step and leave 160px of air" % [id, int(depth)])
		if fposmod(band_w, 16.0) > EPS or fposmod(x0, 16.0) > EPS:
			_err(rep, "roof: %s bands are %.1fpx wide; they must be whole tiles" % [id, band_w])
		if x0 < HollowMap.WEST_WALL + EPS or x1 > HollowMap.EAST_WALL - EPS:
			_err(rep, "roof: %s is not wholly inside the civic cavity" % id)
		var deck := HollowMap.lvl(k)
		if not _covers(deck, x0, x1):
			_err(rep, "roof: %s is not wholly over one band-line deck at level %d" % [id, int(k)])
		var room_top := deck - HollowMap.ROOM_HEIGHT
		for l in HollowMap.ladders():
			if float(l["top_y"]) < deck - EPS and float(l["bottom_y"]) > room_top + EPS and float(l["open_x"]) - 16.0 < x1 and float(l["open_x"]) + HollowMap.SHAFT_OPENING + 16.0 > x0:
				_err(rep, "roof: %s hangs in ladder %s's shaft" % [id, str(l["id"])])
		for lf in HollowMap.lifts():
			var stops: Array = lf["stops"]
			if float(stops[0]) < deck - EPS and float(stops[stops.size() - 1]) > room_top + EPS and float(lf["open_x"]) - 16.0 < x1 and float(lf["open_x"]) + float(lf["width"]) + 16.0 > x0:
				_err(rep, "roof: %s hangs in lift %s's shaft" % [id, str(lf["id"])])
		for s in HollowMap.stairs():
			var lo := minf(float(s["foot_x"]), float(s["top_x"]))
			var hi := maxf(float(s["foot_x"]), float(s["top_x"]))
			if float(s["top_y"]) < deck - EPS and float(s["foot_y"]) > room_top + EPS and lo < x1 and hi > x0:
				_err(rep, "roof: %s hangs over the flight of stair %s" % [id, str(s["id"])])


## Warning, not an error (variety-pass decision 4): a long run with no step, landing or terrace in it.
static func _check_flat(rep: Dictionary) -> void:
	var plain := HollowMap.plain_runs()
	for r in HollowMap.runs():
		if HollowMap.is_heart_zone(r["zone"]) or plain.has(r["id"]):
			continue
		var len := float(r["x1"]) - float(r["x0"])
		if len > MAX_FLAT:
			rep["warnings"].append("flat: %s is %dpx unbroken (over %d): add a step, landing or terrace, or list it in HollowMap.plain_runs()" % [run_label(r), int(len), int(MAX_FLAT)])


## True when x is within a stepped hall (closed interval) whose levels include k.
static func _in_hall(k: float, x: float) -> bool:
	for h in HollowMap.halls():
		if k >= float(h["k_top"]) - 0.01 and k <= float(h["k_bottom"]) + 0.01 and x >= float(h["x0"]) - EPS and x <= float(h["x1"]) + EPS:
			return true
	return false


static func _check_ends(rep: Dictionary) -> void:
	for r in HollowMap.runs():
		var x0: float = r["x0"]
		var x1: float = r["x1"]
		var y: float = r["y"]
		match r["l"]:
			HollowMap.END_WALL:
				pass
			HollowMap.END_MOUTH:
				if absf(x0 - HollowMap.MOUTH_R) > EPS:
					_err(rep, "end: %s claims a Mouth lip on its left at x=%d; the east lip is x=%d" % [run_label(r), int(x0), int(HollowMap.MOUTH_R)])
			HollowMap.END_OPEN:
				if not _in_hall(float(r["k"]), x0):
					_err(rep, "end: %s says its left end is open, but x=%d is not inside a stepped hall on its level" % [run_label(r), int(x0)])
			HollowMap.END_LEDGE:
				var lmax := HollowMap.ledge_max(float(r["k"]))
				if not (x0 >= HollowMap.MOUTH_R - lmax - EPS and x0 < HollowMap.MOUTH_R - EPS):
					_err(rep, "end: %s claims a Mouth ledge on its left at x=%d; on level %s it must reach 1..%dpx out from the east lip (x=%d)" % [run_label(r), int(x0), str(r["k"]), int(lmax), int(HollowMap.MOUTH_R)])
			HollowMap.END_ROCK:
				if not (x0 >= HollowMap.ENV_LEFT + MIN_FLANK_BEYOND - EPS and x0 < HollowMap.WEST_WALL):
					_err(rep, "end: %s claims rock at x=%d, outside the west flank" % [run_label(r), int(x0)])
			HollowMap.END_FOOT:
				if not _stair_at_foot(x0, y, -1):
					_err(rep, "end: %s says its left end is a stair foot, but no stair rises west from there" % run_label(r))
			HollowMap.END_TOP:
				if not _stair_at_top(x0, y, 1):
					_err(rep, "end: %s says its left end is a stair top, but no stair arrives there heading east" % run_label(r))
			HollowMap.END_JOIN:
				if not _joined(r, x0):
					_err(rep, "end: %s says it joins a neighbour on the left, but nothing touches it" % run_label(r))
			_:
				_err(rep, "end: %s has no left end type" % run_label(r))
		match r["r"]:
			HollowMap.END_WALL:
				pass
			HollowMap.END_MOUTH:
				if absf(x1 - HollowMap.MOUTH_L) > EPS:
					_err(rep, "end: %s claims a Mouth lip on its right at x=%d; the west lip is x=%d" % [run_label(r), int(x1), int(HollowMap.MOUTH_L)])
			HollowMap.END_OPEN:
				if not _in_hall(float(r["k"]), x1):
					_err(rep, "end: %s says its right end is open, but x=%d is not inside a stepped hall on its level" % [run_label(r), int(x1)])
			HollowMap.END_LEDGE:
				var lmax := HollowMap.ledge_max(float(r["k"]))
				if not (x1 > HollowMap.MOUTH_L + EPS and x1 <= HollowMap.MOUTH_L + lmax + EPS):
					_err(rep, "end: %s claims a Mouth ledge on its right at x=%d; on level %s it must reach 1..%dpx out from the west lip (x=%d)" % [run_label(r), int(x1), str(r["k"]), int(lmax), int(HollowMap.MOUTH_L)])
			HollowMap.END_ROCK:
				if not (x1 > HollowMap.EAST_WALL - EPS and x1 <= HollowMap.ENV_RIGHT - MIN_FLANK_BEYOND + EPS):
					_err(rep, "end: %s claims rock at x=%d, outside the east flank" % [run_label(r), int(x1)])
			HollowMap.END_FOOT:
				if not _stair_at_foot(x1, y, 1):
					_err(rep, "end: %s says its right end is a stair foot, but no stair rises east from there" % run_label(r))
			HollowMap.END_TOP:
				if not _stair_at_top(x1, y, -1):
					_err(rep, "end: %s says its right end is a stair top, but no stair arrives there heading west" % run_label(r))
			HollowMap.END_JOIN:
				if not _joined(r, x1):
					_err(rep, "end: %s says it joins a neighbour on the right, but nothing touches it" % run_label(r))
			_:
				_err(rep, "end: %s has no right end type" % run_label(r))


static func _check_stairs(rep: Dictionary) -> void:
	var runs := HollowMap.runs()
	for s in HollowMap.stairs():
		var id := str(s["id"])
		var fx: float = s["foot_x"]
		var fy: float = s["foot_y"]
		var tx: float = s["top_x"]
		var ty: float = s["top_y"]
		var dir: int = s["dir"]
		var lo := minf(fx, tx)
		var hi := maxf(fx, tx)
		var foot_ok := false
		for r in runs:
			var ry: float = r["y"]
			var overlaps: bool = float(r["x0"]) < hi - EPS and float(r["x1"]) > lo + EPS
			if absf(ry - fy) < EPS:
				if (dir > 0 and absf(float(r["x1"]) - fx) < EPS) or (dir < 0 and absf(float(r["x0"]) - fx) < EPS):
					foot_ok = true
				elif overlaps:
					_err(rep, "stair: %s wedge [%d..%d] overlaps %s" % [id, int(lo), int(hi), run_label(r)])
			elif ry > ty + EPS and ry < fy - EPS and overlaps:
				_err(rep, "stair: %s flight crosses %s" % [id, run_label(r)])
		if not foot_ok:
			_err(rep, "stair: %s foot (%d,%d) has no run ending there on its open side" % [id, int(fx), int(fy)])
		var landed := false
		for p in HollowMap.deck_pieces():
			if absf(float(p["y"]) - ty) < EPS and float(p["x0"]) <= tx + EPS and float(p["x1"]) >= tx - EPS:
				landed = true
		if not landed:
			_err(rep, "stair: %s arrives at (%d,%d) but no deck is there" % [id, int(tx), int(ty)])


static func _covers(y: float, x0: float, x1: float) -> bool:
	for r in HollowMap.runs():
		if absf(float(r["y"]) - y) < EPS and float(r["x0"]) <= x0 + EPS and float(r["x1"]) >= x1 - EPS:
			return true
	return false


static func _check_ladders(rep: Dictionary) -> void:
	for l in HollowMap.ladders():
		var x0: float = l["open_x"]
		var x1 := x0 + HollowMap.SHAFT_OPENING
		var id := str(l["id"])
		if not _covers(l["top_y"], x0, x1):
			_err(rep, "ladder: %s has no deck at its top (y=%d) to step off onto" % [id, int(l["top_y"])])
		if not _covers(l["bottom_y"], x0, x1):
			_err(rep, "ladder: %s has no deck at its bottom (y=%d) to land on" % [id, int(l["bottom_y"])])
		for r in HollowMap.runs():
			var y: float = r["y"]
			if y > float(l["top_y"]) + EPS and y < float(l["bottom_y"]) - EPS and float(r["x0"]) < x1 and float(r["x1"]) > x0 and not _covers(y, x0, x1):
				_err(rep, "ladder: %s clips the end of %s" % [id, run_label(r)])


static func _check_lifts(rep: Dictionary) -> void:
	for lf in HollowMap.lifts():
		var id := str(lf["id"])
		var x0: float = lf["open_x"]
		var w: float = lf["width"]
		var x1 := x0 + w
		var stops: Array = lf["stops"]
		if not [HollowMap.LIFT_FREIGHT_WIDTH, HollowMap.LIFT_PREMIUM_WIDTH].has(w):
			_err(rep, "lift: %s has width %d, which is not a freight or premium cab" % [id, int(w)])
		if fposmod(x0, 16.0) > EPS or fposmod(w, 16.0) > EPS:
			_err(rep, "lift: %s is not on 16px tiles" % id)
		if stops.size() < 2:
			_err(rep, "lift: %s needs at least two stops" % id)
			continue
		for y in stops:
			if not _covers(y, x0, x1):
				_err(rep, "lift: %s has no deck under the whole cab at its stop y=%d" % [id, int(y)])
		var lo: float = stops[0]
		var hi: float = stops[stops.size() - 1]
		for r in HollowMap.runs():
			var y: float = r["y"]
			if y > lo + EPS and y < hi - EPS and not stops.has(y) and float(r["x0"]) < x1 and float(r["x1"]) > x0:
				_err(rep, "lift: %s passes through %s without a stop there" % [id, run_label(r)])
		for s in HollowMap.stairs():
			var slo := minf(float(s["foot_x"]), float(s["top_x"]))
			var shi := maxf(float(s["foot_x"]), float(s["top_x"]))
			if slo < x1 + 16.0 and shi > x0 - 16.0 and float(s["top_y"]) < hi - EPS and float(s["foot_y"]) > lo + EPS:
				_err(rep, "lift: %s shaft is crossed by the flight of stair %s" % [id, str(s["id"])])
		for l in HollowMap.ladders():
			if float(l["open_x"]) < x1 + 16.0 and float(l["open_x"]) + HollowMap.SHAFT_OPENING > x0 - 16.0 and float(l["top_y"]) < hi - EPS and float(l["bottom_y"]) > lo + EPS:
				_err(rep, "lift: %s shares its shaft with ladder %s" % [id, str(l["id"])])
		if lf["gate"] != &"":
			var found := false
			for g in HollowMap.gates():
				if g["id"] == lf["gate"]:
					found = true
			if not found:
				_err(rep, "lift: %s names gate %s, which does not exist" % [id, str(lf["gate"])])


## Zones that only a lift reaches: with every lift ignored (gates open) none of their decks may be reachable.
static func _check_lift_only(rep: Dictionary) -> void:
	var g := build_graph(true, false)
	var nodes: Array = g["nodes"]
	var s := spawn_node(nodes)
	if s == -1:
		return
	var reach := _reach_set(g["adj"], s)
	var only := HollowMap.lift_only_zones()
	for i in nodes.size():
		var n: Dictionary = nodes[i]
		var z := zone_of(Vector2(float(n["x0"]) + 8.0, float(n["y"]) - 32.0))
		if only.has(z) and reach.has(i):
			_err(rep, "lift_only: deck %s (zone %s) is reachable without a lift" % [str(n["run"]), str(z)])


static func _check_gates(rep: Dictionary) -> void:
	for g in HollowMap.gates():
		var r := HollowMap.run_by_id(g["run"])
		if r.is_empty():
			_err(rep, "gate: %s is on unknown run %s" % [str(g["id"]), str(g["run"])])
			continue
		var x: float = g["x"]
		if x < float(r["x0"]) - EPS or x > float(r["x1"]) + EPS:
			_err(rep, "gate: %s at x=%d is outside %s" % [str(g["id"]), int(x), run_label(r)])
		if g["blocks"]:
			for l in HollowMap.ladders():
				if absf(float(l["open_x"]) + 32.0 - x) < 64.0 and float(r["y"]) >= float(l["top_y"]) - EPS and float(r["y"]) <= float(l["bottom_y"]) + EPS:
					_err(rep, "gate: %s at x=%d stands on ladder %s" % [str(g["id"]), int(x), str(l["id"])])
	for g in HollowMap.gates():
		if not g["blocks"]:
			continue
		var gr2 := HollowMap.run_by_id(g["run"])
		for lf in HollowMap.lifts():
			if (lf["stops"] as Array).has(gr2["y"]) and float(g["x"]) > float(lf["open_x"]) - 48.0 and float(g["x"]) < float(lf["open_x"]) + float(lf["width"]) + 48.0:
				_err(rep, "gate: %s at x=%d stands on lift %s" % [str(g["id"]), int(g["x"]), str(lf["id"])])
	for id in HollowMap.closed_at_start():
		var known := false
		for g in HollowMap.gates():
			if g["id"] == id:
				known = true
		if not known:
			_err(rep, "gate: closed_at_start names %s, which does not exist" % str(id))


## The bulging cliff faces stay out of every deck, ledge, flight, ladder and Mid Heart: they only ever fill rock rows.
static func _check_cliff(rep: Dictionary) -> void:
	var bulges := HollowMap.cliff_bulges()
	for row in bulges.keys():
		var b: Vector2 = bulges[row]
		if b == Vector2.ZERO:
			continue
		var y0 := float(row) * 16.0
		var west := Rect2(HollowMap.MOUTH_L, y0, b.x, 16.0)
		var east := Rect2(HollowMap.MOUTH_R - b.y, y0, b.y, 16.0)
		for r in HollowMap.runs():
			var deck := Rect2(float(r["x0"]), float(r["y"]) - HollowMap.ROOM_HEIGHT, float(r["x1"]) - float(r["x0"]), HollowMap.ROOM_HEIGHT + HollowMap.FLOOR_THICK)
			if (b.x > 0.0 and west.intersects(deck)) or (b.y > 0.0 and east.intersects(deck)):
				_err(rep, "cliff: a cliff bulge at row %d overlaps %s" % [int(row), run_label(r)])
				return
		for st in HollowMap.stairs():
			var wedge := Rect2(minf(st["foot_x"], st["top_x"]), float(st["top_y"]) - 112.0, absf(float(st["top_x"]) - float(st["foot_x"])), absf(float(st["foot_y"]) - float(st["top_y"])) + 112.0)
			if (b.x > 0.0 and west.intersects(wedge)) or (b.y > 0.0 and east.intersects(wedge)):
				_err(rep, "cliff: a cliff bulge at row %d overlaps stair %s" % [int(row), str(st["id"])])
				return


static func _check_mouth(rep: Dictionary) -> void:
	var crossing := false
	for p in HollowMap.deck_pieces():
		var inside: bool = float(p["x1"]) > HollowMap.MOUTH_L + EPS and float(p["x0"]) < HollowMap.MOUTH_R - EPS
		var run := HollowMap.run_by_id(p["run"])
		# a short ledge off a lip is allowed (USER 2026-10-02): the run says so with END_LEDGE, and it stays under LEDGE_MAX
		var lmax := HollowMap.ledge_max(float(run["k"]))
		var west_ledge: bool = run["r"] == HollowMap.END_LEDGE and float(p["x0"]) <= HollowMap.MOUTH_L + EPS and float(p["x1"]) <= HollowMap.MOUTH_L + lmax + EPS
		var east_ledge: bool = run["l"] == HollowMap.END_LEDGE and float(p["x1"]) >= HollowMap.MOUTH_R - EPS and float(p["x0"]) >= HollowMap.MOUTH_R - lmax - EPS
		if inside and not HollowMap.is_heart_zone(run["zone"]) and not west_ledge and not east_ledge:
			_err(rep, "mouth: deck %s y=%d x=%d..%d is over the Devil's Mouth but is not Mid Heart or a ledge of at most %dpx" % [str(p["run"]), int(p["y"]), int(p["x0"]), int(p["x1"]), int(lmax)])
	for s in HollowMap.stairs():
		var lo := minf(float(s["foot_x"]), float(s["top_x"]))
		var hi := maxf(float(s["foot_x"]), float(s["top_x"]))
		if hi > HollowMap.MOUTH_L + EPS and lo < HollowMap.MOUTH_R - EPS and not HollowMap.is_heart_zone(s["zone"]):
			_err(rep, "mouth: stair %s is over the Devil's Mouth but is not Mid Heart" % str(s["id"]))
	for l in HollowMap.ladders():
		if float(l["open_x"]) > HollowMap.MOUTH_L - 64.0 and float(l["open_x"]) < HollowMap.MOUTH_R:
			_err(rep, "mouth: ladder %s is over the Devil's Mouth" % str(l["id"]))
	# Mid Heart must actually cross: west lip run to east lip run through its own decks and stairs.
	var g := build_graph(true)
	var nodes: Array = g["nodes"]
	var west := -1
	var east := -1
	for i in nodes.size():
		var n: Dictionary = nodes[i]
		if absf(float(n["y"]) - HollowLayout.HEART_Y) < EPS:
			if absf(float(n["x1"]) - HollowMap.MOUTH_L) < EPS or (float(n["x0"]) <= HollowMap.MOUTH_L and float(n["x1"]) > HollowMap.MOUTH_L):
				if HollowMap.is_heart_zone(HollowMap.run_by_id(n["run"])["zone"]):
					west = i
			if float(n["x1"]) >= HollowMap.MOUTH_R - EPS and HollowMap.is_heart_zone(HollowMap.run_by_id(n["run"])["zone"]):
				east = i
	if west == -1 or east == -1:
		_err(rep, "mouth: Mid Heart has no west or east raft touching the lips")
		return
	# BFS restricted to Mid Heart nodes.
	var heart_nodes: Dictionary = {}
	for i in nodes.size():
		if HollowMap.is_heart_zone(HollowMap.run_by_id(nodes[i]["run"])["zone"]):
			heart_nodes[i] = true
	var seen := {west: true}
	var queue: Array[int] = [west]
	while not queue.is_empty():
		var c: int = queue.pop_front()
		for nb in g["adj"][c]:
			if heart_nodes.has(nb) and not seen.has(nb):
				seen[nb] = true
				queue.append(nb)
	crossing = seen.has(east)
	if not crossing:
		_err(rep, "mouth: Mid Heart's own decks and stairs do not connect the west lip to the east lip")


static func _check_reserves(rep: Dictionary) -> void:
	for rs in HollowMap.reserves():
		var rect: Rect2 = rs["rect"]
		var id := str(rs["id"])
		for r in HollowMap.runs():
			var deck := Rect2(float(r["x0"]), float(r["y"]) - HollowMap.ROOM_HEIGHT, float(r["x1"]) - float(r["x0"]), HollowMap.ROOM_HEIGHT + HollowMap.FLOOR_THICK)
			if rect.intersects(deck):
				_err(rep, "reserve: %s overlaps %s" % [id, run_label(r)])
		for w in HollowMap.wall_rects():
			if rect.intersects(w):
				_err(rep, "reserve: %s overlaps a wall" % id)
		for s in HollowMap.stairs():
			var wedge := Rect2(minf(s["foot_x"], s["top_x"]), s["top_y"], absf(float(s["top_x"]) - float(s["foot_x"])), float(s["foot_y"]) - float(s["top_y"]))
			if rect.intersects(wedge):
				_err(rep, "reserve: %s overlaps stair %s" % [id, str(s["id"])])
		var touches := false
		for r in HollowMap.runs():
			if r["zone"] != rs["district"]:
				continue
			var near := Rect2(float(r["x0"]) - 40.0, float(r["y"]) - HollowMap.ROOM_HEIGHT, float(r["x1"]) - float(r["x0"]) + 80.0, HollowMap.ROOM_HEIGHT + HollowMap.FLOOR_THICK)
			if rect.intersects(near):
				touches = true
		if not touches:
			_err(rep, "reserve: %s does not touch any %s run" % [id, str(rs["district"])])


static func _deck_under(p: Vector2) -> int:
	var pieces := HollowMap.deck_pieces()
	for i in pieces.size():
		if absf(float(pieces[i]["y"]) - p.y) < EPS and p.x >= float(pieces[i]["x0"]) - EPS and p.x <= float(pieces[i]["x1"]) + EPS:
			return i
	return -1


static func _check_zones(rep: Dictionary) -> void:
	var zones := HollowMap.zones()
	for i in zones.size():
		var a: Dictionary = zones[i]
		var ra: Rect2 = a["rect"]
		for j in range(i + 1, zones.size()):
			var b: Dictionary = zones[j]
			if a.get("volume", false) or b.get("volume", false):
				continue
			if ra.intersects(b["rect"]):
				_err(rep, "zone: '%s' and '%s' overlap" % [str(a["id"]), str(b["id"])])
		if a.get("volume", false):
			continue
		var anchor: Vector2 = a["anchor"]
		if _deck_under(anchor) == -1:
			_err(rep, "zone: '%s' anchor (%d,%d) does not stand on a deck piece" % [str(a["id"]), int(anchor.x), int(anchor.y)])
		if not ra.has_point(anchor):
			_err(rep, "zone: '%s' rect does not contain its anchor" % str(a["id"]))
	for p in HollowMap.deck_pieces():
		for sample in [float(p["x0"]) + 32.0, (float(p["x0"]) + float(p["x1"])) * 0.5, float(p["x1"]) - 32.0]:
			var pt := Vector2(sample, float(p["y"]) - 32.0)
			var inside := false
			for z in zones:
				if not z.get("volume", false) and (z["rect"] as Rect2).has_point(pt):
					inside = true
			if not inside:
				_err(rep, "zone: deck %s (y=%d) has no zone at x=%d" % [str(p["run"]), int(p["y"]), int(sample)])
				break


## Walk graph over deck pieces. Ladders and stairs link pieces both ways; closed gates
## split the piece they stand on. Falling is never an edge (a fall is a rescue, not a route).
static func build_graph(open_gates: bool, use_lifts: bool = true) -> Dictionary:
	var nodes: Array[Dictionary] = []
	var closed: Array = HollowMap.closed_at_start()
	for p in HollowMap.deck_pieces():
		var cuts: Array[float] = []
		if not open_gates:
			for g in HollowMap.gates():
				if g["blocks"] and closed.has(g["id"]):
					var gr := HollowMap.run_by_id(g["run"])
					if gr["id"] == p["run"] and float(g["x"]) > float(p["x0"]) and float(g["x"]) < float(p["x1"]):
						cuts.append(float(g["x"]))
		cuts.sort()
		var start: float = p["x0"]
		for c in cuts:
			nodes.append({"run": p["run"], "x0": start, "x1": c, "y": p["y"]})
			start = c
		nodes.append({"run": p["run"], "x0": start, "x1": p["x1"], "y": p["y"]})
	var adj: Array = []
	for i in nodes.size():
		adj.append([])
	var link := func(a: int, b: int) -> void:
		if a >= 0 and b >= 0 and a != b:
			if not adj[a].has(b):
				adj[a].append(b)
			if not adj[b].has(a):
				adj[b].append(a)
	var find := func(y: float, x: float, side: int) -> int:
		# side -1: node whose right end touches x; +1: node whose left end touches x; 0: contains x
		for i in nodes.size():
			var n: Dictionary = nodes[i]
			if absf(float(n["y"]) - y) > EPS:
				continue
			if side < 0 and absf(float(n["x1"]) - x) < EPS:
				return i
			if side > 0 and absf(float(n["x0"]) - x) < EPS:
				return i
			if side == 0 and float(n["x0"]) - EPS <= x and float(n["x1"]) + EPS >= x:
				return i
		return -1
	# Runs that meet end to end (Wickwork into Mid Heart) are one walkway.
	for i in nodes.size():
		for j in range(i + 1, nodes.size()):
			var na: Dictionary = nodes[i]
			var nb: Dictionary = nodes[j]
			if na["run"] != nb["run"] and absf(float(na["y"]) - float(nb["y"])) < EPS:
				if absf(float(na["x1"]) - float(nb["x0"])) < EPS or absf(float(nb["x1"]) - float(na["x0"])) < EPS:
					link.call(i, j)
	# Ladders: decks are one-way, so the shaft passes through them. Every deck that
	# covers the shaft at a served level is linked to the others.
	var shafts: Array[Dictionary] = []
	for l in HollowMap.ladders():
		shafts.append({"x": l["open_x"], "ys": [l["top_y"], l["bottom_y"]]})
	if use_lifts:
		for lf in HollowMap.lifts():
			if lf["gate"] != &"" and not open_gates and closed.has(lf["gate"]):
				continue
			shafts.append({"x": lf["open_x"], "w": lf["width"], "ys": lf["stops"]})
	for sh in shafts:
		var ox: float = sh["x"]
		var members: Array[int] = []
		for i in nodes.size():
			var n: Dictionary = nodes[i]
			if (sh["ys"] as Array).has(n["y"]) and float(n["x0"]) <= ox + EPS and float(n["x1"]) >= ox + float(sh.get("w", HollowMap.SHAFT_OPENING)) - EPS:
				members.append(i)
		for a2 in members:
			for b2 in members:
				link.call(a2, b2)
	# Stairs: the foot node, the node holding the top, and every street node over the flight's
	# last stretch (Down drops through a one-way deck onto the tread, up to DROP_REACH below).
	for s2 in HollowMap.stairs():
		var foot_node: int = find.call(s2["foot_y"], s2["foot_x"], -1 if int(s2["dir"]) > 0 else 1)
		var tx: float = s2["top_x"]
		link.call(foot_node, find.call(s2["top_y"], tx, 0))
		var hole_reach := maxf(HollowMap.stair_hole_length(s2), 112.0)
		var reach_lo := minf(tx, tx - float(s2["dir"]) * hole_reach)
		var reach_hi := maxf(tx, tx - float(s2["dir"]) * hole_reach)
		for i in nodes.size():
			var n2: Dictionary = nodes[i]
			if absf(float(n2["y"]) - float(s2["top_y"])) < EPS and float(n2["x0"]) < reach_hi and float(n2["x1"]) > reach_lo:
				link.call(foot_node, i)
	return {"nodes": nodes, "adj": adj}


static func _reach_set(adj: Array, start: int) -> Dictionary:
	var seen := {start: true}
	var queue: Array[int] = [start]
	while not queue.is_empty():
		var c: int = queue.pop_front()
		for nb in adj[c]:
			if not seen.has(nb):
				seen[nb] = true
				queue.append(nb)
	return seen


static func spawn_node(nodes: Array) -> int:
	var p := HollowLayout.player_spawn_point()
	for i in nodes.size():
		var n: Dictionary = nodes[i]
		if absf(float(n["y"]) - (p.y + 32.0)) < EPS and p.x >= float(n["x0"]) and p.x <= float(n["x1"]):
			return i
	return -1


static func _node_at(nodes: Array, p: Vector2) -> int:
	for i in nodes.size():
		var n: Dictionary = nodes[i]
		if absf(float(n["y"]) - p.y) < EPS and p.x >= float(n["x0"]) and p.x <= float(n["x1"]):
			return i
	return -1


static func zone_of(p: Vector2) -> StringName:
	for z in HollowMap.zones():
		if not z.get("volume", false) and (z["rect"] as Rect2).has_point(p):
			return z["id"]
	return &""


static func _check_reach(rep: Dictionary) -> void:
	var full := build_graph(true)
	var nodes: Array = full["nodes"]
	var s := spawn_node(nodes)
	if s == -1:
		_err(rep, "reach: player spawn does not stand on any deck")
		return
	var fwd := _reach_set(full["adj"], s)
	for i in nodes.size():
		if not fwd.has(i):
			var n: Dictionary = nodes[i]
			_err(rep, "reach: deck %s (y=%d x=%d..%d) cannot be reached from spawn even with every gate open" % [str(n["run"]), int(n["y"]), int(n["x0"]), int(n["x1"])])
	var closed := build_graph(false)
	var cn: Array = closed["nodes"]
	var cfwd := _reach_set(closed["adj"], spawn_node(cn))
	var early_seen: Dictionary = {}
	var sealed_zones: Dictionary = {}
	for i in cn.size():
		var n: Dictionary = cn[i]
		var sx: float = float(n["x0"]) + 8.0
		while sx < float(n["x1"]):
			var z := zone_of(Vector2(sx, float(n["y"]) - 32.0))
			if cfwd.has(i):
				early_seen[z] = true
			else:
				sealed_zones[z] = true
			sx += 160.0
	for z in HollowMap.early_zones():
		if not early_seen.has(z):
			_err(rep, "reach: zone '%s' is meant to be open at the start but is sealed behind a closed gate" % str(z))
	# Held points: sealed while gates are shut, reachable once open.
	var open_reach := _reach_set(full["adj"], s)
	for pt in HollowMap.held_points():
		var fi := _node_at(nodes, pt)
		var ci := _node_at(cn, pt)
		if fi == -1:
			_err(rep, "reach: held point (%d,%d) does not stand on a deck" % [int(pt.x), int(pt.y)])
			continue
		if not open_reach.has(fi):
			_err(rep, "reach: held point (%d,%d) is unreachable even with every gate open" % [int(pt.x), int(pt.y)])
		if ci != -1 and cfwd.has(ci):
			_err(rep, "reach: held point (%d,%d) is reachable at the start; its gate can be walked around" % [int(pt.x), int(pt.y)])
	var held: Array[String] = []
	for z in sealed_zones.keys():
		if not early_seen.has(z):
			held.append(str(z))
	held.sort()
	rep["info"].append("reach: held back until gates open: %s" % ", ".join(held))
	rep["reach"] = {"early": early_seen.keys(), "held": held}


static func _space_report(rep: Dictionary) -> void:
	var walk: Dictionary = {}
	var west := 0.0
	var east := 0.0
	for p in HollowMap.deck_pieces():
		var w := float(p["x1"]) - float(p["x0"])
		var mid := (float(p["x0"]) + float(p["x1"])) * 0.5
		var z := zone_of(Vector2(mid, float(p["y"]) - 32.0))
		walk[z] = float(walk.get(z, 0.0)) + w
		if mid < HollowMap.MOUTH_L:
			west += w
		elif mid > HollowMap.MOUTH_R:
			east += w
	var keys := walk.keys()
	keys.sort()
	var lines: Array[String] = []
	for k in keys:
		lines.append("%s %d" % [str(k), int(walk[k])])
	var ratio := east / maxf(west, 1.0)
	rep["info"].append("space: walkable deck length west %dpx, east %dpx (east/west %.2f) | %s" % [int(west), int(east), ratio, "; ".join(lines)])
	if ratio < 0.8 or ratio > 1.25:
		_err(rep, "space: east and west walls differ too much in walkable length (west %d, east %d)" % [int(west), int(east)])


## Spans a thing occupies along a deck, as [x0, x1].
static func _span(x: float, w: float) -> Vector2:
	return Vector2(x - w * 0.5, x + w * 0.5)


## Why a span on a level cannot hold dressing: a stair wedge, the street over a flight, a ladder or
## a closed gate bar. "" when it can.
static func _dress_conflict(span: Vector2, k: int, allow_shaft: bool) -> String:
	var y := HollowMap.deck_y_at((span.x + span.y) * 0.5, float(k))
	for s in HollowMap.stairs():
		var lo := minf(float(s["foot_x"]), float(s["top_x"]))
		var hi := maxf(float(s["foot_x"]), float(s["top_x"]))
		if absf(float(s["foot_y"]) - y) < EPS and span.x < hi and span.y > lo:
			return "stair %s's wedge" % str(s["id"])
		if absf(float(s["top_y"]) - y) < EPS:
			var tx: float = s["top_x"]
			var a := minf(tx, tx - float(s["dir"]) * 112.0)
			var b := maxf(tx, tx - float(s["dir"]) * 112.0)
			if span.x < b and span.y > a:
				return "the street over stair %s" % str(s["id"])
	if not allow_shaft:
		for l in HollowMap.ladders():
			if y >= float(l["top_y"]) - EPS and y <= float(l["bottom_y"]) + EPS:
				var ox: float = l["open_x"]
				if span.x < ox + HollowMap.SHAFT_OPENING + 16.0 and span.y > ox - 16.0:
					return "ladder %s's shaft" % str(l["id"])
	for g in HollowMap.gates():
		if not g["blocks"]:
			continue
		var gr := HollowMap.run_by_id(g["run"])
		if not gr.is_empty() and absf(float(gr["y"]) - y) < EPS and span.x < float(g["x"]) + 32.0 and span.y > float(g["x"]) - 32.0:
			return "gate %s" % str(g["id"])
	for lf in HollowMap.lifts():
		if (lf["stops"] as Array).has(y) and span.x < float(lf["open_x"]) + float(lf["width"]) + 48.0 and span.y > float(lf["open_x"]) - 48.0:
			return "lift %s's shaft" % str(lf["id"])
	for d in HollowMap.doors():
		var dr := HollowMap.run_by_id(d["run"])
		if not dr.is_empty() and absf(float(dr["y"]) - y) < EPS and span.x < float(d["x"]) + 72.0 and span.y > float(d["x"]) - 72.0 and not allow_shaft:
			return "door %s" % str(d["id"])
	return ""


## Height of the air above a deck at x: a room in the civic cavity, a carved gallery in a flank.
static func _ceiling_at(x: float) -> float:
	return (HollowMap.FLANK_CLEAR if HollowMap.in_flank(x) else HollowMap.ROOM_HEIGHT) - 8.0


static func _check_dressing(rep: Dictionary) -> void:
	var zone_ids: Dictionary = {}
	for z in HollowMap.zones():
		zone_ids[z["id"]] = true
	var label := func(kind: String, id: Variant, x: float, k: int) -> String:
		return "%s %s (x=%d level %d)" % [kind, str(id), int(x), k]
	for p in HollowDressing.props():
		var k: int = p["k"]
		var y := HollowMap.deck_y_at(float(p["x"]), float(k))
		var sp := _span(float(p["x"]), float(p["w"]))
		var who: String = label.call("prop", p["id"], p["x"], k)
		if not zone_ids.has(p["zone"]):
			_err(rep, "dress: %s names unknown zone %s" % [who, str(p["zone"])])
			continue
		if not _covers(y, float(p["x"]) - 1.0, float(p["x"]) + 1.0):
			_err(rep, "dress: %s does not stand on a deck" % who)
		elif zone_of(Vector2(float(p["x"]), y - 32.0)) != p["zone"]:
			_err(rep, "dress: %s is outside zone %s" % [who, str(p["zone"])])
		var ceiling := _ceiling_at(float(p["x"]))
		if float(p["y_off"]) + float(p["h"]) > ceiling:
			_err(rep, "dress: %s reaches the ceiling (%d of %d)" % [who, int(float(p["y_off"]) + float(p["h"])), int(ceiling)])
		var why := _dress_conflict(sp, k, false)
		if why != "":
			_err(rep, "dress: %s overlaps %s" % [who, why])
	for l in HollowDressing.lamps():
		var lk: int = l["k"]
		var lwho: String = label.call("lamp", l["zone"], l["x"], lk)
		if not _covers(HollowMap.deck_y_at(float(l["x"]), float(lk)), float(l["x"]) - 1.0, float(l["x"]) + 1.0):
			_err(rep, "dress: %s does not hang over a deck" % lwho)
		elif zone_of(Vector2(float(l["x"]), HollowMap.deck_y_at(float(l["x"]), float(lk)) - 32.0)) != l["zone"]:
			_err(rep, "dress: %s is outside zone %s" % [lwho, str(l["zone"])])
		if float(l["y_off"]) > _ceiling_at(float(l["x"])):
			_err(rep, "dress: %s hangs above the ceiling" % lwho)
	var seen_spans: Array[Dictionary] = []
	for b in HollowDressing.buildings():
		var bk: int = b["k"]
		var by := HollowMap.deck_y_at((float(b["x0"]) + float(b["x1"])) * 0.5, float(bk))
		var bwho: String = label.call("building", b["id"], b["x0"], bk)
		if not _covers(by, float(b["x0"]) + 1.0, float(b["x1"]) - 1.0):
			_err(rep, "dress: %s is not wholly over one deck" % bwho)
		if zone_of(Vector2(float(b["x0"]) + 8.0, by - 32.0)) != b["zone"] or zone_of(Vector2(float(b["x1"]) - 8.0, by - 32.0)) != b["zone"]:
			_err(rep, "dress: %s leaves zone %s" % [bwho, str(b["zone"])])
		var civic: bool = not HollowMap.in_flank(float(b["x0"])) and not HollowMap.in_flank(float(b["x1"]))
		var bceil := HollowMap.ROOM_HEIGHT if civic else minf(_ceiling_at(float(b["x0"])), _ceiling_at(float(b["x1"])))
		if float(b["height"]) + float(b["y_off"]) > bceil + EPS:
			_err(rep, "dress: %s is taller than the room" % bwho)
		var bwhy := _dress_conflict(Vector2(float(b["x0"]), float(b["x1"])), bk, true)
		if bwhy != "" and not str(bwhy).begins_with("gate") and not str(bwhy).begins_with("the street"):
			_err(rep, "dress: %s overlaps %s" % [bwho, bwhy])
		for o in seen_spans:
			var nested: bool = o["kind"] == &"nook" or b["kind"] == &"nook" or bool(o.get("overlay", false)) or bool(b.get("overlay", false)) # a nook is cut into a wall; an overlay stands in front of one
			if o["k"] == bk and not nested and float(o["x0"]) < float(b["x1"]) and float(b["x0"]) < float(o["x1"]):
				_err(rep, "dress: %s overlaps building %s" % [bwho, str(o["id"])])
		seen_spans.append(b)
		for dx in b["doors"]:
			if float(dx) < float(b["x0"]) or float(dx) > float(b["x1"]):
				_err(rep, "dress: %s has a door at x=%d outside itself" % [bwho, int(dx)])
	for a in HollowDressing.actors():
		var ak: int = a["k"]
		var ay := HollowMap.deck_y_at(float(a["x"]), float(ak))
		var awho: String = label.call("person", a["id"], a["x"], ak)
		var rng: float = a["range"]
		var asp := Vector2(float(a["x"]) - 16.0 - rng, float(a["x"]) + 16.0 + rng)
		if not _covers(ay, asp.x, asp.y):
			_err(rep, "dress: %s walks off the end of the deck" % awho)
		elif zone_of(Vector2(float(a["x"]), ay - 32.0)) != a["zone"]:
			_err(rep, "dress: %s is outside zone %s" % [awho, str(a["zone"])])
		var awhy := _dress_conflict(asp, ak, false)
		if awhy != "":
			_err(rep, "dress: %s stands in %s" % [awho, awhy])
		if not HollowDressing.ROLES.has(a["role"]):
			_err(rep, "dress: %s has unknown role %s" % [awho, str(a["role"])])
	var used: Array[Dictionary] = []
	for st in HollowDressing.stations():
		if bool(st.get("interior", false)):
			continue # stands in the home's room, not on a street
		var sk: int = st["k"]
		var swho: String = label.call("station", st["id"], st["x"], sk)
		if not _covers(HollowMap.deck_y_at(float(st["x"]), float(sk)), float(st["x"]) - 8.0, float(st["x"]) + 8.0):
			_err(rep, "dress: %s is not on a deck" % swho)
		elif zone_of(Vector2(float(st["x"]), HollowMap.deck_y_at(float(st["x"]), float(sk)) - 32.0)) != st["zone"]:
			_err(rep, "dress: %s is outside zone %s" % [swho, str(st["zone"])])
		var swhy := _dress_conflict(_span(float(st["x"]), 24.0), sk, false)
		if swhy != "":
			_err(rep, "dress: %s sits in %s" % [swho, swhy])
		for o2 in used:
			if o2["k"] == sk and absf(float(o2["x"]) - float(st["x"])) < 40.0:
				_err(rep, "dress: %s is within 40px of station %s (you could not pick one)" % [swho, str(o2["id"])])
		used.append(st)
	var thin: Array[String] = []
	for zone in HollowDressing.SLICE_ZONES.keys():
		var want: Dictionary = HollowDressing.SLICE_ZONES[zone]
		var have := HollowDressing.counts(zone)
		for key in ["props", "lamps", "actors"]:
			if int(have[key]) < int(want[key]):
				_err(rep, "dress: zone %s has %d %s, the slice needs %d" % [str(zone), int(have[key]), key, int(want[key])])
				thin.append(str(zone))
	rep["info"].append("dress: %d props, %d lamps, %d buildings, %d people, %d stations across %d slice zones" % [HollowDressing.props().size(), HollowDressing.lamps().size(), HollowDressing.buildings().size(), HollowDressing.actors().size(), HollowDressing.stations().size(), HollowDressing.SLICE_ZONES.size()])


## The shell: the Hollow is wrapped in diggable rock on every side but the pit.
static func _check_shell(rep: Dictionary) -> void:
	var env := HollowMap.env_rect()
	var cavity := HollowMap.cavity_rect()
	var pit := HollowMap.pit_rect()
	if HollowMap.ROCK_TOP < MIN_FIRMAMENT:
		_err(rep, "shell: the Firmament is only %dpx thick (min %d)" % [int(HollowMap.ROCK_TOP), int(MIN_FIRMAMENT)])
	if HollowMap.ROCK_BOTTOM < MIN_SLAB:
		_err(rep, "shell: the floor slab is only %dpx thick (min %d)" % [int(HollowMap.ROCK_BOTTOM), int(MIN_SLAB)])
	if HollowMap.SIDE_DEPTH < MIN_FLANK_BEYOND * 2.0:
		_err(rep, "shell: the side flanks are only %dpx deep (min %d)" % [int(HollowMap.SIDE_DEPTH), int(MIN_FLANK_BEYOND * 2.0)])
	if not env.encloses(cavity):
		_err(rep, "shell: the civic cavity is not inside the dig envelope")
	if absf(pit.size.x - (HollowMap.MOUTH_R - HollowMap.MOUTH_L)) > EPS or pit.end.y < env.end.y - EPS:
		_err(rep, "shell: the pit is not the full Mouth width open to the bottom of the envelope")
	for r in HollowMap.runs():
		var air := Rect2(float(r["x0"]), float(r["y"]) - HollowMap.ROOM_HEIGHT, float(r["x1"]) - float(r["x0"]), HollowMap.ROOM_HEIGHT + 16.0)
		var inside_cavity := cavity.encloses(air)
		var flank_run: bool = float(r["x0"]) < HollowMap.WEST_WALL - EPS or float(r["x1"]) > HollowMap.EAST_WALL + EPS
		if not flank_run and not inside_cavity:
			_err(rep, "shell: %s sticks out of the civic cavity (Firmament %d, floor slab %d)" % [run_label(r), int(HollowMap.ROCK_TOP), int(HollowMap.CAVITY_BOTTOM)])
		if float(r["y"]) - HollowMap.ROOM_HEIGHT < HollowMap.ROCK_TOP - EPS:
			_err(rep, "shell: %s has its room inside the Firmament" % run_label(r))
		if float(r["y"]) + 16.0 > HollowMap.CAVITY_BOTTOM + EPS:
			_err(rep, "shell: %s is below the floor of the cavity" % run_label(r))
		if float(r["x0"]) < env.position.x + MIN_FLANK_BEYOND - EPS and r["l"] != HollowMap.END_ROCK:
			_err(rep, "shell: %s starts too close to the west edge of the envelope" % run_label(r))
		if float(r["x0"]) < env.position.x + MIN_FLANK_BEYOND - EPS or float(r["x1"]) > env.end.x - MIN_FLANK_BEYOND + EPS:
			_err(rep, "shell: %s leaves less than %dpx of rock beyond its end" % [run_label(r), int(MIN_FLANK_BEYOND)])
	for z in HollowMap.zones():
		if z.get("volume", false) and not env.encloses(z["rect"]):
			_err(rep, "shell: volume '%s' is outside the dig envelope" % str(z["id"]))
	rep["info"].append("shell: envelope x %d..%d, y 0..%d; Firmament %dpx, floor slab %dpx, flanks %dpx past each wall" % [int(env.position.x), int(env.end.x), int(env.end.y), int(HollowMap.ROCK_TOP), int(HollowMap.ROCK_BOTTOM), int(HollowMap.SIDE_DEPTH)])


## ------------------------------------------------------------------ scene checks

## Solid tile layers only (dig rock, walls, treads). One-way decks are checked separately.
static func _layers(scene: Node) -> Array[TileMapLayer]:
	var layers: Array[TileMapLayer] = []
	for path in ["Terrain", "Hollow/HollowTerrain"]:
		var layer := scene.get_node_or_null(path) as TileMapLayer
		if layer != null:
			layers.append(layer)
	return layers


static func _deck_layer(scene: Node) -> TileMapLayer:
	return scene.get_node_or_null("Hollow/HollowTerrain/Decks") as TileMapLayer


static func _solid_at(layers: Array[TileMapLayer], x: float, y: float) -> bool:
	var cell := Vector2i(int(floor(x / 16.0)), int(floor(y / 16.0)))
	for layer in layers:
		if layer.get_cell_source_id(cell) != -1:
			return true
	return false


## The dressing builder made everything the data declares, where the data says.
static func _lint_dressing_scene(scene: Node, rep: Dictionary) -> void:
	var dressing := scene.get_node_or_null("Hollow/Dressing")
	if dressing == null:
		_err(rep, "scene: Hollow/Dressing is missing (props, people and stations are built there)")
		return
	var back_views := 0
	var rock_views := 0
	for child in dressing.get_children():
		if child.name.begins_with("View_back_"):
			back_views += 1
		elif child.name.begins_with("Rock_"):
			rock_views += 1
	if back_views == 0 or rock_views != back_views:
		_err(rep, "scene: the dressing was not built in chunks (%d drawing, %d rock)" % [back_views, rock_views])
	var npcs := scene.get_node_or_null("Hollow/NPCs")
	for a in HollowDressing.actors():
		var path := ("Talker_%s" % str(a["id"])) if bool(a["talk"]) else ("Person_%s" % str(a["id"]))
		var holder: Node = npcs if bool(a["talk"]) else dressing
		var node := holder.get_node_or_null(path) as Node2D if holder != null else null
		if node == null:
			_err(rep, "scene: person %s was not built" % str(a["id"]))
		elif absf(node.position.x - float(a["x"])) > float(a["range"]) + 14.0 or absf(node.position.y - (HollowMap.deck_y_at(float(a["x"]), float(a["k"])) - float(a["y_off"]))) > EPS:
			_err(rep, "scene: person %s stands at %s, the data says (%d, %d)" % [str(a["id"]), str(node.position), int(a["x"]), int(HollowMap.deck_y_at(float(a["x"]), float(a["k"])) - float(a["y_off"]))])
	for s in HollowDressing.stations():
		var home := scene.get_node_or_null("HomeInterior")
		var st := (home.get_node_or_null("Station_%s" % str(s["id"])) if bool(s.get("interior", false)) and home != null else dressing.get_node_or_null("Station_%s" % str(s["id"]))) as Node2D
		if st == null:
			_err(rep, "scene: station %s was not built" % str(s["id"]))
		elif not st.has_method("get_interact_prompt") and not st.has_method("on_interact"):
			_err(rep, "scene: station %s is not an interactable" % str(s["id"]))


## The shell is really painted: Firmament overhead, floor slab under both walls, rock at both
## edges, the cavity open, the pit open all the way down.
static func _lint_shell_scene(layers: Array[TileMapLayer], rep: Dictionary) -> void:
	var env := HollowMap.env_rect()
	var cavity := HollowMap.cavity_rect()
	var x := env.position.x + 8.0
	var missing := 0
	var first_bad := Vector2.ZERO
	while x < env.end.x:
		var firmament_floor := HollowMap.ROCK_TOP
		for dr in HollowMap.dome_rects():
			if x >= dr.position.x and x < dr.end.x:
				firmament_floor = minf(firmament_floor, dr.position.y)
				if _solid_at(layers, x, dr.position.y + 8.0):
					missing += 1 # the dome air was not carved
					first_bad = Vector2(x, dr.position.y + 8.0)
		if not _solid_at(layers, x, 8.0) or not _solid_at(layers, x, firmament_floor - 8.0):
			missing += 1
			first_bad = Vector2(x, firmament_floor - 8.0)
		x += 320.0
	if missing > 0:
		_err(rep, "shell: the Firmament has %d unpainted samples along the top of the world (last at %d, %d)" % [missing, int(first_bad.x), int(first_bad.y)])
	var slab_missing := 0
	x = cavity.position.x + 8.0
	while x < cavity.end.x:
		var over_pit := x > HollowMap.MOUTH_L - 16.0 and x < HollowMap.MOUTH_R
		var solid := _solid_at(layers, x, HollowMap.CAVITY_BOTTOM + 8.0) and _solid_at(layers, x, env.end.y - 8.0)
		if over_pit and (_solid_at(layers, x, HollowMap.CAVITY_BOTTOM + 8.0) or _solid_at(layers, x, env.end.y - 8.0)):
			_err(rep, "shell: the pit is plugged at x=%d" % int(x))
			break
		if not over_pit and not solid:
			slab_missing += 1
		x += 320.0
	if slab_missing > 0:
		_err(rep, "shell: the floor slab has %d unpainted samples under the civic walls" % slab_missing)
	var edge_missing := 0
	var first_missing := Vector2.ZERO
	var y := HollowMap.ROCK_TOP + 8.0
	while y < env.end.y:
		for ex in [env.position.x + 8.0, env.end.x - 8.0, HollowMap.WEST_WALL - 8.0, HollowMap.EAST_WALL + 8.0]:
			if not _solid_at(layers, ex, y) and not _is_carved_air(ex, y):
				if edge_missing == 0:
					first_missing = Vector2(ex, y)
				edge_missing += 1
		y += 320.0
	if edge_missing > 0:
		_err(rep, "shell: the side flanks have %d unpainted samples at the envelope edges and civic walls (first at %d, %d)" % [edge_missing, int(first_missing.x), int(first_missing.y)])
	# The civic cavity itself must be empty of rock at its centre line between decks.
	if _solid_at(layers, HollowMap.HEART_X, HollowMap.ROCK_TOP + 64.0) or _solid_at(layers, HollowMap.HEART_X, HollowMap.CAVITY_BOTTOM - 64.0):
		_err(rep, "shell: rock is filling the Mouth inside the civic cavity")


## True where the map carves walk air out of a flank (galleries, shafts, stairs): not a hole.
static func _is_carved_air(x: float, y: float) -> bool:
	var p := Vector2(x, y)
	for rc in HollowMap.flank_air_rects(HollowMap.FLANK_CLEAR):
		if rc.grow(8.0).has_point(p):
			return true
	# the one-way deck row of a flank run is not on the solid layers either
	for r in HollowMap.runs():
		if x >= float(r["x0"]) and x <= float(r["x1"]) and y >= float(r["y"]) - 8.0 and y <= float(r["y"]) + HollowMap.FLOOR_THICK + 8.0:
			return true
	return false


## Instanced structures match the data; walls and stairs are painted; the air above every
## deck and tread is clear; flank ends meet rock.
static func lint_scene(scene: Node) -> Dictionary:
	var rep := {"errors": [] as Array[String], "warnings": [] as Array[String], "info": [] as Array[String]}
	var layers := _layers(scene)
	var structures := scene.get_node_or_null("Hollow/Structures")
	if structures == null:
		_err(rep, "scene: Hollow/Structures is missing (ladders, gates and zone anchors are built there)")
	else:
		for l in HollowMap.ladders():
			var node := structures.get_node_or_null(str(l["id"])) as Node2D
			if node == null:
				_err(rep, "scene: ladder %s was not built" % str(l["id"]))
				continue
			var want_x: float = float(l["open_x"]) + (HollowLayout.LADDER_OPENING - HollowLayout.LADDER_WIDTH) * 0.5
			if absf(node.position.x - want_x) > EPS or absf(node.position.y - float(l["top_y"])) > EPS:
				_err(rep, "scene: ladder %s sits at %s, map says (%d,%d)" % [str(l["id"]), str(node.position), int(want_x), int(l["top_y"])])
			var h: float = node.get("shaft_size").y
			if absf(h - (float(l["bottom_y"]) - float(l["top_y"]))) > EPS:
				_err(rep, "scene: ladder %s is %dpx tall, map says %dpx" % [str(l["id"]), int(h), int(float(l["bottom_y"]) - float(l["top_y"]))])
		for lf in HollowMap.lifts():
			var node := structures.get_node_or_null("Lift_%s" % str(lf["id"])) as Node2D
			if node == null:
				_err(rep, "scene: lift %s was not built" % str(lf["id"]))
			elif absf(node.position.x - float(lf["open_x"])) > EPS:
				_err(rep, "scene: lift %s is at x=%d, map says %d" % [str(lf["id"]), int(node.position.x), int(lf["open_x"])])
		for g in HollowMap.gates():
			if structures.get_node_or_null(str(g["id"])) == null:
				_err(rep, "scene: gate %s was not built" % str(g["id"]))
		for z in HollowMap.zones():
			if z.get("volume", false):
				continue
			var anchor := structures.get_node_or_null("Zone_%s" % str(z["id"])) as Node2D
			if anchor == null:
				_err(rep, "scene: zone anchor %s was not built" % str(z["id"]))
			else:
				var marker: Node2D = anchor.get_child(0) as Node2D if anchor.get_child_count() > 0 else null
				if marker == null or marker.global_position.distance_to(z["anchor"]) > EPS:
					_err(rep, "scene: zone %s idle marker is not at its anchor" % str(z["id"]))
	_lint_dressing_scene(scene, rep)
	var decks := _deck_layer(scene)
	if layers.size() < 2 or decks == null:
		_err(rep, "scene: terrain layers (Terrain, HollowTerrain, HollowTerrain/Decks) missing")
		return rep
	# Every deck piece is painted (one-way) along its whole length.
	for p in HollowMap.deck_pieces():
		var unpainted := 0
		var dx: float = float(p["x0"]) + 8.0
		while dx < float(p["x1"]):
			var open_here := HollowMap.in_hole(dx, float(p["y"]))
			var painted := decks.get_cell_source_id(Vector2i(int(floor(dx / 16.0)), int(round(float(p["y"]) / 16.0)))) != -1
			if painted == open_here: # painted where a stair opening should be, or missing where it should not
				unpainted += 1
			dx += 64.0
		if unpainted > 0:
			_err(rep, "deck: %s y=%d x=%d..%d has %d unpainted samples" % [str(p["run"]), int(p["y"]), int(p["x0"]), int(p["x1"]), unpainted])
		if decks.collision_enabled == false:
			_err(rep, "deck: the Decks layer starts with collision off")
	# Headroom over every deck piece (32px body: two tile rows, every 64px).
	for p in HollowMap.deck_pieces():
		var blocked := 0
		var first_x := 0.0
		var x: float = float(p["x0"]) + 8.0
		while x < float(p["x1"]):
			for up in [8.0, 24.0]:
				if _solid_at(layers, x, float(p["y"]) - up):
					if blocked == 0:
						first_x = x
					blocked += 1
			x += 64.0
		if blocked > 0:
			_err(rep, "headroom: deck %s y=%d x=%d..%d has %d blocked samples above the floor (first near x=%d)" % [str(p["run"]), int(p["y"]), int(p["x0"]), int(p["x1"]), blocked, int(first_x)])
	# Stairs: the tread is solid and the 32px above it is clear.
	for s in HollowMap.stairs():
		var steps := int(absf(float(s["top_x"]) - float(s["foot_x"])) / 16.0)
		var dir := signf(float(s["top_x"]) - float(s["foot_x"]))
		var bad_tread := 0
		var bad_air := 0
		var first_bad_air := -1.0
		for i in range(steps + 1):
			var x: float = float(s["foot_x"]) + dir * 16.0 * float(i) + 8.0
			# the tread row is the lerped row rounded to a tile, exactly as paint_stairs does
			var y: float = roundf(lerpf(float(s["foot_y"]), float(s["top_y"]), float(i) / float(steps)) / 16.0) * 16.0
			if not _solid_at(layers, x, y + 8.0):
				bad_tread += 1
			if _solid_at(layers, x, y - 8.0) or _solid_at(layers, x, y - 24.0):
				if bad_air == 0:
					first_bad_air = x
				bad_air += 1
		if bad_tread > 0:
			_err(rep, "stair: %s has %d unpainted tread columns" % [str(s["id"]), bad_tread])
		if bad_air > 0:
			_err(rep, "stair: %s has %d columns with no headroom above the tread (first near x=%d)" % [str(s["id"]), bad_air, int(first_bad_air)])
	# Walls.
	for w in HollowMap.wall_rects():
		var missing := 0
		var y := w.position.y + 8.0
		while y < w.end.y:
			if not _solid_at(layers, w.position.x + 8.0, y):
				missing += 1
			y += 64.0
		if missing > 0:
			_err(rep, "wall: column at x=%d y=%d..%d is missing %d painted samples" % [int(w.position.x), int(w.position.y), int(w.end.y), missing])
	_lint_shell_scene(layers, rep)
	# Rock beyond flank ends.
	for r in HollowMap.runs():
		if r["l"] == HollowMap.END_ROCK and not _solid_at(layers, float(r["x0"]) - 8.0, float(r["y"]) - 160.0):
			_err(rep, "end: %s has no rock beyond its left end" % run_label(r))
		if r["r"] == HollowMap.END_ROCK and not _solid_at(layers, float(r["x1"]) + 8.0, float(r["y"]) - 160.0):
			_err(rep, "end: %s has no rock beyond its right end" % run_label(r))
	return rep
