extends Node2D

const PLASTER := Color(0.31, 0.32, 0.26)
const RECESS := Color(0.14, 0.20, 0.19)
const COPPER := Color(0.55, 0.37, 0.23)
const WICK := Color(0.40, 0.86, 0.69)


func _draw() -> void:
	var court := HollowLayout.HOME_COURT_DECK
	var landing := HollowLayout.HOME_LANDING
	var stair := HollowLayout.HOME_BACK_STAIR
	var roof: float = HollowLayout.HOME_ROOF_Y + 16.0
	draw_rect(Rect2(court.x, roof, landing.y - court.x, court.z - roof), PLASTER)
	draw_rect(Rect2(court.x + 8, court.z - 96, court.y - court.x - 16, 96), RECESS)
	draw_rect(Rect2(landing.x + 8, landing.z - 96, landing.y - landing.x - 16, 96), RECESS)
	_draw_basin(Vector2(court.x + 8, court.z))
	_draw_stove(Vector2(court.y - 32, court.z))
	draw_line(Vector2(court.x + 16, court.z - 80), Vector2(court.y - 16, court.z - 80), COPPER, 2)
	for cloth in range(3):
		draw_rect(Rect2(court.x + 20 + cloth * 16, court.z - 79, 10, 20), Color(0.40, 0.48, 0.42))
	draw_rect(Rect2(landing.x + 8, landing.z - 12, 32, 12), COPPER)
	draw_rect(Rect2(landing.x + 8, landing.z - 16, 32, 5), Color(0.58, 0.58, 0.43))
	draw_rect(Rect2(landing.x + 48, landing.z - 24, 20, 5), COPPER)
	draw_line(Vector2(landing.x + 50, landing.z - 19), Vector2(landing.x + 50, landing.z), COPPER, 3)
	draw_rect(Rect2(landing.y - 24, landing.z - 14, 16, 14), COPPER)
	draw_rect(Rect2(landing.y - 18, landing.z - 10, 4, 4), WICK)
	_draw_lamp(Vector2(court.x + 12, court.z - 112))
	_draw_lamp(Vector2(landing.y - 16, landing.z - 80))
	var rail_start := Vector2(stair.x, stair.y - 36)
	var rail_end := Vector2(stair.z, stair.w - 36)
	draw_line(rail_start, rail_end, COPPER, 3)
	for post in range(5):
		var rail_point := rail_start.lerp(rail_end, post / 4.0)
		draw_line(rail_point, rail_point + Vector2(0, 36), COPPER, 2)


func _draw_basin(base: Vector2) -> void:
	draw_line(base + Vector2(4, -64), base + Vector2(4, -30), COPPER, 3)
	draw_line(base + Vector2(4, -30), base + Vector2(14, -30), COPPER, 3)
	draw_rect(Rect2(base + Vector2(0, -20), Vector2(28, 20)), Color(0.38, 0.43, 0.40))
	draw_rect(Rect2(base + Vector2(3, -20), Vector2(22, 4)), WICK.darkened(0.35))


func _draw_stove(base: Vector2) -> void:
	draw_rect(Rect2(base + Vector2(0, -24), Vector2(24, 24)), COPPER.darkened(0.3))
	draw_rect(Rect2(base + Vector2(6, -16), Vector2(12, 8)), Color(0.76, 0.48, 0.24))
	draw_line(base + Vector2(20, -24), base + Vector2(20, -64), COPPER, 4)


func _draw_lamp(center: Vector2) -> void:
	draw_circle(center, 12, Color(WICK, 0.08))
	draw_circle(center, 7, COPPER)
	draw_circle(center, 4, WICK)
