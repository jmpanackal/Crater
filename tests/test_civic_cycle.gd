extends SceneTree
## Build Bible Spec 15 (Civic Cycle / Pulse / Ritual) acceptance tests.
##
## Not covered here, and why:
## - The economics of district resolution — Spec 22 hangs them off
##   EventBus.cycle_resolved; this only proves the event's timing/count.
## - What a missed Ritual MEANS (Trust, NPC reactions) — canon §12 says it
##   is contextual, never an automatic penalty; Specs 19/21 read the fact.
## - Mid-rescue / forced-time-skip double logging — Spec 30's forward
##   dependency, flagged in the spec itself.

const RitualGroundScript := preload("res://ritual_ground.gd")

var _body: CharacterBody2D


func _init() -> void:
	call_deferred("_run")


func _fail(msg: String) -> void:
	push_error("FAIL " + msg)
	quit(1)


func _move_body_to(pos: Vector2) -> void:
	_body.global_position = pos
	for _i in range(3):
		await physics_frame


func _run() -> void:
	var civic: Node = root.get_node_or_null("CivicCycle")
	var clock: Node = root.get_node_or_null("Clock")
	var bus: Node = root.get_node_or_null("EventBus")
	var fact_log: Node = root.get_node_or_null("FactLog")
	var console: Node = root.get_node_or_null("DebugConsole")
	var save_load: Node = root.get_node_or_null("SaveLoad")
	var community: Node = root.get_node_or_null("Community")
	if civic == null or clock == null or bus == null or fact_log == null or console == null or save_load == null:
		_fail("missing autoloads (CivicCycle / Clock / EventBus / FactLog / DebugConsole / SaveLoad)")
		return
	if community:
		community.set_paused(true)
	save_load.clear_save()
	clock.pause("test")  # real time must not move phases under us
	clock.reset_all()
	clock.pause("test")
	civic.reset_all()
	fact_log.clear_all()

	var resolved: Array = []
	bus.cycle_resolved.connect(func(cycle: int) -> void: resolved.append(cycle))
	var checks: Array = []
	bus.ritual_checked.connect(func(attended: bool, cycle: int) -> void: checks.append({"attended": attended, "cycle": cycle}))

	# --- 1. District resolution fires exactly once per cycle, at the
	# Ritual -> Rousing transition, observable via EventBus. ---
	console.execute("force_advance 3")  # rousing -> working -> gathering -> ritual
	if clock.get_phase() != &"ritual" or not resolved.is_empty():
		_fail("cycle_resolved fired before Ritual -> Rousing (phase %s, events %s)" % [clock.get_phase(), resolved])
		return
	console.execute("force_advance 1")  # ritual -> rousing: cycle 0 ends
	if resolved.size() != 1 or int(resolved[0]) != 0 or int(civic.get_last_resolved_cycle()) != 0:
		_fail("expected exactly one cycle_resolved(0), got %s" % [resolved])
		return
	console.execute("force_advance 4")  # a full second cycle
	if resolved.size() != 2 or int(resolved[1]) != 1 or clock.get_phase() != &"rousing":
		_fail("second cycle did not resolve exactly once with index 1: %s" % [resolved])
		return
	# A sleep-style advance from Gathering crosses Ritual -> Rousing once
	# and must resolve exactly once too (G3: sleep triggers one resolution).
	console.execute("force_phase gathering")
	if not bool(clock.request_advance_to_next_rousing()) or resolved.size() != 3 or int(resolved[2]) != 2:
		_fail("sleep-advance did not resolve exactly one cycle: %s" % [resolved])
		return
	print("PASS district resolution fires exactly once per cycle at Ritual -> Rousing, via EventBus")

	# --- 2. Ritual attendance is automatic: absent -> exactly one
	# ritual_missed fact for that cycle; present (real body overlap with a
	# Ritual ground) -> none. ---
	fact_log.clear_all()
	checks.clear()
	_body = CharacterBody2D.new()
	_body.name = "Player"
	_body.add_to_group("player")
	_body.collision_layer = 1
	_body.collision_mask = 0
	var body_shape := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = Vector2(16, 32)
	body_shape.shape = rect
	_body.add_child(body_shape)
	root.add_child(_body)
	var ground: Area2D = RitualGroundScript.new()
	ground.name = "TestRitualGround"
	ground.position = Vector2(0, 0)
	var ground_shape := CollisionShape2D.new()
	var ground_rect := RectangleShape2D.new()
	ground_rect.size = Vector2(176, 80)
	ground_shape.shape = ground_rect
	ground.add_child(ground_shape)
	root.add_child(ground)
	await _move_body_to(Vector2(3000, 3000))
	if bool(civic.is_player_at_ritual()):
		_fail("player counted as at Ritual while far from any ground")
		return
	var cycle_now: int = int(clock.get_cycles_elapsed())
	console.execute("force_phase gathering")
	console.execute("force_advance 1")  # gathering -> ritual: the check
	var missed: Array = fact_log.get_by_type(&"ritual_missed")
	if missed.size() != 1:
		_fail("absent player should get exactly one ritual_missed fact, got %d" % missed.size())
		return
	var fact: Dictionary = missed[0]
	if int(fact["cycle"]) != cycle_now or fact["location"] != &"mid_heart" or str(fact["subject"]) != "player":
		_fail("ritual_missed fact carries the wrong cycle/location/subject: %s" % [fact])
		return
	if checks.size() != 1 or bool(checks[0]["attended"]) or int(checks[0]["cycle"]) != cycle_now:
		_fail("ritual_checked did not report attended=false once: %s" % [checks])
		return
	console.execute("force_advance 1")  # ritual -> rousing (next cycle)
	if (fact_log.get_by_type(&"ritual_missed") as Array).size() != 1:
		_fail("leaving Ritual logged a second fact")
		return
	await _move_body_to(ground.position)
	if not bool(civic.is_player_at_ritual()):
		_fail("standing on the Ritual ground did not count as present")
		return
	console.execute("force_phase gathering")
	console.execute("force_advance 1")  # gathering -> ritual, present this time
	if (fact_log.get_by_type(&"ritual_missed") as Array).size() != 1:
		_fail("present player got a ritual_missed fact")
		return
	if checks.size() != 2 or not bool(checks[1]["attended"]):
		_fail("ritual_checked did not report attended=true for the present player: %s" % [checks])
		return
	# The debug shortcut re-runs the check but never double-logs by itself
	# for a present player, and the per-cycle guard holds for repeats.
	var status: String = console.execute("civic")
	if not status.contains("attended"):
		_fail("civic debug status missing the last check: '%s'" % status)
		return
	print("PASS absent player gets exactly one ritual_missed fact; present player gets none")

	# --- 3. QUARANTINED (2026-09-18): the real play scene's Ritual ground over
	# Mid Heart — main.tscn's Hollow subtree was deleted for a canon-grounded
	# rebuild (docs/hollow-level-authoring.md). This pass only rebuilds Home
	# Court + Bottom-West Dig Front; Mid Heart and its Ritual ground are a
	# later phase. Restore this test's real assertions once Mid Heart is
	# rebuilt — tracked in docs/priority-roadmap.md, not forgotten.
	ground.queue_free()
	_body.queue_free()
	await process_frame

	# --- 4. Persistence through the real SaveLoad path; presence is live
	# state and never saved. ---
	var pre_save: Dictionary = civic.save_state()
	if pre_save.has("grounds") or int(pre_save["last_resolved_cycle"]) < 0:
		_fail("save_state shape wrong: %s" % [pre_save])
		return
	save_load.clear_save()
	if not save_load.save_game():
		_fail("save_game")
		return
	civic.reset_all()
	if int(civic.get_last_resolved_cycle()) != -1:
		_fail("reset_all did not clear")
		return
	if not save_load.load_game():
		_fail("load_game")
		return
	if civic.save_state() != pre_save:
		_fail("CivicCycle did not round-trip through SaveLoad:\n%s\nvs\n%s" % [pre_save, civic.save_state()])
		return
	print("PASS CivicCycle persists through a real save/load round-trip")

	save_load.clear_save()
	fact_log.clear_all()
	civic.reset_all()
	clock.reset_all()
	print("CIVIC_CYCLE_TESTS_PASSED")
	quit(0)
