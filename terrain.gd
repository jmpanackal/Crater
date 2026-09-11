class_name TerrainLayer
extends TileMapLayer
## Terrain — diggable world grid for Krater.
## Owns tile creation and destruction so digging stays one reusable system
## (player tools, later NPCs/cave-ins, etc. should call into here).
## Dual frontiers: upward Firmament digs carry secrecy risk; downward Pit digs are
## public-ish danger (flavor + instability warning), same tools.

signal dig_completed(cell: Vector2i, direction: Vector2i, found_record: StringName)
signal frontier_notice(text: String)

## Dig cells stay 64px to match player art / dig spacing. SpriteFusion sources
## are 32x32 and nearest-neighbor upscaled into dig_site_tiles.png (4x3 atlas).
const TILE_SIZE := 64
const TILE_SHEET_PATH := "res://sprites/dig_site_tiles.png"

# Default atlas used by tests / simple fills (first SpriteFusion vein tile).
const PLACEHOLDER_ATLAS := Vector2i(0, 0)

## Cells with y < this are Firmament rock (secret upward frontier).
const FIRMAMENT_Y_MAX := 4
## Cells with y >= this are Pit walls (public-ish downward frontier).
const PIT_Y_MIN := 9

var _atlas_coords: Array[Vector2i] = []
var _pit_digs_since_warn := 0


func _ready() -> void:
	texture_filter = TEXTURE_FILTER_NEAREST
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

	_atlas_coords = _coords_for_texture(texture)
	for coord in _atlas_coords:
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
	for coord in _atlas_coords:
		var tile_data := atlas.get_tile_data(coord, 0)
		tile_data.add_collision_polygon(0)
		tile_data.set_collision_polygon_points(0, 0, poly)

	return tileset


func _coords_for_texture(texture: Texture2D) -> Array[Vector2i]:
	@warning_ignore("integer_division")
	var cols: int = texture.get_width() / TILE_SIZE
	@warning_ignore("integer_division")
	var rows: int = texture.get_height() / TILE_SIZE
	var coords: Array[Vector2i] = []
	for y in range(rows):
		for x in range(cols):
			coords.append(Vector2i(x, y))
	return coords


func _build_fallback_tileset() -> TileSet:
	_atlas_coords = [PLACEHOLDER_ATLAS]
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


## Dig columns start past the Hollow exit ledge (world x = cell * TILE_SIZE).
## Hollow is pit-centered terraces ending at ~1024; dig must not bleed into home.
const DIG_START_X := 16 # world 1024 — after Hollow exit ledge
const DIG_END_X := 32 # exclusive; 16 columns of Firmament/Pit


func _fill_ground() -> void:
	# Dig site past Hollow terraces + exit ledge (see HollowLayout.EXIT_RIGHT).
	# Firmament rock (secret) above the walk ledge; Pit walls deeper below.
	if _atlas_coords.is_empty():
		return
	for x in range(DIG_START_X, DIG_END_X):
		# Firmament / ceiling rock — upward secret frontier.
		for y in range(0, FIRMAMENT_Y_MAX + 1):
			_place_random(Vector2i(x, y))
		# Mid band + Pit walls — downward public-ish danger.
		for y in range(5, 16):
			_place_random(Vector2i(x, y))


func _place_random(cell: Vector2i) -> void:
	var atlas_coords: Vector2i = _atlas_coords[randi() % _atlas_coords.size()]
	set_cell(cell, 0, atlas_coords)


## True if this map cell currently has a diggable tile.
func has_tile(cell: Vector2i) -> bool:
	return get_cell_source_id(cell) != -1


func is_firmament_cell(cell: Vector2i) -> bool:
	return cell.y <= FIRMAMENT_Y_MAX


func is_pit_cell(cell: Vector2i) -> bool:
	return cell.y >= PIT_Y_MIN


## Remove a tile if present. Returns true when something was destroyed.
## Grants Salvage through Resources; yield comes from Upgrades when present.
## Salvage is carried haul — it only becomes useful when siphoned at the Hollow.
func destroy_cell(cell: Vector2i, direction: Vector2i = Vector2i.ZERO) -> bool:
	if not has_tile(cell):
		return false
	erase_cell(cell)
	var is_firmament := is_firmament_cell(cell)
	var is_pit := is_pit_cell(cell)
	var yield_amt := _salvage_yield_for_dig(cell)
	var wallet := _resource_wallet()
	if wallet:
		wallet.add(wallet.SALVAGE, yield_amt)
	_apply_frontier_rules(cell, direction)
	var world := to_global(map_to_local(cell))
	FeelFx.spawn_dig_dust(self, world, direction, is_firmament, is_pit)
	FeelFx.spawn_salvage_float(self, world, yield_amt, is_firmament, is_pit)
	var found := _try_record_drop(cell, direction)
	if found != StringName():
		FeelFx.spawn_record_float(self, world, "Record")
	dig_completed.emit(cell, direction, found)
	return true


func _salvage_yield_for_dig(cell: Vector2i) -> int:
	var base := _base_salvage_yield()
	# Pit digs sometimes shake loose a bit more — public danger payoff.
	if is_pit_cell(cell) and randf() < 0.2:
		return base + 1
	return base


func _base_salvage_yield() -> int:
	if is_inside_tree():
		var upgrades := get_tree().root.get_node_or_null("Upgrades")
		if upgrades and upgrades.has_method("get_dig_salvage_yield"):
			return int(upgrades.get_dig_salvage_yield())
	var wallet := _resource_wallet()
	if wallet:
		return int(wallet.SALVAGE_PER_TILE)
	return 1


func _apply_frontier_rules(cell: Vector2i, direction: Vector2i) -> void:
	var dug_up := direction.y < 0 or is_firmament_cell(cell)
	var dug_down := direction.y > 0 or is_pit_cell(cell)

	if dug_up and direction.y < 0:
		var upgrades := get_tree().root.get_node_or_null("Upgrades") if is_inside_tree() else null
		var quiet := 0
		if upgrades and upgrades.has_method("get_quiet_dig_level"):
			quiet = int(upgrades.get_quiet_dig_level())
		var community := get_tree().root.get_node_or_null("Community") if is_inside_tree() else null
		if community and community.has_method("roll_upward_dig_risk"):
			community.roll_upward_dig_risk(quiet)

	if dug_down and is_pit_cell(cell):
		_pit_digs_since_warn += 1
		if _pit_digs_since_warn >= 4:
			_pit_digs_since_warn = 0
			frontier_notice.emit("The Pit walls groan. Going further feels wrong — but not forbidden.")


func _try_record_drop(cell: Vector2i, direction: Vector2i) -> StringName:
	if not is_inside_tree():
		return StringName()
	var journal := get_tree().root.get_node_or_null("Journal")
	if journal == null or not journal.has_method("try_find_on_dig"):
		return StringName()
	var dug_upward := direction.y < 0 or is_firmament_cell(cell)
	var found: StringName = journal.try_find_on_dig(dug_upward)
	if found != StringName():
		var def: Dictionary = journal.get_def(found)
		frontier_notice.emit("Record found: %s" % str(def.get("title", found)))
	return found


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
## Same path for every direction — Firmament vs Pit fiction layers wrap outcomes.
func dig_in_direction(origin_world: Vector2, direction: Vector2i) -> bool:
	var cardinal := _to_cardinal(direction)
	if cardinal == Vector2i.ZERO:
		return false

	var target_world := origin_world + Vector2(cardinal) * float(TILE_SIZE)
	return destroy_cell(world_to_cell(target_world), cardinal)


## Collapse any Vector2i into a single cardinal dig direction (no diagonals yet).
## Vertical aim wins if both axes are set, so W/S clearly dig up/down while moving.
func _to_cardinal(direction: Vector2i) -> Vector2i:
	if direction.y != 0:
		return Vector2i(0, signi(direction.y))
	if direction.x != 0:
		return Vector2i(signi(direction.x), 0)
	return Vector2i.ZERO
