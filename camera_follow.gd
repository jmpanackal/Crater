extends Camera2D
## Soft Hollow follow — look-ahead, drag deadzone, light shake.
## Keeps Firmament/Mouth vertical climbs readable without snappy lock-on.
## Hollow clamps limit_right so dig-tile columns never peek into Wick framing.
## Mid-East Approach keeps civic framing; dig unlock starts after its east tip.

const LOOK_AHEAD_X := 44.0
const LOOK_AHEAD_Y := 34.0
const LOOK_LERP := 5.2
const SHAKE_DECAY := 10.0

## Dig columns begin at TerrainLayer.DIG_START_X * TILE (1024). Hide west of Mid-East.
const LIMIT_RIGHT_HOLLOW := 1024
const LIMIT_RIGHT_DIG := 2200
## Half-viewport pad past Mid-East Approach's east tip so the player stays framed at x=1408.
## Dig unlock waits until the player walks past the civic approach into Dig Front.
const MID_EAST_FRAME_PAD := 576.0
## Dig unlock span past Mid-East Approach into Mid-East Dig Front.
const DIG_LIMIT_BLEND_SPAN := 256.0

var _look := Vector2.ZERO
var _shake := 0.0


func _ready() -> void:
	add_to_group("player_camera")
	enabled = true
	process_callback = Camera2D.CAMERA2D_PROCESS_PHYSICS
	make_current()
	position_smoothing_enabled = true
	position_smoothing_speed = 5.5
	drag_horizontal_enabled = true
	drag_vertical_enabled = true
	# Soft deadzone so small ledge nudges don't yank the frame.
	drag_left_margin = 0.12
	drag_right_margin = 0.12
	drag_top_margin = 0.18
	drag_bottom_margin = 0.24
	limit_right = LIMIT_RIGHT_HOLLOW


func _physics_process(delta: float) -> void:
	var body := get_parent() as CharacterBody2D
	var want := Vector2.ZERO
	if body != null:
		_update_dig_limit(body.global_position.x)
		var vx := clampf(body.velocity.x / 200.0, -1.0, 1.0)
		var vy := clampf(body.velocity.y / 380.0, -1.0, 1.0)
		# Climbing: bias slightly up so the next deck enters frame early.
		if body.has_method("is_climbing") and body.is_climbing():
			vy = minf(vy, -0.35)
		want = Vector2(vx * LOOK_AHEAD_X, vy * LOOK_AHEAD_Y)
	_look = _look.lerp(want, clampf(LOOK_LERP * delta, 0.0, 1.0))
	_shake = maxf(0.0, _shake - SHAKE_DECAY * delta)
	var jitter := Vector2.ZERO
	if _shake > 0.01:
		jitter = Vector2(randf_range(-1.0, 1.0), randf_range(-1.0, 1.0)) * _shake
	offset = _look + jitter


## Ideal right clamp for a player x — Mid-East civic first, then dig unlock.
func desired_limit_right(player_x: float) -> float:
	var mid_east_start := HollowLayout.PIT_RIGHT
	var civic_east_end := HollowLayout.civic_east_end()
	var hollow := float(LIMIT_RIGHT_HOLLOW)
	var mid_east_framed := civic_east_end + MID_EAST_FRAME_PAD
	var dig := float(LIMIT_RIGHT_DIG)
	# Ease across the full Mid Heart / Mouth crossing — a short Heart-East blend
	# expands limit_right too fast and jerks the clamped camera mid-Mouth.
	var approach_start := HollowLayout.HEART_WEST.x
	if player_x < approach_start:
		return hollow
	if player_x < mid_east_start:
		var approach_span := mid_east_start - approach_start
		var at := 0.0 if approach_span <= 0.0 else clampf((player_x - approach_start) / approach_span, 0.0, 1.0)
		at = at * at * (3.0 - 2.0 * at)
		return lerpf(hollow, mid_east_framed, at)
	# On Mid-East Landing / Approach: frame the civic east walk without unlocking dig.
	if player_x <= civic_east_end:
		return mid_east_framed
	# Past Mid-East Approach: blend dig framing open into Dig Front.
	var blend_end := civic_east_end + DIG_LIMIT_BLEND_SPAN
	var span := blend_end - civic_east_end
	if span <= 0.0:
		return dig
	var t := clampf((player_x - civic_east_end) / span, 0.0, 1.0)
	t = t * t * (3.0 - 2.0 * t)
	return lerpf(mid_east_framed, dig, t)


func _update_dig_limit(player_x: float) -> void:
	limit_right = int(round(desired_limit_right(player_x)))


func apply_shake(amplitude: float) -> void:
	_shake = maxf(_shake, amplitude)


func debug_shake() -> float:
	return _shake


func debug_look() -> Vector2:
	return _look


## Test helper — Hollow framing should not expose dig columns.
func debug_hollow_limit_right() -> int:
	return LIMIT_RIGHT_HOLLOW
