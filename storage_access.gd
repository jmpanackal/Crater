extends Area2D
## Build Bible Spec 11 — a world-side access point to personal storage (the
## chest/shelf/rack at a residence), implemented as a Spec 10 Interactable:
## the player walks up, Interact fires on_interact(), and this hands over
## the ONE unified Storage pool. This is the concrete reason Spec 11
## depends on Spec 10.
##
## residence_id is identity/flavor only ("which home is this?") — it
## deliberately changes nothing about what get_storage() returns. Storage
## is identical whether opened from the Lower home or a later residence
## (Spec 11, confirmed option A); a per-residence split was considered and
## rejected there.
##
## Usage: add to a scene, set interact_radius/residence_id/prompt in the
## inspector. Standalone Area2D, so no relay is needed (unlike hollow_npc.gd,
## whose root node is pinned to Node2D by main.tscn).

const InteractionScript := preload("res://interaction.gd")

## Fired when the player interacts. Whatever storage UI lands later listens
## to this; nothing here assumes a particular presentation.
signal opened(residence_id: StringName, storage: Node)

@export var residence_id: StringName = &"lower"
@export var interact_radius: float = 48.0
@export var prompt: String = "Open storage"


func _ready() -> void:
	collision_layer = InteractionScript.INTERACTABLE_LAYER
	collision_mask = 0
	monitoring = false
	monitorable = true
	if get_node_or_null("CollisionShape2D") == null:
		var shape := CollisionShape2D.new()
		shape.name = "CollisionShape2D"
		var circle := CircleShape2D.new()
		circle.radius = interact_radius
		shape.shape = circle
		add_child(shape)


func get_interact_prompt() -> String:
	return prompt


func on_interact(_player: Node) -> void:
	# Arriving at home storage with a bundle in tow deposits it (Build
	# Bible Spec 13: depositing releases the hauling block and turns the
	# physical load into Storage's abstract count) — this interactable is
	# what gates "at storage"; Hauling itself doesn't check position.
	var hauling := get_tree().root.get_node_or_null("Hauling") if is_inside_tree() else null
	if hauling != null and hauling.has_method("is_loaded") and bool(hauling.is_loaded()):
		hauling.deposit_at_storage()
	opened.emit(residence_id, get_storage())


## The unified pool. Every access point in the world returns this same node.
func get_storage() -> Node:
	if not is_inside_tree():
		return null
	return get_tree().root.get_node_or_null("Storage")
