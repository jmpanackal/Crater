extends Area2D
## Build Bible Spec 10 — small reusable Area2D relay for an interactable
## whose root node can't itself be an Area2D (e.g. main.tscn already
## declares its node type elsewhere, so the script's base class alone
## can't change it). Delegates get_interact_prompt()/on_interact() to its
## parent, so the parent only needs to implement those two methods
## normally — it never has to become an Area2D itself.
##
## Usage: add as a child (any name), then call setup(radius) once.

const InteractionScript := preload("res://interaction.gd")


func setup(radius: float) -> void:
	collision_layer = InteractionScript.INTERACTABLE_LAYER
	collision_mask = 0
	monitoring = false
	monitorable = true
	if get_node_or_null("CollisionShape2D") == null:
		var shape := CollisionShape2D.new()
		shape.name = "CollisionShape2D"
		var circle := CircleShape2D.new()
		circle.radius = radius
		shape.shape = circle
		add_child(shape)


func get_interact_prompt() -> String:
	var parent := get_parent()
	if parent != null and parent.has_method("get_interact_prompt"):
		return str(parent.get_interact_prompt())
	return ""


func on_interact(player) -> void:
	var parent := get_parent()
	if parent != null and parent.has_method("on_interact"):
		parent.on_interact(player)
