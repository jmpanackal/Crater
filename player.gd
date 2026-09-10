extends CharacterBody2D
## Player controller — movement, dig aim, and 8-dir idle visuals.
## Digging still uses 4 cardinal directions; sprite facing reuses the same aim
## input but keeps diagonals for the 8-direction idle set.

const SPEED := 200.0
const JUMP_VELOCITY := -400.0
const TILE := 32.0

@export var terrain: TerrainLayer

@onready var _sprite: AnimatedSprite2D = $AnimatedSprite2D

# Last dig aim (cardinal only). Used when R is pressed with no aim keys held.
var _aim_dir := Vector2i.RIGHT

# Last visual facing (may be diagonal). Drives idle_* animations.
var _facing_8 := Vector2i(1, 0) # east / right default


func _ready() -> void:
	add_to_group("player")
	if terrain == null:
		terrain = get_node_or_null("../Terrain") as TerrainLayer
	if _sprite:
		_sprite.sprite_frames = _build_idle_frames()
		_play_idle_for_facing()


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

	# Dig aim: 4-dir (vertical wins) — same as before.
	var held_aim := _read_held_aim()
	if held_aim != Vector2i.ZERO:
		_aim_dir = held_aim
	elif move_x != 0.0:
		_aim_dir = Vector2i.RIGHT if move_x > 0.0 else Vector2i.LEFT

	# Visual facing: same WASD/arrows, but keep diagonals for 8-dir sprites.
	var visual := _read_visual_dir()
	if visual != Vector2i.ZERO:
		_facing_8 = visual
	elif move_x != 0.0:
		_facing_8 = Vector2i.RIGHT if move_x > 0.0 else Vector2i.LEFT

	velocity.x = move_x * SPEED
	move_and_slide()
	_play_idle_for_facing()

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


## Current dig aim from WASD / arrows. Vertical wins over horizontal if both held
## so "hold W + R" digs up even while also nudging left/right.
func _read_held_aim() -> Vector2i:
	var aim := _read_raw_aim()
	if aim.y != 0:
		return Vector2i(0, signi(aim.y))
	if aim.x != 0:
		return Vector2i(signi(aim.x), 0)
	return Vector2i.ZERO


## Same keys as dig aim, but diagonals are kept for sprite facing.
func _read_visual_dir() -> Vector2i:
	var aim := _read_raw_aim()
	if aim == Vector2i.ZERO:
		return Vector2i.ZERO
	return Vector2i(signi(aim.x), signi(aim.y))


func _read_raw_aim() -> Vector2i:
	var aim := Vector2i.ZERO
	if Input.is_action_pressed("ui_left") or Input.is_physical_key_pressed(KEY_A):
		aim.x -= 1
	if Input.is_action_pressed("ui_right") or Input.is_physical_key_pressed(KEY_D):
		aim.x += 1
	if Input.is_action_pressed("ui_up") or Input.is_physical_key_pressed(KEY_W):
		aim.y -= 1
	if Input.is_action_pressed("ui_down") or Input.is_physical_key_pressed(KEY_S):
		aim.y += 1
	return aim


func _play_idle_for_facing() -> void:
	if _sprite == null or _sprite.sprite_frames == null:
		return
	var anim := facing_to_idle_anim(_facing_8)
	if _sprite.animation != anim or not _sprite.is_playing():
		_sprite.play(anim)


## Maps a Vector2i facing to PixelLab idle animation names (south = +Y).
static func facing_to_idle_anim(dir: Vector2i) -> StringName:
	var x := signi(dir.x)
	var y := signi(dir.y)
	if x == 0 and y == 0:
		return &"idle_east"
	if x == 0 and y > 0:
		return &"idle_south"
	if x == 0 and y < 0:
		return &"idle_north"
	if y == 0 and x > 0:
		return &"idle_east"
	if y == 0 and x < 0:
		return &"idle_west"
	if x > 0 and y > 0:
		return &"idle_south_east"
	if x < 0 and y > 0:
		return &"idle_south_west"
	if x > 0 and y < 0:
		return &"idle_north_east"
	return &"idle_north_west"


func _build_idle_frames() -> SpriteFrames:
	var frames := SpriteFrames.new()
	var paths := {
		&"idle_south": "res://sprites/player/idle/south.png",
		&"idle_south_east": "res://sprites/player/idle/south-east.png",
		&"idle_east": "res://sprites/player/idle/east.png",
		&"idle_north_east": "res://sprites/player/idle/north-east.png",
		&"idle_north": "res://sprites/player/idle/north.png",
		&"idle_north_west": "res://sprites/player/idle/north-west.png",
		&"idle_west": "res://sprites/player/idle/west.png",
		&"idle_south_west": "res://sprites/player/idle/south-west.png",
	}
	# Remove the default empty animation Godot adds.
	if frames.has_animation(&"default"):
		frames.remove_animation(&"default")

	for anim_name in paths.keys():
		frames.add_animation(anim_name)
		frames.set_animation_loop(anim_name, true)
		frames.set_animation_speed(anim_name, 1.0)
		var tex: Texture2D = load(paths[anim_name])
		if tex:
			frames.add_frame(anim_name, tex)
	return frames
