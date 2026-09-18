extends Node2D
## Build Bible Spec 16 — a zone's presence in a loaded scene, plus its
## marked idle points. Placing one of these under a scene says "zone
## <zone_id> is loaded here"; its Marker2D children are the spots an NPC
## scheduled to this zone can stand (Spec 16, confirmed option A: schedules
## name zones, the zone supplies the exact spot). Registers with the Zones
## autoload (Spec 05's "which zones are currently loaded" state — live,
## self-correcting, never saved) on enter and unregisters on exit.
##
## Usage: add under a scene, set zone_id (must match a
## content/zones/<zone_id>.tres), add Marker2D children at deck-level
## positions (NPC origin = feet).

@export var zone_id: String = ""


func _ready() -> void:
	if zone_id == "":
		push_warning("ZoneAnchor '%s' has no zone_id — not registered" % name)
		return
	var zones := _zones()
	if zones != null:
		zones.register_loaded_zone(zone_id, self)


func _exit_tree() -> void:
	if zone_id == "":
		return
	var zones := _zones()
	if zones != null:
		zones.unregister_loaded_zone(zone_id, self)


## Global positions of every Marker2D (or any Node2D) child, in tree order.
func get_idle_points() -> Array[Vector2]:
	var out: Array[Vector2] = []
	for child in get_children():
		if child is Node2D:
			out.append((child as Node2D).global_position)
	return out


func _zones() -> Node:
	if not is_inside_tree():
		return null
	return get_tree().root.get_node_or_null("Zones")
