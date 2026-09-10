class_name TerrainLayer
extends TileMapLayer
## Terrain — diggable world grid for Krater.
## Owns tile creation and destruction so digging stays one reusable system
## (player tools, later NPCs/cave-ins, etc. should call into here).

## Matches sprites/dig_site_tiles.png (2x2 of 64px) and the 64px player art.
const TILE_SIZE := 64
const TILE_SHEET_PATH := "res://sprites/dig_site_tiles.png"

# Atlas coords in dig_site_tiles.png (2x2 sheet).
const ATLAS_SOLID := Vector2i(0, 0)
const ATLAS_CRACKED := Vector2i(1, 0)
const ATLAS_RUBBLE := Vector2i(0, 1)
const ATLAS_DEBRIS := Vector2i(1, 1)

# Default atlas used by tests / simple fills (solid mineral rock).
const PLACEHOLDER_ATLAS := ATLAS_SOLID


func _ready() -> void:
	tile_set = _build_tileset()
	_fill_ground()


## Build TileSet from the dig-site sheet; every variant gets full-cell collision.
func _build_tileset() -> TileSet:
	var texture: Texture2D = load(TILE_SHEET_PATH)
	if texture == null:
		push_error("TerrainLayer: missing %s — using flat fallback" % TILE_SHEET_PATH)
		return _build_fallback_tileset()

	var tileset := TileSet.new()
	tileset.tile_size = Vector2i(TILE_SIZE, TILE_SIZE)
	tileset.add_physics_layer()

	var atlas := TileSetAtlasSource.new()
	atlas.texture = texture
	atlas.texture_region_size = Vector2i(TILE_SIZE, TILE_SIZE)

	var coords := [ATLAS_SOLID, ATLAS_CRACKED, ATLAS_RUBBLE, ATLAS_DEBRIS]
	for coord in coords:
		atlas.create_tile(coord)

	# Source must be on the TileSet before TileData physics edits are kept.
	tileset.add_source(atlas)

	var half := float(TILE_SIZE) / 2.0
	var poly := PackedVector2Array([
		Vector2(-half, -half),
		Vector2(half, -half),
		Vector2(half, half),
		Vector2(-half, half),
	])
	for coord in coords:
		var tile_data := atlas.get_tile_data(coord, 0)
		tile_data.add_collision_polygon(0)
		tile_data.set_collision_polygon_points(0, 0, poly)

	return tileset


func _build_fallback_tileset() -> TileSet:
	var image := Image.create(TILE_SIZE, TILE_SIZE, false, Image.FORMAT_RGBA8)
	image.fill(Color(0.25, 0.4, 0.42))
	var texture := ImageTexture.create_from_image(image)
	var tileset := TileSet.new()
	tileset.tile_size = Vector2i(TILE_SIZE, TILE_SIZE)
	tileset.add_physics_layer()
	var atlas := TileSetAtlasSource.new()
	atlas.texture = texture
	atlas.texture_region_size = Vector2i(TILE_SIZE, TILE_SIZE)
	atlas.create_tile(PLACEHOLDER_ATLAS)
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
	# Dig site to the right of the Hollow. Cell size 64 → x=5 is world x=320.
	var variants := [ATLAS_SOLID, ATLAS_SOLID, ATLAS_CRACKED, ATLAS_CRACKED, ATLAS_RUBBLE]
	for x in range(5, 20):
		for y in range(5, 12):
			var atlas_coords: Vector2i = variants[randi() % variants.size()]
			# Deeper rows lean solid/cracked; surface can show rubble occasionally.
			if y >= 8 and randf() < 0.15:
				atlas_coords = ATLAS_DEBRIS
			set_cell(Vector2i(x, y), 0, atlas_coords)


## True if this map cell currently has a diggable tile.
func has_tile(cell: Vector2i) -> bool:
	return get_cell_source_id(cell) != -1


## Remove a tile if present. Returns true when something was destroyed.
## Grants Salvage through Resources; yield comes from Upgrades when present.
## Salvage is carried haul — it only becomes useful when siphoned at the Hollow.
func destroy_cell(cell: Vector2i) -> bool:
	if not has_tile(cell):
		return false
	erase_cell(cell)
	var wallet := _resource_wallet()
	if wallet:
		wallet.add(wallet.SALVAGE, _salvage_yield_for_dig())
	return true


## Live Resources autoload instance (node name from project.godot).
func _resource_wallet() -> Node:
	if not is_inside_tree():
		return null
	return get_tree().root.get_node_or_null("Resources")


## Prefer Upgrades dig yield so Hollow siphons visibly change payout.
func _salvage_yield_for_dig() -> int:
	if is_inside_tree():
		var upgrades := get_tree().root.get_node_or_null("Upgrades")
		if upgrades and upgrades.has_method("get_dig_salvage_yield"):
			return int(upgrades.get_dig_salvage_yield())
	var wallet := _resource_wallet()
	if wallet:
		return int(wallet.SALVAGE_PER_TILE)
	return 1


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
