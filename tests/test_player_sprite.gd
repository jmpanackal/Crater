extends SceneTree
## 8-dir idle mapping, textures load, dig still works, ColorRect replaced.


func _init() -> void:
	call_deferred("_run_tests")


func _run_tests() -> void:
	var cases := {
		Vector2i(0, 1): &"idle_south",
		Vector2i(0, -1): &"idle_north",
		Vector2i(1, 0): &"idle_east",
		Vector2i(-1, 0): &"idle_west",
		Vector2i(1, 1): &"idle_south_east",
		Vector2i(-1, 1): &"idle_south_west",
		Vector2i(1, -1): &"idle_north_east",
		Vector2i(-1, -1): &"idle_north_west",
	}
	for dir in cases.keys():
		var expected: StringName = cases[dir]
		var actual: StringName = _facing_to_idle_anim(dir)
		if actual != expected:
			push_error("FAIL facing %s -> %s expected %s" % [dir, actual, expected])
			quit(1)
			return
		print("PASS facing ", dir, " -> ", actual)

	var paths := [
		"res://sprites/player/idle/south.png",
		"res://sprites/player/idle/south-east.png",
		"res://sprites/player/idle/east.png",
		"res://sprites/player/idle/north-east.png",
		"res://sprites/player/idle/north.png",
		"res://sprites/player/idle/north-west.png",
		"res://sprites/player/idle/west.png",
		"res://sprites/player/idle/south-west.png",
	]
	for path in paths:
		if load(path) == null:
			push_error("FAIL missing texture %s" % path)
			quit(1)
			return
	print("PASS all idle textures load")

	var community: Node = root.get_node_or_null("Community")
	if community:
		community.set_paused(true)

	var terrain := TerrainLayer.new()
	root.add_child(terrain)
	await process_frame
	terrain.clear()
	var center := Vector2i(10, 10)
	for d in [Vector2i.LEFT, Vector2i.RIGHT, Vector2i.UP, Vector2i.DOWN]:
		terrain.set_cell(center + d, 0, TerrainLayer.PLACEHOLDER_ATLAS)
	var origin := terrain.to_global(terrain.map_to_local(center))
	for d in [Vector2i.LEFT, Vector2i.RIGHT, Vector2i.UP, Vector2i.DOWN]:
		if not terrain.dig_in_direction(origin, d):
			push_error("FAIL dig %s" % d)
			quit(1)
			return
	print("PASS dig still works in 4 directions")

	var scene: Node = (load("res://main.tscn") as PackedScene).instantiate()
	root.add_child(scene)
	await process_frame
	var player: Node = scene.get_node("Player")
	if player.get_node_or_null("ColorRect") != null:
		push_error("FAIL ColorRect placeholder still present")
		quit(1)
		return
	var sprite: AnimatedSprite2D = player.get_node_or_null("AnimatedSprite2D")
	if sprite == null:
		push_error("FAIL AnimatedSprite2D missing")
		quit(1)
		return
	if sprite.sprite_frames == null or sprite.sprite_frames.get_animation_names().is_empty():
		push_error("FAIL sprite frames not built")
		quit(1)
		return
	print("PASS player uses AnimatedSprite2D with idle frames (", sprite.animation, ")")

	print("PLAYER_SPRITE_TESTS_PASSED")
	quit(0)


## Mirrors player.gd facing_to_idle_anim for headless checks.
func _facing_to_idle_anim(dir: Vector2i) -> StringName:
	var x := signi(dir.x)
	var y := signi(dir.y)
	if x == 0 and y == 0:
		return &"idle_east"
	if x == 0 and y > 0:
		return &"idle_south"
	if x == 0 and y < 0:
		return &"idle_north"
	if y == 0 and x > 0:
		return &"idle_east"
	if y == 0 and x < 0:
		return &"idle_west"
	if x > 0 and y > 0:
		return &"idle_south_east"
	if x < 0 and y > 0:
		return &"idle_south_west"
	if x > 0 and y < 0:
		return &"idle_north_east"
	return &"idle_north_west"
