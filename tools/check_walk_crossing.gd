extends SceneTree
## Manual diagnostic: actually walks the player (real input held, real physics,
## real SPEED) from Home Court spawn east across Mid Heart / Devil's Mouth,
## capturing a screenshot every ~1s of simulated time and reporting the real
## elapsed time for the crossing. Needs a real window, not --headless.
## Run: godot --path . --windowed --script res://tools/check_walk_crossing.gd -- output=tmp/walk

var _output_dir := "res://tmp/walk"


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	if DisplayServer.get_name() == "headless":
		push_error("This check needs a rendered window, not --headless")
		quit(1)
		return
	var arguments := OS.get_cmdline_user_args()
	for argument in arguments:
		if argument.begins_with("output="):
			_output_dir = argument.trim_prefix("output=")
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(_output_dir))
	root.size = Vector2i(1280, 720)
	var scene: Node2D = load("res://main.tscn").instantiate()
	root.add_child(scene)
	var player: CharacterBody2D = scene.get_node("Player")
	for tick in range(10):
		await physics_frame

	var shot_index := 0
	var elapsed := 0.0
	var last_shot_at := -10.0
	var physics_dt := 1.0 / float(Engine.physics_ticks_per_second)

	# --- Leg 1a: Home Court spawn -> the Home->Heart ladder base. ---
	Input.action_press("ui_right")
	var ladder_x := HollowLayout.LADDER_HOME_HEART_X
	var reached_ladder := false
	for tick in range(1000):
		await physics_frame
		elapsed += physics_dt
		if elapsed - last_shot_at >= 1.0:
			await RenderingServer.frame_post_draw
			var img := root.get_texture().get_image()
			img.save_png(_output_dir.path_join("walk-%03d_t%.1fs.png" % [shot_index, elapsed]))
			shot_index += 1
			last_shot_at = elapsed
		if player.global_position.x >= ladder_x - 8.0:
			reached_ladder = true
			break
	if not reached_ladder:
		Input.action_release("ui_right")
		push_error("FAIL never reached Home->Heart ladder; last pos=%s" % player.global_position)
		quit(1)
		return
	Input.action_release("ui_right")
	print("Reached ladder base at t=%.2fs (pos=%s)" % [elapsed, player.global_position])

	# --- Leg 1b: climb the ladder up onto the Mid Heart approach. ---
	Input.action_press("ui_up")
	var west_lip := HollowLayout.PIT_LEFT
	var reached_west_lip := false
	for tick in range(2000):
		await physics_frame
		elapsed += physics_dt
		if elapsed - last_shot_at >= 1.0:
			await RenderingServer.frame_post_draw
			var img := root.get_texture().get_image()
			img.save_png(_output_dir.path_join("walk-%03d_t%.1fs.png" % [shot_index, elapsed]))
			shot_index += 1
			last_shot_at = elapsed
		if absf(player.global_position.y - (HollowLayout.HEART_Y - 32.0)) < 8.0 and player.is_on_floor():
			reached_west_lip = true
			break
	if not reached_west_lip:
		Input.action_release("ui_up")
		Input.action_release("ui_right")
		push_error("FAIL never climbed onto Mid Heart approach; last pos=%s" % player.global_position)
		quit(1)
		return
	Input.action_release("ui_up")
	print("Climbed onto Mid Heart approach at t=%.2fs (pos=%s)" % [elapsed, player.global_position])

	# --- Leg 1c: walk right the rest of the way to the Mouth's west lip. ---
	Input.action_press("ui_right")
	reached_west_lip = false
	for tick in range(1000):
		await physics_frame
		elapsed += physics_dt
		if elapsed - last_shot_at >= 1.0:
			await RenderingServer.frame_post_draw
			var img := root.get_texture().get_image()
			img.save_png(_output_dir.path_join("walk-%03d_t%.1fs.png" % [shot_index, elapsed]))
			shot_index += 1
			last_shot_at = elapsed
		if player.global_position.x >= west_lip - 8.0:
			reached_west_lip = true
			print("Reached Mid Heart west lip at t=%.2fs (pos=%s)" % [elapsed, player.global_position])
			break
	if not reached_west_lip:
		Input.action_release("ui_right")
		push_error("FAIL never reached Mid Heart west lip; last pos=%s" % player.global_position)
		quit(1)
		return

	# --- Leg 2: the actual Mouth crossing, west lip -> east lip. ---
	var east_lip := HollowLayout.PIT_RIGHT
	var crossing_start := elapsed
	var reached_east_lip := false
	for tick in range(3000):
		await physics_frame
		elapsed += physics_dt
		if elapsed - last_shot_at >= 1.0:
			await RenderingServer.frame_post_draw
			var img := root.get_texture().get_image()
			img.save_png(_output_dir.path_join("walk-%03d_t%.1fs.png" % [shot_index, elapsed]))
			shot_index += 1
			last_shot_at = elapsed
		if player.global_position.x >= east_lip - 8.0:
			reached_east_lip = true
			break
	Input.action_release("ui_right")
	if not reached_east_lip:
		push_error("FAIL never reached Mid Heart east lip; last pos=%s" % player.global_position)
		quit(1)
		return
	var crossing_time := elapsed - crossing_start
	print("Reached Mid Heart east lip at t=%.2fs (pos=%s)" % [elapsed, player.global_position])
	print("MID_HEART_CROSSING_SECONDS=%.2f" % crossing_time)

	for tick in range(10):
		await physics_frame
	await RenderingServer.frame_post_draw
	var final_img := root.get_texture().get_image()
	final_img.save_png(_output_dir.path_join("walk-%03d_t%.1fs_FINISH.png" % [shot_index, elapsed]))

	scene.queue_free()
	await process_frame
	quit(0)
