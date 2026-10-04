extends Control
## The civic cycle as the Pulse shows it: four lamps for Rousing, Working, Gathering and Ritual (the same four the
## Pulse's own indicator row lights), the current phase burning, the finished ones banked low, and a thin line for
## how far through the phase it is. Reads Clock, listens to EventBus.phase_changed. Display only.

const PHASES: Array[StringName] = [&"rousing", &"working", &"gathering", &"ritual"]
const LAMP := 12.0
const GAP := 6.0

var _phase: StringName = &"rousing"
var _progress := 0.0
var _t := 0.0


func _ready() -> void:
	custom_minimum_size = Vector2(4.0 * LAMP + 3.0 * GAP, LAMP + 6.0)
	mouse_filter = Control.MOUSE_FILTER_PASS
	tooltip_text = "The Pulse sets the civic cycle: Rousing, Working, Gathering, Ritual."
	var bus := get_node_or_null("/root/EventBus")
	if bus != null and bus.has_signal("phase_changed"):
		bus.phase_changed.connect(func(_old: StringName, new_phase: StringName) -> void: _set_phase(new_phase))
	_refresh()


func _set_phase(p: StringName) -> void:
	_phase = p
	queue_redraw()


func _refresh() -> void:
	var clock := get_node_or_null("/root/Clock")
	if clock != null and clock.has_method("get_phase"):
		_phase = clock.get_phase()
		_progress = clock.get_phase_progress()
	queue_redraw()


func _process(delta: float) -> void:
	_t += delta
	_refresh()


func _draw() -> void:
	var now := PHASES.find(_phase)
	for i in range(PHASES.size()):
		var x := float(i) * (LAMP + GAP)
		var r := Rect2(x, 0.0, LAMP, LAMP)
		draw_rect(r.grow(1.5), Color(0.03, 0.03, 0.03, 0.9))
		var col := Color(0.1, 0.1, 0.1)
		if i == now:
			var pulse := 0.85 + 0.15 * sin(_t * 3.0)
			col = Color(1.0, 0.95, 0.75) if _phase == &"ritual" else Color(1.0, 0.78, 0.42)
			col = Color(col.r * pulse, col.g * pulse, col.b * pulse)
			draw_circle(r.get_center(), LAMP * 1.2, Color(col.r, col.g, col.b, 0.12))
		elif i < now:
			col = Color(0.42, 0.3, 0.16)
		draw_rect(r, col)
		draw_rect(Rect2(r.position, Vector2(LAMP, 2.0)), Color(1, 1, 1, 0.12))
	# progress through the current phase, under the lamp that is burning
	if now >= 0:
		var x0 := float(now) * (LAMP + GAP)
		draw_rect(Rect2(x0, LAMP + 3.0, LAMP, 2.0), Color(0.04, 0.04, 0.04, 0.9))
		draw_rect(Rect2(x0, LAMP + 3.0, LAMP * clampf(_progress, 0.0, 1.0), 2.0), Color(1.0, 0.78, 0.42, 0.95))
