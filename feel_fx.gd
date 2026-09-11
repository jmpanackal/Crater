class_name FeelFx
extends RefCounted
## Quiet Act 1 juice — grit bursts, soft shake, micro dig hitch, restrained floats.
## Firmament digs stay softer/shorter than Pit digs (secrecy vs public danger).

const _FeelAudio := preload("res://feel_audio.gd")

## Last burst intensity (0..~1.4) for headless asserts.
static var last_dust_intensity: float = 0.0
static var last_dust_kind: StringName = &""
static var dust_spawn_count: int = 0
static var last_shake_amp: float = 0.0
static var shake_request_count: int = 0
static var last_hitstop_ms: float = 0.0
static var hitstop_request_count: int = 0
static var last_float_text: String = ""
static var last_float_kind: StringName = &""
static var float_spawn_count: int = 0

static var _hitstop_active := false


static func reset_debug() -> void:
	last_dust_intensity = 0.0
	last_dust_kind = &""
	dust_spawn_count = 0
	last_shake_amp = 0.0
	shake_request_count = 0
	last_hitstop_ms = 0.0
	hitstop_request_count = 0
	last_float_text = ""
	last_float_kind = &""
	float_spawn_count = 0
	_FeelAudio.reset_debug()
	# Tests must never leave timescale sticky.
	if _hitstop_active or not is_equal_approx(Engine.time_scale, 1.0):
		Engine.time_scale = 1.0
		_hitstop_active = false


## Firmament quieter, Pit heavier; mid-band digs sit in between.
static func dig_intensity(is_firmament: bool, is_pit: bool) -> float:
	if is_firmament:
		return 0.42
	if is_pit:
		return 1.15
	return 0.75


## Soft shake amps — Firmament barely notches; Pit slightly more; land scales with impact.
static func dig_shake_amp(is_firmament: bool, is_pit: bool) -> float:
	if is_firmament:
		return 0.12
	if is_pit:
		return 0.55
	return 0.28


static func land_shake_amp(impact: float) -> float:
	return clampf(0.25 + impact * 0.45, 0.2, 0.95)


## Micro hitch only — Firmament ~1 frame, Pit ~2–3 frames. Never stack.
static func dig_hitstop_ms(is_firmament: bool, is_pit: bool) -> float:
	if is_firmament:
		return 16.0
	if is_pit:
		return 40.0
	return 26.0


static func request_shake(host: Node, amplitude: float) -> void:
	last_shake_amp = amplitude
	shake_request_count += 1
	if host == null or not is_instance_valid(host) or amplitude <= 0.01:
		return
	var tree := host.get_tree()
	if tree == null:
		return
	var cams := tree.get_nodes_in_group("player_camera")
	for cam in cams:
		if cam != null and cam.has_method("apply_shake"):
			cam.apply_shake(amplitude)
			return


static func request_hitstop(host: Node, duration_ms: float) -> void:
	last_hitstop_ms = duration_ms
	hitstop_request_count += 1
	if host == null or not is_instance_valid(host) or duration_ms <= 0.5:
		return
	if _hitstop_active:
		return
	var tree := host.get_tree()
	if tree == null:
		return
	_hitstop_active = true
	# Near-pause (not hard 0) so rare systems keep a trickle of delta.
	Engine.time_scale = 0.08
	var sec := duration_ms / 1000.0
	var timer := tree.create_timer(sec, true, false, true)
	timer.timeout.connect(_end_hitstop)


static func _end_hitstop() -> void:
	Engine.time_scale = 1.0
	_hitstop_active = false


static func spawn_dig_dust(
	parent: Node,
	world_pos: Vector2,
	direction: Vector2i,
	is_firmament: bool,
	is_pit: bool
) -> void:
	var intensity := dig_intensity(is_firmament, is_pit)
	var color := Color(0.55, 0.48, 0.38, 0.55)
	if is_firmament:
		color = Color(0.62, 0.66, 0.64, 0.28) # quieter, cooler
	elif is_pit:
		color = Color(0.42, 0.36, 0.3, 0.7)
	_spawn_burst(parent, world_pos, Vector2(direction), intensity, color, &"dig")
	request_shake(parent, dig_shake_amp(is_firmament, is_pit))
	request_hitstop(parent, dig_hitstop_ms(is_firmament, is_pit))
	_FeelAudio.play_dig(parent, is_firmament, is_pit)


static func spawn_land_dust(parent: Node, world_pos: Vector2, impact: float = 1.0) -> void:
	var intensity := clampf(0.35 + impact * 0.35, 0.25, 0.85)
	_spawn_burst(
		parent,
		world_pos + Vector2(0, 14),
		Vector2(0, -1),
		intensity,
		Color(0.5, 0.45, 0.36, 0.4),
		&"land"
	)
	request_shake(parent, land_shake_amp(impact))
	_FeelAudio.play_land(parent, impact)


## Subdued haul confirm — copper tick, Firmament quieter than Pit.
static func spawn_salvage_float(
	parent: Node,
	world_pos: Vector2,
	amount: int,
	is_firmament: bool,
	is_pit: bool
) -> void:
	var alpha := 0.52
	var pop := 1.06
	if is_pit:
		alpha = 0.78
		pop = 1.14
	elif not is_firmament:
		alpha = 0.65
		pop = 1.1
	var color := Color(0.78, 0.58, 0.4, alpha)
	_spawn_float(parent, world_pos + Vector2(0, -6), "+%d" % maxi(amount, 1), color, pop, &"salvage")


## Rare Record find — slightly clearer than Salvage, still not arcade.
static func spawn_record_float(parent: Node, world_pos: Vector2, title: String = "Record") -> void:
	var text := title if title.strip_edges() != "" else "Record"
	_spawn_float(
		parent,
		world_pos + Vector2(0, -18),
		text,
		Color(0.7, 0.86, 0.82, 0.88),
		1.2,
		&"record"
	)


static func _spawn_float(
	parent: Node,
	world_pos: Vector2,
	text: String,
	color: Color,
	pop_scale: float,
	kind: StringName
) -> void:
	if parent == null or not is_instance_valid(parent):
		return
	last_float_text = text
	last_float_kind = kind
	float_spawn_count += 1

	var root := Node2D.new()
	root.name = "FeelFloat"
	root.z_index = 12
	parent.add_child(root)
	root.global_position = world_pos

	var label := Label.new()
	label.text = text
	label.add_theme_font_size_override("font_size", 12 if kind == &"salvage" else 13)
	label.modulate = color
	label.position = Vector2(-18, -8)
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(label)

	var tree := parent.get_tree()
	if tree == null:
		root.queue_free()
		return
	root.scale = Vector2(pop_scale, pop_scale)
	var life := 0.55 if kind == &"salvage" else 0.85
	var tween := tree.create_tween()
	tween.set_parallel(true)
	tween.tween_property(root, "global_position", world_pos + Vector2(0, -22), life).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.tween_property(root, "scale", Vector2.ONE, 0.18).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_property(label, "modulate:a", 0.0, life).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tween.chain().tween_callback(root.queue_free)


static func _spawn_burst(
	parent: Node,
	world_pos: Vector2,
	dir: Vector2,
	intensity: float,
	color: Color,
	kind: StringName
) -> void:
	if parent == null or not is_instance_valid(parent):
		return
	last_dust_intensity = intensity
	last_dust_kind = kind
	dust_spawn_count += 1

	var count := clampi(int(round(3.0 + intensity * 4.0)), 3, 8)
	var root := Node2D.new()
	root.name = "DustBurst"
	root.z_index = 8
	parent.add_child(root)
	root.global_position = world_pos

	var base_dir := dir
	if base_dir.length_squared() < 0.01:
		base_dir = Vector2(0, -1)
	base_dir = base_dir.normalized()

	for i in range(count):
		var grit := ColorRect.new()
		var size := 2.0 + intensity * 1.5 + float(i % 2)
		grit.size = Vector2(size, size)
		grit.position = Vector2(-size * 0.5, -size * 0.5)
		grit.color = color
		grit.mouse_filter = Control.MOUSE_FILTER_IGNORE
		root.add_child(grit)
		var spread := Vector2(randf_range(-1.0, 1.0), randf_range(-0.4, 0.6))
		var vel := (base_dir * (28.0 + intensity * 36.0) + spread * 40.0) * intensity
		_animate_grit(grit, vel, 0.22 + intensity * 0.12)

	# Free the burst root after particles finish.
	parent.get_tree().create_timer(0.45).timeout.connect(func() -> void:
		if is_instance_valid(root):
			root.queue_free()
	)


static func _animate_grit(grit: ColorRect, vel: Vector2, life: float) -> void:
	var tree := grit.get_tree()
	if tree == null:
		grit.queue_free()
		return
	var tween := tree.create_tween()
	tween.set_parallel(true)
	tween.tween_property(grit, "position", grit.position + vel, life).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.tween_property(grit, "modulate:a", 0.0, life).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tween.chain().tween_callback(grit.queue_free)
