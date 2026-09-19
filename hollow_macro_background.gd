@tool
extends Node2D

const Layout := preload("res://hollow_layout.gd")
const WORLD_BOUNDS := Rect2(-1280, -320, 3584, 1792)
const MOUTH_BOUNDS := Rect2(Layout.PIT_LEFT, -128, Layout.PIT_RIGHT - Layout.PIT_LEFT, 1600)
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
	return [
		{"name": "Ashram Heights / west", "bounds": Rect2(-576, -128, 832, 208), "level": Layout.UPPER_RES_Y},
		{"name": "Ashram Heights / east", "bounds": Rect2(736, -128, 416, 208), "level": Layout.UPPER_RES_Y},
		{"name": "High-West Dig Front", "bounds": Rect2(-1136, 80, 560, 288), "level": Layout.FARMS_Y},
		{"name": "Glowbeds", "bounds": Rect2(736, 80, 416, 288), "level": Layout.FARMS_Y},
		{"name": "Wickwork", "bounds": Rect2(-576, 368, 800, 208), "level": Layout.WICK_Y},
		{"name": "Mid Heart / moored rafts", "bounds": Rect2(288, 368, 448, 352), "level": Layout.HEART_Y},
		{"name": "Mid allotments / homes", "bounds": Rect2(-576, 576, 800, 144), "level": Layout.MID_ALLOT_Y},
		{"name": "Mid-East landing", "bounds": Rect2(736, 368, 416, 352), "level": Layout.HEART_Y},
		{"name": "Mid-East approach", "bounds": Rect2(1152, 432, 256, 288), "level": Layout.HEART_Y},
		{"name": "Mid-East Dig Front", "bounds": Rect2(1408, 432, 704, 288), "level": Layout.HEART_Y},
		{"name": "Lower worker terraces", "bounds": Rect2(-368, 720, 624, 160), "level": Layout.LOWER_WORK_Y},
		{"name": "Lower-East services", "bounds": Rect2(736, 720, 416, 208), "level": Layout.LOWER_WORK_Y},
		{"name": "Bottom-West galleries", "bounds": Rect2(-1136, 928, 512, 208), "level": Layout.BOTTOM_WEST_Y},
		{"name": "Cistern", "bounds": Rect2(736, 928, 416, 288), "level": Layout.CISTERN_Y},
		{"name": "Seep / service threshold", "bounds": Rect2(736, 1216, 416, 128), "level": Layout.SEEP_Y},
	]


static func transport_guides() -> Array[Dictionary]:
	return [
		{"name": "West civic / Mid to High", "x": 240.0, "label_y": 120.0, "stops": [Layout.UPPER_RES_Y, Layout.FARMS_Y, Layout.WICK_Y]},
		{"name": "East upper / guarded", "x": 1088.0, "label_y": 400.0, "stops": [Layout.UPPER_RES_Y, Layout.FARMS_Y, Layout.HEART_Y]},
		{"name": "Cistern freight / Low to Mid", "x": 848.0, "label_y": 616.0, "stops": [Layout.HEART_Y, Layout.LOWER_WORK_Y, Layout.CISTERN_Y]},
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
		draw_rect(MOUTH_BOUNDS, Color(0.025, 0.055, 0.065))
		draw_rect(Rect2(WORLD_BOUNDS.position, Vector2(WORLD_BOUNDS.size.x, 192)), Color(0.18, 0.22, 0.21))
		return
	if not show_planning_guides or (not Engine.is_editor_hint() and not show_guides_in_game):
		return
	_label(Vector2(-1232, -264), "HOLLOW SCALE PLAN  |  GUIDES ONLY - NO COLLISION", 24, GUIDE_COLOR)
	_label(Vector2(-1232, -232), "16 px tiles / 32 px player. Dashed extents and routes are provisional, not playable platforms.", 17, GUIDE_COLOR)
	_label(Vector2(-560, -160), "FIRMAMENT / sustained upward excavation, locked at start", 19, GUIDE_COLOR)
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
	var return_route := PackedVector2Array([Vector2(-112, 864), Vector2(-304, 720), Vector2(-112, 576), Vector2(288, 576)])
	for index in range(return_route.size() - 1):
		draw_dashed_line(return_route[index], return_route[index + 1], FUTURE_COLOR, 2, 10)
	_label(Vector2(-352, 696), "Worker return switchbacks / planned", 13, FUTURE_COLOR)
	for reserve in [Rect2(-832, 368, 256, 208), Rect2(1152, 80, 256, 288), Rect2(1152, 928, 256, 288)]:
		_outline(reserve, FUTURE_COLOR)
		_label(reserve.position + Vector2(12, 48), "Growth reserve", 15, FUTURE_COLOR)
		_label(reserve.position + Vector2(12, 68), "footprint to refine", 12, FUTURE_COLOR)
	_label(Vector2(320, 880), "DEVIL'S MOUTH", 22, GUIDE_COLOR)
	_label(Vector2(320, 912), "OPEN DEPTH / NO CROSS-SHAFT FLOOR", 12, GUIDE_COLOR)
	_label(Vector2(-1232, 1200), "Solid opening-route tiles = currently playable", 17, GUIDE_COLOR)
	_label(Vector2(-1232, 1232), "Home -> Dispatch -> Bottom-West -> return", 17, GUIDE_COLOR)
	draw_rect(Rect2(-1232, 1280, 32, 32), GUIDE_COLOR, false, 2)
	_label(Vector2(-1184, 1304), "32 px player reference", 17, GUIDE_COLOR)
	draw_line(Vector2(-1232, 1360), Vector2(-976, 1360), GUIDE_COLOR, 2)
	_label(Vector2(-1232, 1392), "256 px / 16 tiles", 17, GUIDE_COLOR)


func _outline(bounds: Rect2, color: Color) -> void:
	var corners := [bounds.position, Vector2(bounds.end.x, bounds.position.y), bounds.end, Vector2(bounds.position.x, bounds.end.y)]
	for index in range(4):
		draw_dashed_line(corners[index], corners[(index + 1) % 4], color, 1, 8)


func _label(at: Vector2, text: String, size: int, color: Color) -> void:
	draw_string(ThemeDB.fallback_font, at, text, HORIZONTAL_ALIGNMENT_LEFT, -1, size, color)
