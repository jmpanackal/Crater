extends Node2D
## Soft Firmament↑ / Pit↓ dressing around the dig columns — same tools, different read.
## Firmament: quieter cool haze. Pit: heavier ink gloom. No new tileset required.

const FIRMAMENT_HAZE := Color(0.55, 0.72, 0.7, 0.07)
const PIT_GLOOM := Color(0.04, 0.07, 0.09, 0.22)
const PIT_LIP := Color(0.12, 0.2, 0.22, 0.18)


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

	# Heavier gloom over Pit walls.
	var pit := ColorRect.new()
	pit.name = "PitGloom"
	pit.position = Vector2(x0, float(TerrainLayer.PIT_Y_MIN) * tile)
	pit.size = Vector2(width, float(16 - TerrainLayer.PIT_Y_MIN) * tile)
	pit.color = PIT_GLOOM
	pit.mouse_filter = Control.MOUSE_FILTER_IGNORE
	pit.z_index = 2
	add_child(pit)

	var lip := ColorRect.new()
	lip.name = "PitLipMist"
	lip.position = Vector2(x0, float(TerrainLayer.PIT_Y_MIN) * tile - 24.0)
	lip.size = Vector2(width, 36.0)
	lip.color = PIT_LIP
	lip.mouse_filter = Control.MOUSE_FILTER_IGNORE
	lip.z_index = 2
	add_child(lip)

	_soft_label("FirmamentMark", "Firmament ↑ — quiet work", Vector2(x0 + 24.0, 12.0), Color(0.75, 0.85, 0.82, 0.55))
	_soft_label("PitMark", "Pit ↓ — walls groan", Vector2(x0 + 24.0, float(TerrainLayer.PIT_Y_MIN) * tile + 8.0), Color(0.7, 0.62, 0.5, 0.6))


func _soft_label(node_name: String, text: String, pos: Vector2, color: Color) -> void:
	var label := Label.new()
	label.name = node_name
	label.text = text
	label.position = pos
	label.add_theme_font_size_override("font_size", 13)
	label.modulate = color
	label.z_index = 3
	add_child(label)


## Test helper — Firmament haze must be quieter (lower alpha) than Pit gloom.
func firmament_quieter_than_pit() -> bool:
	var firmament := get_node_or_null("FirmamentHaze") as ColorRect
	var pit := get_node_or_null("PitGloom") as ColorRect
	if firmament == null or pit == null:
		return false
	return firmament.color.a < pit.color.a
