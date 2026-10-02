extends SceneTree
## Build Bible Spec 10 (Interaction) acceptance tests. Uses a synthetic
## setup (Interaction component + small test-double interactables) rather
## than the full main.tscn/Player, for precise control over distances —
## NPC-specific behavior (talk_requested, prompt text) is covered by the
## existing NPC tests and isn't duplicated here.

const InteractionScript := preload("res://interaction.gd")


## Minimal test-double interactable: an Area2D on INTERACTABLE_LAYER with a
## configurable prompt and a call counter, standing in for any real
## interactable (NPC, rest point, storage, ...) without needing one.
class FakeInteractable extends Area2D:
	var prompt := "Fake prompt"
	var interact_count := 0

	func _ready() -> void:
		collision_layer = InteractionScript.INTERACTABLE_LAYER
		collision_mask = 0
		monitoring = false
		monitorable = true
		var shape := CollisionShape2D.new()
		var circle := CircleShape2D.new()
		circle.radius = 16.0
		shape.shape = circle
		add_child(shape)

	func get_interact_prompt() -> String:
		return prompt

	func on_interact(_player) -> void:
		interact_count += 1


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var interaction: Area2D = InteractionScript.new()
	interaction.global_position = Vector2(500, 500)
	root.add_child(interaction)

	var near := FakeInteractable.new()
	near.prompt = "Near thing"
	near.global_position = interaction.global_position + Vector2(20, 0)
	root.add_child(near)

	for _i in range(5):
		await physics_frame

	# --- 1. Standing near exactly one interactable shows its prompt and
	# triggers it on Interact. ---
	if interaction.get_current_target() != near:
		push_error("FAIL closest target should be the only nearby interactable")
		quit(1)
		return
	if interaction.get_current_prompt() != "Near thing":
		push_error("FAIL prompt did not match the in-range interactable")
		quit(1)
		return
	if not interaction.try_interact(null) or near.interact_count != 1:
		push_error("FAIL try_interact did not trigger the in-range interactable exactly once")
		quit(1)
		return
	print("PASS standing near exactly one interactable shows its prompt and triggers it")

	# --- 2. Standing near two shows/triggers the closer one. ---
	var far := FakeInteractable.new()
	far.prompt = "Far thing"
	far.global_position = interaction.global_position + Vector2(50, 0)  # still in range, farther
	root.add_child(far)
	for _i in range(5):
		await physics_frame

	if interaction.get_current_target() != near:
		push_error("FAIL closest-wins did not pick the nearer interactable")
		quit(1)
		return
	interaction.try_interact(null)
	if far.interact_count != 0 or near.interact_count != 2:
		push_error("FAIL interact triggered the farther interactable instead of the closer one")
		quit(1)
		return
	print("PASS standing near two interactables shows/triggers the closer one")

	# --- 3. Walking out of range clears the prompt. ---
	near.global_position = interaction.global_position + Vector2(5000, 5000)
	far.global_position = interaction.global_position + Vector2(5000, 5000)
	for _i in range(5):
		await physics_frame

	if interaction.get_current_target() != null or interaction.get_current_prompt() != "":
		push_error("FAIL prompt/target did not clear after walking out of range")
		quit(1)
		return
	if interaction.try_interact(null):
		push_error("FAIL try_interact succeeded with nothing in range")
		quit(1)
		return
	print("PASS walking out of range clears the prompt")

	# --- 4. An interactable freed while in range drops out cleanly rather
	# than leaving a stuck reference (Spec 10 failure case). ---
	var doomed := FakeInteractable.new()
	doomed.global_position = interaction.global_position
	root.add_child(doomed)
	for _i in range(5):
		await physics_frame
	if interaction.get_current_target() != doomed:
		push_error("FAIL setup: doomed interactable should be the current target before freeing")
		quit(1)
		return
	doomed.queue_free()
	for _i in range(5):
		await physics_frame
	# Comparing against `doomed` itself here would be unreliable — Godot
	# treats a freed Object reference as equal to null in == comparisons,
	# so the actually meaningful check is that nothing is targeted at all.
	if is_instance_valid(doomed) or interaction.get_current_target() != null:
		push_error("FAIL a freed interactable was still returned as the current target")
		quit(1)
		return
	print("PASS an interactable freed while in range drops out cleanly")

	interaction.queue_free()
	near.queue_free()
	far.queue_free()
	print("INTERACTION_TESTS_PASSED")
	quit(0)
