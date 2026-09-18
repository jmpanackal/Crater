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
## Soft respawn if we drop past Hollow/dig void (below seep band).
## Below this the player has fallen past the deepest deck (SEEP_Y=1216) into the
## Mouth and gets soft-respawned. Keeps the same ~112px margin under Seep it
## always had; must move if SEEP_Y does.
const VOID_FALL_Y := 1328.0


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
## Last grounded stand — used when falling into Devil's Mouth.
var _last_safe_pos := Vector2.ZERO
var _has_safe_pos := false
## Sprite-only squash/stretch (never scales collision).
var _feel_scale := Vector2.ONE
var _was_on_floor := false
var _land_impact := 0.0


func _ready() -> void:
	add_to_group("player")
	floor_max_angle = deg_to_rad(50.0)
	floor_snap_length = 8.0
	if terrain == null:
		terrain = get_node_or_null("../Terrain") as TerrainLayer
	if _sprite:
		_sprite.sprite_frames = _build_idle_frames()
		_sprite.scale = Vector2(SPRITE_SCALE, SPRITE_SCALE)
		_play_idle_for_facing()
		_ensure_contact_shadow()
	_ensure_interaction()
	_last_safe_pos = global_position
	_has_safe_pos = true
	_was_on_floor = is_on_floor()


const InteractionScript := preload("res://interaction.gd")


## Build Bible Spec 10 — one central Area2D-based Interaction component
## instead of every interactable type handling its own input. Instantiated
## via preload rather than the Interaction class_name identifier — a
## freshly added class_name isn't in the global script class cache until
## an editor rescan, which a headless test run never triggers.
func _ensure_interaction() -> void:
	if get_node_or_null("Interaction") != null:
		return
	var interaction: Area2D = InteractionScript.new()
	interaction.name = "Interaction"
	add_child(interaction)


func get_interaction() -> Node:
	return get_node_or_null("Interaction")


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
	if in_zone and climb_y != 0.0 and not _climbing:
		# Grabbing a ladder is strenuous while hauling (Spec 13 / G1).
		if _pay_strenuous_if_loaded():
			_climbing = true
		else:
			climb_y = 0.0

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
	if Input.is_action_just_pressed("interact"):
		var interaction := get_interaction()
		if interaction != null:
			interaction.try_interact(self)


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
	# A jump is strenuous while hauling (Spec 13 / G1); Exhausted refuses it.
	if not _pay_strenuous_if_loaded():
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
	var x_speed := SPEED * (0.45 if _climbing else 1.0) * _hauling_speed_multiplier()
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
	if not _can_afford_dig():
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


## Build Bible Spec 07 (Player Controller) contract hooks into Stamina
## (Spec 08, now built) and Hauling (Spec 13, not yet built). Contract-only
## per Spec 07's own failure-case note: method signatures agreed, bodies
## stubbed until real numbers exist — normal movement must never break just
## because a dependency doesn't exist, or doesn't have a tuned cost yet.
##
## Player Controller calls these systems' public APIs directly for
## blocking-relevant actions (Spec 07, confirmed option A) — no
## intermediary "Action" layer between input and consequence. This matches
## Spec 01's "reads are open, writes are not" ownership rule: Player
## Controller only ever reads/requests here, it never mutates Stamina's or
## Hauling's own state.

## Digging's real stamina cost is canon-OPEN — not decided or tuned
## anywhere yet, despite digging being explicitly named a strenuous action
## in canon §9. 0.0 (always affordable) preserves today's actual game feel
## exactly rather than inventing a number; this is the one line to change
## once a real tuning value exists.
const DIG_STAMINA_COST := 0.0


## True when a dig is currently affordable per Stamina's current block
## state. Fails safe (true) when Stamina doesn't exist yet — real once
## Stamina (Spec 08) is present, using can_afford(cost: float), matching
## its actual API rather than the guessed shape this stub used before
## Spec 08 existed.
func _can_afford_dig() -> bool:
	var stamina := get_tree().root.get_node_or_null("Stamina")
	if stamina == null or not stamina.has_method("can_afford"):
		return true
	return bool(stamina.can_afford(dig_stamina_cost()))


## The per-dig stamina cost after Gear (Build Bible Spec 14: excavation
## Gear like the Fracture Pick reduces it — Rig.EFFECT_DIG_COST_REDUCTION,
## a fraction). Baseline digging itself is never Gear-gated; Gear can only
## make it cheaper. Still 0.0 in practice while DIG_STAMINA_COST is
## untuned, but the hook is real so tuning it is one constant.
func dig_stamina_cost() -> float:
	var rig := get_tree().root.get_node_or_null("Rig")
	if rig == null or not rig.has_method("get_effect_sum"):
		return DIG_STAMINA_COST
	var reduction := clampf(float(rig.get_effect_sum(&"dig_stamina_cost_reduction")), 0.0, 1.0)
	return DIG_STAMINA_COST * (1.0 - reduction)


## Movement speed multiplier from Hauling's current loaded state — per the
## locked G1 decision, being loaded makes climbing/ladders/ramps/jumps
## strenuous and unlocks a slower loaded-movement speed. Player Controller
## owns SPEED itself and only reads this adjustment (Spec 07, confirmed
## option A) — Hauling never reaches in and sets it directly. Fails safe
## (1.0, unaffected) when Hauling doesn't exist yet.
func _hauling_speed_multiplier() -> float:
	var hauling := get_tree().root.get_node_or_null("Hauling")
	if hauling == null or not hauling.has_method("get_movement_speed_multiplier"):
		return 1.0
	return float(hauling.get_movement_speed_multiplier())


## Build Bible Spec 13 (G1, option A): while a bundle is attached, jumps
## and ladder grabs are strenuous — they spend stamina. Unloaded, they
## stay free, exactly as before. At zero usable stamina the action still
## happens as an Overexertion (G21, option A) — Stamina/Fatigue own that
## conversion; only being Exhausted refuses the action outright. Returns
## whether the action may proceed. Ramps aren't a distinct traversal in
## the prototype yet and sprinting doesn't exist, so neither is gated here.
func _pay_strenuous_if_loaded() -> bool:
	var hauling := get_tree().root.get_node_or_null("Hauling")
	if hauling == null or not hauling.has_method("is_loaded") or not bool(hauling.is_loaded()):
		return true
	var stamina := get_tree().root.get_node_or_null("Stamina")
	if stamina == null or not stamina.has_method("can_afford"):
		return true
	if bool(stamina.is_exhausted()):
		return false
	var cost := float(hauling.get_strenuous_action_cost())
	if bool(stamina.can_afford(cost)):
		stamina.spend(cost)
	else:
		stamina.overexert(cost)
	return true


## Placeholder-art-first (2026-09-17): the real PixelLab idle sheets this
## used to load (sprites/player/idle/*.png) were generated in an
## "Eastward/Owlboy-detail" style that predates this project's
## placeholder-art-first plan and its beginner-achievable pixel-art scale
## — removed, not resized, since they were never the target style.
## facing_to_idle_anim()'s 8-direction mapping is real, tested logic and
## is unchanged; only the pixels backing each animation name changed, to
## a procedurally drawn flat-color silhouette (hollow_npc.gd's convention).
const ANIM_FACING := {
	&"idle_south": Vector2i(0, 1),
	&"idle_south_east": Vector2i(1, 1),
	&"idle_east": Vector2i(1, 0),
	&"idle_north_east": Vector2i(1, -1),
	&"idle_north": Vector2i(0, -1),
	&"idle_north_west": Vector2i(-1, -1),
	&"idle_west": Vector2i(-1, 0),
	&"idle_south_west": Vector2i(-1, 1),
}


func _build_idle_frames() -> SpriteFrames:
	var frames := SpriteFrames.new()
	# Remove the default empty animation Godot adds.
	if frames.has_animation(&"default"):
		frames.remove_animation(&"default")

	for anim_name: StringName in ANIM_FACING.keys():
		frames.add_animation(anim_name)
		frames.set_animation_loop(anim_name, true)
		frames.set_animation_speed(anim_name, 1.0)
		frames.add_frame(anim_name, _placeholder_frame(ANIM_FACING[anim_name]))
	return frames


## Flat-color placeholder silhouette on a 64x64 canvas (matches the old
## sheet's baseline so SPRITE_SCALE/BODY_HEIGHT math is unchanged). A
## small offset "face" mark shows facing direction during playtesting.
func _placeholder_frame(facing: Vector2i) -> Texture2D:
	var image := Image.create(64, 64, false, Image.FORMAT_RGBA8)
	image.fill(Color(0.0, 0.0, 0.0, 0.0))
	image.fill_rect(Rect2i(20, 20, 24, 36), Color(0.65, 0.5, 0.35, 0.9)) # body
	image.fill_rect(Rect2i(24, 8, 16, 16), Color(0.75, 0.62, 0.48, 0.95)) # head
	var face_center := Vector2i(32, 16) + facing * 6
	image.fill_rect(Rect2i(face_center.x - 2, face_center.y - 2, 4, 4), Color(0.15, 0.12, 0.1, 1.0))
	return ImageTexture.create_from_image(image)
