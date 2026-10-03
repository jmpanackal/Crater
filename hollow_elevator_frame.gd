extends Node2D
## The fixed steel frame of one Presswater elevator, one continuous run from the top lintel to the bottom stop:
## two tall hydraulic columns standing in the 16 px margin beside the cab (a cylinder sleeve with a chrome ram
## inside it, ribbed collars, a flange at every stop and a pressure pipe up the outer side), cross-braces between
## them, and a dim back plate so the shaft reads as one machine and never as a gap in the rock. Decoration only:
## no collision. Built by hollow_structures.gd from HollowMap.lifts().

const CHUNK := 128.0
const COLUMN_W := 12.0
const BRACE_STEP := 64.0
const TOP_CLEAR := 128.0 ## frame stands this far above the top deck, level with the stop lintels

var lift_id: StringName = &""
var _x0 := 0.0
var _w := 0.0
var _top := 0.0
var _bottom := 0.0
var _stops: Array = []
var _premium := false


func _ready() -> void:
	var data := HollowLayout.lift_data(lift_id)
	_x0 = float(data["open_x"])
	_w = float(data["width"])
	_stops = data["stops"]
	_premium = data["kind"] == &"premium"
	_top = float(_stops[0]) - TOP_CLEAR
	_bottom = float(_stops[_stops.size() - 1]) + 12.0
	z_index = 1
	queue_redraw()


func _palette() -> Dictionary:
	if _premium:
		return {
			"sleeve": Color(0.55, 0.42, 0.22), "sleeve_hi": Color(0.8, 0.66, 0.4), "ram": Color(0.9, 0.84, 0.66),
			"collar": Color(0.36, 0.27, 0.14), "brace": Color(0.42, 0.33, 0.18, 0.8), "plate": Color(0.16, 0.13, 0.09, 0.55),
			"pipe": Color(0.5, 0.68, 0.66),
		}
	return {
		"sleeve": Color(0.3, 0.34, 0.37), "sleeve_hi": Color(0.5, 0.56, 0.6), "ram": Color(0.78, 0.82, 0.84),
		"collar": Color(0.18, 0.2, 0.22), "brace": Color(0.26, 0.29, 0.31, 0.8), "plate": Color(0.09, 0.11, 0.13, 0.55),
		"pipe": Color(0.38, 0.58, 0.62),
	}


func _draw() -> void:
	var pal := _palette()
	var left_x := _x0 - 14.0
	var right_x := _x0 + _w + 2.0
	# back plate: one strip per chunk, behind the rider, so it never becomes one huge filled rect
	var y := _top
	while y < _bottom:
		var h := minf(CHUNK, _bottom - y)
		draw_rect(Rect2(_x0, y, _w, h), pal["plate"])
		y += h
	# cross-braces
	y = _top + BRACE_STEP
	while y < _bottom - 8.0:
		draw_rect(Rect2(_x0, y, _w, 3.0), pal["brace"])
		draw_rect(Rect2(_x0, y + 3.0, _w, 1.0), Color(0, 0, 0, 0.25))
		y += BRACE_STEP
	# columns: sleeve (cylinder) in chunks, chrome ram down the middle, highlight edge
	for cx in [left_x, right_x]:
		var cy := _top
		while cy < _bottom:
			var h := minf(CHUNK, _bottom - cy)
			draw_rect(Rect2(cx, cy, COLUMN_W, h), pal["sleeve"])
			draw_rect(Rect2(cx + 1.0, cy, 3.0, h), pal["sleeve_hi"])
			draw_rect(Rect2(cx + COLUMN_W - 2.0, cy, 2.0, h), Color(0, 0, 0, 0.35))
			draw_rect(Rect2(cx + 5.0, cy, 2.0, h), pal["ram"])
			cy += h
		# ribbed collars every 32 px give the column its hydraulic look
		var ry := _top + 16.0
		while ry < _bottom:
			draw_rect(Rect2(cx - 2.0, ry, COLUMN_W + 4.0, 4.0), pal["collar"])
			ry += 32.0
		# a flange at the top of the frame and at every stop
		draw_rect(Rect2(cx - 4.0, _top - 6.0, COLUMN_W + 8.0, 8.0), pal["collar"])
		for stop_y in _stops:
			draw_rect(Rect2(cx - 4.0, float(stop_y) - 10.0, COLUMN_W + 8.0, 10.0), pal["collar"])
			draw_rect(Rect2(cx - 4.0, float(stop_y) - 10.0, COLUMN_W + 8.0, 2.0), pal["sleeve_hi"])
		draw_rect(Rect2(cx - 4.0, _bottom - 4.0, COLUMN_W + 8.0, 8.0), pal["collar"])
	# pressure pipe up the outer side of the right column, with a coupling at each stop
	var px := right_x + COLUMN_W + 2.0
	var py := _top
	while py < _bottom:
		var h := minf(CHUNK, _bottom - py)
		draw_rect(Rect2(px, py, 4.0, h), pal["pipe"])
		py += h
	for stop_y in _stops:
		draw_rect(Rect2(px - 2.0, float(stop_y) - 14.0, 8.0, 6.0), pal["collar"])
	# header: the cylinder housing the rams run into
	draw_rect(Rect2(left_x - 4.0, _top - 14.0, right_x + COLUMN_W + 4.0 - left_x + 4.0, 10.0), pal["collar"])
	draw_rect(Rect2(left_x - 4.0, _top - 14.0, right_x + COLUMN_W + 4.0 - left_x + 4.0, 2.0), pal["sleeve_hi"])
