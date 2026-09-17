class_name TerrainLayer
extends TileMapLayer
## Terrain — diggable world grid for Krater.
## Owns tile creation and destruction so digging stays one reusable system
## (player tools, later NPCs/cave-ins, etc. should call into here).
## Dual frontiers: upward Firmament digs carry secrecy risk; downward Devil’s Mouth digs are
## public-ish danger (flavor + instability warning), same tools.

signal dig_completed(cell: Vector2i, direction: Vector2i, found_record: StringName)
signal frontier_notice(text: String)

## Scale correction (2026-09-17): dig cells were 64px, letting a single dig
## cover more ground than the Stamina/Hauling/Fatigue systems intend to make
## weighty. Unified to 16px so digging reads as incremental work, matching
## Dome Keeper/Terraria precedent, per the scale-visualization pass in
## CONTEXT.md. World-space envelope bounds below (DIG_START_X/END_X,
## FIRMAMENT_Y_MAX, MOUTH_Y_MIN) are re-derived to cover the exact same
## world-pixel footprint as before — only the grid fineness changed.
const TILE_SIZE := 16

# Default atlas used by tests / simple fills (first SpriteFusion vein tile).
const PLACEHOLDER_ATLAS := Vector2i(0, 0)

## Cells with y < this are Firmament rock (secret upward frontier).
## Re-derived for TILE_SIZE=16 to cover the same world-y span as the old
## 64px value (4): (4+1)*64 = 320px -> (320/16)-1 = 19.
const FIRMAMENT_Y_MAX := 19
## Cells with y >= this are Devil’s Mouth walls (public-ish downward frontier).
## Re-derived for TILE_SIZE=16 to cover the same world-y as the old 64px
## value (9): 9*64 = 576px -> 576/16 = 36.
const MOUTH_Y_MIN := 36

var _atlas_coords: Array[Vector2i] = []
var _pit_digs_since_warn := 0


func _ready() -> void:
	texture_filter = TEXTURE_FILTER_NEAREST
	tile_set = _build_tileset()
	_fill_ground()
	# Build Bible Spec 02's save contract only auto-discovers autoloads by
	# root-relative name; Terrain has to live inside the play scene's
	# hierarchy to render/collide correctly, so it registers itself with
	# SaveLoad instead (see save_load.gd's register_scene_domain()).
	var save_load := get_tree().root.get_node_or_null("SaveLoad") if is_inside_tree() else null
	if save_load != null and save_load.has_method("register_scene_domain"):
		save_load.register_scene_domain("Terrain", self)


func _exit_tree() -> void:
	var save_load := get_tree().root.get_node_or_null("SaveLoad")
	if save_load != null and save_load.has_method("unregister_scene_domain"):
		save_load.unregister_scene_domain("Terrain")


## Builds the flat-color placeholder tileset. The real SpriteFusion art at
## res://sprites/dig_site_tiles.png is sized for the old 64px grid — slicing
## it at the new 16px TILE_SIZE would mis-crop every real tile into 16
## garbled sub-pieces, not shrink them. A 16px dig-site sheet needs to be
## generated before this loads real art again; until then the flat-color
## fallback is correct on its own terms, not a stopgap — this project's
## placeholder-art-first plan already calls for greybox art at this stage.
func _build_tileset() -> TileSet:
	return _build_fallback_tileset()


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
## Re-derived for TILE_SIZE=16 to cover the same world-x span as the old
## 64px values (16..32, i.e. world 1024..2048): 1024/16 = 64, 2048/16 = 128.
const DIG_START_X := 64 # world 1024 — after Hollow exit ledge
const DIG_END_X := 128 # exclusive; 64 columns of Firmament/Devil’s Mouth


func _fill_ground() -> void:
	# Dig site past Hollow terraces + exit ledge (see HollowLayout.EXIT_RIGHT).
	# Firmament rock (secret) above the walk ledge; Devil’s Mouth walls deeper below.
	if _atlas_coords.is_empty():
		return
	for x in range(DIG_START_X, DIG_END_X):
		# Firmament / ceiling rock — upward secret frontier.
		for y in range(0, FIRMAMENT_Y_MAX + 1):
			_place_random(Vector2i(x, y))
		# Mid band + Devil’s Mouth walls — downward public-ish danger.
		# Re-derived for TILE_SIZE=16 from the old 64px range(5, 16): 5*4=20, 16*4=64.
		for y in range(20, 64):
			_place_random(Vector2i(x, y))


func _place_random(cell: Vector2i) -> void:
	var atlas_coords: Vector2i = _atlas_coords[randi() % _atlas_coords.size()]
	set_cell(cell, 0, atlas_coords)


## True if this map cell currently has a diggable tile.
func has_tile(cell: Vector2i) -> bool:
	return get_cell_source_id(cell) != -1


## Build Bible Spec 06 contract surface — see docs/build-bible/specs/06-
## destructible-terrain.md. The envelope is currently the same rectangle
## _fill_ground() authors (DIG_START_X..DIG_END_X, y 0..63) — opt-in
## destructibility per §63/the atlas's "fixed outer envelope of
## destructible chunks" language: nothing outside it is diggable, full
## stop, regardless of whether a real Zone (Spec 05, not authored yet)
## eventually replaces this rectangle with real chunk-authored bounds.
func is_within_dig_envelope(cell: Vector2i) -> bool:
	return cell.x >= DIG_START_X and cell.x < DIG_END_X and cell.y >= 0 and cell.y < 64


## can_dig(position) from the spec's contract surface, in world space to
## match dig_in_direction()'s existing convention. False outside the
## authored envelope — true within it regardless of whether that specific
## cell has already been dug (an already-dug cell is a legal dig ATTEMPT
## that will simply find nothing there; only being outside the envelope
## entirely is refused at this level).
func can_dig(world_pos: Vector2) -> bool:
	return is_within_dig_envelope(world_to_cell(world_pos))


## dig(position) from the spec's contract surface: mutates terrain, emits
## the EventBus dig event, and returns what was exposed/extracted. Refuses
## cleanly (no mutation, no event) outside the authored envelope — Spec 06's
## own failure case: "a no-op with feedback, never a crash or an unintended
## tunnel into fixed geography." Delegates to the existing dig_in_direction/
## destroy_cell internals rather than duplicating their logic.
func dig(world_pos: Vector2, direction: Vector2i) -> Dictionary:
	if not can_dig(world_pos):
		return {"success": false, "reason": "outside_envelope"}
	var destroyed := dig_in_direction(world_pos, direction)
	return {"success": destroyed, "reason": "" if destroyed else "nothing_there"}


## intact / depleted / none, per the spec's contract surface. No dedicated
## Deposit concept exists yet (Build Bible Spec 12, Deposits + Extraction,
## owns that) — until then this treats "has a tile" as intact and "within
## the envelope but already dug" as depleted, matching canon's general
## depletion-overlay principle (§6) without presuming Spec 12's real
## deposit-vs-ordinary-rock distinction.
func get_deposit_state(world_pos: Vector2) -> StringName:
	var cell := world_to_cell(world_pos)
	if not is_within_dig_envelope(cell):
		return &"none"
	return &"intact" if has_tile(cell) else &"depleted"


func is_firmament_cell(cell: Vector2i) -> bool:
	return cell.y <= FIRMAMENT_Y_MAX


func is_mouth_cell(cell: Vector2i) -> bool:
	return cell.y >= MOUTH_Y_MIN


## Remove a tile if present. Returns true when something was destroyed.
## Grants Materials (+ transitional Salvage) through Resources; yield from Upgrades.
## Materials feed District production when turned in at the Hollow.
func destroy_cell(cell: Vector2i, direction: Vector2i = Vector2i.ZERO) -> bool:
	if not has_tile(cell):
		return false
	erase_cell(cell)
	var is_firmament := is_firmament_cell(cell)
	var is_mouth := is_mouth_cell(cell)
	var yield_amt := _salvage_yield_for_dig(cell)
	var wallet := _resource_wallet()
	if wallet:
		if wallet.has_method("grant_dig_haul"):
			wallet.grant_dig_haul(yield_amt)
		else:
			wallet.add(wallet.SALVAGE, yield_amt)
	_apply_frontier_rules(cell, direction)
	var world := to_global(map_to_local(cell))
	FeelFx.spawn_dig_dust(self, world, direction, is_firmament, is_mouth)
	FeelFx.spawn_salvage_float(self, world, yield_amt, is_firmament, is_mouth)
	var found := _try_record_drop(cell, direction)
	if found != StringName():
		FeelFx.spawn_record_float(self, world, "Record")
	dig_completed.emit(cell, direction, found)
	# Build Bible Spec 06's own confirmed design choice: digging is push,
	# not pull. This EventBus event is ADDITIONAL to the direct
	# Resources/Upgrades/Community/Journal calls above, not a replacement
	# for them - those are pre-canon prototype stand-ins with their own
	# future Build Bible specs (Materials #11, Rig/Gear #14, Trust #19,
	# Capability Web #25), and rewiring their call sites to be pure
	# EventBus listeners is each of THEIR migrations to do, not a side
	# effect of implementing Terrain's own spec. This event exists for
	# systems that don't have a direct call site at all yet - Perception
	# (#17), Material extraction (#12), the Fact Log.
	if is_inside_tree():
		var bus := get_tree().root.get_node_or_null("EventBus")
		if bus != null:
			bus.terrain_dug.emit(cell, direction, is_firmament, is_mouth)
	return true


func _salvage_yield_for_dig(cell: Vector2i) -> int:
	var base := _base_salvage_yield()
	# Devil’s Mouth digs sometimes shake loose a bit more — public danger payoff.
	if is_mouth_cell(cell) and randf() < 0.2:
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
	var dug_down := direction.y > 0 or is_mouth_cell(cell)

	if dug_up and direction.y < 0:
		var upgrades := get_tree().root.get_node_or_null("Upgrades") if is_inside_tree() else null
		var quiet := 0
		if upgrades and upgrades.has_method("get_quiet_dig_level"):
			quiet = int(upgrades.get_quiet_dig_level())
		var community := get_tree().root.get_node_or_null("Community") if is_inside_tree() else null
		if community and community.has_method("roll_upward_dig_risk"):
			community.roll_upward_dig_risk(quiet)

	if dug_down and is_mouth_cell(cell):
		_pit_digs_since_warn += 1
		if _pit_digs_since_warn >= 4:
			_pit_digs_since_warn = 0
			frontier_notice.emit("The Devil’s Mouth walls groan. Going further feels wrong — but not forbidden.")


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
## Same path for every direction — Firmament vs Devil’s Mouth fiction layers wrap outcomes.
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


## Build Bible Spec 02 uniform SaveLoad contract, via register_scene_domain()
## (see _ready() above) rather than autoload discovery.
##
## Persists as the set of currently-dug cells within the envelope — the
## SIMPLEST of the representations 00-dependency-map.md's technical spike
## is meant to choose between ("per-tile deltas... or full chunk snapshots,
## or something else"). This is a working placeholder that round-trips
## correctly, not a claim that the spike question is settled; Spec 06's own
## text is explicit that the representation itself isn't this spec's call.
## Scans rather than tracking a parallel dug-cells set, since the
## TileMapLayer itself is already the authoritative state (Spec 01: no
## shadow copies of something already readable from its owner) — the
## envelope is only 4096 cells, cheap to scan.
func save_state() -> Dictionary:
	var dug: Array = []
	for x in range(DIG_START_X, DIG_END_X):
		for y in range(64):
			var cell := Vector2i(x, y)
			if not has_tile(cell):
				dug.append([cell.x, cell.y])
	return {"dug_cells": dug}


func load_state(data: Dictionary) -> void:
	_fill_ground()  # reset envelope to fully intact, then reapply the delta
	var dug: Variant = data.get("dug_cells", [])
	if typeof(dug) != TYPE_ARRAY:
		return
	for entry: Variant in dug:
		if typeof(entry) == TYPE_ARRAY and entry.size() == 2:
			erase_cell(Vector2i(int(entry[0]), int(entry[1])))


func reset_all() -> void:
	_fill_ground()
