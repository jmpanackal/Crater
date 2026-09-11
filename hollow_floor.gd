extends TileMapLayer
## Hollow walkable floor visuals — PixelLab sidescroller tiles (64px = 32×2 NN).
## Collision stays on Hollow StaticBody2D decks; this layer is display-only.
## Source 0 = hollow_ledge (terraces), source 1 = hollow_bridge (mid pit).
## Upper decks leave a tile-aligned gap at each ladder top; lower landings stay solid.

const TILE_SIZE := 64
const LEDGE_SHEET := "res://sprites/hollow_ledge/hollow_ledge_tiles_64.png"
const BRIDGE_SHEET := "res://sprites/hollow_bridge/hollow_bridge_tiles_64.png"
const SOURCE_LEDGE := 0
const SOURCE_BRIDGE := 1
## wang_12 = flat top ledge (air above, rock/planks below).
const ATLAS_TOP_MID := Vector2i(3, 0)


func _ready() -> void:
	texture_filter = TEXTURE_FILTER_NEAREST
	# Cell top == deck_y for collision, but atlas ledge art only fills the lower half.
	position = Vector2(0.0, -HollowLayout.FLOOR_VISUAL_INSET)
	tile_set = _build_tileset()
	_paint_terraces()


func _build_tileset() -> TileSet:
	var tileset := TileSet.new()
	tileset.tile_size = Vector2i(TILE_SIZE, TILE_SIZE)
	_add_sheet(tileset, LEDGE_SHEET)
	_add_sheet(tileset, BRIDGE_SHEET)
	return tileset


func _add_sheet(tileset: TileSet, path: String) -> void:
	var texture: Texture2D = load(path)
	if texture == null:
		push_error("HollowFloor: missing %s" % path)
		return
	var atlas := TileSetAtlasSource.new()
	atlas.texture = texture
	atlas.texture_region_size = Vector2i(TILE_SIZE, TILE_SIZE)
	for y in range(4):
		for x in range(4):
			atlas.create_tile(Vector2i(x, y))
	tileset.add_source(atlas)


func _paint_terraces() -> void:
	clear()
	var farms_y := int(HollowLayout.FARMS_Y / TILE_SIZE)
	var wick_y := int(HollowLayout.WICK_Y / TILE_SIZE)
	var cistern_y := int(HollowLayout.CISTERN_Y / TILE_SIZE)
	var pit_l := int(HollowLayout.PIT_LEFT / TILE_SIZE)
	var pit_r := int(HollowLayout.PIT_RIGHT / TILE_SIZE)
	var exit_r := int(HollowLayout.EXIT_RIGHT / TILE_SIZE)
	var farms_open := int(HollowLayout.LADDER_FARMS_OPEN_X / TILE_SIZE)
	var cistern_open := int(HollowLayout.LADDER_CISTERN_OPEN_X / TILE_SIZE)

	_paint_span(0, farms_open, farms_y, SOURCE_LEDGE)
	_paint_span(0, pit_l, wick_y, SOURCE_LEDGE)
	_paint_span(pit_l, pit_r, wick_y, SOURCE_BRIDGE)
	_paint_span(pit_r, cistern_open, wick_y, SOURCE_LEDGE)
	_paint_span(cistern_open + 1, exit_r, wick_y, SOURCE_LEDGE)
	_paint_span(pit_r + 1, exit_r - 1, cistern_y, SOURCE_LEDGE)


func _paint_span(x0: int, x1: int, y: int, source_id: int) -> void:
	for x in range(x0, x1):
		set_cell(Vector2i(x, y), source_id, ATLAS_TOP_MID)


## Cell count used by smoke tests (left farms + wick left/bridge/right + cistern).
func painted_cell_count() -> int:
	var count := 0
	for cell in get_used_cells():
		if get_cell_source_id(cell) != -1:
			count += 1
	return count
