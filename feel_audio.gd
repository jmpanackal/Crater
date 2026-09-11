class_name FeelAudio
extends RefCounted
## Procedural dig/land click stubs — no asset files.
## Slight pitch randomize; Firmament quieter / muffled, Pit fuller.

static var last_pitch: float = 1.0
static var last_volume_db: float = -80.0
static var last_kind: StringName = &""
static var dig_play_count: int = 0
static var land_play_count: int = 0

static var _click_stream: AudioStreamWAV


static func reset_debug() -> void:
	last_pitch = 1.0
	last_volume_db = -80.0
	last_kind = &""
	dig_play_count = 0
	land_play_count = 0


## Firmament quieter than mid; Pit louder. Pitch base differs by frontier.
static func dig_volume_db(is_firmament: bool, is_pit: bool) -> float:
	if is_firmament:
		return -22.0
	if is_pit:
		return -13.5
	return -17.5


static func dig_pitch_base(is_firmament: bool, is_pit: bool) -> float:
	if is_firmament:
		return 1.08 # thinner / quieter read
	if is_pit:
		return 0.86 # heavier
	return 0.96


static func play_dig(host: Node, is_firmament: bool, is_pit: bool) -> void:
	last_pitch = dig_pitch_base(is_firmament, is_pit) * randf_range(0.94, 1.06)
	last_volume_db = dig_volume_db(is_firmament, is_pit) + randf_range(-0.6, 0.6)
	last_kind = &"dig"
	dig_play_count += 1
	_play(host, last_pitch, last_volume_db)


static func play_land(host: Node, impact: float = 1.0) -> void:
	var soft := clampf(impact, 0.2, 1.4)
	last_pitch = randf_range(0.9, 1.08)
	last_volume_db = lerpf(-24.0, -15.5, (soft - 0.2) / 1.2)
	last_kind = &"land"
	land_play_count += 1
	_play(host, last_pitch, last_volume_db)


static func _play(host: Node, pitch: float, volume_db: float) -> void:
	if host == null or not is_instance_valid(host):
		return
	var tree := host.get_tree()
	if tree == null:
		return
	var player := AudioStreamPlayer.new()
	player.stream = _ensure_stream()
	player.pitch_scale = pitch
	player.volume_db = volume_db
	host.add_child(player)
	player.play()
	player.finished.connect(player.queue_free)


static func _ensure_stream() -> AudioStreamWAV:
	if _click_stream != null:
		return _click_stream
	var rate := 22050
	var n := int(rate * 0.032)
	var data := PackedByteArray()
	data.resize(n * 2)
	for i in range(n):
		var t := float(i) / float(rate)
		var env := 1.0 - float(i) / float(n)
		env *= env
		var tone := sin(t * TAU * 190.0) * 0.32 + sin(t * TAU * 420.0) * 0.12
		var grit := randf_range(-0.1, 0.1)
		var sample_f := clampf((tone + grit) * env, -1.0, 1.0)
		var sample := int(sample_f * 32767.0)
		data.encode_s16(i * 2, sample)
	var stream := AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = rate
	stream.stereo = false
	stream.data = data
	_click_stream = stream
	return stream
