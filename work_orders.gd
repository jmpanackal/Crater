extends Node
## Act 1 Work Orders (autoload: WorkOrders).
## Joss at Mid Heart assigns one civic Materials delivery at a time.
## Deliveries reuse Districts.queue_material — never invent production outside Harvest rules.

signal work_order_changed
signal work_order_resolved(order_id: StringName)

const STATE_OFFERED := &"offered"
const STATE_ACTIVE := &"active"
const STATE_MATERIALS_DELIVERED := &"materials_delivered"
const STATE_AWAITING_HARVEST := &"awaiting_Harvest"
const STATE_RESOLVED := &"resolved"

const FEED_GLOWBEDS := &"feed_glowbeds"
const HOLD_GALLERY := &"hold_gallery"
const PRESSURE_BELOW := &"pressure_below"

const ORDER_SEQUENCE: Array[StringName] = [FEED_GLOWBEDS, HOLD_GALLERY, PRESSURE_BELOW]

var _defs: Dictionary = {
	FEED_GLOWBEDS: {
		"title": "Feed the Glowbeds",
		"material": &"sporemeal",
		"amount": 2,
		"district": &"farms",
		"tracker": "Sporemeal → Glowbeds",
	},
	HOLD_GALLERY: {
		"title": "Hold the Gallery",
		"material": &"lampwick",
		"amount": 2,
		"district": &"wickwork",
		"tracker": "Lampwick → Wickwork",
	},
	PRESSURE_BELOW: {
		"title": "Pressure Below",
		"material": &"brinecrystal",
		"amount": 2,
		"district": &"cistern",
		"tracker": "Brinecrystal → Cistern",
	},
}

var _active_id: StringName = FEED_GLOWBEDS
var _state: StringName = STATE_OFFERED
var _delivered: int = 0
var _completed: Array[StringName] = []
var _wired := false


func _ready() -> void:
	call_deferred("_wire_hooks")


func _wire_hooks() -> void:
	if _wired:
		return
	var districts := get_tree().root.get_node_or_null("Districts")
	if districts and districts.has_signal("material_queued"):
		if not districts.material_queued.is_connected(_on_material_queued):
			districts.material_queued.connect(_on_material_queued)
	var community := get_tree().root.get_node_or_null("Community")
	if community and community.has_signal("harvest_completed"):
		if not community.harvest_completed.is_connected(_on_harvest_completed):
			community.harvest_completed.connect(_on_harvest_completed)
	_wired = true


func reset_all() -> void:
	_active_id = FEED_GLOWBEDS
	_state = STATE_OFFERED
	_delivered = 0
	_completed.clear()
	work_order_changed.emit()


func get_active_order_id() -> StringName:
	return _active_id


func get_state() -> StringName:
	return _state


func get_delivered_count() -> int:
	return _delivered


func get_required_amount() -> int:
	return int(_defs.get(_active_id, {}).get("amount", 0))


func get_required_material() -> StringName:
	return StringName(str(_defs.get(_active_id, {}).get("material", "")))


func get_title() -> String:
	if _active_id == StringName() or not _defs.has(_active_id):
		return ""
	return str(_defs[_active_id].get("title", ""))


func is_completed(order_id: StringName) -> bool:
	return order_id in _completed


func are_all_complete() -> bool:
	for id in ORDER_SEQUENCE:
		if id not in _completed:
			return false
	return true


func accept_offered() -> bool:
	if _state != STATE_OFFERED or _active_id == StringName():
		return false
	_state = STATE_ACTIVE
	_delivered = 0
	work_order_changed.emit()
	return true


func acknowledge_delivery() -> bool:
	if _state != STATE_MATERIALS_DELIVERED:
		return false
	_state = STATE_AWAITING_HARVEST
	work_order_changed.emit()
	return true


## Tracker copy for the small objective chip (empty when idle / all done).
func get_tracker_text() -> String:
	if are_all_complete() or _active_id == StringName() or not _defs.has(_active_id):
		return ""
	if _state == STATE_OFFERED:
		return "Talk to Joss — %s" % get_title()
	var def: Dictionary = _defs[_active_id]
	var need: int = int(def.get("amount", 0))
	var hint: String = str(def.get("tracker", ""))
	match _state:
		STATE_ACTIVE:
			return "%s  %d/%d" % [hint, _delivered, need]
		STATE_MATERIALS_DELIVERED:
			return "%s — report to Joss" % get_title()
		STATE_AWAITING_HARVEST:
			return "%s — wait for Harvest" % get_title()
		_:
			return ""


func get_joss_lines() -> PackedStringArray:
	if are_all_complete():
		return PackedStringArray([
			"That's the civic slate for now.",
			"Keep the side galleries braced — Mid Heart will call when more work lands.",
		])
	if not _defs.has(_active_id):
		return PackedStringArray(["Mid Heart's quiet. Check back after Harvest."])
	match _active_id:
		FEED_GLOWBEDS:
			return _lines_feed_glowbeds()
		HOLD_GALLERY:
			return _lines_hold_gallery()
		PRESSURE_BELOW:
			return _lines_pressure_below()
		_:
			return PackedStringArray(["Need something turned in?"])


func get_joss_choice_prompt() -> String:
	if _state == STATE_OFFERED and not are_all_complete():
		return "Take the work?"
	return ""


func get_snapshot() -> Dictionary:
	var completed_out: Array = []
	for id in _completed:
		completed_out.append(str(id))
	return {
		"active_id": str(_active_id),
		"state": str(_state),
		"delivered": _delivered,
		"completed": completed_out,
	}


func apply_snapshot(data: Dictionary) -> void:
	if data.is_empty():
		return
	var active := StringName(str(data.get("active_id", FEED_GLOWBEDS)))
	if active != StringName() and not _defs.has(active) and not are_all_ids_done_from(data):
		active = FEED_GLOWBEDS
	_active_id = active
	var st := StringName(str(data.get("state", STATE_OFFERED)))
	_state = st if st != StringName() else STATE_OFFERED
	_delivered = maxi(0, int(data.get("delivered", 0)))
	_completed.clear()
	var done: Variant = data.get("completed", [])
	if typeof(done) == TYPE_ARRAY:
		for item in done:
			var id := StringName(str(item))
			if id in ORDER_SEQUENCE and id not in _completed:
				_completed.append(id)
	if are_all_complete():
		_active_id = StringName()
		_state = STATE_RESOLVED
		_delivered = 0
	work_order_changed.emit()


func are_all_ids_done_from(data: Dictionary) -> bool:
	var done: Variant = data.get("completed", [])
	if typeof(done) != TYPE_ARRAY:
		return false
	var set_done: Dictionary = {}
	for item in done:
		set_done[str(item)] = true
	for id in ORDER_SEQUENCE:
		if not set_done.has(str(id)):
			return false
	return true


func _on_material_queued(material_id: StringName) -> void:
	if _state != STATE_ACTIVE:
		return
	if material_id != get_required_material():
		return
	_delivered += 1
	if _delivered >= get_required_amount():
		_delivered = get_required_amount()
		_state = STATE_MATERIALS_DELIVERED
	work_order_changed.emit()


func _on_harvest_completed(_missed: bool) -> void:
	if _state != STATE_AWAITING_HARVEST:
		return
	var finished := _active_id
	if finished != StringName() and finished not in _completed:
		_completed.append(finished)
	work_order_resolved.emit(finished)
	_advance_to_next_offered()


func _advance_to_next_offered() -> void:
	var next_id := StringName()
	for id in ORDER_SEQUENCE:
		if id not in _completed:
			next_id = id
			break
	if next_id == StringName():
		_active_id = StringName()
		_state = STATE_RESOLVED
		_delivered = 0
	else:
		_active_id = next_id
		_state = STATE_OFFERED
		_delivered = 0
	work_order_changed.emit()


func _lines_feed_glowbeds() -> PackedStringArray:
	match _state:
		STATE_OFFERED:
			return PackedStringArray([
				"Glowbeds are short on Sporemeal.",
				"Bring two bags to the beds — households need the next allotment.",
			])
		STATE_ACTIVE:
			return PackedStringArray([
				"Still need Sporemeal at Glowbeds.",
				"Two bags. Turn them in at the beds — [E] works.",
			])
		STATE_MATERIALS_DELIVERED:
			return PackedStringArray([
				"That Sporemeal's queued. Good work.",
				"Wait for Harvest — then the Glowrations move.",
			])
		STATE_AWAITING_HARVEST:
			return PackedStringArray([
				"Harvest hasn't settled yet.",
				"Once it does, the beds' output goes back out.",
			])
		_:
			return PackedStringArray([
				"Glowbeds are feeding nearby households again.",
				"A worker said the wall growth's been thick since the crash. Keep that quiet.",
			])


func _lines_hold_gallery() -> PackedStringArray:
	match _state:
		STATE_OFFERED:
			return PackedStringArray([
				"Side gallery stays dark until Wickwork has Lampwick.",
				"Two strands. Verdigris is optional — lamps and Bindcord will do.",
			])
		STATE_ACTIVE:
			return PackedStringArray([
				"Lampwick to Wickwork — two turns.",
				"We're lighting and bracing the reopened gallery, not patching the shop itself.",
			])
		STATE_MATERIALS_DELIVERED:
			return PackedStringArray([
				"Wickwork's queue is set.",
				"Tell me once Harvest lands — crew needs those Wicklamps and Bindcord.",
			])
		STATE_AWAITING_HARVEST:
			return PackedStringArray([
				"Still waiting on Harvest.",
				"Then the gallery crew can light and brace the side cut.",
			])
		_:
			return PackedStringArray([
				"Gallery crew's got light and Bindcord now.",
				"Keep Verdigris for Wickwork or Mid Heart Tallies — your call.",
			])


func _lines_pressure_below() -> PackedStringArray:
	match _state:
		STATE_OFFERED:
			return PackedStringArray([
				"Lateral seep gallery's bleeding pressure.",
				"Two Brinecrystal to the Cistern — Presswater and Sealbrine. Stay off Devil's Mouth.",
			])
		STATE_ACTIVE:
			return PackedStringArray([
				"Brinecrystal at the Cistern — two deliveries.",
				"Presswater for freight lines; Sealbrine for the seep crew.",
			])
		STATE_MATERIALS_DELIVERED:
			return PackedStringArray([
				"Cistern queue's loaded.",
				"After Harvest, freight stays supplied and the seep gets sealed.",
			])
		STATE_AWAITING_HARVEST:
			return PackedStringArray([
				"Harvest still pending.",
				"Don't treat Devil's Mouth as a work route — keep it lateral.",
			])
		_:
			return PackedStringArray([
				"Presswater's back on the public freight lines.",
				"Seep crew found an old pressure reading in hull scrap — crater and ship, same bones.",
			])
