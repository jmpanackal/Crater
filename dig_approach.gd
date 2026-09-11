extends Node2D
## Soft dig-site threshold — chasm lip + quiet work-walls placard past Hollow exit.
## Visual-only craft; walkable geometry stays on Hollow Floor / Terrain.

const SoftWorldLabel := preload("res://soft_world_label.gd")


func _ready() -> void:
	_build_entry()


func _build_entry() -> void:
	if get_node_or_null("ThresholdPlank") != null:
		return

	# Multi-board walk lip — leaving home decks toward work walls.
	var plank := ColorRect.new()
	plank.name = "ThresholdPlank"
	plank.position = Vector2(HollowLayout.HOLLOW_RIGHT, HollowLayout.WICK_Y - 6.0)
	plank.size = Vector2(HollowLayout.EXIT_RIGHT - HollowLayout.HOLLOW_RIGHT, 10.0)
	plank.color = Color(0.32, 0.24, 0.16, 0.7)
	plank.mouse_filter = Control.MOUSE_FILTER_IGNORE
	plank.z_index = 1
	add_child(plank)

	# Individual board seams so the lip reads as planks, not a hallway strip.
	var seam_x := HollowLayout.HOLLOW_RIGHT + 10.0
	var seam_i := 0
	while seam_x < HollowLayout.EXIT_RIGHT - 4.0:
		var seam := ColorRect.new()
		seam.name = "ThresholdSeam%d" % seam_i
		seam.position = Vector2(seam_x, HollowLayout.WICK_Y - 5.0)
		seam.size = Vector2(2.0, 8.0)
		seam.color = Color(0.18, 0.12, 0.08, 0.55)
		seam.mouse_filter = Control.MOUSE_FILTER_IGNORE
		seam.z_index = 2
		add_child(seam)
		seam_x += 12.0
		seam_i += 1

	var lip := ColorRect.new()
	lip.name = "ThresholdLip"
	lip.position = Vector2(HollowLayout.HOLLOW_RIGHT - 6.0, HollowLayout.WICK_Y - 12.0)
	lip.size = Vector2(14.0, 8.0)
	lip.color = Color(0.45, 0.34, 0.22, 0.55)
	lip.mouse_filter = Control.MOUSE_FILTER_IGNORE
	lip.z_index = 1
	add_child(lip)

	# Post + rope at the Hollow side of the threshold.
	var post := ColorRect.new()
	post.name = "ThresholdPost"
	post.position = Vector2(HollowLayout.HOLLOW_RIGHT - 3.0, HollowLayout.WICK_Y - 28.0)
	post.size = Vector2(4.0, 22.0)
	post.color = Color(0.28, 0.2, 0.14, 0.95)
	post.mouse_filter = Control.MOUSE_FILTER_IGNORE
	post.z_index = 2
	add_child(post)

	# Deeper ink under the plank so the gap reads as a small chasm, not a hallway.
	var chasm := ColorRect.new()
	chasm.name = "ThresholdChasm"
	chasm.position = Vector2(HollowLayout.HOLLOW_RIGHT + 4.0, HollowLayout.WICK_Y + 6.0)
	chasm.size = Vector2(56.0, 140.0)
	chasm.color = Color(0.01, 0.02, 0.03, 0.92)
	chasm.mouse_filter = Control.MOUSE_FILTER_IGNORE
	chasm.z_index = 0
	add_child(chasm)

	# Cool mist rising from the gap — home warmth ends here.
	var cool := ColorRect.new()
	cool.name = "ThresholdCoolMist"
	cool.position = Vector2(HollowLayout.HOLLOW_RIGHT - 8.0, HollowLayout.WICK_Y - 40.0)
	cool.size = Vector2(80.0, 50.0)
	cool.color = Color(0.2, 0.4, 0.45, 0.1)
	cool.mouse_filter = Control.MOUSE_FILTER_IGNORE
	cool.z_index = 0
	add_child(cool)

	# Warm spill fading from Wick deck — lantern grammar cutover.
	var warm_fade := ColorRect.new()
	warm_fade.name = "ThresholdWarmFade"
	warm_fade.position = Vector2(HollowLayout.HOLLOW_RIGHT - 48.0, HollowLayout.WICK_Y - 24.0)
	warm_fade.size = Vector2(44.0, 24.0)
	warm_fade.color = Color(1.0, 0.7, 0.35, 0.08)
	warm_fade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	warm_fade.z_index = 0
	add_child(warm_fade)

	# Soft rock teeth under the far side — dig walls begin.
	var teeth := ColorRect.new()
	teeth.name = "ThresholdTeeth"
	teeth.position = Vector2(HollowLayout.EXIT_RIGHT - 10.0, HollowLayout.WICK_Y + 4.0)
	teeth.size = Vector2(14.0, 28.0)
	teeth.color = Color(0.12, 0.18, 0.17, 0.75)
	teeth.mouse_filter = Control.MOUSE_FILTER_IGNORE
	teeth.z_index = 1
	add_child(teeth)

	var label := Label.new()
	label.name = "ThresholdLabel"
	label.text = "Work walls ahead"
	label.position = Vector2(HollowLayout.HOLLOW_RIGHT + 8.0, HollowLayout.WICK_Y - 40.0)
	label.add_theme_font_size_override("font_size", 12)
	label.set_script(SoftWorldLabel)
	label.set("show_radius", 180.0)
	label.set("far_alpha", 0.12)
	label.set("near_alpha", 0.72)
	label.modulate = Color(0.78, 0.72, 0.58, 0.7)
	label.z_index = 3
	add_child(label)


## Test helper — entry pieces exist and chasm is darker than the plank.
func entry_reads_as_threshold() -> bool:
	var plank := get_node_or_null("ThresholdPlank") as ColorRect
	var chasm := get_node_or_null("ThresholdChasm") as ColorRect
	var label := get_node_or_null("ThresholdLabel") as Label
	var cool := get_node_or_null("ThresholdCoolMist") as ColorRect
	if plank == null or chasm == null or label == null or cool == null:
		return false
	return chasm.color.a > plank.color.a and "work" in label.text.to_lower()
