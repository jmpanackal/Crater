class_name MineController
extends Node2D
## Mouse mining, Terraria style: hover a rock tile, hold the left mouse button, and it cracks and
## breaks after a short hold. A tile can only be mined if it is within reach and in line of sight
## (rock or a wall in between blocks it). Everything goes through TerrainLayer.destroy_cell, so
## deposits, evidence, Perception and the dust all behave exactly as they do for the R key.
## Lives as Player/MineController; the keyboard dig (R + aim) is unchanged.

const ACTION := &"mine"
## Centre of the body to the centre of the tile. 96px = six tiles = three body heights.
const REACH_PX := 96.0
## Seconds of holding to break one tile.
const MINE_TIME := 0.28
## Hit progress on a tile you stopped mining fades this many times faster than it builds.
const DECAY_RATE := 2.0
const CRACK_STAGES := 4
const OUTLINE_OK := Color(1.0, 0.92, 0.7, 0.95)
const FILL_OK := Color(1.0, 0.92, 0.7, 0.12)
const OUTLINE_FAR := Color(0.9, 0.35, 0.3, 0.55)

## Tests set this to aim without a real mouse (world position). INF = use the mouse.
var aim_override := Vector2.INF

var _player: CharacterBody2D
var _terrain: TerrainLayer
## cell -> seconds of progress
var _damage: Dictionary = {}
var _hover := Vector2i(1 << 30, 1 << 30)
var _hover_state := &"none" ## none | ok | far | blocked
var _mining_cell := Vector2i(1 << 30, 1 << 30)


func _ready() -> void:
	top_level = true
	z_index = 40
	_ensure_action()
	_player = get_parent() as CharacterBody2D
	if _player != null:
		_terrain = _player.get("terrain") as TerrainLayer
	set_physics_process(true)


func _ensure_action() -> void:
	if InputMap.has_action(ACTION):
		return
	InputMap.add_action(ACTION)
	var ev := InputEventMouseButton.new()
	ev.button_index = MOUSE_BUTTON_LEFT
	InputMap.action_add_event(ACTION, ev)


## World position the cursor is on.
func aim_world() -> Vector2:
	if aim_override != Vector2.INF:
		return aim_override
	return get_global_mouse_position()


func hovered_cell() -> Vector2i:
	return _hover


func hover_state() -> StringName:
	return _hover_state


func damage_at(cell: Vector2i) -> float:
	return float(_damage.get(cell, 0.0))


func _player_center() -> Vector2:
	return _player.global_position + Vector2(16.0, 16.0)


func _physics_process(delta: float) -> void:
	if _player == null or not is_instance_valid(_player):
		return
	if _terrain == null:
		_terrain = _player.get("terrain") as TerrainLayer
		if _terrain == null:
			return
	_hover = _terrain.world_to_cell(aim_world())
	_hover_state = _classify(_hover)
	var holding := Input.is_action_pressed(ACTION) and not _ui_blocking()
	var target := _hover if (holding and _hover_state == &"ok") else Vector2i(1 << 30, 1 << 30)
	_decay(delta, target)
	if target.x != (1 << 30):
		_mine(target, delta)
	else:
		_mining_cell = Vector2i(1 << 30, 1 << 30)
	queue_redraw()


## none: nothing diggable there. far: out of reach. blocked: no line of sight. ok: mineable now.
func _classify(cell: Vector2i) -> StringName:
	if not _terrain.has_tile(cell) or not _terrain.is_within_dig_envelope(cell):
		return &"none"
	var centre := _terrain.to_global(_terrain.map_to_local(cell))
	if _player_center().distance_to(centre) > REACH_PX:
		return &"far"
	if not line_of_sight(cell):
		return &"blocked"
	return &"ok"


## True when nothing solid sits between the player's centre and the tile (the tile itself and
## open air do not block). Direct access only: rock, walls, stair wedges and floors (decks) all
## block, so nothing can be mined through a floor or from behind another tile.
func line_of_sight(cell: Vector2i) -> bool:
	var from := _player_center()
	var to := _terrain.to_global(_terrain.map_to_local(cell))
	var solid := _solid_layer()
	var steps := int(ceil(from.distance_to(to) / 2.0))
	for i in range(1, steps):
		var p := from.lerp(to, float(i) / float(steps))
		var c := _terrain.world_to_cell(p)
		if c == cell:
			continue
		if _terrain.has_tile(c):
			return false
		if solid != null and solid.has_method("cell_source") and int(solid.call("cell_source", solid.local_to_map(solid.to_local(p)))) != -1:
			return false # a wall, a stair wedge or a deck (cell_source counts the deck layer too)
	return true


func _solid_layer() -> TileMapLayer:
	var scene := _terrain.get_parent()
	if scene == null:
		return null
	return scene.get_node_or_null("Hollow/HollowTerrain") as TileMapLayer


func _mine(cell: Vector2i, delta: float) -> void:
	if not _player.has_method("_can_afford_dig") or not bool(_player.call("_can_afford_dig")):
		return
	if cell != _mining_cell:
		_mining_cell = cell
		if _player.has_method("face_toward"):
			_player.call("face_toward", _dir_to(cell))
	var progress := float(_damage.get(cell, 0.0)) + delta
	if progress >= MINE_TIME:
		_damage.erase(cell)
		_terrain.destroy_cell(cell, _dir_to(cell))
		_mining_cell = Vector2i(1 << 30, 1 << 30)
		return
	_damage[cell] = progress


func _dir_to(cell: Vector2i) -> Vector2i:
	var d := _terrain.to_global(_terrain.map_to_local(cell)) - _player_center()
	if absf(d.y) > absf(d.x):
		return Vector2i(0, 1 if d.y > 0.0 else -1)
	return Vector2i(1 if d.x > 0.0 else -1, 0)


func _decay(delta: float, target: Vector2i) -> void:
	for key: Variant in _damage.keys():
		if key == target:
			continue
		var left := float(_damage[key]) - delta * DECAY_RATE
		if left <= 0.0:
			_damage.erase(key)
		else:
			_damage[key] = left


## True while a menu that owns the mouse is up (dialogue, journal, requisition), or the mouse is
## over a clickable control.
func _ui_blocking() -> bool:
	var scene := get_tree().current_scene if get_tree() != null else null
	var root := scene if scene != null else _player.get_parent()
	for path in ["UI/DialoguePanel", "UI/JournalHud/Panel", "UI/RequisitionPanel"]:
		var n := root.get_node_or_null(path)
		if n != null and bool(n.get("visible")):
			return true
	if aim_override == Vector2.INF:
		var hovered := get_viewport().gui_get_hovered_control()
		if hovered != null and hovered.mouse_filter == Control.MOUSE_FILTER_STOP:
			return true
	return false


func _draw() -> void:
	if _terrain == null or _hover_state == &"none":
		return
	var tile := float(TerrainLayer.TILE_SIZE)
	var rect := Rect2(_terrain.to_global(_terrain.map_to_local(_hover)) - Vector2(tile, tile) * 0.5, Vector2(tile, tile))
	rect.position -= global_position
	if _hover_state == &"ok":
		draw_rect(rect, FILL_OK)
		draw_rect(rect, OUTLINE_OK, false, 1.0)
	else:
		draw_rect(rect, OUTLINE_FAR, false, 1.0)
	for key: Variant in _damage.keys():
		var cell: Vector2i = key
		var stage := int(floor(float(_damage[key]) / MINE_TIME * float(CRACK_STAGES)))
		if stage <= 0:
			continue
		var r := Rect2(_terrain.to_global(_terrain.map_to_local(cell)) - Vector2(tile, tile) * 0.5 - global_position, Vector2(tile, tile))
		draw_rect(r, Color(0.0, 0.0, 0.0, 0.12 * float(stage)))
		# Cracks grow with each stage.
		var c := r.get_center()
		draw_line(c + Vector2(-5, -5), c + Vector2(-1, 0), Color(0, 0, 0, 0.7), 1.0)
		if stage >= 2:
			draw_line(c + Vector2(-1, 0), c + Vector2(4, 3), Color(0, 0, 0, 0.7), 1.0)
		if stage >= 3:
			draw_line(c + Vector2(2, -6), c + Vector2(0, 1), Color(0, 0, 0, 0.7), 1.0)
		if stage >= 4:
			draw_line(c + Vector2(-6, 4), c + Vector2(-1, 1), Color(0, 0, 0, 0.7), 1.0)
