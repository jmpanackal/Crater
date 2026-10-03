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
##
## Map decks (HollowMap runs) are ONE-WAY platforms on a child layer, "Decks" (2026-10-01):
## you stand on them, but climb up through them from below and press Down to drop through
## to a stair or deck within DROP_PROBE beneath. That is what lets a stair rise through a
## street and a ladder or lift pass a floor with no hole in it, so streets stay continuous.
## Walls, stair treads and wedges stay solid on this layer. paint_floor() stays solid (it
## paints walls, and test rigs rely on it); paint_deck() paints the one-way kind.

const TILE_SIZE := 16
const SOURCE_LEDGE := 0
const SOURCE_BRIDGE := 1
const SOURCE_STAIR := 2
const SOURCE_ROCK := 3
const ATLAS_TOP_MID := Vector2i(0, 0)
## Stone and timber, lit from the top-left (see RockTextures.tile).
const LEDGE_COLOR := Color(0.46, 0.4, 0.34)
const BRIDGE_COLOR := Color(0.44, 0.31, 0.2)
const STAIR_COLOR := Color(0.52, 0.45, 0.38)
const WALL_COLOR := Color(0.21, 0.21, 0.26)
const DECK_GROUP := &"hollow_decks"

var _decks: TileMapLayer


func _ready() -> void:
	texture_filter = TEXTURE_FILTER_NEAREST
	tile_set = _build_tileset()
	_decks = TileMapLayer.new()
	_decks.name = "Decks"
	_decks.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	_decks.tile_set = _build_tileset(true)
	_decks.add_to_group(DECK_GROUP)
	add_child(_decks)
	_paint_map()


## Paint everything HollowMap declares: one-way decks, wall columns at wall ends, and stair
## wedges. Collision and visual are the same tile.
func _paint_map() -> void:
	_paint_civic_rock() # first: the stair treads, walls and roofs below overwrite what they need
	for rect in HollowMap.deck_rects():
		var source := SOURCE_BRIDGE if rect.w <= HollowLayout.BRIDGE_THICKNESS + 0.5 else SOURCE_LEDGE
		paint_deck(rect.x, rect.y, rect.z, source)
	for stair in HollowMap.stairs():
		paint_stairs(stair["foot_x"], stair["foot_y"], stair["top_x"], stair["top_y"])
	for wall in HollowMap.wall_rects():
		paint_block(wall, SOURCE_ROCK)
	for roof in HollowMap.roof_rects():
		paint_block(roof, SOURCE_ROCK)
	for door in HollowMap.door_rects():
		paint_block(door, SOURCE_ROCK)


## The solid rock between rooms (HollowMap.civic_rock_rows): the whole civic cavity except the rooms, flights,
## shafts, domes and the Mouth. Not diggable (this layer is not the dig Terrain).
func _paint_civic_rock() -> void:
	var rows := HollowMap.civic_rock_rows()
	for row in rows.keys():
		for span: Vector2 in rows[row]:
			for x in range(int(span.x / TILE_SIZE), int(span.y / TILE_SIZE)):
				set_cell(Vector2i(x, int(row)), SOURCE_ROCK, _coords(SOURCE_ROCK, x, int(row)))


func _build_tileset(one_way: bool = false) -> TileSet:
	var tileset := TileSet.new()
	tileset.tile_size = Vector2i(TILE_SIZE, TILE_SIZE)
	tileset.add_physics_layer()
	tileset.set_physics_layer_collision_layer(0, 1)
	tileset.set_physics_layer_collision_mask(0, 0)
	_add_placeholder_source(tileset, LEDGE_COLOR, one_way, &"slab")
	_add_placeholder_source(tileset, BRIDGE_COLOR, one_way, &"plank")
	_add_placeholder_source(tileset, STAIR_COLOR, one_way, &"step")
	_add_placeholder_source(tileset, WALL_COLOR, one_way, &"wall")
	return tileset


func paint_block(bounds: Rect2, source_id: int) -> void:
	for row in range(int(bounds.position.y / TILE_SIZE), int(bounds.end.y / TILE_SIZE)):
		paint_floor(bounds.position.x, bounds.end.x, row * TILE_SIZE, source_id)


## The atlas tile for a cell: carved wall and wedge mass is the same cave-rock cobble as the dig rock, cut
## into an 8 x 8 atlas indexed by the cell, so it continues the stones around it; the rest are single tiles.
const ROCK_ATLAS := 8


static func _coords(source_id: int, x: int, y: int) -> Vector2i:
	if source_id == SOURCE_ROCK:
		return Vector2i(posmod(x, ROCK_ATLAS), posmod(y, ROCK_ATLAS))
	return ATLAS_TOP_MID


func _add_placeholder_source(tileset: TileSet, color: Color, one_way: bool = false, kind: StringName = &"wall") -> void:
	var texture: Texture2D = RockTextures.cobble() if kind == &"wall" else RockTextures.tile(kind, color)
	var atlas := TileSetAtlasSource.new()
	atlas.texture = texture
	atlas.texture_region_size = Vector2i(TILE_SIZE, TILE_SIZE)
	# Register the source with the tileset BEFORE creating tiles on it — a TileData's
	# physics-layer array is only populated once its atlas is actually part of a
	# TileSet that has physics layers; doing this in the other order silently leaves
	# tile_data with zero physics layers ("Index p_layer_id = 0 is out of bounds").
	tileset.add_source(atlas)
	var half := TILE_SIZE * 0.5
	var poly := PackedVector2Array([
		Vector2(-half, -half),
		Vector2(half, -half),
		Vector2(half, half),
		Vector2(-half, half),
	])
	var span := ROCK_ATLAS if kind == &"wall" else 1
	for ty in span:
		for tx in span:
			var coords := Vector2i(tx, ty)
			atlas.create_tile(coords)
			var tile_data := atlas.get_tile_data(coords, 0)
			if kind == &"wall":
				# the same rock shader as the slabs and the dig rock, so the wedges and walls match them
				tile_data.material = RockTextures.rock_material()
			tile_data.add_collision_polygon(0)
			tile_data.set_collision_polygon_points(0, 0, poly)
			if one_way:
				tile_data.set_collision_polygon_one_way(0, 0, true)
				tile_data.set_collision_polygon_one_way_margin(0, 0, 2.0)


## The child layer map decks live on (one-way). Null before _ready.
func deck_layer() -> TileMapLayer:
	return _decks


## Paint a flat ONE-WAY deck span (see the file header). Same arguments as paint_floor.
func paint_deck(x0_px: float, x1_px: float, y_px: float, source_id: int = SOURCE_LEDGE) -> void:
	var x0 := int(round(x0_px / TILE_SIZE))
	var x1 := int(round(x1_px / TILE_SIZE))
	var y := int(round(y_px / TILE_SIZE))
	if x0 > x1:
		var tmp := x0
		x0 = x1
		x1 = tmp
	for x in range(x0, x1):
		_decks.set_cell(Vector2i(x, y), source_id, _coords(source_id, x, y))


## True if any tile (either layer) sits within `reach` px below the standing deck row at the
## columns a body of half-width `half_width` covers around feet.x. The player asks this before
## stepping through a one-way deck so Down never drops into open air or the Mouth.
func has_support_below(feet: Vector2, half_width: float, reach: float) -> bool:
	var row0 := int(floor(feet.y / TILE_SIZE)) + 1
	var row1 := int(floor((feet.y + reach) / TILE_SIZE))
	var col0 := int(floor((feet.x - half_width) / TILE_SIZE))
	var col1 := int(floor((feet.x + half_width) / TILE_SIZE))
	for row in range(row0, row1 + 1):
		for col in range(col0, col1 + 1):
			if cell_source(Vector2i(col, row)) != -1:
				return true
	return false


## Source id painted at a cell on either layer (-1 = nothing). Decks win a shared cell.
func cell_source(cell: Vector2i) -> int:
	if _decks != null:
		var d := _decks.get_cell_source_id(cell)
		if d != -1:
			return d
	return get_cell_source_id(cell)


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
		set_cell(Vector2i(x, y), source_id, _coords(source_id, x, y))


## Paint a one-tile-per-column staircase between two deck tops (Rule 2 — no floating
## ramp polygons). y0_px/y1_px are the walkable tops at x0_px/x1_px respectively; both
## must be TILE_SIZE-aligned and the run is stepped one column at a time between them.
## Each column is filled from its own step down to the lower end, not just its single
## top tile — two diagonally-adjacent single tiles only share a corner, not an edge,
## which left visible gaps in the staircase's silhouette (confirmed in-engine); a
## filled solid-block staircase (Terraria's own convention, cited in terrain.gd) has
## no such gap and reads as one continuous ascending mass.
## Exception: inside Devil's Mouth (PIT_LEFT..PIT_RIGHT) only the walkable tread is
## painted — solid fill-down would plug the open void with stair mass.
## Inclusive of BOTH x0 and x1 (unlike paint_floor's exclusive-x1 span convention):
## a flight's own endpoints are where it hands off to the flat floor at each end, and
## paint_floor already excludes ITS x1/includes its x0 at a shared boundary — a stair
## whose x1 also excluded that same column left it painted by neither side, a real
## 1-tile gap confirmed in-engine between a flight and the landing/threshold it
## should land flush on.
func paint_stairs(x0_px: float, y0_px: float, x1_px: float, y1_px: float) -> void:
	var x0 := int(round(x0_px / TILE_SIZE))
	var x1 := int(round(x1_px / TILE_SIZE))
	var y0 := int(round(y0_px / TILE_SIZE))
	var y1 := int(round(y1_px / TILE_SIZE))
	var span := absi(x1 - x0)
	if span == 0:
		return
	var dir := 1 if x1 > x0 else -1
	var y_bottom := maxi(y0, y1)
	var pit_l := int(round(HollowLayout.PIT_LEFT / float(TILE_SIZE)))
	var pit_r := int(round(HollowLayout.PIT_RIGHT / float(TILE_SIZE)))
	for i in range(span + 1):
		var t := float(i) / float(span)
		var x := x0 + i * dir
		var y := int(round(lerpf(float(y0), float(y1), t)))
		var in_mouth := x >= pit_l and x < pit_r
		if in_mouth:
			set_cell(Vector2i(x, y), SOURCE_STAIR, ATLAS_TOP_MID)
		else:
			# the tread is a stone step; the mass under it is carved rock
			set_cell(Vector2i(x, y), SOURCE_STAIR, ATLAS_TOP_MID)
			for fy in range(y + 1, y_bottom + 1):
				set_cell(Vector2i(x, fy), SOURCE_ROCK, _coords(SOURCE_ROCK, x, fy))


func painted_cell_count() -> int:
	var count := 0
	for cell in get_used_cells():
		if get_cell_source_id(cell) != -1:
			count += 1
	if _decks != null:
		count += _decks.get_used_cells().size()
	return count
