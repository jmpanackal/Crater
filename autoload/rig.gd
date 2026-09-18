extends Node
## Krater Rig + Gear + Capacity / Strain (autoload: Rig).
## Build Bible Spec 14 (docs/build-bible/specs/14-rig-gear.md).
##
## The player's one evolving Rig (canon §33–§36, §67) — the dependency
## map's "Equipped Gear, Core Improvements, Rig Capacity" row. Owns:
## equipped Gear per slot, the owned-Gear list (Spec 23's Orders add to it),
## active grafts, installed Core Improvements, and the current Rig Strain
## block (delegated to Stamina under "rig_strain" — no shadow copy).
##
## Locked rules this implements literally:
## - Core Improvements use no slot and permanently raise slot count /
##   Capacity; Gear fills configurable slots. Slots are generic — canon §36
##   says category restrictions are "not yet locked", so none are invented.
## - Capacity is a SOFT limit (§35): equipping past it succeeds and creates
##   Rig Strain, which blocks stamina — linear in overcapacity, magnitude in
##   tuning (the exact formula is §35's own OPEN item; this is the contract).
## - Forbidden Gear is a graft (§67): uses no slot at all, draws only on
##   Capacity, and is installed only at the private workspace with the Mid
##   Reach residence tier or better.
## - Station restriction is enforced HERE, not by a UI convention (Spec 14,
##   confirmed option A): equip/unequip/graft/install refuse unless a
##   station is physically in range — the debug console, a future quick-
##   refit, anything, goes through the same refusal. "In range" is real
##   physics: rig_station.gd reports the player body entering/leaving its
##   area; this holds only a live, unsaved list of those stations.
## - Baseline move/dig/light/tether are never Gear-gated (Spec 07) — nothing
##   here can take them away; Gear only ADDS effects on top.
##
## Effects are additive numbers by id (get_effect_sum), consumed by the
## systems that own the behavior: Hauling reads EFFECT_HAULING_CAPACITY /
## EFFECT_HAULING_BLOCK_REDUCTION, Terrain reads EFFECT_QUIET_DIG, the
## player controller reads EFFECT_DIG_COST_REDUCTION. Rig never reaches
## into any of them (same one-directional shape as Spec 07/13).
##
## Not here, by design: what a Gear COSTS to acquire (Spec 23 Orders /
## Spec 28 Forbidden Builds decide that and then call add_owned_gear() /
## graft()); residence ownership (Spec 27 Homes — get_residence_tier() asks
## a "Homes" autoload when one exists and treats its absence as the Lower
## home, so grafting fails safe until Homes is built).
##
## Access via get_tree().root.get_node("Rig") (no class_name, matching the
## existing project convention — see resources.gd).

const GEAR_DIR := "res://content/gear/"
const CORE_IMPROVEMENTS_DIR := "res://content/core_improvements/"
const TUNING_DOMAIN := "rig_tuning"

const KIND_APPROVED := &"approved"
const KIND_GRAFT := &"graft"

## Station kinds a rig_station.gd can declare (canon §34: home, private
## workbench, Wickwork/approved facility, other proper stations). Only
## STATION_WORKSPACE permits grafting.
const STATION_HOME := &"home"
const STATION_WORKBENCH := &"workbench"
const STATION_WICKWORK := &"wickwork"
const STATION_WORKSPACE := &"workspace"

## Residence tiers in ascending order (canon §41/§67: Lower -> the Mid
## Reach -> Ashram Heights). Owned by Homes (Spec 27) once it exists.
const RESIDENCE_LOWER := &"lower"
const RESIDENCE_MID_REACH := &"mid_reach"
const RESIDENCE_ASHRAM_HEIGHTS := &"ashram_heights"
const RESIDENCE_ORDER: Array[StringName] = [RESIDENCE_LOWER, RESIDENCE_MID_REACH, RESIDENCE_ASHRAM_HEIGHTS]

## Effect ids consumed somewhere real today. Any other id in a definition's
## effects dictionary is inert data until a consumer exists.
const EFFECT_HAULING_CAPACITY := &"hauling_capacity_bonus"
const EFFECT_HAULING_BLOCK_REDUCTION := &"hauling_block_reduction"
const EFFECT_QUIET_DIG := &"quiet_dig_level"
const EFFECT_DIG_COST_REDUCTION := &"dig_stamina_cost_reduction"
## Build Bible Spec 18: Secrecy-build Gear raises the concealment tier a
## seal kit achieves by this many steps (Basic -> Improved -> Advanced).
## No authored Gear provides it yet — which Secrecy Gear improves which
## tier is that spec's own open item; the hook is what's locked.
const EFFECT_SEAL_TIER_BONUS := &"seal_tier_bonus"

## Change kinds carried by EventBus.rig_changed.
const CHANGE_EQUIPPED := &"equipped"
const CHANGE_UNEQUIPPED := &"unequipped"
const CHANGE_GRAFTED := &"grafted"
const CHANGE_UNGRAFTED := &"ungrafted"
const CHANGE_OWNED := &"owned"
const CHANGE_CORE_INSTALLED := &"core_installed"
const CHANGE_LOADED := &"loaded"

var _gear_defs: Dictionary = {}  # StringName -> Resource (GearDefinition)
var _core_defs: Dictionary = {}  # StringName -> Resource (CoreImprovementDefinition)

var _slots: Array[StringName] = []  # index = slot; &"" = empty
var _owned: Array[StringName] = []
var _grafts: Array[StringName] = []
var _core: Array[StringName] = []

## Live physical state only — which stations' areas the player body is
## inside right now. Never saved; self-corrects the moment a scene loads.
var _stations_in_range: Array[Node] = []


func _ready() -> void:
	reload_definitions()
	_ensure_slots()
	var console := get_tree().root.get_node_or_null("DebugConsole")
	if console == null:
		return
	console.register_command("rig", "rig — show slots, capacity, strain, grafts, owned Gear, stations in range.", _debug_rig)
	console.register_command("give_gear", "give_gear <gear_id> — add Gear to the owned list (no station needed; ownership isn't a refit).", _debug_give_gear)
	console.register_command("equip", "equip <gear_id> <slot> — equip owned Gear; refused away from a station, like every other path.", _debug_equip)
	console.register_command("unequip", "unequip <slot> — clear a slot; refused away from a station.", _debug_unequip)
	console.register_command("graft", "graft <design_id> — install a graft; refused outside a Mid Reach+ workspace.", _debug_graft)
	console.register_command("install_core", "install_core <improvement_id> — install a Core Improvement at a station.", _debug_install_core)


# --- Content Definitions ---------------------------------------------------------

## Re-scans both content directories (same resilience rule as Storage/
## Zones: a bad file is skipped with a warning). Equipped/owned state is
## untouched — only the definitions refresh.
func reload_definitions() -> void:
	_gear_defs = _load_definitions(GEAR_DIR, "gear_id")
	_core_defs = _load_definitions(CORE_IMPROVEMENTS_DIR, "improvement_id")


func _load_definitions(dir_path: String, id_property: String) -> Dictionary:
	var out: Dictionary = {}
	var dir := DirAccess.open(dir_path)
	if dir == null:
		push_warning("Rig: %s does not exist (no definitions authored)" % dir_path)
		return out
	dir.list_dir_begin()
	var file_name := dir.get_next()
	while file_name != "":
		if not dir.current_is_dir() and file_name.ends_with(".tres"):
			var path := dir_path + file_name
			var res: Resource = ResourceLoader.load(path, "", ResourceLoader.CACHE_MODE_REPLACE)
			if res == null:
				push_warning("Rig: failed to load %s — skipped" % path)
			else:
				var id := StringName(str(res.get(id_property)))
				if id == &"":
					push_warning("Rig: %s has no %s set — skipped" % [path, id_property])
				else:
					out[id] = res
		file_name = dir.get_next()
	dir.list_dir_end()
	return out


func is_known_gear(gear_id: StringName) -> bool:
	return _gear_defs.has(gear_id)


func get_gear_ids() -> Array[StringName]:
	var out: Array[StringName] = []
	for key: Variant in _gear_defs.keys():
		out.append(key)
	return out


func get_gear_kind(gear_id: StringName) -> StringName:
	var def: Resource = _gear_defs.get(gear_id, null)
	if def == null:
		return &""
	return StringName(str(def.get("kind")))


func is_graft_design(gear_id: StringName) -> bool:
	return get_gear_kind(gear_id) == KIND_GRAFT


func get_gear_display_name(gear_id: StringName) -> String:
	var def: Resource = _gear_defs.get(gear_id, null)
	if def == null:
		return str(gear_id)
	var display := str(def.get("display_name"))
	return display if display != "" else str(gear_id)


func get_gear_capacity_cost(gear_id: StringName) -> int:
	var def: Resource = _gear_defs.get(gear_id, null)
	if def == null:
		return 0
	return maxi(0, int(def.get("capacity_cost")))


## A copy of one definition's data, for UI/inspection. Copies, so nothing
## can edit the loaded definition through this.
func get_gear_info(gear_id: StringName) -> Dictionary:
	var def: Resource = _gear_defs.get(gear_id, null)
	if def == null:
		return {}
	return {
		"gear_id": gear_id,
		"display_name": get_gear_display_name(gear_id),
		"description": str(def.get("description")),
		"kind": get_gear_kind(gear_id),
		"category": StringName(str(def.get("category"))),
		"capacity_cost": get_gear_capacity_cost(gear_id),
		"effects": _effects_of(def),
	}


func is_known_core_improvement(improvement_id: StringName) -> bool:
	return _core_defs.has(improvement_id)


func get_core_improvement_ids() -> Array[StringName]:
	var out: Array[StringName] = []
	for key: Variant in _core_defs.keys():
		out.append(key)
	return out


func get_core_improvement_display_name(improvement_id: StringName) -> String:
	var def: Resource = _core_defs.get(improvement_id, null)
	if def == null:
		return str(improvement_id)
	var display := str(def.get("display_name"))
	return display if display != "" else str(improvement_id)


func _effects_of(def: Resource) -> Dictionary:
	var out: Dictionary = {}
	var raw: Variant = def.get("effects")
	if typeof(raw) != TYPE_DICTIONARY:
		return out
	for key: Variant in (raw as Dictionary).keys():
		out[StringName(str(key))] = float((raw as Dictionary)[key])
	return out


# --- Tuning ---------------------------------------------------------------------

func get_base_slots() -> int:
	var tuning := _tuning()
	return maxi(0, int(tuning.base_slots)) if tuning != null else 3


func get_base_capacity() -> int:
	var tuning := _tuning()
	return maxi(0, int(tuning.base_capacity)) if tuning != null else 3


func get_strain_block_per_overcapacity() -> float:
	var tuning := _tuning()
	return maxf(0.0, float(tuning.strain_block_per_overcapacity)) if tuning != null else 15.0


func _tuning() -> Resource:
	var registry := get_tree().root.get_node_or_null("TuningRegistry")
	if registry == null:
		return null
	return registry.get_domain(TUNING_DOMAIN)


# --- Stations (live physical state) ----------------------------------------------

## Called by rig_station.gd when the player body enters its area.
func enter_station(station: Node) -> void:
	if station == null or _stations_in_range.has(station):
		return
	_stations_in_range.append(station)


## Called by rig_station.gd when the player body leaves (or the station
## leaves the tree).
func leave_station(station: Node) -> void:
	_stations_in_range.erase(station)


func get_stations_in_range() -> Array[Node]:
	_stations_in_range = _stations_in_range.filter(func(n: Node) -> bool: return is_instance_valid(n) and n.is_inside_tree())
	return _stations_in_range.duplicate()


## Spec 14's station check: any proper station physically in range.
func can_equip_at_current_location() -> bool:
	return not get_stations_in_range().is_empty()


## Grafting's stricter gate (§67): the private workspace, AND the Mid Reach
## residence tier or better. {"ok": bool, "reason": String}.
func can_graft_at_current_location() -> Dictionary:
	if _workspace_station() == null:
		return {"ok": false, "reason": "not_at_workspace"}
	if residence_tier_rank(get_residence_tier()) < residence_tier_rank(RESIDENCE_MID_REACH):
		return {"ok": false, "reason": "residence_tier_too_low"}
	return {"ok": true, "reason": ""}


func _workspace_station() -> Node:
	for station: Node in get_stations_in_range():
		if _station_kind(station) == STATION_WORKSPACE:
			return station
	return null


func _station_kind(station: Node) -> StringName:
	if station.has_method("get_station_kind"):
		return StringName(str(station.get_station_kind()))
	var raw: Variant = station.get("station_kind")
	return StringName(str(raw)) if raw != null else &""


## The residence tier the player currently holds. Homes (Spec 27) owns
## this; until it exists the answer is the Lower home — the fail-safe
## direction, since it makes grafting refuse rather than silently allow.
func get_residence_tier() -> StringName:
	var homes := get_tree().root.get_node_or_null("Homes")
	if homes == null or not homes.has_method("get_residence_tier"):
		return RESIDENCE_LOWER
	var tier := StringName(str(homes.get_residence_tier()))
	return tier if RESIDENCE_ORDER.has(tier) else RESIDENCE_LOWER


func residence_tier_rank(tier: StringName) -> int:
	return RESIDENCE_ORDER.find(tier)


# --- Slots, Capacity, Strain ------------------------------------------------------

func get_slot_count() -> int:
	var count := get_base_slots()
	for id: StringName in _core:
		var def: Resource = _core_defs.get(id, null)
		if def != null:
			count += int(def.get("slot_bonus"))
	return maxi(0, count)


func get_capacity() -> int:
	var capacity := get_base_capacity()
	for id: StringName in _core:
		var def: Resource = _core_defs.get(id, null)
		if def != null:
			capacity += int(def.get("capacity_bonus"))
	return maxi(0, capacity)


## Everything active draws from the one pool: worn Gear and grafts alike.
func get_capacity_used() -> int:
	var used := 0
	for id: StringName in _slots:
		if id != &"":
			used += get_gear_capacity_cost(id)
	for id: StringName in _grafts:
		used += get_gear_capacity_cost(id)
	return used


func get_overcapacity() -> int:
	return maxi(0, get_capacity_used() - get_capacity())


## The rig_strain block this Rig currently asks Stamina for.
func get_strain_block() -> float:
	return float(get_overcapacity()) * get_strain_block_per_overcapacity()


func _apply_strain() -> void:
	var stamina := get_tree().root.get_node_or_null("Stamina")
	if stamina == null:
		return
	var block := get_strain_block()
	if block > 0.0:
		stamina.request_block(stamina.SOURCE_RIG_STRAIN, block)
	else:
		stamina.release_block(stamina.SOURCE_RIG_STRAIN)


func _ensure_slots() -> void:
	var count := get_slot_count()
	while _slots.size() < count:
		_slots.append(&"")
	while _slots.size() > count:
		_slots.pop_back()


# --- Equipped Gear (worn, slotted) --------------------------------------------------

## Copy of the slot array: index = slot, &"" = empty.
func get_equipped() -> Array[StringName]:
	_ensure_slots()
	return _slots.duplicate()


func get_equipped_in_slot(slot: int) -> StringName:
	_ensure_slots()
	if slot < 0 or slot >= _slots.size():
		return &""
	return _slots[slot]


func is_equipped(gear_id: StringName) -> bool:
	return _slots.has(gear_id)


## Fits owned Gear to a slot. Refused — false, no mutation, with a reason —
## away from a station (Spec 14 option A: enforced here, not by UI), for
## unknown/unowned Gear, for a graft design (grafts don't use slots), for
## a bad or occupied slot, or if it's already equipped elsewhere. Beyond
## Capacity it still SUCCEEDS and Rig Strain rises (soft limit, §35).
## Result shape matches Terrain.dig()/Hauling.cache_at():
## {"success": bool, "reason": String}.
func equip(gear_id: StringName, slot: int) -> Dictionary:
	_ensure_slots()
	if not can_equip_at_current_location():
		return _fail("not_at_station")
	if not is_known_gear(gear_id):
		return _fail("unknown_gear")
	if is_graft_design(gear_id):
		return _fail("grafts_do_not_use_slots")
	if not is_owned(gear_id):
		return _fail("not_owned")
	if slot < 0 or slot >= _slots.size():
		return _fail("no_such_slot")
	if is_equipped(gear_id):
		return _fail("already_equipped")
	if _slots[slot] != &"":
		return _fail("slot_occupied")
	_slots[slot] = gear_id
	_apply_strain()
	_emit_changed(CHANGE_EQUIPPED, gear_id)
	return {"success": true, "reason": ""}


func unequip(slot: int) -> Dictionary:
	_ensure_slots()
	if not can_equip_at_current_location():
		return _fail("not_at_station")
	if slot < 0 or slot >= _slots.size():
		return _fail("no_such_slot")
	var gear_id := _slots[slot]
	if gear_id == &"":
		return _fail("slot_empty")
	_slots[slot] = &""
	_apply_strain()
	_emit_changed(CHANGE_UNEQUIPPED, gear_id)
	return {"success": true, "reason": ""}


# --- Owned Gear -------------------------------------------------------------------

## The owned-but-not-necessarily-equipped list. Spec 23's Orders add here
## on a successful order ("acquires ownership; does not auto-equip").
## Ownership isn't a refit, so no station is needed. Grafts are never
## "owned" as loose items — they're fabricated and installed in one
## workspace act (graft()).
func add_owned_gear(gear_id: StringName) -> bool:
	if not is_known_gear(gear_id) or is_graft_design(gear_id) or is_owned(gear_id):
		return false
	_owned.append(gear_id)
	_emit_changed(CHANGE_OWNED, gear_id)
	return true


func is_owned(gear_id: StringName) -> bool:
	return _owned.has(gear_id)


func get_owned_gear() -> Array[StringName]:
	return _owned.duplicate()


# --- Grafts (Forbidden Gear, §67) ---------------------------------------------------

func get_grafts() -> Array[StringName]:
	return _grafts.duplicate()


func is_grafted(design_id: StringName) -> bool:
	return _grafts.has(design_id)


## Installs a graft. Refused away from the private workspace or below the
## Mid Reach residence tier (§67), for an unknown id, for a non-graft
## definition, or if already installed. Uses no slot; draws Capacity;
## over Capacity still succeeds and creates Rig Strain — "nothing new is
## added to how Capacity or Strain work." Whether its recipe was paid is
## the caller's (Spec 28's) gate before calling this.
func graft(design_id: StringName) -> Dictionary:
	var check := can_graft_at_current_location()
	if not bool(check["ok"]):
		return _fail(str(check["reason"]))
	if not is_known_gear(design_id):
		return _fail("unknown_gear")
	if not is_graft_design(design_id):
		return _fail("not_a_graft")
	if is_grafted(design_id):
		return _fail("already_grafted")
	_grafts.append(design_id)
	_apply_strain()
	_emit_changed(CHANGE_GRAFTED, design_id)
	return {"success": true, "reason": ""}


## Swapping/removing a graft follows the same workspace rule (§67 "Removal
## and refitting"). The real cost and recovery window of a swap are Spec
## 28's; this is only the state change and its gate.
func remove_graft(design_id: StringName) -> Dictionary:
	var check := can_graft_at_current_location()
	if not bool(check["ok"]):
		return _fail(str(check["reason"]))
	if not is_grafted(design_id):
		return _fail("not_grafted")
	_grafts.erase(design_id)
	_apply_strain()
	_emit_changed(CHANGE_UNGRAFTED, design_id)
	return {"success": true, "reason": ""}


# --- Core Improvements ---------------------------------------------------------------

func get_core_improvements() -> Array[StringName]:
	return _core.duplicate()


func has_core_improvement(improvement_id: StringName) -> bool:
	return _core.has(improvement_id)


## A permanent, slot-less baseline improvement (§34). A major Rig change,
## so it happens at a station like everything else. Its source is the
## granting spec's business (G6, mixed).
func install_core_improvement(improvement_id: StringName) -> Dictionary:
	if not can_equip_at_current_location():
		return _fail("not_at_station")
	if not is_known_core_improvement(improvement_id):
		return _fail("unknown_core_improvement")
	if has_core_improvement(improvement_id):
		return _fail("already_installed")
	_core.append(improvement_id)
	_ensure_slots()
	_apply_strain()
	_emit_changed(CHANGE_CORE_INSTALLED, improvement_id)
	return {"success": true, "reason": ""}


# --- Effects ------------------------------------------------------------------------

## Sum of effect_id across every active piece — equipped Gear and grafts.
## 0.0 when nothing provides it. Consumers own what the number means.
func get_effect_sum(effect_id: StringName) -> float:
	var total := 0.0
	for id: StringName in _slots:
		if id != &"":
			total += _effect_from(id, effect_id)
	for id: StringName in _grafts:
		total += _effect_from(id, effect_id)
	return total


func _effect_from(gear_id: StringName, effect_id: StringName) -> float:
	var def: Resource = _gear_defs.get(gear_id, null)
	if def == null:
		return 0.0
	return float(_effects_of(def).get(effect_id, 0.0))


# --- Internals ----------------------------------------------------------------------

func _fail(reason: String) -> Dictionary:
	return {"success": false, "reason": reason}


func _emit_changed(change: StringName, id: StringName) -> void:
	var bus := get_tree().root.get_node_or_null("EventBus") if is_inside_tree() else null
	if bus != null:
		bus.rig_changed.emit(change, id)


# --- Build Bible Spec 02 uniform SaveLoad contract ------------------------------------

func save_state() -> Dictionary:
	_ensure_slots()
	var slots: Array = []
	for id: StringName in _slots:
		slots.append(str(id))
	return {
		"slots": slots,
		"owned": _to_strings(_owned),
		"grafts": _to_strings(_grafts),
		"core_improvements": _to_strings(_core),
	}


func load_state(data: Dictionary) -> void:
	_core = _known_ids(data.get("core_improvements", []), _core_defs)
	_owned = _known_ids(data.get("owned", []), _gear_defs)
	_grafts = _known_ids(data.get("grafts", []), _gear_defs)
	_slots.clear()
	var raw_slots: Variant = data.get("slots", [])
	if typeof(raw_slots) == TYPE_ARRAY:
		for entry: Variant in (raw_slots as Array):
			var id := StringName(str(entry))
			if id != &"" and (not _gear_defs.has(id) or _slots.has(id)):
				push_warning("Rig: dropping unknown/duplicate equipped Gear '%s' from save" % id)
				id = &""
			_slots.append(id)
	_ensure_slots()
	_apply_strain()
	_emit_changed(CHANGE_LOADED, &"")


func reset_all() -> void:
	_slots.clear()
	_owned.clear()
	_grafts.clear()
	_core.clear()
	_ensure_slots()
	_apply_strain()


func _to_strings(ids: Array[StringName]) -> Array:
	var out: Array = []
	for id: StringName in ids:
		out.append(str(id))
	return out


func _known_ids(raw: Variant, defs: Dictionary) -> Array[StringName]:
	var out: Array[StringName] = []
	if typeof(raw) != TYPE_ARRAY:
		return out
	for entry: Variant in (raw as Array):
		var id := StringName(str(entry))
		if id == &"" or out.has(id):
			continue
		if not defs.has(id):
			push_warning("Rig: dropping unknown id '%s' from save" % id)
			continue
		out.append(id)
	return out


# --- Debug -----------------------------------------------------------------------------

func _debug_rig(_args: Array[String]) -> String:
	var lines: PackedStringArray = []
	lines.append("Capacity %d / %d used (overcapacity %d, rig_strain block %.1f)" % [get_capacity_used(), get_capacity(), get_overcapacity(), get_strain_block()])
	var equipped := get_equipped()
	for i in range(equipped.size()):
		lines.append("  slot %d: %s" % [i, equipped[i] if equipped[i] != &"" else &"(empty)"])
	lines.append("Grafts: %s" % [", ".join(PackedStringArray(_grafts)) if not _grafts.is_empty() else "(none)"])
	lines.append("Core Improvements: %s" % [", ".join(PackedStringArray(_core)) if not _core.is_empty() else "(none)"])
	lines.append("Owned: %s" % [", ".join(PackedStringArray(_owned)) if not _owned.is_empty() else "(none)"])
	var stations: PackedStringArray = []
	for station: Node in get_stations_in_range():
		stations.append("%s (%s)" % [station.name, _station_kind(station)])
	lines.append("Stations in range: %s — residence tier %s" % [", ".join(stations) if not stations.is_empty() else "(none)", get_residence_tier()])
	lines.append("Known Gear: %s" % [", ".join(PackedStringArray(get_gear_ids()))])
	return "\n".join(lines)


func _debug_give_gear(args: Array[String]) -> String:
	if args.is_empty():
		return "Usage: give_gear <gear_id>"
	var id := StringName(args[0])
	if not add_owned_gear(id):
		return "Can't own '%s' — unknown, a graft design, or already owned. Known: %s" % [id, ", ".join(PackedStringArray(get_gear_ids()))]
	return "Now own %s" % id


func _debug_equip(args: Array[String]) -> String:
	if args.size() < 2:
		return "Usage: equip <gear_id> <slot>"
	var result := equip(StringName(args[0]), int(args[1]))
	if not bool(result["success"]):
		return "Refused: %s" % result["reason"]
	return "Equipped %s in slot %s (rig_strain block now %.1f)" % [args[0], args[1], get_strain_block()]


func _debug_unequip(args: Array[String]) -> String:
	if args.is_empty():
		return "Usage: unequip <slot>"
	var result := unequip(int(args[0]))
	if not bool(result["success"]):
		return "Refused: %s" % result["reason"]
	return "Slot %s cleared (rig_strain block now %.1f)" % [args[0], get_strain_block()]


func _debug_graft(args: Array[String]) -> String:
	if args.is_empty():
		return "Usage: graft <design_id>"
	var result := graft(StringName(args[0]))
	if not bool(result["success"]):
		return "Refused: %s" % result["reason"]
	return "Grafted %s (rig_strain block now %.1f)" % [args[0], get_strain_block()]


func _debug_install_core(args: Array[String]) -> String:
	if args.is_empty():
		return "Usage: install_core <improvement_id>"
	var result := install_core_improvement(StringName(args[0]))
	if not bool(result["success"]):
		return "Refused: %s" % result["reason"]
	return "Installed %s — slots %d, capacity %d" % [args[0], get_slot_count(), get_capacity()]
