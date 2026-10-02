class_name Interaction
extends Area2D
## Build Bible Spec 10 — generic interaction targeting for the player.
## Build order #10 (docs/build-bible/specs/10-interaction.md).
##
## Tracks nearby interactables via real Area2D overlap (confirmed option A
## — not raycast/aim, not a bare distance check) and exposes the single
## closest one for a UI prompt and for the one unified Interact input to
## trigger (confirmed option A), regardless of what type of interactable
## it is — talk, rest, turn-in, open all go through the same path instead
## of each object type inventing its own input handling.
##
## Interactable objects implement a small duck-typed interface (no formal
## Godot interface class): get_interact_prompt() -> String, on_interact
## (player) -> void, and sit on Interaction.INTERACTABLE_LAYER so this
## Area2D's overlap actually finds them.
##
## Owns no persistent state (Spec 10) — only which interactables are
## currently in range and which is closest, recomputed live on every query.

## Physics layer interactable objects (NPCs, rest points, storage, ...)
## put themselves on, distinct from layer 1 (world/player collision) so
## interaction detection never interferes with physical movement.
const INTERACTABLE_LAYER := 2

const DEFAULT_RADIUS := 56.0

var _in_range: Array[Node] = []


func _ready() -> void:
	monitoring = true
	monitorable = false
	collision_layer = 0
	collision_mask = INTERACTABLE_LAYER
	if get_node_or_null("CollisionShape2D") == null:
		var shape := CollisionShape2D.new()
		shape.name = "CollisionShape2D"
		var circle := CircleShape2D.new()
		circle.radius = DEFAULT_RADIUS
		shape.shape = circle
		add_child(shape)
	area_entered.connect(_on_area_entered)
	area_exited.connect(_on_area_exited)


func _on_area_entered(area: Area2D) -> void:
	if area.has_method("on_interact") and not _in_range.has(area):
		_in_range.append(area)


func _on_area_exited(area: Area2D) -> void:
	_in_range.erase(area)


## The closest currently-in-range interactable, or null. Prunes anything
## freed since it entered range (Spec 10 failure case: an interactable
## that becomes invalid while in range — an NPC that walks off and gets
## freed mid-interaction, say — must cleanly drop out, not leave the
## player stuck).
func get_current_target() -> Node:
	_in_range = _in_range.filter(func(n: Node) -> bool: return is_instance_valid(n))
	if _in_range.is_empty():
		return null
	var closest: Node = null
	var closest_dist := INF
	for n: Node in _in_range:
		var d := (n as Node2D).global_position.distance_squared_to(global_position)
		if d < closest_dist:
			closest_dist = d
			closest = n
	return closest


func get_current_prompt() -> String:
	var target := get_current_target()
	if target == null or not target.has_method("get_interact_prompt"):
		return ""
	return str(target.get_interact_prompt())


## Triggers the closest interactable's on_interact(), if any. Returns
## whether something was actually triggered.
func try_interact(player: Node) -> bool:
	var target := get_current_target()
	if target == null or not target.has_method("on_interact"):
		return false
	target.on_interact(player)
	return true
