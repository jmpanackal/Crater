extends Node2D
## Builds everything HollowDressing declares: the two drawing layers, the ambient people, the
## talkers (under Hollow/NPCs so main.gd wires their dialogue) and the usable stations. Like
## HollowStructures, main.tscn carries none of it by hand. Place one as Hollow/Dressing.

const ViewScript := preload("res://hollow_dressing_view.gd")
const RockViewScript := preload("res://hollow_rock_view.gd")
## Drawing is split into chunks (a level band by a slice of the map) so the engine can skip
## whatever is off screen; one giant canvas item was 17,000 draw calls a frame.
const FringeViewScript := preload("res://hollow_fringe_view.gd")
const BackdropViewScript := preload("res://hollow_backdrop_view.gd")
const StairwellViewScript := preload("res://hollow_stairwell_view.gd")
const CisternViewScript := preload("res://hollow_cistern_view.gd")
const CHUNK := 1024.0
const AmbientScript := preload("res://hollow_ambient.gd")
const NpcScript := preload("res://hollow_npc.gd")
const RestScript := preload("res://rest_point.gd")
const FragmentScript := preload("res://lore_fragment.gd")
const StorageScript := preload("res://storage_access.gd")
const RigScript := preload("res://rig_station.gd")


func _ready() -> void:
	_build_views()
	_build_backdrop()
	_build_stairwells()
	_build_cistern_basin()
	_build_fringes()
	_build_people()
	_build_stations()


func _chunk_range(x0: float, x1: float) -> Array[int]:
	var out: Array[int] = []
	for cx in range(int(floorf(x0 / CHUNK)), int(floorf(x1 / CHUNK)) + 1):
		out.append(cx)
	return out


func _build_views() -> void:
	var back: Dictionary = {}
	var front: Dictionary = {}
	for r in HollowMap.runs():
		if r["zone"] == &"mid_heart":
			continue
		for cx in _chunk_range(float(r["x0"]) - 12.0, float(r["x1"]) + 12.0):
			back[Vector2i(int(r["k"]), cx)] = true
	for b in HollowDressing.buildings():
		for cx in _chunk_range(float(b["x0"]) - 12.0, float(b["x1"]) + 12.0):
			back[Vector2i(int(b["k"]), cx)] = true
	for p in HollowDressing.props():
		var key := Vector2i(int(p["k"]), int(floorf(float(p["x"]) / CHUNK)))
		if p["layer"] == HollowDressing.LAYER_FRONT:
			front[key] = true
		else:
			back[key] = true
	for l in HollowDressing.lamps():
		back[Vector2i(int(l["k"]), int(floorf(float(l["x"]) / CHUNK)))] = true
	for key: Vector2i in back.keys():
		var rock := Node2D.new()
		rock.name = "Rock_%d_%d" % [key.x, key.y]
		rock.set_script(RockViewScript)
		_set_chunk(rock, key)
		add_child(rock)
		var view := Node2D.new()
		view.name = "View_back_%d_%d" % [key.x, key.y]
		view.set_script(ViewScript)
		view.set("layer", HollowDressing.LAYER_BACK)
		_set_chunk(view, key)
		add_child(view)
	for key: Vector2i in front.keys():
		var fv := Node2D.new()
		fv.name = "View_front_%d_%d" % [key.x, key.y]
		fv.set_script(ViewScript)
		fv.set("layer", HollowDressing.LAYER_FRONT)
		_set_chunk(fv, key)
		add_child(fv)


## Carved back wall behind the whole cavity (see HollowBackdropView), in 1024 px blocks.
func _build_backdrop() -> void:
	for r in HollowBackdropView.blocks(CHUNK):
		var view := Node2D.new()
		view.name = "Backdrop_%d_%d" % [int(r.position.x), int(r.position.y)]
		view.set_script(BackdropViewScript)
		view.set("rect", r)
		add_child(view)


## The Cistern's pressure basin: tanks and pipes filling hall H_CI (see HollowCisternView).
func _build_cistern_basin() -> void:
	var view := Node2D.new()
	view.name = "CisternBasin"
	view.set_script(CisternViewScript)
	add_child(view)


## A carved back wall and ceiling behind every stair flight that sits in a room. Mid Heart's flights are
## open treads over the Mouth (no rock there), so they stay bare.
func _build_stairwells() -> void:
	for st in HollowMap.stairs():
		if st["zone"] == &"mid_heart" or HollowMap.is_step(st):
			continue
		var view := Node2D.new()
		view.name = "Stairwell_%s" % str(st["id"])
		view.set_script(StairwellViewScript)
		view.set("stair", st)
		add_child(view)


## Ragged rock over the edges the tile grid leaves straight (see HollowFringeView). Lives under Terrain so
## it draws after the tiles and behind the player.
func _build_fringes() -> void:
	var terrain := get_parent().get_parent().get_node_or_null("Terrain")
	if terrain == null:
		return
	var keys: Dictionary = {}
	for cx in _chunk_range(HollowMap.WEST_WALL, HollowMap.EAST_WALL):
		keys[Vector2i(0, cx)] = true
	for b in HollowDressing.buildings():
		for cx in _chunk_range(float(b["x0"]), float(b["x1"])):
			keys[Vector2i(int(b["k"]), cx)] = true
	for r in HollowMap.runs():
		if r["zone"] == &"mid_heart":
			continue
		for cx in _chunk_range(float(r["x0"]) - 16.0, float(r["x1"]) + 16.0):
			keys[Vector2i(int(r["k"]), cx)] = true
	for key: Vector2i in keys.keys():
		var fringe := Node2D.new()
		fringe.name = "Fringe_%d_%d" % [key.x, key.y]
		fringe.set_script(FringeViewScript)
		_set_chunk(fringe, key)
		terrain.add_child(fringe)


func _set_chunk(node: Node2D, key: Vector2i) -> void:
	node.set("chunk_k", key.x)
	node.set("chunk_x0", float(key.y) * CHUNK)
	node.set("chunk_x1", float(key.y + 1) * CHUNK)


func _build_people() -> void:
	var talk_parent: Node = get_parent().get_node_or_null("NPCs")
	for a in HollowDressing.actors():
		var pos := Vector2(float(a["x"]), HollowMap.deck_y_at(float(a["x"]), float(a["k"])) - float(a["y_off"]))
		var roles: Dictionary = HollowDressing.ROLES.get(a["role"], HollowDressing.ROLES[&"resident"])
		if bool(a["talk"]) and talk_parent != null:
			var npc := Node2D.new()
			npc.name = "Talker_%s" % str(a["id"])
			npc.set_script(NpcScript)
			npc.set("npc_name", str(a["name"]))
			npc.set("lines", a["lines"])
			npc.set("body_color", roles["body"])
			npc.set("interact_radius", 44.0)
			npc.position = pos # before add_child: the NPC keeps its wander origin from _ready
			talk_parent.add_child(npc)
			continue
		var person := Node2D.new()
		person.name = "Person_%s" % str(a["id"])
		person.set_script(AmbientScript)
		person.set("role", a["role"])
		person.set("activity", a["activity"])
		person.set("patrol_range", a["range"])
		person.set("face", a["face"])
		person.position = pos
		add_child(person)


func _build_stations() -> void:
	for s in HollowDressing.stations():
		var node: Area2D = null
		match s["kind"]:
			&"rest":
				node = RestScript.new()
			&"storage":
				node = StorageScript.new()
				node.set("residence_id", &"lower")
				node.set("prompt", s["prompt"])
			&"rig":
				node = RigScript.new()
				node.set("station_kind", s.get("station", &"home"))
				node.set("prompt", s["prompt"])
			&"fragment":
				node = FragmentScript.new()
				node.set("prompt", s["prompt"])
		if node == null:
			continue
		node.name = "Station_%s" % str(s["id"])
		match s["kind"]:
			&"rest", &"fragment":
				node.set("interact_radius", s["radius"])
			&"storage":
				node.set("interact_radius", s["radius"])
			&"rig":
				node.set("radius", s["radius"])
		add_child(node)
		node.position = Vector2(float(s["x"]), HollowMap.deck_y_at(float(s["x"]), float(s["k"])) - 14.0)
