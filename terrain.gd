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

## Total envelope depth in rows (Firmament + mid band + Devil's Mouth
## combined). Locked 2026-09-17 via the macro-layout scale pass — dig
## deliberately reaches deeper than Hollow's own 74-tile height (1.25x),
## per the interactive scale editor in CONTEXT.md. The single source of
## truth for envelope depth — reference this, not a literal, anywhere
## that needs the total (dig_site_dressing.gd's mouth overlay height was
## a hardcoded "16" that silently went stale across two earlier scale
## passes before this constant existed; don't repeat that).
## World-scale pass (2026-09-19): row counts x5 — TILE_SIZE stays 16, so this
## is 5x more rows covering 5x the world-px depth, same proportional split.
const ENVELOPE_ROWS := 480
## Cells with y <= this are Firmament rock (secret upward frontier).
## 141 rows (0..140), same ~31% share of ENVELOPE_ROWS as the original split.
const FIRMAMENT_Y_MAX := 140
## Cells with y >= this are Devil’s Mouth walls (public-ish downward frontier).
## Mid band is FIRMAMENT_Y_MAX+1 .. MOUTH_Y_MIN-1 (119 rows); Mouth is
## MOUTH_Y_MIN .. ENVELOPE_ROWS-1 — same proportional split as before.
const MOUTH_Y_MIN := 260

## Build Bible Spec 12 (Deposits + Extraction). Deposits are authored data
## (content/deposits/*.tres, filtered to this envelope's id) placed inside
## the envelope; most rock yields nothing (canon §5). A deposit is hidden
## under its rock until digging exposes it, then a DepositNode
## (deposit_node.gd, a Spec 10 Interactable) offers the hold-to-extract;
## completing that depletes it for good. Depletion is drawn exactly as
## canon §6 locks it: base terrain + an intact overlay -> a depleted
## overlay, on a placeholder overlay layer here.
const ENVELOPE_ID := &"east"
const DEPOSITS_DIR := "res://content/deposits/"
const DEPOSIT_INTACT_ATLAS := Vector2i(0, 0)
const DEPOSIT_DEPLETED_ATLAS := Vector2i(1, 0)
const DEPOSIT_INTERACT_RADIUS := 24.0
const DepositNodeScript := preload("res://deposit_node.gd")

var _atlas_coords: Array[Vector2i] = []
var _pit_digs_since_warn := 0

## cell -> {"material_id": StringName, "amount": int, "exposed": bool, "depleted": bool}
var _deposits: Dictionary = {}
var _deposit_nodes: Dictionary = {}  # cell -> DepositNode (only while exposed & intact)
var _deposit_overlay: TileMapLayer


func _ready() -> void:
	add_to_group("terrain")
	texture_filter = TEXTURE_FILTER_NEAREST
	tile_set = _build_tileset()
	_build_deposit_overlay()
	_fill_ground()
	_carve_hollow_civic_overlaps()
	# Build Bible Spec 02's save contract only auto-discovers autoloads by
	# root-relative name; Terrain has to live inside the play scene's
	# hierarchy to render/collide correctly, so it registers itself with
	# SaveLoad instead (see save_load.gd's register_scene_domain()).
	var save_load := get_tree().root.get_node_or_null("SaveLoad") if is_inside_tree() else null
	if save_load != null and save_load.has_method("register_scene_domain"):
		save_load.register_scene_domain("Terrain", self)
	var console := get_tree().root.get_node_or_null("DebugConsole") if is_inside_tree() else null
	if console != null:
		console.register_command("deposits", "deposits — list every authored deposit and its state.", _debug_list_deposits)
		console.register_command("extract_all", "extract_all — complete extraction on every exposed deposit.", _debug_extract_all)


func _exit_tree() -> void:
	var save_load := get_tree().root.get_node_or_null("SaveLoad")
	if save_load != null and save_load.has_method("unregister_scene_domain"):
		save_load.unregister_scene_domain("Terrain")
	var console := get_tree().root.get_node_or_null("DebugConsole")
	if console != null:
		console.unregister_command("deposits")
		console.unregister_command("extract_all")


## Dig Front rock — warm grey-brown, never teal/aqua filler.
## The old Color(0.25, 0.4, 0.42) read as a solid aqua wall in civic/Mouth views.
const DIG_ROCK_COLOR := Color(0.36, 0.30, 0.26)


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
	image.fill(DIG_ROCK_COLOR)
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
## Dig lives OUTSIDE the Hollow civic void / Devil's Mouth — east Dig Front and
## High-West Dig Front flanks, never aqua fill inside the Mouth.
## Re-derived for TILE_SIZE=16 against HollowLayout.EXIT_RIGHT / Dig Front tip.
## World-scale pass (2026-09-19): x5 against the rescaled HollowLayout values.
const DIG_START_X := 400 ## world 6400 — after Hollow exit ledge (EXIT_RIGHT)
const DIG_END_X := 800 ## exclusive; covers Mid-East Dig Front out to ~x=11840
## High-West Dig Front (destructible outside Mouth) — world x -5680..-2880.
const WEST_DIG_START_X := -355 ## world -5680
const WEST_DIG_END_X := -180 ## exclusive; world -2880


func _fill_ground() -> void:
	# Dig site past Hollow terraces + exit ledge (see HollowLayout.EXIT_RIGHT).
	# Firmament rock (secret) above the walk ledge; Devil’s Mouth walls deeper below.
	_seed_deposits()
	_clear_evidence()
	if _atlas_coords.is_empty():
		return
	for x in range(DIG_START_X, DIG_END_X):
		# Firmament / ceiling rock — upward secret frontier.
		for y in range(0, FIRMAMENT_Y_MAX + 1):
			_place_random(Vector2i(x, y))
		# Mid band + Devil’s Mouth walls — downward public-ish danger.
		for y in range(FIRMAMENT_Y_MAX + 1, ENVELOPE_ROWS):
			_place_random(Vector2i(x, y))
	_fill_west_dig_front()


## High-West Dig Front — brown dig mass west of the Hollow civic void.
## Extends through Bottom-West Dig Front elevation so both dig fronts open
## into destructible rock; never enters Devil's Mouth.
func _fill_west_dig_front() -> void:
	if _atlas_coords.is_empty():
		return
	var y_max := int(HollowLayout.BOTTOM_WEST_LOWER_Y / float(TILE_SIZE)) + 8
	y_max = mini(y_max, ENVELOPE_ROWS)
	for x in range(WEST_DIG_START_X, WEST_DIG_END_X):
		for y in range(0, FIRMAMENT_Y_MAX + 1):
			_place_random(Vector2i(x, y))
		for y in range(FIRMAMENT_Y_MAX + 1, y_max):
			_place_random(Vector2i(x, y))
	_carve_west_dig_front_overlaps()


## Clear walk air above High-West / Bottom-West dig-front decks so HollowTerrain
## owns the corridor; keep a thin diggable face above each walk clear.
func _carve_west_dig_front_overlaps() -> void:
	var dig_x0_px := float(WEST_DIG_START_X) * float(TILE_SIZE)
	var dig_x1_px := float(WEST_DIG_END_X) * float(TILE_SIZE)
	var walk_clear_px := 96.0
	var dig_face_px := float(TILE_SIZE) * 2.0
	for rect in HollowLayout.west_stack_deck_rects():
		var x0_px: float = maxf(rect.x, dig_x0_px)
		var x1_px: float = minf(rect.y, dig_x1_px)
		if x1_px <= x0_px:
			continue
		_clear_dig_rect(x0_px, x1_px, rect.z - walk_clear_px, rect.z)
		var face_y1 := rect.z - walk_clear_px
		var face_y0 := face_y1 - dig_face_px
		_restore_dig_rect(x0_px, x1_px, face_y0, face_y1)
	# West ladder shaft through dig-front elevations (High-West / Bottom-West).
	_clear_dig_rect(
		HollowLayout.LADDER_WEST_OPEN_X,
		HollowLayout.ladder_west_open_end(),
		HollowLayout.WEST_ASHRAM_UPPER_Y - walk_clear_px,
		HollowLayout.BOTTOM_WEST_LOWER_Y
	)


## Hollow Mid-East / Ashram / Glowbeds / Cistern decks and LadderEastStack sit
## inside the dig envelope (world x >= DIG_START_X * TILE). Solid-filling that
## envelope buried those floors under teal dig rock and sealed the walk into the
## east passenger shaft. Carve walk air + shaft openings so HollowTerrain owns
## the civic approach.
##
## Civic band (DIG_START → civic_east_end): also clear inter-deck air so teal
## dig rock does not read as aqua filler blocks between terraces. Dig Front
## (past civic tip) keeps excavation mass; only corridor + shaft air is carved.
func _carve_hollow_civic_overlaps() -> void:
	var dig_x0_px := float(DIG_START_X) * float(TILE_SIZE)
	var dig_x1_px := float(DIG_END_X) * float(TILE_SIZE)
	var civic_end_px := HollowLayout.civic_east_end()
	## Standing clearance above a deck top (player body + jump headroom).
	var walk_clear_px := 96.0
	## Thin diggable face kept above each civic corridor (not a void-filling slab).
	var dig_face_px := float(TILE_SIZE) * 2.0
	for rect in HollowLayout.expansion_deck_rects():
		var x0_px: float = maxf(rect.x, dig_x0_px)
		var x1_px: float = minf(rect.y, dig_x1_px)
		if x1_px <= x0_px:
			continue
		_clear_dig_rect(x0_px, x1_px, rect.z - walk_clear_px, rect.z)
	# Civic east wall: open the whole inhabited air column. Teal dig fill between
	# Ashram / Glowbeds / Hang / Mid-East / Lower / Cistern read as aqua blocks
	# east of LadderEastStack — clear them, then restore a thin diggable face
	# above each corridor so Dig Front gameplay still has rock to chip.
	var civic_x1 := minf(civic_end_px, dig_x1_px)
	if civic_x1 > dig_x0_px:
		_clear_dig_rect(
			dig_x0_px,
			civic_x1,
			HollowLayout.UPPER_RES_Y - walk_clear_px,
			HollowLayout.CISTERN_Y
		)
		for rect in HollowLayout.expansion_deck_rects():
			var x0_px: float = maxf(rect.x, dig_x0_px)
			var x1_px: float = minf(rect.y, civic_x1)
			if x1_px <= x0_px:
				continue
			# Face sits just above walk clear: [deck - walk_clear - face, deck - walk_clear).
			var face_y1 := rect.z - walk_clear_px
			var face_y0 := face_y1 - dig_face_px
			_restore_dig_rect(x0_px, x1_px, face_y0, face_y1)
	# Full vertical east passenger shaft (Ashram → Cistern), including floor rows.
	_clear_dig_rect(
		HollowLayout.LADDER_EAST_OPEN_X,
		HollowLayout.ladder_east_open_end(),
		HollowLayout.UPPER_RES_Y - walk_clear_px,
		HollowLayout.CISTERN_Y
	)
	# Freight cage sits west of dig-start today; clear defensively if it drifts east.
	var freight_x0 := HollowLayout.FREIGHT_LIFT_X
	var freight_x1 := freight_x0 + HollowLayout.LIFT_WIDTH
	if freight_x1 > dig_x0_px and freight_x0 < dig_x1_px:
		_clear_dig_rect(
			maxf(freight_x0, dig_x0_px),
			minf(freight_x1, dig_x1_px),
			HollowLayout.HEART_Y - walk_clear_px,
			HollowLayout.CISTERN_Y
		)
	# Dig Front: empty the sky-wall above the walk so Mid Heart / Mouth views
	# don't show a solid mass. Keep a thin diggable face + rock below for digs.
	var dig_front := HollowLayout.MID_EAST_DIG_FRONT
	var df_x0 := maxf(dig_front.x, dig_x0_px)
	var df_x1 := minf(dig_front.y, dig_x1_px)
	if df_x1 > df_x0:
		_clear_dig_rect(
			df_x0,
			df_x1,
			HollowLayout.UPPER_RES_Y - walk_clear_px,
			dig_front.z
		)
		var df_face_y1 := dig_front.z - walk_clear_px
		var df_face_y0 := df_face_y1 - dig_face_px
		_restore_dig_rect(df_x0, df_x1, df_face_y0, df_face_y1)
		# Firmament diggable band (upward frontier) — rock only where digs belong.
		_restore_dig_rect(
			df_x0,
			df_x1,
			0.0,
			float(FIRMAMENT_Y_MAX + 1) * float(TILE_SIZE)
		)


func _clear_dig_rect(x0_px: float, x1_px: float, y0_px: float, y1_px: float) -> void:
	## Clears [x0,x1) × [y0,y1] in world pixels. y1 is an inclusive deck-top
	## surface (matches HollowLayout floor convention / paint_floor's round).
	var cells := _dig_rect_cells(x0_px, x1_px, y0_px, y1_px)
	for cell in cells:
		erase_cell(cell)
		if _deposit_overlay != null:
			_deposit_overlay.erase_cell(cell)
		if _deposits.has(cell):
			_deposits.erase(cell)
		if _deposit_nodes.has(cell):
			var node: Node = _deposit_nodes[cell]
			_deposit_nodes.erase(cell)
			if node != null and is_instance_valid(node):
				node.queue_free()


func _restore_dig_rect(x0_px: float, x1_px: float, y0_px: float, y1_px: float) -> void:
	## Re-places dig rock in [x0,x1) × [y0,y1) after a civic air carve — thin
	## diggable faces only, never Mouth/inter-deck void fillers.
	if _atlas_coords.is_empty():
		return
	var cells := _dig_rect_cells(x0_px, x1_px, y0_px, y1_px, false)
	for cell in cells:
		if not is_within_dig_envelope(cell):
			continue
		_place_random(cell)


func _dig_rect_cells(
	x0_px: float,
	x1_px: float,
	y0_px: float,
	y1_px: float,
	y1_inclusive_deck := true
) -> Array[Vector2i]:
	var x0 := clampi(int(floor(x0_px / float(TILE_SIZE))), DIG_START_X, DIG_END_X - 1)
	var x1 := clampi(int(ceil(x1_px / float(TILE_SIZE))), DIG_START_X, DIG_END_X)
	var y0 := clampi(int(floor(y0_px / float(TILE_SIZE))), 0, ENVELOPE_ROWS - 1)
	var y1: int
	if y1_inclusive_deck:
		y1 = clampi(int(round(y1_px / float(TILE_SIZE))) + 1, 0, ENVELOPE_ROWS)
	else:
		y1 = clampi(int(ceil(y1_px / float(TILE_SIZE))), 0, ENVELOPE_ROWS)
	var cells: Array[Vector2i] = []
	if x1 <= x0 or y1 <= y0:
		return cells
	for x in range(x0, x1):
		for y in range(y0, y1):
			cells.append(Vector2i(x, y))
	return cells


func _place_random(cell: Vector2i) -> void:
	var atlas_coords: Vector2i = _atlas_coords[randi() % _atlas_coords.size()]
	set_cell(cell, 0, atlas_coords)


## True if this map cell currently has a diggable tile.
func has_tile(cell: Vector2i) -> bool:
	return get_cell_source_id(cell) != -1


## Build Bible Spec 06 contract surface — see docs/build-bible/specs/06-
## destructible-terrain.md. The envelope is currently the same rectangle
## _fill_ground() authors (DIG_START_X..DIG_END_X, y 0..ENVELOPE_ROWS-1) —
## opt-in destructibility per §63/the atlas's "fixed outer envelope of
## destructible chunks" language: nothing outside it is diggable, full
## stop, regardless of whether a real Zone (Spec 05, not authored yet)
## eventually replaces this rectangle with real chunk-authored bounds.
func is_within_dig_envelope(cell: Vector2i) -> bool:
	if cell.y < 0 or cell.y >= ENVELOPE_ROWS:
		return false
	if cell.x >= DIG_START_X and cell.x < DIG_END_X:
		return true
	# West dig flank — Firmament through Bottom-West Dig Front (not Mouth).
	var west_y_max := int(HollowLayout.BOTTOM_WEST_LOWER_Y / float(TILE_SIZE)) + 8
	if cell.x >= WEST_DIG_START_X and cell.x < WEST_DIG_END_X and cell.y < west_y_max:
		return true
	return false


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


## intact / depleted / none, per Spec 06's contract surface, now backed by
## real deposits (Build Bible Spec 12): "none" for ordinary rock or any
## cell outside the envelope, "intact" for an authored deposit that hasn't
## been extracted (whether or not digging has exposed it yet — see
## is_deposit_exposed()), "depleted" once extracted. Finite: a depleted
## deposit never returns to intact.
func get_deposit_state(world_pos: Vector2) -> StringName:
	var cell := world_to_cell(world_pos)
	if not _deposits.has(cell):
		return &"none"
	return &"depleted" if bool(_deposits[cell]["depleted"]) else &"intact"


# --- Build Bible Spec 18: physical evidence on the dug-cell delta ------------
## Evidence is a flag on THIS layer's own delta (Spec 18, option A) — no
## second registry. cell -> {"sealed_tier": StringName} where &"" = exposed.
const SealNodeScript := preload("res://seal_node.gd")
const EVIDENCE_SOURCE_ID := "restricted_dig"
var _evidence: Dictionary = {}
var _evidence_nodes: Dictionary = {}  # cell -> SealNode (only while exposed)


## Is digging this cell restricted excavation? Reads the authored zone's
## `restricted` flag (Spec 18: "Terrain reads the zone's authored
## sanctioned/restricted flag") and falls back to the Firmament band when
## no authored footprint covers the cell — the band canon forbids digging
## either way, so the answer never silently flips to "sanctioned" just
## because a zone isn't authored yet.
func is_restricted_dig_cell(cell: Vector2i) -> bool:
	var world := to_global(map_to_local(cell))
	var zones := get_tree().root.get_node_or_null("Zones") if is_inside_tree() else null
	if zones != null and zones.has_method("get_zone_at") and str(zones.get_zone_at(world)) != "":
		return bool(zones.is_restricted_at(world))
	return is_firmament_cell(cell)


func _leave_evidence(cell: Vector2i) -> void:
	if _evidence.has(cell):
		return
	_evidence[cell] = {"sealed_tier": &""}
	_spawn_seal_node(cell)
	_emit_evidence_changed(cell, &"", true)


func has_evidence(cell: Vector2i) -> bool:
	return _evidence.has(cell)


func get_evidence_cells() -> Array[Vector2i]:
	var out: Array[Vector2i] = []
	for key: Variant in _evidence.keys():
		out.append(key)
	return out


## {} if the cell holds no evidence, else {"cell", "position",
## "sealed_tier", "zone_id"} — a copy, never the record.
func get_evidence_info(cell: Vector2i) -> Dictionary:
	if not _evidence.has(cell):
		return {}
	var world := to_global(map_to_local(cell))
	var zone_id := ""
	var zones := get_tree().root.get_node_or_null("Zones") if is_inside_tree() else null
	if zones != null and zones.has_method("get_zone_at"):
		zone_id = str(zones.get_zone_at(world))
	return {
		"cell": cell,
		"position": world,
		"sealed_tier": StringName(str(_evidence[cell]["sealed_tier"])),
		"zone_id": zone_id,
	}


func get_evidence_records() -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	for key: Variant in _evidence.keys():
		out.append(get_evidence_info(key))
	return out


func get_evidence_node(cell: Vector2i) -> Node:
	var node: Variant = _evidence_nodes.get(cell, null)
	if node == null or not is_instance_valid(node):
		return null
	return node


## Called when a seal hold completes (seal_node.gd) or by Evidence.seal().
## Consumes ONE instance of the kit Component (Spec 11), records the tier
## it achieves (kit tier + Secrecy Gear, via Evidence.achievable_tier) and
## frees the exposed-evidence interactable. Refuses cleanly — nothing
## consumed — if there's no evidence here, it's already sealed, the kit
## isn't a seal kit, or none is owned. {"success", "reason", "tier"}.
func complete_seal(cell: Vector2i, kit_id: StringName) -> Dictionary:
	if not _evidence.has(cell):
		return {"success": false, "reason": "no_evidence_here", "tier": &""}
	if StringName(str(_evidence[cell]["sealed_tier"])) != &"":
		return {"success": false, "reason": "already_sealed", "tier": &""}
	var evidence := get_tree().root.get_node_or_null("Evidence") if is_inside_tree() else null
	var storage := get_tree().root.get_node_or_null("Storage") if is_inside_tree() else null
	if evidence == null or storage == null:
		return {"success": false, "reason": "no_evidence_system", "tier": &""}
	if not bool(evidence.is_seal_kit(kit_id)):
		return {"success": false, "reason": "not_a_seal_kit", "tier": &""}
	var owned: Array[Dictionary] = storage.get_components(kit_id)
	if owned.is_empty():
		return {"success": false, "reason": "no_kit", "tier": &""}
	var tier: StringName = evidence.achievable_tier(kit_id)
	if not bool(storage.remove_component(int(owned[0]["uid"]))):
		return {"success": false, "reason": "no_kit", "tier": &""}
	_evidence[cell]["sealed_tier"] = tier
	_free_seal_node(cell)
	_emit_evidence_changed(cell, tier, true)
	return {"success": true, "reason": "", "tier": tier}


func _spawn_seal_node(cell: Vector2i) -> void:
	_free_seal_node(cell)
	var node: Area2D = SealNodeScript.new()
	node.setup(self, cell)
	add_child(node)
	node.position = map_to_local(cell)
	_evidence_nodes[cell] = node


func _free_seal_node(cell: Vector2i) -> void:
	var node: Variant = _evidence_nodes.get(cell, null)
	_evidence_nodes.erase(cell)
	if node != null and is_instance_valid(node):
		(node as Node).queue_free()


func _clear_evidence() -> void:
	for key: Variant in _evidence_nodes.keys():
		var node: Variant = _evidence_nodes[key]
		if node != null and is_instance_valid(node):
			(node as Node).queue_free()
	_evidence_nodes.clear()
	_evidence.clear()


func _emit_evidence_changed(cell: Vector2i, tier: StringName, exists: bool) -> void:
	if not is_inside_tree():
		return
	var bus := get_tree().root.get_node_or_null("EventBus")
	if bus != null:
		bus.evidence_changed.emit(cell, tier, exists)


func is_firmament_cell(cell: Vector2i) -> bool:
	return cell.y <= FIRMAMENT_Y_MAX


func is_mouth_cell(cell: Vector2i) -> bool:
	return cell.y >= MOUTH_Y_MIN


## Remove a tile if present. Returns true when something was destroyed.
## Rock removal exposes deposits; deposits, not ordinary digs, grant Materials.
func destroy_cell(cell: Vector2i, direction: Vector2i = Vector2i.ZERO) -> bool:
	if not has_tile(cell):
		return false
	erase_cell(cell)
	# Digging the rock a deposit sits in EXPOSES it (Spec 12: discover ->
	# expose); it does not hand the Material over — that's extraction.
	if _deposits.has(cell) and not bool(_deposits[cell]["exposed"]):
		_expose_deposit_cell(cell, true)
	var is_firmament := is_firmament_cell(cell)
	var is_mouth := is_mouth_cell(cell)
	var yield_amt := _salvage_yield_for_dig(cell)
	_apply_frontier_rules(cell, direction)
	var world := to_global(map_to_local(cell))
	FeelFx.spawn_dig_dust(self, world, direction, is_firmament, is_mouth)
	FeelFx.spawn_salvage_float(self, world, yield_amt, is_firmament, is_mouth)
	var found := _try_record_drop(cell, direction)
	if found != StringName():
		FeelFx.spawn_record_float(self, world, "Record")
	dig_completed.emit(cell, direction, found)
	# Build Bible Spec 06's own confirmed design choice: digging is push,
	# not pull. Systems that care about digging observe this event without
	# inheriting a retired wallet or social-penalty path.
	# Build Bible Specs 17/18: whether a dig is restricted is THIS system's
	# decision (the zone's authored flag, Firmament band as fallback), not
	# Perception's or Evidence's. A restricted dig does two things at once
	# — the spec is explicit they aren't mutually exclusive: it leaves
	# persistent evidence on this delta (Spec 18) AND is witnessable right
	# now (Spec 17). Ordinary civic digging does neither.
	var restricted := is_restricted_dig_cell(cell)
	if restricted:
		_leave_evidence(cell)
	if is_inside_tree():
		var bus := get_tree().root.get_node_or_null("EventBus")
		if bus != null:
			bus.terrain_dug.emit(cell, direction, is_firmament, is_mouth)
		# One source id for the sustained activity, so continuous restricted
		# mining seen by the same NPC is one fact per cooldown window, not
		# one per cell.
		if restricted:
			var perception := get_tree().root.get_node_or_null("Perception")
			if perception != null and perception.has_method("flag_witnessable"):
				perception.flag_witnessable(
					EVIDENCE_SOURCE_ID, world, perception.FACT_EXCAVATED_RESTRICTED_WALL,
					{"cell": [cell.x, cell.y], "direction": [direction.x, direction.y]}
				)
	return true


# --- Build Bible Spec 12: deposits + extraction ------------------------------

## Spec 12 API: expose the deposit at a world position (normally digging
## does this via destroy_cell; this is the explicit form for content/debug).
## The rock over it is removed if still present — an exposed deposit is an
## open pocket. False if there's no deposit there or it's already exposed.
func expose_deposit(world_pos: Vector2) -> bool:
	var cell := world_to_cell(world_pos)
	if not _deposits.has(cell) or bool(_deposits[cell]["exposed"]):
		return false
	if has_tile(cell):
		erase_cell(cell)
	_expose_deposit_cell(cell, true)
	return true


func is_deposit_exposed(cell: Vector2i) -> bool:
	return _deposits.has(cell) and bool(_deposits[cell]["exposed"])


func get_deposit_cells() -> Array[Vector2i]:
	var out: Array[Vector2i] = []
	for key: Variant in _deposits.keys():
		out.append(key)
	return out


## Copy of a deposit's record ({material_id, amount, exposed, depleted}),
## or {} if none there.
func get_deposit_info(cell: Vector2i) -> Dictionary:
	if not _deposits.has(cell):
		return {}
	return (_deposits[cell] as Dictionary).duplicate()


## The live DepositNode for an exposed, intact deposit, or null.
func get_deposit_node(cell: Vector2i) -> Node:
	var node: Variant = _deposit_nodes.get(cell, null)
	if node == null or not is_instance_valid(node):
		return null
	return node


## Called by a DepositNode when its hold-to-extract completes. Depletes the
## deposit (finite, never regenerates), flips the overlay, frees the
## interactable, and hands the Material to the player. Returns the amount
## granted, or 0 if there was nothing extractable here (never exposed, or
## already depleted — a second completion can't double-grant).
func complete_extraction(cell: Vector2i) -> int:
	if not _deposits.has(cell):
		return 0
	var record: Dictionary = _deposits[cell]
	if not bool(record["exposed"]) or bool(record["depleted"]):
		return 0
	var material_id: StringName = record["material_id"]
	var amount: int = int(record["amount"])
	# You can't take what you can't carry (Spec 13): if the bundle can't
	# hold this load — wrong type towed, or no room — the deposit stays
	# intact for a later trip rather than depleting into nothing.
	var hauling := get_tree().root.get_node_or_null("Hauling") if is_inside_tree() else null
	if hauling != null and hauling.has_method("can_attach") and not bool(hauling.can_attach(material_id, amount)):
		return 0
	record["depleted"] = true
	_set_deposit_overlay(cell, DEPOSIT_DEPLETED_ATLAS)
	_free_deposit_node(cell)
	_grant_extracted(material_id, amount)
	var world := to_global(map_to_local(cell))
	var display := str(material_id)
	var storage := get_tree().root.get_node_or_null("Storage") if is_inside_tree() else null
	if storage != null:
		display = str(storage.get_material_display_name(material_id))
	FeelFx.spawn_material_float(self, world, display, amount)
	if is_inside_tree():
		var bus := get_tree().root.get_node_or_null("EventBus")
		if bus != null:
			bus.material_extracted.emit(material_id, amount, cell)
	return amount


## The one seam between extraction and "the player has it". Spec 12's
## confirmed API says completion calls Materials.add; canon puts a physical
## haul (Spec 13, built after this) between the two. So: Hauling takes the
## load if it exists, otherwise the Material goes straight into Storage
## (Spec 11) — the same fail-safe hook shape Spec 07 uses for Hauling.
## Spec 13 takes this seam over without touching anything else here.
func _grant_extracted(material_id: StringName, amount: int) -> void:
	if not is_inside_tree():
		return
	var hauling := get_tree().root.get_node_or_null("Hauling")
	if hauling != null and hauling.has_method("attach"):
		hauling.attach(material_id, amount)
		return
	var storage := get_tree().root.get_node_or_null("Storage")
	if storage != null and storage.has_method("deposit_material"):
		storage.deposit_material(material_id, amount)


## `emit_event` is false when a save is restoring an already-exposed deposit
## — that's restoration, not a new discovery.
func _expose_deposit_cell(cell: Vector2i, emit_event: bool) -> void:
	var record: Dictionary = _deposits[cell]
	record["exposed"] = true
	if bool(record["depleted"]):
		_set_deposit_overlay(cell, DEPOSIT_DEPLETED_ATLAS)
		return
	_set_deposit_overlay(cell, DEPOSIT_INTACT_ATLAS)
	_spawn_deposit_node(cell)
	if emit_event and is_inside_tree():
		var bus := get_tree().root.get_node_or_null("EventBus")
		if bus != null:
			bus.deposit_exposed.emit(cell, record["material_id"])


func _spawn_deposit_node(cell: Vector2i) -> void:
	_free_deposit_node(cell)
	var record: Dictionary = _deposits[cell]
	var node: Area2D = DepositNodeScript.new()
	node.setup(self, cell, record["material_id"], int(record["amount"]), DEPOSIT_INTERACT_RADIUS)
	node.position = map_to_local(cell)
	add_child(node)
	_deposit_nodes[cell] = node


func _free_deposit_node(cell: Vector2i) -> void:
	var node: Variant = _deposit_nodes.get(cell, null)
	_deposit_nodes.erase(cell)
	if node != null and is_instance_valid(node):
		(node as Node).queue_free()


func _set_deposit_overlay(cell: Vector2i, atlas: Vector2i) -> void:
	if _deposit_overlay != null:
		_deposit_overlay.set_cell(cell, 0, atlas)


## Reloads the authored pockets for this envelope, resetting every deposit
## to hidden/intact and clearing overlay + interactables. Called from
## _fill_ground(), so reset_all()/load_state() start from a clean seed.
func _seed_deposits() -> void:
	for key: Variant in _deposit_nodes.keys():
		var node: Variant = _deposit_nodes[key]
		if node != null and is_instance_valid(node):
			(node as Node).queue_free()
	_deposit_nodes.clear()
	_deposits.clear()
	if _deposit_overlay != null:
		_deposit_overlay.clear()
	var dir := DirAccess.open(DEPOSITS_DIR)
	if dir == null:
		return
	dir.list_dir_begin()
	var file_name := dir.get_next()
	while file_name != "":
		if not dir.current_is_dir() and file_name.ends_with(".tres"):
			var path := DEPOSITS_DIR + file_name
			var res: Resource = ResourceLoader.load(path, "", ResourceLoader.CACHE_MODE_REPLACE)
			if res == null:
				push_warning("Terrain: failed to load deposit pockets %s — skipped" % path)
			elif StringName(str(res.get("envelope_id"))) == ENVELOPE_ID:
				var pockets: Array = res.get("pockets")
				for pocket: Dictionary in pockets:
					_place_authored_pocket(pocket, path)
		file_name = dir.get_next()
	dir.list_dir_end()


func _place_authored_pocket(pocket: Dictionary, source_path: String) -> void:
	var cell_value: Variant = pocket.get("cell", null)
	if typeof(cell_value) != TYPE_VECTOR2I:
		push_warning("Terrain: pocket in %s has no Vector2i cell — skipped" % source_path)
		return
	var cell: Vector2i = cell_value
	if not is_within_dig_envelope(cell):
		push_warning("Terrain: pocket at %s in %s is outside the dig envelope — skipped" % [cell, source_path])
		return
	var material_id := StringName(str(pocket.get("material_id", "")))
	var amount := int(pocket.get("amount", 0))
	if material_id == &"" or amount <= 0:
		push_warning("Terrain: pocket at %s in %s needs a material_id and a positive amount — skipped" % [cell, source_path])
		return
	_deposits[cell] = {
		"material_id": material_id,
		"amount": amount,
		"exposed": false,
		"depleted": false,
	}


## Placeholder overlay: two flat tiles on their own layer above the rock
## (canon §6: base terrain + intact overlay -> depleted overlay). Real
## overlay art lands with the same two atlas slots.
func _build_deposit_overlay() -> void:
	if _deposit_overlay != null:
		return
	var image := Image.create(TILE_SIZE * 2, TILE_SIZE, false, Image.FORMAT_RGBA8)
	image.fill_rect(Rect2i(0, 0, TILE_SIZE, TILE_SIZE), Color(0.86, 0.68, 0.3, 0.95))  # intact: warm ore
	image.fill_rect(Rect2i(TILE_SIZE, 0, TILE_SIZE, TILE_SIZE), Color(0.3, 0.27, 0.24, 0.85))  # depleted: dull
	var texture := ImageTexture.create_from_image(image)
	var tileset := TileSet.new()
	tileset.tile_size = Vector2i(TILE_SIZE, TILE_SIZE)
	var atlas := TileSetAtlasSource.new()
	atlas.texture = texture
	atlas.texture_region_size = Vector2i(TILE_SIZE, TILE_SIZE)
	atlas.create_tile(DEPOSIT_INTACT_ATLAS)
	atlas.create_tile(DEPOSIT_DEPLETED_ATLAS)
	tileset.add_source(atlas)
	_deposit_overlay = TileMapLayer.new()
	_deposit_overlay.name = "DepositOverlay"
	_deposit_overlay.texture_filter = TEXTURE_FILTER_NEAREST
	_deposit_overlay.tile_set = tileset
	_deposit_overlay.z_index = 1
	add_child(_deposit_overlay)


func get_deposit_overlay() -> TileMapLayer:
	return _deposit_overlay


func _debug_list_deposits(_args: Array[String]) -> String:
	if _deposits.is_empty():
		return "No deposits authored for envelope '%s'." % ENVELOPE_ID
	var lines: PackedStringArray = []
	var cells: Array = _deposits.keys()
	cells.sort()
	for key: Variant in cells:
		var r: Dictionary = _deposits[key]
		var state := "depleted" if bool(r["depleted"]) else ("exposed" if bool(r["exposed"]) else "hidden")
		lines.append("%s  %s x%d  %s" % [key, r["material_id"], int(r["amount"]), state])
	return "\n".join(lines)


func _debug_extract_all(_args: Array[String]) -> String:
	var done := 0
	for key: Variant in _deposits.keys():
		if complete_extraction(key) > 0:
			done += 1
	return "Extracted %d exposed deposit(s)." % done


func _salvage_yield_for_dig(cell: Vector2i) -> int:
	var base := _base_salvage_yield()
	# Devil’s Mouth digs sometimes shake loose a bit more — public danger payoff.
	if is_mouth_cell(cell) and randf() < 0.2:
		return base + 1
	return base


func _base_salvage_yield() -> int:
	var rig := get_tree().root.get_node_or_null("Rig") if is_inside_tree() else null
	return 1 + int(round(float(rig.get_effect_sum(&"dig_yield_bonus")))) if rig else 1


func _apply_frontier_rules(cell: Vector2i, direction: Vector2i) -> void:
	var dug_up := direction.y < 0 or is_firmament_cell(cell)
	var dug_down := direction.y > 0 or is_mouth_cell(cell)

	if dug_up and direction.y < 0:
		var quiet := 0
		# Quieting is a Gear effect now (Dampening Wrap / Quieting Coupler).
		var rig := get_tree().root.get_node_or_null("Rig") if is_inside_tree() else null
		if rig and rig.has_method("get_effect_sum"):
			quiet += int(round(float(rig.get_effect_sum(&"quiet_dig_level"))))
		if quiet > 0:
			frontier_notice.emit("Your rig keeps the Firmament work quiet.")

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
## envelope is only 5888 cells, cheap to scan.
func save_state() -> Dictionary:
	var dug: Array = []
	for x in range(DIG_START_X, DIG_END_X):
		for y in range(ENVELOPE_ROWS):
			var cell := Vector2i(x, y)
			if not has_tile(cell):
				dug.append([cell.x, cell.y])
	# Deposits: only the delta from the authored seed (content defines the
	# pockets; a save only records which ones the player has exposed or
	# depleted). Finite-and-never-regenerates lives here — a depleted
	# deposit stays depleted across every reload.
	var deposits: Array = []
	for key: Variant in _deposits.keys():
		var r: Dictionary = _deposits[key]
		if bool(r["exposed"]) or bool(r["depleted"]):
			var c: Vector2i = key
			deposits.append({"cell": [c.x, c.y], "exposed": bool(r["exposed"]), "depleted": bool(r["depleted"])})
	# Evidence (Build Bible Spec 18): the flag and its concealment tier
	# ride along with the delta they belong to — no separate save format.
	var evidence: Array = []
	for key: Variant in _evidence.keys():
		var c2: Vector2i = key
		evidence.append({"cell": [c2.x, c2.y], "sealed_tier": str(_evidence[key]["sealed_tier"])})
	return {"dug_cells": dug, "deposits": deposits, "evidence": evidence}


func load_state(data: Dictionary) -> void:
	_fill_ground()  # reset envelope + re-seed deposits, then reapply the deltas
	var dug: Variant = data.get("dug_cells", [])
	if typeof(dug) == TYPE_ARRAY:
		for entry: Variant in dug:
			if typeof(entry) == TYPE_ARRAY and entry.size() == 2:
				erase_cell(Vector2i(int(entry[0]), int(entry[1])))
	var deposits: Variant = data.get("deposits", [])
	if typeof(deposits) == TYPE_ARRAY:
		for entry: Variant in deposits:
			if typeof(entry) != TYPE_DICTIONARY:
				continue
			var e: Dictionary = entry
			var cell_arr: Variant = e.get("cell", null)
			if typeof(cell_arr) != TYPE_ARRAY or (cell_arr as Array).size() != 2:
				continue
			var cell := Vector2i(int(cell_arr[0]), int(cell_arr[1]))
			if not _deposits.has(cell):
				continue  # a pocket the current content no longer authors
			if bool(e.get("depleted", false)):
				_deposits[cell]["depleted"] = true
			if bool(e.get("exposed", false)) or bool(e.get("depleted", false)):
				_expose_deposit_cell(cell, false)
	# Evidence (Build Bible Spec 18): restore each flag + tier; only
	# still-exposed evidence gets its seal interactable back. Restoration
	# emits nothing — it isn't a new dig.
	var evidence: Variant = data.get("evidence", [])
	if typeof(evidence) == TYPE_ARRAY:
		for entry: Variant in evidence:
			if typeof(entry) != TYPE_DICTIONARY:
				continue
			var e: Dictionary = entry
			var cell_arr: Variant = e.get("cell", null)
			if typeof(cell_arr) != TYPE_ARRAY or (cell_arr as Array).size() != 2:
				continue
			var cell := Vector2i(int(cell_arr[0]), int(cell_arr[1]))
			var tier := StringName(str(e.get("sealed_tier", "")))
			_evidence[cell] = {"sealed_tier": tier}
			if tier == &"":
				_spawn_seal_node(cell)


func reset_all() -> void:
	_fill_ground()
