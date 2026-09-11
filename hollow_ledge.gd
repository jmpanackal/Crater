extends TileMapLayer
## Terrace cliff ledge + timber joist underside (PixelLab sidescroller, 64px = 32×2 NN).
## Extends hollow_floor language on left/right decks; mid-bridge is hollow_bridge.
## Collision stays on Hollow StaticBody2D decks; this layer is display-only.

const TILE_SIZE := 64
const SHEET_PATH := "res://sprites/hollow_ledge/hollow_ledge_tiles_64.png"
## wang_12 = flat top ledge (air above, cliff + joist below).
const ATLAS_TOP_MID := Vector2i(3, 0)


func _ready() -> void:
	texture_filter = TEXTURE_FILTER_NEAREST
	position = Vector2(0.0, -HollowLayout.FLOOR_VISUAL_INSET)
	tile_set = _build_tileset()
	_paint_ledges()


func _build_tileset() -> TileSet:
	var texture: Texture2D = load(SHEET_PATH)
	if texture == null:
		push_error("HollowLedge: missing %s" % SHEET_PATH)
		return TileSet.new()

	var tileset := TileSet.new()
	tileset.tile_size = Vector2i(TILE_SIZE, TILE_SIZE)
	var atlas := TileSetAtlasSource.new()
	atlas.texture = texture
	atlas.texture_region_size = Vector2i(TILE_SIZE, TILE_SIZE)
	for y in range(4):
		for x in range(4):
			atlas.create_tile(Vector2i(x, y))
	tileset.add_source(atlas)
	return tileset


func _paint_ledges() -> void:
	clear()
	var farms_y := int(HollowLayout.FARMS_Y / TILE_SIZE)
	var wick_y := int(HollowLayout.WICK_Y / TILE_SIZE)
	var cistern_y := int(HollowLayout.CISTERN_Y / TILE_SIZE)
	var pit_l := int(HollowLayout.PIT_LEFT / TILE_SIZE)
	var pit_r := int(HollowLayout.PIT_RIGHT / TILE_SIZE)
	var exit_r := int(HollowLayout.EXIT_RIGHT / TILE_SIZE)
	var farms_open := int(HollowLayout.LADDER_FARMS_OPEN_X / TILE_SIZE)
	var cistern_open := int(HollowLayout.LADDER_CISTERN_OPEN_X / TILE_SIZE)

	# Terraces only — mid-bridge owned by HollowBridge.
	_paint_span(0, farms_open, farms_y)
	_paint_span(0, pit_l, wick_y)
	_paint_span(pit_r, cistern_open, wick_y)
	_paint_span(cistern_open + 1, exit_r, wick_y)
	_paint_span(pit_r + 1, exit_r - 1, cistern_y)


func _paint_span(x0: int, x1: int, y: int) -> void:
	for x in range(x0, x1):
		set_cell(Vector2i(x, y), 0, ATLAS_TOP_MID)


func painted_cell_count() -> int:
	var count := 0
	for cell in get_used_cells():
		if get_cell_source_id(cell) != -1:
			count += 1
	return count
