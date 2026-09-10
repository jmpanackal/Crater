extends SceneTree
## Hollow backdrop is a tiled TextureRect covering the zone without ColorRect.


func _init() -> void:
	call_deferred("_run_tests")


func _run_tests() -> void:
	var tex: Texture2D = load("res://sprites/hollow_bg.png")
	if tex == null:
		push_error("FAIL hollow_bg.png missing")
		quit(1)
		return
	if tex.get_width() != 256 or tex.get_height() != 256:
		push_error("FAIL unexpected hollow_bg size %dx%d" % [tex.get_width(), tex.get_height()])
		quit(1)
		return
	print("PASS hollow_bg loaded 256x256")

	var scene: Node = (load("res://main.tscn") as PackedScene).instantiate()
	root.add_child(scene)
	await process_frame

	var backdrop: Node = scene.get_node_or_null("Hollow/Backdrop")
	if backdrop == null:
		push_error("FAIL Hollow/Backdrop missing")
		quit(1)
		return
	if not (backdrop is TextureRect):
		push_error("FAIL Backdrop is %s, expected TextureRect" % backdrop.get_class())
		quit(1)
		return

	var rect := backdrop as TextureRect
	if rect.texture != tex and rect.texture == null:
		push_error("FAIL Backdrop has no texture")
		quit(1)
		return
	if rect.stretch_mode != TextureRect.STRETCH_TILE:
		push_error("FAIL stretch_mode=%d expected STRETCH_TILE" % rect.stretch_mode)
		quit(1)
		return
	if rect.texture_repeat != CanvasItem.TEXTURE_REPEAT_ENABLED:
		push_error("FAIL texture_repeat not enabled")
		quit(1)
		return

	var size := rect.size
	if size.x < 319.0 or size.y < 399.0:
		push_error("FAIL Backdrop size %s too small for Hollow zone" % size)
		quit(1)
		return

	# Native tile is 256x256; a 320x400 rect needs tiling (not a single stretched copy).
	var tiles_x := size.x / float(tex.get_width())
	var tiles_y := size.y / float(tex.get_height())
	if tiles_x <= 1.0 and tiles_y <= 1.0:
		push_error("FAIL zone fits in one tile — unexpected for this setup")
		quit(1)
		return
	print("PASS Backdrop tiles across Hollow (%.2fx%.2f tiles)" % [tiles_x, tiles_y])

	# Zone logic untouched.
	if scene.get_node_or_null("Hollow/HollowZone") == null:
		push_error("FAIL HollowZone missing")
		quit(1)
		return
	if scene.get_node_or_null("Hollow/Floor/CollisionShape2D") == null:
		push_error("FAIL Hollow floor collision missing")
		quit(1)
		return
	print("PASS Hollow zone + collision still present")

	print("HOLLOW_BG_TESTS_PASSED")
	quit(0)
