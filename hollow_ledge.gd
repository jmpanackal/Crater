extends TileMapLayer
## Terrace cliff ledge + timber joist underside — flat-color placeholder.
## Extends hollow_floor language on left/right decks; Mid Heart / spans use bridge source elsewhere.
## Collision stays on Hollow StaticBody2D decks; this layer is display-only.
##
## Scale correction (2026-09-17): unified to the same 16px grid as Terrain
## (was 64px). The real PixelLab sheet this used to load
## (sprites/hollow_ledge/) was generated in an "Eastward/Owlboy-detail"
## style that predates this project's placeholder-art-first plan and its
## beginner-achievable pixel-art scale — removed, not resized, since it
## was never the target style. Uses a flat-color placeholder tile instead.
const TILE_SIZE := 16
const ATLAS_TOP_MID := Vector2i(0, 0)
const PLACEHOLDER_COLOR := Color(0.5, 0.4, 0.3, 0.95)


func _ready() -> void:
	texture_filter = TEXTURE_FILTER_NEAREST
	position = Vector2(0.0, -HollowLayout.FLOOR_VISUAL_INSET)
	tile_set = _build_tileset()
	_paint_ledges()


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


func _paint_ledges() -> void:
	clear()
	var farms_y := int(HollowLayout.FARMS_Y / TILE_SIZE)
	var wick_y := int(HollowLayout.WICK_Y / TILE_SIZE)
	var cistern_y := int(HollowLayout.CISTERN_Y / TILE_SIZE)
	var left := int(HollowLayout.HOLLOW_LEFT / TILE_SIZE)
	var pit_r := int(HollowLayout.PIT_RIGHT / TILE_SIZE)
	var exit_r := int(HollowLayout.EXIT_RIGHT / TILE_SIZE)
	var lift_open := int(HollowLayout.LIFT_OPEN_X / TILE_SIZE)
	var cistern_open := int(HollowLayout.LADDER_CISTERN_OPEN_X / TILE_SIZE)

	_paint_span(left, lift_open, farms_y)
	_paint_span(left, lift_open, wick_y)
	_paint_span(pit_r, cistern_open, wick_y)
	_paint_span(cistern_open + 1, exit_r, wick_y)
	_paint_span(lift_open - 2, lift_open, cistern_y)
	_paint_span(pit_r, cistern_open, cistern_y)
	_paint_span(cistern_open + 1, exit_r, cistern_y)


func _paint_span(x0: int, x1: int, y: int) -> void:
	for x in range(x0, x1):
		set_cell(Vector2i(x, y), 0, ATLAS_TOP_MID)


func painted_cell_count() -> int:
	var count := 0
	for cell in get_used_cells():
		if get_cell_source_id(cell) != -1:
			count += 1
	return count
