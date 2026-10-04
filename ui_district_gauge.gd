extends Control
## A district's condition as a row of lamps on a pressure line (comfortable to critical), the way the Cistern's own
## gauges read: more lamps lit and cooler is better, fewer and redder is strained. The text beside it still says the
## word; this is the glance. Reads District; listens to EventBus.district_changed. Display only.

@export var district_id: StringName = &"cistern"

const ORDER: Array[StringName] = [&"comfortable", &"stable", &"strained", &"shortage", &"critical"]

var _condition: StringName = &"stable"


func _ready() -> void:
	custom_minimum_size = Vector2(44.0, 12.0)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	var bus := get_node_or_null("/root/EventBus")
	if bus != null and bus.has_signal("district_changed"):
		bus.district_changed.connect(_on_changed)
	_pull()


func _pull() -> void:
	var d := get_node_or_null("/root/District")
	if d != null and d.has_method("get_condition"):
		var c: StringName = d.get_condition(district_id)
		if c != &"":
			_condition = c
	queue_redraw()


func _on_changed(id: StringName, condition: StringName) -> void:
	if id == district_id:
		_condition = condition
		queue_redraw()


func _draw() -> void:
	var rank := ORDER.find(_condition)
	if rank < 0:
		rank = 1
	var lit := 5 - rank
	var tone := Color(0.42, 0.85, 0.8)
	if rank == 2:
		tone = Color(1.0, 0.76, 0.4)
	elif rank == 3:
		tone = Color(0.95, 0.55, 0.28)
	elif rank >= 4:
		tone = Color(0.88, 0.34, 0.28)
	for i in range(5):
		var x := float(i) * 9.0
		var r := Rect2(x, 2.0, 7.0, size.y - 4.0)
		draw_rect(r.grow(1.0), Color(0.03, 0.03, 0.03, 0.9))
		draw_rect(r, tone if i < lit else Color(0.1, 0.1, 0.1))
		if i < lit:
			draw_rect(Rect2(r.position, Vector2(7.0, 2.0)), Color(1, 1, 1, 0.18))
