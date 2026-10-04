class_name HollowLayout
extends Object
## Shared Hollow world metrics — constants and thin query helpers.
##
## The map itself (every deck, stair, ladder, gate, reserve and zone) is declared in
## hollow_map.gd and judged by hollow_map_lint.gd; see docs/hollow-map-spec.md. This file
## keeps the named constants other systems read (level Ys, Mouth lips, spawn, key deck
## spans) and answers "where" questions by delegating to HollowMap. Level Ys are all on the
## grid y = LEVEL_ORIGIN + LEVEL_GAP * k so nothing here may carry a hand-typed Y.
##
## History: TILE relaxed 64 -> 16 (2026-09-18); world x5 scale pass (2026-09-19); west stack
## locked to 12 equal levels (2026-09-19); east stack re-gridded and the whole map rebuilt as
## a data-driven cut-away with stairs, ladders and gates (2026-10-01). Same day: level
## gap 640 -> 384 and ROOM_HEIGHT 480 -> 256 (rooms were 15 bodies tall), the Firmament moved to
## the top of the whole map and the Hollow wrapped in a diggable shell with deep side flanks.

const TILE := 16

## Devil's Mouth: the open central void. Mid Heart (and only Mid Heart) crosses it.
const PIT_LEFT := 1440.0
const PIT_RIGHT := 4960.0 ## width 3520 px (~1/6 of the 19200 px world)

## Distance between consecutive levels; also the minimum headroom between stacked bands.
const MIN_BAND_GAP := HollowMap.LEVEL_GAP

const FLOOR_THICKNESS := 32.0
const BRIDGE_THICKNESS := 20.0
## Shift FloorVisual so rock lips sit on collision tops (lip two tiles into the 16px grid).
const FLOOR_VISUAL_INSET := 32.0

## Cages and ladders are sized to the 32px body, not to the city.
const LADDER_OPENING := 64.0
const LADDER_WIDTH := 40.0

## --- Levels (deck tops): y = LEVEL_ORIGIN + LEVEL_GAP * k ---------------------------------------
const WEST_LEVEL_GAP := MIN_BAND_GAP
const WEST_ASHRAM_UPPER_Y := HollowMap.LEVEL_ORIGIN + 4.0 * HollowMap.LEVEL_GAP ## L4 (the Ashram; four levels sit above it)
const WEST_ASHRAM_LOWER_Y := WEST_ASHRAM_UPPER_Y + 1.0 * WEST_LEVEL_GAP ## L5
const WEST_HIGH_UPPER_Y := WEST_ASHRAM_UPPER_Y + 2.0 * WEST_LEVEL_GAP ## L6
const WEST_HIGH_LOWER_Y := WEST_ASHRAM_UPPER_Y + 3.0 * WEST_LEVEL_GAP ## L7
const WICK_Y := WEST_ASHRAM_UPPER_Y + 4.0 * WEST_LEVEL_GAP ## L8
const HEART_Y := WICK_Y ## Mid Heart's main deck is level with Wickwork's street
const WICK_LOWER_Y := WEST_ASHRAM_UPPER_Y + 5.0 * WEST_LEVEL_GAP ## L9
const MID_ALLOT_UPPER_Y := WEST_ASHRAM_UPPER_Y + 6.0 * WEST_LEVEL_GAP ## L10
const MID_ALLOT_LOWER_Y := WEST_ASHRAM_UPPER_Y + 7.0 * WEST_LEVEL_GAP ## L11
const WEST_LW_UPPER_Y := WEST_ASHRAM_UPPER_Y + 8.0 * WEST_LEVEL_GAP ## L12 — Home Court / spawn
const WEST_LW_LOWER_Y := WEST_ASHRAM_UPPER_Y + 9.0 * WEST_LEVEL_GAP ## L13
const BOTTOM_WEST_UPPER_Y := WEST_ASHRAM_UPPER_Y + 10.0 * WEST_LEVEL_GAP ## L14
const BOTTOM_WEST_LOWER_Y := WEST_ASHRAM_UPPER_Y + 11.0 * WEST_LEVEL_GAP ## L15
const VAULTWARD_Y := 0.0 ## top of the Firmament, the top of the world
## Legacy aliases kept for older call sites.
const MID_ALLOT_Y := MID_ALLOT_UPPER_Y
const BOTTOM_WEST_Y := BOTTOM_WEST_UPPER_Y
## Mid Heart's raised Ritual deck and lower freight tier (half levels, Mouth cluster only).
const RITUAL_Y := WICK_Y - 0.5 * WEST_LEVEL_GAP ## 3136
const FREIGHT_TIER_Y := WICK_Y + 0.5 * WEST_LEVEL_GAP ## 3520

## East stack sits on the same grid, one deck per level (see HollowMap.runs()).
const UPPER_RES_Y := WEST_ASHRAM_UPPER_Y ## L0 — Ashram Heights east (Firmament ceiling)
const FARMS_Y := WEST_HIGH_UPPER_Y ## L2 — Glowbeds main gallery
const GLOW_SUB_Y := WEST_HIGH_LOWER_Y ## L3 — Glowbeds hang / fiber racks
const LOWER_WORK_Y := MID_ALLOT_LOWER_Y ## L7 — Lower-East services / freight yard
const CISTERN_Y := WEST_LW_LOWER_Y ## L9 — Cistern core
const SEEP_Y := BOTTOM_WEST_LOWER_Y ## L11 — Seep gallery

## --- Walls of the Mouth ---------------------------------------------------------------------
## West civic interior WEST_HOLLOW_LEFT..PIT_LEFT, dig flank HIGH_WEST_DIG_LEFT..WEST_HOLLOW_LEFT.
## East civic interior PIT_RIGHT..EAST_CIVIC_RIGHT, dig flank EAST_CIVIC_RIGHT..EAST_FLANK_RIGHT.
const WEST_HOLLOW_LEFT := -2880.0
const WEST_HOLLOW_RIGHT := PIT_LEFT
const HIGH_WEST_DIG_LEFT := -5760.0 ## the authored galleries stop here; the rock runs on to ENV_LEFT
const HIGH_WEST_DIG_RIGHT := WEST_HOLLOW_LEFT
const GALLERY_LEFT := HIGH_WEST_DIG_LEFT
const EAST_CIVIC_RIGHT := 9280.0
const EAST_FLANK_RIGHT := 12160.0
## The dig envelope (the shell): rock on every side of the Hollow except the pit.
const ENV_LEFT := HollowMap.ENV_LEFT
const ENV_RIGHT := HollowMap.ENV_RIGHT
const ENV_TOP := HollowMap.ENV_TOP
const ENV_BOTTOM := HollowMap.ENV_BOTTOM
const ROCK_TOP := HollowMap.ROCK_TOP ## Firmament thickness above the highest room
## Legacy names for the same lines.
const HOLLOW_LEFT := WEST_HOLLOW_LEFT
const HOLLOW_RIGHT := EAST_CIVIC_RIGHT
const EXIT_RIGHT := EAST_CIVIC_RIGHT ## where the east dig rock begins

## --- Opening route (Home Court is the Act 1 spawn) ---------------------------------------------
const HOME_COURT_LEFT := -320.0
const HOME_COURT_DECK := Vector4(HOME_COURT_LEFT, 160.0, WEST_LW_UPPER_Y, FLOOR_THICKNESS)
const HOME_LANDING := Vector4(160.0, 640.0, WEST_LW_UPPER_Y, FLOOR_THICKNESS)
const SWITCHBACK_LEFT := -800.0
const SWITCHBACK_FLOOR := Vector4(SWITCHBACK_LEFT, HOME_COURT_LEFT, WEST_LW_UPPER_Y, FLOOR_THICKNESS)
const WEST_DISPATCH_LEFT := -1600.0
const WEST_DISPATCH_YARD := Vector4(WEST_DISPATCH_LEFT, SWITCHBACK_LEFT, WEST_LW_UPPER_Y, FLOOR_THICKNESS)
const HOME_ROOF_Y := WEST_LW_UPPER_Y - WEST_LEVEL_GAP
const HOME_BOUNDS := Rect2(HOME_COURT_LEFT, HOME_ROOF_Y, 960.0, WEST_LW_UPPER_Y + 80.0 - HOME_ROOF_Y)
const BOTTOM_WEST_THRESHOLD_LEFT := -4640.0
const BOTTOM_WEST_THRESHOLD := Vector4(BOTTOM_WEST_THRESHOLD_LEFT, -3440.0 - HollowMap.RISE, BOTTOM_WEST_UPPER_Y, FLOOR_THICKNESS)
const GALLERY_FLOOR := Vector4(HIGH_WEST_DIG_LEFT, BOTTOM_WEST_THRESHOLD_LEFT, BOTTOM_WEST_UPPER_Y, FLOOR_THICKNESS)
const LOWER_LIFT_LANDING := Vector4(-3440.0, -2800.0, WEST_LW_LOWER_Y, FLOOR_THICKNESS)
const APPROACH_LANDING1_Y := WEST_LW_LOWER_Y
const APPROACH_LANDING2_Y := BOTTOM_WEST_UPPER_Y
const WICK_BAY_WEST := -3680.0

## --- Mid Heart and the east approach ---------------------------------------------------------
## Main crossing: West Exchange raft -> stairs over the raised Ritual deck -> East Service raft.
const HEART_WEST := Vector4(PIT_LEFT, HollowMap.RITUAL_LEFT - 0.5 * HollowMap.RISE, HEART_Y, BRIDGE_THICKNESS)
const HEART_RITUAL := Vector4(HollowMap.RITUAL_LEFT, HollowMap.RITUAL_RIGHT, RITUAL_Y, BRIDGE_THICKNESS)
const HEART_EAST := Vector4(HollowMap.RITUAL_RIGHT + 0.5 * HollowMap.RISE, PIT_RIGHT, HEART_Y, BRIDGE_THICKNESS)
const HEART_FREIGHT := Vector4(PIT_LEFT + 0.5 * HollowMap.RISE, PIT_RIGHT - 0.5 * HollowMap.RISE, FREIGHT_TIER_Y, BRIDGE_THICKNESS)
const HEART_SPAN := Vector4(PIT_LEFT, PIT_RIGHT, HEART_Y, BRIDGE_THICKNESS) ## extent only, not one deck
const HEART_MID_X := (PIT_LEFT + PIT_RIGHT) * 0.5
const HEART_MID := Vector4(HEART_MID_X - 32.0, HEART_MID_X + 32.0, RITUAL_Y, BRIDGE_THICKNESS)

const MID_EAST_LANDING := Vector4(PIT_RIGHT, 7040.0, HEART_Y, FLOOR_THICKNESS)
const MID_EAST_APPROACH := Vector4(7040.0, EAST_CIVIC_RIGHT, HEART_Y, FLOOR_THICKNESS)
const MID_EAST_DIG_FRONT := Vector4(EAST_CIVIC_RIGHT, EAST_FLANK_RIGHT, HEART_Y, FLOOR_THICKNESS)



## ---------------------------------------------------------------- map queries (via HollowMap)

## Every walkable deck piece, as Vector4(x0, x1, y, thickness).
static func all_deck_rects() -> Array[Vector4]:
	return HollowMap.deck_rects()


## Decks that carry the opening route (Home Court spawn -> Dispatch -> Bottom-West).
static func opening_route_deck_rects() -> Array[Vector4]:
	return _rects_for_runs([&"LW8", &"BW9", &"BW10", &"BW11"])


## Everything that is not the opening route.
static func expansion_deck_rects() -> Array[Vector4]:
	var opening := opening_route_deck_rects()
	var out: Array[Vector4] = []
	for r in HollowMap.deck_rects():
		if not opening.has(r):
			out.append(r)
	return out


static func west_stack_deck_rects() -> Array[Vector4]:
	var out: Array[Vector4] = []
	for r in HollowMap.deck_rects():
		if r.y <= PIT_LEFT + 0.5:
			out.append(r)
	return out


static func _rects_for_runs(ids: Array[StringName]) -> Array[Vector4]:
	var out: Array[Vector4] = []
	for p in HollowMap.deck_pieces():
		if ids.has(p["run"]):
			out.append(Vector4(p["x0"], p["x1"], p["y"], FLOOR_THICKNESS))
	return out


## Stairs as Vector4(foot_x, foot_y, top_x, top_y) — the argument order of paint_stairs().
static func opening_route_stair_rects() -> Array[Vector4]:
	var out: Array[Vector4] = []
	for s in HollowMap.stairs():
		if [&"S_LW", &"S_BW1", &"S_BW2"].has(s["id"]):
			out.append(Vector4(s["foot_x"], s["foot_y"], s["top_x"], s["top_y"]))
	return out


static func expansion_stair_rects() -> Array[Vector4]:
	var opening := opening_route_stair_rects()
	var out: Array[Vector4] = []
	for s in HollowMap.stairs():
		var v := Vector4(s["foot_x"], s["foot_y"], s["top_x"], s["top_y"])
		if not opening.has(v):
			out.append(v)
	return out


static func heart_deck_rects() -> Array[Vector4]:
	var out: Array[Vector4] = []
	for p in HollowMap.deck_pieces():
		if p["x1"] > PIT_LEFT and p["x0"] < PIT_RIGHT and HollowMap.is_heart_zone(HollowMap.run_by_id(p["run"])["zone"]):
			out.append(Vector4(p["x0"], p["x1"], p["y"], BRIDGE_THICKNESS))
	return out


## Mid Heart reaches from the west lip to the east lip.
static func mid_heart_spans_mouth() -> bool:
	var rects := heart_deck_rects()
	if rects.is_empty():
		return false
	var x0: float = rects[0].x
	var x1: float = rects[0].y
	for r in rects:
		x0 = minf(x0, r.x)
		x1 = maxf(x1, r.y)
	return x0 <= PIT_LEFT + 0.5 and x1 >= PIT_RIGHT - 0.5


## East tip of the civic east walk; the dig front begins here.
static func civic_east_end() -> float:
	return EAST_CIVIC_RIGHT


static func west_stack_level_ys() -> Array[float]:
	return HollowMap.level_ys()


## Ladder shafts, as {"id", "open_x", "top_y", "bottom_y"}.
static func ladder_defs() -> Array[Dictionary]:
	return HollowMap.ladders()


## --- Lifts (HollowMap.lifts) ---------------------------------------------------------------------------
static func lift_data(lift_id: StringName) -> Dictionary:
	for lf in HollowMap.lifts():
		if lf["id"] == lift_id:
			return lf
	return {}


static func stop_ys_for_lift(lift_id: StringName) -> Array[float]:
	var lf := lift_data(lift_id)
	if lf.is_empty():
		return []
	var out: Array[float] = []
	for y in lf["stops"]:
		out.append(float(y))
	return out


## Left edge of the cab.
static func lift_x_for(lift_id: StringName) -> float:
	var lf := lift_data(lift_id)
	return float(lf["open_x"]) if not lf.is_empty() else 0.0


static func ladder_open_end(open_x: float) -> float:
	return open_x + LADDER_OPENING


## Deliberate deviations from the lint rules, each with a reason a player could read off the
## world. {"kind": "end"|"gap", "y": deck top, "x": the end/gap start, "reason": ...}.
## Empty on purpose: every end in this map is a wall, a lip, a stair, a shaft or rock.
static func intentional_exceptions() -> Array[Dictionary]:
	return []


## Ordered walkable deck tops used for clearance checks (top -> bottom).
static func walkable_band_ys() -> Array[float]:
	var ys: Array[float] = HollowMap.level_ys()
	ys.append(RITUAL_Y)
	ys.append(FREIGHT_TIER_Y)
	ys.sort()
	return ys


static func band_gap(upper_y: float, lower_y: float) -> float:
	return lower_y - upper_y


static func band_headroom(upper_y: float, lower_y: float) -> float:
	return band_gap(upper_y, lower_y) - FLOOR_THICKNESS


static func floor_visual_world_y(deck_top_y: float) -> float:
	return deck_top_y - FLOOR_VISUAL_INSET


static func floor_visual_lip_y(deck_top_y: float) -> float:
	return floor_visual_world_y(deck_top_y) + FLOOR_VISUAL_INSET


static func player_spawn_point() -> Vector2:
	## Feet on Lower Worker Terraces / Home Court (CharacterBody2D origin ~ body top-left).
	return Vector2((HOME_COURT_DECK.x + HOME_COURT_DECK.y) * 0.5, WEST_LW_UPPER_Y - 32.0)


## CharacterBody2D stand positions: every zone anchor (feet on a deck -> y = deck - 32).
static func safe_stand_points() -> Array[Vector2]:
	var out: Array[Vector2] = [player_spawn_point()]
	for z in HollowMap.zones():
		if z.get("volume", false):
			continue
		var a: Vector2 = z["anchor"]
		out.append(Vector2(a.x, a.y - 32.0))
	out.append(Vector2(HEART_MID_X, RITUAL_Y - 32.0))
	return out


static func nearest_safe_stand(from: Vector2) -> Vector2:
	var best := player_spawn_point()
	var best_d := INF
	for p in safe_stand_points():
		var d := from.distance_squared_to(p)
		if d < best_d:
			best_d = d
			best = p
	return best


## True inside the civic cavity: the Hollow's own air, between the Firmament and the floor slab and
## between the two civic walls. The dig galleries, the rock shell and the pit are "out in the field".
static func in_hollow(p: Vector2) -> bool:
	return HollowMap.cavity_rect().has_point(p)


static func vaultward_locked() -> bool:
	## Act 1 start: Vaultward / Firmament route is not free.
	return true
