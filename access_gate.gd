extends StaticBody2D
## Build Bible Spec 31 — a physical access gate: solid until its
## requirements (a Trust standing, a story flag, a residence tier) are met,
## explained in the world without numbers. Registers with the Access
## autoload, which re-evaluates it on the events that can change the
## answer and calls set_open().
##
## Children built on _ready if missing: a CollisionShape2D (the barrier),
## an interactable relay Area2D (the prompt), and a "Beyond" Area2D past
## the gate — entering it while the gate is CLOSED is a restricted entry
## (Access.report_restricted_entry -> fact + Perception witness check).

const InteractionScript := preload("res://interaction.gd")
const InteractableRelayScript := preload("res://interactable_relay.gd")
const PLAYER_BODY_LAYER := 1

signal opened_changed(is_open: bool)

@export var gate_id: StringName = &""
## Trust standing id needed ("" = none), e.g. &"relied_on".
@export var required_trust: StringName = &""
## Story flag needed ("" = none).
@export var required_flag: StringName = &""
## Residence tier needed ("" = none), e.g. &"ashram_heights".
@export var required_residence: StringName = &""
## The in-world line shown while closed (no numbers). "" = Access's default.
@export var explanation: String = ""
@export var barrier_size: Vector2 = Vector2(32, 64)
## Where the "beyond" sensor sits relative to the gate, and its size.
@export var beyond_offset: Vector2 = Vector2(48, 0)
@export var beyond_size: Vector2 = Vector2(48, 96)
@export var display_name: String = "Gate"

var _open := false
var _beyond: Area2D


func _ready() -> void:
	collision_layer = 1
	collision_mask = 0
	if get_node_or_null("CollisionShape2D") == null:
		var shape := CollisionShape2D.new()
		shape.name = "CollisionShape2D"
		var rect := RectangleShape2D.new()
		rect.size = barrier_size
		shape.shape = rect
		add_child(shape)
	if get_node_or_null("Prompt") == null:
		# The prompt is a Spec 10 relay child (the gate's root is a
		# StaticBody2D, not an Area2D) — same pattern as hollow_npc.gd.
		var prompt: Area2D = InteractableRelayScript.new()
		prompt.name = "Prompt"
		add_child(prompt)
		prompt.setup(maxf(barrier_size.x, barrier_size.y) * 0.75 + 16.0)
	_beyond = get_node_or_null("Beyond") as Area2D
	if _beyond == null:
		_beyond = Area2D.new()
		_beyond.name = "Beyond"
		_beyond.collision_layer = 0
		_beyond.collision_mask = PLAYER_BODY_LAYER
		_beyond.monitoring = true
		_beyond.monitorable = false
		var bshape := CollisionShape2D.new()
		var brect := RectangleShape2D.new()
		brect.size = beyond_size
		bshape.shape = brect
		_beyond.add_child(bshape)
		_beyond.position = beyond_offset
		add_child(_beyond)
	_beyond.body_entered.connect(_on_beyond_entered)
	var access := _access()
	if access != null:
		access.register_gate(self)


func _exit_tree() -> void:
	var access := _access()
	if access != null:
		access.unregister_gate(self)


func is_open() -> bool:
	return _open


## Called by Access. Open = the barrier's collision is off.
func set_open(open: bool) -> void:
	if _open == open:
		return
	_open = open
	var shape := get_node_or_null("CollisionShape2D") as CollisionShape2D
	if shape != null:
		shape.set_deferred("disabled", open)
	opened_changed.emit(open)


## Spec 10 prompt: the explanation while closed, the way's name when open.
func get_interact_prompt() -> String:
	if _open:
		return "%s (open)" % display_name
	var access := _access()
	if access == null:
		return "%s (closed)" % display_name
	return "%s — %s" % [display_name, access.can_pass(gate_id)["explanation"]]


func on_interact(_player: Node) -> void:
	pass  # a gate is passed by walking; the prompt only explains it


func _on_beyond_entered(body: Node2D) -> void:
	if _open or not (body.is_in_group("player") or body.name == "Player"):
		return
	var access := _access()
	if access != null:
		access.report_restricted_entry(gate_id, body.global_position)


func _access() -> Node:
	if not is_inside_tree():
		return null
	return get_tree().root.get_node_or_null("Access")
