extends TileMapLayer
## Hollow walkable floor — collision and visuals on ONE TileMapLayer via a TileSet
## physics layer, so a painted tile always carries its own collision and nothing else
## can. Replaces the old split between hollow_decks.gd (hand-built CollisionShape2D
## rectangles) and hollow_floor.gd (a separate paint-only layer) — see
## docs/hollow-level-authoring.md Rule 1 for why that split caused real bugs
## (a ramp with collision but no painted tile under it).
##
## Elevation changes are one-tile-per-column staircases (Rule 2), never floating ramp
## polygons — paint_stairs() below.

const TILE_SIZE := 16
const SOURCE_LEDGE := 0
const SOURCE_BRIDGE := 1
const SOURCE_STAIR := 2
const ATLAS_TOP_MID := Vector2i(0, 0)
const LEDGE_COLOR := Color(0.5, 0.4, 0.3, 0.95)
const BRIDGE_COLOR := Color(0.42, 0.32, 0.24, 0.95)
const STAIR_COLOR := Color(0.58, 0.46, 0.34, 0.95)


func _ready() -> void:
	texture_filter = TEXTURE_FILTER_NEAREST
	tile_set = _build_tileset()
	_paint_opening_route()


## Home Court -> Bottom-West Dig Front cluster. See HollowLayout's "Opening-route
## west wing" section for the numbers and docs/hollow-level-authoring.md for why
## this is a compact, vertically-arranged cluster and not a flat strip.
func _paint_opening_route() -> void:
	for rect in HollowLayout.opening_route_deck_rects():
		paint_floor(rect.x, rect.y, rect.z)
	for stair in HollowLayout.opening_route_stair_rects():
		paint_stairs(stair.x, stair.y, stair.z, stair.w)


func _build_tileset() -> TileSet:
	var tileset := TileSet.new()
	tileset.tile_size = Vector2i(TILE_SIZE, TILE_SIZE)
	tileset.add_physics_layer()
	tileset.set_physics_layer_collision_layer(0, 1)
	tileset.set_physics_layer_collision_mask(0, 0)
	_add_placeholder_source(tileset, LEDGE_COLOR)
	_add_placeholder_source(tileset, BRIDGE_COLOR)
	_add_placeholder_source(tileset, STAIR_COLOR)
	return tileset


func _add_placeholder_source(tileset: TileSet, color: Color) -> void:
	var image := Image.create(TILE_SIZE, TILE_SIZE, false, Image.FORMAT_RGBA8)
	image.fill(color)
	var texture := ImageTexture.create_from_image(image)
	var atlas := TileSetAtlasSource.new()
	atlas.texture = texture
	atlas.texture_region_size = Vector2i(TILE_SIZE, TILE_SIZE)
	# Register the source with the tileset BEFORE creating tiles on it — a TileData's
	# physics-layer array is only populated once its atlas is actually part of a
	# TileSet that has physics layers; doing this in the other order silently leaves
	# tile_data with zero physics layers ("Index p_layer_id = 0 is out of bounds").
	tileset.add_source(atlas)
	atlas.create_tile(ATLAS_TOP_MID)
	var tile_data := atlas.get_tile_data(ATLAS_TOP_MID, 0)
	tile_data.add_collision_polygon(0)
	var half := TILE_SIZE * 0.5
	var poly := PackedVector2Array([
		Vector2(-half, -half),
		Vector2(half, -half),
		Vector2(half, half),
		Vector2(-half, half),
	])
	tile_data.set_collision_polygon_points(0, 0, poly)


## Paint a flat walkable span. x0_px/x1_px/y_px are world pixels; y_px is the deck's
## walkable TOP surface (matches hollow_layout.gd's existing top_y convention).
func paint_floor(x0_px: float, x1_px: float, y_px: float, source_id: int = SOURCE_LEDGE) -> void:
	var x0 := int(round(x0_px / TILE_SIZE))
	var x1 := int(round(x1_px / TILE_SIZE))
	var y := int(round(y_px / TILE_SIZE))
	# Normalize order — a reversed pair silently painted nothing (range(x0,x1) is
	# empty when x0 > x1), which is exactly the invisible-collision bug class
	# this whole system exists to prevent. Caught twice by real constants during
	# the opening-route build; fixed here so it can't recur from a third.
	if x0 > x1:
		var tmp := x0
		x0 = x1
		x1 = tmp
	for x in range(x0, x1):
		set_cell(Vector2i(x, y), source_id, ATLAS_TOP_MID)


## Paint a one-tile-per-column staircase between two deck tops (Rule 2 — no floating
## ramp polygons). y0_px/y1_px are the walkable tops at x0_px/x1_px respectively; both
## must be TILE_SIZE-aligned and the run is stepped one column at a time between them.
## Each column is filled from its own step down to the lower end, not just its single
## top tile — two diagonally-adjacent single tiles only share a corner, not an edge,
## which left visible gaps in the staircase's silhouette (confirmed in-engine); a
## filled solid-block staircase (Terraria's own convention, cited in terrain.gd) has
## no such gap and reads as one continuous ascending mass.
func paint_stairs(x0_px: float, y0_px: float, x1_px: float, y1_px: float) -> void:
	var x0 := int(round(x0_px / TILE_SIZE))
	var x1 := int(round(x1_px / TILE_SIZE))
	var y0 := int(round(y0_px / TILE_SIZE))
	var y1 := int(round(y1_px / TILE_SIZE))
	var steps := absi(x1 - x0)
	if steps == 0:
		return
	var dir := 1 if x1 > x0 else -1
	var y_bottom := maxi(y0, y1)
	for i in range(steps):
		var t := float(i) / float(steps)
		var x := x0 + i * dir
		var y := int(round(lerpf(float(y0), float(y1), t)))
		for fy in range(y, y_bottom + 1):
			set_cell(Vector2i(x, fy), SOURCE_STAIR, ATLAS_TOP_MID)


func painted_cell_count() -> int:
	var count := 0
	for cell in get_used_cells():
		if get_cell_source_id(cell) != -1:
			count += 1
	return count
