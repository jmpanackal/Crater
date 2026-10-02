extends Node
## Krater district system: Capacity / Demand / District Reserves.
## Build Bible Spec 22 (docs/build-bible/specs/22-districts.md).
##
## The core district economy loop, canon §24–§26 exactly, thin slice:
## Wickwork with real contributor content, Glowbeds/Cistern the same
## machinery seeded with placeholder contributors. Named "District"
## (singular, as the dependency map and specs call it) because the retired
## prototype economy previously held named goods and a Harvest queue.
## goods, Harvest timer, Shortage Risk) — that legacy keeps running
## alongside until its consumers (work orders, HUD, upgrades) migrate in
## Specs 23/24/26; nothing here reaches into it.
##
## Six tracked values per district (canon §24): Capacity (a sum of named
## contributors, grows only through lasting investment), Civic Demand (a
## sum of named contributors — the breakdown IS the data, Spec 22 option
## A), District Output (= Capacity each cycle, not its own lever),
## Reserves (banked surplus), Reserve Cap, and the DERIVED Unmet Demand /
## condition label — computed live, never cached (option A).
##
## Resolution runs ONCE per civic cycle on EventBus.cycle_resolved (Spec
## 15 fires it exactly once, on Ritual -> Rousing), in canon's locked
## order: (1) Output = Capacity, (2) Output serves Demand first, (3)
## surplus fills Reserves up to the Cap, (4) a short Output draws on
## Reserves, (5) what's still short is Unmet Demand. Then G4-C as an
## explicit step 6 (option A): the books' expected Reserves vs. the real
## Reserves — a withdrawal that was never recorded (Diversion, Spec 26)
## shows up as unexplained loss, and when the cumulative loss since the
## last check crosses a threshold that shrinks as condition worsens, a
## `district_discrepancy` fact is logged (what Investigation, Spec 20,
## scores) and the books are re-checked.
##
## One generic withdrawal entry point (dependency map: "District owns
## Reserves and serves withdrawal requests; neither system knows about
## the other"): Orders (Spec 23) and Diversion (Spec 26) both call
## request_withdrawal(); it grants only what's there and never goes
## negative. The requester's context says whether the draw is on the
## books ("recorded": true — an authorized Order) or not (a theft) —
## that is the whole accounting model, not a distinction in service.
## deposit() is G5-C: return diverted output / donate personal stores.
##
## Access via get_tree().root.get_node("District") (no class_name,
## matching the existing project convention — see resources.gd).

const DISTRICTS_DIR := "res://content/districts/"
const TUNING_DOMAIN := "district_tuning"

const FACT_DISTRICT_DISCREPANCY := &"district_discrepancy"
const FACT_UNMET_DEMAND := &"district_unmet_demand"

## Per district id: {
##   "capacity": [{"id","name","amount","cycles_left"}],  (content + registered)
##   "demand":   [{"id","name","amount","cycles_left"}],
##   "reserves": float, "reserve_cap": float,
##   "ledger_reserves": float,   # what the books say (G4-C "expected")
##   "last": {}                  # last resolution summary
## }
var _districts: Dictionary = {}
var _defs: Dictionary = {}  # district_id -> Resource


func _ready() -> void:
	reload_definitions()
	var bus := get_tree().root.get_node_or_null("EventBus")
	if bus != null and not bus.cycle_resolved.is_connected(_on_cycle_resolved):
		bus.cycle_resolved.connect(_on_cycle_resolved)
	var console := get_tree().root.get_node_or_null("DebugConsole")
	if console == null:
		return
	console.register_command("district", "district [id] — Capacity/Demand breakdown, Reserves, condition, last resolution.", _debug_district)
	console.register_command("district_withdraw", "district_withdraw <id> <amount> [recorded|unrecorded] — request a withdrawal (default recorded).", _debug_withdraw)
	console.register_command("district_deposit", "district_deposit <id> <amount> — G5-C: return/donate to Reserves.", _debug_deposit)
	console.register_command("district_demand", "district_demand <id> <contributor_id> <amount> [cycles] — register (amount>0) or remove (amount=0) a demand contributor.", _debug_demand)


# --- Content ----------------------------------------------------------------------------

## Loads content/districts/*.tres and (re)seeds every district's baseline.
## Runtime-registered contributors, Reserves and the ledger are RESET —
## this is the new-game seed; load_state() restores a save on top.
func reload_definitions() -> void:
	_defs.clear()
	_districts.clear()
	var dir := DirAccess.open(DISTRICTS_DIR)
	if dir == null:
		push_warning("District: %s does not exist (no districts authored)" % DISTRICTS_DIR)
		return
	dir.list_dir_begin()
	var file_name := dir.get_next()
	while file_name != "":
		if not dir.current_is_dir() and file_name.ends_with(".tres"):
			var path := DISTRICTS_DIR + file_name
			var res: Resource = ResourceLoader.load(path, "", ResourceLoader.CACHE_MODE_REPLACE)
			if res == null:
				push_warning("District: failed to load %s — skipped" % path)
			else:
				var id := StringName(str(res.get("district_id")))
				if id == &"":
					push_warning("District: %s has no district_id — skipped" % path)
				else:
					_defs[id] = res
					_districts[id] = _seed_from(res)
		file_name = dir.get_next()
	dir.list_dir_end()


func _seed_from(def: Resource) -> Dictionary:
	var state := {
		"capacity": _contributors_from(def.get("capacity_contributors")),
		"demand": _contributors_from(def.get("demand_contributors")),
		"reserves": maxf(0.0, float(def.get("starting_reserves"))),
		"reserve_cap": maxf(0.0, float(def.get("reserve_cap"))),
		"ledger_reserves": maxf(0.0, float(def.get("starting_reserves"))),
		"last": {},
	}
	state["reserves"] = minf(state["reserves"], state["reserve_cap"])
	state["ledger_reserves"] = state["reserves"]
	return state


func _contributors_from(raw: Variant) -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	if typeof(raw) != TYPE_ARRAY:
		return out
	for entry: Variant in (raw as Array):
		if typeof(entry) != TYPE_DICTIONARY:
			continue
		var e: Dictionary = entry
		out.append({
			"id": str(e.get("id", "")),
			"name": str(e.get("name", e.get("id", ""))),
			"amount": float(e.get("amount", 0.0)),
			"cycles_left": -1,  # baseline content is permanent
		})
	return out


func is_known_district(district_id: StringName) -> bool:
	return _districts.has(district_id)


func get_district_ids() -> Array[StringName]:
	var names: Array[String] = []
	for key: Variant in _districts.keys():
		names.append(str(key))
	names.sort()
	var out: Array[StringName] = []
	for n: String in names:
		out.append(StringName(n))
	return out


func get_display_name(district_id: StringName) -> String:
	var def: Resource = _defs.get(district_id, null)
	if def == null:
		return str(district_id)
	var display := str(def.get("display_name"))
	return display if display != "" else str(district_id)


# --- Tuning ---------------------------------------------------------------------------------

func _tuning() -> Resource:
	var registry := get_tree().root.get_node_or_null("TuningRegistry")
	if registry == null:
		return null
	return registry.get_domain(TUNING_DOMAIN)


func get_condition_ladder() -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	var tuning := _tuning()
	if tuning == null:
		return [
			{"id": &"comfortable", "label": "Comfortable", "min_health": 1.0},
			{"id": &"stable", "label": "Stable", "min_health": 0.25},
			{"id": &"strained", "label": "Strained", "min_health": 0.0},
			{"id": &"shortage", "label": "Shortage", "min_health": -0.5},
			{"id": &"critical", "label": "Critical", "min_health": -1000000.0},
		]
	var ids: Array = tuning.condition_ids
	var labels: Array = tuning.condition_labels
	var mins: Array = tuning.condition_min_health
	for i in range(ids.size()):
		out.append({
			"id": StringName(str(ids[i])),
			"label": str(labels[i]) if i < labels.size() else str(ids[i]).capitalize(),
			"min_health": float(mins[i]) if i < mins.size() else -1000000.0,
		})
	return out


func get_discrepancy_threshold(district_id: StringName) -> float:
	var tuning := _tuning()
	var base := float(tuning.discrepancy_threshold) if tuning != null else 3.0
	var multiplier := 1.0
	if tuning != null:
		var table: Dictionary = tuning.discrepancy_multiplier_by_condition
		multiplier = float(table.get(str(get_condition(district_id)), 1.0))
	return base * multiplier


# --- Reads (derived where canon says derived) -----------------------------------------------------

func get_capacity(district_id: StringName) -> float:
	return _sum(_state(district_id).get("capacity", []))


func get_demand(district_id: StringName) -> float:
	return _sum(_state(district_id).get("demand", []))


## Copies of the named contributors — the explainable breakdown (§24/§26).
func get_demand_breakdown(district_id: StringName) -> Array[Dictionary]:
	return _copy_contributors(_state(district_id).get("demand", []))


func get_capacity_breakdown(district_id: StringName) -> Array[Dictionary]:
	return _copy_contributors(_state(district_id).get("capacity", []))


func get_reserves(district_id: StringName) -> float:
	return float(_state(district_id).get("reserves", 0.0))


func get_reserve_cap(district_id: StringName) -> float:
	return float(_state(district_id).get("reserve_cap", 0.0))


## Whole buffer beyond one cycle's need, in cycles of Demand — the live
## number the condition label is read from. Never stored.
func get_health(district_id: StringName) -> float:
	var demand := get_demand(district_id)
	return (get_capacity(district_id) + get_reserves(district_id) - demand) / maxf(demand, 1.0)


## The derived qualitative condition (canon §26 DIRECTION names, tunable),
## computed live from Capacity / Demand contributors / Reserves right now.
func get_condition(district_id: StringName) -> StringName:
	if not is_known_district(district_id):
		return &""
	var health := get_health(district_id)
	for step: Dictionary in get_condition_ladder():
		if health >= float(step["min_health"]):
			return step["id"]
	return get_condition_ladder()[-1]["id"]


func get_condition_label(district_id: StringName) -> String:
	var id := get_condition(district_id)
	for step: Dictionary in get_condition_ladder():
		if step["id"] == id:
			return str(step["label"])
	return str(id)


## Summary of the last cycle resolution for this district ({} if none yet):
## {"cycle", "output", "demand", "served", "surplus_banked", "drawn_from_reserves",
##  "unmet", "reserves_after", "unexplained_loss", "discrepancy_logged"}.
func get_last_resolution(district_id: StringName) -> Dictionary:
	return (_state(district_id).get("last", {}) as Dictionary).duplicate()


func get_unmet_demand(district_id: StringName) -> float:
	return float(get_last_resolution(district_id).get("unmet", 0.0))


# --- Contributors (Projects, Jobs' emergency Capacity, civic construction) ------------------------

## Registers (or replaces, by contributor id) a named Capacity source.
## cycles = -1 permanent (a lasting improvement); N > 0 expires after N
## resolutions (G5-B emergency Capacity).
func register_capacity_contributor(district_id: StringName, contributor_id: String, name: String, amount: float, cycles: int = -1) -> bool:
	return _register(district_id, "capacity", contributor_id, name, amount, cycles)


func unregister_capacity_contributor(district_id: StringName, contributor_id: String) -> bool:
	return _unregister(district_id, "capacity", contributor_id)


## Registers (or replaces) a named Demand source — a project under
## construction, maintenance, a frontier worksite. Demand must always be
## explainable, so a name is required.
func register_demand_contributor(district_id: StringName, contributor_id: String, name: String, amount: float, cycles: int = -1) -> bool:
	return _register(district_id, "demand", contributor_id, name, amount, cycles)


func unregister_demand_contributor(district_id: StringName, contributor_id: String) -> bool:
	return _unregister(district_id, "demand", contributor_id)


func _register(district_id: StringName, kind: String, contributor_id: String, name: String, amount: float, cycles: int) -> bool:
	if not is_known_district(district_id) or contributor_id == "" or name.strip_edges() == "" or amount < 0.0:
		return false
	var list: Array[Dictionary] = _state(district_id)[kind]
	for i in range(list.size()):
		if str(list[i]["id"]) == contributor_id:
			list[i] = {"id": contributor_id, "name": name, "amount": amount, "cycles_left": cycles}
			_emit_changed(district_id)
			return true
	list.append({"id": contributor_id, "name": name, "amount": amount, "cycles_left": cycles})
	_emit_changed(district_id)
	return true


func _unregister(district_id: StringName, kind: String, contributor_id: String) -> bool:
	if not is_known_district(district_id):
		return false
	var list: Array[Dictionary] = _state(district_id)[kind]
	for i in range(list.size()):
		if str(list[i]["id"]) == contributor_id:
			list.remove_at(i)
			_emit_changed(district_id)
			return true
	return false


# --- Withdrawals and deposits (Orders, Diversion, G5-C) ------------------------------------------

## The one generic withdrawal path. Grants only what's actually in
## Reserves (never negative); the requester decides what a short grant
## means for it. requester_context["recorded"] (default true) says whether
## the draw goes on the books: an authorized Order is recorded, a
## diversion is not — which is exactly what G4-C's accounting check later
## notices. Returns the amount granted.
func request_withdrawal(district_id: StringName, amount: float, requester_context: Dictionary = {}) -> float:
	if not is_known_district(district_id) or amount <= 0.0:
		return 0.0
	var state := _state(district_id)
	var granted := minf(amount, float(state["reserves"]))
	if granted <= 0.0:
		return 0.0
	state["reserves"] = float(state["reserves"]) - granted
	if bool(requester_context.get("recorded", true)):
		state["ledger_reserves"] = maxf(0.0, float(state["ledger_reserves"]) - granted)
	_emit_changed(district_id)
	return granted


## G5-C: return diverted output or donate personal stores straight into
## Reserves (up to the Cap; the overflow is refused, not lost silently).
## source_context["recorded"] (default true) — an open return/donation is
## on the books; an anonymous one isn't, which quietly REDUCES the
## unexplained loss the next check sees. Reflected immediately in
## get_condition(). Returns the amount accepted.
func deposit(district_id: StringName, amount: float, source_context: Dictionary = {}) -> float:
	if not is_known_district(district_id) or amount <= 0.0:
		return 0.0
	var state := _state(district_id)
	var room := maxf(0.0, float(state["reserve_cap"]) - float(state["reserves"]))
	var accepted := minf(amount, room)
	if accepted <= 0.0:
		return 0.0
	state["reserves"] = float(state["reserves"]) + accepted
	if bool(source_context.get("recorded", true)):
		state["ledger_reserves"] = float(state["ledger_reserves"]) + accepted
	_emit_changed(district_id)
	return accepted


## A loss the books didn't know about is now accounted for (an open return
## of diverted output, Spec 26 G5-C; a confession; an investigation's
## finding). Lowers what the books expect so the next check doesn't count
## it as unexplained. Returns the amount explained.
func explain_loss(district_id: StringName, amount: float) -> float:
	if not is_known_district(district_id) or amount <= 0.0:
		return 0.0
	var state := _state(district_id)
	var explained := minf(amount, float(state["ledger_reserves"]))
	state["ledger_reserves"] = float(state["ledger_reserves"]) - explained
	return explained


# --- Cycle resolution (canon §24's locked order + G4-C step 6) -----------------------------------

func _on_cycle_resolved(cycle: int) -> void:
	for district_id: StringName in get_district_ids():
		resolve_district(district_id, cycle)


## Exposed for tests/debug; the real trigger is EventBus.cycle_resolved.
func resolve_district(district_id: StringName, cycle: int) -> Dictionary:
	if not is_known_district(district_id):
		return {}
	var state := _state(district_id)
	var capacity := get_capacity(district_id)
	var demand := get_demand(district_id)
	var reserves := float(state["reserves"])
	var cap := float(state["reserve_cap"])
	# 1. Output = Capacity.
	var output := capacity
	# 2. Output serves Demand first.
	var served := minf(output, demand)
	# 3. Surplus fills Reserves up to the Cap.
	var surplus := output - served
	var banked := minf(surplus, maxf(0.0, cap - reserves))
	reserves += banked
	# 4. A short Output draws on Reserves.
	var deficit := demand - served
	var drawn := minf(deficit, reserves)
	reserves -= drawn
	# 5. What's still short is Unmet Demand.
	var unmet := deficit - drawn
	state["reserves"] = reserves
	# The books expect the same production/demand movement.
	var ledger := float(state["ledger_reserves"])
	var ledger_banked := minf(surplus, maxf(0.0, cap - ledger))
	ledger += ledger_banked
	var ledger_drawn := minf(deficit, ledger)
	ledger -= ledger_drawn
	var expected_unmet := deficit - ledger_drawn
	state["ledger_reserves"] = ledger
	# 6. G4-C accounting check: cumulative unexplained loss since the last
	# check = what the books expect minus what's really there. Two places
	# a missing buffer shows: Reserves lower than the books say, AND —
	# when a shortage consumed everything either way — more Unmet Demand
	# than the books expected (the stolen buffer would have covered it).
	var unexplained := maxf(0.0, ledger - reserves) + maxf(0.0, unmet - expected_unmet)
	var threshold := get_discrepancy_threshold(district_id)
	var logged := false
	if unexplained >= threshold and unexplained > 0.0:
		logged = true
		_record_discrepancy(district_id, unexplained, threshold, cycle)
		state["ledger_reserves"] = reserves  # checked: the books now match
	_expire_contributors(state)
	var summary := {
		"cycle": cycle, "output": output, "demand": demand, "served": served,
		"surplus_banked": banked, "drawn_from_reserves": drawn, "unmet": unmet,
		"reserves_after": reserves, "unexplained_loss": unexplained, "discrepancy_logged": logged,
	}
	state["last"] = summary
	if unmet > 0.0:
		_record_unmet(district_id, unmet, cycle)
	var bus := get_tree().root.get_node_or_null("EventBus")
	if bus != null and bus.has_signal("district_resolved"):
		bus.district_resolved.emit(district_id, summary.duplicate())
	_emit_changed(district_id)
	return summary.duplicate()


func _expire_contributors(state: Dictionary) -> void:
	for kind in ["capacity", "demand"]:
		var list: Array[Dictionary] = state[kind]
		var keep: Array[Dictionary] = []
		for entry: Dictionary in list:
			var left := int(entry["cycles_left"])
			if left < 0:
				keep.append(entry)
			elif left > 1:
				entry["cycles_left"] = left - 1
				keep.append(entry)
			# left == 1: this was its last resolution — drop it.
		state[kind] = keep


func _record_discrepancy(district_id: StringName, unexplained: float, threshold: float, cycle: int) -> void:
	var fact_log := get_tree().root.get_node_or_null("FactLog")
	if fact_log == null:
		return
	var witnesses: Array[String] = []
	fact_log.record(FACT_DISTRICT_DISCREPANCY, str(district_id), district_id, witnesses, {
		"district_id": str(district_id), "unexplained_loss": unexplained, "threshold": threshold,
		"condition": str(get_condition(district_id)),
	}, cycle)


func _record_unmet(district_id: StringName, unmet: float, cycle: int) -> void:
	var fact_log := get_tree().root.get_node_or_null("FactLog")
	if fact_log == null:
		return
	var witnesses: Array[String] = []
	fact_log.record(FACT_UNMET_DEMAND, str(district_id), district_id, witnesses, {
		"district_id": str(district_id), "unmet": unmet, "condition": str(get_condition(district_id)),
	}, cycle)


# --- Internals ------------------------------------------------------------------------------------

func _state(district_id: StringName) -> Dictionary:
	return _districts.get(district_id, {})


func _sum(list: Array) -> float:
	var total := 0.0
	for entry: Dictionary in list:
		total += float(entry["amount"])
	return total


func _copy_contributors(list: Array) -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	for entry: Dictionary in list:
		out.append(entry.duplicate())
	return out


func _emit_changed(district_id: StringName) -> void:
	var bus := get_tree().root.get_node_or_null("EventBus") if is_inside_tree() else null
	if bus != null and bus.has_signal("district_changed"):
		bus.district_changed.emit(district_id, get_condition(district_id))


# --- Build Bible Spec 02 uniform SaveLoad contract ------------------------------------------------

func save_state() -> Dictionary:
	var out: Dictionary = {}
	for district_id: StringName in get_district_ids():
		var state := _state(district_id)
		out[str(district_id)] = {
			"reserves": float(state["reserves"]),
			"ledger_reserves": float(state["ledger_reserves"]),
			"reserve_cap": float(state["reserve_cap"]),
			"capacity": _copy_contributors(state["capacity"]),
			"demand": _copy_contributors(state["demand"]),
			"last": (state["last"] as Dictionary).duplicate(),
		}
	return {"districts": out}


func load_state(data: Dictionary) -> void:
	reload_definitions()
	var districts: Variant = data.get("districts", {})
	if typeof(districts) != TYPE_DICTIONARY:
		return
	for key: Variant in (districts as Dictionary).keys():
		var district_id := StringName(str(key))
		if not is_known_district(district_id):
			continue  # a district the current content no longer authors
		var saved: Dictionary = (districts as Dictionary)[key]
		var state := _state(district_id)
		state["reserves"] = float(saved.get("reserves", state["reserves"]))
		state["ledger_reserves"] = float(saved.get("ledger_reserves", state["reserves"]))
		state["reserve_cap"] = float(saved.get("reserve_cap", state["reserve_cap"]))
		state["capacity"] = _restore_contributors(saved.get("capacity", state["capacity"]))
		state["demand"] = _restore_contributors(saved.get("demand", state["demand"]))
		var last: Variant = saved.get("last", {})
		var restored_last: Dictionary = (last as Dictionary).duplicate() if typeof(last) == TYPE_DICTIONARY else {}
		if restored_last.has("cycle"):
			restored_last["cycle"] = int(restored_last["cycle"])  # JSON stores every number as float
		state["last"] = restored_last


func _restore_contributors(raw: Variant) -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	if typeof(raw) != TYPE_ARRAY:
		return out
	for entry: Variant in (raw as Array):
		if typeof(entry) != TYPE_DICTIONARY:
			continue
		var e: Dictionary = entry
		out.append({
			"id": str(e.get("id", "")), "name": str(e.get("name", "")),
			"amount": float(e.get("amount", 0.0)), "cycles_left": int(e.get("cycles_left", -1)),
		})
	return out


func reset_all() -> void:
	reload_definitions()


# --- Debug ------------------------------------------------------------------------------------------

func _debug_district(args: Array[String]) -> String:
	var ids := get_district_ids()
	if not args.is_empty():
		ids = [StringName(args[0])]
	var lines: PackedStringArray = []
	for id: StringName in ids:
		if not is_known_district(id):
			lines.append("Unknown district '%s'" % id)
			continue
		lines.append("%s — %s (health %.2f): Capacity %.1f, Demand %.1f, Reserves %.1f / %.1f, discrepancy threshold %.1f" % [
			get_display_name(id), get_condition_label(id), get_health(id), get_capacity(id), get_demand(id), get_reserves(id), get_reserve_cap(id), get_discrepancy_threshold(id),
		])
		for c: Dictionary in get_capacity_breakdown(id):
			lines.append("   + %.1f  %s%s" % [float(c["amount"]), c["name"], "" if int(c["cycles_left"]) < 0 else " (%d cycles left)" % int(c["cycles_left"])])
		for d: Dictionary in get_demand_breakdown(id):
			lines.append("   - %.1f  %s%s" % [float(d["amount"]), d["name"], "" if int(d["cycles_left"]) < 0 else " (%d cycles left)" % int(d["cycles_left"])])
		var last := get_last_resolution(id)
		if not last.is_empty():
			lines.append("   last cycle %d: output %.1f served %.1f banked %.1f drew %.1f unmet %.1f unexplained %.1f%s" % [
				int(last["cycle"]), float(last["output"]), float(last["served"]), float(last["surplus_banked"]), float(last["drawn_from_reserves"]), float(last["unmet"]), float(last["unexplained_loss"]), " DISCREPANCY LOGGED" if bool(last["discrepancy_logged"]) else "",
			])
	return "\n".join(lines)


func _debug_withdraw(args: Array[String]) -> String:
	if args.size() < 2:
		return "Usage: district_withdraw <id> <amount> [recorded|unrecorded]"
	var recorded := args.size() < 3 or args[2].to_lower() != "unrecorded"
	var granted := request_withdrawal(StringName(args[0]), float(args[1]), {"recorded": recorded, "requester": "debug"})
	return "Granted %.1f of %s from %s (%s) — Reserves now %.1f" % [granted, args[1], args[0], "on the books" if recorded else "UNRECORDED", get_reserves(StringName(args[0]))]


func _debug_deposit(args: Array[String]) -> String:
	if args.size() < 2:
		return "Usage: district_deposit <id> <amount>"
	var accepted := deposit(StringName(args[0]), float(args[1]), {"source": "debug"})
	return "Accepted %.1f into %s — Reserves now %.1f, condition %s" % [accepted, args[0], get_reserves(StringName(args[0])), get_condition_label(StringName(args[0]))]


func _debug_demand(args: Array[String]) -> String:
	if args.size() < 3:
		return "Usage: district_demand <id> <contributor_id> <amount> [cycles]"
	var id := StringName(args[0])
	var amount := float(args[2])
	if amount <= 0.0:
		return "Removed" if unregister_demand_contributor(id, args[1]) else "No such contributor"
	var cycles := int(args[3]) if args.size() > 3 else -1
	if not register_demand_contributor(id, args[1], "Debug: %s" % args[1], amount, cycles):
		return "Refused (unknown district?)"
	return "%s Demand now %.1f — condition %s" % [args[0], get_demand(id), get_condition_label(id)]
