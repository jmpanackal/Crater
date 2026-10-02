extends SceneTree
## The opening scene exposes the authored Jobs Duty through physical objects.


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	await process_frame
	var jobs: Node = root.get_node_or_null("Jobs")
	if jobs == null:
		push_error("FAIL Jobs autoload missing")
		quit(1)
		return
	jobs.reset_all()
	var scene := (load("res://main.tscn") as PackedScene).instantiate()
	root.add_child(scene)
	await process_frame
	var dispatcher: Area2D = scene.get_node_or_null("Hollow/OpeningDutyDispatcher") as Area2D
	var collection: Area2D = scene.get_node_or_null("Hollow/OpeningDutyCollection") as Area2D
	if dispatcher == null or collection == null:
		push_error("FAIL opening Duty interactables missing")
		quit(1)
		return
	if not dispatcher.get_interact_prompt().contains("Open the new gallery"):
		push_error("FAIL dispatcher prompt does not present the opening Duty")
		quit(1)
		return
	dispatcher.on_interact(null)
	if jobs.get_stage(&"open_the_gallery") != jobs.STAGE_ACCEPTED:
		push_error("FAIL dispatcher did not offer and accept the opening Duty")
		quit(1)
		return
	if not collection.get_interact_prompt().contains("Open the new gallery"):
		push_error("FAIL collection point is not bound to the opening Duty")
		quit(1)
		return
	print("OPENING_DUTY_SCENE_TESTS_PASSED")
	quit(0)
