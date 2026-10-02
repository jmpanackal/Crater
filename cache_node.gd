extends Area2D
## Build Bible Spec 13 — a player-created cache in the world (canon's own
## DIRECTION: "a small pile, crate, marked stash"), as a Spec 10
## Interactable: walk up, Interact, and the bundle is picked back up
## through Hauling.retrieve_cache(). Owns no state — the cache record is
## Hauling's; this is its marker and its interaction surface.

const InteractionScript := preload("res://interaction.gd")
const INTERACT_RADIUS := 28.0

var uid: int = -1
var material_id: StringName = &""
var amount: int = 0

var _hauling: Node


func setup(hauling: Node, p_uid: int, p_material_id: StringName, p_amount: int) -> void:
	_hauling = hauling
	uid = p_uid
	material_id = p_material_id
	amount = p_amount
	name = "Cache_%d" % p_uid
	collision_layer = InteractionScript.INTERACTABLE_LAYER
	collision_mask = 0
	monitoring = false
	monitorable = true
	if get_node_or_null("CollisionShape2D") == null:
		var shape := CollisionShape2D.new()
		shape.name = "CollisionShape2D"
		var circle := CircleShape2D.new()
		circle.radius = INTERACT_RADIUS
		shape.shape = circle
		add_child(shape)
	if get_node_or_null("Pile") == null:
		var pile := ColorRect.new()
		pile.name = "Pile"
		pile.size = Vector2(16, 10)
		pile.position = Vector2(-8, -10)
		pile.color = Color(0.58, 0.44, 0.27, 0.95)
		pile.mouse_filter = Control.MOUSE_FILTER_IGNORE
		add_child(pile)
		var mark := ColorRect.new()
		mark.name = "Mark"
		mark.size = Vector2(2, 14)
		mark.position = Vector2(9, -18)
		mark.color = Color(0.82, 0.66, 0.4, 0.9)
		mark.mouse_filter = Control.MOUSE_FILTER_IGNORE
		add_child(mark)


func get_interact_prompt() -> String:
	var display := str(material_id)
	var storage := get_tree().root.get_node_or_null("Storage") if is_inside_tree() else null
	if storage != null:
		display = str(storage.get_material_display_name(material_id))
	return "Pick up bundle (%d %s)" % [amount, display]


func on_interact(_player: Node) -> void:
	if _hauling != null and _hauling.has_method("retrieve_cache"):
		_hauling.retrieve_cache(uid)
