extends Control
## Small drawn icons for the HUD: an ore chunk (Materials), a wax seal (Trust) and a pressure dial. Flat shapes in the
## HUD's brass, amber and teal, drawn so they stay crisp at any scale. Display only.

@export var kind: StringName = &"ore"
@export var tone := Color(0.9, 0.7, 0.45)


func _ready() -> void:
	custom_minimum_size = Vector2(16.0, 16.0)
	mouse_filter = Control.MOUSE_FILTER_IGNORE


func _draw() -> void:
	var c := size * 0.5
	var r := minf(size.x, size.y) * 0.5 - 1.0
	match kind:
		&"ore":
			var pts := PackedVector2Array([c + Vector2(-r, 0.2 * r), c + Vector2(-0.5 * r, -r), c + Vector2(0.6 * r, -0.8 * r), c + Vector2(r, 0.1 * r), c + Vector2(0.4 * r, r), c + Vector2(-0.6 * r, 0.8 * r)])
			draw_colored_polygon(pts, Color(0.36, 0.4, 0.46))
			draw_colored_polygon(PackedVector2Array([pts[1], pts[2], c + Vector2(0.1 * r, -0.1 * r)]), Color(0.55, 0.6, 0.66))
			draw_circle(c + Vector2(0.3 * r, 0.2 * r), r * 0.18, Color(0.9, 0.7, 0.45))
		&"seal":
			draw_circle(c, r, Color(0.5, 0.2, 0.16))
			draw_circle(c, r * 0.7, Color(0.62, 0.28, 0.2))
			draw_arc(c, r * 0.4, 0.4, 5.9, 12, Color(0.95, 0.8, 0.6, 0.9), 1.5)
		&"bolt":
			# the stamina emblem: a lightning bolt in a brass ring
			draw_circle(c, r, Color(0.55, 0.4, 0.22))
			draw_circle(c, r - 2.0, Color(0.05, 0.07, 0.05))
			draw_colored_polygon(PackedVector2Array([c + Vector2(0.15 * r, -0.8 * r), c + Vector2(-0.45 * r, 0.1 * r), c + Vector2(-0.05 * r, 0.1 * r), c + Vector2(-0.2 * r, 0.8 * r), c + Vector2(0.5 * r, -0.2 * r), c + Vector2(0.1 * r, -0.2 * r)]), Color(0.55, 0.85, 0.5))
		&"pulse":
			# a tiny Pulse: the squat machine with its stack and one lit lamp
			draw_rect(Rect2(c.x - 0.55 * r, c.y - 0.5 * r, 1.1 * r, 1.2 * r), Color(0.3, 0.33, 0.37))
			draw_rect(Rect2(c.x - 0.18 * r, c.y - 0.95 * r, 0.36 * r, 0.5 * r), Color(0.2, 0.22, 0.25))
			draw_rect(Rect2(c.x - 0.3 * r, c.y - 0.1 * r, 0.6 * r, 0.3 * r), Color(1.0, 0.78, 0.42))
		&"gauge":
			# the stamina gauge's emblem: a brass-ringed dial with tick marks and a needle
			draw_circle(c, r, Color(0.55, 0.4, 0.22))
			draw_circle(c, r - 2.0, Color(0.06, 0.055, 0.05))
			for i in range(9):
				var a2 := PI * 0.85 + float(i) * (PI * 1.3 / 8.0)
				draw_line(c + Vector2(cos(a2), sin(a2)) * (r - 5.0), c + Vector2(cos(a2), sin(a2)) * (r - 3.0), Color(0.9, 0.78, 0.55, 0.9), 1.0)
			draw_line(c, c + Vector2(0.5 * r, -0.55 * r), Color(1.0, 0.76, 0.4), 2.0)
			draw_circle(c, 2.0, Color(0.9, 0.78, 0.55))
		&"dial":
			draw_circle(c, r, Color(0.2, 0.2, 0.2))
			draw_circle(c, r * 0.82, Color(0.78, 0.74, 0.62))
			draw_line(c, c + Vector2(0.45 * r, -0.5 * r), Color(0.55, 0.14, 0.1), 1.5)
		_:
			draw_circle(c, r, tone)
