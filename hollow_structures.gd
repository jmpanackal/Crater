extends Node2D
## Builds every ladder, gate and zone anchor that HollowMap declares, so main.tscn
## carries none of them by hand and they cannot drift from the map (HollowMapLint.lint_scene
## checks the result). Place one of these as Hollow/Structures.

const ClimbScript := preload("res://hollow_climb.gd")
const GateScript := preload("res://access_gate.gd")
const ZoneAnchorScript := preload("res://zone_anchor.gd")


const GATE_BAR := Vector2(32.0, 128.0)


func _ready() -> void:
	_build_ladders()
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
