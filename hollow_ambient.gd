extends Node2D
## An ambient person: a placeholder figure that stands, works or walks a short beat. Not
## interactable, no collision, no schedule, no canon. It only makes a place read as occupied
## (docs/hollow-chunk-map.md: "residents use shared spaces, crews handle carts and tools"). Anyone
## who should talk is a hollow_npc.gd instead.
## Origin is the feet on the deck. Animation runs only while the player is near.

@export var role: StringName = &"resident"
@export var activity: StringName = &"idle"
## Walk range either side of the start x for `patrol`.
@export var patrol_range := 0.0
@export var face := 1.0

const WALK_SPEED := 28.0
const NEAR_X := 1800.0
const NEAR_Y := 700.0

var _t := 0.0
var _home_x := 0.0
var _dir := 1.0
var _player: Node2D
var _check := 0.0
var _awake := true


func _ready() -> void:
	_home_x = position.x
	_t = randf() * 10.0
	_dir = face if face != 0.0 else 1.0
	z_index = 1
	_player = get_tree().get_first_node_in_group("player") as Node2D


func _process(delta: float) -> void:
	_check -= delta
	if _check <= 0.0:
		_check = 0.25
		if _player == null or not is_instance_valid(_player):
			_player = get_tree().get_first_node_in_group("player") as Node2D
		_awake = _player == null or (absf(_player.global_position.x - global_position.x) < NEAR_X and absf(_player.global_position.y - global_position.y) < NEAR_Y)
	if not _awake:
		return
	_t += delta
	if activity == &"patrol" and patrol_range > 0.0:
		position.x += _dir * WALK_SPEED * delta
		if position.x > _home_x + patrol_range:
			_dir = -1.0
		elif position.x < _home_x - patrol_range:
			_dir = 1.0
		face = _dir
	queue_redraw()


func _draw() -> void:
	var colors: Dictionary = HollowDressing.ROLES.get(role, HollowDressing.ROLES[&"resident"])
	var body: Color = colors["body"]
	var accent: Color = colors["accent"]
	var f := face if face != 0.0 else 1.0
	var sit := activity == &"sit"
	var bob := 0.0
	var step := 0.0
	match activity:
		&"patrol":
			step = sin(_t * 8.0) * 2.0
			bob = absf(sin(_t * 8.0)) * 1.0
		&"idle", &"stand", &"point":
			bob = sin(_t * 1.6) * 0.6
	var top := 12.0 if sit else 0.0
	# legs
	if not sit:
		draw_rect(Rect2(-5.0 + step, -9.0, 4.0, 9.0), body.darkened(0.35))
		draw_rect(Rect2(1.0 - step, -9.0, 4.0, 9.0), body.darkened(0.35))
	else:
		draw_rect(Rect2(-6.0, -6.0, 12.0, 6.0), body.darkened(0.35))
	# torso
	draw_rect(Rect2(-7.0, -24.0 + top + bob, 14.0, 16.0 - top * 0.3), body)
	draw_rect(Rect2(-7.0, -12.0 + top * 0.5, 14.0, 2.0), accent)
	# head
	draw_rect(Rect2(-5.0, -33.0 + top + bob, 10.0, 9.0), Color(0.78, 0.62, 0.48))
	draw_rect(Rect2(-5.0, -33.0 + top + bob, 10.0, 3.0), body.darkened(0.45))
	if role == &"warden":
		draw_rect(Rect2(-6.0, -35.0 + top + bob, 12.0, 3.0), accent)
	if role == &"foreman":
		draw_rect(Rect2(-6.0, -35.0 + top + bob, 12.0, 3.0), accent)
	# the arm that does the work
	var shoulder := Vector2(0.0, -21.0 + top + bob)
	var hand := shoulder + Vector2(7.0 * f, 9.0)
	var tool_len := 0.0
	match activity:
		&"hammer":
			var s := sin(_t * 7.0)
			hand = shoulder + Vector2(10.0 * f, -4.0 + s * 7.0)
			tool_len = 9.0
			if s > 0.9:
				draw_circle(shoulder + Vector2(14.0 * f, 8.0), 1.8, Color(1.0, 0.8, 0.4, 0.9))
		&"dig":
			var s2 := sin(_t * 3.4)
			hand = shoulder + Vector2((9.0 + maxf(s2, 0.0) * 5.0) * f, -8.0 + (1.0 - maxf(s2, 0.0)) * 8.0)
			tool_len = 12.0
		&"sort":
			hand = shoulder + Vector2((6.0 + sin(_t * 2.2) * 5.0) * f, 8.0)
		&"cook":
			hand = shoulder + Vector2(9.0 * f, 4.0 + sin(_t * 4.0) * 2.0)
		&"hang_laundry":
			hand = shoulder + Vector2(6.0 * f, -9.0 + sin(_t * 2.4) * 3.0)
		&"point":
			hand = shoulder + Vector2(12.0 * f, -2.0)
		&"patrol":
			hand = shoulder + Vector2(7.0 * f, 8.0)
			if role == &"courier":
				draw_rect(Rect2(6.0 * f - 6.0, -22.0 + bob, 12.0, 8.0), accent.darkened(0.2))
	draw_line(shoulder, hand, body.lightened(0.15), 3.0)
	if tool_len > 0.0:
		var dir := (hand - shoulder).normalized()
		draw_line(hand, hand + dir * tool_len, Color(0.55, 0.4, 0.26), 2.0)
		draw_rect(Rect2(hand + dir * tool_len - Vector2(3.0, 2.0), Vector2(6.0, 4.0)), Color(0.62, 0.64, 0.66))
