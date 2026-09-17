extends SceneTree
## Build Bible Spec 07 (Player Controller) acceptance tests — the parts that
## are actually new (contract hooks into not-yet-built Stamina/Hauling).
## Existing movement/dig/coyote/buffer/squash regression coverage already
## lives in test_player_feel.gd and test_player_sprite.gd and isn't
## duplicated here.


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var community: Node = root.get_node_or_null("Community")
	var save_load: Node = root.get_node_or_null("SaveLoad")
	if community:
		community.set_paused(true)
		if "skip_lie_prompt" in community:
			community.skip_lie_prompt = true
	if save_load:
		save_load.clear_save()

	var scene: Node = (load("res://main.tscn") as PackedScene).instantiate()
	root.add_child(scene)
	await process_frame
	await process_frame

	var player: Node = scene.get_node_or_null("Player")
	var terrain: TerrainLayer = scene.get_node_or_null("Terrain") as TerrainLayer
	if player == null or terrain == null:
		push_error("FAIL missing Player or Terrain in main.tscn")
		quit(1)
		return

	# --- 1. Stubbed Stamina/Hauling don't exist yet — hooks fail safe. ---
	if not bool(player.call("_can_afford_dig")):
		push_error("FAIL _can_afford_dig() should default true with no Stamina autoload")
		quit(1)
		return
	if not is_equal_approx(float(player.call("_hauling_speed_multiplier")), 1.0):
		push_error("FAIL _hauling_speed_multiplier() should default 1.0 with no Hauling autoload")
		quit(1)
		return
	print("PASS Stamina/Hauling hooks fail safe (unblocked/unaffected) when those systems don't exist")

	# --- 2. Baseline move/dig remain available with zero Gear/systems —
	# a real dig still succeeds end to end. ---
	terrain.clear()
	var cell := Vector2i(TerrainLayer.DIG_START_X + 1, 6)
	terrain.set_cell(cell + Vector2i.DOWN, 0, TerrainLayer.PLACEHOLDER_ATLAS)
	var origin := terrain.to_global(terrain.map_to_local(cell))
	if not terrain.dig_in_direction(origin, Vector2i.DOWN):
		push_error("FAIL baseline dig failed with zero Gear/systems present")
		quit(1)
		return
	print("PASS baseline dig remains available with zero Gear equipped")

	# --- 3. A real Stamina test double (proving the hook actually reads
	# through, not just a permanently-true stub) blocks the dig. ---
	var fake_stamina := Node.new()
	fake_stamina.name = "Stamina"
	var stamina_script := GDScript.new()
	stamina_script.source_code = "extends Node\nfunc can_afford(_action: String) -> bool:\n\treturn false\n"
	stamina_script.reload()
	fake_stamina.set_script(stamina_script)
	root.add_child(fake_stamina)

	if bool(player.call("_can_afford_dig")):
		push_error("FAIL _can_afford_dig() did not respect a real Stamina.can_afford() returning false")
		quit(1)
		return

	terrain.set_cell(cell + Vector2i.UP, 0, TerrainLayer.PLACEHOLDER_ATLAS)
	var before := terrain.has_tile(cell + Vector2i.UP)
	player.call("_try_dig")
	if terrain.has_tile(cell + Vector2i.UP) != before:
		push_error("FAIL _try_dig() dug despite Stamina refusing to afford it")
		quit(1)
		return
	print("PASS a real Stamina.can_afford()=false blocks _try_dig() (hook reads through, not a permanent stub)")

	fake_stamina.queue_free()
	print("PLAYER_CONTRACT_TESTS_PASSED")
	quit(0)
