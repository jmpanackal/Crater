extends TileMapLayer
## Hollow walkable floor visuals — flat-color placeholder tiles.
## Collision stays on Hollow StaticBody2D decks; this layer is display-only.
## Source 0 = ledge placeholder (terraces), source 1 = bridge placeholder (Heart / lower span).
## Lift shafts and local ladder openings stay empty on their bands.
##
## Scale correction (2026-09-17): unified to the same 16px grid as Terrain
## (was 64px). The real PixelLab sheets this used to load
## (sprites/hollow_ledge/, sprites/hollow_bridge/) were generated in an
## "Eastward/Owlboy-detail" style that predates this project's
## placeholder-art-first plan and its beginner-achievable pixel-art scale
## — removed, not resized, since they were never the target style. Uses
## flat-color placeholder tiles instead, one per source.
const TILE_SIZE := 16
const SOURCE_LEDGE := 0
const SOURCE_BRIDGE := 1
const ATLAS_TOP_MID := Vector2i(0, 0)
const LEDGE_COLOR := Color(0.5, 0.4, 0.3, 0.95)
const BRIDGE_COLOR := Color(0.42, 0.32, 0.24, 0.95)


func _ready() -> void:
	texture_filter = TEXTURE_FILTER_NEAREST
	position = Vector2(0.0, -HollowLayout.FLOOR_VISUAL_INSET)
	tile_set = _build_tileset()
	_paint_terraces()


func _build_tileset() -> TileSet:
	var tileset := TileSet.new()
	tileset.tile_size = Vector2i(TILE_SIZE, TILE_SIZE)
	_add_placeholder_source(tileset, LEDGE_COLOR)
	_add_placeholder_source(tileset, BRIDGE_COLOR)
	return tileset


func _add_placeholder_source(tileset: TileSet, color: Color) -> void:
	var image := Image.create(TILE_SIZE, TILE_SIZE, false, Image.FORMAT_RGBA8)
	image.fill(color)
	var texture := ImageTexture.create_from_image(image)
	var atlas := TileSetAtlasSource.new()
	atlas.texture = texture
	atlas.texture_region_size = Vector2i(TILE_SIZE, TILE_SIZE)
	atlas.create_tile(ATLAS_TOP_MID)
	tileset.add_source(atlas)


func _paint_terraces() -> void:
	clear()
	var farms_y := int(HollowLayout.FARMS_Y / TILE_SIZE)
	var glow_sub_y := int(HollowLayout.GLOW_SUB_Y / TILE_SIZE)
	var wick_y := int(HollowLayout.WICK_Y / TILE_SIZE)
	var mid_allot_y := int(HollowLayout.MID_ALLOT_Y / TILE_SIZE)
	var lower_y := int(HollowLayout.LOWER_WORK_Y / TILE_SIZE)
	var cistern_y := int(HollowLayout.CISTERN_Y / TILE_SIZE)
	var seep_y := int(HollowLayout.SEEP_Y / TILE_SIZE)
	var upper_res_y := int(HollowLayout.UPPER_RES_Y / TILE_SIZE)
	var left := int(HollowLayout.HOLLOW_LEFT / TILE_SIZE)
	var pit_l := int(HollowLayout.PIT_LEFT / TILE_SIZE)
	var pit_r := int(HollowLayout.PIT_RIGHT / TILE_SIZE)
	var exit_r := int(HollowLayout.EXIT_RIGHT / TILE_SIZE)
	var heart_open := int(HollowLayout.LIFT_OPEN_X / TILE_SIZE)
	var left_open := int(HollowLayout.LEFT_LIFT_OPEN_X / TILE_SIZE)
	var freight_open := int(HollowLayout.FREIGHT_LIFT_OPEN_X / TILE_SIZE)
	var mid_ladder := int(HollowLayout.LADDER_MID_OPEN_X / TILE_SIZE)
	var cistern_ladder := int(HollowLayout.LADDER_CISTERN_OPEN_X / TILE_SIZE)

	var upper_ladder := int(HollowLayout.LADDER_UPPER_OPEN_X / TILE_SIZE)

	# Upper residences + Glowbeds bands (skip lift + residence-ladder openings).
	_paint_span(left, upper_ladder, upper_res_y, SOURCE_LEDGE)
	_paint_span(upper_ladder + 1, heart_open, upper_res_y, SOURCE_LEDGE)
	_paint_span(left, left_open, farms_y, SOURCE_LEDGE)
	_paint_span(left_open + 1, heart_open, farms_y, SOURCE_LEDGE)
	_paint_span(left, left_open, glow_sub_y, SOURCE_LEDGE)
	_paint_span(left_open + 1, heart_open - 1, glow_sub_y, SOURCE_LEDGE)

	# Wickwork left around mid ladder + left service + Heart hoist.
	_paint_span(left, mid_ladder, wick_y, SOURCE_LEDGE)
	_paint_span(mid_ladder + 1, left_open, wick_y, SOURCE_LEDGE)
	_paint_span(left_open + 1, heart_open, wick_y, SOURCE_LEDGE)
	# Mid allotment is the lower landing under LadderMid — keep solid (opening only on Wick).
	_paint_span(left, heart_open - 1, mid_allot_y, SOURCE_LEDGE)

	# Mid Heart cluster — bridge tiles with gaps keeping the void readable.
	var heart_west0 := int(HollowLayout.HEART_WEST.x / TILE_SIZE)
	var heart_west1 := int(HollowLayout.HEART_WEST.y / TILE_SIZE)
	var heart_mid0 := int(HollowLayout.HEART_MID.x / TILE_SIZE)
	var heart_mid1 := int(HollowLayout.HEART_MID.y / TILE_SIZE)
	var heart_east0 := int(HollowLayout.HEART_EAST.x / TILE_SIZE)
	var heart_east1 := int(HollowLayout.HEART_EAST.y / TILE_SIZE)
	_paint_span(heart_west0, heart_west1, wick_y, SOURCE_BRIDGE)
	_paint_span(heart_mid0, heart_mid1, wick_y, SOURCE_BRIDGE)
	_paint_span(heart_east0, heart_east1, wick_y, SOURCE_BRIDGE)

	# Right mid terrace around freight (Cistern ladder opens only on lower-work).
	_paint_span(pit_r, freight_open, wick_y, SOURCE_LEDGE)
	_paint_span(freight_open + 1, exit_r, wick_y, SOURCE_LEDGE)

	# Lower working band + Mouth transfer span.
	_paint_span(left + 1, heart_open, lower_y, SOURCE_LEDGE)
	_paint_span(pit_l, pit_r, lower_y, SOURCE_BRIDGE)
	_paint_span(pit_r, cistern_ladder, lower_y, SOURCE_LEDGE)
	_paint_span(cistern_ladder + 1, freight_open, lower_y, SOURCE_LEDGE)
	_paint_span(freight_open + 1, int(HollowLayout.HOLLOW_RIGHT / TILE_SIZE), lower_y, SOURCE_LEDGE)

	# Cistern + seep: ladder opening only on lower-work (upper); Cistern landing solid.
	_paint_span(pit_r, freight_open, cistern_y, SOURCE_LEDGE)
	_paint_span(freight_open + 1, exit_r, cistern_y, SOURCE_LEDGE)
	_paint_span(freight_open - 1, freight_open, seep_y, SOURCE_LEDGE)
	_paint_span(freight_open + 1, exit_r, seep_y, SOURCE_LEDGE)


func _paint_span(x0: int, x1: int, y: int, source_id: int) -> void:
	for x in range(x0, x1):
		set_cell(Vector2i(x, y), source_id, ATLAS_TOP_MID)


func painted_cell_count() -> int:
	var count := 0
	for cell in get_used_cells():
		if get_cell_source_id(cell) != -1:
			count += 1
	return count
