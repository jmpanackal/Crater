extends Node2D
## Lightweight Hollow NPC — works/lives near a district, talks on interact.
## Most lines are talk-only (#20 D). Rare choice prompts handled by callers.

signal talk_requested(npc: Node2D, lines: PackedStringArray, choice_prompt: String)

@export var npc_name: String = "Neighbor"
@export var district_id: StringName = &"farms"
@export var body_color: Color = Color(0.85, 0.7, 0.45)
@export var interact_radius: float = 48.0
@export var lines: PackedStringArray = PackedStringArray([
	"Harvest soon. Don't wander too far.",
])
## If non-empty, rare choice prompt after lines (Yes/No style).
@export var choice_prompt: String = ""

var _player: Node2D
var _label: Label
var _body: ColorRect
var _hint: Label
var _wander_origin := Vector2.ZERO
var _wander_t := 0.0


func _ready() -> void:
	_wander_origin = position
	_wander_t = randf() * TAU
	_build_visuals()
	_player = get_tree().get_first_node_in_group("player") as Node2D


func _build_visuals() -> void:
	# Soft silhouette placeholders until NPC art lands — still read as people on decks.
	_body = ColorRect.new()
	_body.size = Vector2(14, 22)
	_body.position = Vector2(-7, -22)
	_body.color = Color(body_color.r, body_color.g, body_color.b, 0.72)
	_body.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_body)

	var head := ColorRect.new()
	head.size = Vector2(10, 10)
	head.position = Vector2(-5, -32)
	head.color = Color(body_color.lightened(0.12).r, body_color.lightened(0.12).g, body_color.lightened(0.12).b, 0.78)
	head.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(head)

	_label = Label.new()
	_label.text = npc_name
	_label.position = Vector2(-28, -48)
	_label.add_theme_font_size_override("font_size", 12)
	_label.visible = false
	add_child(_label)

	_hint = Label.new()
	_hint.text = "[E]"
	_hint.visible = false
	_hint.position = Vector2(-10, -62)
	_hint.add_theme_font_size_override("font_size", 11)
	_hint.modulate = Color(1.0, 0.9, 0.55)
	add_child(_hint)


func _process(delta: float) -> void:
	_wander_t += delta
	position.x = _wander_origin.x + sin(_wander_t * 0.7) * 10.0
	if _player == null or not is_instance_valid(_player):
		_player = get_tree().get_first_node_in_group("player") as Node2D
	var near := _is_player_near()
	if _label:
		_label.visible = near
	if _hint:
		_hint.visible = near


func _unhandled_input(event: InputEvent) -> void:
	if not _is_player_near():
		return
	if event.is_action_pressed("interact") or (event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_E):
		talk_requested.emit(self, lines, choice_prompt)
		get_viewport().set_input_as_handled()


func _is_player_near() -> bool:
	if _player == null:
		return false
	return global_position.distance_to(_player.global_position) <= interact_radius
