extends Control
## Hollow orientation minimap — quiet corner overlay (default on; M toggles).
## Drawn overview from MacroBackground extents + district guides; no second camera.

const Macro := preload("res://hollow_macro_background.gd")
const TOGGLE_ACTION := "toggle_minimap"

const MAP_SIZE := Vector2(440, 204)
## A small map is a glance, not a gazetteer: the header names where you are, the streets show the way, and the district
## names stay off it (their label geometry is still computed for the tests).
const DRAW_LABELS := false
const MAP_VIEW_SCALE := 0.46
const PAD := 8.0
## Strip above the map for the current place name.
const HEADER_H := 16.0
const LABEL_SIZE := 7
## World-space padding around the inhabited map.
const CONTENT_PAD := Vector2(200.0, 120.0)

const PANEL_BG := Color(0.04, 0.06, 0.07, 0.9)
const PANEL_BORDER := Color(0.62, 0.42, 0.28, 0.7)
const ROCK_FILL := Color(0.17, 0.14, 0.12, 0.95)
const FIRMAMENT_FILL := Color(0.14, 0.15, 0.16, 0.95)
const CAVITY_FILL := Color(0.075, 0.1, 0.11, 1.0)
const ZONE_LINE := Color(0.3, 0.42, 0.42, 0.35)
const ZONE_HELD := Color(0.62, 0.36, 0.3, 0.45)
const DECK_COLOR := Color(0.88, 0.64, 0.38, 0.95)
const HEART_COLOR := Color(1.0, 0.8, 0.45, 1.0)
const STAIR_COLOR := Color(0.95, 0.5, 0.22, 0.9)
const LADDER_COLOR := Color(0.5, 0.82, 0.72, 0.9)
const GATE_CLOSED := Color(1.0, 0.32, 0.28, 0.95)
const LIFT_COLOR := Color(0.38, 0.66, 1.0, 0.95)
const GATE_OPEN := Color(0.45, 0.75, 0.5, 0.6)
const LABEL_COLOR := Color(0.82, 0.86, 0.84, 0.7)

var _player: Node2D
var _panel: StyleBox


func _ready() -> void:
	_ensure_toggle_action()
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	custom_minimum_size = MAP_SIZE
	size = MAP_SIZE
	# drawn small: a glance in the corner, scaled about its top-right corner so the layout and the tests still see a full-size map
	scale = Vector2(MAP_VIEW_SCALE, MAP_VIEW_SCALE)
	pivot_offset = Vector2(MAP_SIZE.x, 0.0)
	_panel = preload("res://ui_style.gd").panel_style(&"copper")
	modulate = Color(1.0, 1.0, 1.0, 0.94)
	visible = true
	set_process(true)
	_resolve_player()
	queue_redraw()


func _ensure_toggle_action() -> void:
	if InputMap.has_action(TOGGLE_ACTION):
		return
	InputMap.add_action(TOGGLE_ACTION)
	var ev := InputEventKey.new()
	ev.physical_keycode = KEY_M
	InputMap.action_add_event(TOGGLE_ACTION, ev)


func map_world_bounds() -> Rect2:
	## Orientation frame tracks inhabited Hollow content, not padded WORLD_BOUNDS.
	return map_content_bounds()


static func map_content_bounds() -> Rect2:
	# Top of the Firmament to the bottom of the pit, and the authored galleries side to side. The
	# rock that runs on past the galleries is not framed: it would shrink the map to nothing.
	var bounds := Rect2(HollowLayout.HIGH_WEST_DIG_LEFT, HollowLayout.ENV_TOP, HollowLayout.EAST_FLANK_RIGHT - HollowLayout.HIGH_WEST_DIG_LEFT, HollowLayout.ENV_BOTTOM - HollowLayout.ENV_TOP)
	for district in Macro.district_guides():
		bounds = bounds.merge(district.bounds)
	bounds = Rect2(bounds.position - Vector2(CONTENT_PAD.x, 0.0), bounds.size + Vector2(CONTENT_PAD.x * 2.0, 0.0))
	return bounds.intersection(Macro.WORLD_BOUNDS)


func map_content_fill_ratio() -> float:
	## How much of the panel the aspect-fitted content rect occupies (0..1).
	var fitted := _fitted_map_rect()
	var area := _content_rect()
	if area.size.x <= 0.0 or area.size.y <= 0.0:
		return 0.0
	return (fitted.size.x * fitted.size.y) / (area.size.x * area.size.y)


## Zones that get a name on the panel (the rest draw as quiet outlines). Short panel names.
const PANEL_LABELS := {
	&"ashram_west": "Ashram",
	&"high_west_front": "High-West Dig",
	&"wickwork": "Wickwork",
	&"mid_allotments": "Allotments",
	&"home_court": "Home Court",
	&"bottom_west_threshold": "Bottom-West",
	&"mid_heart": "Mid Heart",
	&"mid_heart_upper": "Upper Heart",
	&"ashram_east": "Ashram East",
	&"glowbeds": "Glowbeds",
	&"mid_east_dig_front": "Dig Front",
	&"lower_east_services": "Lower-East",
	&"cistern": "Cistern",
	&"seep_threshold": "Seep",
}


static func orientation_markers() -> Array[Dictionary]:
	## One centered label per labelled zone footprint, plus the Mouth.
	var mouth_w := HollowLayout.PIT_RIGHT - HollowLayout.PIT_LEFT
	var markers: Array[Dictionary] = [
		{
			"name": "Mouth",
			"bounds": Rect2(HollowLayout.PIT_LEFT, HollowMap.lvl(7.0), mouth_w, HollowMap.LEVEL_GAP),
		},
	]
	for district in Macro.district_guides():
		if PANEL_LABELS.has(district.id):
			markers.append({"name": PANEL_LABELS[district.id], "bounds": district.bounds})
	for marker in markers:
		var b: Rect2 = marker.bounds
		marker["pos"] = b.get_center()
	return markers


## Map-space rect where an orientation label is drawn (centered in section bounds).
func orientation_label_rect(marker: Dictionary) -> Rect2:
	var font := ThemeDB.fallback_font
	var text := str(marker.get("name", ""))
	var text_size := font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, LABEL_SIZE)
	var bounds: Rect2 = marker.get("bounds", Rect2())
	if bounds.size.x <= 0.0 or bounds.size.y <= 0.0:
		var at: Vector2 = world_to_map(marker.get("pos", Vector2.ZERO))
		return Rect2(at, text_size)
	var a := world_to_map(bounds.position)
	var b := world_to_map(bounds.end)
	var section := Rect2(
		Vector2(minf(a.x, b.x), minf(a.y, b.y)),
		Vector2(absf(b.x - a.x), absf(b.y - a.y))
	)
	## True center — do not clamp into the section. Some footprints (Home /
	## Dispatch halves) are narrower than the glyph on the map; pinning would
	## right-shift the label and recreate the floating/edge-clipped look.
	return Rect2(section.get_center() - text_size * 0.5, text_size)


func world_to_map(world: Vector2) -> Vector2:
	var bounds := map_world_bounds()
	var fitted := _fitted_map_rect()
	if bounds.size.x <= 0.0 or bounds.size.y <= 0.0 or fitted.size.x <= 0.0 or fitted.size.y <= 0.0:
		return Vector2.ZERO
	var nx := (world.x - bounds.position.x) / bounds.size.x
	var ny := (world.y - bounds.position.y) / bounds.size.y
	return Vector2(fitted.position.x + nx * fitted.size.x, fitted.position.y + ny * fitted.size.y)


static func mouth_void_color() -> Color:
	## Translucent ink — Mouth reads as open void, not an opaque black plug.
	return Color(0.05, 0.09, 0.11, 0.32)


static func district_draw_bounds(bounds: Rect2) -> Rect2:
	## Keep east-wall district outlines out of the Mouth void. Mid Heart is the
	## primary Mouth crossing — keep its full west-lip→east-lip deck band.
	var mouth_w := HollowLayout.PIT_RIGHT - HollowLayout.PIT_LEFT
	var covers_mouth_band := (
		bounds.position.x <= HollowLayout.PIT_LEFT + 0.5
		and bounds.end.x >= HollowLayout.PIT_RIGHT - 0.5
	)
	if covers_mouth_band:
		## Thin deck band spanning Mouth = Mid Heart bridge (keep). Tall Mouth-
		## filling slabs are rejected (void must stay open).
		if bounds.size.y <= 128.0 and bounds.size.x >= mouth_w - 1.0:
			return bounds
		return Rect2(
			HollowLayout.PIT_LEFT,
			HollowLayout.HEART_Y - 40.0,
			mouth_w,
			80.0
		)
	## Intentional Mouth decks (Mid Heart segments) — keep when inside Mouth.
	var fully_in_mouth := (
		bounds.position.x >= HollowLayout.PIT_LEFT - 0.5
		and bounds.end.x <= HollowLayout.PIT_RIGHT + 0.5
	)
	if fully_in_mouth and bounds.size.x <= HollowMap.LEDGE_REACH_MAX:
		return Rect2() # a Mouth ledge strip: its deck is drawn with its run, the void stays open
	if fully_in_mouth:
		return bounds
	var clipped := bounds
	## Clip any west overhang into Mouth.
	if clipped.position.x < HollowLayout.PIT_RIGHT and clipped.end.x > HollowLayout.PIT_LEFT:
		if clipped.position.x < HollowLayout.PIT_LEFT and clipped.end.x > HollowLayout.PIT_RIGHT:
			## Spans Mouth — keep west stub only (east wall districts use east clip below).
			clipped.size.x = HollowLayout.PIT_LEFT - clipped.position.x
		elif clipped.end.x > HollowLayout.PIT_RIGHT and clipped.position.x < HollowLayout.PIT_RIGHT:
			## East-wall district overlapping Mouth — clip to east lip.
			var x0 := maxf(clipped.position.x, HollowLayout.PIT_RIGHT)
			clipped = Rect2(x0, clipped.position.y, clipped.end.x - x0, clipped.size.y)
		elif clipped.position.x < HollowLayout.PIT_LEFT and clipped.end.x > HollowLayout.PIT_LEFT:
			clipped.size.x = HollowLayout.PIT_LEFT - clipped.position.x
	if clipped.size.x <= 0.0 or clipped.size.y <= 0.0:
		return Rect2()
	return clipped


func toggle() -> void:
	visible = not visible
	if visible:
		queue_redraw()


func is_open() -> bool:
	return visible


## The panel is a quiet overview: redrawing it ten times a second is plenty and keeps it cheap.
const REDRAW_INTERVAL := 0.1
var _redraw_in := 0.0


func _process(delta: float) -> void:
	if not visible:
		return
	_redraw_in -= delta
	if _redraw_in > 0.0:
		return
	_redraw_in = REDRAW_INTERVAL
	if _player == null or not is_instance_valid(_player):
		_resolve_player()
	queue_redraw()


func _unhandled_input(event: InputEvent) -> void:
	var pressed := false
	if InputMap.has_action(TOGGLE_ACTION) and event.is_action_pressed(TOGGLE_ACTION):
		pressed = true
	elif event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_M:
		pressed = true
	if not pressed:
		return
	toggle()
	get_viewport().set_input_as_handled()


func _resolve_player() -> void:
	var scene := get_tree().current_scene
	if scene:
		_player = scene.get_node_or_null("Player") as Node2D
	if _player == null:
		_player = get_tree().get_first_node_in_group("player") as Node2D
	if _player == null:
		# Headless tests parent main.tscn under the SceneTree root.
		var root := get_tree().root
		for child in root.get_children():
			var found := child.get_node_or_null("Player") as Node2D
			if found:
				_player = found
				return


func _content_rect() -> Rect2:
	var s := size
	if s.x < 1.0 or s.y < 1.0:
		s = custom_minimum_size
	return Rect2(Vector2(PAD, PAD + HEADER_H), s - Vector2(PAD * 2.0, PAD * 2.0 + HEADER_H))


func _overlaps_any(candidate: Rect2, existing: Array[Rect2]) -> bool:
	for r in existing:
		if candidate.intersects(r):
			return true
	return false


func _fitted_map_rect() -> Rect2:
	## Aspect-correct fit of map_world_bounds into the panel content area.
	var area := _content_rect()
	var bounds := map_world_bounds()
	if bounds.size.x <= 0.0 or bounds.size.y <= 0.0 or area.size.x <= 0.0 or area.size.y <= 0.0:
		return area
	var scale := minf(area.size.x / bounds.size.x, area.size.y / bounds.size.y)
	var used := bounds.size * scale
	var origin := area.position + (area.size - used) * 0.5
	return Rect2(origin, used)


func _rect_to_map(r: Rect2) -> Rect2:
	var a := world_to_map(r.position)
	var b := world_to_map(r.end)
	return Rect2(Vector2(minf(a.x, b.x), minf(a.y, b.y)), Vector2(absf(b.x - a.x), absf(b.y - a.y)))


func _line(a: Vector2, b: Vector2, color: Color, width: float, area: Rect2) -> void:
	var ma := world_to_map(a)
	var mb := world_to_map(b)
	if not area.grow(2.0).has_point(ma) and not area.grow(2.0).has_point(mb):
		return
	draw_line(ma, mb, color, width, true)


func _current_zone_name() -> String:
	if _player == null or not is_instance_valid(_player):
		return ""
	var zones := get_tree().root.get_node_or_null("Zones")
	if zones == null:
		return ""
	var zone_id := str(zones.get_zone_at(_player.global_position))
	return str(zones.get_display_name(zone_id)) if zone_id != "" else ""


## The static map (shell, Mouth, level rows, zone outlines, decks, stairs, ladders, labels) is recorded once per
## panel size into draw commands and replayed each redraw; only the player's row, the gates, the player and the
## header are recomputed. (Recomputing it all, with dozens of zones and over a hundred decks, cost a visible
## slice of every frame.)
var _cmds: Array = []
var _cmd_size := Vector2.ZERO
var _gates_cache: Array[Dictionary] = []


func _cline(a: Vector2, b: Vector2, color: Color, width: float) -> void:
	_cmds.append([0, a, b, color, width])


func _crect(r: Rect2, color: Color, filled: bool = true, width: float = 1.0) -> void:
	if filled:
		_cmds.append([1, r, color, true, width])
		return
	# An unfilled rect is drawn as four lines.
	var tl := r.position
	var tr := Vector2(r.end.x, r.position.y)
	var br := r.end
	var bl := Vector2(r.position.x, r.end.y)
	_cline(tl, tr, color, width)
	_cline(tr, br, color, width)
	_cline(br, bl, color, width)
	_cline(bl, tl, color, width)


func _cstr(pos: Vector2, text: String, size_px: int, color: Color) -> void:
	_cmds.append([2, pos, text, size_px, color])


func _cline_world(a: Vector2, b: Vector2, color: Color, width: float, area: Rect2) -> void:
	var ma := world_to_map(a)
	var mb := world_to_map(b)
	if not area.grow(2.0).has_point(ma) and not area.grow(2.0).has_point(mb):
		return
	_cline(ma, mb, color, width)


func _build_static(s: Vector2) -> void:
	_cmds.clear()
	_gates_cache.clear()
	var area := _content_rect()
	var bounds := map_world_bounds()
	_crect(area, Color(0.055, 0.075, 0.085, 1.0))

	# The rock shell: Firmament across the top, a flank each side, a slab under each wall. The
	# civic cavity is left open between the walls, and the Mouth runs on down as the pit.
	_crect(_rect_to_map(HollowMap.env_rect()).intersection(area), ROCK_FILL)
	var firmament := _rect_to_map(Rect2(HollowMap.ENV_LEFT, HollowMap.ENV_TOP, HollowMap.ENV_RIGHT - HollowMap.ENV_LEFT, HollowMap.ROCK_TOP - HollowMap.ENV_TOP)).intersection(area)
	_crect(firmament, FIRMAMENT_FILL)
	_crect(_rect_to_map(HollowMap.cavity_rect()).intersection(area), CAVITY_FILL)
	_cstr(Vector2(firmament.position.x + 4.0, firmament.end.y - 3.0), "FIRMAMENT", LABEL_SIZE, Color(0.7, 0.75, 0.75, 0.35))

	# The Mouth: open void between the lips, never a plug.
	var mouth := _rect_to_map(Macro.MOUTH_BOUNDS).intersection(area)
	_crect(mouth, Color(0.01, 0.02, 0.03, 0.85))
	var lip := Color(0.5, 0.62, 0.6, 0.4)
	_cline(Vector2(mouth.position.x, mouth.position.y), Vector2(mouth.position.x, mouth.end.y), lip, 1.0)
	_cline(Vector2(mouth.end.x, mouth.position.y), Vector2(mouth.end.x, mouth.end.y), lip, 1.0)

	# Level rows: faint (the player's row is brightened per redraw).
	for k in range(HollowMap.LEVELS):
		var gy := HollowMap.lvl(float(k))
		_cline_world(Vector2(bounds.position.x, gy), Vector2(bounds.end.x, gy), Color(0.4, 0.55, 0.55, 0.08), 1.0, area)

	# Zones: outlines only; places held out at the start read warm, never solid fills.
	var held_zones := _held_zone_ids()
	for district in Macro.district_guides():
		var drawn := district_draw_bounds(district.bounds)
		if drawn.size.x <= 0.0 or drawn.size.y <= 0.0:
			continue
		var r := _rect_to_map(drawn).intersection(area)
		_crect(r, ZONE_HELD if held_zones.has(district.id) else ZONE_LINE, false, 1.0)

	# The map itself: decks, stairs, ladders. (Gates are drawn per redraw: they open and close.)
	for piece in HollowMap.deck_pieces():
		var heart: bool = HollowMap.is_heart_zone(HollowMap.run_by_id(piece["run"])["zone"])
		_cline_world(Vector2(piece["x0"], piece["y"]), Vector2(piece["x1"], piece["y"]), HEART_COLOR if heart else DECK_COLOR, 2.0 if heart else 1.6, area)
	for stair in HollowMap.stairs():
		_cline_world(Vector2(stair["foot_x"], stair["foot_y"]), Vector2(stair["top_x"], stair["top_y"]), STAIR_COLOR, 1.4, area)
	for ladder in HollowMap.ladders():
		var lx: float = float(ladder["open_x"]) + 32.0
		_cline_world(Vector2(lx, ladder["top_y"]), Vector2(lx, ladder["bottom_y"]), LADDER_COLOR, 1.2, area)
	for lift in HollowMap.lifts():
		var stops: Array = lift["stops"]
		var cx: float = float(lift["open_x"]) + float(lift["width"]) * 0.5
		_cline_world(Vector2(cx, stops[0]), Vector2(cx, stops[stops.size() - 1]), LIFT_COLOR, 2.4, area)
		for stop_y in stops:
			var sp := world_to_map(Vector2(cx, stop_y))
			if area.has_point(sp):
				_crect(Rect2(sp - Vector2(1.5, 1.5), Vector2(3.0, 3.0)), LIFT_COLOR)
	for gate in HollowMap.gates():
		var run := HollowMap.run_by_id(gate["run"])
		if run.is_empty():
			continue
		var gp := world_to_map(Vector2(gate["x"], run["y"]))
		if area.has_point(gp):
			_gates_cache.append({"id": gate["id"], "pos": gp})

	# Labels: soft shadow, nudged apart, centred on their zone footprint.
	var placed: Array[Rect2] = []
	for marker in orientation_markers():
		var label_rect := orientation_label_rect(marker)
		if not area.intersects(label_rect):
			continue
		var guard := 0
		while guard < 6 and _overlaps_any(label_rect, placed):
			label_rect.position.y += label_rect.size.y + 1.0
			guard += 1
		var centre_x := label_rect.get_center().x
		label_rect.position.x = clampf(centre_x - label_rect.size.x * 0.5, area.position.x + 1.0, area.end.x - label_rect.size.x - 1.0)
		label_rect.position.y = clampf(label_rect.position.y, area.position.y, area.end.y - label_rect.size.y)
		placed.append(label_rect)
		var at := Vector2(label_rect.position.x, label_rect.position.y + label_rect.size.y - 2.0)
		if DRAW_LABELS:
			_cstr(at + Vector2(1, 1), str(marker.name), LABEL_SIZE, Color(0, 0, 0, 0.55))
			_cstr(at, str(marker.name), LABEL_SIZE, LABEL_COLOR)
	_cmd_size = s


func _draw() -> void:
	var s := size
	if s.x < 1.0 or s.y < 1.0:
		s = custom_minimum_size
	draw_style_box(_panel, Rect2(Vector2.ZERO, s))
	if _cmds.is_empty() or _cmd_size != s:
		_build_static(s)
	var area := _content_rect()
	var font := ThemeDB.fallback_font
	var bounds := map_world_bounds()
	for c in _cmds:
		match int(c[0]):
			0:
				draw_line(c[1], c[2], c[3], c[4], true)
			1:
				# draw_rect(filled) stalled the main thread for ~15 ms per big rect in the Compatibility renderer;
				# a coloured polygon of the same four corners costs microseconds.
				var rr: Rect2 = c[1]
				draw_colored_polygon(PackedVector2Array([rr.position, Vector2(rr.end.x, rr.position.y), rr.end, Vector2(rr.position.x, rr.end.y)]), c[2])
			2:
				draw_string(font, c[1], c[2], HORIZONTAL_ALIGNMENT_LEFT, -1, int(c[3]), c[4])

	# The player's level row, brighter.
	var player_row := -1
	if _player != null and is_instance_valid(_player):
		player_row = int(roundf((_player.global_position.y + 32.0 - HollowMap.LEVEL_ORIGIN) / HollowMap.LEVEL_GAP))
	if player_row >= 0 and player_row < HollowMap.LEVELS:
		var gy := HollowMap.lvl(float(player_row))
		var ra := world_to_map(Vector2(bounds.position.x, gy))
		var rb := world_to_map(Vector2(bounds.end.x, gy))
		draw_line(ra, rb, Color(0.4, 0.55, 0.55, 0.2), 1.0, true)

	# Gates: shut or open as they stand now.
	var access := get_tree().root.get_node_or_null("Access")
	for g in _gates_cache:
		var open: bool = access != null and bool(access.is_open(g["id"]))
		var gp: Vector2 = g["pos"]
		draw_line(gp + Vector2(0, -4), gp + Vector2(0, 1), GATE_OPEN if open else GATE_CLOSED, 2.0)

	# The player: a dot, nothing else.
	if _player and is_instance_valid(_player):
		var p := world_to_map(_player.global_position + Vector2(16.0, 16.0))
		if area.grow(3.0).has_point(p):
			var pulse := 0.5 + 0.5 * sin(Time.get_ticks_msec() * 0.006)
			draw_circle(p, 5.0 + pulse * 2.0, Color(1.0, 0.85, 0.5, 0.22 * (1.0 - pulse * 0.5)))
			draw_circle(p, 2.6, Color(1.0, 0.92, 0.7, 1.0))
			draw_arc(p, 3.6, 0.0, TAU, 14, Color(0.08, 0.06, 0.04, 0.9), 1.0, true)

	# Header: where you are; hint on the right.
	var zone_name := _current_zone_name()
	draw_string(font, Vector2(PAD, PAD + 9.0), zone_name if zone_name != "" else "Hollow", HORIZONTAL_ALIGNMENT_LEFT, s.x - PAD * 2.0 - 60.0, 11, Color(0.93, 0.83, 0.62, 0.95))
	draw_string(font, Vector2(s.x - PAD - 54.0, PAD + 9.0), "M  hide", HORIZONTAL_ALIGNMENT_RIGHT, 54.0, 8, Color(0.55, 0.6, 0.58, 0.6))


## Zones held out at the start (the far side of every start-closed gate), for tinting.
func _held_zone_ids() -> Dictionary:
	var out := {}
	for point in HollowMap.held_points():
		for z in HollowMap.zones():
			if not z.get("volume", false) and (z["rect"] as Rect2).has_point(point + Vector2(0.0, -32.0)):
				out[z["id"]] = true
	return out
