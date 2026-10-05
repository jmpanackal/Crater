extends Area2D
## A home's front door, as an Interactable (Spec 10): Interact at your own door goes in, Interact at the inside door
## comes out. Built by home_interior.gd, one outside (in the Hollow, where the home's building stands) and one inside.

const InteractionScript := preload("res://interaction.gd")

var interior: Node
var leaving := false
var prompt := "Enter home"


func _ready() -> void:
	collision_layer = InteractionScript.INTERACTABLE_LAYER
	collision_mask = 0
	monitoring = false
	monitorable = true
	var shape := CollisionShape2D.new()
	shape.name = "CollisionShape2D"
	var rect := RectangleShape2D.new()
	rect.size = Vector2(44.0, 72.0)
	shape.shape = rect
	add_child(shape)


func get_interact_prompt() -> String:
	if interior != null and interior.is_busy():
		return ""
	return prompt


func on_interact(_player: Node) -> void:
	if interior == null:
		return
	if leaving:
		interior.leave()
	else:
		interior.enter()
