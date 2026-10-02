extends Node2D
## Soft Firmament↑ dressing around the dig columns — quiet cool haze, no new
## tileset required. The downward dig direction used to carry its own
## "Devil's Mouth" gloom/label here too, but that name belongs to the real
## crater void in the Hollow (HollowLayout.PIT_LEFT..PIT_RIGHT) and reusing
## it for this unrelated east dig site's downward frontier read as a stray,
## unexplained artifact once the real crater was built out — removed
## 2026-09-19.

const FIRMAMENT_HAZE := Color(0.55, 0.72, 0.7, 0.07)


func _ready() -> void:
	_build_dressing()


func _build_dressing() -> void:
	if get_node_or_null("FirmamentHaze") != null:
		return

	var tile := float(TerrainLayer.TILE_SIZE)
	var x0 := float(TerrainLayer.DIG_START_X) * tile
	var x1 := float(TerrainLayer.DIG_END_X) * tile
	var width := x1 - x0

	# Quiet cool wash over Firmament rock (secrecy — less drama).
	var firmament := ColorRect.new()
	firmament.name = "FirmamentHaze"
	firmament.position = Vector2(x0, 0.0)
	firmament.size = Vector2(width, float(TerrainLayer.FIRMAMENT_Y_MAX + 1) * tile)
	firmament.color = FIRMAMENT_HAZE
	firmament.mouse_filter = Control.MOUSE_FILTER_IGNORE
	firmament.z_index = 2
	add_child(firmament)

	# Soft vertical veil just under Firmament — "don't look up" calm band.
	var seal := ColorRect.new()
	seal.name = "FirmamentSealHint"
	seal.position = Vector2(x0, float(TerrainLayer.FIRMAMENT_Y_MAX) * tile)
	seal.size = Vector2(width, 10.0)
	seal.color = Color(0.7, 0.78, 0.76, 0.1)
	seal.mouse_filter = Control.MOUSE_FILTER_IGNORE
	seal.z_index = 2
	add_child(seal)

	_soft_label("FirmamentMark", "Firmament ↑ — quiet work", Vector2(x0 + 24.0, 12.0), Color(0.75, 0.85, 0.82, 0.55))


func _soft_label(node_name: String, text: String, pos: Vector2, color: Color) -> void:
	var label := Label.new()
	label.name = node_name
	label.text = text
	label.position = pos
	label.add_theme_font_size_override("font_size", 13)
	label.modulate = color
	label.z_index = 3
	add_child(label)
