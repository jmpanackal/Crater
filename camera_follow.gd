extends Camera2D
## Soft Hollow follow — look-ahead, drag deadzone, light shake.
## Keeps Firmament/Mouth vertical climbs readable without snappy lock-on.
## Static limits on all four sides pad ≥ half-viewport past stand extents so edge decks
## (Ashram top, Bottom-West lower, west dig lip) stay center-framed.

const LOOK_AHEAD_X := 44.0
const LOOK_AHEAD_Y := 34.0
const LOOK_LERP := 5.2
const SHAKE_DECAY := 10.0

## The camera is clamped to the map's real extents on every side (2026-10-01): west flank
## tip, east flank tip, Vaultward line above, Bottom-West lower below. Both walls are symmetric
## and nothing is hidden from view, so there is no per-region right clamp any more.

## Design play framing (tools / movement stability). Edge limits use at least
## half of this; live viewport half wins when the window is larger.
const DESIGN_VIEWPORT := Vector2(1280.0, 720.0)
const EDGE_PAD_X := DESIGN_VIEWPORT.x * 0.5 ## 640
const EDGE_PAD_Y := DESIGN_VIEWPORT.y * 0.5 ## 360
## Camera sits near body center (~16px below player origin on a 32px body).
const STAND_CENTER_SLACK := 32.0

## Dev overview zoom (press Z to cycle): 1.0 = normal play, then wider views, last = fit the
## whole map. Limits are lifted while zoomed out. A dev tool, not a player feature.
const DEV_ZOOMS: Array[float] = [1.0, 0.6, 0.35, 0.2, 0.0] ## 0.0 = fit the whole map
const DEV_KEY := KEY_Z

var _look := Vector2.ZERO
var _shake := 0.0
var _dev_index := 0
var _dev_label: Label


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
	_apply_play_edge_limits()
	var vp := get_viewport()
	if vp != null and not vp.size_changed.is_connected(_apply_play_edge_limits):
		vp.size_changed.connect(_apply_play_edge_limits)
	set_process_unhandled_key_input(true)


func _unhandled_key_input(event: InputEvent) -> void:
	var key := event as InputEventKey
	if key != null and key.pressed and not key.echo and key.physical_keycode == DEV_KEY:
		cycle_dev_zoom()
		get_viewport().set_input_as_handled()


func dev_zoom_index() -> int:
	return _dev_index


## Map extents the fit-the-whole-map view frames.
static func map_rect() -> Rect2:
	var x0 := HollowLayout.HIGH_WEST_DIG_LEFT
	var x1 := HollowLayout.EAST_FLANK_RIGHT
	var y0 := HollowLayout.VAULTWARD_Y - 320.0
	var y1 := HollowLayout.BOTTOM_WEST_LOWER_Y + 480.0
	return Rect2(x0, y0, x1 - x0, y1 - y0)


func cycle_dev_zoom() -> void:
	set_dev_zoom(_dev_index + 1)


func set_dev_zoom(index: int) -> void:
	_dev_index = index % DEV_ZOOMS.size()
	var z: float = DEV_ZOOMS[_dev_index]
	if _dev_index == 0:
		zoom = Vector2.ONE
		position_smoothing_enabled = true
		drag_horizontal_enabled = true
		drag_vertical_enabled = true
		_apply_play_edge_limits()
	else:
		if z <= 0.0:
			var screen := get_viewport().get_visible_rect().size
			var rect := map_rect()
			z = minf(screen.x / rect.size.x, screen.y / rect.size.y) * 0.94
			drag_horizontal_enabled = false
			drag_vertical_enabled = false
			position_smoothing_enabled = false
		else:
			drag_horizontal_enabled = true
			drag_vertical_enabled = true
			position_smoothing_enabled = true
		zoom = Vector2(z, z)
		limit_left = -100000
		limit_right = 100000
		limit_top = -100000
		limit_bottom = 100000
	_update_dev_label(z)


func _update_dev_label(z: float) -> void:
	if _dev_label == null:
		var layer := CanvasLayer.new()
		layer.layer = 90
		add_child(layer)
		_dev_label = Label.new()
		_dev_label.position = Vector2(380.0, 6.0)
		_dev_label.add_theme_font_size_override("font_size", 12)
		_dev_label.modulate = Color(0.95, 0.85, 0.55, 0.9)
		layer.add_child(_dev_label)
	_dev_label.visible = _dev_index != 0
	_dev_label.text = "DEV ZOOM %.2fx - Z cycles (whole map at the last step)" % z


func _physics_process(delta: float) -> void:
	var body := get_parent() as CharacterBody2D
	var want := Vector2.ZERO
	if body != null:
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
	if _dev_index != 0 and DEV_ZOOMS[_dev_index] <= 0.0 and body != null:
		# Whole-map view: park the frame on the map's centre instead of the player.
		offset = map_rect().get_center() - body.global_position - Vector2(16.0, 16.0)


## Half-viewport (design or live) pad past stand extents — does not touch limit_right.
func edge_pad() -> Vector2:
	var pad := Vector2(EDGE_PAD_X, EDGE_PAD_Y)
	var vp := get_viewport()
	if vp == null:
		return pad
	var screen := vp.get_visible_rect().size
	var zx := zoom.x if zoom.x > 0.001 else 1.0
	var zy := zoom.y if zoom.y > 0.001 else 1.0
	return Vector2(maxf(pad.x, screen.x * 0.5 / zx), maxf(pad.y, screen.y * 0.5 / zy))


func _apply_play_edge_limits() -> void:
	if _dev_index != 0:
		return
	var pad := edge_pad()
	# Godot clamps camera *center* to [limit + half_view, limit - half_view].
	# Pad past stand extents so the center can still sit on the player.
	# Top uses Vaultward (highest civic band); Ashram is below and stays covered.
	limit_left = int(floor(HollowLayout.HIGH_WEST_DIG_LEFT - pad.x - STAND_CENTER_SLACK))
	limit_top = int(floor(HollowLayout.VAULTWARD_Y - pad.y - STAND_CENTER_SLACK))
	limit_bottom = int(ceil(HollowLayout.BOTTOM_WEST_LOWER_Y + pad.y + STAND_CENTER_SLACK))
	limit_right = int(desired_limit_right())


## Right clamp: the east flank tip plus the half-viewport pad. (Kept as a function of the
## player's x so older callers keep working; it no longer depends on x.)
func desired_limit_right(_player_x: float = 0.0) -> float:
	return ceil(HollowLayout.EAST_FLANK_RIGHT + edge_pad().x + STAND_CENTER_SLACK)


func apply_shake(amplitude: float) -> void:
	_shake = maxf(_shake, amplitude)


func debug_shake() -> float:
	return _shake


func debug_look() -> Vector2:
	return _look


## Test helper — the static right clamp.
func debug_hollow_limit_right() -> int:
	return int(desired_limit_right())
