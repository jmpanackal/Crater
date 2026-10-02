extends Node2D
## Builds every ladder, lift, gate and zone anchor that HollowMap declares, so main.tscn
## carries none of them by hand and they cannot drift from the map (HollowMapLint.lint_scene
## checks the result). Place one of these as Hollow/Structures.

const ClimbScript := preload("res://hollow_climb.gd")
const LiftScript := preload("res://hollow_lift.gd")
const GateScript := preload("res://access_gate.gd")
const ZoneAnchorScript := preload("res://zone_anchor.gd")

const SoftWorldLabel := preload("res://soft_world_label.gd")

const GATE_BAR := Vector2(32.0, 128.0)
## Decks are one-way: going up a stair needs nothing, going down means pressing Down on the
## street above the flight. This is the cue.
const STAIR_DOWN_HINT := "[S] stairs down"


func _ready() -> void:
	_build_ladders()
	_build_lifts()
	_build_gates()
	_build_zone_anchors()
	_build_stair_hints()


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
		lift.set_script(LiftScript)
		lift.set("lift_id", lf["id"])
		lift.set("access_gate_id", lf["gate"])
		# Presswater cages beat a ladder (140 px/s): the essential civic cage fastest.
		lift.set("move_speed", 220.0 if HollowLayout.is_essential_lift(lf["id"]) else 160.0)
		# Park at the bottom stop: a rider arriving from below finds the cage waiting.
		lift.set("default_stop_index", (lf["stops"] as Array).size() - 1)
		add_child(lift)


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


func _build_stair_hints() -> void:
	for st in HollowMap.stairs():
		var hint := Label.new()
		hint.name = "StairHint_%s" % str(st["id"])
		hint.text = STAIR_DOWN_HINT
		hint.position = Vector2(float(st["top_x"]) - float(st["dir"]) * 56.0 - 44.0, float(st["top_y"]) - 70.0)
		hint.add_theme_font_size_override("font_size", 11)
		hint.set_script(SoftWorldLabel)
		hint.set("show_radius", 260.0)
		hint.set("far_alpha", 0.0)
		hint.set("near_alpha", 0.75)
		hint.modulate = Color(0.85, 0.78, 0.6, 0.75)
		hint.z_index = 4
		add_child(hint)
