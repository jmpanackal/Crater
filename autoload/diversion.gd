extends Node
## Krater Diversion / Theft (autoload: Diversion).
## Build Bible Spec 26 (docs/build-bible/specs/26-diversion-theft.md — AI
## draft pending USER review).
##
## Systemic diversion of real District Output (canon §30): a hold-to-take
## at a district's physical store (G9-A) removes ONE unit per take from
## the district's Reserves through Spec 22's generic withdrawal with
## {"recorded": false} — served exactly like an Order, just never on the
## books, which is what the district's own accounting check notices
## later (G4-C). Every take also writes an `unexplained_loss` fact
## (G4-A). Taken units ride on the player (carried) until stashed at a
## workspace station into Storage's concealed stockpile (§47/§62).
##
## Detection is Spec 17's: the hold re-checks witnesses on every noise
## tick, so a quiet start is safe and a wanderer mid-hold can still catch
## it. Nothing here touches Trust — being caught is a witness fact that
## Investigation (Spec 20) turns into consequences.
##
## G5-C: return_output() gives units back to the district, openly (on
## the books) or anonymously (unrecorded).
##
## Access via get_tree().root.get_node("Diversion") (no class_name).

const TUNING_DOMAIN := "diversion_tuning"
const FACT_UNEXPLAINED_LOSS := &"unexplained_loss"
const FACT_THEFT_WITNESSED := &"theft_witnessed"

var _carried: Dictionary = {}  # district_id -> int


func _ready() -> void:
	var console := get_tree().root.get_node_or_null("DebugConsole")
	if console == null:
		return
	console.register_command("divert", "divert <district_id> — take one unit instantly (skips the hold; still unrecorded, still a fact).", _debug_divert)
	console.register_command("stash", "stash — stash carried stolen units at the workspace you're standing in.", _debug_stash)
	console.register_command("carried", "carried — stolen units on your person and in concealed storage.", _debug_carried)
	console.register_command("return_output", "return_output <district_id> <amount> [anon] — G5-C: return concealed units.", _debug_return)


func get_take_hold_seconds() -> float:
	var tuning := _tuning()
	return float(tuning.take_hold_seconds) if tuning != null else 1.6


func get_noise_tick_seconds() -> float:
	var tuning := _tuning()
	return float(tuning.noise_tick_seconds) if tuning != null else 0.5


func _tuning() -> Resource:
	var registry := get_tree().root.get_node_or_null("TuningRegistry")
	if registry == null:
		return null
	return registry.get_domain(TUNING_DOMAIN)


# --- Taking -------------------------------------------------------------------------

## {"ok": bool, "reason": String} — can one unit be taken from this
## district right now? Only Reserves matter (you can't steal what isn't
## there); witnesses are the hold's business.
func can_take(district_id: StringName) -> Dictionary:
	var district := get_tree().root.get_node_or_null("District")
	if district == null:
		return {"ok": false, "reason": "system_missing"}
	if not bool(district.is_known_district(district_id)):
		return {"ok": false, "reason": "unknown_district"}
	if float(district.get_reserves(district_id)) < 1.0:
		return {"ok": false, "reason": "nothing_to_take"}
	return {"ok": true, "reason": ""}


## A noise tick during the hold: the witness re-check (Spec 17). Returns
## who caught it this tick.
func noise_tick(district_id: StringName, world_pos: Vector2) -> Array[StringName]:
	var perception := get_tree().root.get_node_or_null("Perception")
	if perception == null:
		return []
	return perception.flag_witnessable("theft:%s" % str(district_id), world_pos, FACT_THEFT_WITNESSED, {"district_id": str(district_id)})


## Completes one take (the store node calls this when its hold finishes).
## One unrecorded unit out of Reserves, one carried unit on the player,
## one unexplained_loss fact. {"success", "reason"}.
func complete_take(district_id: StringName) -> Dictionary:
	var check := can_take(district_id)
	if not bool(check["ok"]):
		return {"success": false, "reason": str(check["reason"])}
	var district := get_tree().root.get_node_or_null("District")
	var granted := float(district.request_withdrawal(district_id, 1.0, {"recorded": false, "requester": "diversion"}))
	if granted < 1.0:
		return {"success": false, "reason": "nothing_to_take"}
	_carried[district_id] = int(_carried.get(district_id, 0)) + 1
	_record_loss(district_id, 1)
	var bus := get_tree().root.get_node_or_null("EventBus")
	if bus != null and bus.has_signal("diversion_taken"):
		bus.diversion_taken.emit(district_id, 1)
	return {"success": true, "reason": ""}


func get_carried(district_id: StringName) -> int:
	return int(_carried.get(district_id, 0))


func get_carried_total() -> int:
	var total := 0
	for key: Variant in _carried.keys():
		total += int(_carried[key])
	return total


func get_carried_snapshot() -> Dictionary:
	var out: Dictionary = {}
	for key: Variant in _carried.keys():
		if int(_carried[key]) > 0:
			out[str(key)] = int(_carried[key])
	return out


## Moves everything carried into Storage's concealed stockpile. Only at
## a workspace station (Spec 14's live list) — the crude Lower-home
## workspace counts (G8). Returns units stashed.
func stash_at_workspace() -> int:
	if not is_at_workspace():
		return 0
	var storage := get_tree().root.get_node_or_null("Storage")
	if storage == null or not storage.has_method("deposit_concealed"):
		return 0
	var stashed := 0
	for key: Variant in _carried.keys():
		var amount := int(_carried[key])
		if amount > 0 and bool(storage.deposit_concealed(key, amount)):
			stashed += amount
	_carried.clear()
	return stashed


func is_at_workspace() -> bool:
	var rig := get_tree().root.get_node_or_null("Rig")
	if rig == null or not rig.has_method("get_stations_in_range"):
		return false
	for station: Node in rig.get_stations_in_range():
		var kind: Variant = station.get("station_kind")
		if kind != null and StringName(str(kind)) == &"workspace":
			return true
	return false


## Confiscation on the person (a rescue or a search that finds what the
## player is carrying, Specs 27/30). Returns what was taken.
func confiscate_carried() -> Dictionary:
	var taken := get_carried_snapshot()
	_carried.clear()
	return taken


## G5-C: return concealed units to the district's Reserves. Anonymous =
## unrecorded (reality gains what the books never lost, so the next
## check's unexplained loss shrinks); open = on the books. Returns units
## actually accepted.
func return_output(district_id: StringName, amount: int, anonymous: bool = false) -> float:
	var storage := get_tree().root.get_node_or_null("Storage")
	var district := get_tree().root.get_node_or_null("District")
	if storage == null or district == null or amount <= 0:
		return 0.0
	if int(storage.get_concealed(district_id)) < amount:
		return 0.0
	# Either way the units physically come back UNRECORDED as a deposit (the
	# books never saw them leave, so a recorded deposit would inflate the
	# ledger); an OPEN return additionally explains the loss — a confession
	# the books can reconcile. An anonymous one just makes reality whole.
	var accepted := float(district.deposit(district_id, float(amount), {"recorded": false, "source": "returned_output", "anonymous": anonymous}))
	if accepted > 0.0:
		storage.withdraw_concealed(district_id, int(accepted))
		if not anonymous and district.has_method("explain_loss"):
			district.explain_loss(district_id, accepted)
	return accepted


func _record_loss(district_id: StringName, amount: int) -> void:
	var fact_log := get_tree().root.get_node_or_null("FactLog")
	var clock := get_tree().root.get_node_or_null("Clock")
	if fact_log == null:
		return
	var witnesses: Array[String] = []
	fact_log.record(FACT_UNEXPLAINED_LOSS, str(district_id), district_id, witnesses, {"district_id": str(district_id), "amount": amount}, int(clock.get_cycles_elapsed()) if clock != null else -1)


# --- Build Bible Spec 02 uniform SaveLoad contract --------------------------------------

func save_state() -> Dictionary:
	return {"carried": get_carried_snapshot()}


func load_state(data: Dictionary) -> void:
	_carried.clear()
	var carried: Variant = data.get("carried", {})
	if typeof(carried) == TYPE_DICTIONARY:
		for key: Variant in (carried as Dictionary).keys():
			_carried[StringName(str(key))] = int((carried as Dictionary)[key])


func reset_all() -> void:
	_carried.clear()


# --- Debug -------------------------------------------------------------------------------

func _debug_divert(args: Array[String]) -> String:
	if args.is_empty():
		return "Usage: divert <district_id>"
	var result := complete_take(StringName(args[0]))
	return "Took one unit of %s output (carried %d)" % [args[0], get_carried(StringName(args[0]))] if bool(result["success"]) else "Refused: %s" % result["reason"]


func _debug_stash(_args: Array[String]) -> String:
	var n := stash_at_workspace()
	return "Stashed %d unit(s)" % n if n > 0 else "Nothing stashed (not at a workspace, or nothing carried)"


func _debug_carried(_args: Array[String]) -> String:
	var storage := get_tree().root.get_node_or_null("Storage")
	var lines: PackedStringArray = []
	lines.append("Carried: %d" % get_carried_total())
	for key: Variant in _carried.keys():
		lines.append("  %s: %d on you" % [key, int(_carried[key])])
	if storage != null and storage.has_method("get_concealed_snapshot"):
		lines.append("Concealed at home: %s" % [storage.get_concealed_snapshot()])
	return "\n".join(lines)


func _debug_return(args: Array[String]) -> String:
	if args.size() < 2:
		return "Usage: return_output <district_id> <amount> [anon]"
	var anon := args.size() > 2 and args[2].to_lower().begins_with("anon")
	var accepted := return_output(StringName(args[0]), int(args[1]), anon)
	return "Returned %.0f to %s (%s)" % [accepted, args[0], "anonymously" if anon else "openly"]
