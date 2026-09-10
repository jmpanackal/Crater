extends CharacterBody2D
## Placeholder player controller.
## Movement is simple for now; digging is the important seed system —
## direction is always a Vector2i so up/down expeditions can reuse the same path.

const SPEED := 200.0
const JUMP_VELOCITY := -400.0
const TILE := 32.0

@export var terrain: TerrainLayer

# Last horizontal facing (left/right). Used when dig is pressed with no aim keys.
var _facing := Vector2i.RIGHT


func _ready() -> void:
	if terrain == null:
		terrain = get_node_or_null("../Terrain") as TerrainLayer


func _physics_process(delta: float) -> void:
	if not is_on_floor():
		velocity += get_gravity() * delta

	# Space / ui_accept = jump (dig is a separate "dig" action on E).
	if Input.is_action_just_pressed("ui_accept") and is_on_floor():
		velocity.y = JUMP_VELOCITY

	var direction := 0.0
	if Input.is_action_pressed("ui_left") or Input.is_physical_key_pressed(KEY_A):
		direction -= 1.0
	if Input.is_action_pressed("ui_right") or Input.is_physical_key_pressed(KEY_D):
		direction += 1.0

	if direction != 0.0:
		_facing = Vector2i.RIGHT if direction > 0.0 else Vector2i.LEFT

	velocity.x = direction * SPEED
	move_and_slide()

	if Input.is_action_just_pressed("dig"):
		_try_dig()


## Dig one adjacent tile. Aim with WASD / arrows; otherwise use facing.
## Up and down are first-class directions (same dig call as left/right).
func _try_dig() -> void:
	if terrain == null:
		return

	var dig_dir := _resolve_dig_direction()
	var origin := global_position + Vector2(TILE * 0.5, TILE * 0.5)
	var target_cell := terrain.world_to_cell(origin + Vector2(dig_dir) * TILE)

	# Flat ground: left/right often aims at empty air — fall back to digging down.
	if not terrain.has_tile(target_cell) and dig_dir.y == 0:
		dig_dir = Vector2i.DOWN
		target_cell = terrain.world_to_cell(origin + Vector2(dig_dir) * TILE)

	terrain.destroy_cell(target_cell)


## Prefer explicit aim (including up/down), else last left/right facing.
func _resolve_dig_direction() -> Vector2i:
	if Input.is_action_pressed("ui_down") or Input.is_physical_key_pressed(KEY_S):
		return Vector2i.DOWN
	if Input.is_action_pressed("ui_up") or Input.is_physical_key_pressed(KEY_W):
		return Vector2i.UP
	if Input.is_action_pressed("ui_left") or Input.is_physical_key_pressed(KEY_A):
		return Vector2i.LEFT
	if Input.is_action_pressed("ui_right") or Input.is_physical_key_pressed(KEY_D):
		return Vector2i.RIGHT
	return _facing
