extends SceneTree
## Terraria-style light: the Hollow is lit, rock is black a few cells in, the player's own light
## reaches a short way into stone, lamps light galleries, Gear can raise the player's light, and the
## dark hides in the dev overview zooms.


func _init() -> void:
	call_deferred("_run")


func _fail(msg: String) -> void:
	push_error("FAIL " + msg)
	quit(1)


func _frames(n: int) -> void:
	for _i in range(n):
		await physics_frame


func _run() -> void:
	var scene: Node = (load("res://main.tscn") as PackedScene).instantiate()
	root.add_child(scene)
	await process_frame
	await process_frame
	var vision := scene.get_node_or_null("Vision") as VisionLayer
	var player: CharacterBody2D = scene.get_node("Player") as CharacterBody2D
	if vision == null:
		_fail("Vision layer missing from main.tscn")
		return
	await _frames(8)
	if not vision.is_dark_visible():
		_fail("the dark should be on in normal play")
		return

	# --- In the Hollow it is bright: ambient light, and lamps. ---
	player.global_position = HollowLayout.player_spawn_point()
	(player.get_node("Camera2D") as Camera2D).reset_smoothing()
	await _frames(40) # let the camera catch up to the teleport
	vision.solve_now()
	var home := player.global_position + Vector2(16.0, 16.0)
	var cavity_pt := home + Vector2(220.0, -90.0)
	if vision.light_at(home) < 0.85 or vision.light_at(cavity_pt) < 0.8:
		_fail("the Hollow should be well lit (player %s, cavity %s)" % [vision.light_at(home), vision.light_at(cavity_pt)])
		return
	print("PASS the Hollow is lit")

	# --- In a dug gallery with no lamp near, you see a short way and the rock is dark. ---
	var gallery_x := -5744.0 # the west end of the High-West gallery, beside the unfinished face
	player.global_position = Vector2(gallery_x, HollowLayout.WEST_HIGH_UPPER_Y - 32.0)
	player.velocity = Vector2.ZERO
	(player.get_node("Camera2D") as Camera2D).reset_smoothing()
	await _frames(40) # let the camera catch up to the teleport
	vision.solve_now()
	var eye := player.global_position + Vector2(16.0, 16.0)
	var face_1 := eye + Vector2(-48.0, 0.0) # one cell into the rock face (the face begins 32px west of the eye)
	var face_4 := eye + Vector2(-112.0, 0.0) # four cells in
	var face_9 := eye + Vector2(-190.0, 0.0)
	var air_6 := eye + Vector2(96.0, 0.0) # six cells of open gallery
	var l_player := vision.light_at(eye)
	var l1 := vision.light_at(face_1)
	var l4 := vision.light_at(face_4)
	var l9 := vision.light_at(face_9)
	var la := vision.light_at(air_6)
	if l_player < 0.85:
		_fail("the player's own cell should be bright (%s)" % l_player)
		return
	if not (l1 > 0.25 and l4 < 0.12 and l9 < 0.02 and l1 > l4):
		_fail("rock should be lit a cell or two in then go black (1 cell %s, 4 cells %s, 9 cells %s)" % [l1, l4, l9])
		return
	if not (la > 0.25 and la > l4 + 0.2):
		_fail("open air should be seen further than rock (air %s at 6 cells, rock %s at 4 cells)" % [la, l4])
		return
	print("PASS in a gallery you see a short way into rock (%.2f, %.2f, %.2f) and further along air (%.2f)" % [l1, l4, l9, la])

	# --- A mined tile opens the dark. ---
	var terrain: TerrainLayer = scene.get_node("Terrain") as TerrainLayer
	var dig_cell := terrain.world_to_cell(face_4)
	if not terrain.has_tile(dig_cell):
		_fail("test setup: rock expected at %s" % dig_cell)
		return
	var first_cell := terrain.world_to_cell(face_1)
	for cx in range(dig_cell.x - 1, first_cell.x + 1): # a tunnel from the face to past the fourth cell
		terrain.erase_cell(Vector2i(cx, dig_cell.y))
	vision.solve_now()
	if vision.light_at(face_4) <= l4 + 0.1:
		_fail("a cleared tunnel should light further in (%s -> %s)" % [l4, vision.light_at(face_4)])
		return
	print("PASS digging lets the light in")

	# --- Gear: the player's light is what the upgrade raises. ---
	if not (VisionLayer.strength_for(160.0) > VisionLayer.strength_for(0.0) + 0.5):
		_fail("a vision bonus should raise the player's light")
		return
	print("PASS a vision bonus raises the player's light")

	# --- Toggle and dev zoom. ---
	vision.enabled = false
	await _frames(2)
	if vision.is_dark_visible():
		_fail("toggled off, the dark must hide")
		return
	vision.enabled = true
	var cam: Camera2D = player.get_node("Camera2D") as Camera2D
	cam.set_dev_zoom(2)
	await _frames(3)
	if vision.is_dark_visible():
		_fail("the dark must hide in the dev overview zoom")
		return
	cam.set_dev_zoom(0)
	await _frames(3)
	if not vision.is_dark_visible():
		_fail("back at normal zoom the dark should return")
		return
	print("PASS the dark toggles (V) and hides in the dev overview zooms")
	print("VISION_TESTS_PASSED")
	quit(0)
