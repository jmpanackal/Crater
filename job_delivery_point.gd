extends Area2D
## Build Bible Spec 24 — a worksite collection point, as a Spec 10
## Interactable: the player walks up with a towed bundle (Spec 13) and
## Interact hands it to the job that wants it. This is the physical "haul
## / deliver -> see where it goes" step of canon §15, not a menu.
##
## Which job: the first live job (offered/accepted/in progress) for
## `district_id` whose Material matches the bundle — or the one named in
## `job_id` when set. Owns no state.

const InteractionScript := preload("res://interaction.gd")

signal delivered(job_id: StringName, amount: int)

@export var district_id: StringName = &"wickwork"
## Optional: deliver only to this job instance.
@export var job_id: StringName = &""
@export var interact_radius: float = 40.0


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
	var target := _target_job()
	if target.is_empty():
		return "Worksite collection"
	return "Deliver to \"%s\" (%d/%d)" % [target["title"], int(target["delivered"]), int(target["required"])]


func on_interact(_player: Node) -> void:
	var jobs := _jobs()
	var target := _target_job()
	if jobs == null or target.is_empty():
		return
	var counted: int = int(jobs.deliver_from_bundle(target["job_id"]))
	if counted > 0:
		delivered.emit(target["job_id"], counted)


func _target_job() -> Dictionary:
	var jobs := _jobs()
	if jobs == null:
		return {}
	if job_id != &"":
		var job: Dictionary = jobs.get_job(job_id)
		return job if not job.is_empty() and job["stage"] != &"settled" else {}
	var hauling := get_tree().root.get_node_or_null("Hauling") if is_inside_tree() else null
	var towed := StringName(str(hauling.get_load()["material_id"])) if hauling != null and bool(hauling.is_loaded()) else &""
	var fallback: Dictionary = {}
	for job: Dictionary in jobs.get_active_jobs():
		if job["district_id"] != district_id:
			continue
		if towed != &"" and job["material_id"] == towed:
			return job
		if fallback.is_empty():
			fallback = job
	return fallback


func _jobs() -> Node:
	if not is_inside_tree():
		return null
	return get_tree().root.get_node_or_null("Jobs")
