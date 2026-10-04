extends Area2D
## The call button on one elevator landing: stand at the shaft on that deck and press Interact to bring the
## cab here. A Spec 10 Interactable (see interaction.gd). Built by hollow_elevator.gd, one per stop.

const InteractionScript := preload("res://interaction.gd")

var elevator_path: NodePath
var stop_index := 0
var shaft_width := 96.0


func _ready() -> void:
	collision_layer = InteractionScript.INTERACTABLE_LAYER
	collision_mask = 0
	monitoring = false
	monitorable = true
	var shape := CollisionShape2D.new()
	shape.name = "CollisionShape2D"
	var rect := RectangleShape2D.new()
	rect.size = Vector2(shaft_width + 24.0, 48.0)
	shape.shape = rect
	add_child(shape)


func _elevator() -> Node:
	return get_node_or_null(elevator_path) if is_inside_tree() else null


func get_interact_prompt() -> String:
	var lift := _elevator()
	if lift == null:
		return ""
	# A prompt means Interact does something: nothing to offer when the cab is here, locked or parked (the lift's own
	# hint above the cab already says why), so no key cap is shown for an action that would do nothing.
	if lift.current_stop_index() == stop_index and not lift.is_moving():
		return ""
	if lift.is_locked() or lift.is_parked():
		return ""
	return "Call lift"


func on_interact(_player: Node) -> void:
	var lift := _elevator()
	if lift != null:
		lift.call_to(stop_index)
