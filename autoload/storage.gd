extends Node
## Krater Materials / Components + Storage (autoload: Storage).
## Build Bible Spec 11 (docs/build-bible/specs/11-materials-storage.md).
##
## The canon owner of the player's stored Materials and Components (the
## dependency map's "Storage" row: personal storage, later concealed
## storage and caches). Everything here follows the spec's confirmed
## choices literally:
##
## - Stored Materials are a plain integer count per locked type (option A)
##   — "abstract stored quantities" once home, no per-batch metadata.
## - ONE unified personal pool reachable from any owned residence (option
##   A). There is deliberately no residence parameter on any method; the
##   world-side access points (storage_access.gd) all route here.
## - Components share the same unified-pool model (option A), but keep
##   per-instance identity (a list, not a count) since a Component "may
##   carry more identity than a bare count, e.g. which specific recovered
##   part."
## - No per-unit ownership tag (option A). Whether a Material was "supposed"
##   to go to a district is resolved by the job/commitment expecting it,
##   which checks current totals via has_materials() at the moment it
##   settles — never a reserved allocation.
## - Records are NOT stored here. Knowledge lives in the Journal (Build
##   Bible: "owned by the Journal/Capability Web systems, not duplicated
##   here") — see journal.gd's has_record()/unlock_record()/get_unlocked_ids().
##
## Material and Component definitions are Content Definitions (Spec 01)
## loaded from res://content/materials/*.tres and
## res://content/components/*.tres, exactly like Zones — the LOCKED Act 1
## roster (Sutral, Ravelstone, Brinecrystal, Verdigris, Hullbit) is data,
## and a retired name (Sporemeal, Lampwick, ...) is simply unknown here and
## rejected. The retired Salvage-wallet prototype (resources.gd) is still
## present and still owns the retired mechanics (dig-to-wallet, named
## district goods, Tallies) until Specs 12/13/22/23 migrate each of those;
## this system does not reach into it.
##
## Access via get_tree().root.get_node("Storage") (no class_name, matching
## the existing project convention — see resources.gd).

const MATERIALS_DIR := "res://content/materials/"
const COMPONENTS_DIR := "res://content/components/"

const KIND_MATERIAL := &"material"
const KIND_COMPONENT := &"component"

## Locked Act 1 roster ids, for callers that want a constant rather than a
## string literal. The definitions themselves still come from content.
const SUTRAL := &"sutral"
const RAVELSTONE := &"ravelstone"
const BRINECRYSTAL := &"brinecrystal"
const VERDIGRIS := &"verdigris"
const HULLBIT := &"hullbit"

var _material_defs: Dictionary = {}  # StringName -> Resource (MaterialDefinition)
var _component_defs: Dictionary = {}  # StringName -> Resource (ComponentDefinition)

var _materials: Dictionary = {}  # StringName -> int
## Each entry: {"uid": int, "id": StringName, "data": Dictionary}.
var _components: Array[Dictionary] = []
var _next_component_uid: int = 1


func _ready() -> void:
	reload_definitions()
	var console := get_tree().root.get_node_or_null("DebugConsole")
	if console == null:
		return
	console.register_command(
		"add_component",
		"add_component <id> — add one Component instance to personal storage.",
		_debug_add_component
	)
	console.register_command(
		"remove_component",
		"remove_component <uid> — remove a Component instance by its uid.",
		_debug_remove_component
	)


## Re-scans both content directories. Safe to call at any time; a file that
## fails to load is skipped with a warning rather than aborting, matching
## the resilience rule TuningRegistry and Zones already follow. Stored
## counts are untouched — only the definitions refresh.
func reload_definitions() -> void:
	_material_defs = _load_definitions(MATERIALS_DIR, "material_id")
	_component_defs = _load_definitions(COMPONENTS_DIR, "component_id")


func _load_definitions(dir_path: String, id_property: String) -> Dictionary:
	var out: Dictionary = {}
	var dir := DirAccess.open(dir_path)
	if dir == null:
		push_warning("Storage: %s does not exist (no definitions authored)" % dir_path)
		return out
	dir.list_dir_begin()
	var file_name := dir.get_next()
	while file_name != "":
		if not dir.current_is_dir() and file_name.ends_with(".tres"):
			var path := dir_path + file_name
			var res: Resource = ResourceLoader.load(path, "", ResourceLoader.CACHE_MODE_REPLACE)
			if res == null:
				push_warning("Storage: failed to load %s — skipped" % path)
			else:
				var id := StringName(str(res.get(id_property)))
				if id == &"":
					push_warning("Storage: %s has no %s set — skipped" % [path, id_property])
				else:
					out[id] = res
		file_name = dir.get_next()
	dir.list_dir_end()
	return out


# --- Materials ---------------------------------------------------------------

func is_known_material(material_id: StringName) -> bool:
	return _material_defs.has(material_id)


func get_material_ids() -> Array[StringName]:
	var out: Array[StringName] = []
	for key: Variant in _material_defs.keys():
		out.append(key)
	return out


func get_material_display_name(material_id: StringName) -> String:
	var def: Resource = _material_defs.get(material_id, null)
	if def == null:
		return str(material_id)
	var display := str(def.get("display_name"))
	return display if display != "" else str(material_id)


func get_material_count(material_id: StringName) -> int:
	return int(_materials.get(material_id, 0))


## Adds `amount` of a known Material to the unified pool. This is the moment
## a physical haul (Spec 13) becomes an abstract count — the whole
## conversion is this one integer add, so there is nothing to lose.
## Refuses cleanly (false, no mutation) for an unknown/retired id or a
## non-positive amount.
func deposit_material(material_id: StringName, amount: int) -> bool:
	if amount <= 0 or not is_known_material(material_id):
		return false
	var next := get_material_count(material_id) + amount
	_materials[material_id] = next
	_emit_changed(KIND_MATERIAL, material_id, next)
	return true


## Removes exactly `amount` (all or nothing — never a partial withdrawal, so
## a count can never go negative and a caller never has to reconcile a
## half-filled request). False if the pool doesn't hold that much.
func withdraw_material(material_id: StringName, amount: int) -> bool:
	if amount <= 0 or not has_materials(material_id, amount):
		return false
	var next := get_material_count(material_id) - amount
	if next == 0:
		_materials.erase(material_id)
	else:
		_materials[material_id] = next
	_emit_changed(KIND_MATERIAL, material_id, next)
	return true


## The check a job/commitment makes when it settles ("expects 5 Ravelstone"):
## current total against the requirement, right now. Deliberately NOT a
## reservation — two jobs each expecting 5 both see 5 as satisfied until
## one of them actually withdraws (Spec 11's own failure/edge-case rule).
func has_materials(material_id: StringName, amount: int) -> bool:
	return get_material_count(material_id) >= amount


func get_materials_snapshot() -> Dictionary:
	var out: Dictionary = {}
	for key: Variant in _materials.keys():
		out[str(key)] = int(_materials[key])
	return out


# --- Components --------------------------------------------------------------

func is_known_component(component_id: StringName) -> bool:
	return _component_defs.has(component_id)


func get_component_ids() -> Array[StringName]:
	var out: Array[StringName] = []
	for key: Variant in _component_defs.keys():
		out.append(key)
	return out


func get_component_display_name(component_id: StringName) -> String:
	var def: Resource = _component_defs.get(component_id, null)
	if def == null:
		return str(component_id)
	var display := str(def.get("display_name"))
	return display if display != "" else str(component_id)


## One authored field of a Component definition (e.g. "seal_tier" for
## Build Bible Spec 18), or `default` if unknown. Reads only — the
## definition itself is never handed out.
func get_component_field(component_id: StringName, field: String, default: Variant = null) -> Variant:
	var def: Resource = _component_defs.get(component_id, null)
	if def == null:
		return default
	var value: Variant = def.get(field)
	return default if value == null else value


## Adds one instance of a known Component, with optional per-instance data
## (which specific recovered part, condition, provenance — whatever a later
## system wants to hang on it). Returns the instance's stable uid, or -1 for
## an unknown id (no mutation).
func add_component(component_id: StringName, data: Dictionary = {}) -> int:
	if not is_known_component(component_id):
		return -1
	var uid := _next_component_uid
	_next_component_uid += 1
	_components.append({"uid": uid, "id": component_id, "data": data.duplicate(true)})
	_emit_changed(KIND_COMPONENT, component_id, count_components(component_id))
	return uid


func remove_component(uid: int) -> bool:
	for i in range(_components.size()):
		if int(_components[i]["uid"]) == uid:
			var component_id: StringName = _components[i]["id"]
			_components.remove_at(i)
			_emit_changed(KIND_COMPONENT, component_id, count_components(component_id))
			return true
	return false


func has_component(component_id: StringName) -> bool:
	return count_components(component_id) > 0


func count_components(component_id: StringName) -> int:
	var n := 0
	for entry: Dictionary in _components:
		if entry["id"] == component_id:
			n += 1
	return n


## Copies of the owned instances (all of them, or only those of one id).
## Copies, so a caller can't reach in and edit an instance's data without
## going through this owner — Spec 01's "reads are open, writes are not".
func get_components(component_id: StringName = &"") -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	for entry: Dictionary in _components:
		if component_id == &"" or entry["id"] == component_id:
			out.append(entry.duplicate(true))
	return out


# --- Concealed storage (Build Bible Spec 26) ------------------------------------
## Diverted District Output stashed at the player's concealed workspace,
## integer units per district (canon §47/§62: accumulates across cycles
## toward a Forbidden build; larger stockpiles are stronger evidence if
## found — Spec 27 reads this on a residence search). Capacity is
## canon-OPEN, so none is enforced yet.

var _concealed: Dictionary = {}  # district_id -> int


func deposit_concealed(district_id: StringName, amount: int) -> bool:
	if amount <= 0 or district_id == &"":
		return false
	_concealed[district_id] = get_concealed(district_id) + amount
	_emit_changed(&"concealed", district_id, get_concealed(district_id))
	return true


## All-or-nothing, like withdraw_material.
func withdraw_concealed(district_id: StringName, amount: int) -> bool:
	if amount <= 0 or get_concealed(district_id) < amount:
		return false
	var next := get_concealed(district_id) - amount
	if next == 0:
		_concealed.erase(district_id)
	else:
		_concealed[district_id] = next
	_emit_changed(&"concealed", district_id, next)
	return true


func get_concealed(district_id: StringName) -> int:
	return int(_concealed.get(district_id, 0))


func get_concealed_total() -> int:
	var total := 0
	for key: Variant in _concealed.keys():
		total += int(_concealed[key])
	return total


func get_concealed_snapshot() -> Dictionary:
	var out: Dictionary = {}
	for key: Variant in _concealed.keys():
		out[str(key)] = int(_concealed[key])
	return out


## Confiscation (a residence search that found the stockpile, Spec 27):
## everything concealed is gone. Returns what was taken.
func clear_concealed() -> Dictionary:
	var taken := get_concealed_snapshot()
	_concealed.clear()
	for key: Variant in taken.keys():
		_emit_changed(&"concealed", StringName(str(key)), 0)
	return taken


# --- Cross-cutting ------------------------------------------------------------

func _emit_changed(kind: StringName, id: StringName, new_count: int) -> void:
	var bus := get_tree().root.get_node_or_null("EventBus") if is_inside_tree() else null
	if bus != null:
		bus.storage_changed.emit(kind, id, new_count)


## Build Bible Spec 02 uniform SaveLoad contract.
func save_state() -> Dictionary:
	var components: Array = []
	for entry: Dictionary in _components:
		components.append({
			"uid": int(entry["uid"]),
			"id": str(entry["id"]),
			"data": (entry["data"] as Dictionary).duplicate(true),
		})
	return {
		"materials": get_materials_snapshot(),
		"components": components,
		"next_component_uid": _next_component_uid,
		"concealed": get_concealed_snapshot(),
	}


func load_state(data: Dictionary) -> void:
	_materials.clear()
	var materials: Variant = data.get("materials", {})
	if typeof(materials) == TYPE_DICTIONARY:
		for key: Variant in (materials as Dictionary).keys():
			var amount := int((materials as Dictionary)[key])
			if amount > 0:
				_materials[StringName(str(key))] = amount
	_components.clear()
	var components: Variant = data.get("components", [])
	if typeof(components) == TYPE_ARRAY:
		for entry: Variant in (components as Array):
			if typeof(entry) != TYPE_DICTIONARY:
				continue
			var e: Dictionary = entry
			var inst_data: Variant = e.get("data", {})
			_components.append({
				"uid": int(e.get("uid", 0)),
				"id": StringName(str(e.get("id", ""))),
				"data": (inst_data as Dictionary).duplicate(true) if typeof(inst_data) == TYPE_DICTIONARY else {},
			})
	# Never hand out a uid that a loaded instance already holds.
	var highest := 0
	for entry: Dictionary in _components:
		highest = maxi(highest, int(entry["uid"]))
	_next_component_uid = maxi(int(data.get("next_component_uid", 1)), highest + 1)
	_concealed.clear()
	var concealed: Variant = data.get("concealed", {})
	if typeof(concealed) == TYPE_DICTIONARY:
		for key: Variant in (concealed as Dictionary).keys():
			var amount := int((concealed as Dictionary)[key])
			if amount > 0:
				_concealed[StringName(str(key))] = amount


func reset_all() -> void:
	_materials.clear()
	_components.clear()
	_next_component_uid = 1
	_concealed.clear()


func _debug_add_component(args: Array[String]) -> String:
	if args.is_empty():
		return "Usage: add_component <id>"
	var component_id := StringName(args[0])
	var uid := add_component(component_id)
	if uid < 0:
		return "Unknown Component '%s' — known: %s" % [args[0], ", ".join(PackedStringArray(get_component_ids()))]
	return "Added %s (uid %d) — now %d owned" % [component_id, uid, count_components(component_id)]


func _debug_remove_component(args: Array[String]) -> String:
	if args.is_empty():
		return "Usage: remove_component <uid>"
	var uid := int(args[0])
	if not remove_component(uid):
		return "No Component instance with uid %d" % uid
	return "Removed Component instance %d" % uid
