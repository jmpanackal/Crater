@tool
extends Node2D

const Layout := preload("res://hollow_layout.gd")
## The whole dig envelope, symmetric about the Mouth centre (x=3200). The rock shell is painted over
## this by the terrain layers; what shows through is the civic cavity.
const WORLD_BOUNDS := Rect2(Layout.ENV_LEFT, Layout.ENV_TOP, Layout.ENV_RIGHT - Layout.ENV_LEFT, Layout.ENV_BOTTOM - Layout.ENV_TOP)
## The Mouth: open void from under the Firmament all the way down the pit.
const MOUTH_BOUNDS := Rect2(Layout.PIT_LEFT, Layout.ROCK_TOP, Layout.PIT_RIGHT - Layout.PIT_LEFT, Layout.ENV_BOTTOM - Layout.ROCK_TOP)
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


## Named places, straight from the map data (HollowMap.zones). One guide per zone.
static func district_guides() -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	for z in HollowMap.zones():
		if z.get("volume", false):
			continue
		var anchor: Vector2 = z["anchor"]
		out.append({"id": z["id"], "name": z["display"], "bounds": z["rect"], "level": anchor.y})
	return out


## Lifts and ladders, as vertical guides: {"name", "x", "label_y", "stops"}.
static func transport_guides() -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	for lf in HollowMap.lifts():
		var stops: Array = lf["stops"]
		out.append({"name": "Presswater lift: %s" % str(lf["id"]), "x": float(lf["open_x"]), "label_y": float(stops[0]) - 40.0, "stops": stops})
	for l in HollowMap.ladders():
		out.append({"name": str(l["id"]), "x": float(l["open_x"]), "label_y": float(l["top_y"]) - 20.0, "stops": [l["top_y"], l["bottom_y"]], "ladder": true})
	return out


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
		draw_rect(WORLD_BOUNDS, Color(0.035, 0.05, 0.085))
		# Ink void — open shaft, not a solid filler block (docs: #091419).
		draw_rect(MOUTH_BOUNDS, Color(0.02, 0.03, 0.06))
		return
	if not show_planning_guides or (not Engine.is_editor_hint() and not show_guides_in_game):
		return
	_label(Vector2(-2800, 160), "HOLLOW SCALE PLAN  |  GUIDES ONLY - NO COLLISION", 24, GUIDE_COLOR)
	_label(Vector2(-2800, 320), "16 px tiles / 32 px player. Dashed extents and routes are provisional, not playable platforms.", 17, GUIDE_COLOR)
	_label(Vector2(-2800, 800), "FIRMAMENT / sustained upward excavation, locked at start", 19, GUIDE_COLOR)
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
	for stair in HollowMap.stairs():
		draw_line(Vector2(stair["foot_x"], stair["foot_y"]), Vector2(stair["top_x"], stair["top_y"]), FUTURE_COLOR, 2)
	for reserve in HollowMap.reserves():
		var rect: Rect2 = reserve["rect"]
		_outline(rect, FUTURE_COLOR)
		_label(rect.position + Vector2(12, 48), "Growth reserve", 15, FUTURE_COLOR)
		_label(rect.position + Vector2(12, 68), str(reserve["district"]), 12, FUTURE_COLOR)
	for gate in HollowMap.gates():
		var run := HollowMap.run_by_id(gate["run"])
		if not run.is_empty():
			draw_line(Vector2(gate["x"], float(run["y"]) - 128.0), Vector2(gate["x"], run["y"]), Color(1.0, 0.35, 0.3, 0.9), 3)
	_label(Vector2(Layout.HEART_MID_X - 80.0, Layout.HEART_Y + 1200.0), "DEVIL'S MOUTH", 22, GUIDE_COLOR)
	_label(Vector2(Layout.HEART_MID_X - 120.0, Layout.HEART_Y + 1360.0), "OPEN VOID / MID HEART IS THE ONLY CROSSING", 12, GUIDE_COLOR)
	## Physical reference markers — deliberately NOT scaled: still the real
	## 32px player body and the real 256px (16-tile) span, so they stay true
	## after the world-scale pass. Only their anchor position moves.
	var ref := Vector2(Layout.HIGH_WEST_DIG_LEFT, Layout.WEST_LW_UPPER_Y - 600.0)
	draw_rect(Rect2(ref, Vector2(32, 32)), GUIDE_COLOR, false, 2)
	_label(ref + Vector2(40, 40), "32 px player reference", 17, GUIDE_COLOR)
	draw_line(ref + Vector2(0, 80), ref + Vector2(256, 80), GUIDE_COLOR, 2)
	_label(ref + Vector2(0, 120), "256 px / 16 tiles", 17, GUIDE_COLOR)


func _outline(bounds: Rect2, color: Color) -> void:
	var corners := [bounds.position, Vector2(bounds.end.x, bounds.position.y), bounds.end, Vector2(bounds.position.x, bounds.end.y)]
	for index in range(4):
		draw_dashed_line(corners[index], corners[(index + 1) % 4], color, 1, 8)


func _label(at: Vector2, text: String, size: int, color: Color) -> void:
	draw_string(ThemeDB.fallback_font, at, text, HORIZONTAL_ALIGNMENT_LEFT, -1, size, color)
