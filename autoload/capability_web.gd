extends Node
## Krater Capability Web (autoload: CapabilityWeb).
## Build Bible Spec 25 (docs/build-bible/specs/25-capability-web.md).
##
## Canon §40's discovered capability web — Known -> Understood ->
## Available — instead of a visible tech tree, and §41's steerable
## progression through leads. Thin slice.
##
## Confirmed choices, implemented literally:
## - Known/Understood are set ONLY through submitted discovery events
##   (option A): submit_discovery(tech_id, level, source_context). This
##   system never decides on its own that something became Known. The
##   real sources are wired to those events — a Record read (Journal), a
##   Component recovered (Storage), Gear owned (Rig) — as declared on each
##   technology's own definition, so "never without an in-world reason"
##   holds structurally. One-directional: nothing un-discovers; a repeat
##   or lower-level event is a harmless no-op.
## - Available is computed live on every query, never cached (option A):
##   is_available() re-checks the current Material/Component/Tallies/
##   access/district conditions each time. Spend the Material and the next
##   query reads false again.
## - Families are tags on the technology's definition (option A); a tech
##   carries several at once. get_leads(family) is the steering surface:
##   what's Known in that family and what each still needs.
##
## Openly sanctioned Approved Gear starts Known + Understood (the public
## catalog, canon §28) and its Availability IS Orders.can_order() — one
## source of truth for order terms. Forbidden designs start unknown; their
## requirements (Material / Component / Record / residence) are authored
## here; the diverted-output cost and the build itself are Spec 28's.
##
## Owns only the per-technology level flags (authoritative). Records stay
## the Journal's; nothing here duplicates them.
##
## Access via get_tree().root.get_node("CapabilityWeb") (no class_name,
## matching the existing project convention — see resources.gd).

const TECH_DIR := "res://content/technologies/"

const LEVEL_KNOWN := &"known"
const LEVEL_UNDERSTOOD := &"understood"
const LEVEL_RANK := {&"": 0, &"known": 1, &"understood": 2}

const KIND_APPROVED_GEAR := &"approved_gear"
const KIND_FORBIDDEN_DESIGN := &"forbidden_design"
const KIND_CORE_IMPROVEMENT := &"core_improvement"

const FAMILY_EXCAVATION := &"excavation"
const FAMILY_SURVEY := &"survey"
const FAMILY_HAULING := &"hauling"
const FAMILY_MOBILITY := &"mobility"
const FAMILY_LIGHT := &"light"
const FAMILY_SECRECY := &"secrecy"
const FAMILY_RIG_CORE := &"rig_core"
const FAMILIES: Array[StringName] = [FAMILY_EXCAVATION, FAMILY_SURVEY, FAMILY_HAULING, FAMILY_MOBILITY, FAMILY_LIGHT, FAMILY_SECRECY, FAMILY_RIG_CORE]

const FACT_DISCOVERY := &"discovery"

var _defs: Dictionary = {}  # tech_id -> Resource
var _levels: Dictionary = {}  # tech_id -> StringName level (&"" = nothing)


func _ready() -> void:
	reload_definitions()
	_apply_starting_levels()
	var bus := get_tree().root.get_node_or_null("EventBus")
	if bus != null:
		if not bus.storage_changed.is_connected(_on_storage_changed):
			bus.storage_changed.connect(_on_storage_changed)
		if bus.has_signal("rig_changed") and not bus.rig_changed.is_connected(_on_rig_changed):
			bus.rig_changed.connect(_on_rig_changed)
	var journal := get_tree().root.get_node_or_null("Journal")
	if journal != null and journal.has_signal("record_unlocked") and not journal.record_unlocked.is_connected(_on_record_unlocked):
		journal.record_unlocked.connect(_on_record_unlocked)
	var console := get_tree().root.get_node_or_null("DebugConsole")
	if console == null:
		return
	console.register_command("web", "web [family] — every technology's Known/Understood/Available and what's missing (optionally one family).", _debug_web)
	console.register_command("discover", "discover <tech_id> <known|understood> — submit a discovery event.", _debug_discover)


# --- Content ---------------------------------------------------------------------------

func reload_definitions() -> void:
	_defs.clear()
	var dir := DirAccess.open(TECH_DIR)
	if dir == null:
		push_warning("CapabilityWeb: %s does not exist (no technologies authored)" % TECH_DIR)
		return
	dir.list_dir_begin()
	var file_name := dir.get_next()
	while file_name != "":
		if not dir.current_is_dir() and file_name.ends_with(".tres"):
			var path := TECH_DIR + file_name
			var res: Resource = ResourceLoader.load(path, "", ResourceLoader.CACHE_MODE_REPLACE)
			if res == null:
				push_warning("CapabilityWeb: failed to load %s — skipped" % path)
			else:
				var id := StringName(str(res.get("tech_id")))
				if id == &"":
					push_warning("CapabilityWeb: %s has no tech_id — skipped" % path)
				else:
					_defs[id] = res
		file_name = dir.get_next()
	dir.list_dir_end()


## The public catalog: sanctioned technology that starts Known/Understood.
func _apply_starting_levels() -> void:
	for id: StringName in get_tech_ids():
		var def: Resource = _defs[id]
		if bool(def.get("starts_understood")):
			_raise(id, LEVEL_UNDERSTOOD)
		elif bool(def.get("starts_known")):
			_raise(id, LEVEL_KNOWN)


func is_known_tech(tech_id: StringName) -> bool:
	return _defs.has(tech_id)


func get_tech_ids() -> Array[StringName]:
	var names: Array[String] = []
	for key: Variant in _defs.keys():
		names.append(str(key))
	names.sort()
	var out: Array[StringName] = []
	for n: String in names:
		out.append(StringName(n))
	return out


func get_display_name(tech_id: StringName) -> String:
	var def: Resource = _defs.get(tech_id, null)
	if def == null:
		return str(tech_id)
	var display := str(def.get("display_name"))
	return display if display != "" else str(tech_id)


func get_kind(tech_id: StringName) -> StringName:
	var def: Resource = _defs.get(tech_id, null)
	return StringName(str(def.get("kind"))) if def != null else &""


## The authored build/order requirements, as data (Spec 28's build
## consumes exactly these): {"materials": {id: n}, "components": [ids],
## "diverted_output": {district: n}, "tallies": int, "residence", "trust"}.
func get_requirements(tech_id: StringName) -> Dictionary:
	var def: Resource = _defs.get(tech_id, null)
	if def == null:
		return {}
	var materials: Dictionary = {}
	for key: Variant in (def.get("requires_materials") as Dictionary).keys():
		materials[StringName(str(key))] = int((def.get("requires_materials") as Dictionary)[key])
	var components: Array = []
	for c: Variant in (def.get("requires_components") as Array):
		components.append(StringName(str(c)))
	var diverted: Dictionary = {}
	var raw_div: Variant = def.get("requires_diverted_output")
	if typeof(raw_div) == TYPE_DICTIONARY:
		for key: Variant in (raw_div as Dictionary).keys():
			diverted[StringName(str(key))] = int((raw_div as Dictionary)[key])
	return {
		"materials": materials, "components": components, "diverted_output": diverted,
		"tallies": int(def.get("requires_tallies")),
		"residence": StringName(str(def.get("requires_residence"))),
		"trust": StringName(str(def.get("requires_trust"))),
	}


## All family tags on the technology (several at once is normal).
func get_families(tech_id: StringName) -> Array[StringName]:
	var out: Array[StringName] = []
	var def: Resource = _defs.get(tech_id, null)
	if def == null:
		return out
	for f: Variant in (def.get("families") as Array):
		out.append(StringName(str(f)))
	return out


# --- Discovery (the only way Known/Understood move) ------------------------------------

## Raises tech_id to `level` (LEVEL_KNOWN / LEVEL_UNDERSTOOD) because the
## calling system says something in-world justified it. Records a
## `discovery` fact with the source context. Returns whether the level
## actually rose (false for unknown tech, an unknown level, or a level
## already reached — one-directional, harmless no-op).
func submit_discovery(tech_id: StringName, level: StringName, source_context: Dictionary = {}) -> bool:
	if not is_known_tech(tech_id) or not LEVEL_RANK.has(level) or level == &"":
		return false
	if not _raise(tech_id, level):
		return false
	var fact_log := get_tree().root.get_node_or_null("FactLog")
	var clock := get_tree().root.get_node_or_null("Clock")
	if fact_log != null:
		var witnesses: Array[String] = []
		var ctx := source_context.duplicate(true)
		ctx["tech_id"] = str(tech_id)
		ctx["level"] = str(level)
		fact_log.record(FACT_DISCOVERY, fact_log.SUBJECT_PLAYER, StringName(), witnesses, ctx, int(clock.get_cycles_elapsed()) if clock != null else -1)
	var bus := get_tree().root.get_node_or_null("EventBus")
	if bus != null and bus.has_signal("technology_discovered"):
		bus.technology_discovered.emit(tech_id, level)
	return true


func _raise(tech_id: StringName, level: StringName) -> bool:
	var current: StringName = _levels.get(tech_id, &"")
	if int(LEVEL_RANK[level]) <= int(LEVEL_RANK[current]):
		return false
	_levels[tech_id] = level
	return true


func get_level(tech_id: StringName) -> StringName:
	return _levels.get(tech_id, &"")


func is_tech_known(tech_id: StringName) -> bool:
	return int(LEVEL_RANK[get_level(tech_id)]) >= 1


func is_understood(tech_id: StringName) -> bool:
	return int(LEVEL_RANK[get_level(tech_id)]) >= 2


# --- Available (derived, live) ---------------------------------------------------------

## {"known", "understood", "available", "missing": [human-readable]} —
## `available` and `missing` recomputed on every call.
func get_state(tech_id: StringName) -> Dictionary:
	var missing := get_missing(tech_id)
	return {
		"known": is_tech_known(tech_id),
		"understood": is_understood(tech_id),
		"available": is_tech_known(tech_id) and is_understood(tech_id) and missing.is_empty(),
		"missing": missing,
	}


func is_available(tech_id: StringName) -> bool:
	return bool(get_state(tech_id)["available"])


## What still stands between the player and ordering/building this —
## the "what is missing" line canon §42 asks a Discoveries entry to
## explain. [] when every condition is met right now. Knowledge gaps are
## listed too, so a Known-but-not-Understood lead explains itself.
func get_missing(tech_id: StringName) -> Array[String]:
	var missing: Array[String] = []
	var def: Resource = _defs.get(tech_id, null)
	if def == null:
		return ["unknown technology"]
	if not is_tech_known(tech_id):
		missing.append("no reason to know this exists")
		return missing
	if not is_understood(tech_id):
		missing.append("not understood — a Record or someone who knows the procedure")
	var kind := get_kind(tech_id)
	var gear_id := StringName(str(def.get("gear_id")))
	if kind == KIND_APPROVED_GEAR:
		_missing_for_order(gear_id, missing)
	else:
		_missing_requirements(def, missing)
		if kind == KIND_CORE_IMPROVEMENT:
			var rig := get_tree().root.get_node_or_null("Rig")
			if rig != null and gear_id != &"" and bool(rig.has_core_improvement(gear_id)):
				return []  # already installed — nothing missing
	return missing


func _missing_for_order(gear_id: StringName, missing: Array[String]) -> void:
	var orders := get_tree().root.get_node_or_null("Orders")
	var rig := get_tree().root.get_node_or_null("Rig")
	if orders == null or rig == null or gear_id == &"":
		missing.append("no order terms")
		return
	if bool(rig.is_owned(gear_id)):
		return  # already owned: nothing missing
	var check: Dictionary = orders.can_order(gear_id)
	if bool(check["ok"]):
		return
	match str(check["reason"]):
		"insufficient_tallies":
			missing.append("Tallies (%d)" % int(orders.get_order_terms(gear_id).get("tallies", 0)))
		"insufficient_district_output":
			missing.append("%s output (%.0f)" % [orders.get_order_terms(gear_id).get("district", ""), float(orders.get_order_terms(gear_id).get("output", 0.0))])
		"district_refused_for_demand":
			missing.append("%s is holding its output for essential demand" % orders.get_order_terms(gear_id).get("district", ""))
		"trust_too_low":
			missing.append("standing (%s)" % orders.get_order_terms(gear_id).get("min_trust", ""))
		_:
			missing.append(str(check["reason"]))


func _missing_requirements(def: Resource, missing: Array[String]) -> void:
	var storage := get_tree().root.get_node_or_null("Storage")
	var wallet := get_tree().root.get_node_or_null("Wallet")
	var trust := get_tree().root.get_node_or_null("Trust")
	var rig := get_tree().root.get_node_or_null("Rig")
	var materials: Dictionary = def.get("requires_materials")
	for key: Variant in materials.keys():
		var id := StringName(str(key))
		var amount := int(materials[key])
		if storage == null or not bool(storage.has_materials(id, amount)):
			missing.append("%s ×%d" % [storage.get_material_display_name(id) if storage != null else str(id), amount])
	for c: Variant in (def.get("requires_components") as Array):
		var cid := StringName(str(c))
		if storage == null or not bool(storage.has_component(cid)):
			missing.append(str(storage.get_component_display_name(cid)) if storage != null else str(cid))
	var tallies := int(def.get("requires_tallies"))
	if tallies > 0 and (wallet == null or not bool(wallet.can_afford(tallies))):
		missing.append("Tallies (%d)" % tallies)
	# Build Bible Spec 28: diverted District Output stashed in the concealed
	# workspace (Spec 26) is the base cost of every Forbidden item.
	var diverted: Variant = def.get("requires_diverted_output")
	if typeof(diverted) == TYPE_DICTIONARY:
		for key: Variant in (diverted as Dictionary).keys():
			var units := int((diverted as Dictionary)[key])
			if units > 0 and (storage == null or not storage.has_method("get_concealed") or int(storage.get_concealed(StringName(str(key)))) < units):
				missing.append("diverted %s output ×%d" % [str(key), units])
	var residence := StringName(str(def.get("requires_residence")))
	if residence != &"" and rig != null:
		if int(rig.residence_tier_rank(rig.get_residence_tier())) < int(rig.residence_tier_rank(residence)):
			missing.append("residence (%s)" % residence)
	var standing := StringName(str(def.get("requires_trust")))
	if standing != &"" and trust != null and not _standing_at_least(trust, standing):
		missing.append("standing (%s)" % standing)


func _standing_at_least(trust: Node, needed: StringName) -> bool:
	var ladder: Array[Dictionary] = trust.get_standing_ladder()
	var current: StringName = trust.get_trust()
	var current_rank := -1
	var needed_rank := -1
	for i in range(ladder.size()):
		if ladder[i]["id"] == current:
			current_rank = i
		if ladder[i]["id"] == needed:
			needed_rank = i
	return needed_rank < 0 or current_rank >= needed_rank


# --- Steering (canon §41) -----------------------------------------------------------------

## Known technologies in a family with what each still needs — the
## meaningful leads a player pursuing that direction can act on. Unknown
## technology never appears (no greyed-out mystery list).
func get_leads(family: StringName) -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	for id: StringName in get_tech_ids():
		if not is_tech_known(id) or not get_families(id).has(family):
			continue
		var state := get_state(id)
		out.append({"tech_id": id, "display_name": get_display_name(id), "kind": get_kind(id), "understood": state["understood"], "available": state["available"], "missing": state["missing"]})
	return out


## Every Known technology (what a Discoveries surface may list).
func get_known_tech_ids() -> Array[StringName]:
	var out: Array[StringName] = []
	for id: StringName in get_tech_ids():
		if is_tech_known(id):
			out.append(id)
	return out


# --- Wired discovery sources ---------------------------------------------------------------

func _on_record_unlocked(record_id: StringName) -> void:
	for id: StringName in get_tech_ids():
		var def: Resource = _defs[id]
		if (def.get("understood_from_records") as Array).has(record_id):
			submit_discovery(id, LEVEL_UNDERSTOOD, {"source": "record", "record_id": str(record_id)})
		elif (def.get("known_from_records") as Array).has(record_id):
			submit_discovery(id, LEVEL_KNOWN, {"source": "record", "record_id": str(record_id)})


func _on_storage_changed(kind: StringName, id: StringName, new_count: int) -> void:
	if kind != &"component" or new_count <= 0:
		return
	for tech_id: StringName in get_tech_ids():
		var def: Resource = _defs[tech_id]
		if (def.get("known_from_components") as Array).has(id):
			submit_discovery(tech_id, LEVEL_KNOWN, {"source": "component", "component_id": str(id)})


## Owning a piece of Gear is understanding it.
func _on_rig_changed(change: StringName, gear_id: StringName) -> void:
	if change != &"owned" and change != &"grafted" and change != &"core_installed":
		return
	for tech_id: StringName in get_tech_ids():
		if StringName(str((_defs[tech_id] as Resource).get("gear_id"))) == gear_id:
			submit_discovery(tech_id, LEVEL_UNDERSTOOD, {"source": "gear", "change": str(change)})


# --- Build Bible Spec 02 uniform SaveLoad contract ----------------------------------------------

func save_state() -> Dictionary:
	var out: Dictionary = {}
	for key: Variant in _levels.keys():
		out[str(key)] = str(_levels[key])
	return {"levels": out}


func load_state(data: Dictionary) -> void:
	_levels.clear()
	_apply_starting_levels()
	var levels: Variant = data.get("levels", {})
	if typeof(levels) != TYPE_DICTIONARY:
		return
	for key: Variant in (levels as Dictionary).keys():
		var id := StringName(str(key))
		var level := StringName(str((levels as Dictionary)[key]))
		if is_known_tech(id) and LEVEL_RANK.has(level):
			_raise(id, level)


func reset_all() -> void:
	_levels.clear()
	_apply_starting_levels()


# --- Debug ----------------------------------------------------------------------------------------

func _debug_web(args: Array[String]) -> String:
	var family := StringName(args[0].to_lower()) if not args.is_empty() else &""
	var lines: PackedStringArray = []
	for id: StringName in get_tech_ids():
		if family != &"" and not get_families(id).has(family):
			continue
		var state := get_state(id)
		var status := "unknown"
		if bool(state["available"]):
			status = "AVAILABLE"
		elif bool(state["understood"]):
			status = "understood"
		elif bool(state["known"]):
			status = "known"
		lines.append("  %s [%s | %s] — %s%s" % [
			get_display_name(id), get_kind(id), ", ".join(PackedStringArray(get_families(id))), status,
			"" if (state["missing"] as Array).is_empty() or not bool(state["known"]) else " — missing: " + ", ".join(PackedStringArray(state["missing"])),
		])
	return "No technologies." if lines.is_empty() else "\n".join(lines)


func _debug_discover(args: Array[String]) -> String:
	if args.size() < 2:
		return "Usage: discover <tech_id> <known|understood>"
	var ok := submit_discovery(StringName(args[0]), StringName(args[1].to_lower()), {"source": "debug"})
	return "%s is now %s" % [args[0], get_level(StringName(args[0]))] if ok else "No change (unknown tech/level, or already there)"
