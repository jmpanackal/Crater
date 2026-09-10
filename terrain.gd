extends TileMapLayer

const TILE_SIZE := 32
const GROUND_COLOR := Color(0.45, 0.32, 0.22)


func _ready() -> void:
	tile_set = _build_tileset()
	_fill_ground()


func _build_tileset() -> TileSet:
	var image := Image.create(TILE_SIZE, TILE_SIZE, false, Image.FORMAT_RGBA8)
	image.fill(GROUND_COLOR)
	var texture := ImageTexture.create_from_image(image)

	var tileset := TileSet.new()
	tileset.tile_size = Vector2i(TILE_SIZE, TILE_SIZE)
	# Physics layer must exist before collision polygons are authored on tile data.
	tileset.add_physics_layer()

	var atlas := TileSetAtlasSource.new()
	atlas.texture = texture
	atlas.texture_region_size = Vector2i(TILE_SIZE, TILE_SIZE)
	atlas.create_tile(Vector2i.ZERO)

	# Source must be on the TileSet before TileData physics edits are kept.
	tileset.add_source(atlas)

	var half := float(TILE_SIZE) / 2.0
	var tile_data := atlas.get_tile_data(Vector2i.ZERO, 0)
	tile_data.add_collision_polygon(0)
	tile_data.set_collision_polygon_points(
		0,
		0,
		PackedVector2Array([
			Vector2(-half, -half),
			Vector2(half, -half),
			Vector2(half, half),
			Vector2(-half, half),
		])
	)

	return tileset


func _fill_ground() -> void:
	for x in range(0, 40):
		for y in range(11, 24):
			set_cell(Vector2i(x, y), 0, Vector2i.ZERO)
