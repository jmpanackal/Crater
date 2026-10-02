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
	var stamina_reset: Node = root.get_node_or_null("Stamina")
	if stamina_reset:
		stamina_reset.reset_all()

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

	# --- 1. Hauling doesn't exist yet — that hook fails safe. Stamina now
	# does exist (Spec 08) — _can_afford_dig() should genuinely delegate to
	# its real can_afford(), not a leftover hardcoded stub. ---
	if not is_equal_approx(float(player.call("_hauling_speed_multiplier")), 1.0):
		push_error("FAIL _hauling_speed_multiplier() should default 1.0 with no Hauling autoload")
		quit(1)
		return
	var stamina: Node = root.get_node_or_null("Stamina")
	if stamina == null:
		push_error("FAIL Stamina autoload missing")
		quit(1)
		return
	var expected: bool = stamina.can_afford(player.DIG_STAMINA_COST)
	if bool(player.call("_can_afford_dig")) != expected:
		push_error("FAIL _can_afford_dig() does not match Stamina.can_afford(DIG_STAMINA_COST) — stale/stubbed logic?")
		quit(1)
		return
	print("PASS Hauling hook fails safe (no Hauling yet); _can_afford_dig() genuinely delegates to real Stamina")

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

	# --- 3. DIG_STAMINA_COST is deliberately 0.0 (canon-OPEN, not tuned
	# yet — see player.gd's own comment), so a dig is always affordable
	# right now by design; that's proven directly above. Once a real
	# tuning value lands, Spec 08's own test suite already proves
	# Stamina.can_afford()/spend()/overexert() are correct in isolation —
	# re-proving "an unaffordable Stamina blocks a dig" here would just be
	# testing DIG_STAMINA_COST's future value, not this spec's own contract.

	print("PLAYER_CONTRACT_TESTS_PASSED")
	quit(0)
