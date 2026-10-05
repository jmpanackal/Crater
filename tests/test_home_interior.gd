extends SceneTree
## The player's home can be entered (USER 2026-10-04): Interact at your own door fades into a small room that holds the
## bed, lockbox and workbench (the same Rest, Storage and Rig-station nodes, so their rules are unchanged), the Hollow is
## hidden while you are inside, and Interact at the inside door puts you back at the street door. The stations are no
## longer standing in the street.

var _failed := false


func _init() -> void:
	call_deferred("_run")


func _fail(msg: String) -> void:
	_failed = true
	push_error("FAIL " + msg)


func _frames(n: int) -> void:
	for _i in range(n):
		await physics_frame


func _run() -> void:
	var scene: Node = (load("res://main.tscn") as PackedScene).instantiate()
	root.add_child(scene)
	await _frames(20)
	var player: CharacterBody2D = scene.get_node("Player")
	var home: Node = scene.get_node("HomeInterior")
	var hollow: Node2D = scene.get_node("Hollow")
	var cam: Camera2D = player.get_node("Camera2D")
	# the stations are in the room, not the street
	for id in ["home_bed", "home_lockbox", "home_workbench"]:
		if home.get_node_or_null("Station_%s" % id) == null:
			_fail("%s should stand in the home" % id)
		if hollow.find_child("Station_%s" % id, true, false) != null:
			_fail("%s should not also stand in the street" % id)
	# at the door, Interact offers to go in
	player.global_position = home.outside_position()
	player.velocity = Vector2.ZERO
	await _frames(20)
	if str(player.get_interaction().get_current_prompt()) != "Enter home":
		_fail("at the door the prompt should be 'Enter home' (got '%s')" % player.get_interaction().get_current_prompt())
	var zoom_before := cam.zoom
	player.get_interaction().try_interact(player)
	await _frames(90)
	if not home.is_inside() or hollow.visible:
		_fail("Interact at the door should take the player in and hide the Hollow (inside %s, hollow visible %s)" % [home.is_inside(), hollow.visible])
	if player.global_position.distance_to(home.spawn_position()) > 90.0 or not player.is_on_floor():
		_fail("the player should stand on the room's floor near the door (at %s)" % player.global_position)
	if cam.zoom == zoom_before:
		_fail("the frame should zoom to the room")
	# the stations work in the room: standing at the lockbox, Interact offers storage
	player.global_position = home.global_position + Vector2(-130.0 - 16.0, -17.0)
	player.velocity = Vector2.ZERO
	await _frames(15)
	if str(player.get_interaction().get_current_prompt()) != "Open storage":
		_fail("at the lockbox the prompt should be 'Open storage' (got '%s')" % player.get_interaction().get_current_prompt())
	# standing at the workbench is a real Rig station
	var rig: Node = root.get_node("Rig")
	player.global_position = home.global_position + Vector2(150.0, -17.0)
	player.velocity = Vector2.ZERO
	await _frames(20)
	if not rig.can_equip_at_current_location():
		_fail("the Rig should be refittable at the workbench inside")
	# the street's other stations do not reach in, and the room's door goes back out
	player.global_position = home.global_position + Vector2(-292.0, -17.0)
	player.velocity = Vector2.ZERO
	await _frames(15)
	if str(player.get_interaction().get_current_prompt()) != "Leave home":
		_fail("at the inside door the prompt should be 'Leave home' (got '%s')" % player.get_interaction().get_current_prompt())
	player.get_interaction().try_interact(player)
	await _frames(90)
	if home.is_inside() or not hollow.visible:
		_fail("Interact at the inside door should come back out and show the Hollow")
	if player.global_position.distance_to(home.outside_position()) > 60.0:
		_fail("the player should be back at the street door (at %s)" % player.global_position)
	if rig.can_equip_at_current_location():
		_fail("out in the street the Rig must not be refittable")
	if cam.zoom != zoom_before:
		_fail("the frame should return to its zoom")
	if _failed:
		quit(1)
		return
	print("PASS the home can be entered and left; the bed, lockbox and workbench stand in the room")
	quit(0)
