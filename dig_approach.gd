extends Node2D
## Soft dig-site threshold — braced civic lateral-gallery mouth past Hollow exit.
## Visual-only craft; walkable geometry stays on Hollow Floor / Terrain.

const SoftWorldLabel := preload("res://soft_world_label.gd")


func _ready() -> void:
	_build_entry()


func _build_entry() -> void:
	if get_node_or_null("ThresholdPlank") != null:
		return

	var deck_y := HollowLayout.WICK_Y
	var hx := HollowLayout.HOLLOW_RIGHT
	var ex := HollowLayout.EXIT_RIGHT

	# Multi-board walk lip — leaving home decks toward braced side galleries.
	var plank := ColorRect.new()
	plank.name = "ThresholdPlank"
	plank.position = Vector2(hx, deck_y - 6.0)
	plank.size = Vector2(ex - hx, 10.0)
	plank.color = Color(0.32, 0.24, 0.16, 0.7)
	plank.mouse_filter = Control.MOUSE_FILTER_IGNORE
	plank.z_index = 1
	add_child(plank)

	var seam_x := hx + 10.0
	var seam_i := 0
	while seam_x < ex - 4.0:
		var seam := ColorRect.new()
		seam.name = "ThresholdSeam%d" % seam_i
		seam.position = Vector2(seam_x, deck_y - 5.0)
		seam.size = Vector2(2.0, 8.0)
		seam.color = Color(0.18, 0.12, 0.08, 0.55)
		seam.mouse_filter = Control.MOUSE_FILTER_IGNORE
		seam.z_index = 2
		add_child(seam)
		seam_x += 12.0
		seam_i += 1

	var lip := ColorRect.new()
	lip.name = "ThresholdLip"
	lip.position = Vector2(hx - 6.0, deck_y - 12.0)
	lip.size = Vector2(14.0, 8.0)
	lip.color = Color(0.45, 0.34, 0.22, 0.55)
	lip.mouse_filter = Control.MOUSE_FILTER_IGNORE
	lip.z_index = 1
	add_child(lip)

	# Braced tunnel mouth — civic excavation sideways into the right crater wall.
	var brace_l := ColorRect.new()
	brace_l.name = "ExcavationBraceL"
	brace_l.position = Vector2(hx + 8.0, deck_y - 56.0)
	brace_l.size = Vector2(6.0, 56.0)
	brace_l.color = Color(0.28, 0.2, 0.14, 0.95)
	brace_l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	brace_l.z_index = 2
	add_child(brace_l)
	var brace_r := ColorRect.new()
	brace_r.name = "ExcavationBraceR"
	brace_r.position = Vector2(ex - 16.0, deck_y - 56.0)
	brace_r.size = Vector2(6.0, 56.0)
	brace_r.color = Color(0.28, 0.2, 0.14, 0.95)
	brace_r.mouse_filter = Control.MOUSE_FILTER_IGNORE
	brace_r.z_index = 2
	add_child(brace_r)
	var lintel := ColorRect.new()
	lintel.name = "ExcavationLintel"
	lintel.position = Vector2(hx + 8.0, deck_y - 60.0)
	lintel.size = Vector2(ex - hx - 16.0, 6.0)
	lintel.color = Color(0.35, 0.26, 0.18, 0.9)
	lintel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	lintel.z_index = 2
	add_child(lintel)
	# Cross-brace / rock bolts.
	var cross := ColorRect.new()
	cross.name = "ExcavationCrossBrace"
	cross.position = Vector2(hx + 18.0, deck_y - 40.0)
	cross.size = Vector2(ex - hx - 36.0, 3.0)
	cross.color = Color(0.65, 0.41, 0.28, 0.7)
	cross.mouse_filter = Control.MOUSE_FILTER_IGNORE
	cross.z_index = 2
	add_child(cross)
	var cross2 := ColorRect.new()
	cross2.name = "ExcavationCrossBrace2"
	cross2.position = Vector2(hx + 22.0, deck_y - 28.0)
	cross2.size = Vector2(ex - hx - 44.0, 2.0)
	cross2.color = Color(0.5, 0.35, 0.24, 0.55)
	cross2.mouse_filter = Control.MOUSE_FILTER_IGNORE
	cross2.z_index = 2
	add_child(cross2)

	var post := ColorRect.new()
	post.name = "ThresholdPost"
	post.position = Vector2(hx - 3.0, deck_y - 28.0)
	post.size = Vector2(4.0, 22.0)
	post.color = Color(0.28, 0.2, 0.14, 0.95)
	post.mouse_filter = Control.MOUSE_FILTER_IGNORE
	post.z_index = 2
	add_child(post)

	# Crew warning board + tool rack (public excavation threshold).
	var sign := ColorRect.new()
	sign.name = "CrewSignage"
	sign.position = Vector2(hx + 18.0, deck_y - 78.0)
	sign.size = Vector2(32.0, 16.0)
	sign.color = Color(0.4, 0.32, 0.22, 0.85)
	sign.mouse_filter = Control.MOUSE_FILTER_IGNORE
	sign.z_index = 2
	add_child(sign)
	var warn := ColorRect.new()
	warn.name = "WarningBoard"
	warn.position = Vector2(hx + 22.0, deck_y - 74.0)
	warn.size = Vector2(24.0, 3.0)
	warn.color = Color(0.89, 0.65, 0.36, 0.7)
	warn.mouse_filter = Control.MOUSE_FILTER_IGNORE
	warn.z_index = 3
	add_child(warn)

	var rack := ColorRect.new()
	rack.name = "ToolRack"
	rack.position = Vector2(hx - 22.0, deck_y - 36.0)
	rack.size = Vector2(16.0, 30.0)
	rack.color = Color(0.3, 0.22, 0.16, 0.9)
	rack.mouse_filter = Control.MOUSE_FILTER_IGNORE
	rack.z_index = 2
	add_child(rack)
	for i in 3:
		var tool := ColorRect.new()
		tool.name = "Tool%d" % i
		tool.position = Vector2(hx - 20.0 + i * 5.0, deck_y - 34.0)
		tool.size = Vector2(2.0, 18.0)
		tool.color = Color(0.65, 0.41, 0.28, 0.8)
		tool.mouse_filter = Control.MOUSE_FILTER_IGNORE
		tool.z_index = 3
		add_child(tool)

	# Rail cart / crate stack — freight at the gallery mouth.
	var cart := ColorRect.new()
	cart.name = "RailCart"
	cart.position = Vector2(hx + 28.0, deck_y - 18.0)
	cart.size = Vector2(22.0, 14.0)
	cart.color = Color(0.45, 0.34, 0.24, 0.9)
	cart.mouse_filter = Control.MOUSE_FILTER_IGNORE
	cart.z_index = 2
	add_child(cart)
	var wheel := ColorRect.new()
	wheel.name = "CartWheel"
	wheel.position = Vector2(hx + 32.0, deck_y - 6.0)
	wheel.size = Vector2(6.0, 6.0)
	wheel.color = Color(0.2, 0.18, 0.16, 0.85)
	wheel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	wheel.z_index = 3
	add_child(wheel)
	var crate := ColorRect.new()
	crate.name = "ThresholdCrate"
	crate.position = Vector2(hx + 52.0, deck_y - 14.0)
	crate.size = Vector2(12.0, 12.0)
	crate.color = Color(0.38, 0.28, 0.18, 0.9)
	crate.mouse_filter = Control.MOUSE_FILTER_IGNORE
	crate.z_index = 2
	add_child(crate)

	# Side-tunnel rock mouth receding sideways — not a descent into the Mouth.
	var mouth := ColorRect.new()
	mouth.name = "TunnelMouth"
	mouth.position = Vector2(ex - 28.0, deck_y - 52.0)
	mouth.size = Vector2(36.0, 52.0)
	mouth.color = Color(0.06, 0.09, 0.09, 0.92)
	mouth.mouse_filter = Control.MOUSE_FILTER_IGNORE
	mouth.z_index = 1
	add_child(mouth)
	var tunnel_depth := ColorRect.new()
	tunnel_depth.name = "TunnelRecess"
	tunnel_depth.position = Vector2(ex - 10.0, deck_y - 44.0)
	tunnel_depth.size = Vector2(22.0, 40.0)
	tunnel_depth.color = Color(0.03, 0.05, 0.05, 0.95)
	tunnel_depth.mouse_filter = Control.MOUSE_FILTER_IGNORE
	tunnel_depth.z_index = 1
	add_child(tunnel_depth)

	var chasm := ColorRect.new()
	chasm.name = "ThresholdChasm"
	chasm.position = Vector2(hx + 4.0, deck_y + 6.0)
	chasm.size = Vector2(56.0, 140.0)
	chasm.color = Color(0.01, 0.02, 0.03, 0.92)
	chasm.mouse_filter = Control.MOUSE_FILTER_IGNORE
	chasm.z_index = 0
	add_child(chasm)

	var cool := ColorRect.new()
	cool.name = "ThresholdCoolMist"
	cool.position = Vector2(hx - 8.0, deck_y - 40.0)
	cool.size = Vector2(80.0, 50.0)
	cool.color = Color(0.2, 0.4, 0.45, 0.1)
	cool.mouse_filter = Control.MOUSE_FILTER_IGNORE
	cool.z_index = 0
	add_child(cool)

	var warm_fade := ColorRect.new()
	warm_fade.name = "ThresholdWarmFade"
	warm_fade.position = Vector2(hx - 48.0, deck_y - 24.0)
	warm_fade.size = Vector2(44.0, 24.0)
	warm_fade.color = Color(1.0, 0.7, 0.35, 0.08)
	warm_fade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	warm_fade.z_index = 0
	add_child(warm_fade)

	var label := Label.new()
	label.name = "ThresholdLabel"
	label.text = "Side galleries ahead"
	label.position = Vector2(hx + 4.0, deck_y - 92.0)
	label.add_theme_font_size_override("font_size", 12)
	label.set_script(SoftWorldLabel)
	label.set("show_radius", 180.0)
	label.set("far_alpha", 0.12)
	label.set("near_alpha", 0.72)
	label.modulate = Color(0.78, 0.72, 0.58, 0.7)
	label.z_index = 3
	add_child(label)


## Test helper — entry pieces exist and chasm is darker than the plank.
func entry_reads_as_threshold() -> bool:
	var plank := get_node_or_null("ThresholdPlank") as ColorRect
	var chasm := get_node_or_null("ThresholdChasm") as ColorRect
	var label := get_node_or_null("ThresholdLabel") as Label
	var cool := get_node_or_null("ThresholdCoolMist") as ColorRect
	var brace := get_node_or_null("ExcavationBraceL") as ColorRect
	var cart := get_node_or_null("RailCart") as ColorRect
	if plank == null or chasm == null or label == null or cool == null or brace == null:
		return false
	if cart == null:
		return false
	var text := label.text.to_lower()
	return chasm.color.a > plank.color.a and ("galler" in text or "excav" in text or "side" in text)
