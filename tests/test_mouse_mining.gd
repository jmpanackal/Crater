extends SceneTree
## Terraria-style mouse mining: hover a tile, hold the button, it cracks and breaks. Reach and line
## of sight are enforced; progress fades when you let go; menus own the mouse.
## The mouse is replaced by MineController.aim_override (a world position).


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
	var player: CharacterBody2D = scene.get_node("Player") as CharacterBody2D
	var terrain: TerrainLayer = scene.get_node("Terrain") as TerrainLayer
	var mc: Node2D = player.get_node_or_null("MineController") as Node2D
	if mc == null or terrain == null:
		_fail("Player/MineController missing from main.tscn")
		return
	if not InputMap.has_action("mine"):
		_fail("the mine action is not registered")
		return
	var gallery_x := -5744.0 # at the west end of the High-West gallery, beside the unfinished rock face
	player.global_position = Vector2(gallery_x, HollowLayout.WEST_HIGH_UPPER_Y - 32.0)
	player.velocity = Vector2.ZERO
	await _frames(20)
	var cell := terrain.world_to_cell(Vector2(gallery_x - 24.0, HollowLayout.WEST_HIGH_UPPER_Y - 16.0)) # the face, level with the player
	if not terrain.has_tile(cell):
		_fail("test setup: expected rock at %s at the end of the High-West gallery" % cell)
		return
	var centre := terrain.to_global(terrain.map_to_local(cell))

	# --- 1. Hover is classified; holding breaks the tile after MINE_TIME, not before. ---
	mc.set("aim_override", centre)
	await _frames(2)
	if mc.hover_state() != &"ok" or mc.hovered_cell() != cell:
		_fail("a tile in reach and sight should be mineable (state %s, cell %s)" % [mc.hover_state(), mc.hovered_cell()])
		return
	Input.action_press("mine")
	await _frames(8)
	if not terrain.has_tile(cell) or mc.damage_at(cell) <= 0.0:
		_fail("holding should crack the tile without breaking it yet (damage %s)" % mc.damage_at(cell))
		return
	await _frames(14)
	Input.action_release("mine")
	if terrain.has_tile(cell):
		_fail("holding past MINE_TIME should break the tile")
		return
	var dug: Array = terrain.save_state()["dug_cells"]
	if not dug.has([cell.x, cell.y]):
		_fail("a mined tile is saved like any other dig")
		return
	print("PASS hover, hold to crack, break after the hold; the dig is saved")

	# --- 2. Out of reach does nothing, however long you hold. ---
	var far_cell := cell + Vector2i(-8, 0)
	mc.set("aim_override", terrain.to_global(terrain.map_to_local(far_cell)))
	Input.action_press("mine")
	await _frames(40)
	Input.action_release("mine")
	if mc.hover_state() != &"far" or not terrain.has_tile(far_cell):
		_fail("a tile past REACH_PX must not be mined (state %s)" % mc.hover_state())
		return
	print("PASS reach is enforced")

	# --- 3. Let go early and the cracks fade. ---
	var next := cell + Vector2i(0, -1)
	mc.set("aim_override", terrain.to_global(terrain.map_to_local(next)))
	Input.action_press("mine")
	await _frames(8)
	Input.action_release("mine")
	if mc.damage_at(next) <= 0.0:
		_fail("a started tile should carry damage")
		return
	await _frames(60)
	if mc.damage_at(next) > 0.0 or not terrain.has_tile(next):
		_fail("abandoned damage should fade away and leave the tile intact")
		return
	print("PASS abandoned cracks fade")

	# --- 3b. Direct access only: not through another tile, and not through the floor. ---
	var behind := terrain.world_to_cell(Vector2(gallery_x - 24.0 - 32.0, HollowLayout.WEST_HIGH_UPPER_Y - 16.0)) # two tiles deeper than the face
	var under_floor := terrain.world_to_cell(Vector2(gallery_x + 8.0, HollowLayout.WEST_HIGH_UPPER_Y + 24.0))
	for case in [["behind another tile", behind], ["through the floor", under_floor]]:
		var c: Vector2i = case[1]
		if not terrain.has_tile(c):
			_fail("test setup: expected rock %s" % case[0])
			return
		mc.set("aim_override", terrain.to_global(terrain.map_to_local(c)))
		Input.action_press("mine")
		await _frames(40)
		Input.action_release("mine")
		if mc.hover_state() != &"blocked" or not terrain.has_tile(c):
			_fail("a tile %s must not be mined (state %s)" % [case[0], mc.hover_state()])
			return
	print("PASS no mining through a tile or through the floor")

	# --- 4. Open air and the civic cavity are not minable. ---
	mc.set("aim_override", Vector2(gallery_x, HollowLayout.WEST_HIGH_UPPER_Y - 40.0))
	await _frames(2)
	if mc.hover_state() != &"none":
		_fail("empty air should not be a target (state %s)" % mc.hover_state())
		return
	print("PASS air is not a target")

	# --- 5. Line of sight: rock between you and a tile blocks it. Synthetic tiles in the cavity. ---
	var open := Vector2(1000.0, HollowLayout.WICK_Y - 400.0)
	player.global_position = open
	player.velocity = Vector2.ZERO
	var base := terrain.world_to_cell(open + Vector2(16.0, 16.0))
	var blocker := base + Vector2i(2, 0)
	var target := base + Vector2i(4, 0)
	terrain.set_cell(target, 0, TerrainLayer.PLACEHOLDER_ATLAS)
	if not mc.line_of_sight(target):
		_fail("open air to a tile should be in sight")
		return
	terrain.set_cell(blocker, 0, TerrainLayer.PLACEHOLDER_ATLAS)
	if mc.line_of_sight(target):
		_fail("a tile behind another tile must not be in sight")
		return
	terrain.erase_cell(blocker)
	terrain.erase_cell(target)
	print("PASS line of sight")

	# --- 6. A menu owns the mouse. ---
	player.global_position = Vector2(gallery_x, HollowLayout.WEST_HIGH_UPPER_Y - 32.0)
	await _frames(10)
	var panel: Node = scene.get_node_or_null("UI/DialoguePanel")
	var third := cell + Vector2i(0, -2)
	mc.set("aim_override", terrain.to_global(terrain.map_to_local(third)))
	if panel != null:
		panel.set("visible", true)
	Input.action_press("mine")
	await _frames(30)
	Input.action_release("mine")
	if panel != null:
		panel.set("visible", false)
	if not terrain.has_tile(third):
		_fail("mining must pause while the dialogue panel is open")
		return
	print("PASS menus block mining")

	mc.set("aim_override", Vector2.INF)
	print("MOUSE_MINING_TESTS_PASSED")
	quit(0)
