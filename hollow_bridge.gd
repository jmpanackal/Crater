extends TileMapLayer
## Mid Heart + lower freight span bridge visuals — flat-color placeholder.
## Collision stays on Hollow Floor Heart*/LowerSpan shapes; this layer is display-only.
##
## Scale correction (2026-09-17): unified to the same 16px grid as Terrain
## (was 64px). The real PixelLab sheet this used to load
## (sprites/hollow_bridge/) was generated in an "Eastward/Owlboy-detail"
## style that predates this project's placeholder-art-first plan and its
## beginner-achievable pixel-art scale — removed, not resized, since it
## was never the target style. Uses a flat-color placeholder tile instead.
const TILE_SIZE := 16
const ATLAS_TOP_MID := Vector2i(0, 0)
const PLACEHOLDER_COLOR := Color(0.42, 0.32, 0.24, 0.95)


func _ready() -> void:
	texture_filter = TEXTURE_FILTER_NEAREST
	position = Vector2(0.0, -HollowLayout.FLOOR_VISUAL_INSET)
	tile_set = _build_tileset()
	_paint_bridge()


func _build_tileset() -> TileSet:
	var image := Image.create(TILE_SIZE, TILE_SIZE, false, Image.FORMAT_RGBA8)
	image.fill(PLACEHOLDER_COLOR)
	var texture := ImageTexture.create_from_image(image)

	var tileset := TileSet.new()
	tileset.tile_size = Vector2i(TILE_SIZE, TILE_SIZE)
	var atlas := TileSetAtlasSource.new()
	atlas.texture = texture
	atlas.texture_region_size = Vector2i(TILE_SIZE, TILE_SIZE)
	atlas.create_tile(ATLAS_TOP_MID)
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
