class_name HollowBackdropView
extends Node2D
## The dim cobble back wall behind the whole civic cavity: every open stretch of room, shaft and stair
## void shows carved rock instead of the bare dark, so all the stone around the Hollow reads as one
## material. Slabs, stairwells, buildings and props draw in front of it. The Mouth stays open void
## (Mid Heart hangs over it). One instance per block of the cavity so the engine can skip what is off screen.

@export var rect := Rect2()

## Dim, so the lit foreground reads in front. HollowStairwellView matches it.
const TONE := Color(0.45, 0.45, 0.55)


func _ready() -> void:
	z_index = -3
	texture_repeat = CanvasItem.TEXTURE_REPEAT_ENABLED
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	material = RockTextures.rock_material()
	queue_redraw()


## The cavity blocks to build: both sides of the Mouth, from the Firmament to the floor slab.
static func blocks(size: float) -> Array[Rect2]:
	var out: Array[Rect2] = []
	var cavity := HollowMap.cavity_rect()
	for side in [Vector2(cavity.position.x, HollowMap.MOUTH_L), Vector2(HollowMap.MOUTH_R, cavity.end.x)]:
		var x := floorf(side.x / size) * size
		while x < side.y:
			var y := floorf(cavity.position.y / size) * size
			while y < cavity.end.y:
				var r := Rect2(maxf(x, side.x), maxf(y, cavity.position.y), 0.0, 0.0)
				r.end = Vector2(minf(x + size, side.y), minf(y + size, cavity.end.y))
				if r.size.x > 0.0 and r.size.y > 0.0:
					out.append(r)
				y += size
			x += size
	return out


func _draw() -> void:
	var tex := RockTextures.cobble()
	var size := float(RockTextures.ROCK_SIZE)
	var bx := floorf(rect.position.x / size) * size
	while bx < rect.end.x:
		var by := floorf(rect.position.y / size) * size
		while by < rect.end.y:
			var x0 := maxf(rect.position.x, bx)
			var y0 := maxf(rect.position.y, by)
			var x1 := minf(rect.end.x, bx + size)
			var y1 := minf(rect.end.y, by + size)
			if x1 > x0 and y1 > y0:
				draw_texture_rect_region(tex, Rect2(x0, y0, x1 - x0, y1 - y0), Rect2(x0 - bx, y0 - by, x1 - x0, y1 - y0), TONE)
			by += size
		bx += size
