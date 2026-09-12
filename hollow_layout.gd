class_name HollowLayout
extends Object
## Shared Hollow world metrics — multi-band Devil's Mouth settlement (side-view).
## Upper / Mid / Lower civic anchors each contain inhabited sub-levels.
## Primary vertical travel: three Presswater cage lifts. Dig Site at TerrainLayer.DIG_START_X.
## Band tops are tile-aligned (multiples of TILE) so FloorVisual lips match collision.

const TILE := 64

## Broad uninterrupted Devil's Mouth void (no full-width floor).
const PIT_LEFT := 288.0
const PIT_RIGHT := 736.0

## Minimum gap between consecutive walkable deck tops.
## Clearance under an upper deck ≈ gap - FLOOR_THICKNESS; need > BODY_HEIGHT (32).
const MIN_BAND_GAP := 128.0

## --- Vertical society bands (deck tops; multiples of TILE) ---
## Vaultward sits beneath the Firmament — locked until late Act 1.
const VAULTWARD_Y := 0.0
## Upper band: quiet residences + Glowbeds cultivation.
const UPPER_RES_Y := 64.0
const FARMS_Y := 192.0 ## Glowbeds main gallery (alias kept)
const GLOW_SUB_Y := 320.0 ## Glowbeds hang / fiber racks
## Mid band: Wickwork, Mid Heart, allotments.
const WICK_Y := 512.0
const HEART_Y := 512.0 ## Mid Heart civic cluster base
const MID_ALLOT_Y := 640.0 ## mid allotment / residential street
## Lower band: working terraces, Cistern, seep galleries.
const LOWER_WORK_Y := 768.0 ## crowded worker terraces — Act 1 spawn band
const CISTERN_Y := 960.0
const SEEP_Y := 1088.0 ## lower seep / service gallery threshold

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
## Shift FloorVisual so rock lips sit on collision tops (64px tiles, lip mid-tile).
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
	## Expected rock-lip Y inside a 64px ledge tile (mid-tile after inset).
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
