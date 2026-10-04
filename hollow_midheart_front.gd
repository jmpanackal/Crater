extends Node2D
## The front layer of Mid Heart's structure: the stone wall columns that END_WALL puts at the ends of a Heart deck are
## clad in riveted hull plating, so the Council Terrace reads as a bulkhead of the wreck and not a stub of cave rock.
## Visual only.

const PLATE := Color(0.22, 0.24, 0.27)
const PLATE_HI := Color(0.36, 0.39, 0.43)
const RIVET := Color(0.12, 0.13, 0.15)


func _ready() -> void:
	z_index = 2
	queue_redraw()


func _draw() -> void:
	for r in HollowMap.runs():
		if not HollowMap.is_heart_zone(r["zone"]):
			continue
		var y: float = r["y"]
		var top := y - HollowMap.ROOM_HEIGHT
		if r["l"] == HollowMap.END_WALL:
			_plate(Rect2(float(r["x0"]) - HollowMap.WALL_THICK, top, HollowMap.WALL_THICK, HollowMap.ROOM_HEIGHT))
		if r["r"] == HollowMap.END_WALL:
			_plate(Rect2(float(r["x1"]), top, HollowMap.WALL_THICK, HollowMap.ROOM_HEIGHT))


func _plate(rc: Rect2) -> void:
	draw_rect(rc, PLATE)
	draw_rect(Rect2(rc.position.x, rc.position.y, 4.0, rc.size.y), PLATE_HI)
	var y := rc.position.y + 16.0
	while y < rc.end.y:
		draw_rect(Rect2(rc.position.x, y, rc.size.x, 2.0), RIVET)
		draw_rect(Rect2(rc.position.x + 6.0, y + 8.0, 4.0, 4.0), RIVET)
		draw_rect(Rect2(rc.end.x - 10.0, y + 8.0, 4.0, 4.0), RIVET)
		y += 64.0
