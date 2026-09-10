extends CharacterBody2D

const SPEED := 200.0
const JUMP_VELOCITY := -400.0
const TILE := 32.0

@export var terrain: TileMapLayer

var _facing := Vector2i.RIGHT


func _ready() -> void:
	if terrain == null:
		terrain = get_node_or_null("../Terrain") as TileMapLayer


func _physics_process(delta: float) -> void:
	if not is_on_floor():
		velocity += get_gravity() * delta

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


func _try_dig() -> void:
	if terrain == null:
		return

	var dig_dir := _facing
	if Input.is_action_pressed("ui_down") or Input.is_physical_key_pressed(KEY_S):
		dig_dir = Vector2i.DOWN
	elif Input.is_action_pressed("ui_up") or Input.is_physical_key_pressed(KEY_W):
		dig_dir = Vector2i.UP
	elif Input.is_action_pressed("ui_left") or Input.is_physical_key_pressed(KEY_A):
		dig_dir = Vector2i.LEFT
	elif Input.is_action_pressed("ui_right") or Input.is_physical_key_pressed(KEY_D):
		dig_dir = Vector2i.RIGHT

	# Aim from player center one tile in the dig direction.
	var origin := global_position + Vector2(TILE * 0.5, TILE * 0.5)
	var target := origin + Vector2(dig_dir) * TILE
	var cell := terrain.local_to_map(terrain.to_local(target))

	# On flat ground, left/right often points at empty air — dig down instead.
	if terrain.get_cell_source_id(cell) == -1 and dig_dir.y == 0:
		dig_dir = Vector2i.DOWN
		target = origin + Vector2(dig_dir) * TILE
		cell = terrain.local_to_map(terrain.to_local(target))

	if terrain.get_cell_source_id(cell) != -1:
		terrain.erase_cell(cell)
