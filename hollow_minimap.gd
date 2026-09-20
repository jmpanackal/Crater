extends Control
## Hollow orientation minimap — quiet corner overlay (default on; M toggles).
## Drawn overview from MacroBackground extents + district guides; no second camera.

const Macro := preload("res://hollow_macro_background.gd")
const UiStyleRef := preload("res://ui_style.gd")
const TOGGLE_ACTION := "toggle_minimap"

const MAP_SIZE := Vector2(268, 156)
const PAD := 6.0
const LABEL_SIZE := 9
## Tight pad around inhabited districts — not the full Macro WORLD_BOUNDS margins.
## World-scale pass (2026-09-19): x5 — this is world-space padding, unlike
## MAP_SIZE/PAD/LABEL_SIZE below which stay fixed screen-space UI sizing.
const CONTENT_PAD := Vector2(240.0, 160.0)

var _player: Node2D
var _style: StyleBoxFlat


func _ready() -> void:
	_ensure_toggle_action()
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	custom_minimum_size = MAP_SIZE
	size = MAP_SIZE
	_style = UiStyleRef.quiet_panel_style()
	modulate = Color(1.0, 1.0, 1.0, 0.78)
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
	var bounds := Macro.MOUTH_BOUNDS
	for district in Macro.district_guides():
		bounds = bounds.merge(district.bounds)
	bounds = Rect2(bounds.position - CONTENT_PAD, bounds.size + CONTENT_PAD * 2.0)
	return bounds.intersection(Macro.WORLD_BOUNDS)


func map_content_fill_ratio() -> float:
	## How much of the panel the aspect-fitted content rect occupies (0..1).
	var fitted := _fitted_map_rect()
	var area := _content_rect()
	if area.size.x <= 0.0 or area.size.y <= 0.0:
		return 0.0
	return (fitted.size.x * fitted.size.y) / (area.size.x * area.size.y)


static func orientation_markers() -> Array[Dictionary]:
	## Sparse placards for greybox orientation — each carries the section
	## bounds the label must be centered in (matches Macro district footprints
	## so labels sit in the boxes the player sees, not tiny named pads).
	var band := HollowLayout.WEST_LEVEL_GAP
	var wh_l := HollowLayout.WEST_HOLLOW_LEFT
	var wh_w := HollowLayout.WEST_HOLLOW_RIGHT - HollowLayout.WEST_HOLLOW_LEFT
	var mouth_w := HollowLayout.PIT_RIGHT - HollowLayout.PIT_LEFT
	var west_dig_w := (
		HollowLayout.HIGH_WEST_DIG_RIGHT - HollowLayout.HIGH_WEST_DIG_LEFT + wh_w
	)
	## Lower-worker band: Dispatch owns the west half, Home Court the east half
	## (same vertical section the minimap outlines as Lower worker terraces).
	var lw_y := HollowLayout.WEST_LW_UPPER_Y - 160.0
	var lw_h := band * 2.0
	var lw_mid_x := wh_l + wh_w * 0.5
	var markers: Array[Dictionary] = [
		{
			"name": "Home Court",
			"bounds": Rect2(lw_mid_x, lw_y, wh_w * 0.5, lw_h),
		},
		{
			"name": "Dispatch",
			"bounds": Rect2(wh_l, lw_y, wh_w * 0.5, lw_h),
		},
		{
			"name": "Mouth",
			"bounds": Rect2(
				HollowLayout.PIT_LEFT,
				HollowLayout.WEST_LW_UPPER_Y - band * 0.25,
				mouth_w,
				band * 0.75
			),
		},
		{
			"name": "Mid Heart",
			"bounds": Rect2(
				HollowLayout.PIT_LEFT,
				HollowLayout.HEART_Y - 200.0,
				mouth_w,
				400.0
			),
		},
		{
			"name": "Wickwork",
			"bounds": Rect2(wh_l, HollowLayout.WICK_Y - 160.0, wh_w, band * 2.0),
		},
		{
			"name": "Dig Front",
			"bounds": Rect2(
				HollowLayout.MID_EAST_DIG_FRONT.x,
				2160.0,
				HollowLayout.MID_EAST_DIG_FRONT.y - HollowLayout.MID_EAST_DIG_FRONT.x,
				1440.0
			),
		},
		{
			"name": "West Dig",
			"bounds": Rect2(
				HollowLayout.HIGH_WEST_DIG_LEFT,
				HollowLayout.WEST_HIGH_UPPER_Y - 160.0,
				west_dig_w,
				band * 2.0
			),
		},
		{
			"name": "Cistern",
			"bounds": Rect2(
				HollowLayout.PIT_RIGHT,
				4640.0,
				4640.0,
				1440.0
			),
		},
	]
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


func _process(_delta: float) -> void:
	if not visible:
		return
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
	return Rect2(Vector2(PAD, PAD), s - Vector2(PAD * 2.0, PAD * 2.0))


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


func _draw() -> void:
	var s := size
	if s.x < 1.0 or s.y < 1.0:
		s = custom_minimum_size
	if _style:
		draw_style_box(_style, Rect2(Vector2.ZERO, s))
	var area := _content_rect()
	draw_rect(area, Color(0.06, 0.09, 0.1, 0.92))
	# Mouth void — translucent band (open shaft), not an opaque plug / aqua stack.
	var mouth_a := world_to_map(Macro.MOUTH_BOUNDS.position)
	var mouth_b := world_to_map(Macro.MOUTH_BOUNDS.end)
	var mouth := Rect2(
		Vector2(minf(mouth_a.x, mouth_b.x), minf(mouth_a.y, mouth_b.y)),
		Vector2(absf(mouth_b.x - mouth_a.x), absf(mouth_b.y - mouth_a.y))
	)
	draw_rect(mouth.intersection(area), mouth_void_color())
	# Soft lip lines so the void edges stay readable without filling the shaft.
	var lip := Color(0.45, 0.58, 0.55, 0.35)
	draw_line(Vector2(mouth.position.x, mouth.position.y), Vector2(mouth.position.x, mouth.end.y), lip, 1.0)
	draw_line(Vector2(mouth.end.x, mouth.position.y), Vector2(mouth.end.x, mouth.end.y), lip, 1.0)
	## Outline only — never solid aqua district fills on the minimap.
	## Landmark districts (named on the panel) draw brighter; the rest recede
	## to a quiet backdrop so the labeled footprints stay the clear signal.
	var district_color := Color(0.28, 0.52, 0.5, 0.55)
	var backdrop_color := Color(0.28, 0.52, 0.5, 0.28)
	var mid_heart_color := Color(0.72, 0.62, 0.42, 0.85)
	var dig_color := Color(0.55, 0.42, 0.32, 0.7)
	for district in Macro.district_guides():
		var bounds: Rect2 = district_draw_bounds(district.bounds)
		if bounds.size.x <= 0.0 or bounds.size.y <= 0.0:
			continue
		var a := world_to_map(bounds.position)
		var b := world_to_map(bounds.end)
		var r := Rect2(
			Vector2(minf(a.x, b.x), minf(a.y, b.y)),
			Vector2(absf(b.x - a.x), absf(b.y - a.y))
		)
		var name := str(district.name)
		var is_mid_heart := name.begins_with("Mid Heart")
		var is_dig := name.contains("Dig Front")
		var is_landmark := is_mid_heart or is_dig or name.begins_with("Wickwork") or name.begins_with("Cistern")
		var outline := mid_heart_color if is_mid_heart else (dig_color if is_dig else (district_color if is_landmark else backdrop_color))
		var width := 2.0 if is_mid_heart or is_dig else 1.0
		draw_rect(r.intersection(area), outline, false, width)
	var label_color := Color(0.72, 0.78, 0.76, 0.72)
	var font := ThemeDB.fallback_font
	var placed_labels: Array[Rect2] = []
	for marker in orientation_markers():
		var bounds: Rect2 = marker.get("bounds", Rect2())
		var at: Vector2 = world_to_map(marker.pos)
		if bounds.size.x > 0.0 and bounds.size.y > 0.0:
			var ba := world_to_map(bounds.position)
			var bb := world_to_map(bounds.end)
			var section := Rect2(
				Vector2(minf(ba.x, bb.x), minf(ba.y, bb.y)),
				Vector2(absf(bb.x - ba.x), absf(bb.y - ba.y))
			)
			if not section.intersects(area):
				continue
			at = section.get_center()
		elif not area.has_point(at):
			continue
		draw_circle(at, 1.5, Color(0.62, 0.82, 0.78, 0.85))
		var text := str(marker.name)
		var text_size := font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, LABEL_SIZE)
		var label_rect := orientation_label_rect(marker)
		## Nearby markers can still collide at this scale — nudge down but keep
		## the label's horizontal center locked to the section.
		var section_cx := label_rect.get_center().x
		var guard := 0
		while guard < 8 and _overlaps_any(label_rect, placed_labels):
			label_rect.position.y += text_size.y + 1.0
			guard += 1
		label_rect.position.y = clampf(label_rect.position.y, area.position.y, area.end.y - label_rect.size.y)
		## Panel clamp may shift X; restore section-centered X afterward when
		## the glyph still fits inside the panel.
		var desired_x := section_cx - label_rect.size.x * 0.5
		if desired_x >= area.position.x and desired_x + label_rect.size.x <= area.end.x:
			label_rect.position.x = desired_x
		else:
			label_rect.position.x = clampf(desired_x, area.position.x, area.end.x - label_rect.size.x)
		placed_labels.append(label_rect)
		draw_string(
			font,
			Vector2(label_rect.position.x, label_rect.position.y + text_size.y),
			text,
			HORIZONTAL_ALIGNMENT_LEFT,
			-1,
			LABEL_SIZE,
			label_color
		)
	if _player and is_instance_valid(_player):
		var p := world_to_map(_player.global_position)
		if area.grow(2.0).has_point(p):
			draw_circle(p, 3.0, Color(0.95, 0.82, 0.55, 0.95))
			draw_circle(p, 1.5, Color(0.98, 0.95, 0.85, 1.0))
	draw_string(
		ThemeDB.fallback_font,
		Vector2(PAD + 2, s.y - 3),
		"M minimap",
		HORIZONTAL_ALIGNMENT_LEFT,
		-1,
		8,
		Color(0.55, 0.6, 0.58, 0.45)
	)
