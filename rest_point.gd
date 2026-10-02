extends Area2D
## A bed: Build Bible Spec 09's proper rest point (sleep). A Spec 10 Interactable. Sleeping
## clears Fatigue and advances the Civic Cycle to the next Rousing, which the Clock only allows
## from Gathering or Ritual — earlier in the day the prompt says so and nothing happens.
## Usage: instanced by HollowDressingBuilder for station kind "rest".

const InteractionScript := preload("res://interaction.gd")

signal slept

@export var interact_radius: float = 30.0


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


func can_sleep() -> bool:
	var clock := _node("Clock")
	return clock != null and (clock.get_phase() == &"gathering" or clock.get_phase() == &"ritual")


func get_interact_prompt() -> String:
	return "Sleep until Rousing" if can_sleep() else "Bed (sleep after Gathering)"


func on_interact(_player: Node) -> void:
	var clock := _node("Clock")
	if clock == null or not can_sleep():
		_notice("Too early to sleep. The day is not done.")
		return
	if bool(clock.request_advance_to_next_rousing()):
		var fatigue := _node("Fatigue")
		if fatigue != null:
			fatigue.recover_full()
		_notice("You sleep. Rousing.")
		slept.emit()


func _node(name: String) -> Node:
	return get_tree().root.get_node_or_null(name) if is_inside_tree() else null


func _notice(text: String) -> void:
	var player := get_tree().get_first_node_in_group("player") if is_inside_tree() else null
	var scene := player.get_parent() if player != null else null
	var panel := scene.get_node_or_null("UI/UpgradePanel") if scene != null else null
	if panel != null and panel.has_method("show_notice"):
		panel.show_notice(text)
