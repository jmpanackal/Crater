extends Node
## Ambiguous Records / Journal stub (autoload: Journal).
## Fragments stay myth/history-flavored — never clear "alien planet."

signal records_changed
signal record_unlocked(record_id: StringName)

const RECORD_NURSERY := &"nursery_rhyme"
const RECORD_SLATE := &"slate_shard"
const RECORD_FIRMAMENT_NOTE := &"firmament_note"
const LEGACY_RECORD_CAP_NOTE := &"cap_note"

var _defs: Dictionary = {
	RECORD_NURSERY: {
		"title": "Nursery scrap",
		"text": "Don't knock the Firmament, don't wake the belly — dig down if you must, never up.",
	},
	RECORD_SLATE: {
		"title": "Slate shard",
		"text": "…course correction failed. Hull breach. Seek—  [the rest is scored away]",
	},
	RECORD_FIRMAMENT_NOTE: {
		"title": "Folded note",
		"text": "If the Roof is only rock, why does the Wickwork hoard the bright tools?",
		"unlocks_upgrade": &"quiet_dig",
		"unlock_hint": "Quiet Dig — softer Firmament strikes, harder to notice.",
	},
}

## record_id -> true when found
var _unlocked: Dictionary = {}


func get_all_ids() -> Array[StringName]:
	var out: Array[StringName] = []
	for id in _defs.keys():
		out.append(id)
	return out


func get_def(record_id: StringName) -> Dictionary:
	return _defs.get(record_id, {})


func has_record(record_id: StringName) -> bool:
	return bool(_unlocked.get(record_id, false))


func unlock_record(record_id: StringName) -> bool:
	if not _defs.has(record_id):
		return false
	if has_record(record_id):
		return false
	_unlocked[record_id] = true
	record_unlocked.emit(record_id)
	records_changed.emit()
	_notify_knowledge_unlock(record_id)
	return true


## Soft social notice when a Record opens a forbidden siphon option.
func _notify_knowledge_unlock(record_id: StringName) -> void:
	var def := get_def(record_id)
	var upgrade_id: StringName = StringName(str(def.get("unlocks_upgrade", "")))
	if upgrade_id == StringName():
		return
	var hint := str(def.get("unlock_hint", ""))
	var upgrades := get_tree().root.get_node_or_null("Upgrades")
	var name := str(upgrade_id)
	if upgrades and upgrades.has_method("get_display_name"):
		name = str(upgrades.get_display_name(upgrade_id))
	var text := "Knowledge unlocked: %s." % name
	if hint != "":
		text = "Knowledge unlocked: %s — %s" % [name, hint]
	var community := get_tree().root.get_node_or_null("Community")
	if community:
		community.notice_message.emit(text)


func get_unlocked_ids() -> Array[StringName]:
	var out: Array[StringName] = []
	for id in _defs.keys():
		if has_record(id):
			out.append(id)
	return out


## Chance roll after a dig. Upward digs bias Firmament-related scraps.
func try_find_on_dig(dug_upward: bool) -> StringName:
	var pool: Array[StringName] = []
	for id in _defs.keys():
		if not has_record(id):
			pool.append(id)
	if pool.is_empty():
		return StringName()

	var chance := 0.04
	if dug_upward:
		chance = 0.12
	if randf() > chance:
		return StringName()

	var pick: StringName = pool[randi() % pool.size()]
	if dug_upward and pool.has(RECORD_FIRMAMENT_NOTE) and not has_record(RECORD_FIRMAMENT_NOTE):
		if randf() < 0.55:
			pick = RECORD_FIRMAMENT_NOTE
	unlock_record(pick)
	return pick


func get_snapshot() -> Array:
	var out: Array = []
	for id in get_unlocked_ids():
		out.append(str(id))
	return out


func apply_snapshot(ids: Array) -> void:
	_unlocked.clear()
	for item in ids:
		var id := StringName(str(item))
		if id == LEGACY_RECORD_CAP_NOTE:
			id = RECORD_FIRMAMENT_NOTE
		if _defs.has(id):
			_unlocked[id] = true
	records_changed.emit()


func clear_all() -> void:
	_unlocked.clear()
	records_changed.emit()
