class_name HollowMap
extends Object
## THE Hollow map, as data. Everything walkable, climbable, rideable or gated is declared
## here once; terrain painting, scene structures (ladders, gates, zone anchors),
## carving, the minimap and HollowMapLint all derive from it. See docs/hollow-map-spec.md.
##
## Model: a cut-away of rock with carved rooms.
##   run      a walkable deck (a room's floor) at one level, with an end type on each side
##   stair    a 45-degree flight between two decks; a solid wedge below. The deck above is one-way,
##            so the flight rises through it; Down steps back through (HollowTerrain, player.gd)
##   ladder   a shaft climbed with W/S; decks are one-way, so there is no hatch
##   gate     a physical access barrier on a run
##   reserve  empty footprint kept for a district's growth (nothing may be built in it)
##   zone     a named place: rect + anchor standing on a deck
##
## Levels sit on one grid: y = LEVEL_ORIGIN + LEVEL_GAP * k (k = 0..LEVELS-1). Half levels (k + 0.5)
## are allowed only for Mid Heart's raised Ritual deck and its lower freight tier.
##
## West wall: x -2880 .. 1440 civic interior, -5760 .. -2880 authored dig galleries.
## East wall: x 4960 .. 9280 civic interior, 9280 .. 12160 authored dig galleries. Mouth: 1440 .. 4960.
##
## The Hollow is encased in diggable rock on every side (the "shell"): the Firmament above the
## whole map, a flank each side that runs far past the authored galleries, and a floor slab
## under both walls. Only the Devil's Mouth stays open at the bottom: the pit.
##   x: ENV_LEFT .. ENV_RIGHT        y: 0 .. ENV_BOTTOM
##   Firmament        y 0 .. ROCK_TOP                 (full width, tougher rock later)
##   civic cavity     x WEST_WALL .. EAST_WALL, y ROCK_TOP .. CAVITY_BOTTOM
##   floor slab       y CAVITY_BOTTOM .. ENV_BOTTOM under both walls; open under the Mouth (the pit)

## Rock above the highest room: the Firmament.
const ROCK_TOP := 1536.0
## Air above a deck in a carved room (walls and zone rects use this). 256 = eight body heights.
const ROOM_HEIGHT := 256.0
## Deck to deck. ROOM_HEIGHT of air, then LEVEL_GAP - ROOM_HEIGHT of floor slab and ceiling.
const LEVEL_GAP := 384.0
const LEVEL_ORIGIN := ROCK_TOP + ROOM_HEIGHT
## Levels in the stack (k = 0 is the top). 18 since 2026-10-02: four added above the old top (the Ashram is now k = 4) and two below the old bottom.
const LEVELS := 18
const FLOOR_THICK := 32.0
const WALL_THICK := 32.0
## Stairs are 45 degrees, so a flight is as long as the level gap is tall.
const RISE := LEVEL_GAP
## Width of a ladder shaft (the ladder frame is sized to the body).
const SHAFT_OPENING := 64.0
## Air carved above a deck in a dig gallery (the flanks). 160 = five body heights: roomy enough to
## brace, cart and dress, tight enough to read as dug rock rather than a hall.
const FLANK_CLEAR := 160.0

const MOUTH_L := 1440.0
const MOUTH_R := 4960.0
const WEST_WALL := -2880.0
const WEST_FLANK_LEFT := -5760.0
const EAST_WALL := 9280.0
const EAST_FLANK_RIGHT := 12160.0

## The shell. Rock past the authored galleries so the player can dig a long way sideways.
const SIDE_DEPTH := 7680.0
const ROCK_BOTTOM := 1024.0
const ENV_TOP := 0.0
const ENV_LEFT := WEST_WALL - SIDE_DEPTH
const ENV_RIGHT := EAST_WALL + SIDE_DEPTH
const BOTTOM_LEVEL_Y := LEVEL_ORIGIN + LEVEL_GAP * float(LEVELS - 1)
## First pixel row of the floor slab (one tile under the bottom deck's own tile row).
const CAVITY_BOTTOM := BOTTOM_LEVEL_Y + 16.0
const ENV_BOTTOM := BOTTOM_LEVEL_Y + ROCK_BOTTOM

## End types for a run side.
const END_WALL := &"wall" ## painted wall column just outside the run
const END_MOUTH := &"mouth" ## open lip over the Devil's Mouth
const END_ROCK := &"rock" ## dig-flank rock face (Terrain tiles)
const END_FOOT := &"foot" ## the low end of a stair (its wedge is the wall)
const END_TOP := &"top" ## the high end of a stair (stairwell edge)
const END_JOIN := &"join" ## continues into the neighbouring run (Mouth cluster)
const END_OPEN := &"open" ## an edge or pier end inside a stepped hall: no wall, the floor just stops (you can drop down)
const END_LEDGE := &"ledge" ## a short cantilevered ledge reaching out over the Mouth (at most LEDGE_MAX)
## How far a ledge may reach over the Mouth (USER 2026-10-02). Mid Heart stays the only thing that spans it.
const LEDGE_MAX := 128.0 ## the reach of a Mouth ledge far from Mid Heart
const LEDGE_REACH_MAX := 320.0 ## the longest ledge anywhere (the levels beside Mid Heart)


## How far a Mouth ledge may reach over the Mouth on level k. USER 2026-10-04: the terraces near Mid Heart are longer
## and more pronounced the closer they sit to it; the steps are AI-proposed (a level or two either side of the
## cluster reaches farthest, and everything past three levels away keeps the old 128 px).
static func ledge_max(k: float) -> float:
	var d := absf(k - 8.0)
	if d <= 1.0:
		return 320.0
	if d <= 2.0:
		return 256.0
	if d <= 3.0:
		return 192.0
	return LEDGE_MAX
## A door is a rock partition across a room, from the ceiling down to DOOR_OPENING above the deck, DOOR_THICK wide.
const DOOR_OPENING := 96.0
const DOOR_THICK := 32.0

const FLAG_NONE := &""

## Mid Heart's raised Ritual deck (x), centred on the Mouth.
const RITUAL_LEFT := 2720.0
const RITUAL_RIGHT := 3680.0
## Centre line of the Mouth.
const HEART_X := (MOUTH_L + MOUTH_R) * 0.5

static var _cache: Dictionary = {}


static func lvl(k: float) -> float:
	return LEVEL_ORIGIN + LEVEL_GAP * k


## The deck top of band k at x: the run of that band covering x (so any per-run deck offset is
## honoured), else the nominal band line. Anything that stands on or hangs from a deck asks this;
## lvl(k) alone is only the band's nominal line.
static func deck_y_at(x: float, k: float) -> float:
	for r in runs():
		if absf(float(r["k"]) - k) < 0.01 and x >= float(r["x0"]) - 0.5 and x <= float(r["x1"]) + 0.5:
			return r["y"]
	return lvl(k)


## ---------------------------------------------------------------- runs

## dy is a terrace offset (px, negative = raised): the run still belongs to band k, but its deck sits
## dy off the band line. Everything that stands on a deck reads it through deck_y_at().
static func _run(id: StringName, zone: StringName, x0: float, x1: float, k: float, l: StringName, r: StringName, dy: float = 0.0) -> Dictionary:
	return {"id": id, "zone": zone, "x0": x0, "x1": x1, "k": k, "y": lvl(k) + dy, "dy": dy, "l": l, "r": r, "landing": false}


## A half-level landing between two flights of one stair. Sits under the street that passes over the
## stair, and carries the stair's district.
static func _landing(id: StringName, zone: StringName, x0: float, x1: float, k: float, l: StringName, r: StringName) -> Dictionary:
	var run := _run(id, zone, x0, x1, k, l, r)
	run["landing"] = true
	return run


static func runs() -> Array[Dictionary]:
	if _cache.has("runs"):
		return _cache["runs"]
	var out: Array[Dictionary] = [
		# ---- WEST WALL ----
		_run(&"LW8", &"lower_worker", -1600.0, 640.0, 12, END_TOP, END_FOOT),
		_run(&"BW9", &"bottom_west", -3440.0, -1600.0 - RISE, 13, END_TOP, END_FOOT),
		_run(&"BW10", &"bottom_west", WEST_FLANK_LEFT, -3440.0 - RISE, 14, END_ROCK, END_FOOT),
		_run(&"BW11", &"bottom_west", WEST_FLANK_LEFT, -3200.0, 15, END_ROCK, END_WALL),
		_landing(&"WS", &"wickwork", 192.0, 448.0, 8.5, END_OPEN, END_FOOT), # Wickwork's hanging drying shelf
		_landing(&"GL1", &"glowbeds_hang", 5712.0, 6112.0, 5.5, END_OPEN, END_FOOT), # a planter terrace in the court
		# Bottom-West deeper galleries (behind the service-run gate): more lateral dig frontier

		# ---- MID HEART (the only structure over the Mouth) ----
		_run(&"HM_W", &"mid_heart", MOUTH_L, 1632.0, 8, END_JOIN, END_FOOT),
		_run(&"HM_R", &"mid_heart", RITUAL_LEFT, RITUAL_RIGHT, 7.5, END_TOP, END_TOP),
		_run(&"HM_E", &"mid_heart", RITUAL_RIGHT + 0.5 * RISE, 4064.0, 8, END_FOOT, END_FOOT),
		# Lower Heart (AI, 2026-10-03, user: Mid Heart needs another level): the freight tier dips into a lowered dock
		_run(&"HM_F", &"mid_heart", MOUTH_L + 0.5 * RISE, 2544.0, 8.5, END_TOP, END_TOP),
		_run(&"HM_LH", &"mid_heart", 2736.0, 3664.0, 9, END_FOOT, END_FOOT), # the lowered freight dock: cranes, dispatch, recovery
		_run(&"HM_F2", &"mid_heart", 3856.0, MOUTH_R - 0.5 * RISE, 8.5, END_TOP, END_TOP),
		# Upper Heart: the Council Terrace over the Ritual Raft (the Ritual hall is two levels), reached by the two masts
		_run(&"HM_UC", &"mid_heart_upper", 2448.0, 3952.0, 6, END_WALL, END_WALL),
		# Mid Heart variety (AI, 2026-10-03): two galleries above the exchange and service rafts, and a freight crane dock hung under the tier
		# the crossing now steps over a gallery on each side of the Ritual Raft: lip, landing, gallery, landing, Ritual
		_run(&"HM_W2", &"mid_heart", 2336.0, RITUAL_LEFT - 0.5 * RISE, 8, END_FOOT, END_FOOT), # the Exchange landing before the Ritual flight
		_run(&"HM_WG", &"mid_heart", 1824.0, 2144.0, 7.5, END_TOP, END_TOP), # the Exchange gallery
		_run(&"HM_EG", &"mid_heart", 4256.0, 4576.0, 7.5, END_TOP, END_TOP), # the Stewards' gallery
		_run(&"HM_E2", &"mid_heart", 4768.0, MOUTH_R, 8, END_FOOT, END_JOIN), # the service landing at the east lip
		# ---- EAST WALL ----
		# Mouth balconies (2026-10-02): short pockets at the lips, each reached by a ladder from the street above
		_run(&"MB10", &"mid_allotments", 1056.0, 1696.0, 10, END_WALL, END_LEDGE), # west, 256 px out
		_run(&"ME10", &"lower_east_homes", 4704.0, 5136.0, 10, END_LEDGE, END_WALL), # east, 256 px out
		_run(&"ME13", &"cistern_intake", 4864.0, 5600.0, 13, END_LEDGE, END_WALL), # east, 96 px out
		# Lower-East Stair landing: two flights (S_LE6a steep, S_LE6b shallow) around a half-level landing.
		_landing(&"E5L", &"lower_east_homes", 5440.0, 5568.0, 9.5, END_FOOT, END_TOP),
	]
	for t in _terraces():
		out.append_array(_terrace_parts(t)["runs"])
	_cache["runs"] = out
	return out


## ---------------------------------------------------------------- terraces

## Streets broken up for variety (the variety pass). Each entry is one band run written as an ordered
## list of flat `pieces` [x0, x1, dy] (dy: px off the band line, a whole number of tiles, 16-96,
## negative = raised, positive = a dip). Between two pieces the gap is a flight joining them: its rise
## is the dy difference and its run is the gap, so a gap equal to the rise is a 45 degree step and a
## wider gap is a gentler slope (stepped tiles, one tile per riser). Pieces are named id, id_1, id_2...;
## the flights S_id_1, S_id_2... The first and last piece keep the run's own end types. Keep shafts,
## anchors, gates and stair tops on band-line (dy 0) pieces, and no dip over a flight: the lint checks.
## HollowMapLint's `flat` warning is what these answer.
static func _terraces() -> Array[Dictionary]:
	return [
		# ---- West civic
		{"id": &"A0", "zone": &"ashram_west", "k": 4, "l": END_FOOT, "r": END_LEDGE, "pieces": [
			[-1280.0, -640.0, 0.0], [-576.0, -400.0, 32.0], [-336.0, 496.0, 0.0],
			[528.0, 624.0, 16.0], [656.0, 752.0, 32.0], [784.0, 976.0, 48.0], [1008.0, 1104.0, 32.0], [1136.0, 1232.0, 16.0], [1264.0, 1536.0, 0.0]]}, # a small sunken court, then a round bowl-floored court under a dome (D_A0)
		{"id": &"A1", "zone": &"ashram_west", "k": 5, "l": END_WALL, "r": END_FOOT, "pieces": [
			[-2720.0, -1408.0, 0.0], [-1152.0, -1040.0, -64.0], [-912.0, -160.0, 0.0]]}, # a long ramp up, a short drop
		{"id": &"WK4", "zone": &"wickwork", "k": 8, "l": END_ROCK, "r": END_JOIN, "pieces": [
			[-5440.0, -4560.0, 0.0], [-4464.0, -4144.0, -48.0], [-4048.0, -3584.0, 0.0], [-3488.0, -3232.0, 32.0], [-3136.0, -2096.0, 0.0], [-2000.0, -1808.0, -48.0], [-1712.0, -304.0, 0.0], [-176.0, 256.0, -64.0], [384.0, 1440.0, 0.0]]},
		{"id": &"WK5", "zone": &"wickwork", "k": 9, "l": END_FOOT, "r": END_MOUTH, "pieces": [
			[-1280.0, 160.0, 0.0], [304.0, 560.0, 48.0], [656.0, 1440.0, 0.0]]},
		{"id": &"AL6", "zone": &"mid_allotments", "k": 10, "l": END_WALL, "r": END_FOOT, "pieces": [
			[-2400.0, -2256.0, 0.0], [-2128.0, -1856.0, -64.0], [-1728.0, -1104.0, 0.0], [-1040.0, -704.0, -32.0], [-640.0, 640.0, 0.0]]},
		{"id": &"AL7", "zone": &"mid_allotments", "k": 11, "l": END_FOOT, "r": END_WALL, "pieces": [
			[-1280.0, -160.0, 0.0], [-112.0, 560.0, -48.0], [608.0, 1376.0, 0.0]]}, # the residences street is tucked back from the Mouth (a 64 px rock wall) and closed off by rock
		# ---- Ashram Heights upper wards (2026-10-02): a zigzag of tiers climbing to the Firmament, joined by
		# processional stairs. Each tier is a street the one below passes under; the top tier (L0) is directly
		# under the Firmament (AI working layout, names and purposes for the user to confirm).
		{"id": &"AW3", "zone": &"ashram_west_3", "k": 3, "l": END_WALL, "r": END_FOOT, "pieces": [
			[-2400.0, -1984.0, -48.0], [-1888.0, -480.0, 0.0]]},
		{"id": &"AW2", "zone": &"ashram_west_2", "k": 2, "l": END_FOOT, "r": END_WALL, "pieces": [
			[-960.0, 448.0, 0.0]]},
		{"id": &"AW1", "zone": &"ashram_west_1", "k": 1, "l": END_WALL, "r": END_FOOT, "pieces": [
			[-2000.0, -1696.0, -32.0], [-1632.0, -208.0, 0.0]]},
		{"id": &"AW0", "zone": &"ashram_west_0", "k": 0, "l": END_WALL, "r": END_WALL, "pieces": [
			[-608.0, 448.0, 0.0]]},
		{"id": &"AE3", "zone": &"ashram_east_3", "k": 3, "l": END_FOOT, "r": END_WALL, "pieces": [
			[8208.0, 9248.0, 0.0]]},
		{"id": &"AE2", "zone": &"ashram_east_2", "k": 2, "l": END_WALL, "r": END_FOOT, "pieces": [
			[6608.0, 7280.0, 0.0], [7376.0, 7696.0, -48.0], [7792.0, 8496.0, 0.0]]},
		{"id": &"AE1", "zone": &"ashram_east_1", "k": 1, "l": END_FOOT, "r": END_WALL, "pieces": [
			[8096.0, 9248.0, 0.0]]},
		{"id": &"AE0", "zone": &"ashram_east_0", "k": 0, "l": END_WALL, "r": END_WALL, "pieces": [
			[6896.0, 8304.0, 0.0]]},
		# ---- High-West galleries (flank dig gallery and the civic part to the Mouth rail ledge, 48 px)
		{"id": &"HW2", "zone": &"high_west_front", "k": 6, "l": END_ROCK, "r": END_LEDGE, "pieces": [
			[WEST_FLANK_LEFT, -4304.0, 0.0], [-4240.0, -3984.0, 32.0], [-3920.0, -2400.0, 0.0], [-2304.0, -1888.0, -48.0],
			[-1792.0, -352.0, 0.0], [-224.0, 288.0, -64.0], [416.0, 1696.0, 0.0]]}, # the rail ledge reaches 256 px out toward Mid Heart
		{"id": &"HW3", "zone": &"high_west_lower", "k": 7, "l": END_ROCK, "r": END_FOOT, "pieces": [
			[WEST_FLANK_LEFT, -4352.0, 0.0], [-4224.0, -3872.0, -64.0], [-3744.0, -2336.0, 0.0], [-2240.0, -1888.0, 48.0],
			[-1792.0, -800.0, 0.0]]},
		# ---- Bottom-West deeper galleries (behind the service-run gate): more lateral dig frontier
		{"id": &"BW12", "zone": &"bottom_west_deeper", "k": 16, "l": END_ROCK, "r": END_WALL, "pieces": [
			[WEST_FLANK_LEFT, -4560.0, 0.0], [-4464.0, -4144.0, 48.0], [-4048.0, -3328.0, 0.0]]},
		{"id": &"BW13", "zone": &"bottom_west_lowest", "k": 17, "l": END_ROCK, "r": END_WALL, "pieces": [
			[WEST_FLANK_LEFT, -4688.0, 0.0], [-4592.0, -4336.0, -32.0], [-4240.0, -4064.0, 0.0]]},
		# ---- Wickwork Foundry (USER 2026-10-04: Wickwork needs far more room): behind the growth gate the Expansion Bay now runs
		# down through a slag gallery to a casting floor, a three-level foundry stack in the west flank; and on the public side
		# a gantry level hangs toward Mid Heart above the street.
		{"id": &"WK9F", "zone": &"wickwork_slag", "k": 9, "l": END_WALL, "r": END_WALL, "pieces": [
			[-5440.0, -4640.0, 0.0], [-4544.0, -4288.0, -32.0], [-4192.0, -3712.0, 0.0]]},
		{"id": &"WC10", "zone": &"wickwork_casting", "k": 10, "l": END_WALL, "r": END_WALL, "pieces": [
			[-5440.0, -4480.0, 0.0], [-4384.0, -4096.0, -48.0], [-4000.0, -3040.0, 0.0]]},
		{"id": &"WK7", "zone": &"wickwork_upper", "k": 7, "l": END_WALL, "r": END_LEDGE, "pieces": [
			[1232.0, 1760.0, 0.0]]}, # the gantry level: a public ledge 320 px out toward Mid Heart
		# ---- Cistern: the core, the tanks and the seep threshold, broken up (footprint unchanged)
		{"id": &"E9", "zone": &"cistern", "k": 13, "l": END_FOOT, "r": END_OPEN, "pieces": [
			[6400.0, 7312.0, 0.0], [7408.0, 7792.0, -48.0], [7888.0, 8096.0, 0.0]]}, # a maintenance balcony over the basin chamber
		{"id": &"PF13", "zone": &"cistern", "k": 13, "l": END_OPEN, "r": END_OPEN, "pieces": [
			[8672.0, 8928.0, 0.0]]}, # the freight elevator's landing: a pier in the basin chamber
		{"id": &"E10", "zone": &"cistern_tanks", "k": 14, "l": END_FOOT, "r": END_ROCK, "pieces": [
			[7360.0, 7616.0, 0.0], [7680.0, 7904.0, 32.0], [7968.0, 9376.0, 0.0], [9472.0, 9760.0, -48.0], [9856.0, 10560.0, 0.0]]}, # past the wall: the tank annex (growth room, gate_cistern_growth)
		{"id": &"E11", "zone": &"seep_threshold", "k": 15, "l": END_WALL, "r": END_WALL, "pieces": [
			[6400.0, 7328.0, 0.0], [7424.0, 7760.0, 48.0], [7856.0, EAST_WALL, 0.0]]},
		# ---- Mid-East street: the Landing, the Approach and the dig-front gallery
		{"id": &"E4", "zone": &"mid_east", "k": 8, "l": END_JOIN, "r": END_ROCK, "pieces": [
			[4960.0, 6560.0, 0.0], [6656.0, 6880.0, -48.0], [6976.0, 8352.0, 0.0], [8448.0, 8544.0, -32.0],
			[8640.0, 9728.0, 0.0], [9824.0, 10880.0, 48.0], [10976.0, 12160.0, 0.0]]},
		# ---- Lower Mouth Rows (2026-10-02, AI working layout): cliff dwellings hugging the west side of the Mouth,
		# climbing and stepping in and out; lower-tier housing and Bottom-West annexes. Joined by ladders and stairs.
		{"id": &"LP12", "zone": &"worker_return_ascent", "k": 12, "l": END_WALL, "r": END_LEDGE, "pieces": [
			[1056.0, 1536.0, 0.0]]}, # 96 px out
		{"id": &"LP13", "zone": &"lower_rows_1", "k": 13, "l": END_WALL, "r": END_LEDGE, "pieces": [
			[-160.0, 544.0, 0.0], [608.0, 768.0, 32.0], [832.0, 1504.0, 0.0]]}, # 64 px out
		{"id": &"LP14", "zone": &"lower_rows_2", "k": 14, "l": END_WALL, "r": END_FOOT, "pieces": [
			[-640.0, 800.0, 0.0]]}, # tucked back, closed off from the Mouth
		{"id": &"LP15", "zone": &"lower_rows_3", "k": 15, "l": END_FOOT, "r": END_LEDGE, "pieces": [
			[-96.0, 704.0, 0.0], [768.0, 1104.0, -32.0], [1168.0, 1568.0, 0.0]]}, # 128 px out
		{"id": &"LP16", "zone": &"lower_rows_4", "k": 16, "l": END_WALL, "r": END_WALL, "pieces": [
			[-800.0, 608.0, 0.0]]},
		{"id": &"LP17", "zone": &"lower_rows_5", "k": 17, "l": END_WALL, "r": END_FOOT, "pieces": [
			[-800.0, 96.0, 0.0]]},
		# ---- Lower-East / Cistern Mouth Rows: the east cliff, mirroring the west rows (AI working layout)
		{"id": &"EP11", "zone": &"east_rows_1", "k": 11, "l": END_LEDGE, "r": END_WALL, "pieces": [
			[4768.0, 6240.0, 0.0]]},
		{"id": &"EP12", "zone": &"east_rows_2", "k": 12, "l": END_LEDGE, "r": END_WALL, "pieces": [
			[4864.0, 5376.0, 0.0]]},
		{"id": &"EP14", "zone": &"east_rows_3", "k": 14, "l": END_LEDGE, "r": END_FOOT, "pieces": [
			[4896.0, 6208.0, 0.0]]},
		{"id": &"EP15", "zone": &"east_rows_4", "k": 15, "l": END_WALL, "r": END_WALL, "pieces": [
			[5200.0, 6304.0, 0.0]]},
		{"id": &"EP16", "zone": &"east_rows_5", "k": 16, "l": END_LEDGE, "r": END_FOOT, "pieces": [
			[4864.0, 6000.0, 0.0]]},
		{"id": &"EP17", "zone": &"east_rows_6", "k": 17, "l": END_FOOT, "r": END_WALL, "pieces": [
			[5808.0, 7008.0, 0.0]]},
		# ---- East civic
		# The east Ashram promenade and its residences are one level now (USER 2026-10-04: Glowbeds and the east Ashram sit higher):
		# a public promenade out to a Mouth overlook, the Warden gate at x 7040, and the residences beyond it.
		{"id": &"E1", "zone": &"ashram_east", "k": 4, "l": END_LEDGE, "r": END_FOOT, "pieces": [
			[4832.0, 5600.0, 0.0], [5632.0, 5856.0, 16.0], [5888.0, 6560.0, 0.0], [6608.0, 6880.0, -48.0], [6928.0, 7520.0, 0.0],
			[7552.0, 7808.0, 16.0], [7840.0, 8800.0, 0.0]]},
		{"id": &"E2", "zone": &"glowbeds", "k": 5, "l": END_LEDGE, "r": END_ROCK, "pieces": [
			[4768.0, 5520.0, 0.0], [5568.0, 5888.0, -48.0], [5936.0, 6560.0, 0.0], [6624.0, 6880.0, -64.0], [6944.0, 7216.0, 0.0], [7264.0, 7872.0, -48.0],
			[7920.0, 9376.0, 0.0], [9472.0, 9760.0, -48.0], [9856.0, 10400.0, 0.0]]}, # past the wall the court runs on into the flank: the frontier cultivation tier (gate_glowbeds_growth)
		# Glowbeds stepped planter court: a 3-level hall (GB) with the promenade and the terrace as bridges and a
		# cascade of planter terraces down to the Hang floor (E3, GL1, S_GB_1, S_GB_2).
		{"id": &"E3", "zone": &"glowbeds_hang", "k": 6, "l": END_LEDGE, "r": END_FOOT, "pieces": [
			[4704.0, 5584.0, 0.0]]}, # a long terrace reaching 256 px out toward Mid Heart
		{"id": &"E3B", "zone": &"glowbeds_hang", "k": 6, "l": END_OPEN, "r": END_FOOT, "pieces": [
			[5792.0, 7200.0, 0.0], [7232.0, 7392.0, -32.0], [7424.0, 8000.0, 0.0]]},
		# Glowbeds lower gardens (USER 2026-10-04: Glowbeds needs more room): a public level 7 east of the lift, reached by
		# ladders from the hang above and the Mid-East Approach below.
		{"id": &"GL7", "zone": &"glowbeds_lower", "k": 7, "l": END_WALL, "r": END_WALL, "pieces": [
			[6656.0, 7168.0, 0.0], [7264.0, 7552.0, -32.0], [7648.0, 8000.0, 0.0]]},
		# Glowbeds recovery and cultures wing (USER 2026-10-04, AI-built): rest cots, culture shelves and prepared stock
		# on the level the move freed, a gated growth room (gate_glowbeds_wing).
		{"id": &"GW7", "zone": &"glowbeds_wing", "k": 7, "l": END_WALL, "r": END_WALL, "pieces": [
			[5200.0, 6320.0, 0.0]]},
		{"id": &"E5", "zone": &"mid_east_service", "k": 9, "l": END_FOOT, "r": END_FOOT, "pieces": [
			[MOUTH_R, 5472.0, 0.0], [5552.0, 5952.0, -80.0], [6032.0, 7360.0, 0.0]]},
		{"id": &"E6", "zone": &"lower_east_homes", "k": 10, "l": END_FOOT, "r": END_WALL, "pieces": [
			[5760.0, 6896.0, 0.0], [6960.0, 7200.0, -64.0], [7264.0, 8000.0, 0.0]]},
		{"id": &"E7", "zone": &"lower_east_services", "k": 11, "l": END_FOOT, "r": END_WALL, "pieces": [
			[6720.0, 7520.0, 0.0], [7552.0, 7648.0, 16.0], [7680.0, 7776.0, 32.0], [7808.0, 7904.0, 16.0], [7936.0, EAST_WALL, 0.0]]}, # a small round bowl court
		{"id": &"E8", "zone": &"cistern_freight", "k": 12, "l": END_WALL, "r": END_WALL, "pieces": [
			[5440.0, 6288.0, 0.0], [6352.0, 6832.0, -64.0], [6896.0, 7552.0, 0.0], [7600.0, 7824.0, -48.0], [7872.0, EAST_WALL, 0.0]]},
	]


## Low arched roofs: solid rock hung from the room's ceiling, stepping down to `depth` at the middle
## and back up (n bands each side, so the middle is the deepest). They lower the roof over a stretch
## of a band-line deck without touching the rooms above. x0..x1 splits into 2n-1 equal bands, each a
## whole number of tiles wide; depth is 16-96 px (160 px of air always remains). Keep them clear of
## shafts and stair flights: the lint's `roof` rule checks.
static func _roofs() -> Array[Dictionary]:
	return [
		{"id": &"R_A1", "k": 5, "x0": -2400.0, "x1": -1760.0, "depth": 96.0, "n": 3},
		{"id": &"R_WK4", "k": 8, "x0": -1104.0, "x1": -464.0, "depth": 96.0, "n": 3},
		{"id": &"R_AL6", "k": 10, "x0": -1712.0, "x1": -1232.0, "depth": 96.0, "n": 3},
		{"id": &"R_HW2", "k": 6, "x0": -1600.0, "x1": -960.0, "depth": 96.0, "n": 3},
		{"id": &"R_E5", "k": 9, "x0": 6416.0, "x1": 7056.0, "depth": 96.0, "n": 3},
		{"id": &"R_LP14", "k": 14, "x0": -480.0, "x1": 160.0, "depth": 96.0, "n": 3},
		{"id": &"R_EP11", "k": 11, "x0": 5600.0, "x1": 6240.0, "depth": 96.0, "n": 3},
	]


## Domes: air carved up into the rock over a room that has nothing above it in that stretch, stepping
## up to `height` in the middle and back down (n bands each side), for a taller, rounder room than the
## 256 px band allows. Needs no street on any level above within the dome's reach (the lint checks), so
## today only rooms under the unbuilt top levels can have one. x0..x1 splits into 2n-1 equal bands,
## each a whole number of tiles; height is 16-192 px.
static func _domes() -> Array[Dictionary]:
	return [
		{"id": &"D_A0", "k": 4, "x0": 512.0, "x1": 1232.0, "height": 160.0, "n": 5},
		{"id": &"D_AW0", "k": 0, "x0": -448.0, "x1": 352.0, "height": 192.0, "n": 3}, # summit rotunda, into the Firmament
		{"id": &"D_AE0", "k": 0, "x0": 7168.0, "x1": 7968.0, "height": 192.0, "n": 3},
		{"id": &"D_WK4", "k": 8, "x0": 480.0, "x1": 1200.0, "height": 160.0, "n": 5}, # Wickwork's eastern hall
		{"id": &"D_E1", "k": 4, "x0": 5024.0, "x1": 5584.0, "height": 192.0, "n": 3}, # the east Ashram overlook
		{"id": &"D_E4", "k": 8, "x0": 8544.0, "x1": 9264.0, "height": 160.0, "n": 5}, # the Mid-East Approach hall
	]


static func domes() -> Array[Dictionary]:
	return _domes()


## The air rects of one dome: Rect2 (x, y, w, h) sitting on the room's ceiling line, reaching up into the rock.
static func dome_blocks(dome: Dictionary) -> Array[Rect2]:
	var out: Array[Rect2] = []
	var n: int = dome["n"]
	var bands := 2 * n - 1
	var x0: float = dome["x0"]
	var w := (float(dome["x1"]) - x0) / float(bands)
	var base := lvl(float(dome["k"])) - ROOM_HEIGHT
	for i in range(bands):
		var h := float(dome["height"]) * float(mini(i, bands - 1 - i) + 1) / float(n)
		out.append(Rect2(x0 + w * float(i), base - h, w, h))
	return out


static func dome_rects() -> Array[Rect2]:
	var out: Array[Rect2] = []
	for dome in _domes():
		out.append_array(dome_blocks(dome))
	return out


## The ceiling line of band k across x0..x1 as segments Vector3(x0, x1, y): flat at the band's ceiling,
## stepping up over domes of that band.
static func ceiling_segments(x0: float, x1: float, k: float) -> Array[Vector3]:
	var out: Array[Vector3] = []
	var base := lvl(k) - ROOM_HEIGHT
	var rects: Array[Rect2] = []
	for dome in _domes():
		if absf(float(dome["k"]) - k) < 0.01:
			rects.append_array(dome_blocks(dome))
	rects.sort_custom(func(a: Rect2, b: Rect2) -> bool: return a.position.x < b.position.x)
	var cur := x0
	for r in rects:
		if r.end.x <= x0 or r.position.x >= x1:
			continue
		if r.position.x > cur:
			out.append(Vector3(cur, r.position.x, base))
		out.append(Vector3(maxf(r.position.x, x0), minf(r.end.x, x1), r.position.y))
		cur = minf(r.end.x, x1)
	if cur < x1:
		out.append(Vector3(cur, x1, base))
	return out


## True when no run on any band above `k` overlaps x0..x1 (nothing built above that stretch).
static func nothing_above(k: float, x0: float, x1: float) -> bool:
	for r in runs():
		# only the level directly above matters: its street, floor slab and any landing are what a dome would cut
		if float(r["k"]) < k - 0.01 and float(r["k"]) >= k - 1.0 - 0.01 and float(r["x0"]) < x1 and float(r["x1"]) > x0:
			return false
	return true


## ---------------------------------------------------------------- derived: the rock between rooms

## Air in the civic cavity, as Rect2 (x, y, w, h) in px: every room (ceiling to the deck row), every flight
## (112 px above each tread; a terrace step opens the whole room height), every ladder and lift shaft, and
## every dome. Everything else in the civic cavity, outside the Mouth, is solid rock (civic_rock_rows).
static func air_rects() -> Array[Rect2]:
	if _cache.has("air_rects"):
		return _cache["air_rects"]
	var out: Array[Rect2] = []
	var room_rects: Array[Rect2] = []
	for r in runs():
		if HollowMap.is_heart_zone(r["zone"]):
			continue
		var x0 := maxf(float(r["x0"]), WEST_WALL)
		var x1 := minf(float(r["x1"]), EAST_WALL)
		if x1 <= x0:
			continue
		var y: float = r["y"]
		var top := y - 160.0 if bool(r["landing"]) else minf(y, lvl(float(r["k"]))) - ROOM_HEIGHT
		out.append(Rect2(x0, top, x1 - x0, y + FLOOR_THICK - top))
		room_rects.append(out[out.size() - 1])
	_cache["room_rects"] = room_rects
	for s in stairs():
		var fx: float = s["foot_x"]
		var tx: float = s["top_x"]
		var span := int(roundf(absf(tx - fx) / 16.0))
		var dir := signf(tx - fx)
		var air := ROOM_HEIGHT if is_step(s) else float(s.get("air", 112.0))
		for i in range(span + 1):
			var cx := fx + dir * 16.0 * float(i)
			var ty := roundf(lerpf(float(s["foot_y"]), float(s["top_y"]), float(i) / float(maxi(span, 1))) / 16.0) * 16.0
			var x_lo := minf(cx, cx + dir * 16.0)
			if x_lo < WEST_WALL or x_lo + 16.0 > EAST_WALL or (x_lo + 16.0 > MOUTH_L and x_lo < MOUTH_R):
				continue
			out.append(Rect2(x_lo, ty - air, 16.0, air))
	for l in ladders():
		if in_flank(float(l["open_x"])):
			continue
		out.append(Rect2(float(l["open_x"]) - 8.0, float(l["top_y"]), SHAFT_OPENING + 16.0, float(l["bottom_y"]) - float(l["top_y"])))
	for lf in lifts():
		var stops: Array = lf["stops"]
		out.append(Rect2(float(lf["open_x"]) - 16.0, float(stops[0]), float(lf["width"]) + 32.0, float(stops[stops.size() - 1]) - float(stops[0])))
	out.append_array(dome_rects())
	out.append_array(hall_rects())
	_cache["air_rects"] = out
	return out


## Room coves (USER 2026-10-04: rooms read as dark rectangles with straight vertical ends): where a room ends in a wall, its
## upper corner is cut away by a sloped rock cove, 4 to 8 tiles wide at the ceiling, narrowing to nothing a hand's width
## above the headroom line, so a room is a cave and not a box. Only the top 128 px of the 256 px room is ever filled, so
## the 96 px of headroom over every deck is untouched. Returns {row: Array[Vector2(x0, x1)]} of extra rock, already
## minus any flight, shaft, dome or hall that crosses it.
static func cove_rows() -> Dictionary:
	if _cache.has("cove_rows"):
		return _cache["cove_rows"]
	air_rects()
	var rooms: Array = _cache["room_rects"]
	var others: Array[Rect2] = []
	for rc in air_rects():
		if not rooms.has(rc):
			others.append(rc)
	var out: Dictionary = {}
	for r in runs():
		if HollowMap.is_heart_zone(r["zone"]) or bool(r["landing"]):
			continue
		var x0 := float(r["x0"])
		var x1 := float(r["x1"])
		if x1 - x0 < 640.0 or x0 < WEST_WALL or x1 > EAST_WALL:
			continue
		var top := minf(float(r["y"]), lvl(float(r["k"]))) - ROOM_HEIGHT
		var row0 := int(roundf(top / 16.0))
		for side in range(2):
			var end_type: StringName = r["l"] if side == 0 else r["r"]
			if end_type != END_WALL:
				continue
			var rng := RandomNumberGenerator.new()
			rng.seed = hash(str(r["id"])) + side * 13
			var n := rng.randi_range(6, 10)
			for i in range(n):
				var w := float(n - i) * 16.0
				var span := Vector2(x0, x0 + w) if side == 0 else Vector2(x1 - w, x1)
				var row := row0 + i
				var pieces: Array[Vector2] = [span]
				for o in others:
					if float(row) * 16.0 >= o.end.y or float(row + 1) * 16.0 <= o.position.y:
						continue
					var next: Array[Vector2] = []
					for p in pieces:
						if o.end.x <= p.x or o.position.x >= p.y:
							next.append(p)
							continue
						if o.position.x > p.x:
							next.append(Vector2(p.x, o.position.x))
						if o.end.x < p.y:
							next.append(Vector2(o.end.x, p.y))
					pieces = next
				if not out.has(row):
					out[row] = []
				for p in pieces:
					if p.y > p.x:
						(out[row] as Array).append(p)
	_cache["cove_rows"] = out
	return out


## The Mouth's cliff faces are ragged, not a ruled line (USER 2026-10-04: the reference reads as organic cliffs with
## bulging shelves and overhangs). Wherever the rock at a Mouth lip is a solid mass between rooms (no room, ledge, flight or
## shaft reaches the lip on those rows), it bulges out into the void, up to CLIFF_MAX px, in a deterministic seeded profile,
## quantised to whole tiles. Rows of Mid Heart's band and any row a room touches keep the straight lip. Returns
## {row: Vector2(west_bulge, east_bulge)} in px.
const CLIFF_MAX := 192.0
const CLIFF_SEED := 90417


static func cliff_bulges() -> Dictionary:
	if _cache.has("cliff_bulges"):
		return _cache["cliff_bulges"]
	var first_row := int(ROCK_TOP / 16.0)
	var last_row := int(CAVITY_BOTTOM / 16.0) - 1
	var touched_w: Dictionary = {}
	var touched_e: Dictionary = {}
	for rc in air_rects():
		var r0 := int(floorf(rc.position.y / 16.0))
		var r1 := int(ceilf(rc.end.y / 16.0))
		var hits_w: bool = rc.end.x > MOUTH_L - 48.0 and rc.position.x < MOUTH_L + 48.0
		var hits_e: bool = rc.position.x < MOUTH_R + 48.0 and rc.end.x > MOUTH_R - 48.0
		if not (hits_w or hits_e):
			continue
		for row in range(r0, r1):
			if hits_w:
				touched_w[row] = true
			if hits_e:
				touched_e[row] = true
	# Mid Heart's band keeps its straight lips (the rafts, moorings and anchor plates sit on them)
	var band_lo := int(floorf((lvl(5.0) - ROOM_HEIGHT - 96.0) / 16.0))
	var band_hi := int(ceilf((lvl(9.5) + 96.0) / 16.0))
	for row in range(band_lo, band_hi + 1):
		touched_w[row] = true
		touched_e[row] = true
	var out: Dictionary = {}
	for row in range(first_row, last_row + 1):
		out[row] = Vector2.ZERO
	for side in range(2):
		var touched: Dictionary = touched_w if side == 0 else touched_e
		var row := first_row
		while row <= last_row:
			if touched.has(row):
				row += 1
				continue
			var start := row
			while row <= last_row and not touched.has(row):
				row += 1
			var n := row - start
			if n < 4:
				continue
			var rng := RandomNumberGenerator.new()
			rng.seed = CLIFF_SEED + start * 31 + side * 7
			var amp := minf(CLIFF_MAX, float(n) * 16.0 * 0.62) * rng.randf_range(0.55, 1.0)
			var lean := rng.randf_range(0.25, 0.75) # where the bulge peaks along the mass
			for i in range(n):
				var t := (float(i) + 0.5) / float(n)
				var shape := sin(PI * pow(t, log(0.5) / log(lean)))
				var off := clampf(roundf(amp * pow(maxf(shape, 0.0), 0.8) / 16.0) * 16.0, 0.0, CLIFF_MAX)
				if i < 2 or i >= n - 2:
					off = minf(off, 32.0) # tuck into the rooms above and below
				var v: Vector2 = out[start + i]
				if side == 0:
					v.x = off
				else:
					v.y = off
				out[start + i] = v
	_cache["cliff_bulges"] = out
	return out


## The solid civic rock as {row: Array[Vector2(x0, x1)]} in px, row = y / 16, from the Firmament line to
## the floor slab. The Mouth stays open; the diggable shell (Firmament, flanks, slab) is not in here.
static func civic_rock_rows() -> Dictionary:
	if _cache.has("civic_rock_rows"):
		return _cache["civic_rock_rows"]
	var first_row := int(ROCK_TOP / 16.0)
	var last_row := int(CAVITY_BOTTOM / 16.0) - 1
	var per_row: Dictionary = {}
	for rc in air_rects():
		for row in range(maxi(int(floorf(rc.position.y / 16.0)), first_row), mini(int(ceilf(rc.end.y / 16.0)), last_row + 1)):
			if not per_row.has(row):
				per_row[row] = []
			(per_row[row] as Array).append(Vector2(rc.position.x, rc.end.x))
	var bulges := cliff_bulges()
	var out: Dictionary = {}
	for row in range(first_row, last_row + 1):
		var bulge: Vector2 = bulges.get(row, Vector2.ZERO)
		var sides := [Vector2(WEST_WALL, MOUTH_L + bulge.x), Vector2(MOUTH_R - bulge.y, EAST_WALL)]
		var cuts: Array = per_row.get(row, [])
		cuts.sort_custom(func(a: Vector2, b: Vector2) -> bool: return a.x < b.x)
		var spans: Array[Vector2] = []
		for side in sides:
			var cur: float = side.x
			for c in cuts:
				if c.y <= cur or c.x >= side.y:
					continue
				if c.x > cur:
					spans.append(Vector2(cur, c.x))
				cur = maxf(cur, c.y)
			if cur < side.y:
				spans.append(Vector2(cur, side.y))
		# add the room coves, then merge touching spans
		var coves: Dictionary = cove_rows()
		if coves.has(row):
			spans.append_array(coves[row])
			spans.sort_custom(func(a: Vector2, b: Vector2) -> bool: return a.x < b.x)
			var merged: Array[Vector2] = []
			for sp in spans:
				if not merged.is_empty() and sp.x <= merged[merged.size() - 1].y:
					merged[merged.size() - 1].y = maxf(merged[merged.size() - 1].y, sp.y)
				else:
					merged.append(sp)
			spans = merged
		out[row] = spans
	_cache["civic_rock_rows"] = out
	return out


## Stepped halls (2026-10-02, USER): open air joining two or more levels over an x-range, so a cascade of
## landings and short flights (the steps, written as ordinary runs and stairs) sits in one tall room instead
## of separate rooms under slabs. A hall is the air between the ceiling of its top level and the deck of its
## bottom level; the steps inside it are runs on levels k_top .. k_bottom (half levels allowed for landings).
## x0..x1 and the levels are whole tiles; the lint's `hall` rule checks.
static func _halls() -> Array[Dictionary]:
	return [
		# Wickwork's repair hall: the street is a bridge (with a hump) over a tall stepped hall; a hanging shelf
		# (WS) and the repair bay below. x -800..640, levels 8-9.
		{"id": &"H_WK", "x0": -800.0, "x1": 640.0, "k_top": 8, "k_bottom": 9},
		# Glowbeds stepped planter court: levels 5-7, x 5008..6320.
		{"id": &"H_GB", "x0": 5008.0, "x1": 6320.0, "k_top": 4, "k_bottom": 6},
		# Cistern pressure-basin chamber: levels 11-14 at the east end; services street and freight gantry cross it.
		{"id": &"H_CI", "x0": 8096.0, "x1": 9248.0, "k_top": 11, "k_bottom": 14},
	]


static func halls() -> Array[Dictionary]:
	return _halls()


static func hall_rects() -> Array[Rect2]:
	var out: Array[Rect2] = []
	for h in _halls():
		var top := lvl(float(h["k_top"])) - ROOM_HEIGHT
		var bottom := lvl(float(h["k_bottom"]))
		out.append(Rect2(float(h["x0"]), top, float(h["x1"]) - float(h["x0"]), bottom - top))
	return out


## The solid blocks of one roof: Rect2 (x, y, w, h) hanging from y = lvl(k) - ROOM_HEIGHT.
static func roof_blocks(roof: Dictionary) -> Array[Rect2]:
	var out: Array[Rect2] = []
	var n: int = roof["n"]
	var bands := 2 * n - 1
	var x0: float = roof["x0"]
	var w := (float(roof["x1"]) - x0) / float(bands)
	var top := lvl(float(roof["k"])) - ROOM_HEIGHT
	for i in range(bands):
		var step := mini(i, bands - 1 - i) + 1
		out.append(Rect2(x0 + w * float(i), top, w, float(roof["depth"]) * float(step) / float(n)))
	return out


## Every roof block in the map, for painting.
static func roof_rects() -> Array[Rect2]:
	var out: Array[Rect2] = []
	for roof in _roofs():
		out.append_array(roof_blocks(roof))
	return out


static func roofs() -> Array[Dictionary]:
	return _roofs()


## Doors: rock partitions across a room that make pockets (the variety pass). The deck stays continuous; the
## door is solid from the ceiling down to DOOR_OPENING above the deck, so the opening is a doorway. A door
## sits on a dy-0 piece, away from flights, shafts and gates; the lint's `door` rule checks.
static func _doors() -> Array[Dictionary]:
	return [
		{"id": &"DR_MID_EAST", "run": &"E4_2", "x": 7120.0, "kind": &"door"}, # between the Mid-East Landing and the Approach
		{"id": &"DR_AW3", "run": &"AW3_1", "x": -1104.0, "kind": &"arch"},
		{"id": &"DR_AE2", "run": &"AE2", "x": 6960.0, "kind": &"arch"},
		{"id": &"DR_LP13", "run": &"LP13", "x": 400.0, "kind": &"door"},
		{"id": &"DR_LP15", "run": &"LP15", "x": 400.0, "kind": &"arch"},
	]


static func doors() -> Array[Dictionary]:
	return _doors()


## The solid rock of every door: Rect2 (x, y, w, h), painted over the air.
static func door_rects() -> Array[Rect2]:
	var out: Array[Rect2] = []
	for d in _doors():
		var r := run_by_id(d["run"])
		if r.is_empty():
			continue
		var y: float = r["y"]
		var top := minf(y, lvl(float(r["k"]))) - ROOM_HEIGHT
		var x: float = d["x"]
		if d.get("kind", &"door") == &"arch":
			# a stepped archway: a thicker wall (96 px) with the opening one tile taller in the middle
			out.append(Rect2(x - 48.0, top, 32.0, (y - DOOR_OPENING) - top))
			out.append(Rect2(x - 16.0, top, 32.0, (y - DOOR_OPENING - 32.0) - top))
			out.append(Rect2(x + 16.0, top, 32.0, (y - DOOR_OPENING) - top))
		else:
			out.append(Rect2(x - DOOR_THICK * 0.5, top, DOOR_THICK, (y - DOOR_OPENING) - top))
	return out


## A flight between two pieces of a terraced run, from its foot to its top.
static func _flight(id: StringName, zone: StringName, foot_x: float, foot_y: float, top_x: float, top_y: float, dir: int) -> Dictionary:
	return {"id": id, "zone": zone, "dir": dir, "foot_x": foot_x, "foot_y": foot_y, "top_x": top_x, "top_y": top_y}


## One terraced run as {"runs": the pieces, "steps": the flights between them}.
static func _terrace_parts(t: Dictionary) -> Dictionary:
	var runs_out: Array[Dictionary] = []
	var steps_out: Array[Dictionary] = []
	var id := str(t["id"])
	var zone: StringName = t["zone"]
	var k: float = t["k"]
	var pieces: Array = t["pieces"]
	var ends: Array = [] # per piece: [left end, right end]
	for i in range(pieces.size()):
		ends.append([t["l"] if i == 0 else END_FOOT, t["r"] if i == pieces.size() - 1 else END_FOOT])
	for i in range(1, pieces.size()):
		var a: Array = pieces[i - 1]
		var b: Array = pieces[i]
		var ya := lvl(k) + float(a[2])
		var yb := lvl(k) + float(b[2])
		var flight_id := StringName("S_%s_%d" % [id, i])
		if yb < ya:
			# the next piece is higher: the flight rises east from the end of this one
			steps_out.append(_flight(flight_id, zone, a[1], ya, b[0], yb, 1))
			ends[i - 1][1] = END_FOOT
			ends[i][0] = END_TOP
		else:
			# the next piece is lower: the flight rises west from its start
			steps_out.append(_flight(flight_id, zone, b[0], yb, a[1], ya, -1))
			ends[i - 1][1] = END_TOP
			ends[i][0] = END_FOOT
	for i in range(pieces.size()):
		var pc: Array = pieces[i]
		var piece_id := StringName(id if i == 0 else "%s_%d" % [id, i])
		runs_out.append(_run(piece_id, zone, pc[0], pc[1], k, ends[i][0], ends[i][1], pc[2]))
	return {"runs": runs_out, "steps": steps_out}


## ---------------------------------------------------------------- stairs

## dir +1: the flight rises toward +x (foot west, top east). dir -1: rises toward -x.
## pitch is run per rise: 1 = 45 degrees, 1.5 = shallower. Treads stay one tile per riser, so the run
## must come out a whole number of tiles (HollowMapLint checks).
## air is the clear height above the treads (112 for a stairwell; a sloped street, pitch 3 or more, uses 160 so
## it reads as a street climbing a level and not a stair shaft).
static func _stair(id: StringName, zone: StringName, foot_x: float, foot_k: float, dir: int, rise_k: float = 1.0, pitch: float = 1.0, air: float = 112.0) -> Dictionary:
	var foot_y := lvl(foot_k)
	var top_y := lvl(foot_k - rise_k)
	var rise := foot_y - top_y
	return {
		"id": id, "zone": zone, "dir": dir,
		"foot_x": foot_x, "foot_y": foot_y,
		"top_x": foot_x + float(dir) * rise * pitch, "top_y": top_y,
		"air": air,
	}


## Runs kept deliberately plain, as contrast against busier districts. Each is the user's call
## (variety-pass decision 4), so nothing is listed until the user names it. The lint's `flat` warning
## skips these.
static func plain_runs() -> Array[StringName]:
	return []


## A flight this short is a terrace step, not a stair: no stairwell, no "stairs down" cue.
static func is_step(st: Dictionary) -> bool:
	return float(st["foot_y"]) - float(st["top_y"]) < 96.0


static func stairs() -> Array[Dictionary]:
	if _cache.has("stairs"):
		return _cache["stairs"]
	var out: Array[Dictionary] = [
		# West: every stair sits at a corridor end and rises away from it.
		_stair(&"S_A1", &"ashram_west", -160.0, 5, 1, 1.0, 1.5), ## Ashram: promenade up to the overlook
		_stair(&"S_HW3", &"high_west_lower", -800.0, 7, 1, 1.0, 4.0, 160.0), # a sloped street, 1536 px long ## High-West lower gallery up to the terrace
		_stair(&"S_WK5", &"wickwork", -1280.0, 9, -1, 1.0, 3.0, 160.0), # Wickwork's diagonal descent, a sloped street ## Wickwork repair bays up to the street
		_stair(&"S_AL6", &"mid_allotments", 640.0, 10, 1), ## Allotments up to Wickwork's dock
		_stair(&"S_AL7", &"mid_allotments", -1280.0, 11, -1), ## Allotment street up to the residences
		_stair(&"S_LW", &"lower_worker", 640.0, 12, 1), ## Worker Stair: Home Court up to the allotments
		_stair(&"S_BW1", &"bottom_west", -1600.0 - RISE, 13, 1), ## Dispatch yard down to the Bottom-West approach
		_stair(&"S_BW2", &"bottom_west", -3440.0 - RISE, 14, 1), ## Approach down to the dig threshold
		# Mid Heart (open treads over the Mouth): the main crossing climbs over the Ritual deck.
		_stair(&"H_RIT_W", &"mid_heart", RITUAL_LEFT - 0.5 * RISE, 8, 1, 0.5),
		_stair(&"H_RIT_E", &"mid_heart", RITUAL_RIGHT + 0.5 * RISE, 8, -1, 0.5),
		_stair(&"H_FRT_W", &"mid_heart", MOUTH_L, 9, 1, 0.5), ## Wickwork dock to the lower freight tier
		_stair(&"H_FRT_E", &"mid_heart", MOUTH_R, 9, -1, 0.5), ## Mid-East service court to the tier
		_stair(&"H_LH1", &"mid_heart", 2736.0, 9, -1, 0.5), ## the tier down to the lowered dock
		_stair(&"H_LH2", &"mid_heart", 3664.0, 9, 1, 0.5), ## the dock back up to the tier
		_stair(&"H_WG", &"mid_heart", 1632.0, 8, 1, 0.5), ## west lip landing up to the Exchange gallery
		_stair(&"H_WG2", &"mid_heart", 2336.0, 8, -1, 0.5), ## the gallery down to the Exchange landing
		_stair(&"H_EG", &"mid_heart", 4064.0, 8, 1, 0.5), ## the service landing up to the Stewards' gallery
		_stair(&"H_EG2", &"mid_heart", 4768.0, 8, -1, 0.5), ## the gallery down to the east lip landing
		# East
		# Ashram upper wards: processional stairs, alternating direction, one level each
		_stair(&"S_AW_1", &"ashram_west_3", -1280.0, 4, -1),
		_stair(&"S_AW_2", &"ashram_west_2", -480.0, 3, 1, 1.0, 1.5),
		_stair(&"S_AW_3", &"ashram_west_1", -960.0, 2, -1),
		_stair(&"S_AW_4", &"ashram_west_0", -208.0, 1, 1),
		_stair(&"S_AE_1", &"ashram_east_3", 8800.0, 4, 1),
		_stair(&"S_AE_2", &"ashram_east_2", 8208.0, 3, -1),
		_stair(&"S_AE_3", &"ashram_east_1", 8496.0, 2, 1),
		_stair(&"S_AE_4", &"ashram_east_0", 8096.0, 1, -1),
		# Lower Mouth Rows
		_stair(&"S_EP_1", &"east_rows_3", 6208.0, 14, 1, 1.0, 1.0),
		_stair(&"S_EP_2", &"east_rows_5", 6000.0, 16, 1, 1.0, 1.5),
		_stair(&"S_EP_3", &"east_rows_6", 5808.0, 17, -1),
		_stair(&"S_LP_1", &"lower_rows_1", 800.0, 14, 1),
		_stair(&"S_LP_2", &"lower_rows_2", -96.0, 15, -1),
		_stair(&"S_LP_3", &"lower_rows_4", 96.0, 17, 1),
		_stair(&"S_EG3", &"glowbeds", 8000.0, 6, 1),
		_stair(&"S_EM5", &"mid_east_service", 7360.0, 9, 1, 1.0, 2.5, 160.0), # Mid-East service slope
		_stair(&"S_LE6a", &"lower_east_homes", 5760.0, 10, -1, 0.5), ## Lower-East Stair, steep flight up to the landing
		_stair(&"S_LE6b", &"lower_east_homes", 5440.0, 9.5, -1, 0.5, 1.5), ## ...and a shallower flight up to the street
		_stair(&"S_LS7", &"lower_east_services", 6720.0, 11, -1),
		_stair(&"S_CF", &"cistern", 6400.0, 13, -1, 1.0, 2.0, 160.0),
		# stepped-hall flights
		_stair(&"S_WS", &"wickwork", 448.0, 8.5, 1, 0.5, 1.0),
		_stair(&"S_GB_1", &"glowbeds_hang", 5584.0, 6, 1, 0.5, 1.0),
		_stair(&"S_GB_2", &"glowbeds", 6112.0, 5.5, 1, 0.5, 1.0),
		_stair(&"S_CL10", &"cistern_tanks", 7360.0, 14, -1),
	]
	for t in _terraces():
		out.append_array(_terrace_parts(t)["steps"])
	_cache["stairs"] = out
	return out


## ---------------------------------------------------------------- ladders

static func _ladder(id: StringName, zone: StringName, open_x: float, top_k: float, bottom_k: float) -> Dictionary:
	return {"id": id, "zone": zone, "open_x": open_x, "top_y": lvl(top_k), "bottom_y": lvl(bottom_k)}


static func ladders() -> Array[Dictionary]:
	if _cache.has("ladders"):
		return _cache["ladders"]
	var out: Array[Dictionary] = [
		_ladder(&"LAD_A", &"ashram_west", -800.0, 4, 5),
		_ladder(&"LAD_HW", &"high_west_front", -4480.0, 6, 7),
		_ladder(&"LAD_WK4", &"wickwork", -1280.0, 7, 8),
		_ladder(&"LAD_WK5", &"wickwork", -640.0, 8, 9),
		_ladder(&"LAD_AL2", &"mid_allotments", 0.0, 9, 10),
		_ladder(&"LAD_AL", &"mid_allotments", -400.0, 10, 11),
		_ladder(&"LAD_BW", &"bottom_west", -5120.0, 14, 15),
		_ladder(&"LAD_WS1", &"wickwork_slag", -4900.0, 8, 9), # the Expansion Bay down to the slag gallery
		_ladder(&"LAD_WS2", &"wickwork_casting", -4000.0, 9, 10), # the slag gallery down to the casting floor
		_ladder(&"LAD_WK7", &"wickwork_upper", 1340.0, 7, 8), # the street up to the gantry level
		_ladder(&"LAD_GW", &"glowbeds_wing", 5280.0, 6, 7), # the hang down into the recovery wing
		_ladder(&"LAD_EG", &"glowbeds", 7040.0, 5, 6),
		_ladder(&"LAD_GL", &"glowbeds_lower", 6720.0, 6, 7), # the hang down to the lower gardens
		_ladder(&"LAD_GM", &"glowbeds_lower", 7800.0, 7, 8), # the lower gardens down to the Mid-East Approach
		_ladder(&"LAD_EP11", &"east_rows_1", 5072.0, 10, 11),
		_ladder(&"LAD_EP12", &"east_rows_2", 5200.0, 11, 12),
		_ladder(&"LAD_EP15", &"east_rows_4", 5600.0, 14, 15),
		_ladder(&"LAD_EP16", &"east_rows_5", 5700.0, 15, 16),
		_ladder(&"LAD_LP16", &"lower_rows_4", 208.0, 15, 16),
		_ladder(&"LAD_BW2", &"bottom_west_deeper", -3920.0, 15, 16),
		_ladder(&"LAD_BW3", &"bottom_west_lowest", -4800.0, 16, 17),
		# (the Ashram is reached only by the premium lifts; the Lower Mouth Rows and the Mouth balconies on the west
		# freight shaft are reached by that lift)
		_ladder(&"LAD_HW2", &"high_west_front", -2688.0, 6, 7), # High-West upper gallery to the lower
		_ladder(&"LAD_ME10", &"lower_east_homes", 4976.0, 9, 10),
		_ladder(&"LAD_ME13", &"cistern_intake", 5520.0, 12, 13),
		_ladder(&"LAD_LE2", &"lower_east_homes", 7360.0, 10, 11),
		_ladder(&"LAD_EF", &"cistern_freight", 7040.0, 11, 12),
		_ladder(&"LAD_CC", &"cistern", 8000.0, 12, 13),
		_ladder(&"LAD_SE", &"seep_threshold", 8320.0, 14, 15),
	]
	_cache["ladders"] = out
	return out


## ---------------------------------------------------------------- lifts

## Lifts are Presswater elevators (LOCKED: the Cistern's pressurized water drives lifts; Cistern condition
## slows or parks them). Two classes (USER 2026-10-02): a large `freight` elevator that carries you through
## several districts, and a small `premium` elevator, the only way up to Ashram Heights. The cab is
## `width` px wide, the shaft is carved 16 px wider each side, and the lift stops only where a deck covers
## the cab. `essential` lifts never park (they slow instead). `gate` names an Access gate that locks it.
const LIFT_FREIGHT_WIDTH := 160.0
const LIFT_PREMIUM_WIDTH := 96.0


static func _lift(id: StringName, zone: StringName, open_x: float, width: float, stops_k: Array, kind: StringName, essential: bool = false, gate: StringName = FLAG_NONE) -> Dictionary:
	var ys: Array[float] = []
	for k in stops_k:
		ys.append(lvl(float(k)))
	ys.sort()
	return {"id": id, "zone": zone, "open_x": open_x, "width": width, "stops": ys, "kind": kind, "essential": essential, "gate": gate}


static func lifts() -> Array[Dictionary]:
	if _cache.has("lifts"):
		return _cache["lifts"]
	var out: Array[Dictionary] = [
		# West freight elevator: Wickwork down through the Allotments and the Lower Mouth Rows (skips level 14).
		_lift(&"freight_west", &"wickwork", 1200.0, LIFT_FREIGHT_WIDTH, [8, 9, 10, 11, 12, 13, 15], &"freight"),
		# East freight elevator: Mid-East down through Lower-East and the Cistern basin chamber to the tanks (it stops short of the flood gate).
		_lift(&"freight_east", &"cistern_freight", 8704.0, LIFT_FREIGHT_WIDTH, [8, 11, 12, 13, 14], &"freight"),
		# Premium Ashram elevators: Wickwork / Glowbeds up through the guarded galleries to the Ashram lobby.
		# Mid Heart masts: freight cabs up the Ritual hall from the freight tier to the Ritual Raft and the Council Terrace
		_lift(&"heart_mast_west", &"mid_heart", 2752.0, LIFT_FREIGHT_WIDTH, [6, 7.5, 9], &"freight"),
		_lift(&"heart_mast_east", &"mid_heart", 3488.0, LIFT_FREIGHT_WIDTH, [6, 7.5, 9], &"freight"),
		_lift(&"ashram_west", &"wickwork", -2560.0, LIFT_PREMIUM_WIDTH, [5, 6, 7, 8], &"premium", true),
		_lift(&"ashram_east", &"mid_east", 6416.0, LIFT_PREMIUM_WIDTH, [4, 5, 6, 8], &"premium", true),
	]
	_cache["lifts"] = out
	return out


## Zones reachable only by a lift: with every lift ignored they must be unreachable (lint rule `lift_only`).
static func lift_only_zones() -> Array[StringName]:
	return [&"ashram_west", &"ashram_west_3", &"ashram_west_2", &"ashram_west_1", &"ashram_west_0",
		&"ashram_east", &"ashram_east_3", &"ashram_east_2", &"ashram_east_1", &"ashram_east_0"]


## ---------------------------------------------------------------- gates

static func _gate(id: StringName, run: StringName, x: float, label: String, explanation: String, blocks: bool = true, trust: StringName = &"", flag: StringName = &"", residence: StringName = &"", beyond: int = 1) -> Dictionary:
	## blocks=false: a logic gate  with no bar across the deck.
	return {
		"id": id, "run": run, "x": x, "label": label, "explanation": explanation, "blocks": blocks,
		"trust": trust, "flag": flag, "residence": residence, "beyond": beyond,
	}


static func gates() -> Array[Dictionary]:
	if _cache.has("gates"):
		return _cache["gates"]
	var out: Array[Dictionary] = [
		_gate(&"gate_ashram_west", &"A1", -1920.0, "Ashram west gate",
			"Wardens keep the Heights gate. Residents and cleared workers only.", true, &"", &"ashram_clearance"),
		_gate(&"gate_high_west", &"HW2_2", -3520.0, "High-West checkpoint",
			"The High-West gallery is guarded work. Wardens pass only cleared crews.", true, &"", &"high_west_cleared", &"", -1),
		_gate(&"gate_high_west_low", &"HW3_2", -3520.0, "High-West lower checkpoint",
			"The High-West gallery is guarded work. Wardens pass only cleared crews.", true, &"", &"high_west_cleared", &"", -1),
		_gate(&"gate_bw_deep", &"BW11", -4480.0, "Bottom-West service gate",
			"Sealed past the collapse. The deeper service run is not open yet.", true, &"", &"bottom_west_service_open"),
		_gate(&"gate_ashram_east", &"E1_4", 7040.0, "Ashram east gate",
			"Wardens keep the Heights gate. Residents and cleared workers only.", true, &"", &"ashram_clearance"),
		_gate(&"gate_mid_east_dig", &"E4_4", EAST_WALL, "Mid-East dig front gate",
			"The Mid-East front opens once the Stewards clear the shock-fault survey.", true, &"", &"mid_east_survey_cleared"),
		# Growth rooms (USER 2026-10-03: a district gains rooms at its milestones). Flag names are AI-proposed; what
		# earns each flag is OPEN (the upgrade rules are not designed), so today they stay shut until story sets them.
		_gate(&"gate_wickwork_growth", &"WK4_2", -3600.0, "Wickwork expansion bulkhead",
			"The bay west of here is sealed. The workshop expansion is not authorized yet.", true, &"", &"wickwork_expansion", &"", -1),
		_gate(&"gate_glowbeds_growth", &"E2_6", 8720.0, "Glowbeds expansion bulkhead",
			"The planter court's far end is sealed. The next cultivation tier is not open yet.", true, &"", &"glowbeds_expansion"),
		_gate(&"gate_glowbeds_wing", &"GW7", 5440.0, "Glowbeds recovery wing bulkhead",
			"The recovery and cultures wing is sealed. The Glowbeds expansion is not authorized yet.", true, &"", &"glowbeds_recovery_wing"),
		_gate(&"gate_cistern_growth", &"E10_2", EAST_WALL, "Cistern tank bulkhead",
			"The tank annex is sealed. The pressure expansion is not authorized yet.", true, &"", &"cistern_expansion"),
		_gate(&"gate_cistern_deep", &"E11_2", 8640.0, "Cistern flood gate",
			"The flood gate is sealed. Nothing past it is safe or sanctioned.", true, &"", &"cistern_flood_gate_open"),
	]
	_cache["gates"] = out
	return out


## Gates that are shut at the start of Act 1 and block walking.
static func closed_at_start() -> Array[StringName]:
	return [&"gate_ashram_west", &"gate_high_west", &"gate_high_west_low", &"gate_bw_deep", &"gate_ashram_east", &"gate_mid_east_dig", &"gate_cistern_deep", &"gate_wickwork_growth", &"gate_glowbeds_growth", &"gate_glowbeds_wing", &"gate_cistern_growth"]


## Zones a new player must be able to reach with every start-closed gate shut: every main district
## (Wickwork, Allotments, Mid Heart, Glowbeds, the Lower-East homes and services, the Cistern).
## Everything else is deliberately held back for story (Ashram Heights, the High-West and Mid-East
## dig fronts, the deep service runs).
static func early_zones() -> Array[StringName]:
	return [
		&"home_court", &"lower_switchback", &"west_dispatch_yard", &"worker_return_ascent",
		&"east_rows_1", &"east_rows_2", &"east_rows_3", &"east_rows_4", &"east_rows_5", &"east_rows_6",
		&"lower_rows_1", &"lower_rows_2", &"lower_rows_3", &"lower_rows_4", &"lower_rows_5",
		&"lower_lift_landing", &"bottom_west_approach", &"bottom_west_threshold", &"first_expansion_gallery", &"collapsed_side_chamber",
		&"wickwork", &"wickwork_upper", &"mid_allotments", &"mid_heart", &"mid_heart_upper",
		&"mid_east_landing", &"mid_east_approach", &"mid_east_service", &"glowbeds", &"glowbeds_hang", &"glowbeds_lower",
		&"lower_east_homes", &"lower_east_services", &"cistern_freight", &"cistern_intake", &"cistern", &"cistern_tanks", &"seep_threshold",
	]


## Standing points (feet on a deck) that must be walled off at the start and reachable once the
## gates open. Early-game zones are the opposite list above.
static func held_points() -> Array[Vector2]:
	return [
		Vector2(-1500.0, lvl(5)), ## Ashram west promenade, past the gate
		Vector2(-1000.0, lvl(4)), ## Ashram west residences
		Vector2(-1500.0, lvl(3)), ## Ashram west third tier
		Vector2(-100.0, lvl(0)), ## Ashram west summit
		Vector2(8700.0, lvl(3)), ## Ashram east third tier
		Vector2(7500.0, lvl(0)), ## Ashram east summit
		Vector2(-4500.0, lvl(6)), ## High-West gallery, upper
		Vector2(-5000.0, lvl(7)), ## High-West gallery, lower
		Vector2(-4000.0, lvl(15)), ## Bottom-West service run
		Vector2(7500.0, lvl(4)), ## Ashram east residences, past the gate
		Vector2(5600.0, lvl(7)), ## Glowbeds recovery wing
		Vector2(11200.0, lvl(8)), ## Mid-East dig front
		Vector2(-5000.0, lvl(16)), ## Bottom-West deeper gallery (behind the service-run gate)
		Vector2(-5000.0, lvl(17)), ## Bottom-West lowest gallery
		Vector2(9000.0, lvl(15)), ## Cistern flood gate side
		Vector2(-4800.0, lvl(8)), ## Wickwork expansion bay
		Vector2(-5000.0, lvl(9)), ## Wickwork slag gallery
		Vector2(-5000.0, lvl(10)), ## Wickwork casting floor
		Vector2(9100.0, lvl(5)), ## Glowbeds expansion court
		Vector2(10000.0, lvl(14)), ## Cistern tank annex
	]


## ---------------------------------------------------------------- growth reserves

static func _reserve(id: StringName, district: StringName, rect: Rect2, note: String) -> Dictionary:
	return {"id": id, "district": district, "rect": rect, "note": note}


## Empty, rock-backed footprints a district grows into. Nothing may be built in them and each
## must touch a run of its own district (HollowMapLint rule "reserve").
static func reserves() -> Array[Dictionary]:
	if _cache.has("reserves"):
		return _cache["reserves"]
	var out: Array[Dictionary] = [
		# R_WICKWORK, R_GLOWBEDS and R_CISTERN became growth rooms (USER 2026-10-03): see the gate_*_growth gates.
		_reserve(&"R_BW_DEEP", &"bottom_west", Rect2(-3200.0 + WALL_THICK, lvl(15) - ROOM_HEIGHT, 320.0, ROOM_HEIGHT + 96.0),
			"Bottom-West's locked deeper service run continues toward the civic wall."),
	]
	_cache["reserves"] = out
	return out


## ---------------------------------------------------------------- zones

static func _zone(id: StringName, display: String, x0: float, x1: float, k0: float, k1: float, anchor_x: float, anchor_k: float, enclosed: bool = false, restricted: bool = false) -> Dictionary:
	var top := lvl(k0) - ROOM_HEIGHT
	var bottom := lvl(k1) + (LEVEL_GAP - ROOM_HEIGHT)
	return {
		"id": id, "display": display, "enclosed": enclosed, "restricted": restricted,
		"rect": Rect2(x0, top, x1 - x0, bottom - top),
		"anchor": Vector2(anchor_x, lvl(anchor_k)),
	}


## Named places. `restricted` marks unsanctioned-dig evidence zones (Terrain reads it), so it is true only
## for the Firmament volume; guarded places are gated, not restricted. Rects never overlap (HollowMapLint) except the two dig volumes at the end,
## which have no deck and no seams. Each non-volume anchor must stand on a deck.
static func zones() -> Array[Dictionary]:
	if _cache.has("zones"):
		return _cache["zones"]
	var out: Array[Dictionary] = [
		# West
		_zone(&"ashram_west", "Ashram Heights (west)", -2720.0, 1440.0 + ledge_max(4.0), 4, 5, -200.0, 4),
		_zone(&"high_west_ledge", "High-West Rail Ledge", 1440.0, 1440.0 + ledge_max(6.0), 6, 6, 1456.0, 6),
		_zone(&"ashram_west_3", "Ashram Heights (west), third tier", -2400.0, -480.0, 3, 3, -1500.0, 3),
		_zone(&"ashram_west_2", "Ashram Heights (west), second tier", -960.0, 448.0, 2, 2, -300.0, 2),
		_zone(&"ashram_west_1", "Ashram Heights (west), first tier", -2000.0, -208.0, 1, 1, -1000.0, 1),
		_zone(&"ashram_west_0", "Ashram Heights (west), summit", -608.0, 448.0, 0, 0, -100.0, 0),
		_zone(&"high_west_front", "High-West Dig Front", WEST_FLANK_LEFT, 1440.0, 6, 6, -3000.0, 6),
		_zone(&"high_west_lower", "High-West Lower Gallery", WEST_FLANK_LEFT, -768.0, 7, 7, -3000.0, 7),
		_zone(&"wickwork_annex", "Wickwork Expansion Bay", -5440.0, -3680.0, 8, 8, -4800.0, 8, true),
		_zone(&"wickwork_slag", "Wickwork Slag Gallery", -5440.0, -3680.0, 9, 9, -5000.0, 9, true),
		_zone(&"wickwork_casting", "Wickwork Casting Floor", -5440.0, -3008.0, 10, 10, -5000.0, 10, true),
		_zone(&"wickwork_upper", "Wickwork Gantry", 1200.0, 1760.0, 7, 7, 1500.0, 7, true),
		_zone(&"wickwork", "Wickwork", -3680.0, 1440.0, 8, 9, -2160.0, 8, true),
		_zone(&"mid_allotments", "Mid Allotments", -2400.0, 1440.0 + ledge_max(10.0), 10, 11, -1500.0, 10),
		_zone(&"west_dispatch_yard", "West Dispatch Yard", -1600.0, -800.0, 12, 12, -1320.0, 12, true),
		_zone(&"lower_switchback", "Lower Switchback", -800.0, -320.0, 12, 12, -560.0, 12, true),
		_zone(&"home_court", "Home Court", -320.0, 160.0, 12, 12, -80.0, 12, true),
		_zone(&"worker_return_ascent", "Worker Stair Hall", 160.0, 1440.0 + ledge_max(12.0), 12, 12, 400.0, 12),
		_zone(&"lower_rows_1", "Lower Mouth Rows, first row", -320.0, 1568.0, 13, 13, 200.0, 13),
		_zone(&"lower_rows_2", "Lower Mouth Rows, second row", -640.0, 1440.0, 14, 14, -300.0, 14),
		_zone(&"lower_rows_3", "Lower Mouth Rows, third row", -160.0, 1568.0, 15, 15, 300.0, 15),
		_zone(&"lower_rows_4", "Lower Mouth Rows, fourth row", -800.0, 1440.0, 16, 16, -300.0, 16),
		_zone(&"lower_rows_5", "Lower Mouth Rows, lowest row", -800.0, 1440.0, 17, 17, -400.0, 17),
		_zone(&"bottom_west_deeper", "Bottom-West Deeper Gallery", WEST_FLANK_LEFT, -3200.0, 16, 16, -5200.0, 16, true),
		_zone(&"bottom_west_lowest", "Bottom-West Lowest Gallery", WEST_FLANK_LEFT, -3200.0, 17, 17, -5200.0, 17, true),
		_zone(&"lower_lift_landing", "Lower Landing", -3440.0, -2800.0, 13, 13, -3100.0, 13, true),
		_zone(&"bottom_west_approach", "Bottom-West Approach", -2800.0, -1600.0, 13, 13, -2400.0, 13, true),
		_zone(&"first_expansion_gallery", "First Expansion Gallery", WEST_FLANK_LEFT, -4640.0, 14, 14, -5000.0, 14, true),
		_zone(&"bottom_west_threshold", "Bottom-West Threshold", -4640.0, -3440.0, 14, 14, -4400.0, 14, true),
		_zone(&"collapsed_side_chamber", "Collapsed Side Chamber", WEST_FLANK_LEFT, -4480.0, 15, 15, -5440.0, 15, true),
		_zone(&"bottom_west_deep", "Bottom-West Service Run", -4480.0, -3200.0, 15, 15, -4000.0, 15, true),
		# Mid Heart
		_zone(&"mid_heart", "Mid Heart", MOUTH_L, MOUTH_R, 8, 9, 3200.0, 7.5),
		_zone(&"mid_heart_upper", "Upper Heart, the Council Terrace", 2416.0, 3984.0, 6, 6, 3200.0, 6),
		# East
		_zone(&"ashram_east", "Ashram Heights (east)", MOUTH_R - ledge_max(4.0), 8800.0, 4, 4, 6200.0, 4),
		_zone(&"ashram_east_3", "Ashram Heights (east), third tier", 8208.0, 9248.0, 3, 3, 8700.0, 3),
		_zone(&"ashram_east_2", "Ashram Heights (east), second tier", 6608.0, 8496.0, 2, 2, 6900.0, 2),
		_zone(&"ashram_east_1", "Ashram Heights (east), first tier", 8096.0, 9248.0, 1, 1, 8600.0, 1),
		_zone(&"ashram_east_0", "Ashram Heights (east), summit", 6896.0, 8304.0, 0, 0, 7500.0, 0),
		_zone(&"glowbeds", "Glowbeds", MOUTH_R - ledge_max(5.0), 8800.0, 5, 5, 5200.0, 5),
		_zone(&"glowbeds_annex", "Glowbeds Expansion Court", 8800.0, 10432.0, 5, 5, 9100.0, 5),
		_zone(&"glowbeds_hang", "Glowbeds Hang", MOUTH_R - ledge_max(6.0), 8000.0, 6, 6, 7200.0, 6),
		_zone(&"glowbeds_wing", "Glowbeds Recovery Wing", 5184.0, 6368.0, 7, 7, 5600.0, 7),
		_zone(&"glowbeds_lower", "Glowbeds Lower Gardens", 6560.0, 8100.0, 7, 7, 6800.0, 7),
		_zone(&"mid_east_landing", "Mid-East Landing", MOUTH_R, 7040.0, 8, 8, 5840.0, 8),
		_zone(&"mid_east_approach", "Mid-East Approach", 7040.0, EAST_WALL, 8, 8, 7680.0, 8),
		_zone(&"mid_east_dig_front", "Mid-East Dig Front", EAST_WALL, EAST_FLANK_RIGHT, 8, 8, 9600.0, 8),
		_zone(&"mid_east_service", "Mid-East Service Court", MOUTH_R, 7360.0, 9, 9, 6080.0, 9),
		_zone(&"lower_east_homes", "Lower-East Homes", MOUTH_R - ledge_max(10.0), 8000.0, 10, 10, 6800.0, 10),
		_zone(&"lower_east_services", "Lower-East Services", 6720.0, EAST_WALL, 11, 11, 7200.0, 11),
		_zone(&"cistern_freight", "Cistern Freight Landing", 5440.0, EAST_WALL, 12, 12, 7360.0, 12),
		_zone(&"east_rows_1", "Lower-East Mouth Rows, first row", MOUTH_R - ledge_max(11.0), 6240.0, 11, 11, 5600.0, 11),
		_zone(&"east_rows_2", "Lower-East Mouth Rows, second row", 4864.0, 5376.0, 12, 12, 5000.0, 12),
		_zone(&"east_rows_3", "Cistern Mouth Rows, first row", 4896.0, 6208.0, 14, 14, 5400.0, 14, true),
		_zone(&"east_rows_4", "Cistern Mouth Rows, second row", 5200.0, 6304.0, 15, 15, 5800.0, 15, true),
		_zone(&"east_rows_5", "Cistern Mouth Rows, third row", 4864.0, 6000.0, 16, 16, 5300.0, 16, true),
		_zone(&"east_rows_6", "Cistern Mouth Rows, lowest row", 5808.0, 7008.0, 17, 17, 6400.0, 17, true),
		_zone(&"cistern_intake", "Cistern Intake Ledge", 4864.0, 5600.0, 13, 13, 5200.0, 13, true),
		_zone(&"cistern", "Cistern", 6400.0, EAST_WALL, 13, 13, 7200.0, 13, true),
		_zone(&"cistern_tanks", "Cistern Tanks", 7360.0, EAST_WALL, 14, 14, 8000.0, 14, true),
		_zone(&"cistern_annex", "Cistern Tank Annex", EAST_WALL, 10592.0, 14, 14, 10000.0, 14, true),
		_zone(&"seep_threshold", "Seep Gallery", 6400.0, EAST_WALL, 15, 15, 7200.0, 15, true),
	]
	# Dig volumes: the rock shell, not places you stand. No seams, no deck. Where a gallery zone
	# overlaps a flank volume the smaller rect wins (Zones.get_zone_at), so galleries read as themselves.
	out.append({"id": &"firmament", "display": "Firmament", "enclosed": true, "restricted": true,
		"rect": Rect2(ENV_LEFT, ENV_TOP, ENV_RIGHT - ENV_LEFT, ROCK_TOP - ENV_TOP), "anchor": Vector2(HEART_X, ROCK_TOP * 0.5), "volume": true})
	out.append({"id": &"east_dig_site", "display": "East Dig Site", "enclosed": true, "restricted": false,
		"rect": Rect2(EAST_WALL, ROCK_TOP, ENV_RIGHT - EAST_WALL, ENV_BOTTOM - ROCK_TOP), "anchor": Vector2(EAST_WALL + SIDE_DEPTH * 0.5, lvl(10)), "volume": true})
	out.append({"id": &"west_dig_site", "display": "West Dig Site", "enclosed": true, "restricted": false,
		"rect": Rect2(ENV_LEFT, ROCK_TOP, WEST_WALL - ENV_LEFT, ENV_BOTTOM - ROCK_TOP), "anchor": Vector2(WEST_WALL - SIDE_DEPTH * 0.5, lvl(10)), "volume": true})
	_cache["zones"] = out
	return out


## ---------------------------------------------------------------- derived: geometry

static func run_by_id(id: StringName) -> Dictionary:
	if not _cache.has("run_index"):
		var idx: Dictionary = {}
		for r in runs():
			idx[r["id"]] = r
		_cache["run_index"] = idx
	return (_cache["run_index"] as Dictionary).get(id, {})


## Deck pieces: the runs themselves. Decks are one-way (HollowTerrain), so ladders and
## stairs pass through them with no hole cut — a street is never split. Kept as pieces so a
## future cut (a collapsed floor, a trapdoor) has one place to go.
static func deck_pieces() -> Array[Dictionary]:
	if _cache.has("pieces"):
		return _cache["pieces"]
	var out: Array[Dictionary] = []
	for r in runs():
		out.append({"run": r["id"], "x0": r["x0"], "x1": r["x1"], "y": r["y"]})
	_cache["pieces"] = out
	return out


## Stair openings (2026-10-02, USER): where a flight rises through a street, the street's deck is simply
## absent over the last stretch before the stair top, so you climb out of an open stairwell and drop into
## it from either side; there is no one-way covering and no key to press. The opening is as long as the
## flight needs for a body to stand on the tread under the deck: 64 px of depth per unit of pitch, plus a
## margin of two tiles. Terrace steps (rise under 96 px) have no street over them and no opening.
static func stair_hole_length(s: Dictionary) -> float:
	var rise := float(s["foot_y"]) - float(s["top_y"])
	if rise < 96.0:
		return 0.0
	var pitch := absf(float(s["top_x"]) - float(s["foot_x"])) / rise
	return ceilf((64.0 * pitch + 32.0) / 16.0) * 16.0


## The openings as {"id", "x0", "x1", "y"}: columns the street deck at y skips. A flight rising east leaves its
## top tread at top_x and the opening runs west of it; rising west, the opening runs east of the top tread.
static func stair_holes() -> Array[Dictionary]:
	if _cache.has("stair_holes"):
		return _cache["stair_holes"]
	var out: Array[Dictionary] = []
	for s in stairs():
		var l := stair_hole_length(s)
		if l <= 0.0:
			continue
		var tx: float = s["top_x"]
		if int(s["dir"]) > 0:
			out.append({"id": s["id"], "x0": tx - l, "x1": tx, "y": s["top_y"]})
		else:
			out.append({"id": s["id"], "x0": tx + 16.0, "x1": tx + 16.0 + l, "y": s["top_y"]})
	_cache["stair_holes"] = out
	return out


## Lift shaft openings (USER 2026-10-02): where an elevator shaft passes a street, the deck tiles are cut across the
## cab's width at every stop, so the cab rides through an opening in the floor and not through solid-looking
## tiles. Each stop keeps an invisible one-way landing plate (hollow_structures.gd) so nobody falls into the shaft.
static func lift_holes() -> Array[Dictionary]:
	if _cache.has("lift_holes"):
		return _cache["lift_holes"]
	var out: Array[Dictionary] = []
	for lf in lifts():
		for y in lf["stops"]:
			out.append({"id": lf["id"], "x0": float(lf["open_x"]), "x1": float(lf["open_x"]) + float(lf["width"]), "y": float(y)})
	_cache["lift_holes"] = out
	return out


static func in_hole(x: float, y: float) -> bool:
	for h in stair_holes():
		if absf(float(h["y"]) - y) < 0.5 and x >= float(h["x0"]) and x < float(h["x1"]):
			return true
	for h in lift_holes():
		if absf(float(h["y"]) - y) < 0.5 and x >= float(h["x0"]) and x < float(h["x1"]):
			return true
	return false


## Deck rects Vector4(x0, x1, y, thickness) as painted: every run piece minus the stair openings in it.
static func deck_rects() -> Array[Vector4]:
	var out: Array[Vector4] = []
	for p in deck_pieces():
		var segs: Array[Vector2] = [Vector2(float(p["x0"]), float(p["x1"]))]
		var holes: Array[Dictionary] = []
		holes.append_array(stair_holes())
		holes.append_array(lift_holes())
		for h in holes:
			if absf(float(h["y"]) - float(p["y"])) > 0.5:
				continue
			var next: Array[Vector2] = []
			for sg in segs:
				if float(h["x1"]) <= sg.x or float(h["x0"]) >= sg.y:
					next.append(sg)
					continue
				if float(h["x0"]) > sg.x:
					next.append(Vector2(sg.x, float(h["x0"])))
				if float(h["x1"]) < sg.y:
					next.append(Vector2(float(h["x1"]), sg.y))
			segs = next
		for sg in segs:
			if sg.y - sg.x >= 16.0:
				out.append(Vector4(sg.x, sg.y, p["y"], FLOOR_THICK))
	return out


## Mid Heart and the Upper Heart over it: the zones of the one cluster over the Mouth (no rock, no rooms).
static func is_heart_zone(zone: StringName) -> bool:
	return zone == &"mid_heart" or zone == &"mid_heart_upper"


## Wall columns for every END_WALL run side: Rect2 (x, y_top, w, h), standing on the deck.
static func wall_rects() -> Array[Rect2]:
	var out: Array[Rect2] = []
	for r in runs():
		if r["l"] == END_WALL:
			out.append(Rect2(float(r["x0"]) - WALL_THICK, float(r["y"]) - ROOM_HEIGHT, WALL_THICK, ROOM_HEIGHT))
		if r["r"] == END_WALL:
			out.append(Rect2(float(r["x1"]), float(r["y"]) - ROOM_HEIGHT, WALL_THICK, ROOM_HEIGHT))
	return out


## Closed-gate collision bars: Rect2 standing on the deck at the gate's x.
static func gate_rects() -> Array[Rect2]:
	var out: Array[Rect2] = []
	for g in gates():
		var r := run_by_id(g["run"])
		if r.is_empty() or not g["blocks"]:
			continue
		out.append(Rect2(float(g["x"]) - 16.0, float(r["y"]) - 128.0, 32.0, 128.0))
	return out


## True when (x, y) is on a half-level landing run.
static func is_landing_at(x: float, y: float) -> bool:
	for r in runs():
		if bool(r["landing"]) and absf(float(r["y"]) - y) < 0.5 and x >= float(r["x0"]) - 0.5 and x <= float(r["x1"]) + 0.5:
			return true
	return false


static func in_flank(x: float) -> bool:
	return x < WEST_WALL + 0.5 or x > EAST_WALL - 0.5


## Air to carve out of dig-flank rock: every flank run needs walk air; stairs and ladders need theirs.
## Rect2 (x, y_top, w, h). Terrain clears these cells, then keeps a thin diggable face above.
static func flank_air_rects(walk_clear: float) -> Array[Rect2]:
	var out: Array[Rect2] = []
	for r in runs():
		var x0: float = r["x0"]
		var x1: float = r["x1"]
		if x1 <= WEST_WALL + 0.5:
			pass
		elif x0 >= EAST_WALL - 0.5:
			pass
		elif x0 < WEST_WALL and x1 > WEST_WALL:
			x1 = WEST_WALL
		elif x0 < EAST_WALL and x1 > EAST_WALL:
			x0 = EAST_WALL
		else:
			continue
		out.append(Rect2(x0, float(r["y"]) - walk_clear, x1 - x0, walk_clear))
	for l in ladders():
		var lx: float = l["open_x"]
		if in_flank(lx):
			out.append(Rect2(lx, float(l["top_y"]) - walk_clear, SHAFT_OPENING, float(l["bottom_y"]) - float(l["top_y"]) + walk_clear))
	return out


## Flank stair air: per tread column, the 96px above the tread. Returns Rect2 columns of TILE width.
static func flank_stair_air(walk_clear: float) -> Array[Rect2]:
	var out: Array[Rect2] = []
	var tile := float(HollowLayout.TILE)
	for s in stairs():
		var fx: float = s["foot_x"]
		var tx: float = s["top_x"]
		if not (in_flank(fx) and in_flank(tx)):
			continue
		var steps := int(absf(tx - fx) / tile)
		var dir := signf(tx - fx)
		for i in range(steps + 1):
			var x := fx + dir * tile * float(i)
			var y := lerpf(float(s["foot_y"]), float(s["top_y"]), float(i) / float(steps))
			out.append(Rect2(minf(x, x + dir * tile), y - walk_clear, tile, walk_clear))
	return out


## ---------------------------------------------------------------- derived: the rock shell

## Everything the dig envelope covers.
static func env_rect() -> Rect2:
	return Rect2(ENV_LEFT, ENV_TOP, ENV_RIGHT - ENV_LEFT, ENV_BOTTOM - ENV_TOP)


## The civic void: the Hollow's cut-away, from under the Firmament to the floor slab. Not rock.
static func cavity_rect() -> Rect2:
	return Rect2(WEST_WALL, ROCK_TOP, EAST_WALL - WEST_WALL, CAVITY_BOTTOM - ROCK_TOP)


## The pit: the Mouth stays open from the cavity down to the bottom of the envelope.
static func pit_rect() -> Rect2:
	return Rect2(MOUTH_L, CAVITY_BOTTOM, MOUTH_R - MOUTH_L, ENV_BOTTOM - CAVITY_BOTTOM)


## True where the shell is solid diggable rock before any carving: inside the envelope, outside
## the civic cavity and the pit.
static func is_shell_point(p: Vector2) -> bool:
	return env_rect().has_point(p) and not cavity_rect().has_point(p) and not pit_rect().has_point(p)


static func level_ys() -> Array[float]:
	var out: Array[float] = []
	for k in range(LEVELS):
		out.append(lvl(float(k)))
	return out
