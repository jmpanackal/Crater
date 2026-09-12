extends Node2D
## Runtime Hollow livability: Devil's Mouth drama, carved rooms, district kits, lantern grammar.
## No PixelLab — ColorRect / PointLight2D / soft particles that read as lived-in.

const WARM := Color(0.89, 0.65, 0.36, 1.0) # #E3A65B
const COOL_PIT := Color(0.35, 0.55, 0.62, 1.0)
const CISTERN_LIGHT := Color(0.55, 0.71, 0.77, 1.0) # #8BB5C4
const GROWTH := Color(0.36, 0.61, 0.51, 1.0) # #5C9B82
const COPPER := Color(0.65, 0.41, 0.28, 1.0) # #A56848
const PATINA := Color(0.31, 0.51, 0.49, 1.0) # #4E837C
const ROCK := Color(0.23, 0.25, 0.24, 1.0) # #3B403C
const WOOD := Color(0.42, 0.3, 0.2, 0.92)
const WOOD_DARK := Color(0.28, 0.2, 0.14, 0.95)
const ROPE := Color(0.55, 0.42, 0.28, 0.85)
const VOID_INK := Color(0.035, 0.078, 0.098, 1.0) # #091419

var _fog_t := 0.0
var _mist_base := Vector2.ZERO
var _mid_base := Vector2.ZERO
var _high_base := Vector2.ZERO
var _deep_base := Vector2.ZERO
var _veil_base := Vector2.ZERO
var _far_wall_base := Vector2.ZERO
var _sway_nodes: Array[CanvasItem] = []
var _pulse_nodes: Array[CanvasItem] = []


func _ready() -> void:
	_deepen_pit_void()
	_paint_cliff_bands()
	_add_carved_rooms()
	_add_terrace_punctuation()
	_add_deck_architecture()
	_add_heart_structure()
	_add_bridge_crossing()
	_add_vaultward_gate()
	_add_society_life_cues()
	_style_district_props()
	_add_mid_heart_props()
	_add_deck_glows()
	_add_warm_lights()
	_add_district_ambience()
	_add_camera_vignette()
	_boost_pit_fog()
	_add_pit_spores()
	_cache_fog_bases()


func _process(delta: float) -> void:
	_fog_t += delta
	_drift_fog()
	_animate_district_life(delta)


func _deepen_pit_void() -> void:
	var void_rect := get_node_or_null("PitVoid") as ColorRect
	if void_rect:
		void_rect.color = VOID_INK
	if get_node_or_null("PitFarWall") == null:
		var wall := ColorRect.new()
		wall.name = "PitFarWall"
		wall.position = Vector2(HollowLayout.PIT_LEFT + 88, -80)
		wall.size = Vector2(HollowLayout.PIT_RIGHT - HollowLayout.PIT_LEFT - 176, HollowLayout.SEEP_Y + 120.0)
		wall.color = Color(0.03, 0.055, 0.06, 0.55)
		wall.mouse_filter = Control.MOUSE_FILTER_IGNORE
		wall.z_index = -1
		add_child(wall)
	# Impact strata + fractured hull remnants (crash crater, not supernatural throat).
	if get_node_or_null("PitStrataL") == null:
		_band("PitStrataL", Rect2(HollowLayout.PIT_LEFT + 18, 60, 6, 520), Color(0.08, 0.12, 0.12, 0.45))
		_band("PitStrataR", Rect2(HollowLayout.PIT_RIGHT - 28, 90, 5, 480), Color(0.07, 0.11, 0.11, 0.4))
		_band("HullRibFar", Rect2(HollowLayout.PIT_LEFT + 130, 140, 4, 220), Color(0.18, 0.22, 0.2, 0.22))
		_band("HullRibFar2", Rect2(HollowLayout.PIT_LEFT + 148, 200, 3, 160), Color(0.16, 0.2, 0.19, 0.18))
	if get_node_or_null("ImpactStrata") == null:
		var strata := Node2D.new()
		strata.name = "ImpactStrata"
		strata.z_index = -1
		add_child(strata)
		# Dim radial impact banding — fractured rock seams from the crash.
		var bands := [
			[HollowLayout.PIT_LEFT + 40.0, 100.0, 8.0, 90.0, 0.12],
			[HollowLayout.PIT_LEFT + 55.0, 220.0, 5.0, 70.0, 0.1],
			[HollowLayout.PIT_RIGHT - 70.0, 160.0, 7.0, 110.0, 0.11],
			[HollowLayout.PIT_LEFT + 95.0, 340.0, 6.0, 80.0, 0.09],
			[HollowLayout.PIT_RIGHT - 95.0, 380.0, 5.0, 95.0, 0.08],
		]
		for i in bands.size():
			var b: Array = bands[i]
			var seam := ColorRect.new()
			seam.name = "ImpactSeam%d" % i
			seam.position = Vector2(float(b[0]), float(b[1]))
			seam.size = Vector2(float(b[2]), float(b[3]))
			seam.color = Color(0.1, 0.14, 0.13, float(b[4]))
			seam.mouse_filter = Control.MOUSE_FILTER_IGNORE
			strata.add_child(seam)
		# Sparse fractured hull plate remnants (vague wreck scale).
		var plate := ColorRect.new()
		plate.name = "HullPlateFar"
		plate.position = Vector2(HollowLayout.PIT_LEFT + 170.0, 280.0)
		plate.size = Vector2(28.0, 6.0)
		plate.rotation = -0.35
		plate.color = Color(0.22, 0.2, 0.18, 0.16)
		plate.mouse_filter = Control.MOUSE_FILTER_IGNORE
		strata.add_child(plate)
		var plate2 := ColorRect.new()
		plate2.name = "HullPlateFar2"
		plate2.position = Vector2(HollowLayout.PIT_RIGHT - 210.0, 420.0)
		plate2.size = Vector2(22.0, 5.0)
		plate2.rotation = 0.28
		plate2.color = Color(0.2, 0.22, 0.2, 0.14)
		plate2.mouse_filter = Control.MOUSE_FILTER_IGNORE
		strata.add_child(plate2)
		var rib3 := ColorRect.new()
		rib3.name = "HullRibFar3"
		rib3.position = Vector2(HollowLayout.PIT_LEFT + 200.0, 460.0)
		rib3.size = Vector2(3.0, 90.0)
		rib3.color = Color(0.15, 0.18, 0.17, 0.14)
		rib3.mouse_filter = Control.MOUSE_FILTER_IGNORE
		strata.add_child(rib3)
		# Faint distant haze — depth without filling the void.
		var haze := ColorRect.new()
		haze.name = "DistantHazeBand"
		haze.position = Vector2(HollowLayout.PIT_LEFT + 70.0, 300.0)
		haze.size = Vector2(HollowLayout.PIT_RIGHT - HollowLayout.PIT_LEFT - 140.0, 80.0)
		haze.color = Color(0.06, 0.11, 0.13, 0.1)
		haze.mouse_filter = Control.MOUSE_FILTER_IGNORE
		strata.add_child(haze)
		# Additional fractured impact seam (crash strata, not organic throat).
		var seam_deep := ColorRect.new()
		seam_deep.name = "ImpactSeamDeep"
		seam_deep.position = Vector2(HollowLayout.PIT_LEFT + 110.0, 500.0)
		seam_deep.size = Vector2(4.0, 70.0)
		seam_deep.color = Color(0.09, 0.13, 0.12, 0.1)
		seam_deep.mouse_filter = Control.MOUSE_FILTER_IGNORE
		strata.add_child(seam_deep)
		# Vague embedded hull scar — too distant to read as ship in Act 1.
		var scar := ColorRect.new()
		scar.name = "HullScarFar"
		scar.position = Vector2(HollowLayout.PIT_RIGHT - 160.0, 240.0)
		scar.size = Vector2(36.0, 4.0)
		scar.rotation = 0.4
		scar.color = Color(0.18, 0.16, 0.14, 0.12)
		scar.mouse_filter = Control.MOUSE_FILTER_IGNORE
		strata.add_child(scar)
	_band("PitLipShelfL", Rect2(HollowLayout.PIT_LEFT - 10, -40, 10, HollowLayout.SEEP_Y + 80.0), Color(0.12, 0.18, 0.18, 0.85))
	_band("PitLipShelfR", Rect2(HollowLayout.PIT_RIGHT, -40, 10, HollowLayout.SEEP_Y + 80.0), Color(0.11, 0.17, 0.17, 0.85))


func _paint_cliff_bands() -> void:
	var left := HollowLayout.HOLLOW_LEFT
	_band(
		"TerraceBandFarmsL",
		Rect2(left, HollowLayout.FARMS_Y - 6, HollowLayout.PIT_LEFT - left, 6),
		Color(0.16, 0.22, 0.2, 0.55)
	)
	_band(
		"TerraceBandGlowSubL",
		Rect2(left, HollowLayout.GLOW_SUB_Y - 6, HollowLayout.PIT_LEFT - left, 6),
		Color(0.15, 0.21, 0.19, 0.45)
	)
	_band(
		"TerraceBandWickL",
		Rect2(left, HollowLayout.WICK_Y - 6, HollowLayout.PIT_LEFT - left, 6),
		Color(0.18, 0.2, 0.18, 0.5)
	)
	_band(
		"TerraceBandAllotL",
		Rect2(left, HollowLayout.MID_ALLOT_Y - 6, HollowLayout.PIT_LEFT - left, 6),
		Color(0.17, 0.19, 0.17, 0.42)
	)
	_band(
		"TerraceBandLowerL",
		Rect2(left + 64.0, HollowLayout.LOWER_WORK_Y - 6, HollowLayout.PIT_LEFT - left - 64.0, 6),
		Color(0.16, 0.18, 0.17, 0.5)
	)
	_band(
		"TerraceBandWickR",
		Rect2(
			HollowLayout.PIT_RIGHT,
			HollowLayout.WICK_Y - 6,
			HollowLayout.HOLLOW_RIGHT - HollowLayout.PIT_RIGHT,
			6
		),
		Color(0.17, 0.2, 0.19, 0.5)
	)
	_band(
		"TerraceBandLowerR",
		Rect2(
			HollowLayout.PIT_RIGHT,
			HollowLayout.LOWER_WORK_Y - 6,
			HollowLayout.HOLLOW_RIGHT - HollowLayout.PIT_RIGHT,
			6
		),
		Color(0.15, 0.18, 0.18, 0.48)
	)
	_band(
		"TerraceBandCisternR",
		Rect2(
			HollowLayout.PIT_RIGHT,
			HollowLayout.CISTERN_Y - 6,
			HollowLayout.HOLLOW_RIGHT - HollowLayout.PIT_RIGHT,
			6
		),
		Color(0.14, 0.2, 0.24, 0.55)
	)
	_band("PitLipLeft", Rect2(HollowLayout.PIT_LEFT - 3, -80, 3, 820), Color(0.22, 0.3, 0.3, 0.78))
	_band("PitLipRight", Rect2(HollowLayout.PIT_RIGHT, -80, 3, 820), Color(0.2, 0.28, 0.28, 0.78))


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


func _add_carved_rooms() -> void:
	if get_node_or_null("CarvedRooms") != null:
		return
	var root := Node2D.new()
	root.name = "CarvedRooms"
	root.z_index = 0
	add_child(root)

	# Glowbeds grow gallery cutaway (same plane, deeper into left rock).
	_carved_bay(
		root,
		"GlowbedsGallery",
		HollowLayout.HOLLOW_LEFT,
		HollowLayout.FARMS_GALLERY_END,
		HollowLayout.FARMS_Y,
		Color(0.12, 0.18, 0.16, 0.55),
		GROWTH
	)
	# Wickwork carved work bay.
	_carved_bay(
		root,
		"WickworkBay",
		HollowLayout.HOLLOW_LEFT,
		HollowLayout.WICK_BAY_END,
		HollowLayout.WICK_Y,
		Color(0.16, 0.14, 0.12, 0.55),
		COPPER
	)
	# Cistern service alcove toward exit (cutaway into right rock).
	_carved_bay(
		root,
		"CisternAlcove",
		HollowLayout.CISTERN_ALCOVE_START,
		HollowLayout.EXIT_RIGHT,
		HollowLayout.CISTERN_Y,
		Color(0.1, 0.14, 0.18, 0.5),
		CISTERN_LIGHT
	)


func _add_terrace_punctuation() -> void:
	## Break long horizontal walks with lookout bays, visual steps, short ramps,
	## and room-entrance frames — visual / non-blocking (collision unchanged).
	if get_node_or_null("TerracePunctuation") != null:
		return
	var root := Node2D.new()
	root.name = "TerracePunctuation"
	root.z_index = 1
	add_child(root)

	# Glowbeds: gallery→terrace ramp wedge + lookout near pit lip + side door.
	_visual_ramp(root, "FarmsGalleryRamp", HollowLayout.FARMS_GALLERY_END - 8.0, HollowLayout.FARMS_Y, 28.0)
	_lookout_bay(root, "FarmsLookout", HollowLayout.PIT_LEFT - 96.0, HollowLayout.FARMS_Y, GROWTH)
	_room_entrance(root, "FarmsSideDoor", -80.0, HollowLayout.FARMS_Y, GROWTH)
	_step_riser(root, "FarmsStepA", -40.0, HollowLayout.FARMS_Y)
	_step_riser(root, "FarmsStepB", 40.0, HollowLayout.FARMS_Y)

	# Wickwork: bay→street ramp + lookout + Mid Heart approach steps.
	_visual_ramp(root, "WickBayRamp", HollowLayout.WICK_BAY_END - 8.0, HollowLayout.WICK_Y, 32.0)
	_lookout_bay(root, "WickLookoutL", HollowLayout.PIT_LEFT - 110.0, HollowLayout.WICK_Y, COPPER)
	_room_entrance(root, "WickSideDoor", -60.0, HollowLayout.WICK_Y, COPPER)
	_step_riser(root, "WickStepA", 40.0, HollowLayout.WICK_Y)
	_lookout_bay(root, "WickLookoutR", HollowLayout.PIT_RIGHT + 48.0, HollowLayout.WICK_Y, WARM)
	_step_riser(root, "WickRightStep", 720.0, HollowLayout.WICK_Y)
	_room_entrance(root, "WickRightDoor", 780.0, HollowLayout.WICK_Y, COPPER)

	# Cistern: service steps + lookout toward Mouth + alcove entrance cue.
	_lookout_bay(root, "CisternLookout", HollowLayout.PIT_RIGHT + 80.0, HollowLayout.CISTERN_Y, CISTERN_LIGHT)
	_step_riser(root, "CisternStepA", 700.0, HollowLayout.CISTERN_Y)
	_step_riser(root, "CisternStepB", 780.0, HollowLayout.CISTERN_Y)
	_visual_ramp(root, "CisternAlcoveRamp", 868.0, HollowLayout.CISTERN_Y, 24.0)
	_room_entrance(root, "CisternServiceDoor", 860.0, HollowLayout.CISTERN_Y, CISTERN_LIGHT)


func _visual_ramp(parent: Node, ramp_name: String, x: float, deck_y: float, width: float) -> void:
	var ramp := ColorRect.new()
	ramp.name = ramp_name
	ramp.position = Vector2(x, deck_y - 4.0)
	ramp.size = Vector2(width, 4.0)
	ramp.color = Color(0.28, 0.24, 0.18, 0.55)
	ramp.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(ramp)
	var wedge := ColorRect.new()
	wedge.name = ramp_name + "Wedge"
	wedge.position = Vector2(x + 4.0, deck_y - 7.0)
	wedge.size = Vector2(width * 0.45, 3.0)
	wedge.color = Color(0.22, 0.2, 0.16, 0.45)
	wedge.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(wedge)


func _lookout_bay(parent: Node, bay_name: String, x: float, deck_y: float, accent: Color) -> void:
	var bay := Node2D.new()
	bay.name = bay_name
	parent.add_child(bay)
	var niche := ColorRect.new()
	niche.name = "Niche"
	niche.position = Vector2(x, deck_y - 40.0)
	niche.size = Vector2(36.0, 36.0)
	niche.color = Color(0.1, 0.12, 0.12, 0.4)
	niche.mouse_filter = Control.MOUSE_FILTER_IGNORE
	niche.z_index = -1
	bay.add_child(niche)
	var rail := ColorRect.new()
	rail.name = "BayRail"
	rail.position = Vector2(x + 2.0, deck_y - 14.0)
	rail.size = Vector2(32.0, 2.0)
	rail.color = WOOD
	rail.mouse_filter = Control.MOUSE_FILTER_IGNORE
	bay.add_child(rail)
	var post := ColorRect.new()
	post.name = "BayPost"
	post.position = Vector2(x + 16.0, deck_y - 18.0)
	post.size = Vector2(3.0, 16.0)
	post.color = WOOD_DARK
	post.mouse_filter = Control.MOUSE_FILTER_IGNORE
	bay.add_child(post)
	var lamp := ColorRect.new()
	lamp.name = "BayLamp"
	lamp.position = Vector2(x + 14.0, deck_y - 36.0)
	lamp.size = Vector2(5.0, 5.0)
	lamp.color = Color(accent.r, accent.g, accent.b, 0.85)
	lamp.mouse_filter = Control.MOUSE_FILTER_IGNORE
	bay.add_child(lamp)
	_pulse_nodes.append(lamp)


func _room_entrance(parent: Node, door_name: String, x: float, deck_y: float, accent: Color) -> void:
	var frame := ColorRect.new()
	frame.name = door_name
	frame.position = Vector2(x, deck_y - 44.0)
	frame.size = Vector2(12.0, 44.0)
	frame.color = Color(0.08, 0.09, 0.09, 0.65)
	frame.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(frame)
	var post_l := ColorRect.new()
	post_l.name = door_name + "PostL"
	post_l.position = Vector2(x - 2.0, deck_y - 46.0)
	post_l.size = Vector2(3.0, 46.0)
	post_l.color = WOOD_DARK
	post_l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(post_l)
	var post_r := ColorRect.new()
	post_r.name = door_name + "PostR"
	post_r.position = Vector2(x + 11.0, deck_y - 46.0)
	post_r.size = Vector2(3.0, 46.0)
	post_r.color = WOOD_DARK
	post_r.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(post_r)
	var lintel := ColorRect.new()
	lintel.name = door_name + "Lintel"
	lintel.position = Vector2(x - 3.0, deck_y - 50.0)
	lintel.size = Vector2(18.0, 4.0)
	lintel.color = accent.darkened(0.15)
	lintel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(lintel)


func _step_riser(parent: Node, step_name: String, x: float, deck_y: float) -> void:
	## Shallow carved step cue on the terrace face — does not change collision.
	var riser := ColorRect.new()
	riser.name = step_name
	riser.position = Vector2(x, deck_y - 2.0)
	riser.size = Vector2(18.0, 2.0)
	riser.color = Color(0.35, 0.3, 0.24, 0.55)
	riser.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(riser)
	var shadow := ColorRect.new()
	shadow.name = step_name + "Shade"
	shadow.position = Vector2(x, deck_y)
	shadow.size = Vector2(18.0, 3.0)
	shadow.color = Color(0.08, 0.08, 0.07, 0.35)
	shadow.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(shadow)


func _carved_bay(
	parent: Node,
	bay_name: String,
	x0: float,
	x1: float,
	deck_y: float,
	wall_color: Color,
	accent: Color
) -> void:
	var bay := Node2D.new()
	bay.name = bay_name
	parent.add_child(bay)
	var width := x1 - x0
	if width < 40.0:
		return
	# Rock overhang / ceiling so the room reads as carved into crater wall.
	var overhang := ColorRect.new()
	overhang.name = "Overhang"
	overhang.position = Vector2(x0 - 2.0, deck_y - 78.0)
	overhang.size = Vector2(width + 4.0, 14.0)
	overhang.color = Color(ROCK.r, ROCK.g, ROCK.b, 0.95)
	overhang.mouse_filter = Control.MOUSE_FILTER_IGNORE
	bay.add_child(overhang)
	var ceiling := ColorRect.new()
	ceiling.name = "Ceiling"
	ceiling.position = Vector2(x0 + 4.0, deck_y - 72.0)
	ceiling.size = Vector2(width - 8.0, 10.0)
	ceiling.color = ROCK
	ceiling.mouse_filter = Control.MOUSE_FILTER_IGNORE
	bay.add_child(ceiling)
	var back := ColorRect.new()
	back.name = "BackWall"
	back.position = Vector2(x0 + 2.0, deck_y - 64.0)
	back.size = Vector2(width - 4.0, 58.0)
	back.color = wall_color
	back.mouse_filter = Control.MOUSE_FILTER_IGNORE
	back.z_index = -1
	bay.add_child(back)
	# Inner side wall thickness (cutaway depth cue).
	var side := ColorRect.new()
	side.name = "SideWall"
	side.position = Vector2(x0 + 2.0, deck_y - 64.0)
	side.size = Vector2(6.0, 58.0)
	side.color = wall_color.darkened(0.15)
	side.mouse_filter = Control.MOUSE_FILTER_IGNORE
	bay.add_child(side)
	# Door opening toward the public terrace — enterable-looking cutaway.
	var door_x := x1 - 14.0 if x1 < HollowLayout.PIT_LEFT else x0 + 2.0
	var door_w := 14.0
	var frame_l := ColorRect.new()
	frame_l.name = "DoorFrameL"
	frame_l.position = Vector2(door_x, deck_y - 52.0)
	frame_l.size = Vector2(4.0, 52.0)
	frame_l.color = WOOD_DARK
	frame_l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	bay.add_child(frame_l)
	var frame_r := ColorRect.new()
	frame_r.name = "DoorFrameR"
	frame_r.position = Vector2(door_x + door_w - 4.0, deck_y - 52.0)
	frame_r.size = Vector2(4.0, 52.0)
	frame_r.color = WOOD_DARK
	frame_r.mouse_filter = Control.MOUSE_FILTER_IGNORE
	bay.add_child(frame_r)
	var lintel := ColorRect.new()
	lintel.name = "Lintel"
	lintel.position = Vector2(door_x - 2.0, deck_y - 56.0)
	lintel.size = Vector2(door_w + 4.0, 5.0)
	lintel.color = accent.darkened(0.2)
	lintel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	bay.add_child(lintel)
	# Timber braces + rock bolts under overhang.
	var brace := ColorRect.new()
	brace.name = "TimberBrace"
	brace.position = Vector2(x0 + width * 0.35, deck_y - 64.0)
	brace.size = Vector2(3.0, 40.0)
	brace.color = WOOD
	brace.mouse_filter = Control.MOUSE_FILTER_IGNORE
	bay.add_child(brace)
	var brace2 := ColorRect.new()
	brace2.name = "TimberBrace2"
	brace2.position = Vector2(x0 + width * 0.65, deck_y - 60.0)
	brace2.size = Vector2(3.0, 36.0)
	brace2.color = WOOD_DARK
	brace2.mouse_filter = Control.MOUSE_FILTER_IGNORE
	bay.add_child(brace2)
	# Hanging cable / hose inside the carved bay.
	var cable := ColorRect.new()
	cable.name = "HangCable"
	cable.position = Vector2(x0 + width * 0.5, deck_y - 68.0)
	cable.size = Vector2(2.0, 28.0)
	cable.color = Color(0.35, 0.32, 0.26, 0.7)
	cable.mouse_filter = Control.MOUSE_FILTER_IGNORE
	bay.add_child(cable)
	_sway_nodes.append(cable)
	# Storage crates / work stacks (district-flavored via accent).
	var crate := ColorRect.new()
	crate.name = "StorageCrate"
	crate.position = Vector2(x0 + 18.0, deck_y - 14.0)
	crate.size = Vector2(16.0, 12.0)
	crate.color = accent.darkened(0.25)
	crate.mouse_filter = Control.MOUSE_FILTER_IGNORE
	bay.add_child(crate)
	var crate2 := ColorRect.new()
	crate2.name = "StorageCrate2"
	crate2.position = Vector2(x0 + 38.0, deck_y - 11.0)
	crate2.size = Vector2(12.0, 9.0)
	crate2.color = WOOD_DARK
	crate2.mouse_filter = Control.MOUSE_FILTER_IGNORE
	bay.add_child(crate2)
	# Threshold lip — shallow step into the cutaway (visual only).
	var thresh := ColorRect.new()
	thresh.name = "Threshold"
	thresh.position = Vector2(door_x - 2.0, deck_y - 3.0)
	thresh.size = Vector2(door_w + 4.0, 3.0)
	thresh.color = Color(0.32, 0.28, 0.22, 0.75)
	thresh.mouse_filter = Control.MOUSE_FILTER_IGNORE
	bay.add_child(thresh)


func _add_deck_architecture() -> void:
	if get_node_or_null("DeckArchitecture") != null:
		return
	var root := Node2D.new()
	root.name = "DeckArchitecture"
	root.z_index = 0
	add_child(root)

	_deck_underside(
		root, "FarmsUnder", HollowLayout.HOLLOW_LEFT, HollowLayout.PIT_LEFT - 64.0, HollowLayout.FARMS_Y
	)
	_deck_underside(root, "WickLeftUnder", HollowLayout.HOLLOW_LEFT, HollowLayout.PIT_LEFT, HollowLayout.WICK_Y)
	_deck_underside(
		root, "WickRightUnder", HollowLayout.PIT_RIGHT, HollowLayout.HOLLOW_RIGHT, HollowLayout.WICK_Y
	)
	_deck_underside(
		root,
		"CisternUnder",
		HollowLayout.PIT_RIGHT + 64.0,
		HollowLayout.EXIT_RIGHT - 64.0,
		HollowLayout.CISTERN_Y
	)

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
	# Sparse rock-bolted underbeams so decks feel suspended.
	var beam_x := x0 + 24.0
	var i := 0
	while beam_x < x1 - 24.0:
		var beam := ColorRect.new()
		beam.name = "Beam%d" % i
		beam.position = Vector2(beam_x, deck_y + 2.0)
		beam.size = Vector2(3.0, 18.0)
		beam.color = WOOD_DARK
		beam.mouse_filter = Control.MOUSE_FILTER_IGNORE
		group.add_child(beam)
		beam_x += 96.0
		i += 1


func _pit_rail(parent: Node, rail_name: String, lip_x: float, deck_y: float, face_right: bool) -> void:
	var rail := Node2D.new()
	rail.name = rail_name
	parent.add_child(rail)
	var post_xs: Array[float] = []
	if face_right:
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


func _add_heart_structure() -> void:
	# Upper / Lower Heart silhouettes + cables (Mid Heart is the playable cluster).
	if get_node_or_null("HeartStructure") != null:
		return
	var root := Node2D.new()
	root.name = "HeartStructure"
	root.z_index = -1
	add_child(root)

	var mid_x := (HollowLayout.PIT_LEFT + HollowLayout.PIT_RIGHT) * 0.5
	# Upper Heart silhouette — faint suspended deck in the upper civic band.
	var upper := ColorRect.new()
	upper.name = "UpperHeartDeck"
	upper.position = Vector2(mid_x - 70.0, HollowLayout.UPPER_RES_Y + 20.0)
	upper.size = Vector2(140.0, 8.0)
	upper.color = Color(0.2, 0.18, 0.15, 0.35)
	upper.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(upper)
	var upper_rail := ColorRect.new()
	upper_rail.name = "UpperHeartRail"
	upper_rail.position = Vector2(mid_x - 66.0, HollowLayout.UPPER_RES_Y + 8.0)
	upper_rail.size = Vector2(132.0, 2.0)
	upper_rail.color = Color(0.35, 0.28, 0.2, 0.3)
	upper_rail.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(upper_rail)

	# Lower Heart / freight hint on the lower working band.
	var lower := ColorRect.new()
	lower.name = "LowerHeartDeck"
	lower.position = Vector2(mid_x - 50.0, HollowLayout.LOWER_WORK_Y - 8.0)
	lower.size = Vector2(100.0, 6.0)
	lower.color = Color(0.15, 0.16, 0.18, 0.4)
	lower.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(lower)

	# Tension cables / truss stays explaining suspension.
	for i in 4:
		var cable := ColorRect.new()
		cable.name = "StayCable%d" % i
		var side := -1.0 if i % 2 == 0 else 1.0
		var ox := mid_x + side * (40.0 + i * 18.0)
		cable.position = Vector2(ox, HollowLayout.UPPER_RES_Y + 24.0)
		cable.size = Vector2(2.0, HollowLayout.LOWER_WORK_Y - HollowLayout.UPPER_RES_Y - 40.0 + i * 8.0)
		cable.rotation = side * 0.12
		cable.color = Color(0.25, 0.22, 0.18, 0.45)
		cable.mouse_filter = Control.MOUSE_FILTER_IGNORE
		root.add_child(cable)

	# Rock-bolted truss under Mid Heart bridge approach.
	var truss := ColorRect.new()
	truss.name = "MidHeartTruss"
	truss.position = Vector2(HollowLayout.PIT_LEFT + 20.0, HollowLayout.WICK_Y + 4.0)
	truss.size = Vector2(HollowLayout.PIT_RIGHT - HollowLayout.PIT_LEFT - 40.0, 3.0)
	truss.color = Color(0.22, 0.16, 0.12, 0.55)
	truss.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(truss)


func _add_vaultward_gate() -> void:
	## Locked late-Act-1 route beneath the Firmament — readable, not enterable.
	if get_node_or_null("VaultwardGate") != null:
		return
	var root := Node2D.new()
	root.name = "VaultwardGate"
	root.z_index = 2
	add_child(root)

	var gate := ColorRect.new()
	gate.name = "GateBoard"
	gate.position = Vector2(HollowLayout.HOLLOW_LEFT + 200.0, HollowLayout.VAULTWARD_Y - 48.0)
	gate.size = Vector2(72.0, 48.0)
	gate.color = Color(0.22, 0.2, 0.18, 0.92)
	gate.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(gate)
	var seal := ColorRect.new()
	seal.name = "CouncilSeal"
	seal.position = Vector2(HollowLayout.HOLLOW_LEFT + 224.0, HollowLayout.VAULTWARD_Y - 36.0)
	seal.size = Vector2(24.0, 18.0)
	seal.color = Color(0.55, 0.45, 0.3, 0.7)
	seal.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(seal)
	var bar := ColorRect.new()
	bar.name = "GateBar"
	bar.position = Vector2(HollowLayout.HOLLOW_LEFT + 208.0, HollowLayout.VAULTWARD_Y - 8.0)
	bar.size = Vector2(56.0, 6.0)
	bar.color = Color(0.65, 0.41, 0.28, 0.85)
	bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(bar)

	# Collision wall: no free climb from upper residences into Vaultward.
	var body := StaticBody2D.new()
	body.name = "VaultwardBlock"
	body.collision_layer = 1
	body.collision_mask = 0
	root.add_child(body)
	var col := CollisionShape2D.new()
	var shape := RectangleShape2D.new()
	shape.size = Vector2(96.0, 40.0)
	col.shape = shape
	col.position = Vector2(HollowLayout.HOLLOW_LEFT + 236.0, HollowLayout.VAULTWARD_Y - 20.0)
	body.add_child(col)


func _add_society_life_cues() -> void:
	## Lit windows, laundry, distant figures — population without new play routes.
	if get_node_or_null("SocietyLife") != null:
		return
	var root := Node2D.new()
	root.name = "SocietyLife"
	root.z_index = 1
	add_child(root)

	var windows := [
		Vector2(-480.0, HollowLayout.UPPER_RES_Y - 28.0),
		Vector2(-400.0, HollowLayout.UPPER_RES_Y - 24.0),
		Vector2(-520.0, HollowLayout.FARMS_Y - 36.0),
		Vector2(-440.0, HollowLayout.GLOW_SUB_Y - 28.0),
		Vector2(-500.0, HollowLayout.WICK_Y - 40.0),
		Vector2(-360.0, HollowLayout.MID_ALLOT_Y - 28.0),
		Vector2(-420.0, HollowLayout.LOWER_WORK_Y - 32.0),
		Vector2(820.0, HollowLayout.WICK_Y - 36.0),
		Vector2(900.0, HollowLayout.CISTERN_Y - 40.0),
	]
	for i in windows.size():
		var w: Vector2 = windows[i]
		var pane := ColorRect.new()
		pane.name = "Window%d" % i
		pane.position = w
		pane.size = Vector2(10.0, 12.0)
		pane.color = Color(0.89, 0.65, 0.36, 0.55)
		pane.mouse_filter = Control.MOUSE_FILTER_IGNORE
		root.add_child(pane)
		_pulse_nodes.append(pane)

	var laundry := ColorRect.new()
	laundry.name = "LaundryLine"
	laundry.position = Vector2(-300.0, HollowLayout.MID_ALLOT_Y - 48.0)
	laundry.size = Vector2(60.0, 3.0)
	laundry.color = Color(0.7, 0.68, 0.6, 0.5)
	laundry.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(laundry)
	_sway_nodes.append(laundry)

	for i in 3:
		var fig := ColorRect.new()
		fig.name = "DistantFigure%d" % i
		fig.position = Vector2(
			HollowLayout.PIT_RIGHT + 40.0 + i * 28.0,
			HollowLayout.WICK_Y - 22.0
		)
		fig.size = Vector2(6.0, 14.0)
		fig.color = Color(0.2, 0.18, 0.16, 0.45)
		fig.mouse_filter = Control.MOUSE_FILTER_IGNORE
		root.add_child(fig)

	# Left lateral gallery threshold cue (public excavation sideways).
	var left_brace := ColorRect.new()
	left_brace.name = "LeftGalleryBrace"
	left_brace.position = Vector2(HollowLayout.HOLLOW_LEFT + 8.0, HollowLayout.WICK_Y - 52.0)
	left_brace.size = Vector2(5.0, 52.0)
	left_brace.color = Color(0.28, 0.2, 0.14, 0.9)
	left_brace.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(left_brace)

	# Seep gallery threshold cue at lower-right (not into the Mouth).
	var seep_board := ColorRect.new()
	seep_board.name = "SeepWarning"
	seep_board.position = Vector2(HollowLayout.freight_lift_open_end() + 8.0, HollowLayout.SEEP_Y - 40.0)
	seep_board.size = Vector2(36.0, 14.0)
	seep_board.color = Color(0.4, 0.32, 0.22, 0.8)
	seep_board.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(seep_board)


func _add_bridge_crossing() -> void:
	if get_node_or_null("RopeCrossing") != null:
		return
	var root := Node2D.new()
	root.name = "RopeCrossing"
	root.z_index = 2
	add_child(root)

	var deck_y := HollowLayout.WICK_Y
	# Compact Mid Heart cluster — cables and short spans, not one continuous plank bridge.
	var decks: Array[Vector4] = HollowLayout.heart_deck_rects()
	for i in decks.size():
		var d: Vector4 = decks[i]
		var plank := ColorRect.new()
		plank.name = "Plank%d" % i
		plank.position = Vector2(d.x, d.z - 4.0)
		plank.size = Vector2(d.y - d.x, 6.0)
		plank.color = Color(0.4, 0.3, 0.2, 0.55 if d.w < 18.0 else 0.75)
		plank.mouse_filter = Control.MOUSE_FILTER_IGNORE
		root.add_child(plank)
		var post := ColorRect.new()
		post.name = "HeartPost%d" % i
		post.position = Vector2(d.x + 4.0, d.z - 20.0)
		post.size = Vector2(3.0, 16.0)
		post.color = WOOD_DARK
		post.mouse_filter = Control.MOUSE_FILTER_IGNORE
		root.add_child(post)

	_bridge_rope(root, "HandRopeTop", HollowLayout.HEART_WEST.x, HollowLayout.HEART_EAST.y, deck_y - 18.0, 4.0)
	_bridge_rope(root, "HandRopeBot", HollowLayout.HEART_WEST.x, HollowLayout.HEART_EAST.y, deck_y - 10.0, 3.0)

	# Stay cables into both crater walls.
	for i in 3:
		var cable := ColorRect.new()
		cable.name = "ClusterCable%d" % i
		cable.position = Vector2(HollowLayout.HEART_MID.x + 20.0 + i * 28.0, deck_y - 70.0)
		cable.size = Vector2(2.0, 66.0)
		cable.rotation = -0.12 + i * 0.1
		cable.color = Color(0.28, 0.24, 0.2, 0.5)
		cable.mouse_filter = Control.MOUSE_FILTER_IGNORE
		root.add_child(cable)

	var bulb := ColorRect.new()
	bulb.name = "CrossingLamp"
	bulb.position = Vector2(HollowLayout.HEART_MID.x + 40.0, deck_y - 28.0)
	bulb.size = Vector2(6.0, 8.0)
	bulb.color = Color(1.0, 0.78, 0.4, 0.95)
	bulb.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(bulb)


func _bridge_rope(parent: Node, rope_name: String, x0: float, x1: float, y: float, sag: float) -> void:
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
	# Slightly higher-contrast bodies so work props read against crater rock.
	_style_prop("PropFarms", Color(0.38, 0.48, 0.34, 1), GROWTH.lightened(0.08), &"farms")
	_style_prop("PropWick", Color(0.48, 0.34, 0.24, 1), COPPER.lightened(0.06), &"wick")
	_style_prop("PropCistern", Color(0.3, 0.4, 0.48, 1), CISTERN_LIGHT.lightened(0.05), &"cistern")


func _style_prop(prop_name: String, body: Color, accent: Color, kind: StringName) -> void:
	var prop := get_node_or_null(prop_name) as ColorRect
	if prop == null:
		return
	prop.color = body
	var building := prop.get_node_or_null("Building") as Node
	# Rebuild stale kits that predate carved-in facade pieces.
	if building != null and building.get_node_or_null("RockOverhang") == null:
		building.free()
		building = null
	if building != null:
		_ensure_district_extras(prop, kind, accent)
		return
	for old in ["Accent", "Post"]:
		var n := prop.get_node_or_null(old)
		if n:
			n.queue_free()

	building = Node2D.new()
	building.name = "Building"
	prop.add_child(building)
	match kind:
		&"farms":
			_build_farms_kit(building, prop.size, accent)
		&"wick":
			_build_wick_kit(building, prop.size, accent)
		_:
			_build_cistern_kit(building, prop.size, accent)

	_ensure_district_extras(prop, kind, accent)

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
	var extras := prop.get_node_or_null("DistrictExtras") as Node
	if extras != null:
		var needs_rebuild := false
		match kind:
			&"cistern":
				needs_rebuild = extras.get_node_or_null("FreightLift") == null
			&"farms":
				needs_rebuild = extras.get_node_or_null("Planter0") == null
			&"wick":
				needs_rebuild = extras.get_node_or_null("Bench") == null
			_:
				needs_rebuild = true
		if not needs_rebuild:
			return
		extras.free()
	extras = Node2D.new()
	extras.name = "DistrictExtras"
	prop.add_child(extras)
	match kind:
		&"farms":
			_farms_planters(extras, prop.size, accent)
		&"wick":
			_wick_bench(extras, prop.size, accent)
		_:
			_cistern_basin(extras, prop.size, accent)


func _build_farms_kit(root: Node2D, size: Vector2, accent: Color) -> void:
	# Carved-in grow shed: rock overhang + inset door (not a freestanding shed on a flat deck).
	var overhang := ColorRect.new()
	overhang.name = "RockOverhang"
	overhang.size = Vector2(size.x + 18, 8)
	overhang.position = Vector2(-10, -6)
	overhang.color = Color(ROCK.r, ROCK.g, ROCK.b, 0.95)
	overhang.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(overhang)
	var roof := Polygon2D.new()
	roof.name = "Roof"
	roof.color = accent.darkened(0.15)
	roof.polygon = PackedVector2Array([
		Vector2(-4, 8), Vector2(size.x * 0.5, -2), Vector2(size.x + 4, 8),
	])
	root.add_child(roof)
	var brace := ColorRect.new()
	brace.name = "TimberBrace"
	brace.size = Vector2(3, 18)
	brace.position = Vector2(4, 6)
	brace.color = WOOD
	brace.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(brace)
	var door := ColorRect.new()
	door.name = "Door"
	door.size = Vector2(8, 14)
	door.position = Vector2(size.x * 0.5 - 4, size.y - 14)
	door.color = WOOD_DARK
	door.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(door)
	var inset := ColorRect.new()
	inset.name = "InsetDoor"
	inset.size = Vector2(6, 12)
	inset.position = Vector2(size.x * 0.5 - 3, size.y - 13)
	inset.color = Color(0.12, 0.14, 0.12, 0.95)
	inset.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(inset)
	var shelf := ColorRect.new()
	shelf.name = "Shelf"
	shelf.size = Vector2(14, 3)
	shelf.position = Vector2(size.x - 16, size.y - 20)
	shelf.color = WOOD_DARK
	shelf.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(shelf)
	var bed := ColorRect.new()
	bed.name = "Glowbed"
	bed.size = Vector2(size.x * 0.7, 5)
	bed.position = Vector2(size.x + 2, size.y - 7)
	bed.color = Color(accent.r, accent.g, accent.b, 0.85)
	bed.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(bed)
	var mat := ColorRect.new()
	mat.name = "WallMat"
	mat.size = Vector2(14, 10)
	mat.position = Vector2(-16, size.y - 18)
	mat.color = Color(0.25, 0.4, 0.35, 0.7)
	mat.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(mat)
	var cable := ColorRect.new()
	cable.name = "HangCable"
	cable.size = Vector2(2, 16)
	cable.position = Vector2(size.x * 0.25, 2)
	cable.color = Color(0.35, 0.4, 0.32, 0.7)
	cable.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(cable)
	_sway_nodes.append(cable)


func _farms_planters(root: Node2D, size: Vector2, accent: Color) -> void:
	for i in 4:
		var box := ColorRect.new()
		box.name = "Planter%d" % i
		box.size = Vector2(12, 5 + (i % 2))
		box.position = Vector2(size.x + 4 + i * 16, size.y - 7 - (i % 2) * 3)
		box.color = Color(0.35, 0.28, 0.18, 0.95)
		box.mouse_filter = Control.MOUSE_FILTER_IGNORE
		root.add_child(box)
		var crop := ColorRect.new()
		crop.name = "Crop%d" % i
		crop.size = Vector2(8, 5)
		crop.position = Vector2(box.position.x + 2, box.position.y - 5)
		crop.color = accent.lightened(0.04 * i)
		crop.mouse_filter = Control.MOUSE_FILTER_IGNORE
		root.add_child(crop)
		_pulse_nodes.append(crop)
	var rack := ColorRect.new()
	rack.name = "FiberRack"
	rack.size = Vector2(4, 18)
	rack.position = Vector2(size.x + 72, size.y - 20)
	rack.color = WOOD
	rack.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(rack)
	var fiber := ColorRect.new()
	fiber.name = "FiberSway"
	fiber.size = Vector2(10, 12)
	fiber.position = Vector2(size.x + 74, size.y - 18)
	fiber.color = Color(0.45, 0.55, 0.4, 0.75)
	fiber.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(fiber)
	_sway_nodes.append(fiber)
	var basket := ColorRect.new()
	basket.name = "HarvestBasket"
	basket.size = Vector2(10, 7)
	basket.position = Vector2(size.x + 88, size.y - 9)
	basket.color = Color(0.4, 0.3, 0.2, 0.95)
	basket.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(basket)
	var bench := ColorRect.new()
	bench.name = "WorkBench"
	bench.size = Vector2(16, 5)
	bench.position = Vector2(-22, size.y - 7)
	bench.color = WOOD
	bench.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(bench)


func _build_wick_kit(root: Node2D, size: Vector2, accent: Color) -> void:
	# Wick bay carved into rock: overhang, inset door, shelves, hanging cords.
	var overhang := ColorRect.new()
	overhang.name = "RockOverhang"
	overhang.size = Vector2(size.x + 16, 7)
	overhang.position = Vector2(-8, -8)
	overhang.color = Color(ROCK.r * 1.1, ROCK.g, ROCK.b, 0.95)
	overhang.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(overhang)
	var roof := ColorRect.new()
	roof.name = "Roof"
	roof.size = Vector2(size.x + 6, 5)
	roof.position = Vector2(-3, -3)
	roof.color = accent
	roof.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(roof)
	var chimney := ColorRect.new()
	chimney.name = "Chimney"
	chimney.size = Vector2(6, 14)
	chimney.position = Vector2(size.x - 10, -14)
	chimney.color = accent.darkened(0.2)
	chimney.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(chimney)
	var inset := ColorRect.new()
	inset.name = "InsetDoor"
	inset.size = Vector2(9, 16)
	inset.position = Vector2(size.x * 0.4, size.y - 16)
	inset.color = Color(0.1, 0.08, 0.06, 0.95)
	inset.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(inset)
	var window := ColorRect.new()
	window.name = "InsetWindow"
	window.size = Vector2(7, 6)
	window.position = Vector2(6, size.y - 22)
	window.color = Color(WARM.r, WARM.g, WARM.b, 0.35)
	window.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(window)
	var shelf := ColorRect.new()
	shelf.name = "Shelf"
	shelf.size = Vector2(16, 3)
	shelf.position = Vector2(size.x - 18, size.y - 22)
	shelf.color = WOOD
	shelf.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(shelf)
	var spool := ColorRect.new()
	spool.name = "SpoolRack"
	spool.size = Vector2(12, 16)
	spool.position = Vector2(-18, size.y - 18)
	spool.color = WOOD_DARK
	spool.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(spool)
	var cord := ColorRect.new()
	cord.name = "CordSway"
	cord.size = Vector2(3, 14)
	cord.position = Vector2(-14, size.y - 16)
	cord.color = ROPE
	cord.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(cord)
	_sway_nodes.append(cord)
	var brace := ColorRect.new()
	brace.name = "TimberBrace"
	brace.size = Vector2(3, 20)
	brace.position = Vector2(size.x - 4, size.y - 22)
	brace.color = WOOD_DARK
	brace.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(brace)


func _wick_bench(root: Node2D, size: Vector2, accent: Color) -> void:
	var bench := ColorRect.new()
	bench.name = "Bench"
	bench.size = Vector2(20, 6)
	bench.position = Vector2(size.x + 4, size.y - 8)
	bench.color = Color(0.45, 0.32, 0.22, 0.95)
	bench.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(bench)
	var lamp_bench := ColorRect.new()
	lamp_bench.name = "LampBench"
	lamp_bench.size = Vector2(8, 5)
	lamp_bench.position = Vector2(size.x + 8, size.y - 12)
	lamp_bench.color = WARM
	lamp_bench.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(lamp_bench)
	_pulse_nodes.append(lamp_bench)
	var tools := ColorRect.new()
	tools.name = "CopperTools"
	tools.size = Vector2(14, 10)
	tools.position = Vector2(size.x + 26, size.y - 14)
	tools.color = COPPER
	tools.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(tools)
	var rope_b := ColorRect.new()
	rope_b.name = "RopeBundle"
	rope_b.size = Vector2(10, 8)
	rope_b.position = Vector2(size.x + 44, size.y - 10)
	rope_b.color = ROPE
	rope_b.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(rope_b)
	var forge := ColorRect.new()
	forge.name = "ForgeGlow"
	forge.size = Vector2(10, 8)
	forge.position = Vector2(size.x * 0.35, size.y - 14)
	forge.color = Color(1.0, 0.55, 0.25, 0.28)
	forge.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(forge)


func _build_cistern_kit(root: Node2D, size: Vector2, accent: Color) -> void:
	# Cool utility facade: rock overhang, pipes into wall, valve/gauge, wet character.
	var overhang := ColorRect.new()
	overhang.name = "RockOverhang"
	overhang.size = Vector2(size.x + 20, 8)
	overhang.position = Vector2(-10, -8)
	overhang.color = Color(0.16, 0.2, 0.24, 0.95)
	overhang.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(overhang)
	var dome := ColorRect.new()
	dome.name = "Dome"
	dome.size = Vector2(size.x - 8, 8)
	dome.position = Vector2(4, -4)
	dome.color = accent
	dome.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(dome)
	var inset := ColorRect.new()
	inset.name = "InsetDoor"
	inset.size = Vector2(10, 18)
	inset.position = Vector2(size.x * 0.35, size.y - 18)
	inset.color = Color(0.08, 0.12, 0.16, 0.95)
	inset.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(inset)
	var wall_pipe := ColorRect.new()
	wall_pipe.name = "WallPipe"
	wall_pipe.size = Vector2(28, 3)
	wall_pipe.position = Vector2(-14, size.y * 0.28)
	wall_pipe.color = COPPER
	wall_pipe.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(wall_pipe)
	var elbow := ColorRect.new()
	elbow.name = "PipeElbow"
	elbow.size = Vector2(4, 14)
	elbow.position = Vector2(-14, size.y * 0.28)
	elbow.color = COPPER.darkened(0.1)
	elbow.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(elbow)
	var pipe := ColorRect.new()
	pipe.name = "Pipe"
	pipe.size = Vector2(22, 3)
	pipe.position = Vector2(size.x - 2, size.y * 0.35)
	pipe.color = COPPER
	pipe.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(pipe)
	var valve := ColorRect.new()
	valve.name = "Valve"
	valve.size = Vector2(6, 6)
	valve.position = Vector2(size.x + 16, size.y * 0.35 - 1)
	valve.color = accent.lightened(0.1)
	valve.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(valve)
	var gauge := ColorRect.new()
	gauge.name = "PressureGauge"
	gauge.size = Vector2(7, 7)
	gauge.position = Vector2(size.x + 4, size.y * 0.2)
	gauge.color = Color(0.7, 0.78, 0.8, 0.95)
	gauge.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(gauge)
	var brace := ColorRect.new()
	brace.name = "TimberBrace"
	brace.size = Vector2(3, 22)
	brace.position = Vector2(size.x - 6, size.y - 24)
	brace.color = Color(0.3, 0.34, 0.36, 0.9)
	brace.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(brace)


func _cistern_basin(root: Node2D, size: Vector2, accent: Color) -> void:
	var basin := ColorRect.new()
	basin.name = "Basin"
	basin.size = Vector2(24, 9)
	basin.position = Vector2(size.x + 8, size.y - 11)
	basin.color = Color(0.25, 0.35, 0.42, 0.95)
	basin.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(basin)
	var water := ColorRect.new()
	water.name = "Water"
	water.size = Vector2(20, 4)
	water.position = Vector2(basin.position.x + 2, basin.position.y + 2)
	water.color = Color(0.45, 0.7, 0.82, 0.65)
	water.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(water)
	_pulse_nodes.append(water)
	var seep := ColorRect.new()
	seep.name = "SeepMark"
	seep.size = Vector2(6, 18)
	seep.position = Vector2(size.x - 4, size.y - 22)
	seep.color = Color(0.2, 0.32, 0.38, 0.45)
	seep.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(seep)
	var seep2 := ColorRect.new()
	seep2.name = "SeepMark2"
	seep2.size = Vector2(4, 12)
	seep2.position = Vector2(size.x + 2, size.y - 16)
	seep2.color = Color(0.22, 0.34, 0.4, 0.35)
	seep2.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(seep2)
	var hose := ColorRect.new()
	hose.name = "HoseReel"
	hose.size = Vector2(8, 10)
	hose.position = Vector2(size.x + 36, size.y - 14)
	hose.color = PATINA
	hose.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(hose)
	var hose_hang := ColorRect.new()
	hose_hang.name = "HoseSway"
	hose_hang.size = Vector2(3, 16)
	hose_hang.position = Vector2(size.x + 42, size.y - 18)
	hose_hang.color = Color(0.35, 0.45, 0.4, 0.85)
	hose_hang.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(hose_hang)
	_sway_nodes.append(hose_hang)
	var cans := ColorRect.new()
	cans.name = "CanisterRack"
	cans.size = Vector2(16, 12)
	cans.position = Vector2(size.x + 52, size.y - 14)
	cans.color = Color(0.3, 0.34, 0.36, 0.95)
	cans.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(cans)
	# Legacy name kept for older checks; FreightLift is the public Presswater platform.
	var freight := ColorRect.new()
	freight.name = "FreightPlatform"
	freight.size = Vector2(22, 5)
	freight.position = Vector2(size.x + 72, size.y - 7)
	freight.color = WOOD_DARK
	freight.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(freight)
	var lift := Node2D.new()
	lift.name = "FreightLift"
	lift.position = Vector2(size.x + 72, size.y - 28)
	root.add_child(lift)
	var cage := ColorRect.new()
	cage.name = "LiftCage"
	cage.size = Vector2(20, 18)
	cage.position = Vector2(1, 6)
	cage.color = Color(0.28, 0.34, 0.38, 0.9)
	cage.mouse_filter = Control.MOUSE_FILTER_IGNORE
	lift.add_child(cage)
	var rail_l := ColorRect.new()
	rail_l.name = "LiftRailL"
	rail_l.size = Vector2(2, 26)
	rail_l.position = Vector2(0, 0)
	rail_l.color = Color(0.4, 0.45, 0.48, 0.85)
	rail_l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	lift.add_child(rail_l)
	var rail_r := ColorRect.new()
	rail_r.name = "LiftRailR"
	rail_r.size = Vector2(2, 26)
	rail_r.position = Vector2(20, 0)
	rail_r.color = Color(0.4, 0.45, 0.48, 0.85)
	rail_r.mouse_filter = Control.MOUSE_FILTER_IGNORE
	lift.add_child(rail_r)
	var cable := ColorRect.new()
	cable.name = "LiftCable"
	cable.size = Vector2(2, 14)
	cable.position = Vector2(10, -8)
	cable.color = Color(0.45, 0.4, 0.32, 0.8)
	cable.mouse_filter = Control.MOUSE_FILTER_IGNORE
	lift.add_child(cable)
	var hook := ColorRect.new()
	hook.name = "FreightHook"
	hook.size = Vector2(3, 10)
	hook.position = Vector2(size.x + 80, size.y - 16)
	hook.color = COPPER
	hook.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(hook)
	var drip := ColorRect.new()
	drip.name = "Drip"
	drip.size = Vector2(2, 10)
	drip.position = Vector2(size.x + 4, size.y * 0.35 + 3)
	drip.color = accent.darkened(0.1)
	drip.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(drip)
	_pulse_nodes.append(drip)
	var steam := ColorRect.new()
	steam.name = "SteamPuff"
	steam.size = Vector2(8, 6)
	steam.position = Vector2(size.x + 14, size.y * 0.15)
	steam.color = Color(0.7, 0.82, 0.88, 0.18)
	steam.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(steam)
	_pulse_nodes.append(steam)


func _add_mid_heart_props() -> void:
	if get_node_or_null("MidHeartProps") != null:
		return
	var root := Node2D.new()
	root.name = "MidHeartProps"
	root.z_index = 1
	add_child(root)
	var deck_y := HollowLayout.WICK_Y
	# Compact tally booth / counter on Mid Heart center deck — Materials turn-in.
	var booth_x := HollowLayout.HEART_MID.x + 24.0
	var booth := ColorRect.new()
	booth.name = "TallyBooth"
	booth.position = Vector2(booth_x, deck_y - 28.0)
	booth.size = Vector2(36.0, 26.0)
	booth.color = Color(0.32, 0.24, 0.18, 0.95)
	booth.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(booth)
	var counter := ColorRect.new()
	counter.name = "TallyCounter"
	counter.position = Vector2(booth_x - 4.0, deck_y - 10.0)
	counter.size = Vector2(44.0, 5.0)
	counter.color = WOOD
	counter.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(counter)
	var canopy := ColorRect.new()
	canopy.name = "BoothCanopy"
	canopy.position = Vector2(booth_x - 6.0, deck_y - 36.0)
	canopy.size = Vector2(48.0, 6.0)
	canopy.color = Color(WARM.r, WARM.g, WARM.b, 0.75)
	canopy.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(canopy)
	var emblem := ColorRect.new()
	emblem.name = "HangEmblem"
	emblem.position = Vector2(booth_x + 14.0, deck_y - 48.0)
	emblem.size = Vector2(8.0, 10.0)
	emblem.color = COPPER
	emblem.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(emblem)
	_sway_nodes.append(emblem)
	var emblem_chain := ColorRect.new()
	emblem_chain.name = "EmblemChain"
	emblem_chain.position = Vector2(booth_x + 17.0, deck_y - 52.0)
	emblem_chain.size = Vector2(2.0, 6.0)
	emblem_chain.color = Color(0.4, 0.35, 0.28, 0.8)
	emblem_chain.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(emblem_chain)
	var board := ColorRect.new()
	board.name = "TallyBoard"
	board.position = Vector2(booth_x + 40.0, deck_y - 30.0)
	board.size = Vector2(18.0, 22.0)
	board.color = Color(0.22, 0.2, 0.16, 0.92)
	board.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(board)
	var board_mark := ColorRect.new()
	board_mark.name = "TallyBoardMark"
	board_mark.position = Vector2(booth_x + 44.0, deck_y - 24.0)
	board_mark.size = Vector2(10.0, 2.0)
	board_mark.color = Color(WARM.r, WARM.g, WARM.b, 0.55)
	board_mark.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(board_mark)
	var board_mark2 := ColorRect.new()
	board_mark2.name = "TallyBoardMark2"
	board_mark2.position = Vector2(booth_x + 44.0, deck_y - 18.0)
	board_mark2.size = Vector2(8.0, 2.0)
	board_mark2.color = Color(0.55, 0.5, 0.4, 0.5)
	board_mark2.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(board_mark2)
	# Warm lamp over the working area.
	var lamp_post := ColorRect.new()
	lamp_post.name = "BoothLampPost"
	lamp_post.position = Vector2(booth_x - 10.0, deck_y - 34.0)
	lamp_post.size = Vector2(3.0, 20.0)
	lamp_post.color = WOOD_DARK
	lamp_post.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(lamp_post)
	var lamp := ColorRect.new()
	lamp.name = "BoothLamp"
	lamp.position = Vector2(booth_x - 13.0, deck_y - 40.0)
	lamp.size = Vector2(9.0, 7.0)
	lamp.color = WARM
	lamp.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(lamp)
	_pulse_nodes.append(lamp)
	# Small working area around Joss — allotment / material crates on Mid Heart.
	_crate(root, "AllotmentCrateL", Vector2(HollowLayout.HEART_MID.x + 4.0, deck_y - 14.0), COPPER)
	_crate(root, "AllotmentCrateR", Vector2(HollowLayout.HEART_EAST.x + 8.0, deck_y - 14.0), WARM)
	_crate(root, "MaterialCrate", Vector2(HollowLayout.HEART_EAST.x + 28.0, deck_y - 12.0), PATINA)
	_crate(root, "TurnInCrate", Vector2(booth_x - 22.0, deck_y - 12.0), Color(0.45, 0.35, 0.25, 1.0))
	_crate(root, "TalliesCrate", Vector2(booth_x + 60.0, deck_y - 12.0), WARM.darkened(0.15))
	# Handrail posts on the west approach.
	for i in 2:
		var post := ColorRect.new()
		post.name = "ApproachPost%d" % i
		post.position = Vector2(HollowLayout.HEART_WEST.x + 8.0 + i * 18.0, deck_y - 18.0)
		post.size = Vector2(3.0, 18.0)
		post.color = WOOD_DARK
		post.mouse_filter = Control.MOUSE_FILTER_IGNORE
		root.add_child(post)


func _crate(parent: Node, crate_name: String, pos: Vector2, color: Color) -> void:
	var c := ColorRect.new()
	c.name = crate_name
	c.position = pos
	c.size = Vector2(14.0, 12.0)
	c.color = color.darkened(0.1)
	c.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(c)


func _add_deck_glows() -> void:
	_glow(
		"GlowPoolFarms",
		Rect2(HollowLayout.HOLLOW_LEFT + 40, HollowLayout.FARMS_Y - 28, 200, 28),
		Color(1.0, 0.7, 0.35, 0.12)
	)
	_glow(
		"GlowPoolFarmsGrowth",
		Rect2(HollowLayout.HOLLOW_LEFT + 20, HollowLayout.FARMS_Y - 36, 160, 20),
		Color(GROWTH.r, GROWTH.g, GROWTH.b, 0.1)
	)
	_glow(
		"GlowPoolWick",
		Rect2(HollowLayout.WICK_BAY_END, HollowLayout.WICK_Y - 28, 200, 28),
		Color(1.0, 0.65, 0.3, 0.14)
	)
	_glow(
		"GlowPoolBridge",
		Rect2(HollowLayout.HEART_MID.x, HollowLayout.WICK_Y - 22, 120, 22),
		Color(0.95, 0.7, 0.4, 0.12)
	)
	_glow(
		"GlowPoolWickRight",
		Rect2(620, HollowLayout.WICK_Y - 26, 140, 26),
		Color(1.0, 0.68, 0.35, 0.1)
	)
	_glow(
		"GlowPoolCistern",
		Rect2(680, HollowLayout.CISTERN_Y - 28, 180, 28),
		Color(0.55, 0.71, 0.77, 0.1)
	)
	_glow(
		"GlowPoolPitCool",
		Rect2(HollowLayout.PIT_LEFT + 40, HollowLayout.WICK_Y + 40, 240, 180),
		Color(0.25, 0.45, 0.55, 0.06)
	)


func _glow(node_name: String, rect: Rect2, color: Color) -> void:
	var existing := get_node_or_null(node_name) as ColorRect
	if existing != null:
		existing.color = color
		existing.position = rect.position
		existing.size = rect.size
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
	_point_light(root, "LightFarms", Vector2(-300, HollowLayout.FARMS_Y - 40), tex, 0.65, 2.3)
	_point_light(root, "LightFarmsTerrace", Vector2(-40, HollowLayout.FARMS_Y - 40), tex, 0.55, 2.1)
	_point_light(root, "LightWick", Vector2(-200, HollowLayout.WICK_Y - 40), tex, 0.85, 2.8)
	_point_light(root, "LightBridge", Vector2(416, HollowLayout.WICK_Y - 36), tex, 0.7, 2.4)
	_point_light(root, "LightWickRight", Vector2(700, HollowLayout.WICK_Y - 38), tex, 0.55, 2.3)
	_point_light(
		root, "LightCistern", Vector2(740, HollowLayout.CISTERN_Y - 40), tex, 0.55, 2.5, CISTERN_LIGHT
	)
	_point_light(root, "LightCisternSafety", Vector2(820, HollowLayout.CISTERN_Y - 36), tex, 0.35, 1.8, WARM)
	_point_light(root, "LightPitCool", Vector2(416, HollowLayout.CISTERN_Y + 40), tex, 0.35, 3.2, COOL_PIT)
	# Sparse deep lights in Devil's Mouth — scale cues, not bright fill.
	_point_light(root, "LightDeepSparseA", Vector2(340, 480), tex, 0.12, 1.4, COOL_PIT)
	_point_light(root, "LightDeepSparseB", Vector2(480, 560), tex, 0.1, 1.2, Color(0.4, 0.5, 0.55, 1.0))
	_point_light(root, "LightDeepSparseC", Vector2(400, 620), tex, 0.08, 1.0, Color(0.35, 0.42, 0.48, 1.0))
	_lamp_post(root, "LampPostFarms", Vector2(-304, HollowLayout.FARMS_Y - 22))
	_lamp_post(root, "LampPostFarmsTerrace", Vector2(-44, HollowLayout.FARMS_Y - 22))
	_lamp_post(root, "LampPostWick", Vector2(-204, HollowLayout.WICK_Y - 22))
	_lamp_post(root, "LampPostWickRight", Vector2(696, HollowLayout.WICK_Y - 22))
	_lamp_post(root, "LampPostCistern", Vector2(736, HollowLayout.CISTERN_Y - 22), CISTERN_LIGHT)
	_lamp_post(root, "LampPostCisternSafety", Vector2(816, HollowLayout.CISTERN_Y - 22), WARM)
	# Mid Heart civic lamp near tally booth / Joss.
	_lamp_post(root, "LampPostMidHeart", Vector2(340, HollowLayout.WICK_Y - 22), WARM)
	_point_light(root, "LightMidHeartBooth", Vector2(360, HollowLayout.WICK_Y - 36), tex, 0.75, 2.2)


func _lamp_post(
	parent: Node, lamp_name: String, pos: Vector2, glow_color: Color = Color(1.0, 0.78, 0.42, 0.95)
) -> void:
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
	_pulse_nodes.append(glow)


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


func _add_district_ambience() -> void:
	if get_node_or_null("DistrictAmbience") != null:
		return
	var root := Node2D.new()
	root.name = "DistrictAmbience"
	root.z_index = 1
	add_child(root)
	# Glowbeds spores (local, teal-muted).
	var spores := GPUParticles2D.new()
	spores.name = "GlowbedSpores"
	spores.position = Vector2(HollowLayout.HOLLOW_LEFT + 180.0, HollowLayout.FARMS_Y - 40.0)
	spores.amount = 10
	spores.lifetime = 5.0
	spores.preprocess = 2.0
	spores.visibility_rect = Rect2(-120, -80, 240, 160)
	spores.texture = _spore_tex()
	var mat := ParticleProcessMaterial.new()
	mat.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_BOX
	mat.emission_box_extents = Vector3(90, 30, 0)
	mat.direction = Vector3(0, -1, 0)
	mat.spread = 40.0
	mat.initial_velocity_min = 3.0
	mat.initial_velocity_max = 8.0
	mat.gravity = Vector3(0, -1.5, 0)
	mat.scale_min = 0.3
	mat.scale_max = 0.7
	mat.color = Color(GROWTH.r, GROWTH.g, GROWTH.b, 0.4)
	spores.process_material = mat
	root.add_child(spores)


func _animate_district_life(_delta: float) -> void:
	for n in _sway_nodes:
		if is_instance_valid(n):
			n.rotation = sin(_fog_t * 1.4 + n.position.x * 0.01) * 0.12
	for n in _pulse_nodes:
		if is_instance_valid(n):
			n.modulate.a = 0.75 + sin(_fog_t * 2.2 + n.get_instance_id() % 7) * 0.2


func _add_camera_vignette() -> void:
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

	if get_node_or_null("FarHaze") == null:
		var far := ColorRect.new()
		far.name = "FarHaze"
		far.position = Vector2(HollowLayout.PIT_LEFT + 40, 40)
		far.size = Vector2(HollowLayout.PIT_RIGHT - HollowLayout.PIT_LEFT - 80, 280)
		far.color = Color(0.07, 0.13, 0.15, 0.12)
		far.mouse_filter = Control.MOUSE_FILTER_IGNORE
		far.z_index = -1
		add_child(far)
	else:
		var far_exist := get_node_or_null("FarHaze") as ColorRect
		if far_exist:
			far_exist.color = Color(0.07, 0.13, 0.15, 0.12)
			far_exist.size = Vector2(HollowLayout.PIT_RIGHT - HollowLayout.PIT_LEFT - 80, 280)

	if get_node_or_null("PitShaftVeil") == null:
		var veil := ColorRect.new()
		veil.name = "PitShaftVeil"
		veil.position = Vector2(HollowLayout.PIT_LEFT + 28, 170)
		veil.size = Vector2(HollowLayout.PIT_RIGHT - HollowLayout.PIT_LEFT - 56, 260)
		veil.color = Color(0.035, 0.09, 0.11, 0.14)
		veil.mouse_filter = Control.MOUSE_FILTER_IGNORE
		veil.z_index = -1
		add_child(veil)

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
	if get_node_or_null("CarvedRooms/GlowbedsGallery") == null:
		return false
	if get_node_or_null("CarvedRooms/GlowbedsGallery/Overhang") == null:
		return false
	if get_node_or_null("CarvedRooms/GlowbedsGallery/StorageCrate") == null:
		return false
	if get_node_or_null("TerracePunctuation/FarmsLookout") == null:
		return false
	if get_node_or_null("TerracePunctuation/WickBayRamp") == null:
		return false
	if get_node_or_null("ImpactStrata/HullPlateFar") == null:
		return false
	if get_node_or_null("HeartStructure/UpperHeartDeck") == null:
		return false
	if get_node_or_null("MidHeartProps/AllotmentCrateL") == null:
		return false
	var farms := get_node_or_null("PropFarms/DistrictExtras/Planter0")
	var wick := get_node_or_null("PropWick/DistrictExtras/Bench")
	var cistern := get_node_or_null("PropCistern/DistrictExtras/Basin")
	var freight := get_node_or_null("PropCistern/DistrictExtras/FreightLift")
	if freight == null:
		freight = get_node_or_null("PropCistern/DistrictExtras/FreightPlatform")
	var booth := get_node_or_null("MidHeartProps/TallyBooth")
	return (
		farms != null
		and wick != null
		and cistern != null
		and freight != null
		and booth != null
	)
