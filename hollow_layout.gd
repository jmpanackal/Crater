class_name HollowLayout
extends Object
## Shared Hollow world metrics — multi-band Devil's Mouth settlement (side-view).
## Upper / Mid / Lower civic anchors each contain inhabited sub-levels.
## Primary vertical travel: three Presswater cage lifts. Dig Site at TerrainLayer.DIG_START_X.
## Band tops are tile-aligned (multiples of TILE) so FloorVisual lips match collision.
## TILE relaxed 64 -> 16 (2026-09-18): the 64px rule dated from textured 64px
## floor sheets needing exact seam alignment; floor is flat-color 16px
## placeholder now (see CONTEXT.md), so 16px alignment is all that's required.
## That relaxation is what let the +128px height growth below be spread
## evenly (+16 per gap) instead of dumped into one band.
##
## World-scale pass (2026-09-19): every world position/span/footprint size
## below is 5x its previous value so traversal reads at the intended scale
## (Mid Heart's Mouth crossing now takes ~17.6s at SPEED=200, was ~3.5s;
## checked against the confirmed Hollow Cross-Section Blueprint). Constants
## sized to the player's fixed 32px body — TILE, FLOOR_THICKNESS,
## BRIDGE_THICKNESS, FLOOR_VISUAL_INSET, LIFT_OPENING/WIDTH,
## LADDER_OPENING/WIDTH — are unchanged; a lift cage doesn't get 5x wider
## because the city did. MIN_BAND_GAP now scales too: several authored
## rises (e.g. HOME_BACK_STAIR) are defined directly off it, and leaving it
## fixed would have kept just those risers cramped while every other band
## gap grew, which is the opposite of "uniform."

const TILE := 16

## Broad uninterrupted Devil's Mouth void (no full-width floor).
## Scale-plan lock (2026-09-19): Mouth must read as a prominent central shaft
## (~1/5–1/6 of world width). Old 288..736 (448 px / ~12.5%) was too narrow;
## west lip stays at Home Court's east edge, east lip pushes out.
## World-scale pass (2026-09-19): x5 — width 3520 px keeps the same ~1/5.6
## share of Macro WORLD_BOUNDS, now ~17.6s to cross at SPEED=200.
const PIT_LEFT := 1440.0
const PIT_RIGHT := 4960.0 ## width 3520 px (~19.6% of Macro WORLD_BOUNDS)

## Minimum gap between consecutive walkable deck tops.
## Clearance under an upper deck ≈ gap - FLOOR_THICKNESS; need > BODY_HEIGHT (32).
const MIN_BAND_GAP := 640.0

## --- Vertical society bands (deck tops; multiples of TILE) ---
## Vaultward sits beneath the Firmament — locked until late Act 1.
## Heights grown 1088 -> 1216 total (2026-09-18 macro-layout lock), +16px on
## every gap so the whole stack stretches evenly rather than one band.
const VAULTWARD_Y := 0.0
## Upper band: quiet residences + Glowbeds cultivation.
const UPPER_RES_Y := 400.0
const FARMS_Y := 1120.0 ## Glowbeds main gallery (alias kept)
const GLOW_SUB_Y := 1840.0 ## Glowbeds hang / fiber racks
## Mid band: Wickwork / Mid Heart (west stack Wickwork upper locks here).
const WICK_Y := 2880.0
const HEART_Y := 2880.0 ## Mid Heart civic cluster base
## East Lower-East services (west Home Court uses WEST_LW_* below).
const LOWER_WORK_Y := 4320.0
const CISTERN_Y := 5360.0
const SEEP_Y := 6080.0 ## lower seep / service gallery threshold

## --- Uniform west stack (2026-09-19 lock) ---
## 6 sections × 2 levels, every consecutive deck top spaced WEST_LEVEL_GAP.
## Anchored so Wickwork upper == HEART_Y (Mid Heart west exchange). Firmament
## sits above Ashram; unreachable void sits below Bottom-West lower.
## Dig mass is left of WEST_HOLLOW_LEFT; High-West + Bottom-West decks extend
## into that envelope as dig-front openings.
const WEST_LEVEL_GAP := MIN_BAND_GAP
const WEST_HOLLOW_LEFT := -2880.0
const WEST_HOLLOW_RIGHT := PIT_LEFT
const WEST_ASHRAM_UPPER_Y := WICK_Y - 4.0 * WEST_LEVEL_GAP ## 320
const WEST_ASHRAM_LOWER_Y := WICK_Y - 3.0 * WEST_LEVEL_GAP ## 960
const WEST_HIGH_UPPER_Y := WICK_Y - 2.0 * WEST_LEVEL_GAP ## 1600
const WEST_HIGH_LOWER_Y := WICK_Y - 1.0 * WEST_LEVEL_GAP ## 2240
const WICK_LOWER_Y := WICK_Y + WEST_LEVEL_GAP ## 3520
const MID_ALLOT_UPPER_Y := WICK_Y + 2.0 * WEST_LEVEL_GAP ## 4160
const MID_ALLOT_LOWER_Y := WICK_Y + 3.0 * WEST_LEVEL_GAP ## 4800
const WEST_LW_UPPER_Y := WICK_Y + 4.0 * WEST_LEVEL_GAP ## 5440 — Home Court / Act 1 spawn
const WEST_LW_LOWER_Y := WICK_Y + 5.0 * WEST_LEVEL_GAP ## 6080
const BOTTOM_WEST_UPPER_Y := WICK_Y + 6.0 * WEST_LEVEL_GAP ## 6720
const BOTTOM_WEST_LOWER_Y := WICK_Y + 7.0 * WEST_LEVEL_GAP ## 7360
## Legacy aliases used by zones / ambiance / older tests.
const MID_ALLOT_Y := MID_ALLOT_UPPER_Y
const BOTTOM_WEST_Y := BOTTOM_WEST_UPPER_Y

## Left cliff carved rooms (negative X into rock).
const HOLLOW_LEFT := WEST_HOLLOW_LEFT
const FARMS_GALLERY_END := -960.0
const WICK_BAY_END := -800.0

## Right cliff through civic-excavation exits toward Dig Site.
const RIGHT_DECK_LEFT := PIT_RIGHT
const HOLLOW_RIGHT := 6080.0
const EXIT_RIGHT := 6400.0 ## meets dig columns (past Mid-East landing lip)
const CISTERN_ALCOVE_START := 5760.0
const CISTERN_DECK_LEFT := PIT_RIGHT

## Legacy aliases.
const LEFT_DECK_WIDTH := 1280.0

const FLOOR_THICKNESS := 32.0
const BRIDGE_THICKNESS := 20.0
## Shift FloorVisual so rock lips sit on collision tops (lip two tiles into the 16px grid).
const FLOOR_VISUAL_INSET := 32.0

## --- Lift network (Presswater-powered; not fast travel) ---
const LIFT_OPENING := 64.0
const LIFT_WIDTH := 48.0

## 1) Heart hoist — essential Upper↔Mid↔Lower civic route (always available).
const LIFT_OPEN_X := 1120.0
const LIFT_X := LIFT_OPEN_X + (LIFT_OPENING - LIFT_WIDTH) * 0.5
const HEART_HOIST_ID := &"heart"

## 2) Left-wall service lift — Glowbeds / Wickwork terraces (secondary).
const LEFT_LIFT_OPEN_X := -320.0
const LEFT_LIFT_X := LEFT_LIFT_OPEN_X + (LIFT_OPENING - LIFT_WIDTH) * 0.5
const LEFT_SERVICE_ID := &"left_service"

## 3) Right-wall Cistern freight lift (secondary).
const FREIGHT_LIFT_OPEN_X := 5520.0
const FREIGHT_LIFT_X := FREIGHT_LIFT_OPEN_X + (LIFT_OPENING - LIFT_WIDTH) * 0.5
const FREIGHT_LIFT_ID := &"freight"

## Mid Heart — sole primary east–west crossing over Devil's Mouth (west lip → east lip).
## One continuous deck; Mouth stays open void above/below. No multi-deck rafts,
## floating treads, or secondary Lower Span bridging the Mouth.
const HEART_SPAN := Vector4(PIT_LEFT, PIT_RIGHT, HEART_Y, BRIDGE_THICKNESS)
## Prop / label anchors (not separate walk decks).
const HEART_WEST := HEART_SPAN
const HEART_EAST := HEART_SPAN
const HEART_MID_X := (PIT_LEFT + PIT_RIGHT) * 0.5
const HEART_MID := Vector4(HEART_MID_X - 32.0, HEART_MID_X + 32.0, HEART_Y, BRIDGE_THICKNESS)

## Lift lip just east of Heart hoist before Mid Heart (merged into HEART_SPAN).
const LIFT_LIP_MID := Vector4(PIT_LEFT, PIT_LEFT + 800.0, WICK_Y, FLOOR_THICKNESS)

## Local maintenance ladders only (not the primary vertical spine).
const LADDER_OPENING := 64.0
const LADDER_WIDTH := 40.0
## Uniform west stack shaft — one climb for all 6 section transitions.
const LADDER_WEST_OPEN_X := -1040.0
const LADDER_WEST_X := LADDER_WEST_OPEN_X + (LADDER_OPENING - LADDER_WIDTH) * 0.5
const LADDER_WEST_SHAFT_H := BOTTOM_WEST_LOWER_Y - WEST_ASHRAM_UPPER_Y
## Legacy aliases → west stack shaft (older tests / ambiance).
const LADDER_RETURN_OPEN_X := LADDER_WEST_OPEN_X
const LADDER_RETURN_X := LADDER_WEST_X
const LADDER_RETURN_SHAFT_H := LADDER_WEST_SHAFT_H
const LADDER_HOME_HEART_OPEN_X := LADDER_WEST_OPEN_X
const LADDER_HOME_HEART_X := LADDER_WEST_X
const LADDER_HOME_HEART_SHAFT_H := LADDER_WEST_SHAFT_H
## Short residence climb (upper residences ↔ Glowbeds) — legacy east-adjacent.
const LADDER_UPPER_OPEN_X := LADDER_WEST_OPEN_X
const LADDER_UPPER_X := LADDER_WEST_X
## Short right-terrace Cistern emergency climb (beside freight shaft).
const LADDER_CISTERN_OPEN_X := 5200.0
const LADDER_CISTERN_X := LADDER_CISTERN_OPEN_X + (LADDER_OPENING - LADDER_WIDTH) * 0.5
## Legacy Farms ladder removed; alias maps to Heart hoist shaft.
const LADDER_FARMS_OPEN_X := LIFT_OPEN_X
const LADDER_FARMS_X := LIFT_X

## Lift service follows the Cistern's canon condition ladder.
const LIFT_ESSENTIAL_ID := HEART_HOIST_ID

## --- Home Court on Lower Worker Terraces (uniform west stack) ---
## Opening route keeps named west→east zones on the LW upper deck; vertical
## travel to Bottom-West / Mid Heart is LadderWestStack, not stair flights.
const HOME_COURT_LEFT := -320.0
const HOME_COURT_DECK := Vector4(HOME_COURT_LEFT, 160.0, WEST_LW_UPPER_Y, FLOOR_THICKNESS)
## Flat "stair" stub so HomeCourtDressing still draws a rail without a real flight.
const HOME_BACK_STAIR := Vector4(HOME_COURT_DECK.y, WEST_LW_UPPER_Y, 800.0, WEST_LW_UPPER_Y)
const HOME_LANDING := Vector4(800.0, 1280.0, WEST_LW_UPPER_Y, FLOOR_THICKNESS)
const HOME_ROOF_Y := WEST_LW_UPPER_Y - WEST_LEVEL_GAP
const HOME_BOUNDS := Rect2(HOME_COURT_LEFT, HOME_ROOF_Y, 1680.0, WEST_LW_UPPER_Y + 80.0 - HOME_ROOF_Y)

const SWITCHBACK_LEFT := -800.0
const SWITCHBACK_FLOOR := Vector4(SWITCHBACK_LEFT, HOME_COURT_LEFT, WEST_LW_UPPER_Y, FLOOR_THICKNESS)
const WEST_DISPATCH_LEFT := -1840.0
const WEST_DISPATCH_YARD := Vector4(WEST_DISPATCH_LEFT, SWITCHBACK_LEFT, WEST_LW_UPPER_Y, FLOOR_THICKNESS)

## Dig envelope west of the civic hollow (High-West + Bottom-West openings).
const HIGH_WEST_DIG_LEFT := -5680.0
const HIGH_WEST_DIG_RIGHT := WEST_HOLLOW_LEFT
const GALLERY_LEFT := HIGH_WEST_DIG_LEFT
const LADDER_CHAMBER_OPEN_X := GALLERY_LEFT
const LADDER_CHAMBER_X := LADDER_CHAMBER_OPEN_X + (LADDER_OPENING - LADDER_WIDTH) * 0.5
const CHAMBER_ALCOVE_Y := BOTTOM_WEST_LOWER_Y
const CHAMBER_ALCOVE := Vector4(GALLERY_LEFT, -5200.0, CHAMBER_ALCOVE_Y, FLOOR_THICKNESS)
const BOTTOM_WEST_THRESHOLD_LEFT := -4400.0
const BOTTOM_WEST_THRESHOLD := Vector4(BOTTOM_WEST_THRESHOLD_LEFT, WEST_HOLLOW_LEFT, BOTTOM_WEST_UPPER_Y, FLOOR_THICKNESS)
const LOWER_LIFT_LANDING := Vector4(-2320.0, -2160.0, WEST_LW_LOWER_Y, FLOOR_THICKNESS)
const APPROACH_LANDING1_Y := WEST_LW_LOWER_Y
const APPROACH_LANDING2_Y := BOTTOM_WEST_UPPER_Y
const APPROACH_LANDING2 := Vector4(-2800.0, -2640.0, BOTTOM_WEST_UPPER_Y, FLOOR_THICKNESS)
const GALLERY_FLOOR := Vector4(LADDER_CHAMBER_OPEN_X + LADDER_OPENING, BOTTOM_WEST_THRESHOLD_LEFT, BOTTOM_WEST_UPPER_Y, FLOOR_THICKNESS)
## Compatibility alias for minimap / older call sites (Wickwork west span).
const WICK_TERRACE := Vector4(WEST_HOLLOW_LEFT, -1680.0, WICK_Y, FLOOR_THICKNESS)

## East vertical stack (one ladder): Ashram ↔ Glowbeds ↔ Hang ↔ Mid-East ↔ Lower-East ↔ Cistern.
const LADDER_EAST_OPEN_X := 6720.0
const LADDER_EAST_X := LADDER_EAST_OPEN_X + (LADDER_OPENING - LADDER_WIDTH) * 0.5
const LADDER_EAST_SHAFT_H := CISTERN_Y - UPPER_RES_Y
const MID_EAST_LANDING_WEST := Vector4(PIT_RIGHT, FREIGHT_LIFT_X, HEART_Y, FLOOR_THICKNESS)
const MID_EAST_LANDING_EAST := Vector4(FREIGHT_LIFT_X + LIFT_WIDTH, LADDER_EAST_OPEN_X, HEART_Y, FLOOR_THICKNESS)
const MID_EAST_APPROACH := Vector4(LADDER_EAST_OPEN_X + LADDER_OPENING, 8320.0, HEART_Y, FLOOR_THICKNESS)
const MID_EAST_DIG_FRONT := Vector4(MID_EAST_APPROACH.y, 11840.0, HEART_Y, FLOOR_THICKNESS)
const ASHRAM_EAST_WEST := Vector4(PIT_RIGHT, LADDER_EAST_OPEN_X, UPPER_RES_Y, FLOOR_THICKNESS)
const ASHRAM_EAST_EAST := Vector4(LADDER_EAST_OPEN_X + LADDER_OPENING, 7680.0, UPPER_RES_Y, FLOOR_THICKNESS)
const GLOWBEDS_EAST_WEST := Vector4(PIT_RIGHT, LADDER_EAST_OPEN_X, FARMS_Y, FLOOR_THICKNESS)
const GLOWBEDS_EAST_EAST := Vector4(LADDER_EAST_OPEN_X + LADDER_OPENING, 7680.0, FARMS_Y, FLOOR_THICKNESS)
const GLOW_HANG_WEST := Vector4(PIT_RIGHT, LADDER_EAST_OPEN_X, GLOW_SUB_Y, FLOOR_THICKNESS)
const GLOW_HANG_EAST := Vector4(LADDER_EAST_OPEN_X + LADDER_OPENING, 7680.0, GLOW_SUB_Y, FLOOR_THICKNESS)
const LOWER_EAST_WEST_A := Vector4(PIT_RIGHT, FREIGHT_LIFT_X, LOWER_WORK_Y, FLOOR_THICKNESS)
const LOWER_EAST_WEST_B := Vector4(FREIGHT_LIFT_X + LIFT_WIDTH, LADDER_EAST_OPEN_X, LOWER_WORK_Y, FLOOR_THICKNESS)
const LOWER_EAST_EAST := Vector4(LADDER_EAST_OPEN_X + LADDER_OPENING, 7680.0, LOWER_WORK_Y, FLOOR_THICKNESS)
const CISTERN_WEST := Vector4(PIT_RIGHT, FREIGHT_LIFT_X, CISTERN_Y, FLOOR_THICKNESS)
const CISTERN_APPROACH := Vector4(FREIGHT_LIFT_X + LIFT_WIDTH, 7680.0, CISTERN_Y, FLOOR_THICKNESS)
const CISTERN_CHAMBER := Vector4(7680.0, 9600.0, CISTERN_Y, FLOOR_THICKNESS)
const SEEP_WEST := Vector4(PIT_RIGHT, FREIGHT_LIFT_X, SEEP_Y, FLOOR_THICKNESS)
const SEEP_APPROACH := Vector4(FREIGHT_LIFT_X + LIFT_WIDTH, 7040.0, SEEP_Y, FLOOR_THICKNESS)


## Ordered west deck tops (Ashram upper → Bottom-West lower).
static func west_stack_level_ys() -> Array[float]:
	return [
		WEST_ASHRAM_UPPER_Y,
		WEST_ASHRAM_LOWER_Y,
		WEST_HIGH_UPPER_Y,
		WEST_HIGH_LOWER_Y,
		WICK_Y,
		WICK_LOWER_Y,
		MID_ALLOT_UPPER_Y,
		MID_ALLOT_LOWER_Y,
		WEST_LW_UPPER_Y,
		WEST_LW_LOWER_Y,
		BOTTOM_WEST_UPPER_Y,
		BOTTOM_WEST_LOWER_Y,
	]


## Split a west span around openings that pierce this deck.
static func _west_gapped_spans(x0: float, x1: float, y: float) -> Array[Vector4]:
	var openings: Array[Vector2] = [
		Vector2(LADDER_WEST_OPEN_X, LADDER_WEST_OPEN_X + LADDER_OPENING),
	]
	# Left civic lift travels Ashram ↔ Wick — gap every deck in that range.
	# Heart hoist is layout-reserved but not instanced in main.tscn yet, so do
	# not punch an unbridged hole through Wickwork / Home Court.
	if y >= WEST_ASHRAM_UPPER_Y - 0.5 and y <= WICK_Y + 0.5:
		openings.append(Vector2(LEFT_LIFT_OPEN_X, LEFT_LIFT_OPEN_X + LIFT_OPENING))
	var spans: Array[Vector2] = [Vector2(x0, x1)]
	for opening in openings:
		var next_spans: Array[Vector2] = []
		for span in spans:
			if opening.y <= span.x or opening.x >= span.y:
				next_spans.append(span)
				continue
			if opening.x > span.x:
				next_spans.append(Vector2(span.x, opening.x))
			if opening.y < span.y:
				next_spans.append(Vector2(opening.y, span.y))
		spans = next_spans
	var rects: Array[Vector4] = []
	for span in spans:
		if span.y - span.x >= float(TILE):
			rects.append(Vector4(span.x, span.y, y, FLOOR_THICKNESS))
	return rects


## Full west stack decks (hollow civic + dig-front extensions).
static func west_stack_deck_rects() -> Array[Vector4]:
	var rects: Array[Vector4] = []
	# Civic hollow only (Ashram / Wick / Mid Allot / Lower Worker).
	for y in [
		WEST_ASHRAM_UPPER_Y,
		WEST_ASHRAM_LOWER_Y,
		WICK_Y,
		WICK_LOWER_Y,
		MID_ALLOT_UPPER_Y,
		MID_ALLOT_LOWER_Y,
		WEST_LW_UPPER_Y,
		WEST_LW_LOWER_Y,
	]:
		rects.append_array(_west_gapped_spans(WEST_HOLLOW_LEFT, WEST_HOLLOW_RIGHT, y))
	# Dig fronts: full dig envelope → Mouth lip (openings into diggable rock).
	for y in [WEST_HIGH_UPPER_Y, WEST_HIGH_LOWER_Y, BOTTOM_WEST_UPPER_Y, BOTTOM_WEST_LOWER_Y]:
		rects.append_array(_west_gapped_spans(HIGH_WEST_DIG_LEFT, WEST_HOLLOW_RIGHT, y))
	# Collapsed side chamber alcove off Bottom-West lower.
	rects.append(CHAMBER_ALCOVE)
	return rects


## Opening-route named pads (subset of west stack; no stair flights).
static func opening_route_deck_rects() -> Array[Vector4]:
	var rects: Array[Vector4] = [
		HOME_COURT_DECK,
		HOME_LANDING,
		SWITCHBACK_FLOOR,
		WEST_DISPATCH_YARD,
		LOWER_LIFT_LANDING,
		APPROACH_LANDING2,
		BOTTOM_WEST_THRESHOLD,
		GALLERY_FLOOR,
		CHAMBER_ALCOVE,
	]
	# Ensure dig-front / LW lower presence even if named pads miss a sample.
	rects.append_array(_west_gapped_spans(WEST_HOLLOW_LEFT, WEST_HOLLOW_RIGHT, WEST_LW_LOWER_Y))
	rects.append_array(_west_gapped_spans(HIGH_WEST_DIG_LEFT, WEST_HOLLOW_RIGHT, BOTTOM_WEST_LOWER_Y))
	return rects


## Uniform west stack uses LadderWestStack — no stair flights.
static func opening_route_stair_rects() -> Array[Vector4]:
	return []


## East stack + Mid Heart + west stack decks.
static func expansion_deck_rects() -> Array[Vector4]:
	var decks: Array[Vector4] = []
	decks.append_array(west_stack_deck_rects())
	decks.append_array([
		MID_EAST_LANDING_WEST,
		MID_EAST_LANDING_EAST,
		MID_EAST_APPROACH,
		MID_EAST_DIG_FRONT,
		ASHRAM_EAST_WEST,
		ASHRAM_EAST_EAST,
		GLOWBEDS_EAST_WEST,
		GLOWBEDS_EAST_EAST,
		GLOW_HANG_WEST,
		GLOW_HANG_EAST,
		LOWER_EAST_WEST_A,
		LOWER_EAST_WEST_B,
		LOWER_EAST_EAST,
		CISTERN_WEST,
		CISTERN_APPROACH,
		CISTERN_CHAMBER,
		SEEP_WEST,
		SEEP_APPROACH,
	])
	decks.append_array(heart_deck_rects())
	return decks


## East tip of the continuous Mid-East civic walk (landing + approach).
## Dig Front begins past this; camera unlocks dig framing after it.
static func civic_east_end() -> float:
	return MID_EAST_APPROACH.y


static func ladder_east_open_end() -> float:
	return LADDER_EAST_OPEN_X + LADDER_OPENING


static func expansion_stair_rects() -> Array[Vector4]:
	return []


static func ladder_chamber_open_end() -> float:
	return LADDER_CHAMBER_OPEN_X + LADDER_OPENING


static func ladder_west_open_end() -> float:
	return LADDER_WEST_OPEN_X + LADDER_OPENING


static func lift_open_end() -> float:
	return LIFT_OPEN_X + LIFT_OPENING


static func left_lift_open_end() -> float:
	return LEFT_LIFT_OPEN_X + LIFT_OPENING


static func freight_lift_open_end() -> float:
	return FREIGHT_LIFT_OPEN_X + LIFT_OPENING


static func ladder_farms_open_end() -> float:
	return lift_open_end()


static func ladder_cistern_open_end() -> float:
	return LADDER_CISTERN_OPEN_X + LADDER_OPENING


static func ladder_upper_open_end() -> float:
	return ladder_west_open_end()


static func ladder_upper_shaft_height() -> float:
	return FARMS_Y - UPPER_RES_Y


static func ladder_cistern_shaft_height() -> float:
	return CISTERN_Y - LOWER_WORK_Y


static func ladder_return_open_end() -> float:
	return ladder_west_open_end()


static func lift_stop_ys() -> Array[float]:
	## Heart hoist default (essential civic spine).
	return heart_hoist_stop_ys()


static func heart_hoist_stop_ys() -> Array[float]:
	## West hollow decks at the Heart hoist column (Ashram / Wick / Home Court).
	return [WEST_ASHRAM_UPPER_Y, WICK_Y, WEST_LW_UPPER_Y]


static func left_service_stop_ys() -> Array[float]:
	## West civic lift: Ashram Heights ↔ Wickwork (Mid Heart band).
	return [WEST_ASHRAM_UPPER_Y, WICK_Y]


static func freight_lift_stop_ys() -> Array[float]:
	## Low↔Mid↔Cistern↔Seep (Seep landing built 2026-09-19).
	return [HEART_Y, LOWER_WORK_Y, CISTERN_Y, SEEP_Y]


static func stop_ys_for_lift(lift_id: StringName) -> Array[float]:
	match lift_id:
		LEFT_SERVICE_ID:
			return left_service_stop_ys()
		FREIGHT_LIFT_ID:
			return freight_lift_stop_ys()
		_:
			return heart_hoist_stop_ys()


static func lift_x_for(lift_id: StringName) -> float:
	match lift_id:
		LEFT_SERVICE_ID:
			return LEFT_LIFT_X
		FREIGHT_LIFT_ID:
			return FREIGHT_LIFT_X
		_:
			return LIFT_X


static func is_essential_lift(lift_id: StringName) -> bool:
	return lift_id == LIFT_ESSENTIAL_ID or lift_id == &"" or lift_id == &"civic"


static func farms_terrace_tiles() -> int:
	return int((LIFT_OPEN_X - FARMS_GALLERY_END) / TILE)


static func farms_gallery_tiles() -> int:
	return int((FARMS_GALLERY_END - HOLLOW_LEFT) / TILE)


static func wick_left_street_tiles() -> int:
	return int((LIFT_OPEN_X - WICK_BAY_END) / TILE)


static func cistern_terrace_tiles() -> int:
	return int((CISTERN_ALCOVE_START - CISTERN_DECK_LEFT) / TILE)


static func cistern_alcove_tiles() -> int:
	return int((EXIT_RIGHT - CISTERN_ALCOVE_START) / TILE)


static func heart_deck_rects() -> Array[Vector4]:
	## Single continuous Mid Heart span — no multi-deck / link raft chain.
	return [HEART_SPAN]


## Mid Heart walk span across Devil's Mouth (west lip -> east lip).
static func mid_heart_span() -> Vector2:
	return Vector2(PIT_LEFT, PIT_RIGHT)


static func mid_heart_spans_mouth() -> bool:
	var span := mid_heart_span()
	var decks := heart_deck_rects()
	if decks.is_empty():
		return false
	var x0: float = decks[0].x
	var x1: float = decks[0].y
	for rect in decks:
		x0 = minf(x0, rect.x)
		x1 = maxf(x1, rect.y)
	return x0 <= span.x + 0.5 and x1 >= span.y - 0.5

## Ordered walkable deck tops used for clearance checks (top → bottom).
static func walkable_band_ys() -> Array[float]:
	var ys: Array[float] = west_stack_level_ys()
	for y in [UPPER_RES_Y, FARMS_Y, GLOW_SUB_Y, LOWER_WORK_Y, CISTERN_Y, SEEP_Y]:
		if not ys.has(y):
			ys.append(y)
	ys.sort()
	return ys


static func band_gap(upper_y: float, lower_y: float) -> float:
	return lower_y - upper_y


static func band_headroom(upper_y: float, lower_y: float) -> float:
	## Free space under upper deck collider bottom down to lower deck top.
	return band_gap(upper_y, lower_y) - FLOOR_THICKNESS


static func floor_visual_world_y(deck_top_y: float) -> float:
	## World Y of the top edge of the FloorVisual tile for a deck top.
	return deck_top_y - FLOOR_VISUAL_INSET


static func floor_visual_lip_y(deck_top_y: float) -> float:
	## Expected rock-lip Y of the ledge visual (after inset it lands on the deck top).
	return floor_visual_world_y(deck_top_y) + FLOOR_VISUAL_INSET


static func player_spawn_point() -> Vector2:
	## Feet on Lower Worker Terraces / Home Court (CharacterBody2D origin ≈ body top-left).
	return Vector2((HOME_COURT_DECK.x + HOME_COURT_DECK.y) * 0.5, WEST_LW_UPPER_Y - 32.0)


## CharacterBody2D stand positions (feet on deck → position.y = deck_top - 32).
static func safe_stand_points() -> Array[Vector2]:
	var body := 32.0
	return [
		player_spawn_point(),
		Vector2(PIT_RIGHT + 240.0, FARMS_Y - body), ## Glowbeds east terrace (west of east shaft)
		Vector2(LADDER_EAST_OPEN_X + 480.0, GLOW_SUB_Y - body), ## Glowbeds hang (east of east shaft)
		Vector2(PIT_RIGHT + 240.0, UPPER_RES_Y - body), ## Ashram east (west of east shaft)
		Vector2(-1600.0, WEST_ASHRAM_UPPER_Y - body), ## Ashram west
		Vector2(-1600.0, WEST_HIGH_UPPER_Y - body), ## High-West Dig Front
		Vector2(-200.0, WICK_Y - body), ## Wickwork street
		Vector2(-1500.0, WICK_Y - body), ## Wick bay
		Vector2(-1280.0, MID_ALLOT_Y - body), ## mid allotment street
		Vector2(HEART_MID_X, HEART_Y - body), ## Mid Heart center
		Vector2(PIT_LEFT + 160.0, HEART_Y - body), ## Mid Heart west lip
		Vector2(PIT_RIGHT + 400.0, HEART_Y - body), ## Mid-East Landing
		Vector2(MID_EAST_APPROACH.x + 320.0, HEART_Y - body), ## Mid-East Approach
		Vector2((MID_EAST_DIG_FRONT.x + MID_EAST_DIG_FRONT.y) * 0.5, HEART_Y - body), ## Mid-East Dig Front
		Vector2(PIT_RIGHT + 240.0, LOWER_WORK_Y - body), ## Lower-East services
		Vector2(PIT_RIGHT + 240.0, CISTERN_Y - body), ## Cistern approach
		Vector2((CISTERN_CHAMBER.x + CISTERN_CHAMBER.y) * 0.5, CISTERN_Y - body), ## Cistern chamber
		Vector2(1000.0, WEST_LW_UPPER_Y - body), ## Lower west lip (not a Mouth crossing)
		Vector2(-4000.0, BOTTOM_WEST_UPPER_Y - body), ## Bottom-West Dig Front
		Vector2(PIT_RIGHT + 400.0, SEEP_Y - body), ## seep gallery approach
	]


static func nearest_safe_stand(from: Vector2) -> Vector2:
	var best := player_spawn_point()
	var best_d := INF
	for p in safe_stand_points():
		var d := from.distance_squared_to(p)
		if d < best_d:
			best_d = d
			best = p
	return best


static func vaultward_locked() -> bool:
	## Act 1 start: Vaultward / Firmament route is not free.
	return true
