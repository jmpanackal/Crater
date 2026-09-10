class_name TerrainLayer
extends TileMapLayer
## Terrain — diggable world grid for Krater.
## Owns tile creation and destruction so digging stays one reusable system
## (player tools, later NPCs/cave-ins, etc. should call into here).

const TILE_SIZE := 32
const GROUND_COLOR := Color(0.45, 0.32, 0.22)

# Atlas coords for the placeholder solid tile (source id 0).
const PLACEHOLDER_ATLAS := Vector2i.ZERO


func _ready() -> void:
	tile_set = _build_tileset()
	_fill_ground()


## Build a one-tile TileSet at runtime (plain color + collision).
## Real art later = swap the atlas texture; dig API stays the same.
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
	atlas.create_tile(PLACEHOLDER_ATLAS)

	# Source must be on the TileSet before TileData physics edits are kept.
	tileset.add_source(atlas)

	var half := float(TILE_SIZE) / 2.0
	var tile_data := atlas.get_tile_data(PLACEHOLDER_ATLAS, 0)
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
	# Placeholder dirt bed under the spawn area (several rows for dig depth).
	for x in range(0, 40):
		for y in range(11, 24):
			set_cell(Vector2i(x, y), 0, PLACEHOLDER_ATLAS)


## True if this map cell currently has a diggable tile.
func has_tile(cell: Vector2i) -> bool:
	return get_cell_source_id(cell) != -1


## Remove a tile if present. Returns true when something was destroyed.
## Grants Ore through the Resources autoload so any dig path shares the same payout.
func destroy_cell(cell: Vector2i) -> bool:
	if not has_tile(cell):
		return false
	erase_cell(cell)
	var wallet := _resource_wallet()
	if wallet:
		wallet.add(wallet.ORE, wallet.ORE_PER_TILE)
	return true


## Live Resources autoload instance (node name from project.godot).
func _resource_wallet() -> Node:
	if not is_inside_tree():
		return null
	return get_tree().root.get_node_or_null("Resources")


## Convert a world-space point to a map cell on this layer.
func world_to_cell(world_pos: Vector2) -> Vector2i:
	return local_to_map(to_local(world_pos))


## Dig the tile adjacent to a world-space origin in a cardinal direction.
## `direction` should be one of: LEFT, RIGHT, UP, DOWN (Vector2i).
## Same path for every direction — up/down fiction layers can wrap this later.
func dig_in_direction(origin_world: Vector2, direction: Vector2i) -> bool:
	var cardinal := _to_cardinal(direction)
	if cardinal == Vector2i.ZERO:
		return false

	var target_world := origin_world + Vector2(cardinal) * float(TILE_SIZE)
	return destroy_cell(world_to_cell(target_world))


## Collapse any Vector2i into a single cardinal dig direction (no diagonals yet).
## Vertical aim wins if both axes are set, so W/S clearly dig up/down while moving.
func _to_cardinal(direction: Vector2i) -> Vector2i:
	if direction.y != 0:
		return Vector2i(0, signi(direction.y))
	if direction.x != 0:
		return Vector2i(signi(direction.x), 0)
	return Vector2i.ZERO
