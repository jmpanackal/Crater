extends Node2D
## The player's home, entered (USER 2026-10-04: "should houses be entered, with a new view for the inside?" yes, the lower
## home first). Canon: the home is where rest and save, personal storage, the Approved Gear workbench and (once forbidden
## progression begins) the concealed workspace live, and the three residences (lower, Mid Reach, Ashram Heights) each
## improve on the last. This is the lower home: a small crude room.
##
## How it works: the room is a real, tiny physical space (floor, walls, ceiling) parked in the empty void of the Devil's
## Mouth. Interact at your own door fades out, hides the whole Hollow, puts the player in the room and zooms in; Interact
## at the inside door reverses it. The bed, lockbox and workbench are the SAME Rest, Storage and Rig-station nodes the
## Hollow used to hold in the street, now standing in the room, so every rule about them (sleep only from Gathering, the
## Rig only refitted at a station) is unchanged. Time and the civic cycle keep running inside. Only the player's own
## door opens. Other residences (Mid Reach, Ashram Heights) get their own rooms the same way.

const DoorScript := preload("res://home_door.gd")
const ViewScript := preload("res://home_interior_view.gd")
const BuilderScript := preload("res://hollow_dressing_builder.gd")

## The room's floor line (centre of its top edge) in the Mouth's void, well below Mid Heart and above the pit bottom.
const ORIGIN := Vector2(3200.0, 8300.0)
const HALF_WIDTH := 336.0
const ROOM_HEIGHT := 240.0
const INSIDE_ZOOM := 1.4
const OUTSIDE_DOOR_X := -112.0 ## the home_unit building's door (hollow_dressing.gd)
const OUTSIDE_DOOR_K := 12

var _inside := false
var _busy := false
var _return_position := Vector2.ZERO
var _saved_zoom := Vector2.ONE
var _fade: ColorRect
var _hidden: Array[Node] = []
var _exit_door: Area2D
var _enter_door: Area2D


func _ready() -> void:
	name = "HomeInterior"
	position = ORIGIN
	_build_room()
	_build_stations()
	_build_doors()
	_build_fade()
	visible = false # the room is only drawn while you are inside (the stations stay: they are monitorable only in range)
	_set_active(false)


func is_inside() -> bool:
	return _inside


func is_busy() -> bool:
	return _busy


## Where the player stands on arrival (just inside the door).
func spawn_position() -> Vector2:
	return ORIGIN + Vector2(-250.0, -17.0)


func outside_position() -> Vector2:
	return Vector2(OUTSIDE_DOOR_X, HollowMap.deck_y_at(OUTSIDE_DOOR_X, float(OUTSIDE_DOOR_K)) - 17.0)


func _build_room() -> void:
	var view := Node2D.new()
	view.name = "View"
	view.set_script(ViewScript)
	view.z_index = -5
	add_child(view)
	var body := StaticBody2D.new()
	body.name = "Walls"
	body.collision_layer = 1
	body.collision_mask = 0
	add_child(body)
	for r in [
		Rect2(-HALF_WIDTH - 32.0, 0.0, HALF_WIDTH * 2.0 + 64.0, 32.0), # floor
		Rect2(-HALF_WIDTH - 32.0, -ROOM_HEIGHT - 32.0, 32.0, ROOM_HEIGHT + 64.0), # west wall
		Rect2(HALF_WIDTH, -ROOM_HEIGHT - 32.0, 32.0, ROOM_HEIGHT + 64.0), # east wall
		Rect2(-HALF_WIDTH - 32.0, -ROOM_HEIGHT - 32.0, HALF_WIDTH * 2.0 + 64.0, 32.0), # ceiling
	]:
		var col := CollisionShape2D.new()
		var shape := RectangleShape2D.new()
		shape.size = r.size
		col.shape = shape
		col.position = r.get_center()
		body.add_child(col)


## The Rest, Storage and Rig-station nodes for the stations HollowDressing marks `interior`.
func _build_stations() -> void:
	for s in HollowDressing.stations():
		if not bool(s.get("interior", false)):
			continue
		var node: Area2D = BuilderScript.make_station(s)
		if node == null:
			continue
		node.name = "Station_%s" % str(s["id"])
		add_child(node)
		node.position = Vector2(float(s["x"]), -14.0)


func _build_doors() -> void:
	_exit_door = DoorScript.new()
	_exit_door.name = "ExitDoor"
	_exit_door.set("interior", self)
	_exit_door.set("leaving", true)
	_exit_door.set("prompt", "Leave home")
	_exit_door.position = Vector2(-292.0, -36.0)
	add_child(_exit_door)
	_enter_door = DoorScript.new()
	_enter_door.name = "HomeDoor"
	_enter_door.set("interior", self)
	_enter_door.set("prompt", "Enter home")
	var hollow := get_parent().get_node_or_null("Hollow")
	if hollow != null:
		hollow.add_child(_enter_door)
	else:
		add_child(_enter_door)
	_enter_door.global_position = Vector2(OUTSIDE_DOOR_X, HollowMap.deck_y_at(OUTSIDE_DOOR_X, float(OUTSIDE_DOOR_K)) - 36.0)


func _build_fade() -> void:
	var layer := CanvasLayer.new()
	layer.name = "Fade"
	layer.layer = 80
	_fade = ColorRect.new()
	_fade.color = Color(0.02, 0.015, 0.015, 1.0)
	_fade.set_anchors_preset(Control.PRESET_FULL_RECT)
	_fade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_fade.modulate.a = 0.0
	layer.add_child(_fade)
	add_child(layer)


func _player() -> CharacterBody2D:
	return get_tree().get_first_node_in_group("player") as CharacterBody2D


func _camera() -> Camera2D:
	var p := _player()
	return p.get_node_or_null("Camera2D") as Camera2D if p != null else null


func enter() -> void:
	if _inside or _busy:
		return
	_busy = true
	var player := _player()
	if player == null:
		_busy = false
		return
	await _fade_to(1.0)
	_return_position = outside_position()
	_hide_world()
	visible = true
	_set_active(true)
	_move_player(player, spawn_position())
	var cam := _camera()
	if cam != null:
		_saved_zoom = cam.zoom
		cam.zoom = Vector2(INSIDE_ZOOM, INSIDE_ZOOM)
		# the frame is the room: the camera is pinned to its middle (limits narrower than the view centre the camera)
		cam.limit_left = int(ORIGIN.x - HALF_WIDTH)
		cam.limit_right = int(ORIGIN.x + HALF_WIDTH)
		cam.limit_top = int(ORIGIN.y - ROOM_HEIGHT - 40.0)
		cam.limit_bottom = int(ORIGIN.y + 60.0)
		cam.reset_smoothing()
	_inside = true
	await _fade_to(0.0)
	_busy = false


func leave() -> void:
	if not _inside or _busy:
		return
	_busy = true
	var player := _player()
	await _fade_to(1.0)
	visible = false
	_set_active(false)
	_show_world()
	if player != null:
		_move_player(player, _return_position)
	var cam := _camera()
	if cam != null:
		cam.zoom = _saved_zoom
		if cam.has_method("_apply_play_edge_limits"):
			cam.call("_apply_play_edge_limits")
		cam.reset_smoothing()
	_inside = false
	await _fade_to(0.0)
	_busy = false


func _move_player(player: CharacterBody2D, pos: Vector2) -> void:
	player.global_position = pos
	player.velocity = Vector2.ZERO
	player.reset_physics_interpolation()


func _fade_to(alpha: float) -> void:
	var tween := create_tween()
	tween.tween_property(_fade, "modulate:a", alpha, 0.16)
	await tween.finished


## The whole Hollow is hidden while you are inside: its world, its darkness and the dig rock.
func _hide_world() -> void:
	_hidden.clear()
	var root := get_parent()
	for n in ["Hollow", "Terrain", "Vision"]:
		var node := root.get_node_or_null(n)
		if node != null and node.get("visible") == true:
			node.set("visible", false)
			_hidden.append(node)


func _show_world() -> void:
	for node in _hidden:
		if is_instance_valid(node):
			node.set("visible", true)
	_hidden.clear()


## Out of the room, its stations and the inside door must not be reachable from the street (and the room's walls must not
## catch anything): turn their monitoring off.
func _set_active(on: bool) -> void:
	for c in get_children():
		if c is Area2D:
			(c as Area2D).set_deferred("monitorable", on)
			if str(c.name).begins_with("Station_"):
				(c as Area2D).set_deferred("monitoring", on)
	var walls := get_node_or_null("Walls") as StaticBody2D
	if walls != null:
		for c in walls.get_children():
			(c as CollisionShape2D).set_deferred("disabled", not on)
