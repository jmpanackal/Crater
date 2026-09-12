extends Label
## Soft world placard — diegetic signage (post, hanging board, paint), not HUD chrome.

@export var show_radius: float = 140.0
@export var near_alpha: float = 0.92
@export var far_alpha: float = 0.38
## hanging | painted | arch — avoids large flat translucent label rectangles.
@export_enum("hanging", "painted", "arch") var sign_style: String = "hanging"

var _player: Node2D


func _ready() -> void:
	add_to_group("world_chrome")
	# Dark outline keeps type readable against rock without a full placard plate.
	add_theme_color_override("font_outline_color", Color(0.04, 0.06, 0.07, 0.92))
	add_theme_constant_override("outline_size", 3)
	modulate.a = far_alpha
	_player = get_tree().get_first_node_in_group("player") as Node2D
	# Strip legacy flat translucent SignPlate if present from older scenes.
	var legacy := get_node_or_null("SignPlate")
	if legacy:
		legacy.queue_free()
	if get_node_or_null("SignPost") == null and get_node_or_null("PaintMark") == null:
		call_deferred("_add_diegetic_sign")


func _add_diegetic_sign() -> void:
	if get_node_or_null("SignPost") != null or get_node_or_null("PaintMark") != null:
		return
	match sign_style:
		"painted":
			_add_paint_mark()
		"arch":
			_add_entry_arch()
		_:
			_add_hanging_sign()


func _add_hanging_sign() -> void:
	# Compact post + small hanging board — not a full-width translucent rect.
	var post := ColorRect.new()
	post.name = "SignPost"
	post.show_behind_parent = true
	post.mouse_filter = Control.MOUSE_FILTER_IGNORE
	post.color = Color(0.28, 0.2, 0.14, 0.92)
	post.position = Vector2(-10.0, -4.0)
	post.size = Vector2(3.0, 26.0)
	add_child(post)
	var arm := ColorRect.new()
	arm.name = "SignArm"
	arm.mouse_filter = Control.MOUSE_FILTER_IGNORE
	arm.color = Color(0.32, 0.24, 0.16, 0.88)
	arm.position = Vector2(-8.0, -2.0)
	arm.size = Vector2(14.0, 2.0)
	post.add_child(arm)
	var board := ColorRect.new()
	board.name = "HangBoard"
	board.mouse_filter = Control.MOUSE_FILTER_IGNORE
	board.color = Color(0.22, 0.18, 0.12, 0.55)
	board.position = Vector2(4.0, 2.0)
	board.size = Vector2(18.0, 10.0)
	post.add_child(board)
	var bolt := ColorRect.new()
	bolt.name = "Bolt"
	bolt.mouse_filter = Control.MOUSE_FILTER_IGNORE
	bolt.color = Color(0.5, 0.4, 0.28, 0.8)
	bolt.position = Vector2(1.0, 1.0)
	bolt.size = Vector2(2.0, 2.0)
	post.add_child(bolt)


func _add_paint_mark() -> void:
	# Faint painted wall streak + bolt — reads as cave marking, not a UI plate.
	var mark := ColorRect.new()
	mark.name = "PaintMark"
	mark.show_behind_parent = true
	mark.mouse_filter = Control.MOUSE_FILTER_IGNORE
	mark.color = Color(0.2, 0.22, 0.18, 0.35)
	mark.position = Vector2(-4.0, 4.0)
	mark.size = Vector2(10.0, 3.0)
	add_child(mark)
	var bolt := ColorRect.new()
	bolt.name = "PaintBolt"
	bolt.mouse_filter = Control.MOUSE_FILTER_IGNORE
	bolt.color = Color(0.45, 0.36, 0.26, 0.7)
	bolt.position = Vector2(-6.0, 2.0)
	bolt.size = Vector2(2.0, 2.0)
	mark.add_child(bolt)


func _add_entry_arch() -> void:
	var post := ColorRect.new()
	post.name = "SignPost"
	post.show_behind_parent = true
	post.mouse_filter = Control.MOUSE_FILTER_IGNORE
	post.color = Color(0.26, 0.22, 0.18, 0.9)
	post.position = Vector2(-12.0, -6.0)
	post.size = Vector2(4.0, 30.0)
	add_child(post)
	var arch := ColorRect.new()
	arch.name = "ArchLintel"
	arch.mouse_filter = Control.MOUSE_FILTER_IGNORE
	arch.color = Color(0.35, 0.28, 0.2, 0.85)
	arch.position = Vector2(-2.0, -6.0)
	arch.size = Vector2(22.0, 4.0)
	post.add_child(arch)
	var mark := ColorRect.new()
	mark.name = "PaintMark"
	mark.mouse_filter = Control.MOUSE_FILTER_IGNORE
	mark.color = Color(0.18, 0.2, 0.17, 0.4)
	mark.position = Vector2(4.0, 4.0)
	mark.size = Vector2(12.0, 2.0)
	post.add_child(mark)


func _process(_delta: float) -> void:
	if _player == null or not is_instance_valid(_player):
		_player = get_tree().get_first_node_in_group("player") as Node2D
	if _player == null:
		modulate.a = far_alpha
		return
	var near := global_position.distance_to(_player.global_position) <= show_radius
	modulate.a = near_alpha if near else far_alpha
