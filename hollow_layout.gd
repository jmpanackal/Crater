class_name HollowLayout
extends Object
## Shared Hollow world metrics for the pit-centered vertical reblock.
## Side-view terraces left/right of a central void; Dig Site still starts at TerrainLayer.DIG_START_X.

const TILE := 64

## Central crash-pit (no full-width floor — bridge only).
const PIT_LEFT := 256.0
const PIT_RIGHT := 576.0

## Walk-deck tops (multiples of TILE so FloorVisual cells align).
const FARMS_Y := 128.0
const WICK_Y := 320.0
const CISTERN_Y := 512.0

## Left cliff walk width (0 → PIT_LEFT).
const LEFT_DECK_WIDTH := 256.0
## Right cliff from PIT_RIGHT through exit ledge toward Dig Site.
const RIGHT_DECK_LEFT := 576.0
const HOLLOW_RIGHT := 960.0
const EXIT_RIGHT := 1024.0 # meets dig columns

const FLOOR_THICKNESS := 32.0
const BRIDGE_THICKNESS := 24.0

## Climb shafts — tile-aligned deck openings (FloorVisual + StaticBody leave a gap).
const LADDER_OPENING := 64.0 # one TILE
const LADDER_FARMS_OPEN_X := 192.0 # [192, 256) at left cliff edge
const LADDER_CISTERN_OPEN_X := 832.0 # [832, 896) on right terraces
const LADDER_WIDTH := 40.0
## Area2D X centered in the opening so copper rails sit in the gap.
const LADDER_FARMS_X := LADDER_FARMS_OPEN_X + (LADDER_OPENING - LADDER_WIDTH) * 0.5
const LADDER_CISTERN_X := LADDER_CISTERN_OPEN_X + (LADDER_OPENING - LADDER_WIDTH) * 0.5


static func ladder_farms_open_end() -> float:
	return LADDER_FARMS_OPEN_X + LADDER_OPENING


static func ladder_cistern_open_end() -> float:
	return LADDER_CISTERN_OPEN_X + LADDER_OPENING


## CharacterBody2D stand positions (feet on deck → position.y = deck_top - 32).
static func safe_stand_points() -> Array[Vector2]:
	var body := 32.0
	return [
		Vector2(80.0, FARMS_Y - body),
		Vector2(120.0, WICK_Y - body),
		Vector2(416.0, WICK_Y - body), # mid bridge
		Vector2(700.0, WICK_Y - body),
		Vector2(760.0, CISTERN_Y - body),
	]


static func nearest_safe_stand(from: Vector2) -> Vector2:
	var best := Vector2(80.0, FARMS_Y - 32.0)
	var best_d := INF
	for p in safe_stand_points():
		var d := from.distance_squared_to(p)
		if d < best_d:
			best_d = d
			best = p
	return best
