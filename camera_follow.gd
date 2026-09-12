extends Camera2D
## Soft Hollow follow — look-ahead, drag deadzone, light shake.
## Keeps Firmament/Pit vertical climbs readable without snappy lock-on.
## Hollow clamps limit_right so dig-tile columns never peek into Wick framing.

const LOOK_AHEAD_X := 44.0
const LOOK_AHEAD_Y := 34.0
const LOOK_LERP := 5.2
const SHAKE_DECAY := 10.0

## Dig columns begin at TerrainLayer.DIG_START_X * TILE (1024). Hide until exit approach.
const LIMIT_RIGHT_HOLLOW := 1024
const LIMIT_RIGHT_DIG := 2200
## Blend dig framing open across the civic-excavation approach (not a hard unlock snap).
## Starts on the right mid terrace so Mid Heart / left Wick stay dig-free.
const DIG_LIMIT_BLEND_START_X := 880.0
## Fully open once past HollowLayout.EXIT_RIGHT into dig columns.
const DIG_LIMIT_BLEND_END_X := 1120.0

var _look := Vector2.ZERO
var _shake := 0.0


func _ready() -> void:
	add_to_group("player_camera")
	enabled = true
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


func _process(delta: float) -> void:
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


## Ideal right clamp for a player x — continuous across the dig approach.
func desired_limit_right(player_x: float) -> float:
	var span := DIG_LIMIT_BLEND_END_X - DIG_LIMIT_BLEND_START_X
	if span <= 0.0:
		return float(LIMIT_RIGHT_HOLLOW if player_x < DIG_LIMIT_BLEND_END_X else LIMIT_RIGHT_DIG)
	var t := clampf((player_x - DIG_LIMIT_BLEND_START_X) / span, 0.0, 1.0)
	# Smoothstep so the unlock eases in/out instead of linear popping.
	t = t * t * (3.0 - 2.0 * t)
	return lerpf(float(LIMIT_RIGHT_HOLLOW), float(LIMIT_RIGHT_DIG), t)


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
