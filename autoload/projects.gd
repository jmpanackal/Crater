extends Node
## Krater Projects (autoload: Projects).
## Build Bible Spec 29 (docs/build-bible/specs/29-projects.md — AI draft
## pending USER review).
##
## Canon §26's two project categories as state. A project needs knowledge
## (a technology Understood, CapabilityWeb), physical resources (Materials
## the player contributes from Storage or straight from the towed bundle)
## and production capacity (the district not in shortage). While it's
## being built the district carries its Demand (a named contributor,
## Spec 22); on completion the lasting effect lands: a permanent Capacity
## contributor (capacity kind) or a smaller maintenance Demand (civic
## kind), a project_completed fact, and the project's story flag (what
## Access/Gates and world dressing key off). The player enables projects;
## nothing here is a construction menu.
##
## Access via get_tree().root.get_node("Projects") (no class_name).

const PROJECTS_DIR := "res://content/projects/"
const KIND_CAPACITY := &"capacity"
const KIND_CIVIC := &"civic"
const STATUS_NOT_STARTED := &"not_started"
const STATUS_IN_PROGRESS := &"in_progress"
const STATUS_COMPLETE := &"complete"
const FACT_PROJECT_COMPLETED := &"project_completed"

var _defs: Dictionary = {}
## project_id -> {"status": StringName, "delivered": {material_id: int}}
var _state: Dictionary = {}


func _ready() -> void:
	reload_definitions()
	var console := get_tree().root.get_node_or_null("DebugConsole")
	if console == null:
		return
	console.register_command("projects", "projects — every project, its status, progress and district.", _debug_projects)
	console.register_command("start_project", "start_project <project_id> — start a project (knowledge + district capacity).", _debug_start)
	console.register_command("contribute", "contribute <project_id> <material_id> <amount> — contribute Materials from Storage.", _debug_contribute)


func reload_definitions() -> void:
	_defs.clear()
	var dir := DirAccess.open(PROJECTS_DIR)
	if dir == null:
		push_warning("Projects: %s does not exist (no projects authored)" % PROJECTS_DIR)
		return
	dir.list_dir_begin()
	var file_name := dir.get_next()
	while file_name != "":
		if not dir.current_is_dir() and file_name.ends_with(".tres"):
			var path := PROJECTS_DIR + file_name
			var res: Resource = ResourceLoader.load(path, "", ResourceLoader.CACHE_MODE_REPLACE)
			if res == null:
				push_warning("Projects: failed to load %s — skipped" % path)
			else:
				var id := StringName(str(res.get("project_id")))
				if id == &"":
					push_warning("Projects: %s has no project_id — skipped" % path)
				else:
					_defs[id] = res
		file_name = dir.get_next()
	dir.list_dir_end()


func is_known_project(project_id: StringName) -> bool:
	return _defs.has(project_id)


func get_project_ids() -> Array[StringName]:
	var names: Array[String] = []
	for key: Variant in _defs.keys():
		names.append(str(key))
	names.sort()
	var out: Array[StringName] = []
	for n: String in names:
		out.append(StringName(n))
	return out


func get_display_name(project_id: StringName) -> String:
	var def: Resource = _defs.get(project_id, null)
	return str(def.get("display_name")) if def != null else str(project_id)


func get_status(project_id: StringName) -> StringName:
	if not _defs.has(project_id):
		return &""
	return StringName(str((_state.get(project_id, {}) as Dictionary).get("status", STATUS_NOT_STARTED)))


## {"required": {material: n}, "delivered": {material: n}, "complete": bool}.
func get_progress(project_id: StringName) -> Dictionary:
	var def: Resource = _defs.get(project_id, null)
	if def == null:
		return {}
	var required: Dictionary = {}
	for key: Variant in (def.get("requires_materials") as Dictionary).keys():
		required[str(key)] = int((def.get("requires_materials") as Dictionary)[key])
	var delivered: Dictionary = ((_state.get(project_id, {}) as Dictionary).get("delivered", {}) as Dictionary).duplicate()
	var complete := true
	for key: Variant in required.keys():
		if int(delivered.get(key, 0)) < int(required[key]):
			complete = false
	return {"required": required, "delivered": delivered, "complete": complete}


# --- Lifecycle -------------------------------------------------------------------------

## {"ok", "reason"}: unknown_project / already_started / already_complete /
## knowledge_missing / district_in_shortage.
func can_start(project_id: StringName) -> Dictionary:
	var def: Resource = _defs.get(project_id, null)
	if def == null:
		return {"ok": false, "reason": "unknown_project"}
	var status := get_status(project_id)
	if status == STATUS_IN_PROGRESS:
		return {"ok": false, "reason": "already_started"}
	if status == STATUS_COMPLETE:
		return {"ok": false, "reason": "already_complete"}
	var tech := StringName(str(def.get("requires_tech")))
	if tech != &"":
		var web := get_tree().root.get_node_or_null("CapabilityWeb")
		if web == null or not bool(web.is_understood(tech)):
			return {"ok": false, "reason": "knowledge_missing"}
	var district := get_tree().root.get_node_or_null("District")
	var district_id := StringName(str(def.get("district_id")))
	if district == null or not bool(district.is_known_district(district_id)):
		return {"ok": false, "reason": "unknown_district"}
	if float(district.get_health(district_id)) < 0.0:
		return {"ok": false, "reason": "district_in_shortage"}
	return {"ok": true, "reason": ""}


## Starts the project: registers its building Demand with the district.
func start(project_id: StringName) -> Dictionary:
	var check := can_start(project_id)
	if not bool(check["ok"]):
		return {"success": false, "reason": str(check["reason"])}
	var def: Resource = _defs[project_id]
	_state[project_id] = {"status": STATUS_IN_PROGRESS, "delivered": {}}
	var district := get_tree().root.get_node_or_null("District")
	var demand := float(def.get("demand_while_building"))
	if demand > 0.0:
		district.register_demand_contributor(StringName(str(def.get("district_id"))), _building_id(project_id), "Building: %s" % get_display_name(project_id), demand)
	var bus := get_tree().root.get_node_or_null("EventBus")
	if bus != null and bus.has_signal("project_changed"):
		bus.project_changed.emit(project_id, STATUS_IN_PROGRESS)
	return {"success": true, "reason": ""}


## Contributes Materials from Storage: takes min(amount, still needed,
## stored). Returns units contributed. Completes the project when the
## last requirement is met.
func contribute(project_id: StringName, material_id: StringName, amount: int) -> int:
	if get_status(project_id) != STATUS_IN_PROGRESS or amount <= 0:
		return 0
	var progress := get_progress(project_id)
	var needed := int((progress["required"] as Dictionary).get(str(material_id), 0)) - int((progress["delivered"] as Dictionary).get(str(material_id), 0))
	if needed <= 0:
		return 0
	var storage := get_tree().root.get_node_or_null("Storage")
	if storage == null:
		return 0
	var take := mini(amount, mini(needed, int(storage.get_material_count(material_id))))
	if take <= 0 or not bool(storage.withdraw_material(material_id, take)):
		return 0
	_deliver(project_id, material_id, take)
	return take


## Contributes the towed bundle (Spec 13) at a worksite: only what the
## project still needs of the bundle's Material; the rest stays in tow.
func contribute_from_bundle(project_id: StringName) -> int:
	var hauling := get_tree().root.get_node_or_null("Hauling")
	if hauling == null or not bool(hauling.is_loaded()) or get_status(project_id) != STATUS_IN_PROGRESS:
		return 0
	var load: Dictionary = hauling.get_load()
	var material_id: StringName = load["material_id"]
	var progress := get_progress(project_id)
	var needed := int((progress["required"] as Dictionary).get(str(material_id), 0)) - int((progress["delivered"] as Dictionary).get(str(material_id), 0))
	if needed <= 0:
		return 0
	var handed: Dictionary = hauling.hand_over_load()
	var amount := int(handed["amount"])
	var used := mini(amount, needed)
	_deliver(project_id, material_id, used)
	# Anything beyond the need goes to Storage rather than vanishing.
	var storage := get_tree().root.get_node_or_null("Storage")
	if amount - used > 0 and storage != null:
		storage.deposit_material(material_id, amount - used)
	return used


func _deliver(project_id: StringName, material_id: StringName, amount: int) -> void:
	var delivered: Dictionary = _state[project_id]["delivered"]
	delivered[str(material_id)] = int(delivered.get(str(material_id), 0)) + amount
	var bus := get_tree().root.get_node_or_null("EventBus")
	if bus != null and bus.has_signal("project_changed"):
		bus.project_changed.emit(project_id, STATUS_IN_PROGRESS)
	if bool(get_progress(project_id)["complete"]):
		_complete(project_id)


func _complete(project_id: StringName) -> void:
	var def: Resource = _defs[project_id]
	var district := get_tree().root.get_node_or_null("District")
	var district_id := StringName(str(def.get("district_id")))
	_state[project_id]["status"] = STATUS_COMPLETE
	if district != null:
		district.unregister_demand_contributor(district_id, _building_id(project_id))
		var kind := StringName(str(def.get("kind")))
		if kind == KIND_CAPACITY and float(def.get("capacity_gain")) > 0.0:
			district.register_capacity_contributor(district_id, "project_%s" % str(project_id), get_display_name(project_id), float(def.get("capacity_gain")), -1)
		elif kind == KIND_CIVIC and float(def.get("maintenance_demand")) > 0.0:
			district.register_demand_contributor(district_id, "maintenance_%s" % str(project_id), "Maintenance: %s" % get_display_name(project_id), float(def.get("maintenance_demand")), -1)
	var flag := StringName(str(def.get("completion_flag")))
	var story := get_tree().root.get_node_or_null("Story")
	if flag != &"" and story != null:
		story.set_flag(flag, "Project completed: %s" % get_display_name(project_id))
	var fact_log := get_tree().root.get_node_or_null("FactLog")
	var clock := get_tree().root.get_node_or_null("Clock")
	if fact_log != null:
		var witnesses: Array[String] = []
		fact_log.record(FACT_PROJECT_COMPLETED, fact_log.SUBJECT_PLAYER, district_id, witnesses, {"project_id": str(project_id), "kind": str(def.get("kind")), "district_id": str(district_id)}, int(clock.get_cycles_elapsed()) if clock != null else -1)
	var bus := get_tree().root.get_node_or_null("EventBus")
	if bus != null:
		if bus.has_signal("project_completed"):
			bus.project_completed.emit(project_id, district_id)
		if bus.has_signal("project_changed"):
			bus.project_changed.emit(project_id, STATUS_COMPLETE)


func _building_id(project_id: StringName) -> String:
	return "building_%s" % str(project_id)


## Re-applies every complete/in-progress project's district contributors
## (District's own save carries them too; this is the belt for a fresh
## District reset).
func reapply_contributors() -> void:
	var district := get_tree().root.get_node_or_null("District")
	if district == null:
		return
	for project_id: StringName in get_project_ids():
		var def: Resource = _defs[project_id]
		var district_id := StringName(str(def.get("district_id")))
		match get_status(project_id):
			STATUS_IN_PROGRESS:
				if float(def.get("demand_while_building")) > 0.0:
					district.register_demand_contributor(district_id, _building_id(project_id), "Building: %s" % get_display_name(project_id), float(def.get("demand_while_building")))
			STATUS_COMPLETE:
				var kind := StringName(str(def.get("kind")))
				if kind == KIND_CAPACITY and float(def.get("capacity_gain")) > 0.0:
					district.register_capacity_contributor(district_id, "project_%s" % str(project_id), get_display_name(project_id), float(def.get("capacity_gain")), -1)
				elif kind == KIND_CIVIC and float(def.get("maintenance_demand")) > 0.0:
					district.register_demand_contributor(district_id, "maintenance_%s" % str(project_id), "Maintenance: %s" % get_display_name(project_id), float(def.get("maintenance_demand")), -1)


# --- Build Bible Spec 02 uniform SaveLoad contract ------------------------------------------

func save_state() -> Dictionary:
	var out: Dictionary = {}
	for key: Variant in _state.keys():
		out[str(key)] = {"status": str(_state[key]["status"]), "delivered": (_state[key]["delivered"] as Dictionary).duplicate()}
	return {"projects": out}


func load_state(data: Dictionary) -> void:
	_state.clear()
	var projects: Variant = data.get("projects", {})
	if typeof(projects) != TYPE_DICTIONARY:
		return
	for key: Variant in (projects as Dictionary).keys():
		var e: Variant = (projects as Dictionary)[key]
		if typeof(e) != TYPE_DICTIONARY or not _defs.has(StringName(str(key))):
			continue
		var delivered: Dictionary = {}
		var raw: Variant = (e as Dictionary).get("delivered", {})
		if typeof(raw) == TYPE_DICTIONARY:
			for m: Variant in (raw as Dictionary).keys():
				delivered[str(m)] = int((raw as Dictionary)[m])
		_state[StringName(str(key))] = {"status": StringName(str((e as Dictionary).get("status", "not_started"))), "delivered": delivered}


func reset_all() -> void:
	_state.clear()


# --- Debug -------------------------------------------------------------------------------------

func _debug_projects(_args: Array[String]) -> String:
	var lines: PackedStringArray = []
	for id: StringName in get_project_ids():
		var p := get_progress(id)
		lines.append("  %s [%s, %s] — %s: %s / %s" % [get_display_name(id), (_defs[id] as Resource).get("kind"), (_defs[id] as Resource).get("district_id"), get_status(id), p["delivered"], p["required"]])
	return "No projects authored." if lines.is_empty() else "\n".join(lines)


func _debug_start(args: Array[String]) -> String:
	if args.is_empty():
		return "Usage: start_project <project_id>"
	var result := start(StringName(args[0]))
	return "Started %s" % args[0] if bool(result["success"]) else "Refused: %s" % result["reason"]


func _debug_contribute(args: Array[String]) -> String:
	if args.size() < 3:
		return "Usage: contribute <project_id> <material_id> <amount>"
	var n := contribute(StringName(args[0]), StringName(args[1]), int(args[2]))
	return "Contributed %d %s — %s" % [n, args[1], get_status(StringName(args[0]))]
