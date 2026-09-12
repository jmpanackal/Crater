extends TileMapLayer
## Mid Heart + lower freight span bridge visuals (PixelLab sidescroller, 64px).
## Collision stays on Hollow Floor Heart*/LowerSpan shapes; this layer is display-only.

const TILE_SIZE := 64
const SHEET_PATH := "res://sprites/hollow_bridge/hollow_bridge_tiles_64.png"
const ATLAS_TOP_MID := Vector2i(3, 0)


func _ready() -> void:
	texture_filter = TEXTURE_FILTER_NEAREST
	position = Vector2(0.0, -HollowLayout.FLOOR_VISUAL_INSET)
	tile_set = _build_tileset()
	_paint_bridge()


func _build_tileset() -> TileSet:
	var texture: Texture2D = load(SHEET_PATH)
	if texture == null:
		push_error("HollowBridge: missing %s" % SHEET_PATH)
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


func _paint_bridge() -> void:
	clear()
	var wick_y := int(HollowLayout.WICK_Y / TILE_SIZE)
	var lower_y := int(HollowLayout.LOWER_WORK_Y / TILE_SIZE)
	var pit_l := int(HollowLayout.PIT_LEFT / TILE_SIZE)
	var pit_r := int(HollowLayout.PIT_RIGHT / TILE_SIZE)
	# Mid Heart cluster cells only (leave deliberate gaps in the void).
	for x in [6, 7, 8, 9, 10, 11]:
		set_cell(Vector2i(x, wick_y), 0, ATLAS_TOP_MID)
	# Lower Heart freight / worker transfer across the Mouth.
	for x in range(pit_l, pit_r):
		set_cell(Vector2i(x, lower_y), 0, ATLAS_TOP_MID)


func painted_cell_count() -> int:
	var count := 0
	for cell in get_used_cells():
		if get_cell_source_id(cell) != -1:
			count += 1
	return count
