extends CharacterBody2D
## Placeholder player controller.
## Digging aims in four cardinal directions through TerrainLayer.dig_in_direction —
## never hardcoded per-axis removal, so up/down expeditions reuse the same call.

const SPEED := 200.0
const JUMP_VELOCITY := -400.0
const TILE := 32.0

@export var terrain: TerrainLayer

# Last dig/move aim (any cardinal). Used when R is pressed with no aim keys held.
var _aim_dir := Vector2i.RIGHT


func _ready() -> void:
	add_to_group("player")
	if terrain == null:
		terrain = get_node_or_null("../Terrain") as TerrainLayer


func _physics_process(delta: float) -> void:
	if not is_on_floor():
		velocity += get_gravity() * delta

	# Space / ui_accept = jump (dig is the separate "dig" action on R).
	if Input.is_action_just_pressed("ui_accept") and is_on_floor():
		velocity.y = JUMP_VELOCITY

	var move_x := 0.0
	if Input.is_action_pressed("ui_left") or Input.is_physical_key_pressed(KEY_A):
		move_x -= 1.0
	if Input.is_action_pressed("ui_right") or Input.is_physical_key_pressed(KEY_D):
		move_x += 1.0

	# Update aim from held keys (WASD / arrows). Vertical can aim without flying.
	var held_aim := _read_held_aim()
	if held_aim != Vector2i.ZERO:
		_aim_dir = held_aim
	elif move_x != 0.0:
		_aim_dir = Vector2i.RIGHT if move_x > 0.0 else Vector2i.LEFT

	velocity.x = move_x * SPEED
	move_and_slide()

	if Input.is_action_just_pressed("dig"):
		_try_dig()


## Dig one adjacent tile in the current aim direction (held keys, else last aim).
func _try_dig() -> void:
	if terrain == null:
		return

	var dig_dir := _read_held_aim()
	if dig_dir == Vector2i.ZERO:
		dig_dir = _aim_dir

	var origin := global_position + Vector2(TILE * 0.5, TILE * 0.5)
	terrain.dig_in_direction(origin, dig_dir)


## Current aim from WASD / arrows. Vertical wins over horizontal if both held
## so "hold W + R" digs up even while also nudging left/right.
func _read_held_aim() -> Vector2i:
	var aim := Vector2i.ZERO

	if Input.is_action_pressed("ui_left") or Input.is_physical_key_pressed(KEY_A):
		aim.x -= 1
	if Input.is_action_pressed("ui_right") or Input.is_physical_key_pressed(KEY_D):
		aim.x += 1
	if Input.is_action_pressed("ui_up") or Input.is_physical_key_pressed(KEY_W):
		aim.y -= 1
	if Input.is_action_pressed("ui_down") or Input.is_physical_key_pressed(KEY_S):
		aim.y += 1

	if aim.y != 0:
		return Vector2i(0, signi(aim.y))
	if aim.x != 0:
		return Vector2i(signi(aim.x), 0)
	return Vector2i.ZERO
