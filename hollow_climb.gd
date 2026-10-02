extends Area2D
## Visible ladder between Hollow decks — walkable geometry cue + climb zone.
## Player hangs/climbs with W/S while overlapping; Space jumps off.
## Position is the upper deck top; shaft_size.y reaches the lower deck top.

const SHARED_CLIMB_HINT := "[W/S] climb"

@export var shaft_size: Vector2 = Vector2(40, 192)
@export var hint_text: String = SHARED_CLIMB_HINT
@export var rail_color: Color = Color(0.62, 0.42, 0.28, 1) # copper-wood
@export var rung_color: Color = Color(0.78, 0.58, 0.38, 1)
## Extra climb hitbox above the visual top. Keep at 0 so standing on solid deck
## beside an open shaft does not keep the climb prompt; walk into the hole to grab.
@export var grab_margin_top: float = 0.0
## Upper-deck floor gap this shaft climbs through (world X). Lower landing stays solid.
@export var deck_open_x: float = 0.0
@export var deck_open_width: float = 64.0
## When climbing onto the upper deck: -1 prefer/force left landing, 0 nearest, 1 force right.
@export var upper_land_side: int = 0

var _hint: Label
var _hint_player: Node2D


func deck_top_y() -> float:
	return global_position.y


func deck_bottom_y() -> float:
	return global_position.y + shaft_size.y


func upper_opening() -> Vector2:
	## Returns (open_x0, open_x1) for the upper-deck gap.
	return Vector2(deck_open_x, deck_open_x + deck_open_width)


## Drawn ladder bounds in local space (rails / backboard).
func visual_rect() -> Rect2:
	return Rect2(Vector2.ZERO, shaft_size)


## Climb Area collision bounds in local space (matches visual X; may extend above).
func climb_hit_rect() -> Rect2:
	var col := get_node_or_null("CollisionShape2D") as CollisionShape2D
	if col == null:
		return Rect2()
	var shape := col.shape as RectangleShape2D
	if shape == null:
		return Rect2()
	var half := shape.size * 0.5
	return Rect2(col.position - half, shape.size)


func _ready() -> void:
	collision_layer = 0
	collision_mask = 1
	monitoring = true
	monitorable = false
	# Above FloorVisual (z=1) so short shafts stay fully readable in openings.
	z_index = 3
	# One shared climb affordance across every Hollow ladder.
	hint_text = SHARED_CLIMB_HINT
	_ensure_collision()
	_build_visuals()
	set_physics_process(true)
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
	# Match the drawn rails in X; only extend upward so upper-deck feet still overlap.
	var hit_w := shaft_size.x
	var hit_h := shaft_size.y + grab_margin_top
	shape.size = Vector2(hit_w, hit_h)
	col.shape = shape
	col.position = Vector2(hit_w * 0.5, hit_h * 0.5 - grab_margin_top)


func _build_visuals() -> void:
	# Rebuild cleanly if scene was saved with stale children / half-height shafts.
	for child in get_children():
		if child is CollisionShape2D:
			continue
		remove_child(child)
		child.free()

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

	# Plain Label (not SoftWorldLabel): climb prompts are interaction chrome,
	# not diegetic placards — and SoftWorldLabel's distance fade hid tall-shaft
	# hints when the player stood at the lower landing.
	_hint = Label.new()
	_hint.name = "ClimbHint"
	_hint.text = SHARED_CLIMB_HINT
	_hint.position = Vector2(-18, -18)
	_hint.add_theme_font_size_override("font_size", 11)
	_hint.add_theme_color_override("font_outline_color", Color(0.04, 0.06, 0.07, 0.92))
	_hint.add_theme_constant_override("outline_size", 3)
	_hint.modulate = Color(0.95, 0.85, 0.55, 0.9)
	_hint.z_index = 4
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


func _physics_process(_delta: float) -> void:
	_sync_hint_to_player()


func _sync_hint_to_player() -> void:
	if _hint == null or not _hint.visible or _hint_player == null:
		return
	if not is_instance_valid(_hint_player):
		_hint_player = null
		return
	# Keep the prompt beside the climber so tall shafts stay readable at either end.
	var local_y := _hint_player.global_position.y - global_position.y
	local_y = clampf(local_y, -12.0, shaft_size.y - 8.0)
	_hint.position = Vector2(-18.0, local_y - 18.0)


func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("player") and body.has_method("enter_climb_zone"):
		body.enter_climb_zone(self)
		_hint_player = body
		if _hint:
			_hint.text = SHARED_CLIMB_HINT
			_hint.visible = true
			_sync_hint_to_player()


func _on_body_exited(body: Node2D) -> void:
	if body.is_in_group("player") and body.has_method("exit_climb_zone"):
		body.exit_climb_zone(self)
		if _hint_player == body:
			_hint_player = null
		if _hint:
			_hint.visible = false
			_hint.position = Vector2(-18.0, -18.0)
