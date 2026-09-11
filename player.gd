extends CharacterBody2D
## Player controller — movement, dig aim, and 8-dir idle visuals.
## Digging still uses 4 cardinal directions; sprite facing reuses the same aim
## input but keeps diagonals for the 8-direction idle set.

const SPEED := 200.0
const JUMP_VELOCITY := -400.0
const CLIMB_SPEED := 140.0
const TILE := 32.0
const WORLD_COLLISION_MASK := 1
## Body height used to convert deck-top Y → CharacterBody2D position (feet on deck).
const BODY_HEIGHT := 32.0
## Idle sheets are 64×64 (2× PixelLab); scale to match the 32×32 collider so feet sit on deck.
const SPRITE_SCALE := 0.5
## Snap onto a landing if within this many px when climb ends.
const CLIMB_LAND_SNAP_PX := 48.0

## Fairness windows (see docs/game-feel-best-practices.md).
const COYOTE_TIME := 0.10
const JUMP_BUFFER := 0.12
## Light weight without mushy dig-aim (reach max speed in ~0.14s on ground).
const ACCEL := 1400.0
const FRICTION := 1800.0
const AIR_ACCEL := 1000.0
const AIR_FRICTION := 400.0
## Soft respawn if we drop past Hollow/dig void (camera limit_bottom is 900).
const VOID_FALL_Y := 680.0


@export var terrain: TerrainLayer

@onready var _sprite: AnimatedSprite2D = $AnimatedSprite2D

# Last dig aim (cardinal only). Used when R is pressed with no aim keys held.
var _aim_dir := Vector2i.RIGHT

# Last visual facing (may be diagonal). Drives idle_* animations.
var _facing_8 := Vector2i(1, 0) # east / right default

## Nested climb Area2D overlaps (Hollow ladders).
var _climb_zones := 0
var _climb_ladders: Array[Node] = []
## True after grabbing a ladder with W/S until hop-off, leave zone, or land idle.
var _climbing := false
## After auto-landing at a deck end, ignore held W/S until released (avoids re-grab).
var _climb_axis_release_required := false

var _coyote_timer := 0.0
var _jump_buffer_timer := 0.0
## Last grounded stand — used when falling into the pit void.
var _last_safe_pos := Vector2.ZERO
var _has_safe_pos := false
## Sprite-only squash/stretch (never scales collision).
var _feel_scale := Vector2.ONE
var _was_on_floor := false
var _land_impact := 0.0


func _ready() -> void:
	add_to_group("player")
	if terrain == null:
		terrain = get_node_or_null("../Terrain") as TerrainLayer
	if _sprite:
		_sprite.sprite_frames = _build_idle_frames()
		_sprite.scale = Vector2(SPRITE_SCALE, SPRITE_SCALE)
		_play_idle_for_facing()
		_ensure_contact_shadow()
	_last_safe_pos = global_position
	_has_safe_pos = true
	_was_on_floor = is_on_floor()


## Test hooks — keep jump fairness verifiable without Input frame races.
func debug_set_coyote(seconds: float) -> void:
	_coyote_timer = seconds


func debug_set_jump_buffer(seconds: float) -> void:
	_jump_buffer_timer = seconds


func debug_coyote() -> float:
	return _coyote_timer


func debug_jump_buffer() -> float:
	return _jump_buffer_timer


func debug_feel_scale() -> Vector2:
	return _feel_scale


func debug_force_land_feel(impact: float = 1.0) -> void:
	_apply_land_feel(impact)


func enter_climb_zone(ladder: Node = null) -> void:
	_climb_zones += 1
	if ladder != null and not _climb_ladders.has(ladder):
		_climb_ladders.append(ladder)


func exit_climb_zone(ladder: Node = null) -> void:
	if ladder != null:
		_climb_ladders.erase(ladder)
	_climb_zones = maxi(0, _climb_zones - 1)
	if _climb_zones == 0:
		# Keep `ladder` for snap — array is empty after erase when it was the last zone.
		_stop_climbing(true, ladder)
		_climb_ladders.clear()
		_climb_axis_release_required = false


func is_in_climb_zone() -> bool:
	return _climb_zones > 0


func is_climbing() -> bool:
	return _climbing


## Always restores world collision before gravity can run. Optionally snap to a deck.
func _stop_climbing(snap_to_deck: bool = false, ladder: Node = null) -> void:
	var was_climbing := _climbing
	_climbing = false
	collision_mask = WORLD_COLLISION_MASK
	if snap_to_deck and was_climbing:
		_snap_to_nearest_deck_if_close(ladder)


func _physics_process(delta: float) -> void:
	var in_zone := is_in_climb_zone()
	var climb_y := _read_climb_axis() if in_zone else 0.0
	if _climb_axis_release_required:
		if climb_y == 0.0:
			_climb_axis_release_required = false
		else:
			climb_y = 0.0
	if in_zone and climb_y != 0.0:
		_climbing = true

	_update_coyote_and_buffer(delta)
	var jumped := _try_consume_jump(in_zone)

	if _climbing and not jumped:
		# Reach a landing before the Area2D exits below/above the deck collider.
		if _try_dismount_at_deck_end(climb_y):
			pass
		elif climb_y != 0.0 or not is_on_floor():
			# Pass through deck/stair colliders while on the shaft.
			collision_mask = 0
			velocity.y = climb_y * CLIMB_SPEED
		else:
			# Idle on a deck still overlapping the zone.
			_stop_climbing(false)
	else:
		# Mask must be on before gravity — never fall with collision_mask 0.
		collision_mask = WORLD_COLLISION_MASK
		if not is_on_floor():
			velocity += get_gravity() * delta

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

	_apply_horizontal_move(move_x, delta)
	if not is_on_floor() and velocity.y > 0.0:
		_land_impact = maxf(_land_impact, velocity.y / 450.0)
	move_and_slide()
	_update_land_and_feel(delta)
	_remember_safe_ground()
	_soft_respawn_if_void()
	_play_idle_for_facing()

	if Input.is_action_just_pressed("dig"):
		_try_dig()


func _update_coyote_and_buffer(delta: float) -> void:
	if is_on_floor() or _climbing:
		_coyote_timer = COYOTE_TIME
	else:
		_coyote_timer = maxf(0.0, _coyote_timer - delta)

	if Input.is_action_just_pressed("ui_accept"):
		_jump_buffer_timer = JUMP_BUFFER
	else:
		_jump_buffer_timer = maxf(0.0, _jump_buffer_timer - delta)


## Space / ui_accept = jump (dig is separate "dig" on R). Floor, coyote, buffer, or ladder hop.
func _try_consume_jump(in_zone: bool) -> bool:
	var can_floor_jump := is_on_floor() or _coyote_timer > 0.0
	var can_ladder_jump := _climbing or in_zone
	if _jump_buffer_timer <= 0.0:
		return false
	if not can_floor_jump and not can_ladder_jump:
		return false

	_jump_buffer_timer = 0.0
	_coyote_timer = 0.0
	collision_mask = WORLD_COLLISION_MASK
	_climbing = false
	_climb_axis_release_required = false
	velocity.y = JUMP_VELOCITY
	_feel_scale = Vector2(0.88, 1.14) # stretch — sprite only
	return true


func _update_land_and_feel(delta: float) -> void:
	var on_floor_now := is_on_floor() and not _climbing
	if on_floor_now and not _was_on_floor:
		_apply_land_feel(_land_impact)
		_land_impact = 0.0
	elif on_floor_now:
		_land_impact = 0.0
	_was_on_floor = on_floor_now or _climbing

	_feel_scale = _feel_scale.lerp(Vector2.ONE, clampf(14.0 * delta, 0.0, 1.0))
	if _sprite:
		_sprite.scale = _feel_scale * SPRITE_SCALE


func _apply_land_feel(impact: float) -> void:
	var soft := clampf(impact, 0.2, 1.4)
	_feel_scale = Vector2(1.0 + 0.16 * soft, 1.0 - 0.14 * soft)
	FeelFx.spawn_land_dust(get_parent() if get_parent() else self, global_position + Vector2(16, 28), soft)


func _ensure_contact_shadow() -> void:
	if get_node_or_null("ContactShadow") != null:
		return
	var shadow := Polygon2D.new()
	shadow.name = "ContactShadow"
	shadow.z_index = -1
	shadow.color = Color(0.02, 0.03, 0.04, 0.35)
	# Soft oval under the 32×32 body (local origin = top-left of collider).
	shadow.polygon = PackedVector2Array([
		Vector2(6, 30), Vector2(26, 30), Vector2(24, 33), Vector2(8, 33),
	])
	add_child(shadow)


func _apply_horizontal_move(move_x: float, delta: float) -> void:
	var x_speed := SPEED * (0.45 if _climbing else 1.0)
	var target := move_x * x_speed
	if _climbing:
		# Ladder hops stay snappy so W/S + slight A/D feel responsive.
		velocity.x = target
		return

	var on_ground := is_on_floor()
	var rate := ACCEL if on_ground else AIR_ACCEL
	if move_x == 0.0:
		rate = FRICTION if on_ground else AIR_FRICTION
	velocity.x = move_toward(velocity.x, target, rate * delta)


func _remember_safe_ground() -> void:
	if _climbing or not is_on_floor():
		return
	if global_position.y >= VOID_FALL_Y - 40.0:
		return
	_last_safe_pos = global_position
	_has_safe_pos = true


func _soft_respawn_if_void() -> void:
	if global_position.y < VOID_FALL_Y:
		return
	var dest := _last_safe_pos if _has_safe_pos else HollowLayout.nearest_safe_stand(global_position)
	if dest == Vector2.ZERO:
		dest = HollowLayout.nearest_safe_stand(global_position)
	collision_mask = WORLD_COLLISION_MASK
	_climbing = false
	_climb_axis_release_required = false
	_coyote_timer = 0.0
	_jump_buffer_timer = 0.0
	velocity = Vector2.ZERO
	global_position = dest


## Auto-land at shaft ends so we never exit the climb Area below the deck collider.
func _try_dismount_at_deck_end(climb_y: float) -> bool:
	var ladder := _active_ladder()
	if ladder == null or not ladder.has_method("deck_top_y"):
		return false
	var stand_top := float(ladder.deck_top_y()) - BODY_HEIGHT
	var stand_bottom := float(ladder.deck_bottom_y()) - BODY_HEIGHT
	# Climbing down onto lower deck (feet reaching deck top). Lower deck is solid under shaft.
	if climb_y > 0.0 and global_position.y >= stand_bottom - 2.0:
		global_position.y = stand_bottom
		velocity.y = 0.0
		_climb_axis_release_required = true
		_stop_climbing(false)
		return true
	# Climbing up onto upper deck — step beside the floor opening so feet find collision.
	if climb_y < 0.0 and global_position.y <= stand_top - 2.0:
		global_position.y = stand_top
		_snap_beside_upper_opening(ladder)
		velocity.y = 0.0
		_climb_axis_release_required = true
		_stop_climbing(false)
		return true
	return false


func _snap_beside_upper_opening(ladder: Node) -> void:
	if ladder == null or not ladder.has_method("upper_opening"):
		return
	var opening: Vector2 = ladder.upper_opening()
	var open0 := opening.x
	var open1 := opening.y
	if open1 <= open0:
		return
	var body_left := global_position.x
	var body_right := global_position.x + BODY_HEIGHT
	if body_right <= open0 or body_left >= open1:
		return # already clear of the gap
	var land_left := open0 - BODY_HEIGHT
	var land_right := open1
	var side := 0
	if "upper_land_side" in ladder:
		side = int(ladder.upper_land_side)
	if side < 0:
		global_position.x = land_left
	elif side > 0:
		global_position.x = land_right
	elif absf(body_left - land_left) <= absf(body_left - land_right):
		global_position.x = land_left
	else:
		global_position.x = land_right


func _active_ladder() -> Node:
	if _climb_ladders.is_empty():
		return null
	return _climb_ladders[_climb_ladders.size() - 1]


func _snap_to_nearest_deck_if_close(ladder: Node = null) -> void:
	if ladder == null:
		ladder = _active_ladder()
	if ladder == null or not ladder.has_method("deck_top_y"):
		return
	var stand_top := float(ladder.deck_top_y()) - BODY_HEIGHT
	var stand_bottom := float(ladder.deck_bottom_y()) - BODY_HEIGHT
	var target := stand_top
	var onto_upper := true
	if absf(global_position.y - stand_bottom) < absf(global_position.y - stand_top):
		target = stand_bottom
		onto_upper = false
	if absf(global_position.y - target) <= CLIMB_LAND_SNAP_PX:
		global_position.y = target
		if onto_upper:
			_snap_beside_upper_opening(ladder)
		velocity.y = 0.0


func _read_climb_axis() -> float:
	var climb_y := 0.0
	if Input.is_action_pressed("ui_up") or Input.is_physical_key_pressed(KEY_W):
		climb_y -= 1.0
	if Input.is_action_pressed("ui_down") or Input.is_physical_key_pressed(KEY_S):
		climb_y += 1.0
	return climb_y


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
