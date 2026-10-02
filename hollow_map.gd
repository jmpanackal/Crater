class_name HollowMap
extends Object
## THE Hollow map, as data. Everything walkable, climbable, rideable or gated is declared
## here once; terrain painting, scene structures (ladders, lifts, gates, zone anchors),
## carving, the minimap and HollowMapLint all derive from it. See docs/hollow-map-spec.md.
##
## Model: a cut-away of rock with carved rooms.
##   run      a walkable deck (a room's floor) at one level, with an end type on each side
##   stair    a 45-degree flight between two decks; a solid wedge below. The deck above is one-way,
##            so the flight rises through it; Down steps back through (HollowTerrain, player.gd)
##   ladder   a shaft climbed with W/S; decks are one-way, so there is no hatch
##   lift     a Presswater cage; it rides up through one-way decks, so there is no gap
##   gate     a physical access barrier on a run
##   reserve  empty footprint kept for a district's growth (nothing may be built in it)
##   zone     a named place: rect + anchor standing on a deck
##
## Levels sit on one grid: y = LEVEL_ORIGIN + LEVEL_GAP * k (k = 0..11). Half levels (k + 0.5)
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
const FLOOR_THICK := 32.0
const WALL_THICK := 32.0
## Stairs are 45 degrees, so a flight is as long as the level gap is tall.
const RISE := LEVEL_GAP
## Width of a ladder or lift shaft (the cage and the ladder frame are sized to the body).
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
const BOTTOM_LEVEL_Y := LEVEL_ORIGIN + LEVEL_GAP * 11.0
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

const FLAG_NONE := &""

## Mid Heart's raised Ritual deck (x), centred on the Mouth.
const RITUAL_LEFT := 2720.0
const RITUAL_RIGHT := 3680.0
## Centre line of the Mouth.
const HEART_X := (MOUTH_L + MOUTH_R) * 0.5

static var _cache: Dictionary = {}


static func lvl(k: float) -> float:
	return LEVEL_ORIGIN + LEVEL_GAP * k


## ---------------------------------------------------------------- runs

static func _run(id: StringName, zone: StringName, x0: float, x1: float, k: float, l: StringName, r: StringName) -> Dictionary:
	return {"id": id, "zone": zone, "x0": x0, "x1": x1, "k": k, "y": lvl(k), "l": l, "r": r}


static func runs() -> Array[Dictionary]:
	if _cache.has("runs"):
		return _cache["runs"]
	var out: Array[Dictionary] = [
		# ---- WEST WALL ----
		_run(&"A0", &"ashram_west", -1280.0, 1440.0, 0, END_WALL, END_MOUTH),
		_run(&"A1", &"ashram_west", -2720.0, -160.0, 1, END_WALL, END_FOOT),
		_run(&"HW2", &"high_west_front", WEST_FLANK_LEFT, 1440.0, 2, END_ROCK, END_MOUTH),
		_run(&"HW3", &"high_west_front", WEST_FLANK_LEFT, -800.0, 3, END_ROCK, END_FOOT),
		_run(&"WK4", &"wickwork", -3680.0, 1440.0, 4, END_ROCK, END_JOIN),
		_run(&"WK5", &"wickwork", -1280.0, 1440.0, 5, END_FOOT, END_MOUTH),
		_run(&"AL6", &"mid_allotments", -2400.0, 640.0, 6, END_WALL, END_FOOT),
		_run(&"AL7", &"mid_allotments", -1280.0, 1440.0, 7, END_FOOT, END_MOUTH),
		_run(&"LW8", &"lower_worker", -1600.0, 640.0, 8, END_TOP, END_FOOT),
		_run(&"BW9", &"bottom_west", -3440.0, -1600.0 - RISE, 9, END_TOP, END_FOOT),
		_run(&"BW10", &"bottom_west", WEST_FLANK_LEFT, -3440.0 - RISE, 10, END_ROCK, END_FOOT),
		_run(&"BW11", &"bottom_west", WEST_FLANK_LEFT, -3200.0, 11, END_ROCK, END_WALL),
		# ---- MID HEART (the only structure over the Mouth) ----
		_run(&"HM_W", &"mid_heart", MOUTH_L, RITUAL_LEFT - 0.5 * RISE, 4, END_JOIN, END_FOOT),
		_run(&"HM_R", &"mid_heart", RITUAL_LEFT, RITUAL_RIGHT, 3.5, END_TOP, END_TOP),
		_run(&"HM_E", &"mid_heart", RITUAL_RIGHT + 0.5 * RISE, MOUTH_R, 4, END_FOOT, END_JOIN),
		_run(&"HM_F", &"mid_heart", MOUTH_L + 0.5 * RISE, MOUTH_R - 0.5 * RISE, 4.5, END_TOP, END_TOP),
		# ---- EAST WALL ----
		_run(&"E0", &"ashram_east", 6400.0, 8800.0, 0, END_WALL, END_WALL),
		_run(&"E1", &"ashram_east", 5760.0, 8000.0, 1, END_WALL, END_FOOT),
		_run(&"E2", &"glowbeds", 5120.0, 8800.0, 2, END_WALL, END_WALL),
		_run(&"E3", &"glowbeds_hang", 5760.0, 8000.0, 3, END_WALL, END_FOOT),
		_run(&"E4", &"mid_east", MOUTH_R, EAST_FLANK_RIGHT, 4, END_JOIN, END_ROCK),
		_run(&"E5", &"mid_east_service", MOUTH_R, 7360.0, 5, END_FOOT, END_FOOT),
		_run(&"E6", &"lower_east_homes", 5760.0, 8000.0, 6, END_FOOT, END_WALL),
		_run(&"E7", &"lower_east_services", 6720.0, EAST_WALL, 7, END_FOOT, END_WALL),
		_run(&"E8", &"cistern_freight", 5440.0, EAST_WALL, 8, END_WALL, END_WALL),
		_run(&"E9", &"cistern", 6400.0, EAST_WALL, 9, END_FOOT, END_WALL),
		_run(&"E10", &"cistern_tanks", 7360.0, EAST_WALL, 10, END_FOOT, END_WALL),
		_run(&"E11", &"seep_threshold", 6400.0, EAST_WALL, 11, END_WALL, END_WALL),
	]
	_cache["runs"] = out
	return out


## ---------------------------------------------------------------- stairs

## dir +1: the flight rises toward +x (foot west, top east). dir -1: rises toward -x.
static func _stair(id: StringName, zone: StringName, foot_x: float, foot_k: float, dir: int, rise_k: float = 1.0) -> Dictionary:
	var foot_y := lvl(foot_k)
	var top_y := lvl(foot_k - rise_k)
	var rise := foot_y - top_y
	return {
		"id": id, "zone": zone, "dir": dir,
		"foot_x": foot_x, "foot_y": foot_y,
		"top_x": foot_x + float(dir) * rise, "top_y": top_y,
	}


static func stairs() -> Array[Dictionary]:
	if _cache.has("stairs"):
		return _cache["stairs"]
	var out: Array[Dictionary] = [
		# West: every stair sits at a corridor end and rises away from it.
		_stair(&"S_A1", &"ashram_west", -160.0, 1, 1), ## Ashram: promenade up to the overlook
		_stair(&"S_HW3", &"high_west_front", -800.0, 3, 1), ## High-West lower gallery up to the terrace
		_stair(&"S_WK5", &"wickwork", -1280.0, 5, -1), ## Wickwork repair bays up to the street
		_stair(&"S_AL6", &"mid_allotments", 640.0, 6, 1), ## Allotments up to Wickwork's dock
		_stair(&"S_AL7", &"mid_allotments", -1280.0, 7, -1), ## Allotment street up to the residences
		_stair(&"S_LW", &"lower_worker", 640.0, 8, 1), ## Worker Stair: Home Court up to the allotments
		_stair(&"S_BW1", &"bottom_west", -1600.0 - RISE, 9, 1), ## Dispatch yard down to the Bottom-West approach
		_stair(&"S_BW2", &"bottom_west", -3440.0 - RISE, 10, 1), ## Approach down to the dig threshold
		# Mid Heart (open treads over the Mouth): the main crossing climbs over the Ritual deck.
		_stair(&"H_RIT_W", &"mid_heart", RITUAL_LEFT - 0.5 * RISE, 4, 1, 0.5),
		_stair(&"H_RIT_E", &"mid_heart", RITUAL_RIGHT + 0.5 * RISE, 4, -1, 0.5),
		_stair(&"H_FRT_W", &"mid_heart", MOUTH_L, 5, 1, 0.5), ## Wickwork dock to the lower freight tier
		_stair(&"H_FRT_E", &"mid_heart", MOUTH_R, 5, -1, 0.5), ## Mid-East service court to the tier
		# East
		_stair(&"S_EA1", &"ashram_east", 8000.0, 1, 1),
		_stair(&"S_EG3", &"glowbeds", 8000.0, 3, 1),
		_stair(&"S_EM5", &"mid_east_service", 7360.0, 5, 1),
		_stair(&"S_LE6", &"lower_east_homes", 5760.0, 6, -1),
		_stair(&"S_LS7", &"lower_east_services", 6720.0, 7, -1),
		_stair(&"S_CF", &"cistern", 6400.0, 9, -1),
		_stair(&"S_CL10", &"cistern_tanks", 7360.0, 10, -1),
	]
	_cache["stairs"] = out
	return out


## ---------------------------------------------------------------- ladders

static func _ladder(id: StringName, zone: StringName, open_x: float, top_k: float, bottom_k: float) -> Dictionary:
	return {"id": id, "zone": zone, "open_x": open_x, "top_y": lvl(top_k), "bottom_y": lvl(bottom_k)}


static func ladders() -> Array[Dictionary]:
	if _cache.has("ladders"):
		return _cache["ladders"]
	var out: Array[Dictionary] = [
		_ladder(&"LAD_A", &"ashram_west", -800.0, 0, 1),
		_ladder(&"LAD_HW", &"high_west_front", -4480.0, 2, 3),
		_ladder(&"LAD_WK4", &"wickwork", -1280.0, 3, 4),
		_ladder(&"LAD_WK5", &"wickwork", -640.0, 4, 5),
		_ladder(&"LAD_AL2", &"mid_allotments", 0.0, 5, 6),
		_ladder(&"LAD_AL", &"mid_allotments", -400.0, 6, 7),
		_ladder(&"LAD_BW", &"bottom_west", -5120.0, 10, 11),
		_ladder(&"LAD_EA", &"ashram_east", 7360.0, 0, 1),
		_ladder(&"LAD_EG", &"glowbeds", 7040.0, 2, 3),
		_ladder(&"LAD_EG4", &"glowbeds_hang", 7520.0, 3, 4), ## a lift-free way up from the Mid-East Landing
		_ladder(&"LAD_LE2", &"lower_east_homes", 7360.0, 6, 7),
		_ladder(&"LAD_EF", &"cistern_freight", 7040.0, 7, 8),
		_ladder(&"LAD_CC", &"cistern", 8000.0, 8, 9),
		_ladder(&"LAD_SE", &"seep_threshold", 8320.0, 10, 11),
	]
	_cache["ladders"] = out
	return out


## ---------------------------------------------------------------- lifts

static func _lift(id: StringName, zone: StringName, open_x: float, stops_k: Array, gate: StringName) -> Dictionary:
	var ys: Array[float] = []
	for k in stops_k:
		ys.append(lvl(float(k)))
	ys.sort()
	return {"id": id, "zone": zone, "open_x": open_x, "stops": ys, "gate": gate}


static func lifts() -> Array[Dictionary]:
	if _cache.has("lifts"):
		return _cache["lifts"]
	var out: Array[Dictionary] = [
		# West civic cage: always runs. Wickwork up to High-West and the Ashram gateway.
		_lift(&"heart", &"wickwork", -2560.0, [1, 2, 3, 4], FLAG_NONE),
		# East passenger cage: recessed Mid-East landing up through Glowbeds to Ashram. Always runs:
		# Glowbeds is a main district and is open from the start (the Ashram gate is further on).
		_lift(&"east_passenger", &"mid_east", 6400.0, [1, 2, 3, 4], FLAG_NONE),
		# East freight cage: Mid-East down to the Cistern. Heavy, slow, follows Cistern condition.
		_lift(&"freight", &"cistern_freight", 8640.0, [4, 7, 8, 9], FLAG_NONE),
	]
	_cache["lifts"] = out
	return out


## ---------------------------------------------------------------- gates

static func _gate(id: StringName, run: StringName, x: float, label: String, explanation: String, blocks: bool = true, trust: StringName = &"", flag: StringName = &"", residence: StringName = &"", beyond: int = 1) -> Dictionary:
	## blocks=false: a logic gate (a lift's Warden lock) with no bar across the deck.
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
		_gate(&"gate_high_west", &"HW2", -3520.0, "High-West checkpoint",
			"The High-West gallery is guarded work. Wardens pass only cleared crews.", true, &"", &"high_west_cleared", &"", -1),
		_gate(&"gate_high_west_low", &"HW3", -3520.0, "High-West lower checkpoint",
			"The High-West gallery is guarded work. Wardens pass only cleared crews.", true, &"", &"high_west_cleared", &"", -1),
		_gate(&"gate_bw_deep", &"BW11", -4480.0, "Bottom-West service gate",
			"Sealed past the collapse. The deeper service run is not open yet.", true, &"", &"bottom_west_service_open"),
		_gate(&"gate_ashram_east", &"E1", 7040.0, "Ashram east gate",
			"Wardens keep the Heights gate. Residents and cleared workers only.", true, &"", &"ashram_clearance"),
		_gate(&"gate_mid_east_dig", &"E4", EAST_WALL, "Mid-East dig front gate",
			"The Mid-East front opens once the Stewards clear the shock-fault survey.", true, &"", &"mid_east_survey_cleared"),
		_gate(&"gate_cistern_deep", &"E11", 8640.0, "Cistern flood gate",
			"The flood gate is sealed. Nothing past it is safe or sanctioned.", true, &"", &"cistern_flood_gate_open"),
	]
	_cache["gates"] = out
	return out


## Gates that are shut at the start of Act 1 and block walking (lifts are handled by `gate`).
static func closed_at_start() -> Array[StringName]:
	return [&"gate_ashram_west", &"gate_high_west", &"gate_high_west_low", &"gate_bw_deep", &"gate_ashram_east", &"gate_mid_east_dig", &"gate_cistern_deep"]


## Zones a new player must be able to reach with every start-closed gate shut: every main district
## (Wickwork, Allotments, Mid Heart, Glowbeds, the Lower-East homes and services, the Cistern).
## Everything else is deliberately held back for story (Ashram Heights, the High-West and Mid-East
## dig fronts, the deep service runs).
static func early_zones() -> Array[StringName]:
	return [
		&"home_court", &"lower_switchback", &"west_dispatch_yard", &"worker_return_ascent",
		&"lower_lift_landing", &"bottom_west_approach", &"bottom_west_threshold", &"first_expansion_gallery", &"collapsed_side_chamber",
		&"wickwork", &"mid_allotments", &"mid_heart",
		&"mid_east_landing", &"mid_east_approach", &"mid_east_service", &"glowbeds", &"glowbeds_hang",
		&"lower_east_homes", &"lower_east_services", &"cistern_freight", &"cistern", &"cistern_tanks", &"seep_threshold",
	]


## Standing points (feet on a deck) that must be walled off at the start and reachable once the
## gates open. Early-game zones are the opposite list above.
static func held_points() -> Array[Vector2]:
	return [
		Vector2(-1500.0, lvl(1)), ## Ashram west promenade, past the gate
		Vector2(-1000.0, lvl(0)), ## Ashram west residences
		Vector2(-4500.0, lvl(2)), ## High-West gallery, upper
		Vector2(-4000.0, lvl(3)), ## High-West gallery, lower
		Vector2(-4000.0, lvl(11)), ## Bottom-West service run
		Vector2(7500.0, lvl(1)), ## Ashram east promenade, past the gate
		Vector2(7000.0, lvl(0)), ## Ashram east residences
		Vector2(10500.0, lvl(4)), ## Mid-East dig front
		Vector2(9000.0, lvl(11)), ## Cistern flood gate side
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
		_reserve(&"R_WICKWORK", &"wickwork", Rect2(-5440.0, lvl(4) - ROOM_HEIGHT, 1760.0, ROOM_HEIGHT + LEVEL_GAP),
			"Wickwork's next workshop tier: the bay keeps running west into the rock."),
		_reserve(&"R_GLOWBEDS", &"glowbeds", Rect2(8800.0 + WALL_THICK, lvl(2) - ROOM_HEIGHT, 480.0, ROOM_HEIGHT + LEVEL_GAP),
			"Glowbeds' next cultivation tier past the planter court."),
		_reserve(&"R_CISTERN", &"cistern", Rect2(EAST_WALL + WALL_THICK, lvl(9) - ROOM_HEIGHT, 1280.0, ROOM_HEIGHT + LEVEL_GAP * 2.0),
			"Cistern pressure basin and tank expansion, east of the sealed flood gate."),
		_reserve(&"R_BW_DEEP", &"bottom_west", Rect2(-3200.0 + WALL_THICK, lvl(11) - ROOM_HEIGHT, 320.0, ROOM_HEIGHT + 96.0),
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
		_zone(&"ashram_west", "Ashram Heights (west)", -2720.0, 1440.0, 0, 1, -200.0, 0),
		_zone(&"high_west_front", "High-West Dig Front", WEST_FLANK_LEFT, 1440.0, 2, 3, -3000.0, 2),
		_zone(&"wickwork", "Wickwork", -3680.0, 1440.0, 4, 5, -2160.0, 4, true),
		_zone(&"mid_allotments", "Mid Allotments", -2400.0, 1440.0, 6, 7, -1500.0, 6),
		_zone(&"west_dispatch_yard", "West Dispatch Yard", -1600.0, -800.0, 8, 8, -1320.0, 8, true),
		_zone(&"lower_switchback", "Lower Switchback", -800.0, -320.0, 8, 8, -560.0, 8, true),
		_zone(&"home_court", "Home Court", -320.0, 160.0, 8, 8, -80.0, 8, true),
		_zone(&"worker_return_ascent", "Worker Stair Hall", 160.0, 1440.0, 8, 8, 400.0, 8),
		_zone(&"lower_lift_landing", "Lower Landing", -3440.0, -2800.0, 9, 9, -3100.0, 9, true),
		_zone(&"bottom_west_approach", "Bottom-West Approach", -2800.0, -1600.0, 9, 9, -2400.0, 9, true),
		_zone(&"first_expansion_gallery", "First Expansion Gallery", WEST_FLANK_LEFT, -4640.0, 10, 10, -5000.0, 10, true),
		_zone(&"bottom_west_threshold", "Bottom-West Threshold", -4640.0, -3440.0, 10, 10, -4400.0, 10, true),
		_zone(&"collapsed_side_chamber", "Collapsed Side Chamber", WEST_FLANK_LEFT, -4480.0, 11, 11, -5440.0, 11, true),
		_zone(&"bottom_west_deep", "Bottom-West Service Run", -4480.0, -3200.0, 11, 11, -4000.0, 11, true),
		# Mid Heart
		_zone(&"mid_heart", "Mid Heart", MOUTH_L, MOUTH_R, 3.5, 4.5, 3200.0, 3.5),
		# East
		_zone(&"ashram_east", "Ashram Heights (east)", 5760.0, 8800.0, 0, 1, 6800.0, 0),
		_zone(&"glowbeds", "Glowbeds", 5120.0, 8800.0, 2, 2, 5760.0, 2),
		_zone(&"glowbeds_hang", "Glowbeds Hang", 5760.0, 8000.0, 3, 3, 7200.0, 3),
		_zone(&"mid_east_landing", "Mid-East Landing", MOUTH_R, 7040.0, 4, 4, 5840.0, 4),
		_zone(&"mid_east_approach", "Mid-East Approach", 7040.0, EAST_WALL, 4, 4, 7680.0, 4),
		_zone(&"mid_east_dig_front", "Mid-East Dig Front", EAST_WALL, EAST_FLANK_RIGHT, 4, 4, 10080.0, 4),
		_zone(&"mid_east_service", "Mid-East Service Court", MOUTH_R, 7360.0, 5, 5, 6080.0, 5),
		_zone(&"lower_east_homes", "Lower-East Homes", 5760.0, 8000.0, 6, 6, 6800.0, 6),
		_zone(&"lower_east_services", "Lower-East Services", 6720.0, EAST_WALL, 7, 7, 7680.0, 7),
		_zone(&"cistern_freight", "Cistern Freight Landing", 5440.0, EAST_WALL, 8, 8, 7360.0, 8),
		_zone(&"cistern", "Cistern", 6400.0, EAST_WALL, 9, 9, 7200.0, 9, true),
		_zone(&"cistern_tanks", "Cistern Tanks", 7360.0, EAST_WALL, 10, 10, 8000.0, 10, true),
		_zone(&"seep_threshold", "Seep Gallery", 6400.0, EAST_WALL, 11, 11, 7200.0, 11, true),
	]
	# Dig volumes: the rock shell, not places you stand. No seams, no deck. Where a gallery zone
	# overlaps a flank volume the smaller rect wins (Zones.get_zone_at), so galleries read as themselves.
	out.append({"id": &"firmament", "display": "Firmament", "enclosed": true, "restricted": true,
		"rect": Rect2(ENV_LEFT, ENV_TOP, ENV_RIGHT - ENV_LEFT, ROCK_TOP - ENV_TOP), "anchor": Vector2(HEART_X, ROCK_TOP * 0.5), "volume": true})
	out.append({"id": &"east_dig_site", "display": "East Dig Site", "enclosed": true, "restricted": false,
		"rect": Rect2(EAST_WALL, ROCK_TOP, ENV_RIGHT - EAST_WALL, ENV_BOTTOM - ROCK_TOP), "anchor": Vector2(EAST_WALL + SIDE_DEPTH * 0.5, lvl(6)), "volume": true})
	out.append({"id": &"west_dig_site", "display": "West Dig Site", "enclosed": true, "restricted": false,
		"rect": Rect2(ENV_LEFT, ROCK_TOP, WEST_WALL - ENV_LEFT, ENV_BOTTOM - ROCK_TOP), "anchor": Vector2(WEST_WALL - SIDE_DEPTH * 0.5, lvl(6)), "volume": true})
	_cache["zones"] = out
	return out


## ---------------------------------------------------------------- derived: geometry

static func run_by_id(id: StringName) -> Dictionary:
	for r in runs():
		if r["id"] == id:
			return r
	return {}


## Deck pieces: the runs themselves. Decks are one-way (HollowTerrain), so ladders, lifts and
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


static func deck_rects() -> Array[Vector4]:
	var out: Array[Vector4] = []
	for p in deck_pieces():
		out.append(Vector4(p["x0"], p["x1"], p["y"], FLOOR_THICK))
	return out


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
	for k in range(12):
		out.append(lvl(float(k)))
	return out
