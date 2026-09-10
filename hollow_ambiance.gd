extends Node2D
## Runtime Hollow livability: terrace bands, warm deck pools, soft vignette.
## No PixelLab — ColorRect / PointLight2D placeholders that read as lived-in.

const WARM := Color(1.0, 0.72, 0.42, 1.0)


func _ready() -> void:
	_paint_cliff_bands()
	_style_district_props()
	_add_deck_glows()
	_add_warm_lights()
	_add_camera_vignette()
	_boost_pit_fog()


func _paint_cliff_bands() -> void:
	# Subtle ledge stripes on cliff faces so terraces read without full art.
	_band("TerraceBandFarmsL", Rect2(0, HollowLayout.FARMS_Y - 6, HollowLayout.PIT_LEFT, 6), Color(0.16, 0.22, 0.2, 0.55))
	_band("TerraceBandWickL", Rect2(0, HollowLayout.WICK_Y - 6, HollowLayout.PIT_LEFT, 6), Color(0.18, 0.2, 0.18, 0.5))
	_band("TerraceBandWickR", Rect2(HollowLayout.PIT_RIGHT, HollowLayout.WICK_Y - 6, HollowLayout.HOLLOW_RIGHT - HollowLayout.PIT_RIGHT, 6), Color(0.17, 0.2, 0.19, 0.5))
	_band("TerraceBandCisternR", Rect2(HollowLayout.PIT_RIGHT, HollowLayout.CISTERN_Y - 6, HollowLayout.HOLLOW_RIGHT - HollowLayout.PIT_RIGHT, 6), Color(0.14, 0.2, 0.24, 0.55))
	# Inner pit lip — slightly lighter rim so the void edges.
	_band("PitLipLeft", Rect2(HollowLayout.PIT_LEFT - 3, -40, 3, 680), Color(0.2, 0.28, 0.28, 0.7))
	_band("PitLipRight", Rect2(HollowLayout.PIT_RIGHT, -40, 3, 680), Color(0.18, 0.26, 0.26, 0.7))


func _band(node_name: String, rect: Rect2, color: Color) -> void:
	if get_node_or_null(node_name) != null:
		return
	var r := ColorRect.new()
	r.name = node_name
	r.position = rect.position
	r.size = rect.size
	r.color = color
	r.mouse_filter = Control.MOUSE_FILTER_IGNORE
	r.z_index = -2
	add_child(r)


func _style_district_props() -> void:
	_style_prop("PropFarms", Color(0.34, 0.5, 0.3, 1), Color(0.55, 0.7, 0.4, 1))
	_style_prop("PropWick", Color(0.55, 0.36, 0.24, 1), Color(0.85, 0.55, 0.3, 1))
	_style_prop("PropCistern", Color(0.3, 0.44, 0.55, 1), Color(0.45, 0.7, 0.85, 1))


func _style_prop(prop_name: String, body: Color, accent: Color) -> void:
	var prop := get_node_or_null(prop_name) as ColorRect
	if prop == null:
		return
	prop.color = body
	if prop.get_node_or_null("Accent") != null:
		return
	var lip := ColorRect.new()
	lip.name = "Accent"
	lip.size = Vector2(prop.size.x, 4)
	lip.position = Vector2(0, -4)
	lip.color = accent
	lip.mouse_filter = Control.MOUSE_FILTER_IGNORE
	prop.add_child(lip)
	var post := ColorRect.new()
	post.name = "Post"
	post.size = Vector2(4, prop.size.y + 4)
	post.position = Vector2(-4, -4)
	post.color = accent.darkened(0.25)
	post.mouse_filter = Control.MOUSE_FILTER_IGNORE
	prop.add_child(post)


func _add_deck_glows() -> void:
	# Soft amber pools on decks (names avoid retired Warm* bug-rects).
	_glow("GlowPoolFarms", Rect2(40, HollowLayout.FARMS_Y - 28, 120, 28), Color(1.0, 0.7, 0.35, 0.1))
	_glow("GlowPoolWick", Rect2(40, HollowLayout.WICK_Y - 28, 160, 28), Color(1.0, 0.65, 0.3, 0.09))
	_glow("GlowPoolBridge", Rect2(300, HollowLayout.WICK_Y - 22, 230, 22), Color(0.95, 0.7, 0.4, 0.07))
	_glow("GlowPoolCistern", Rect2(680, HollowLayout.CISTERN_Y - 28, 160, 28), Color(0.7, 0.85, 1.0, 0.08))


func _glow(node_name: String, rect: Rect2, color: Color) -> void:
	if get_node_or_null(node_name) != null:
		return
	var r := ColorRect.new()
	r.name = node_name
	r.position = rect.position
	r.size = rect.size
	r.color = color
	r.mouse_filter = Control.MOUSE_FILTER_IGNORE
	r.z_index = 0
	add_child(r)


func _add_warm_lights() -> void:
	if get_node_or_null("AmbianceLights") != null:
		return
	var root := Node2D.new()
	root.name = "AmbianceLights"
	root.z_index = 3
	add_child(root)
	var tex := _radial_light_tex()
	_point_light(root, "LightFarms", Vector2(72, HollowLayout.FARMS_Y - 40), tex, 0.55, 2.2)
	_point_light(root, "LightWick", Vector2(140, HollowLayout.WICK_Y - 40), tex, 0.65, 2.6)
	_point_light(root, "LightBridge", Vector2(416, HollowLayout.WICK_Y - 36), tex, 0.4, 2.0)
	_point_light(root, "LightCistern", Vector2(740, HollowLayout.CISTERN_Y - 40), tex, 0.5, 2.4, Color(0.65, 0.85, 1.0, 1.0))


func _point_light(
	parent: Node,
	light_name: String,
	pos: Vector2,
	tex: Texture2D,
	energy: float,
	scale: float,
	color: Color = WARM
) -> void:
	var light := PointLight2D.new()
	light.name = light_name
	light.position = pos
	light.texture = tex
	light.texture_scale = scale
	light.energy = energy
	light.color = color
	light.range_item_cull_mask = 1
	parent.add_child(light)


func _radial_light_tex() -> Texture2D:
	var img := Image.create(64, 64, false, Image.FORMAT_RGBA8)
	var center := Vector2(31.5, 31.5)
	for y in range(64):
		for x in range(64):
			var d := Vector2(x, y).distance_to(center) / 32.0
			var a := clampf(1.0 - d, 0.0, 1.0)
			a = a * a
			img.set_pixel(x, y, Color(1, 1, 1, a))
	return ImageTexture.create_from_image(img)


func _add_camera_vignette() -> void:
	# Screen-space soft vignette on the play UI layer (quiet INMOST-lite edge).
	var play_root := get_parent()
	var ui := play_root.get_node_or_null("UI") if play_root else null
	if ui == null or ui.get_node_or_null("HollowVignette") != null:
		return
	var vig := Control.new()
	vig.name = "HollowVignette"
	vig.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	vig.mouse_filter = Control.MOUSE_FILTER_IGNORE
	vig.z_index = -1
	ui.add_child(vig)
	# Four edge strips instead of a shader — cheap soft frame.
	_edge(vig, "Top", Color(0.02, 0.05, 0.06, 0.32), 0.0, 0.0, 1.0, 0.0, 0, 0, 0, 52)
	_edge(vig, "Bottom", Color(0.01, 0.03, 0.04, 0.38), 0.0, 1.0, 1.0, 1.0, 0, -72, 0, 0)
	_edge(vig, "Left", Color(0.02, 0.04, 0.05, 0.26), 0.0, 0.0, 0.0, 1.0, 0, 0, 56, 0)
	_edge(vig, "Right", Color(0.02, 0.04, 0.05, 0.2), 1.0, 0.0, 1.0, 1.0, -64, 0, 0, 0)


func _edge(
	parent: Control,
	edge_name: String,
	color: Color,
	a_l: float,
	a_t: float,
	a_r: float,
	a_b: float,
	o_l: float,
	o_t: float,
	o_r: float,
	o_b: float
) -> void:
	var r := ColorRect.new()
	r.name = edge_name
	r.anchor_left = a_l
	r.anchor_top = a_t
	r.anchor_right = a_r
	r.anchor_bottom = a_b
	r.offset_left = o_l
	r.offset_top = o_t
	r.offset_right = o_r
	r.offset_bottom = o_b
	r.color = color
	r.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(r)


func _boost_pit_fog() -> void:
	var deep := get_node_or_null("PitFogDeep") as ColorRect
	if deep:
		deep.color = Color(0.03, 0.08, 0.1, 0.62)
	var mid := get_node_or_null("PitFogMid") as ColorRect
	if mid:
		mid.color = Color(0.05, 0.12, 0.14, 0.28)
	if get_node_or_null("PitFogHigh") == null:
		var high := ColorRect.new()
		high.name = "PitFogHigh"
		high.position = Vector2(HollowLayout.PIT_LEFT, 80)
		high.size = Vector2(HollowLayout.PIT_RIGHT - HollowLayout.PIT_LEFT, 160)
		high.color = Color(0.06, 0.12, 0.14, 0.12)
		high.mouse_filter = Control.MOUSE_FILTER_IGNORE
		high.z_index = -1
		add_child(high)
