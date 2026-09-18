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

const TILE := 16

## Broad uninterrupted Devil's Mouth void (no full-width floor).
const PIT_LEFT := 288.0
const PIT_RIGHT := 736.0

## Minimum gap between consecutive walkable deck tops.
## Clearance under an upper deck ≈ gap - FLOOR_THICKNESS; need > BODY_HEIGHT (32).
const MIN_BAND_GAP := 128.0

## --- Vertical society bands (deck tops; multiples of TILE) ---
## Vaultward sits beneath the Firmament — locked until late Act 1.
## Heights grown 1088 -> 1216 total (2026-09-18 macro-layout lock), +16px on
## every gap so the whole stack stretches evenly rather than one band.
const VAULTWARD_Y := 0.0
## Upper band: quiet residences + Glowbeds cultivation.
const UPPER_RES_Y := 80.0
const FARMS_Y := 224.0 ## Glowbeds main gallery (alias kept)
const GLOW_SUB_Y := 368.0 ## Glowbeds hang / fiber racks
## Mid band: Wickwork, Mid Heart, allotments.
const WICK_Y := 576.0
const HEART_Y := 576.0 ## Mid Heart civic cluster base
const MID_ALLOT_Y := 720.0 ## mid allotment / residential street
## Lower band: working terraces, Cistern, seep galleries.
const LOWER_WORK_Y := 864.0 ## crowded worker terraces — Act 1 spawn band
const CISTERN_Y := 1072.0
const SEEP_Y := 1216.0 ## lower seep / service gallery threshold

## Left cliff carved rooms (negative X into rock).
const HOLLOW_LEFT := -576.0
const FARMS_GALLERY_END := -192.0
const WICK_BAY_END := -160.0

## Right cliff through civic-excavation exits toward Dig Site.
const RIGHT_DECK_LEFT := 736.0
const HOLLOW_RIGHT := 960.0
const EXIT_RIGHT := 1024.0 ## meets dig columns
const CISTERN_ALCOVE_START := 896.0
const CISTERN_DECK_LEFT := 736.0

## Legacy aliases.
const LEFT_DECK_WIDTH := 256.0

const FLOOR_THICKNESS := 32.0
const BRIDGE_THICKNESS := 20.0
## Shift FloorVisual so rock lips sit on collision tops (lip two tiles into the 16px grid).
const FLOOR_VISUAL_INSET := 32.0

## --- Lift network (Presswater-powered; not fast travel) ---
const LIFT_OPENING := 64.0
const LIFT_WIDTH := 48.0

## 1) Heart hoist — essential Upper↔Mid↔Lower civic route (always available).
const LIFT_OPEN_X := 224.0
const LIFT_X := LIFT_OPEN_X + (LIFT_OPENING - LIFT_WIDTH) * 0.5
const HEART_HOIST_ID := &"heart"

## 2) Left-wall service lift — Glowbeds / Wickwork terraces (secondary).
const LEFT_LIFT_OPEN_X := -64.0
const LEFT_LIFT_X := LEFT_LIFT_OPEN_X + (LIFT_OPENING - LIFT_WIDTH) * 0.5
const LEFT_SERVICE_ID := &"left_service"

## 3) Right-wall Cistern freight lift (secondary).
const FREIGHT_LIFT_OPEN_X := 848.0
const FREIGHT_LIFT_X := FREIGHT_LIFT_OPEN_X + (LIFT_OPENING - LIFT_WIDTH) * 0.5
const FREIGHT_LIFT_ID := &"freight"

## Mid Heart — compact suspended decks over the void (flat walk tops; no snag bumps).
const HEART_WEST := Vector4(352.0, 448.0, HEART_Y, BRIDGE_THICKNESS)
const HEART_LINK_AB := Vector4(448.0, 480.0, HEART_Y, 16.0)
const HEART_MID := Vector4(480.0, 592.0, HEART_Y, BRIDGE_THICKNESS)
const HEART_LINK_BC := Vector4(592.0, 624.0, HEART_Y, 16.0)
const HEART_EAST := Vector4(624.0, 736.0, HEART_Y, BRIDGE_THICKNESS)

## Lift lip just east of Heart hoist before Mid Heart.
const LIFT_LIP_MID := Vector4(PIT_LEFT, 352.0, WICK_Y, FLOOR_THICKNESS)

## Lower Heart freight / worker transfer across the Mouth.
const LOWER_SPAN_LEFT := PIT_LEFT
const LOWER_SPAN_RIGHT := PIT_RIGHT

## Local maintenance ladders only (not the primary vertical spine).
const LADDER_OPENING := 64.0
const LADDER_WIDTH := 40.0
## Short residence climb (upper residences ↔ Glowbeds).
const LADDER_UPPER_OPEN_X := -208.0
const LADDER_UPPER_X := LADDER_UPPER_OPEN_X + (LADDER_OPENING - LADDER_WIDTH) * 0.5
## Short Mid allotment ↔ Wick bay maintenance climb (left wall).
const LADDER_MID_OPEN_X := -128.0
const LADDER_MID_X := LADDER_MID_OPEN_X + (LADDER_OPENING - LADDER_WIDTH) * 0.5
## Short right-terrace Cistern emergency climb (beside freight shaft).
const LADDER_CISTERN_OPEN_X := 784.0
const LADDER_CISTERN_X := LADDER_CISTERN_OPEN_X + (LADDER_OPENING - LADDER_WIDTH) * 0.5
## Legacy Farms ladder removed; alias maps to Heart hoist shaft.
const LADDER_FARMS_OPEN_X := LIFT_OPEN_X
const LADDER_FARMS_X := LIFT_X

## Presswater → lift service thresholds (Districts.PROTECTED_RESERVE / THIN).
const LIFT_ESSENTIAL_ID := HEART_HOIST_ID

## --- Opening-route west wing (Bottom-West Dig Front) ---
## Per hollow-chunk-map.md / mechanics-canon.md §52 and the confirmed spatial
## blueprint (docs/hollow-level-authoring.md): Home Court -> Lower Switchback
## -> West Dispatch Yard -> Bottom-West Approach (a real 3-flight descent) ->
## Lower Lift Landing (a mid-descent landing + shortcut) -> Bottom-West
## Threshold -> First Expansion Gallery (+ Collapsed Side Chamber branch).
## Bottom-West Dig Front sits MEASURABLY BELOW Home Court (mirroring Cistern
## sitting below Glowbeds on the east wall) — not beside it at the same
## elevation. A prior pass got this wrong (a flat westward strip); see the
## blueprint's v4 correction. All breakpoints are TILE-aligned.
const HOME_COURT_LEFT := -64.0
const HOME_COURT_DECK := Vector4(HOME_COURT_LEFT, 160.0, LOWER_WORK_Y, FLOOR_THICKNESS)

## Lower Switchback: hollow-chunk-map.md describes this as "sloping down and
## back up around a carved support mass," but that's a landmark prop that
## doesn't exist yet in this greybox pass — an elevation dip with nothing
## visually justifying it just reads as broken terrain (confirmed in-engine),
## per docs/hollow-level-authoring.md's "don't break up flat terrain without a
## reason." Flat for now; the dip is the art/dressing pass's job once the
## support-mass prop exists to hang it on, not a shape invented ahead of it.
const SWITCHBACK_FLOOR := Vector4(-160.0, HOME_COURT_LEFT, LOWER_WORK_Y, FLOOR_THICKNESS)

const WEST_DISPATCH_LEFT := -368.0
const WEST_DISPATCH_YARD := Vector4(WEST_DISPATCH_LEFT, -160.0, LOWER_WORK_Y, FLOOR_THICKNESS)

## Bottom-West Approach — the real descent: 3 shallow flights + 2 landings,
## dropping a full band (LOWER_WORK_Y -> BOTTOM_WEST_Y), same drop scale as
## LOWER_WORK_Y -> CISTERN_Y (208px) elsewhere in the stack.
const BOTTOM_WEST_Y := LOWER_WORK_Y + 192.0
const APPROACH_LANDING1_Y := LOWER_WORK_Y + 64.0
const APPROACH_LANDING2_Y := LOWER_WORK_Y + 128.0
const APPROACH_FLIGHT1 := Vector4(WEST_DISPATCH_LEFT, LOWER_WORK_Y, -432.0, APPROACH_LANDING1_Y)
## Lower Lift Landing — the named reconnection point from mechanics-canon.md
## §52. Growth-reserved (docs/hollow-level-authoring.md Rule 5): this is where
## the real West Civic Lift's lower stop connects once Wickwork is rebuilt: not
## built as a functioning hollow_lift.gd instance this pass, since a single-
## stop lift with no upper destination would be a half-finished mechanic.
const LOWER_LIFT_LANDING := Vector4(-464.0, -432.0, APPROACH_LANDING1_Y, FLOOR_THICKNESS)
const APPROACH_FLIGHT2 := Vector4(-464.0, APPROACH_LANDING1_Y, -528.0, APPROACH_LANDING2_Y)
const APPROACH_LANDING2 := Vector4(-560.0, -528.0, APPROACH_LANDING2_Y, FLOOR_THICKNESS)
const APPROACH_FLIGHT3 := Vector4(-560.0, APPROACH_LANDING2_Y, -624.0, BOTTOM_WEST_Y)

## Shortcut ladder: Lower Lift Landing <-> Bottom-West Threshold, bypassing
## flights 2-3. A second, distinct ascent/descent route between the same two
## elevations (Rule 4's verticality ratio) and constructive backtracking once
## the dig site's been visited once via the long way.
const LADDER_SHORTCUT_X := -448.0
const LADDER_SHORTCUT_TOP_Y := APPROACH_LANDING1_Y
const LADDER_SHORTCUT_BOTTOM_Y := BOTTOM_WEST_Y

const BOTTOM_WEST_THRESHOLD_LEFT := -880.0
const BOTTOM_WEST_THRESHOLD := Vector4(BOTTOM_WEST_THRESHOLD_LEFT, -624.0, BOTTOM_WEST_Y, FLOOR_THICKNESS)

## First Expansion Gallery = the Bottom-West dig site's entry chamber (blueprint's
## "Bottom-West Dig Front"). Collapsed Side Chamber branches off its west wall via
## a short local climb (not a walkway — "crawl/step/short climb" per
## hollow-chunk-map.md), same Area2D pattern as LadderUpper/LadderMid/LadderCistern.
## The ladder opening sits right at GALLERY_LEFT, so the Gallery's main floor
## needs no separate west sliver.
const GALLERY_LEFT := -1136.0
const LADDER_CHAMBER_OPEN_X := GALLERY_LEFT
const LADDER_CHAMBER_X := LADDER_CHAMBER_OPEN_X + (LADDER_OPENING - LADDER_WIDTH) * 0.5
const CHAMBER_ALCOVE_Y := BOTTOM_WEST_Y + 64.0
const CHAMBER_ALCOVE := Vector4(GALLERY_LEFT, -1040.0, CHAMBER_ALCOVE_Y, FLOOR_THICKNESS)
const GALLERY_FLOOR := Vector4(LADDER_CHAMBER_OPEN_X + LADDER_OPENING, BOTTOM_WEST_THRESHOLD_LEFT, BOTTOM_WEST_Y, FLOOR_THICKNESS)

const OPENING_ROUTE_LEFT := GALLERY_LEFT ## westmost extent of the opening route


## Flat decks only (stairs are separate calls) — used by hollow_terrain.gd to
## paint matching visual + collision tiles together (single source of truth).
static func opening_route_deck_rects() -> Array[Vector4]:
	return [
		HOME_COURT_DECK,
		SWITCHBACK_FLOOR,
		WEST_DISPATCH_YARD,
		LOWER_LIFT_LANDING,
		APPROACH_LANDING2,
		BOTTOM_WEST_THRESHOLD,
		GALLERY_FLOOR,
		CHAMBER_ALCOVE,
	]


## Stair flights: (x0, y0, x1, y1) — same Vector4 shape as decks, consumed by
## hollow_terrain.gd's paint_stairs(x0, y0, x1, y1).
static func opening_route_stair_rects() -> Array[Vector4]:
	return [
		APPROACH_FLIGHT1,
		APPROACH_FLIGHT2,
		APPROACH_FLIGHT3,
	]


static func ladder_chamber_open_end() -> float:
	return LADDER_CHAMBER_OPEN_X + LADDER_OPENING


static func ladder_shortcut_shaft_height() -> float:
	return LADDER_SHORTCUT_BOTTOM_Y - LADDER_SHORTCUT_TOP_Y


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


static func ladder_mid_open_end() -> float:
	return LADDER_MID_OPEN_X + LADDER_OPENING


static func ladder_upper_open_end() -> float:
	return LADDER_UPPER_OPEN_X + LADDER_OPENING


static func ladder_upper_shaft_height() -> float:
	return FARMS_Y - UPPER_RES_Y


static func ladder_mid_shaft_height() -> float:
	return MID_ALLOT_Y - WICK_Y


static func ladder_cistern_shaft_height() -> float:
	return CISTERN_Y - LOWER_WORK_Y


static func lift_stop_ys() -> Array[float]:
	## Heart hoist default (essential civic spine).
	return heart_hoist_stop_ys()


static func heart_hoist_stop_ys() -> Array[float]:
	return [FARMS_Y, WICK_Y, LOWER_WORK_Y]


static func left_service_stop_ys() -> Array[float]:
	return [FARMS_Y, GLOW_SUB_Y, WICK_Y]


static func freight_lift_stop_ys() -> Array[float]:
	return [WICK_Y, CISTERN_Y, SEEP_Y]


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
	return [HEART_WEST, HEART_LINK_AB, HEART_MID, HEART_LINK_BC, HEART_EAST]


## Ordered walkable deck tops used for clearance checks (top → bottom).
static func walkable_band_ys() -> Array[float]:
	return [
		UPPER_RES_Y,
		FARMS_Y,
		GLOW_SUB_Y,
		WICK_Y,
		MID_ALLOT_Y,
		LOWER_WORK_Y,
		CISTERN_Y,
		SEEP_Y,
	]


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
	## Feet on lower working terrace (CharacterBody2D origin ≈ body top-left).
	return Vector2(120.0, LOWER_WORK_Y - 32.0)


## CharacterBody2D stand positions (feet on deck → position.y = deck_top - 32).
static func safe_stand_points() -> Array[Vector2]:
	var body := 32.0
	return [
		player_spawn_point(),
		Vector2(80.0, FARMS_Y - body), ## Glowbeds public terrace
		Vector2(-320.0, FARMS_Y - body), ## Glowbeds gallery
		Vector2(-280.0, GLOW_SUB_Y - body), ## Glowbeds hang
		Vector2(40.0, UPPER_RES_Y - body), ## upper residence street
		Vector2(-40.0, WICK_Y - body), ## Wickwork street
		Vector2(-300.0, WICK_Y - body), ## Wick bay
		Vector2(-200.0, MID_ALLOT_Y - body), ## mid allotment street
		Vector2(536.0, HEART_Y - body), ## Mid Heart center
		Vector2(400.0, HEART_WEST.z - body), ## Mid Heart west
		Vector2(780.0, WICK_Y - body), ## right mid / excavation approach
		Vector2(780.0, CISTERN_Y - body), ## Cistern
		Vector2(200.0, LOWER_WORK_Y - body), ## Lower Heart west lip
		Vector2(900.0, SEEP_Y - body), ## seep gallery approach
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
