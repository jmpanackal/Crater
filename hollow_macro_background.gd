@tool
extends Node2D

const Layout := preload("res://hollow_layout.gd")
## Extended east so Mid-East Dig Front (to x=2368) fits with margin.
## World-scale pass (2026-09-19): bounds and every district/transport literal
## below are x5 their previous values — see hollow_layout.gd's header note.
const WORLD_BOUNDS := Rect2(-6400, -1600, 20000, 10000)
const MOUTH_BOUNDS := Rect2(Layout.PIT_LEFT, -640, Layout.PIT_RIGHT - Layout.PIT_LEFT, 9000)
const GUIDE_COLOR := Color(0.57, 0.76, 0.72, 0.65)
const FUTURE_COLOR := Color(0.77, 0.61, 0.38, 0.8)

var _guides_only := false

@export var show_planning_guides := true:
	set(value):
		show_planning_guides = value
		queue_redraw()
		_sync_overlay()
@export var show_guides_in_game := false:
	set(value):
		show_guides_in_game = value
		queue_redraw()
		_sync_overlay()


static func district_guides() -> Array[Dictionary]:
	var pit_l := Layout.PIT_LEFT
	var pit_r := Layout.PIT_RIGHT
	var mouth_w := pit_r - pit_l
	var wh_l := Layout.WEST_HOLLOW_LEFT
	var wh_w := Layout.WEST_HOLLOW_RIGHT - Layout.WEST_HOLLOW_LEFT
	var band_h := Layout.WEST_LEVEL_GAP * 2.0
	return [
		{"name": "Ashram Heights / west", "bounds": Rect2(wh_l, Layout.WEST_ASHRAM_UPPER_Y - 160.0, wh_w, band_h), "level": Layout.WEST_ASHRAM_UPPER_Y},
		{"name": "Ashram Heights / east", "bounds": Rect2(pit_r, -640, 2080, 1040), "level": Layout.UPPER_RES_Y},
		{"name": "High-West Dig Front", "bounds": Rect2(Layout.HIGH_WEST_DIG_LEFT, Layout.WEST_HIGH_UPPER_Y - 160.0, Layout.HIGH_WEST_DIG_RIGHT - Layout.HIGH_WEST_DIG_LEFT + wh_w, band_h), "level": Layout.WEST_HIGH_UPPER_Y},
		{"name": "Glowbeds", "bounds": Rect2(pit_r, 400, 2080, 1440), "level": Layout.FARMS_Y},
		{"name": "Wickwork", "bounds": Rect2(wh_l, Layout.WICK_Y - 160.0, wh_w, band_h), "level": Layout.WICK_Y},
		{
			"name": "Mid Heart / Mouth crossing",
			"bounds": Rect2(pit_l, Layout.HEART_Y - 200.0, mouth_w, 400.0),
			"level": Layout.HEART_Y,
		},
		{"name": "Mid allotments / homes", "bounds": Rect2(wh_l, Layout.MID_ALLOT_UPPER_Y - 160.0, wh_w, band_h), "level": Layout.MID_ALLOT_Y},
		{"name": "Mid-East landing", "bounds": Rect2(pit_r, 1840, 2080, 1760), "level": Layout.HEART_Y},
		{"name": "Mid-East approach", "bounds": Rect2(Layout.MID_EAST_APPROACH.x, 2160, Layout.MID_EAST_APPROACH.y - Layout.MID_EAST_APPROACH.x, 1440), "level": Layout.HEART_Y},
		{"name": "Mid-East Dig Front", "bounds": Rect2(Layout.MID_EAST_DIG_FRONT.x, 2160, Layout.MID_EAST_DIG_FRONT.y - Layout.MID_EAST_DIG_FRONT.x, 1440), "level": Layout.HEART_Y},
		{"name": "Lower worker terraces", "bounds": Rect2(wh_l, Layout.WEST_LW_UPPER_Y - 160.0, wh_w, band_h), "level": Layout.WEST_LW_UPPER_Y},
		{"name": "Lower-East services", "bounds": Rect2(pit_r, 3600, 2080, 1040), "level": Layout.LOWER_WORK_Y},
		{"name": "Bottom-West Dig Front", "bounds": Rect2(Layout.HIGH_WEST_DIG_LEFT, Layout.BOTTOM_WEST_UPPER_Y - 160.0, Layout.HIGH_WEST_DIG_RIGHT - Layout.HIGH_WEST_DIG_LEFT + wh_w, band_h), "level": Layout.BOTTOM_WEST_UPPER_Y},
		{"name": "Cistern", "bounds": Rect2(pit_r, 4640, 4640, 1440), "level": Layout.CISTERN_Y},
		{"name": "Seep / service threshold", "bounds": Rect2(pit_r, 6080, 2080, 640), "level": Layout.SEEP_Y},
	]


static func transport_guides() -> Array[Dictionary]:
	return [
		{"name": "West stack ladder", "x": Layout.LADDER_WEST_OPEN_X, "label_y": 600.0, "stops": Layout.west_stack_level_ys()},
		{"name": "East upper / Ashram to Cistern", "x": Layout.LADDER_EAST_OPEN_X, "label_y": 800.0, "stops": [Layout.UPPER_RES_Y, Layout.FARMS_Y, Layout.GLOW_SUB_Y, Layout.HEART_Y, Layout.CISTERN_Y]},
	]


func _ready() -> void:
	if _guides_only:
		z_as_relative = false
		z_index = 20
		return
	z_index = -4
	var overlay: Node2D = get_script().new()
	overlay.name = "PlanningGuides"
	overlay._guides_only = true
	add_child(overlay, false, Node.INTERNAL_MODE_BACK)
	_sync_overlay()
	queue_redraw()


func _sync_overlay() -> void:
	var overlay := get_node_or_null("PlanningGuides")
	if overlay != null:
		overlay.show_planning_guides = show_planning_guides
		overlay.show_guides_in_game = show_guides_in_game


func _draw() -> void:
	if not _guides_only:
		draw_rect(WORLD_BOUNDS, Color(0.10, 0.155, 0.15))
		# Ink void — open shaft, not a solid filler block (docs: #091419).
		draw_rect(MOUTH_BOUNDS, Color(0.035, 0.078, 0.098))
		draw_rect(Rect2(WORLD_BOUNDS.position, Vector2(WORLD_BOUNDS.size.x, 960)), Color(0.18, 0.22, 0.21))
		return
	if not show_planning_guides or (not Engine.is_editor_hint() and not show_guides_in_game):
		return
	_label(Vector2(-6160, -1320), "HOLLOW SCALE PLAN  |  GUIDES ONLY - NO COLLISION", 24, GUIDE_COLOR)
	_label(Vector2(-6160, -1160), "16 px tiles / 32 px player. Dashed extents and routes are provisional, not playable platforms.", 17, GUIDE_COLOR)
	_label(Vector2(-2800, -800), "FIRMAMENT / sustained upward excavation, locked at start", 19, GUIDE_COLOR)
	draw_rect(WORLD_BOUNDS, GUIDE_COLOR, false, 2)
	for district in district_guides():
		var bounds: Rect2 = district.bounds
		_outline(bounds, GUIDE_COLOR)
		_label(bounds.position + Vector2(12, 24), district.name, 18, GUIDE_COLOR)
		var level: float = district.level
		draw_dashed_line(Vector2(bounds.position.x + 8, level), Vector2(bounds.end.x - 8, level), GUIDE_COLOR, 1, 6)
		_label(Vector2(bounds.position.x + 12, level - 8), "level y=%d / planned" % level, 12, GUIDE_COLOR)
	for transport in transport_guides():
		var stops: Array = transport.stops
		var shaft_x: float = transport.x
		draw_dashed_line(Vector2(shaft_x, stops.front()), Vector2(shaft_x, stops.back()), FUTURE_COLOR, 2, 10)
		for level in stops:
			draw_circle(Vector2(shaft_x, level), 6, FUTURE_COLOR, false, 2)
		_label(Vector2(shaft_x + 10, transport.label_y), transport.name, 13, FUTURE_COLOR)
	var return_route := PackedVector2Array([
		Vector2(-560, Layout.WEST_LW_UPPER_Y),
		Vector2(-1520, Layout.MID_ALLOT_Y),
		Vector2(-560, Layout.WICK_Y),
		Vector2(Layout.PIT_LEFT, Layout.WICK_Y),
	])
	for index in range(return_route.size() - 1):
		draw_dashed_line(return_route[index], return_route[index + 1], FUTURE_COLOR, 2, 10)
	_label(Vector2(-1760, Layout.MID_ALLOT_Y - 80.0), "West stack ladder / Mid Heart", 13, FUTURE_COLOR)
	for reserve in [
		Rect2(-4160, 1840, 1280, 1040),
		Rect2(Layout.MID_EAST_APPROACH.x, 400, 1280, 1440),
		Rect2(Layout.MID_EAST_APPROACH.x, 4640, 1280, 1440),
	]:
		_outline(reserve, FUTURE_COLOR)
		_label(reserve.position + Vector2(12, 48), "Growth reserve", 15, FUTURE_COLOR)
		_label(reserve.position + Vector2(12, 68), "footprint to refine", 12, FUTURE_COLOR)
	_label(Vector2(Layout.HEART_MID_X - 80.0, 4400), "DEVIL'S MOUTH", 22, GUIDE_COLOR)
	_label(Vector2(Layout.HEART_MID_X - 120.0, 4560), "OPEN VOID / MID HEART IS THE CROSSING", 12, GUIDE_COLOR)
	_label(Vector2(-6160, 6000), "Solid opening-route tiles = currently playable", 17, GUIDE_COLOR)
	_label(Vector2(-6160, 6160), "Home -> Dispatch -> Bottom-West -> return", 17, GUIDE_COLOR)
	## Physical reference markers — deliberately NOT scaled: still the real
	## 32px player body and the real 256px (16-tile) span, so they stay true
	## after the world-scale pass. Only their anchor position moves.
	draw_rect(Rect2(-6160, 6400, 32, 32), GUIDE_COLOR, false, 2)
	_label(Vector2(-5920, 6520), "32 px player reference", 17, GUIDE_COLOR)
	draw_line(Vector2(-6160, 6800), Vector2(-6160, 6800) + Vector2(256, 0), GUIDE_COLOR, 2)
	_label(Vector2(-6160, 6960), "256 px / 16 tiles", 17, GUIDE_COLOR)


func _outline(bounds: Rect2, color: Color) -> void:
	var corners := [bounds.position, Vector2(bounds.end.x, bounds.position.y), bounds.end, Vector2(bounds.position.x, bounds.end.y)]
	for index in range(4):
		draw_dashed_line(corners[index], corners[(index + 1) % 4], color, 1, 8)


func _label(at: Vector2, text: String, size: int, color: Color) -> void:
	draw_string(ThemeDB.fallback_font, at, text, HORIZONTAL_ALIGNMENT_LEFT, -1, size, color)
