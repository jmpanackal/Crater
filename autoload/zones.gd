extends Node
## Krater Authored Topology / Zones (autoload: Zones).
## Build Bible Spec 05 (docs/build-bible/specs/05-authored-topology.md).
##
## Loads ZoneDefinition Content Definitions (res://content/zones/*.tres) —
## named, player-recognizable locations (Home Court, Lower Switchback, West
## Dispatch Yard, Bottom-West, Mid Heart, ...), not the chunk-atlas's
## composition-slot grid. No streaming for the vertical slice (Spec 05,
## confirmed option A) — every authored zone is simply loaded together;
## which-zones-are-loaded only becomes meaningful once real streaming lands
## later (priority-roadmap.md Phase 6), not built prematurely here.
##
## NOTE — real zone content (Home Court, Lower Switchback, etc.) is
## explicitly blocked per this spec's own header: "Blocked on a
## camera/tile-scale lock (production decision, not a design gap) before
## real chunk art can target real pixel dimensions." This file is the
## contract — the registry, loading, and seam-validation mechanism — ready
## for that content the moment the scale lock lands. Adding a zone should
## only ever mean adding a .tres file here, never editing this script.
##
## Access via get_tree().root.get_node("Zones") (no class_name, matching
## the existing project convention — see resources.gd).

const ZONES_DIR := "res://content/zones/"

const OPPOSITE_EDGE := {
	"north": "south",
	"south": "north",
	"east": "west",
	"west": "east",
}

## Fired whenever a zone anchor registers or unregisters — Npcs (Spec 16)
## re-places its bodies on this.
signal loaded_zones_changed()

var _zones: Dictionary = {}

## Which zones are currently loaded (Spec 05's own state row), as
## zone_id -> the zone_anchor.gd node that declared it in the live scene.
## Live physical state: self-corrects as scenes enter/leave, never saved.
var _loaded: Dictionary = {}


func _ready() -> void:
	reload_all()


# --- Loaded zones + idle points (Build Bible Spec 16 uses these) ---------------------

## Called by zone_anchor.gd. A zone not authored in content/zones/ is still
## registered (the scene is the ground truth for what's physically here)
## but warned about, since Spec 16 schedules can only name authored zones.
func register_loaded_zone(zone_id: String, anchor: Node) -> void:
	if zone_id == "" or anchor == null:
		return
	if not has_zone(zone_id):
		push_warning("Zones: anchor '%s' registered for unauthored zone '%s'" % [anchor.name, zone_id])
	_loaded[zone_id] = anchor
	loaded_zones_changed.emit()


func unregister_loaded_zone(zone_id: String, anchor: Node = null) -> void:
	if not _loaded.has(zone_id):
		return
	if anchor != null and _loaded[zone_id] != anchor:
		return
	_loaded.erase(zone_id)
	loaded_zones_changed.emit()


func is_zone_loaded(zone_id: String) -> bool:
	var anchor: Variant = _loaded.get(zone_id, null)
	return anchor != null and is_instance_valid(anchor) and (anchor as Node).is_inside_tree()


func get_loaded_zone_ids() -> Array[String]:
	var out: Array[String] = []
	for key: Variant in _loaded.keys():
		if is_zone_loaded(str(key)):
			out.append(str(key))
	out.sort()
	return out


## The loaded zone's marked idle points (global), or [] if it isn't loaded.
func get_idle_points(zone_id: String) -> Array[Vector2]:
	var out: Array[Vector2] = []
	if not is_zone_loaded(zone_id):
		return out
	var anchor: Node = _loaded[zone_id]
	if anchor.has_method("get_idle_points"):
		return anchor.get_idle_points()
	return out


## Re-scans res://content/zones/ and reloads every .tres file found. Safe
## to call at any time; a zone whose file fails to load is skipped with a
## warning rather than aborting the whole load, matching the same
## resilience rule TuningRegistry already follows.
func reload_all() -> void:
	_zones.clear()
	var dir := DirAccess.open(ZONES_DIR)
	if dir == null:
		push_warning("Zones: %s does not exist yet (no zones authored)" % ZONES_DIR)
		return
	dir.list_dir_begin()
	var file_name := dir.get_next()
	while file_name != "":
		if not dir.current_is_dir() and file_name.ends_with(".tres"):
			var path := ZONES_DIR + file_name
			var res: Resource = ResourceLoader.load(path, "", ResourceLoader.CACHE_MODE_REPLACE)
			if res == null:
				push_warning("Zones: failed to load %s — skipped" % path)
			else:
				var zone_id := str(res.get("zone_id"))
				if zone_id == "":
					push_warning("Zones: %s has no zone_id set — skipped" % path)
				else:
					_zones[zone_id] = res
		file_name = dir.get_next()
	dir.list_dir_end()


## Every zone authored in content/zones/ (definitions), whether or not it
## is physically loaded right now — see get_loaded_zone_ids() for that.
func get_authored_zone_ids() -> Array[String]:
	var out: Array[String] = []
	for key: Variant in _zones.keys():
		out.append(str(key))
	out.sort()
	return out


func has_zone(zone_id: String) -> bool:
	return _zones.has(zone_id)


func get_zone_origin(zone_id: String) -> Vector2:
	var zone: Resource = _zones.get(zone_id, null)
	if zone == null:
		return Vector2.ZERO
	return zone.get("world_origin")


func get_display_name(zone_id: String) -> String:
	var zone: Resource = _zones.get(zone_id, null)
	if zone == null:
		return zone_id
	var name := str(zone.get("display_name"))
	return name if name != "" else zone_id


## Build Bible Spec 17's coarse enclosed/open flag. Unknown zone = open.
func is_zone_enclosed(zone_id: String) -> bool:
	var zone: Resource = _zones.get(zone_id, null)
	if zone == null:
		return false
	return bool(zone.get("enclosed"))


func get_neighbor_ids(zone_id: String) -> Array[String]:
	var out: Array[String] = []
	var zone: Resource = _zones.get(zone_id, null)
	if zone == null:
		return out
	var seams: Array = zone.get("seams")
	for seam: Dictionary in seams:
		var neighbor := str(seam.get("neighbor", ""))
		if neighbor != "" and not out.has(neighbor):
			out.append(neighbor)
	return out


## Validates the seam-adjacency graph as a real contract, not manual
## alignment (Spec 05, option B): every zone's every seam must have a
## matching reciprocal seam on its stated neighbor — same opposite edge,
## same shared position — or this zone pair is flagged. Returns a list of
## human-readable problems; an empty array means every seam is consistent.
func validate_seams() -> Array[String]:
	var problems: Array[String] = []
	for zone_id: Variant in _zones.keys():
		var zone: Resource = _zones[zone_id]
		var seams: Array = zone.get("seams")
		for seam: Dictionary in seams:
			var edge := str(seam.get("edge", ""))
			var neighbor_id := str(seam.get("neighbor", ""))
			var position := float(seam.get("position", 0.0))

			if not _zones.has(neighbor_id):
				problems.append("%s has a seam to unknown zone '%s'" % [zone_id, neighbor_id])
				continue

			var expected_edge: String = OPPOSITE_EDGE.get(edge, "")
			var neighbor: Resource = _zones[neighbor_id]
			var neighbor_seams: Array = neighbor.get("seams")
			var found := false
			for n_seam: Dictionary in neighbor_seams:
				if str(n_seam.get("neighbor", "")) != str(zone_id):
					continue
				if str(n_seam.get("edge", "")) != expected_edge:
					continue
				found = true
				var n_position := float(n_seam.get("position", 0.0))
				if not is_equal_approx(n_position, position):
					problems.append(
						"%s/%s seam position mismatch: %s says %s, %s says %s"
						% [zone_id, neighbor_id, zone_id, position, neighbor_id, n_position]
					)
				break
			if not found:
				problems.append(
					"%s has a %s seam to %s with no matching reciprocal %s seam back"
					% [zone_id, edge, neighbor_id, expected_edge]
				)
	return problems


## Build Bible Spec 02 uniform SaveLoad contract. Empty — "which zones are
## loaded" is live scene state (anchors register themselves as the scene
## enters the tree), so it self-corrects on load rather than being saved.
func save_state() -> Dictionary:
	return {}


func load_state(_data: Dictionary) -> void:
	pass
