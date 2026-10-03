extends Node2D
## Builds every ladder, elevator, gate and zone anchor that HollowMap declares, so main.tscn
## carries none of them by hand and they cannot drift from the map (HollowMapLint.lint_scene
## checks the result). Place one of these as Hollow/Structures.

const ClimbScript := preload("res://hollow_climb.gd")
const ElevatorScript := preload("res://hollow_elevator.gd")
const GateScript := preload("res://access_gate.gd")
const ZoneAnchorScript := preload("res://zone_anchor.gd")


const GATE_BAR := Vector2(32.0, 128.0)


func _ready() -> void:
	_build_ladders()
	_build_lifts()
	_build_gates()
	_build_zone_anchors()


func _build_ladders() -> void:
	for l in HollowMap.ladders():
		var ladder := Area2D.new()
		ladder.name = str(l["id"])
		ladder.set_script(ClimbScript)
		ladder.position = Vector2(
			float(l["open_x"]) + (HollowLayout.LADDER_OPENING - HollowLayout.LADDER_WIDTH) * 0.5,
			float(l["top_y"])
		)
		ladder.set("shaft_size", Vector2(HollowLayout.LADDER_WIDTH, float(l["bottom_y"]) - float(l["top_y"])))
		# Decks are one-way: no hatch, so a ladder is mounted from the deck on top of it (the
		# margin lets Down grab it) and the climber lands straight on the deck.
		ladder.set("grab_margin_top", 28.0)
		ladder.set("deck_open_x", float(l["open_x"]))
		ladder.set("deck_open_width", 0.0)
		ladder.set("upper_land_side", 0)
		add_child(ladder)


func _build_lifts() -> void:
	for lf in HollowMap.lifts():
		var lift := AnimatableBody2D.new()
		lift.name = "Lift_%s" % str(lf["id"])
		lift.set_script(ElevatorScript)
		lift.set("lift_id", lf["id"])
		add_child(lift)
		_build_landings(lf, lift)


## One landing per stop: an invisible one-way plate across the shaft opening in the floor (the cab and its riders pass
## up through it, a walker is held up by it) and a door frame (two posts and a lintel) so the opening reads as a
## doorway for the cab, which rides between the posts.
func _build_landings(lf: Dictionary, lift: Node) -> void:
	var w: float = lf["width"]
	var premium: bool = lf["kind"] == &"premium"
	var frame_col := Color(0.72, 0.58, 0.34, 0.9) if premium else Color(0.38, 0.42, 0.44, 0.9)
	var post_h := 104.0 if premium else 120.0
	var stops: Array = lf["stops"]
	for i in range(stops.size()):
		var plate := StaticBody2D.new()
		plate.name = "Landing_%s_%d" % [str(lf["id"]), i]
		plate.position = Vector2(float(lf["open_x"]), float(stops[i]))
		plate.collision_layer = 1
		plate.collision_mask = 0
		var col := CollisionShape2D.new()
		var shape := RectangleShape2D.new()
		shape.size = Vector2(w, 6.0)
		col.shape = shape
		col.position = Vector2(w * 0.5, 3.0)
		col.one_way_collision = true
		col.one_way_collision_margin = 4.0
		plate.add_child(col)
		lift.call("register_landing", i, col) # the plate opens (disables) while the cab is flush with this stop
		for part in [
			[Vector2(-10.0, -post_h), Vector2(8.0, post_h), frame_col], # left post
			[Vector2(w + 2.0, -post_h), Vector2(8.0, post_h), frame_col], # right post
			[Vector2(-10.0, -post_h - 8.0), Vector2(w + 20.0, 8.0), frame_col], # lintel
			[Vector2(0.0, 0.0), Vector2(w, 3.0), Color(0.24, 0.2, 0.14, 0.9)], # the sill the cab slides past
		]:
			var r := ColorRect.new()
			r.position = part[0]
			r.size = part[1]
			r.color = part[2]
			r.mouse_filter = Control.MOUSE_FILTER_IGNORE
			r.z_index = 2
			plate.add_child(r)
		add_child(plate)


func _build_gates() -> void:
	for g in HollowMap.gates():
		var run := HollowMap.run_by_id(g["run"])
		var gate := StaticBody2D.new()
		gate.name = str(g["id"])
		gate.set_script(GateScript)
		gate.set("gate_id", g["id"])
		gate.set("required_trust", g["trust"])
		gate.set("required_flag", g["flag"])
		gate.set("required_residence", g["residence"])
		gate.set("explanation", g["explanation"])
		gate.set("display_name", g["label"])
		if g["blocks"]:
			gate.set("barrier_size", GATE_BAR)
			gate.set("beyond_offset", Vector2(56.0 * float(g["beyond"]), 0.0))
			gate.position = Vector2(float(g["x"]), float(run["y"]) - GATE_BAR.y * 0.5)
		else:
			# A lock with no bar across the deck (the Warden lift): tiny, parked out of the way.
			gate.set("barrier_size", Vector2(4.0, 4.0))
			gate.set("beyond_size", Vector2(4.0, 4.0))
			gate.position = Vector2(float(g["x"]), float(run["y"]) - 320.0)
		add_child(gate)


func _build_zone_anchors() -> void:
	for z in HollowMap.zones():
		if z.get("volume", false):
			continue
		var anchor := Node2D.new()
		anchor.name = "Zone_%s" % str(z["id"])
		anchor.set_script(ZoneAnchorScript)
		anchor.set("zone_id", str(z["id"]))
		add_child(anchor)
		var marker := Marker2D.new()
		marker.name = "Idle1"
		marker.position = z["anchor"]
		anchor.add_child(marker)
