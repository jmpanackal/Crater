extends Area2D
## Physical dispatcher for the opening canon Duty. Offering and accepting the
## one authored opening assignment happens here, never through a legacy HUD.

const InteractionScript := preload("res://interaction.gd")

@export var definition_id: StringName = &"open_the_gallery"
@export var interact_radius := 40.0

var _job_id: StringName = &""


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
	_build_marker()


func get_interact_prompt() -> String:
	var jobs := _jobs()
	if jobs == null:
		return "Dispatch is unavailable"
	if _job_id == &"" or not jobs.has_job(_job_id):
		return "Take Duty: Open the new gallery"
	var job: Dictionary = jobs.get_job(_job_id)
	if job["stage"] == jobs.STAGE_SETTLED:
		return "Dispatch: gallery duty settled"
	return "Opening Duty — %d/%d delivered" % [int(job["delivered"]), int(job["required"])]


func on_interact(_player: Node) -> void:
	var jobs := _jobs()
	if jobs == null:
		return
	if _job_id == &"" or not jobs.has_job(_job_id):
		_job_id = jobs.offer(definition_id)
		if _job_id != &"":
			jobs.accept(_job_id)


func _jobs() -> Node:
	return get_tree().root.get_node_or_null("Jobs") if is_inside_tree() else null


func _build_marker() -> void:
	if get_node_or_null("Marker") != null:
		return
	var marker := ColorRect.new()
	marker.name = "Marker"
	marker.position = Vector2(-10, -28)
	marker.size = Vector2(20, 28)
	marker.color = Color(0.62, 0.48, 0.3, 1.0)
	marker.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(marker)
	var label := Label.new()
	label.name = "Label"
	label.position = Vector2(-54, -48)
	label.size = Vector2(108, 16)
	label.text = "Dispatch"
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", 10)
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(label)
