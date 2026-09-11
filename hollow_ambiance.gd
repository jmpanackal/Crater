extends Node2D
## Runtime Hollow livability: pit drama, deck craft, district silhouettes, lantern grammar.
## No PixelLab — ColorRect / PointLight2D / soft particles that read as lived-in.

const WARM := Color(1.0, 0.72, 0.42, 1.0)
const COOL_PIT := Color(0.45, 0.7, 0.78, 1.0)
const WOOD := Color(0.42, 0.3, 0.2, 0.92)
const WOOD_DARK := Color(0.28, 0.2, 0.14, 0.95)
const ROPE := Color(0.55, 0.42, 0.28, 0.85)
const BEAM := Color(0.22, 0.16, 0.12, 0.75)

var _fog_t := 0.0
var _mist_base := Vector2.ZERO
var _mid_base := Vector2.ZERO
var _high_base := Vector2.ZERO
var _deep_base := Vector2.ZERO
var _veil_base := Vector2.ZERO
var _far_wall_base := Vector2.ZERO


func _ready() -> void:
	_deepen_pit_void()
	_paint_cliff_bands()
	_add_deck_architecture()
	_add_bridge_crossing()
	_style_district_props()
	_add_deck_glows()
	_add_warm_lights()
	_add_camera_vignette()
	_boost_pit_fog()
	_add_pit_spores()
	_cache_fog_bases()


func _process(delta: float) -> void:
	_fog_t += delta
	_drift_fog()


func _deepen_pit_void() -> void:
	var void_rect := get_node_or_null("PitVoid") as ColorRect
	if void_rect:
		# Stronger ink void — terraces keep detail; center stays deep.
		void_rect.color = Color(0.004, 0.007, 0.01, 1.0)
	# Distant shaft wall silhouette (depth cue, not a city panel).
	if get_node_or_null("PitFarWall") == null:
		var wall := ColorRect.new()
		wall.name = "PitFarWall"
		wall.position = Vector2(HollowLayout.PIT_LEFT + 88, -80)
		wall.size = Vector2(HollowLayout.PIT_RIGHT - HollowLayout.PIT_LEFT - 176, 700)
		wall.color = Color(0.03, 0.055, 0.06, 0.55)
		wall.mouse_filter = Control.MOUSE_FILTER_IGNORE
		wall.z_index = -1
		add_child(wall)
	# Soft lip ledge strips so the void edges against cliff faces.
	_band("PitLipShelfL", Rect2(HollowLayout.PIT_LEFT - 10, -40, 10, 680), Color(0.12, 0.18, 0.18, 0.85))
	_band("PitLipShelfR", Rect2(HollowLayout.PIT_RIGHT, -40, 10, 680), Color(0.11, 0.17, 0.17, 0.85))


func _paint_cliff_bands() -> void:
	# Subtle ledge stripes on cliff faces so terraces read without full art.
	_band("TerraceBandFarmsL", Rect2(0, HollowLayout.FARMS_Y - 6, HollowLayout.PIT_LEFT, 6), Color(0.16, 0.22, 0.2, 0.55))
	_band("TerraceBandWickL", Rect2(0, HollowLayout.WICK_Y - 6, HollowLayout.PIT_LEFT, 6), Color(0.18, 0.2, 0.18, 0.5))
	_band("TerraceBandWickR", Rect2(HollowLayout.PIT_RIGHT, HollowLayout.WICK_Y - 6, HollowLayout.HOLLOW_RIGHT - HollowLayout.PIT_RIGHT, 6), Color(0.17, 0.2, 0.19, 0.5))
	_band("TerraceBandCisternR", Rect2(HollowLayout.PIT_RIGHT, HollowLayout.CISTERN_Y - 6, HollowLayout.HOLLOW_RIGHT - HollowLayout.PIT_RIGHT, 6), Color(0.14, 0.2, 0.24, 0.55))
	# Inner pit lip — slightly lighter rim so the void edges.
	_band("PitLipLeft", Rect2(HollowLayout.PIT_LEFT - 3, -40, 3, 680), Color(0.22, 0.3, 0.3, 0.78))
	_band("PitLipRight", Rect2(HollowLayout.PIT_RIGHT, -40, 3, 680), Color(0.2, 0.28, 0.28, 0.78))


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


func _add_deck_architecture() -> void:
	if get_node_or_null("DeckArchitecture") != null:
		return
	var root := Node2D.new()
	root.name = "DeckArchitecture"
	root.z_index = 0
	add_child(root)

	# Underside beams / braces under walk decks (visual only — collision unchanged).
	_deck_underside(root, "FarmsUnder", 0.0, HollowLayout.PIT_LEFT - 64.0, HollowLayout.FARMS_Y)
	_deck_underside(root, "WickLeftUnder", 0.0, HollowLayout.PIT_LEFT, HollowLayout.WICK_Y)
	_deck_underside(root, "WickRightUnder", HollowLayout.PIT_RIGHT, HollowLayout.HOLLOW_RIGHT, HollowLayout.WICK_Y)
	_deck_underside(root, "CisternUnder", HollowLayout.PIT_RIGHT + 64.0, HollowLayout.EXIT_RIGHT - 64.0, HollowLayout.CISTERN_Y)

	# Pit-lip railings so ledges feel built (skip ladder openings).
	_pit_rail(root, "RailFarmsL", HollowLayout.PIT_LEFT - 6.0, HollowLayout.FARMS_Y, true)
	_pit_rail(root, "RailWickL", HollowLayout.PIT_LEFT - 6.0, HollowLayout.WICK_Y, true)
	_pit_rail(root, "RailWickR", HollowLayout.PIT_RIGHT + 2.0, HollowLayout.WICK_Y, false)
	_pit_rail(root, "RailCisternR", HollowLayout.PIT_RIGHT + 2.0, HollowLayout.CISTERN_Y, false)


func _deck_underside(parent: Node, under_name: String, x0: float, x1: float, deck_y: float) -> void:
	var group := Node2D.new()
	group.name = under_name
	parent.add_child(group)
	var width := x1 - x0
	if width < 40.0:
		return
	# PixelLab hollow_ledge tiles already carry timber joist underside on FloorVisual.
	# Keep a named marker so setting craft / tests still find deck architecture.
	var marker := Node2D.new()
	marker.name = "LedgeArt"
	marker.position = Vector2(x0, deck_y)
	group.add_child(marker)
	var width_mark := ColorRect.new()
	width_mark.name = "Joist"
	width_mark.position = Vector2(4.0, 2.0)
	width_mark.size = Vector2(maxf(width - 8.0, 8.0), 1.0)
	width_mark.color = Color(0, 0, 0, 0)
	width_mark.mouse_filter = Control.MOUSE_FILTER_IGNORE
	marker.add_child(width_mark)


func _pit_rail(parent: Node, rail_name: String, lip_x: float, deck_y: float, face_right: bool) -> void:
	var rail := Node2D.new()
	rail.name = rail_name
	parent.add_child(rail)
	var post_xs: Array[float] = []
	if face_right:
		# Left cliff looking into pit — posts along last ~80px of deck.
		post_xs = [lip_x - 72.0, lip_x - 40.0, lip_x - 8.0]
	else:
		post_xs = [lip_x + 8.0, lip_x + 40.0, lip_x + 72.0]
	for i in post_xs.size():
		var post := ColorRect.new()
		post.name = "Post%d" % i
		post.position = Vector2(post_xs[i], deck_y - 16.0)
		post.size = Vector2(3.0, 16.0)
		post.color = WOOD_DARK
		post.mouse_filter = Control.MOUSE_FILTER_IGNORE
		rail.add_child(post)
	# Rope line between first and last post.
	var rope := ColorRect.new()
	rope.name = "Rope"
	var left_x: float = post_xs[0]
	var right_x: float = post_xs[post_xs.size() - 1]
	rope.position = Vector2(minf(left_x, right_x) + 1.0, deck_y - 13.0)
	rope.size = Vector2(absf(right_x - left_x) + 2.0, 2.0)
	rope.color = ROPE
	rope.mouse_filter = Control.MOUSE_FILTER_IGNORE
	rail.add_child(rope)
	var rope2 := ColorRect.new()
	rope2.name = "RopeLow"
	rope2.position = Vector2(rope.position.x, deck_y - 7.0)
	rope2.size = rope.size
	rope2.color = ROPE.darkened(0.15)
	rope2.mouse_filter = Control.MOUSE_FILTER_IGNORE
	rail.add_child(rope2)


func _add_bridge_crossing() -> void:
	# Named RopeCrossing (not retired BridgePlanks bug-rect).
	if get_node_or_null("RopeCrossing") != null:
		return
	var root := Node2D.new()
	root.name = "RopeCrossing"
	root.z_index = 2
	add_child(root)

	var pit_l := HollowLayout.PIT_LEFT
	var pit_r := HollowLayout.PIT_RIGHT
	var deck_y := HollowLayout.WICK_Y
	var mid := (pit_l + pit_r) * 0.5

	# Anchor posts on each cliff lip.
	for side in [
		["PostL", pit_l - 4.0],
		["PostR", pit_r - 2.0],
	]:
		var post := ColorRect.new()
		post.name = String(side[0])
		post.position = Vector2(float(side[1]), deck_y - 22.0)
		post.size = Vector2(5.0, 22.0)
		post.color = WOOD_DARK
		post.mouse_filter = Control.MOUSE_FILTER_IGNORE
		root.add_child(post)

	# Hand ropes with slight mid sag.
	_bridge_rope(root, "HandRopeTop", pit_l, pit_r, deck_y - 18.0, 5.0)
	_bridge_rope(root, "HandRopeBot", pit_l, pit_r, deck_y - 10.0, 3.5)

	# Bridge deck art comes from FloorVisual (hollow_bridge wang tiles).
	# Keep named Plank* markers for setting craft / tests; no ColorRect fill.
	var bridge_tex: Texture2D = load("res://sprites/hollow_bridge/hollow_bridge_tiles_64.png")
	var atlas := AtlasTexture.new()
	if bridge_tex != null:
		atlas.atlas = bridge_tex
		atlas.region = Rect2(192, 0, 64, 64) # wang_12 in 4×4 sheet
	var x := pit_l
	var i := 0
	while x < pit_r:
		var plank := Sprite2D.new()
		plank.name = "Plank%d" % i
		plank.centered = false
		plank.position = Vector2(x, deck_y - HollowLayout.FLOOR_VISUAL_INSET)
		plank.texture = atlas if bridge_tex != null else null
		plank.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		plank.modulate = Color(1, 1, 1, 0.0) # FloorVisual owns pixels; marker only
		plank.z_index = -1
		root.add_child(plank)
		x += 64.0
		i += 1

	# Mid hanging lantern hint (visual bulb; light is separate).
	var bulb := ColorRect.new()
	bulb.name = "CrossingLamp"
	bulb.position = Vector2(mid - 3.0, deck_y - 28.0)
	bulb.size = Vector2(6.0, 8.0)
	bulb.color = Color(1.0, 0.78, 0.4, 0.95)
	bulb.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(bulb)


func _bridge_rope(parent: Node, rope_name: String, x0: float, x1: float, y: float, sag: float) -> void:
	# Approximate sag with three segments.
	var mid_x := (x0 + x1) * 0.5
	var seg_a := ColorRect.new()
	seg_a.name = rope_name + "A"
	seg_a.position = Vector2(x0, y)
	seg_a.size = Vector2(mid_x - x0, 2.0)
	seg_a.rotation = atan2(sag, mid_x - x0) * 0.5
	seg_a.color = ROPE
	seg_a.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(seg_a)
	var seg_b := ColorRect.new()
	seg_b.name = rope_name + "B"
	seg_b.position = Vector2(mid_x, y + sag)
	seg_b.size = Vector2(x1 - mid_x, 2.0)
	seg_b.rotation = -atan2(sag, x1 - mid_x) * 0.5
	seg_b.color = ROPE
	seg_b.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(seg_b)


func _style_district_props() -> void:
	_style_prop("PropFarms", Color(0.34, 0.5, 0.3, 1), Color(0.55, 0.7, 0.4, 1), &"farms")
	_style_prop("PropWick", Color(0.55, 0.36, 0.24, 1), Color(0.85, 0.55, 0.3, 1), &"wick")
	_style_prop("PropCistern", Color(0.3, 0.44, 0.55, 1), Color(0.45, 0.7, 0.85, 1), &"cistern")


func _style_prop(prop_name: String, body: Color, accent: Color, kind: StringName) -> void:
	var prop := get_node_or_null(prop_name) as ColorRect
	if prop == null:
		return
	prop.color = body
	if prop.get_node_or_null("Building") != null:
		# Ensure district extras exist even if Building was built in a prior run.
		_ensure_district_extras(prop, kind, accent)
		return
	# Drop older box accents if a prior session left them.
	for old in ["Accent", "Post"]:
		var n := prop.get_node_or_null(old)
		if n:
			n.queue_free()

	var building := Node2D.new()
	building.name = "Building"
	prop.add_child(building)
	match kind:
		&"farms":
			_build_farms_silhouette(building, prop.size, accent)
		&"wick":
			_build_wick_silhouette(building, prop.size, accent)
		_:
			_build_cistern_silhouette(building, prop.size, accent)

	_ensure_district_extras(prop, kind, accent)

	# Tiny contact blob so stubs read as sitting on the rock lip.
	if prop.get_node_or_null("ContactShadow") == null:
		var shadow := ColorRect.new()
		shadow.name = "ContactShadow"
		shadow.size = Vector2(prop.size.x + 8, 3)
		shadow.position = Vector2(-4, prop.size.y - 1)
		shadow.color = Color(0.02, 0.03, 0.04, 0.4)
		shadow.mouse_filter = Control.MOUSE_FILTER_IGNORE
		shadow.z_index = -1
		prop.add_child(shadow)


func _ensure_district_extras(prop: ColorRect, kind: StringName, accent: Color) -> void:
	if prop.get_node_or_null("DistrictExtras") != null:
		return
	var extras := Node2D.new()
	extras.name = "DistrictExtras"
	prop.add_child(extras)
	match kind:
		&"farms":
			_farms_planters(extras, prop.size, accent)
		&"wick":
			_wick_bench(extras, prop.size, accent)
		_:
			_cistern_basin(extras, prop.size, accent)


func _build_farms_silhouette(root: Node2D, size: Vector2, accent: Color) -> void:
	# Peaked shed — less "box," more glowbed hut.
	var roof := Polygon2D.new()
	roof.name = "Roof"
	roof.color = accent
	roof.polygon = PackedVector2Array([
		Vector2(-4, 2), Vector2(size.x * 0.5, -10), Vector2(size.x + 4, 2),
	])
	root.add_child(roof)
	var door := ColorRect.new()
	door.name = "Door"
	door.size = Vector2(8, 12)
	door.position = Vector2(size.x * 0.5 - 4, size.y - 12)
	door.color = accent.darkened(0.35)
	door.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(door)
	var bed := ColorRect.new()
	bed.name = "Glowbed"
	bed.size = Vector2(size.x * 0.55, 4)
	bed.position = Vector2(size.x + 2, size.y - 6)
	bed.color = Color(0.45, 0.75, 0.4, 0.85)
	bed.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(bed)


func _farms_planters(root: Node2D, size: Vector2, accent: Color) -> void:
	# Row of planter boxes — Farms identity from concept (crops, not crates).
	for i in 3:
		var box := ColorRect.new()
		box.name = "Planter%d" % i
		box.size = Vector2(10, 5)
		box.position = Vector2(size.x + 6 + i * 14, size.y - 7)
		box.color = Color(0.35, 0.28, 0.18, 0.95)
		box.mouse_filter = Control.MOUSE_FILTER_IGNORE
		root.add_child(box)
		var crop := ColorRect.new()
		crop.name = "Crop%d" % i
		crop.size = Vector2(6, 6)
		crop.position = Vector2(box.position.x + 2, box.position.y - 5)
		crop.color = accent.lightened(0.05 * i)
		crop.mouse_filter = Control.MOUSE_FILTER_IGNORE
		root.add_child(crop)


func _build_wick_silhouette(root: Node2D, size: Vector2, accent: Color) -> void:
	# Workshop block + chimney — copper workbench read.
	var roof := ColorRect.new()
	roof.name = "Roof"
	roof.size = Vector2(size.x + 6, 5)
	roof.position = Vector2(-3, -5)
	roof.color = accent
	roof.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(roof)
	var chimney := ColorRect.new()
	chimney.name = "Chimney"
	chimney.size = Vector2(6, 14)
	chimney.position = Vector2(size.x - 10, -16)
	chimney.color = accent.darkened(0.2)
	chimney.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(chimney)
	var awning := ColorRect.new()
	awning.name = "Awning"
	awning.size = Vector2(14, 3)
	awning.position = Vector2(size.x - 2, 6)
	awning.color = Color(0.7, 0.45, 0.28, 0.9)
	awning.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(awning)


func _wick_bench(root: Node2D, size: Vector2, accent: Color) -> void:
	# Workbench + hanging tool — workshop silhouette.
	var bench := ColorRect.new()
	bench.name = "Bench"
	bench.size = Vector2(18, 6)
	bench.position = Vector2(size.x + 4, size.y - 8)
	bench.color = Color(0.45, 0.32, 0.22, 0.95)
	bench.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(bench)
	var anvil := ColorRect.new()
	anvil.name = "Anvil"
	anvil.size = Vector2(8, 5)
	anvil.position = Vector2(size.x + 8, size.y - 12)
	anvil.color = Color(0.55, 0.4, 0.32, 1.0)
	anvil.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(anvil)
	var tool := ColorRect.new()
	tool.name = "Tool"
	tool.size = Vector2(2, 10)
	tool.position = Vector2(size.x + 22, size.y - 16)
	tool.color = accent.lightened(0.1)
	tool.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(tool)
	# Soft forge glow under awning.
	var forge := ColorRect.new()
	forge.name = "ForgeGlow"
	forge.size = Vector2(10, 8)
	forge.position = Vector2(size.x * 0.35, size.y - 14)
	forge.color = Color(1.0, 0.55, 0.25, 0.35)
	forge.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(forge)


func _build_cistern_silhouette(root: Node2D, size: Vector2, accent: Color) -> void:
	# Tank dome + pipe — waterworks, not a flat crate.
	var dome := ColorRect.new()
	dome.name = "Dome"
	dome.size = Vector2(size.x - 8, 8)
	dome.position = Vector2(4, -6)
	dome.color = accent
	dome.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(dome)
	var pipe := ColorRect.new()
	pipe.name = "Pipe"
	pipe.size = Vector2(18, 3)
	pipe.position = Vector2(size.x - 2, size.y * 0.35)
	pipe.color = Color(0.55, 0.7, 0.8, 0.95)
	pipe.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(pipe)
	var valve := ColorRect.new()
	valve.name = "Valve"
	valve.size = Vector2(5, 5)
	valve.position = Vector2(size.x + 12, size.y * 0.35 - 1)
	valve.color = accent.lightened(0.15)
	valve.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(valve)


func _cistern_basin(root: Node2D, size: Vector2, accent: Color) -> void:
	# Open basin + water surface — Cistern identity.
	var basin := ColorRect.new()
	basin.name = "Basin"
	basin.size = Vector2(22, 8)
	basin.position = Vector2(size.x + 8, size.y - 10)
	basin.color = Color(0.25, 0.35, 0.42, 0.95)
	basin.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(basin)
	var water := ColorRect.new()
	water.name = "Water"
	water.size = Vector2(18, 4)
	water.position = Vector2(basin.position.x + 2, basin.position.y + 2)
	water.color = Color(0.4, 0.75, 0.9, 0.7)
	water.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(water)
	var drip := ColorRect.new()
	drip.name = "Drip"
	drip.size = Vector2(2, 10)
	drip.position = Vector2(size.x + 4, size.y * 0.35 + 3)
	drip.color = accent.darkened(0.1)
	drip.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(drip)


func _add_deck_glows() -> void:
	# Soft amber pools on decks (names avoid retired Warm* bug-rects).
	_glow("GlowPoolFarms", Rect2(40, HollowLayout.FARMS_Y - 28, 120, 28), Color(1.0, 0.7, 0.35, 0.14))
	_glow("GlowPoolWick", Rect2(40, HollowLayout.WICK_Y - 28, 160, 28), Color(1.0, 0.65, 0.3, 0.13))
	_glow("GlowPoolBridge", Rect2(300, HollowLayout.WICK_Y - 22, 230, 22), Color(0.95, 0.7, 0.4, 0.1))
	_glow("GlowPoolWickRight", Rect2(620, HollowLayout.WICK_Y - 26, 140, 26), Color(1.0, 0.68, 0.35, 0.1))
	_glow("GlowPoolCistern", Rect2(680, HollowLayout.CISTERN_Y - 28, 160, 28), Color(0.7, 0.85, 1.0, 0.1))
	# Cool wash inside the shaft — lantern grammar contrast.
	_glow("GlowPoolPitCool", Rect2(HollowLayout.PIT_LEFT + 40, HollowLayout.WICK_Y + 40, 240, 180), Color(0.25, 0.45, 0.55, 0.06))


func _glow(node_name: String, rect: Rect2, color: Color) -> void:
	var existing := get_node_or_null(node_name) as ColorRect
	if existing != null:
		existing.color = color
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
	_point_light(root, "LightFarms", Vector2(72, HollowLayout.FARMS_Y - 40), tex, 0.7, 2.4)
	_point_light(root, "LightWick", Vector2(140, HollowLayout.WICK_Y - 40), tex, 0.8, 2.8)
	_point_light(root, "LightBridge", Vector2(416, HollowLayout.WICK_Y - 36), tex, 0.55, 2.2)
	_point_light(root, "LightWickRight", Vector2(700, HollowLayout.WICK_Y - 38), tex, 0.55, 2.3)
	_point_light(root, "LightCistern", Vector2(740, HollowLayout.CISTERN_Y - 40), tex, 0.55, 2.5, Color(0.65, 0.85, 1.0, 1.0))
	# Cool fill deep in the shaft — danger/depth read vs warm decks.
	_point_light(root, "LightPitCool", Vector2(416, HollowLayout.CISTERN_Y + 40), tex, 0.35, 3.2, COOL_PIT)
	# Visible lamp posts (not retired Lantern* bug-rect names).
	_lamp_post(root, "LampPostFarms", Vector2(68, HollowLayout.FARMS_Y - 22))
	_lamp_post(root, "LampPostWick", Vector2(136, HollowLayout.WICK_Y - 22))
	_lamp_post(root, "LampPostWickRight", Vector2(696, HollowLayout.WICK_Y - 22))
	_lamp_post(root, "LampPostCistern", Vector2(736, HollowLayout.CISTERN_Y - 22), Color(0.7, 0.88, 1.0, 0.95))


func _lamp_post(parent: Node, lamp_name: String, pos: Vector2, glow_color: Color = Color(1.0, 0.78, 0.42, 0.95)) -> void:
	var post := ColorRect.new()
	post.name = lamp_name
	post.position = pos
	post.size = Vector2(3, 18)
	post.color = WOOD_DARK
	post.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(post)
	var glow := ColorRect.new()
	glow.name = lamp_name + "Bulb"
	glow.position = pos + Vector2(-2, -6)
	glow.size = Vector2(7, 7)
	glow.color = glow_color
	glow.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(glow)


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
		deep.color = Color(0.02, 0.06, 0.08, 0.72)
		deep.position = Vector2(HollowLayout.PIT_LEFT, 420)
		deep.size = Vector2(HollowLayout.PIT_RIGHT - HollowLayout.PIT_LEFT, 320)
	var mid := get_node_or_null("PitFogMid") as ColorRect
	if mid:
		mid.color = Color(0.04, 0.1, 0.12, 0.34)
	if get_node_or_null("PitFogHigh") == null:
		var high := ColorRect.new()
		high.name = "PitFogHigh"
		high.position = Vector2(HollowLayout.PIT_LEFT, 80)
		high.size = Vector2(HollowLayout.PIT_RIGHT - HollowLayout.PIT_LEFT, 160)
		high.color = Color(0.05, 0.11, 0.13, 0.16)
		high.mouse_filter = Control.MOUSE_FILTER_IGNORE
		high.z_index = -1
		add_child(high)

	# Far depth wash — silhouette distance without a new camera.
	if get_node_or_null("FarHaze") == null:
		var far := ColorRect.new()
		far.name = "FarHaze"
		far.position = Vector2(HollowLayout.PIT_LEFT + 40, 40)
		far.size = Vector2(HollowLayout.PIT_RIGHT - HollowLayout.PIT_LEFT - 80, 220)
		far.color = Color(0.07, 0.13, 0.15, 0.1)
		far.mouse_filter = Control.MOUSE_FILTER_IGNORE
		far.z_index = -1
		add_child(far)

	# Extra mid-shaft veil — one more parallax band between high haze and deep fog.
	if get_node_or_null("PitShaftVeil") == null:
		var veil := ColorRect.new()
		veil.name = "PitShaftVeil"
		veil.position = Vector2(HollowLayout.PIT_LEFT + 28, 170)
		veil.size = Vector2(HollowLayout.PIT_RIGHT - HollowLayout.PIT_LEFT - 56, 260)
		veil.color = Color(0.035, 0.09, 0.11, 0.14)
		veil.mouse_filter = Control.MOUSE_FILTER_IGNORE
		veil.z_index = -1
		add_child(veil)

	# Soft teal mote band near far wall — restrained depth life.
	if get_node_or_null("PitMoteBand") == null:
		var motes := ColorRect.new()
		motes.name = "PitMoteBand"
		motes.position = Vector2(HollowLayout.PIT_LEFT + 100, 200)
		motes.size = Vector2(120, 280)
		motes.color = Color(0.15, 0.35, 0.38, 0.04)
		motes.mouse_filter = Control.MOUSE_FILTER_IGNORE
		motes.z_index = -1
		add_child(motes)


func _add_pit_spores() -> void:
	if get_node_or_null("PitSpores") != null:
		return
	var particles := GPUParticles2D.new()
	particles.name = "PitSpores"
	particles.position = Vector2((HollowLayout.PIT_LEFT + HollowLayout.PIT_RIGHT) * 0.5, 360)
	particles.z_index = 1
	particles.amount = 18
	particles.lifetime = 7.0
	particles.preprocess = 3.0
	particles.visibility_rect = Rect2(-200, -280, 400, 560)
	particles.texture = _spore_tex()
	var mat := ParticleProcessMaterial.new()
	mat.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_BOX
	mat.emission_box_extents = Vector3(110, 160, 0)
	mat.direction = Vector3(0, -1, 0)
	mat.spread = 30.0
	mat.initial_velocity_min = 4.0
	mat.initial_velocity_max = 12.0
	mat.gravity = Vector3(0, -2.5, 0)
	mat.scale_min = 0.35
	mat.scale_max = 0.85
	mat.color = Color(0.55, 0.85, 0.8, 0.35)
	particles.process_material = mat
	add_child(particles)


func _spore_tex() -> Texture2D:
	var img := Image.create(4, 4, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))
	img.set_pixel(1, 1, Color(1, 1, 1, 0.9))
	img.set_pixel(2, 1, Color(1, 1, 1, 0.55))
	img.set_pixel(1, 2, Color(1, 1, 1, 0.55))
	img.set_pixel(2, 2, Color(1, 1, 1, 0.35))
	return ImageTexture.create_from_image(img)


func _cache_fog_bases() -> void:
	var mist := get_node_or_null("Mist") as ColorRect
	if mist:
		_mist_base = mist.position
	var mid := get_node_or_null("PitFogMid") as ColorRect
	if mid:
		_mid_base = mid.position
	var high := get_node_or_null("PitFogHigh") as ColorRect
	if high:
		_high_base = high.position
	var deep := get_node_or_null("PitFogDeep") as ColorRect
	if deep:
		_deep_base = deep.position
	var veil := get_node_or_null("PitShaftVeil") as ColorRect
	if veil:
		_veil_base = veil.position
	var far_wall := get_node_or_null("PitFarWall") as ColorRect
	if far_wall:
		_far_wall_base = far_wall.position


func _drift_fog() -> void:
	# Soft parallax drift — depth without camera change (art-direction lock).
	var mist := get_node_or_null("Mist") as ColorRect
	if mist:
		mist.position = _mist_base + Vector2(sin(_fog_t * 0.22) * 6.0, cos(_fog_t * 0.15) * 2.0)
	var mid := get_node_or_null("PitFogMid") as ColorRect
	if mid:
		mid.position = _mid_base + Vector2(sin(_fog_t * 0.18 + 1.2) * 4.0, cos(_fog_t * 0.12) * 3.0)
	var high := get_node_or_null("PitFogHigh") as ColorRect
	if high:
		high.position = _high_base + Vector2(sin(_fog_t * 0.14 + 0.4) * 3.0, 0.0)
	var deep := get_node_or_null("PitFogDeep") as ColorRect
	if deep:
		deep.position = _deep_base + Vector2(sin(_fog_t * 0.1 + 2.0) * 2.0, cos(_fog_t * 0.08) * 4.0)
	var veil := get_node_or_null("PitShaftVeil") as ColorRect
	if veil:
		veil.position = _veil_base + Vector2(sin(_fog_t * 0.09 + 2.6) * 5.0, cos(_fog_t * 0.07 + 0.8) * 3.5)
		veil.modulate.a = 0.88 + sin(_fog_t * 0.25 + 1.1) * 0.12
	var far := get_node_or_null("FarHaze") as ColorRect
	if far:
		far.modulate.a = 0.85 + sin(_fog_t * 0.3) * 0.15
	var far_wall := get_node_or_null("PitFarWall") as ColorRect
	if far_wall:
		far_wall.position = _far_wall_base + Vector2(sin(_fog_t * 0.06) * 1.5, 0.0)
	var motes := get_node_or_null("PitMoteBand") as ColorRect
	if motes:
		motes.modulate.a = 0.75 + sin(_fog_t * 0.4 + 0.5) * 0.25


## Test helper — setting craft pieces that sell place without changing collision.
func setting_reads_as_place() -> bool:
	if get_node_or_null("RopeCrossing") == null:
		return false
	if get_node_or_null("DeckArchitecture") == null:
		return false
	if get_node_or_null("PitSpores") == null:
		return false
	if get_node_or_null("PitFarWall") == null:
		return false
	var farms := get_node_or_null("PropFarms/DistrictExtras/Planter0")
	var wick := get_node_or_null("PropWick/DistrictExtras/Bench")
	var cistern := get_node_or_null("PropCistern/DistrictExtras/Basin")
	return farms != null and wick != null and cistern != null
