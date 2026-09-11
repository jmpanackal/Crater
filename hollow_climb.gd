extends Area2D
## Visible ladder between Hollow decks — walkable geometry cue + climb zone.
## Player hangs/climbs with W/S while overlapping; Space jumps off.
## Position is the upper deck top; shaft_size.y reaches the lower deck top.

@export var shaft_size: Vector2 = Vector2(40, 192)
@export var hint_text: String = "[W/S] climb"
@export var rail_color: Color = Color(0.62, 0.42, 0.28, 1) # copper-wood
@export var rung_color: Color = Color(0.78, 0.58, 0.38, 1)
## Extra climb hitbox above the visual top so a standing player on the upper deck overlaps.
@export var grab_margin_top: float = 40.0
## Inset climb hitbox from visual rails so the core zone matches the copper ladder.
@export var grab_inset: float = 4.0
## Extra grab reach onto upper-deck lips beside the rails (not into the pit).
@export var grab_reach: float = 20.0
## Upper-deck floor gap this shaft climbs through (world X). Lower landing stays solid.
@export var deck_open_x: float = 0.0
@export var deck_open_width: float = 64.0
## When climbing onto the upper deck: -1 prefer/force left landing, 0 nearest, 1 force right.
@export var upper_land_side: int = 0

var _hint: Label


func deck_top_y() -> float:
	return global_position.y


func deck_bottom_y() -> float:
	return global_position.y + shaft_size.y


func upper_opening() -> Vector2:
	## Returns (open_x0, open_x1) for the upper-deck gap.
	return Vector2(deck_open_x, deck_open_x + deck_open_width)


func _ready() -> void:
	collision_layer = 0
	collision_mask = 1
	monitoring = true
	monitorable = false
	z_index = 2
	_ensure_collision()
	_build_visuals()
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)


func _ensure_collision() -> void:
	var col := get_node_or_null("CollisionShape2D") as CollisionShape2D
	if col == null:
		col = CollisionShape2D.new()
		col.name = "CollisionShape2D"
		add_child(col)
	var shape := col.shape as RectangleShape2D
	if shape == null:
		shape = RectangleShape2D.new()
	else:
		shape = shape.duplicate() as RectangleShape2D
	# Visual ladder starts at (0,0); hitbox extends upward so deck-top feet still overlap.
	# Core width matches rails; grab_reach extends onto upper-deck lips beside the opening.
	var hit_w := maxf(24.0, shaft_size.x - grab_inset * 2.0)
	var hit_center_x := shaft_size.x * 0.5
	if upper_land_side < 0:
		hit_w += grab_reach
		hit_center_x -= grab_reach * 0.5
	elif upper_land_side > 0:
		hit_w += grab_reach
		hit_center_x += grab_reach * 0.5
	else:
		hit_w += grab_reach * 2.0
	var hit_h := shaft_size.y + grab_margin_top
	shape.size = Vector2(hit_w, hit_h)
	col.shape = shape
	col.position = Vector2(hit_center_x, hit_h * 0.5 - grab_margin_top)


func _build_visuals() -> void:
	var w := shaft_size.x
	var h := shaft_size.y
	var rail_w := 5.0
	var wood_dark := rail_color.darkened(0.35)
	wood_dark.a = 0.92

	# Backboard reads as timber depth behind the climbable rails.
	var back := ColorRect.new()
	back.name = "WoodBack"
	back.size = Vector2(w - 6, h)
	back.position = Vector2(3, 0)
	back.color = Color(0.22, 0.14, 0.09, 0.88)
	back.mouse_filter = Control.MOUSE_FILTER_IGNORE
	back.z_index = -1
	add_child(back)

	var left_rail := ColorRect.new()
	left_rail.name = "RailLeft"
	left_rail.size = Vector2(rail_w, h)
	left_rail.position = Vector2(2, 0)
	left_rail.color = rail_color
	left_rail.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(left_rail)
	_rail_grain(left_rail, wood_dark)

	var right_rail := ColorRect.new()
	right_rail.name = "RailRight"
	right_rail.size = Vector2(rail_w, h)
	right_rail.position = Vector2(w - rail_w - 2, 0)
	right_rail.color = rail_color
	right_rail.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(right_rail)
	_rail_grain(right_rail, wood_dark)

	var rung_count := maxi(3, int(h / 28.0))
	for i in range(rung_count):
		var t := (float(i) + 0.5) / float(rung_count)
		var shadow := ColorRect.new()
		shadow.name = "RungShadow%d" % i
		shadow.size = Vector2(w - 8, 2)
		shadow.position = Vector2(4, t * h + 1.5)
		shadow.color = Color(0.05, 0.03, 0.02, 0.45)
		shadow.mouse_filter = Control.MOUSE_FILTER_IGNORE
		add_child(shadow)
		var rung := ColorRect.new()
		rung.name = "Rung%d" % i
		rung.size = Vector2(w - 8, 4)
		rung.position = Vector2(4, t * h - 2.0)
		rung.color = rung_color
		rung.mouse_filter = Control.MOUSE_FILTER_IGNORE
		add_child(rung)

	_hint = Label.new()
	_hint.name = "ClimbHint"
	_hint.text = hint_text
	_hint.position = Vector2(-18, -18)
	_hint.add_theme_font_size_override("font_size", 11)
	_hint.modulate = Color(0.95, 0.85, 0.55, 0.9)
	_hint.visible = false
	add_child(_hint)


func _rail_grain(rail: ColorRect, grain: Color) -> void:
	var strip := ColorRect.new()
	strip.name = "Grain"
	strip.size = Vector2(1.5, rail.size.y)
	strip.position = Vector2(rail.size.x * 0.45, 0)
	strip.color = grain
	strip.mouse_filter = Control.MOUSE_FILTER_IGNORE
	rail.add_child(strip)


func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("player") and body.has_method("enter_climb_zone"):
		body.enter_climb_zone(self)
		if _hint:
			_hint.visible = true


func _on_body_exited(body: Node2D) -> void:
	if body.is_in_group("player") and body.has_method("exit_climb_zone"):
		body.exit_climb_zone(self)
		if _hint:
			_hint.visible = false
