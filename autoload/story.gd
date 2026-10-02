extends Node
## Krater Story flags (autoload: Story).
## Introduced by Build Bible Spec 27 (residence "story clearance") and
## shared with Spec 31 (Access/Gates) and Spec 32 (Firmament). The state
## table's "Story flags" row: authoritative, set only through authored
## events with a reason (same reason-traceable shape as Trust/Wallet).
##
## Access via get_tree().root.get_node("Story") (no class_name).

const FACT_STORY_FLAG := &"story_flag"

var _flags: Dictionary = {}  # flag_id -> {"reason": String, "cycle": int}


func _ready() -> void:
	var console := get_tree().root.get_node_or_null("DebugConsole")
	if console == null:
		return
	console.register_command("flags", "flags — every story flag set and why.", _debug_flags)
	console.register_command("set_flag", "set_flag <flag_id> <reason...> — set a story flag (authored event stand-in).", _debug_set_flag)
	console.register_command("clear_flag", "clear_flag <flag_id> — clear a story flag.", _debug_clear_flag)


## Sets a flag because an authored event happened. Refused (false) without
## a reason. Setting an already-set flag is a no-op.
func set_flag(flag_id: StringName, reason: String) -> bool:
	if flag_id == &"" or reason.strip_edges() == "":
		push_error("Story: set_flag(%s) refused — a flag id and a reason are required" % flag_id)
		return false
	if _flags.has(flag_id):
		return false
	var clock := get_tree().root.get_node_or_null("Clock")
	var cycle := int(clock.get_cycles_elapsed()) if clock != null else -1
	_flags[flag_id] = {"reason": reason.strip_edges(), "cycle": cycle}
	var fact_log := get_tree().root.get_node_or_null("FactLog")
	if fact_log != null:
		var witnesses: Array[String] = []
		fact_log.record(FACT_STORY_FLAG, fact_log.SUBJECT_PLAYER, StringName(), witnesses, {"flag_id": str(flag_id), "reason": reason.strip_edges()}, cycle)
	var bus := get_tree().root.get_node_or_null("EventBus")
	if bus != null and bus.has_signal("story_flag_set"):
		bus.story_flag_set.emit(flag_id)
	return true


func has_flag(flag_id: StringName) -> bool:
	return _flags.has(flag_id)


func clear_flag(flag_id: StringName) -> bool:
	return _flags.erase(flag_id)


func get_flags() -> Dictionary:
	return _flags.duplicate(true)


func save_state() -> Dictionary:
	var out: Dictionary = {}
	for key: Variant in _flags.keys():
		out[str(key)] = (_flags[key] as Dictionary).duplicate()
	return {"flags": out}


func load_state(data: Dictionary) -> void:
	_flags.clear()
	var flags: Variant = data.get("flags", {})
	if typeof(flags) != TYPE_DICTIONARY:
		return
	for key: Variant in (flags as Dictionary).keys():
		var e: Variant = (flags as Dictionary)[key]
		if typeof(e) == TYPE_DICTIONARY:
			_flags[StringName(str(key))] = {"reason": str((e as Dictionary).get("reason", "")), "cycle": int((e as Dictionary).get("cycle", -1))}


func reset_all() -> void:
	_flags.clear()


func _debug_flags(_args: Array[String]) -> String:
	if _flags.is_empty():
		return "No story flags set."
	var lines: PackedStringArray = []
	for key: Variant in _flags.keys():
		lines.append("  %s — %s (cycle %d)" % [key, _flags[key]["reason"], int(_flags[key]["cycle"])])
	return "\n".join(lines)


func _debug_set_flag(args: Array[String]) -> String:
	if args.size() < 2:
		return "Usage: set_flag <flag_id> <reason...>"
	return "Set %s" % args[0] if set_flag(StringName(args[0]), " ".join(args.slice(1))) else "Not set (already set, or no reason)"


func _debug_clear_flag(args: Array[String]) -> String:
	if args.is_empty():
		return "Usage: clear_flag <flag_id>"
	return "Cleared %s" % args[0] if clear_flag(StringName(args[0])) else "No such flag"
