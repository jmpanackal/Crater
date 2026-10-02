extends Area2D
## A find lying in the world that unlocks a Journal record when you pick it up. A Spec 10
## Interactable. Used for the corroded fragment in the Collapsed Side Chamber (the opening
## route's one ambiguous clue: optional, never blocks the public return). Once taken it frees
## itself, and it does not come back if the record is already known.

const InteractionScript := preload("res://interaction.gd")

signal taken(record_id: StringName)

@export var record_id: StringName = &"slate_shard"
@export var prompt: String = "Examine the corroded fragment"
@export var interact_radius: float = 32.0


func _ready() -> void:
	var journal := get_tree().root.get_node_or_null("Journal") if is_inside_tree() else null
	if journal != null and journal.has_record(record_id):
		queue_free()
		return
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
	var journal := get_tree().root.get_node_or_null("Journal")
	if journal == null:
		return
	if journal.unlock_record(record_id):
		_notice("You take the fragment. A new Record is in your Journal (J).")
	taken.emit(record_id)
	queue_free()


func _notice(text: String) -> void:
	var player := get_tree().get_first_node_in_group("player")
	var scene := player.get_parent() if player != null else null
	var panel := scene.get_node_or_null("UI/UpgradePanel") if scene != null else null
	if panel != null and panel.has_method("show_notice"):
		panel.show_notice(text)
