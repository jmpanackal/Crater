extends SceneTree
## Dev probe: writes tmp/rock-preview.png (the rock texture tiled 3x3 at 3x scale) and tmp/brick-preview.png.
## Run: godot --headless --path . --script res://tools/preview_rock.gd


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var tex := RockTextures.cobble()
	var img := tex.get_image()
	var out := Image.create(img.get_width() * 3, img.get_height() * 3, false, Image.FORMAT_RGBA8)
	for ty in 3:
		for tx in 3:
			out.blit_rect(img, Rect2i(0, 0, img.get_width(), img.get_height()), Vector2i(tx * img.get_width(), ty * img.get_height()))
	out.resize(out.get_width() * 3, out.get_height() * 3, Image.INTERPOLATE_NEAREST)
	out.save_png(ProjectSettings.globalize_path("res://tmp/rock-preview.png"))
	quit(0)
