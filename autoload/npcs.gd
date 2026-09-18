extends Node
## Krater NPC Agents + Schedules (autoload: Npcs).
## Build Bible Spec 16 (docs/build-bible/specs/16-npc-agents.md).
##
## NPCs that live somewhere specific depending on the civic phase, whether
## or not the player is nearby to see it — G14 (locked option A) as an
## actual system:
## - Each NPC has a schedule: one ZONE per civic phase (Spec 16, confirmed
##   option A: named zones, never coordinates). Definitions are Content
##   (content/npc_definition.gd -> content/npcs/*.tres).
## - Off-screen, an NPC "is" at its scheduled zone with no physics: the
##   schedule is pure data, so get_scheduled_npcs_at(zone, phase) answers
##   correctly for a zone that was never loaded.
## - A loaded NPC body (hollow_npc.gd, which registers here) is placed at
##   one of its scheduled zone's marked idle points whenever the phase
##   changes; if that zone isn't loaded (Zones.is_zone_loaded), the body is
##   made absent (hidden, not interactable) — it's elsewhere. Perception
##   (Spec 17) asks get_loaded_agents(): only present bodies can witness.
##
## Owns no authoritative state: the schedule is data and an NPC's current
## zone is derived from the Clock's phase, so save_state() is empty.
##
## Navigation is spike-owned (spec header): how a body gets from one zone
## to the next through player-changed terrain is the spike's call. Until
## it lands, relocation at a phase boundary is a direct placement at the
## idle point — the schedule model this spec requires of whatever the
## spike chooses is what's built here, not the traversal.
##
## Access via get_tree().root.get_node("Npcs") (no class_name, matching the
## existing project convention — see resources.gd).

const NPCS_DIR := "res://content/npcs/"

var _defs: Dictionary = {}  # npc_id -> Resource (NpcDefinition)
var _agents: Dictionary = {}  # npc_id -> Node (a loaded body)


func _ready() -> void:
	reload_definitions()
	var bus := get_tree().root.get_node_or_null("EventBus")
	if bus != null and not bus.phase_changed.is_connected(_on_phase_changed):
		bus.phase_changed.connect(_on_phase_changed)
	var zones := get_tree().root.get_node_or_null("Zones")
	if zones != null and zones.has_signal("loaded_zones_changed") and not zones.loaded_zones_changed.is_connected(place_all_agents):
		zones.loaded_zones_changed.connect(place_all_agents)
	var console := get_tree().root.get_node_or_null("DebugConsole")
	if console == null:
		return
	console.register_command("npcs", "npcs — every NPC: scheduled zone this phase, loaded body or off-screen.", _debug_npcs)
	console.register_command("where_is", "where_is <npc_id> — the NPC's scheduled zone now and whether its body is loaded.", _debug_where_is)
	console.register_command("scheduled_at", "scheduled_at <zone_id> <phase> — who is scheduled there, loaded or not.", _debug_scheduled_at)


# --- Content Definitions ---------------------------------------------------------

func reload_definitions() -> void:
	_defs.clear()
	var dir := DirAccess.open(NPCS_DIR)
	if dir == null:
		push_warning("Npcs: %s does not exist (no NPCs authored)" % NPCS_DIR)
		return
	dir.list_dir_begin()
	var file_name := dir.get_next()
	while file_name != "":
		if not dir.current_is_dir() and file_name.ends_with(".tres"):
			var path := NPCS_DIR + file_name
			var res: Resource = ResourceLoader.load(path, "", ResourceLoader.CACHE_MODE_REPLACE)
			if res == null:
				push_warning("Npcs: failed to load %s — skipped" % path)
			else:
				var id := StringName(str(res.get("npc_id")))
				if id == &"":
					push_warning("Npcs: %s has no npc_id set — skipped" % path)
				else:
					_defs[id] = res
		file_name = dir.get_next()
	dir.list_dir_end()


func is_known_npc(npc_id: StringName) -> bool:
	return _defs.has(npc_id)


## Sorted alphabetically — as Strings, because StringName's own ordering
## is by pointer, not text, which would make the idle-point spread below
## non-deterministic across runs.
func get_npc_ids() -> Array[StringName]:
	var names: Array[String] = []
	for key: Variant in _defs.keys():
		names.append(str(key))
	names.sort()
	var out: Array[StringName] = []
	for n: String in names:
		out.append(StringName(n))
	return out


func get_display_name(npc_id: StringName) -> String:
	var def: Resource = _defs.get(npc_id, null)
	if def == null:
		return str(npc_id)
	var display := str(def.get("display_name"))
	return display if display != "" else str(npc_id)


func get_district_id(npc_id: StringName) -> StringName:
	var def: Resource = _defs.get(npc_id, null)
	return StringName(str(def.get("district_id"))) if def != null else &""


# --- Schedules (pure data — valid for zones never loaded) ---------------------------

## The zone this NPC is at during `phase` ("" for an unknown NPC).
func get_scheduled_zone(npc_id: StringName, phase: StringName) -> String:
	var def: Resource = _defs.get(npc_id, null)
	if def == null:
		return ""
	var schedule: Variant = def.get("schedule")
	if typeof(schedule) == TYPE_DICTIONARY:
		var entry: Variant = (schedule as Dictionary).get(str(phase), null)
		if entry != null and str(entry) != "":
			return str(entry)
	return str(def.get("home_zone"))


## "Was anyone scheduled at [zone] during [phase]?" — sorted ids, answered
## from data alone, so it's correct whether or not the zone ever loaded.
func get_scheduled_npcs_at(zone_id: String, phase: StringName) -> Array[StringName]:
	var out: Array[StringName] = []
	for id: StringName in get_npc_ids():
		if get_scheduled_zone(id, phase) == zone_id:
			out.append(id)
	return out


func get_current_phase() -> StringName:
	var clock := get_tree().root.get_node_or_null("Clock")
	if clock == null:
		return &"rousing"
	return StringName(str(clock.get_phase()))


func get_current_zone(npc_id: StringName) -> String:
	return get_scheduled_zone(npc_id, get_current_phase())


# --- Loaded bodies -------------------------------------------------------------------

## Called by hollow_npc.gd when a body for npc_id enters the scene.
## Placement is deferred one frame so zone anchors declared later in the
## same scene have registered by the time it runs.
func register_agent(npc_id: StringName, node: Node) -> void:
	if npc_id == &"" or node == null:
		return
	if not is_known_npc(npc_id):
		push_warning("Npcs: body registered for unknown npc_id '%s' — it will not be scheduled" % npc_id)
		return
	_agents[npc_id] = node
	call_deferred("place_agent", npc_id)


func unregister_agent(npc_id: StringName) -> void:
	_agents.erase(npc_id)


func get_agent(npc_id: StringName) -> Node:
	var node: Variant = _agents.get(npc_id, null)
	if node == null or not is_instance_valid(node) or not (node as Node).is_inside_tree():
		return null
	return node


## A body exists AND its scheduled zone is loaded — the only NPCs
## Perception (Spec 17) may run live checks against.
func is_agent_loaded(npc_id: StringName) -> bool:
	if get_agent(npc_id) == null:
		return false
	return _zone_loaded(get_current_zone(npc_id))


func get_loaded_agents() -> Array[Node]:
	var out: Array[Node] = []
	for id: StringName in get_npc_ids():
		if is_agent_loaded(id):
			out.append(get_agent(id))
	return out


## Applies the schedule to one body right now: present at one of its
## zone's idle points, or absent if the zone isn't loaded.
func place_agent(npc_id: StringName) -> void:
	var node := get_agent(npc_id)
	if node == null:
		return
	var zone_id := get_current_zone(npc_id)
	var zones := get_tree().root.get_node_or_null("Zones")
	if zones == null or not _zone_loaded(zone_id):
		_set_present(node, false)
		return
	_set_present(node, true)
	var points: Array[Vector2] = zones.get_idle_points(zone_id)
	if points.is_empty():
		return
	# Spread everyone scheduled here across the points deterministically —
	# ordinal among the zone's scheduled NPCs (sorted ids), wrapping.
	var here := get_scheduled_npcs_at(zone_id, get_current_phase())
	var ordinal := maxi(0, here.find(npc_id))
	var target := points[ordinal % points.size()]
	if node.has_method("relocate_to"):
		node.relocate_to(target)
	elif node is Node2D:
		(node as Node2D).global_position = target


func place_all_agents() -> void:
	for id: Variant in _agents.keys():
		place_agent(id)


func _on_phase_changed(_old_phase: StringName, _new_phase: StringName) -> void:
	place_all_agents()


func _zone_loaded(zone_id: String) -> bool:
	var zones := get_tree().root.get_node_or_null("Zones")
	return zones != null and zone_id != "" and bool(zones.is_zone_loaded(zone_id))


func _set_present(node: Node, present: bool) -> void:
	if node.has_method("set_present"):
		node.set_present(present)
	elif node is CanvasItem:
		(node as CanvasItem).visible = present


# --- Build Bible Spec 02 uniform SaveLoad contract -----------------------------------

## Nothing authoritative lives here: schedules are content and a current
## location is derived from the Clock's phase (which Clock saves).
func save_state() -> Dictionary:
	return {}


func load_state(_data: Dictionary) -> void:
	pass


func reset_all() -> void:
	pass


# --- Debug -----------------------------------------------------------------------------

func _debug_npcs(_args: Array[String]) -> String:
	var lines: PackedStringArray = []
	var phase := get_current_phase()
	lines.append("Phase %s" % phase)
	for id: StringName in get_npc_ids():
		var zone := get_scheduled_zone(id, phase)
		var status := "off-screen (zone not loaded)"
		if get_agent(id) == null:
			status = "no body in scene"
		elif is_agent_loaded(id):
			status = "loaded at %s" % (get_agent(id) as Node2D).global_position
		lines.append("  %s -> %s — %s" % [id, zone, status])
	return "\n".join(lines)


func _debug_where_is(args: Array[String]) -> String:
	if args.is_empty():
		return "Usage: where_is <npc_id>"
	var id := StringName(args[0])
	if not is_known_npc(id):
		return "Unknown NPC '%s' — known: %s" % [args[0], ", ".join(PackedStringArray(get_npc_ids()))]
	return "%s is at %s this %s (%s)" % [id, get_current_zone(id), get_current_phase(), "loaded" if is_agent_loaded(id) else "off-screen"]


func _debug_scheduled_at(args: Array[String]) -> String:
	if args.size() < 2:
		return "Usage: scheduled_at <zone_id> <phase>"
	var who := get_scheduled_npcs_at(args[0], StringName(args[1].to_lower()))
	if who.is_empty():
		return "Nobody is scheduled at %s during %s" % [args[0], args[1]]
	return "Scheduled at %s during %s: %s" % [args[0], args[1], ", ".join(PackedStringArray(who))]
