extends Node
## Krater Approved Gear Orders (autoload: Orders).
## Build Bible Spec 23 (docs/build-bible/specs/23-tallies-orders.md).
##
## The legitimate spend path (canon §28: work -> Tallies -> Order Approved
## Gear using Tallies + authorized District Output; Access/Trust may
## matter). Terminology is locked: "Approved Gear" is the category,
## "Order" is the action — never "Requisition".
##
## Confirmed choices, implemented literally:
## - Ordering acquires OWNERSHIP; it never equips (option A): on success
##   the item lands in Rig's owned-Gear list (Spec 14's own list, not a
##   second one); fitting it still takes Rig.equip() at a valid station.
## - A failed order is atomic with a distinct, explainable reason (option
##   A): insufficient Tallies, insufficient District Output, and a
##   district refusing for demand reasons are three different reasons,
##   and nothing is spent or partially drawn on any of them.
## - District Output is drawn through District.request_withdrawal() with
##   {"recorded": true} — an authorized, on-the-books draw, exactly the
##   same entry point Diversion (Spec 26) uses without the record.
##
## What a Gear costs is authored on its GearDefinition (order_district /
## order_tallies / order_output / order_min_trust); a definition with no
## order_district (grafts) isn't orderable. Owns no state of its own —
## Wallet owns Tallies, District owns Reserves, Rig owns ownership.
##
## Access via get_tree().root.get_node("Orders") (no class_name, matching
## the existing project convention — see resources.gd).

const REASON_UNKNOWN_GEAR := "unknown_gear"
const REASON_NOT_ORDERABLE := "not_orderable"
const REASON_ALREADY_OWNED := "already_owned"
const REASON_TRUST_TOO_LOW := "trust_too_low"
const REASON_INSUFFICIENT_TALLIES := "insufficient_tallies"
const REASON_INSUFFICIENT_OUTPUT := "insufficient_district_output"
const REASON_DISTRICT_REFUSED := "district_refused_for_demand"
const REASON_SYSTEM_MISSING := "system_missing"


func _ready() -> void:
	var console := get_tree().root.get_node_or_null("DebugConsole")
	if console == null:
		return
	console.register_command("orders", "orders — every orderable Approved Gear with price, district, Trust gate and whether you can order it now.", _debug_orders)
	console.register_command("order", "order <gear_id> — place an Approved Gear order (Tallies + authorized District Output).", _debug_order)


## The authored order terms for a Gear, or {} if it isn't orderable:
## {"district": StringName, "tallies": int, "output": float, "min_trust": StringName}.
func get_order_terms(gear_id: StringName) -> Dictionary:
	var rig := get_tree().root.get_node_or_null("Rig")
	if rig == null or not bool(rig.is_known_gear(gear_id)) or bool(rig.is_graft_design(gear_id)):
		return {}
	var info: Dictionary = rig.get_gear_info(gear_id)
	var district := StringName(str(info.get("order_district", "")))
	if district == &"":
		return {}
	return {
		"district": district,
		"tallies": maxi(0, int(info.get("order_tallies", 0))),
		"output": maxf(0.0, float(info.get("order_output", 0.0))),
		"min_trust": StringName(str(info.get("order_min_trust", ""))),
	}


func get_orderable_gear_ids() -> Array[StringName]:
	var out: Array[StringName] = []
	var rig := get_tree().root.get_node_or_null("Rig")
	if rig == null:
		return out
	for id: StringName in rig.get_gear_ids():
		if not get_order_terms(id).is_empty():
			out.append(id)
	return out


## Validates everything without touching anything. {"ok": bool, "reason": String}.
func can_order(gear_id: StringName) -> Dictionary:
	var rig := get_tree().root.get_node_or_null("Rig")
	var wallet := get_tree().root.get_node_or_null("Wallet")
	var district := get_tree().root.get_node_or_null("District")
	if rig == null or wallet == null or district == null:
		return {"ok": false, "reason": REASON_SYSTEM_MISSING}
	if not bool(rig.is_known_gear(gear_id)):
		return {"ok": false, "reason": REASON_UNKNOWN_GEAR}
	var terms := get_order_terms(gear_id)
	if terms.is_empty():
		return {"ok": false, "reason": REASON_NOT_ORDERABLE}
	if bool(rig.is_owned(gear_id)):
		return {"ok": false, "reason": REASON_ALREADY_OWNED}
	if not _trust_allows(terms["min_trust"]):
		return {"ok": false, "reason": REASON_TRUST_TOO_LOW}
	if not bool(wallet.can_afford(int(terms["tallies"]))):
		return {"ok": false, "reason": REASON_INSUFFICIENT_TALLIES}
	var district_id: StringName = terms["district"]
	if not bool(district.is_known_district(district_id)):
		return {"ok": false, "reason": REASON_NOT_ORDERABLE}
	var output := float(terms["output"])
	if output > 0.0:
		# Canon §25: a district may refuse an otherwise-affordable order when
		# its output is needed for essential demand — a believable civic
		# constraint, surfaced distinctly from "you can't afford it".
		if _district_refuses(district, district_id):
			return {"ok": false, "reason": REASON_DISTRICT_REFUSED}
		if float(district.get_reserves(district_id)) < output:
			return {"ok": false, "reason": REASON_INSUFFICIENT_OUTPUT}
	return {"ok": true, "reason": ""}


## Places the order: spends Tallies, draws authorized District Output
## (recorded), adds the Gear to Rig's owned list — never equips. Atomic:
## any failed check returns its reason with nothing spent.
## {"success", "reason", "tallies_spent", "output_drawn"}.
func order(gear_id: StringName) -> Dictionary:
	var check := can_order(gear_id)
	if not bool(check["ok"]):
		return {"success": false, "reason": str(check["reason"]), "tallies_spent": 0, "output_drawn": 0.0}
	var rig := get_tree().root.get_node_or_null("Rig")
	var wallet := get_tree().root.get_node_or_null("Wallet")
	var district := get_tree().root.get_node_or_null("District")
	var terms := get_order_terms(gear_id)
	var display := str(rig.get_gear_display_name(gear_id))
	var district_name := str(district.get_display_name(terms["district"]))
	var output := float(terms["output"])
	var drawn := 0.0
	if output > 0.0:
		drawn = float(district.request_withdrawal(terms["district"], output, {"recorded": true, "requester": "order", "gear_id": str(gear_id)}))
		if drawn < output:
			# Can't happen after can_order's reserve check, but keep the
			# contract atomic if it ever does: give the district back its units.
			if drawn > 0.0:
				district.deposit(terms["district"], drawn, {"recorded": true, "source": "order_rollback"})
			return {"success": false, "reason": REASON_INSUFFICIENT_OUTPUT, "tallies_spent": 0, "output_drawn": 0.0}
	var price := int(terms["tallies"])
	if price > 0 and not bool(wallet.spend(price, "Ordered %s from %s" % [display, district_name])):
		if drawn > 0.0:
			district.deposit(terms["district"], drawn, {"recorded": true, "source": "order_rollback"})
		return {"success": false, "reason": REASON_INSUFFICIENT_TALLIES, "tallies_spent": 0, "output_drawn": 0.0}
	rig.add_owned_gear(gear_id)
	var bus := get_tree().root.get_node_or_null("EventBus")
	if bus != null and bus.has_signal("gear_ordered"):
		bus.gear_ordered.emit(gear_id, terms["district"], price, drawn)
	return {"success": true, "reason": "", "tallies_spent": price, "output_drawn": drawn}


func _trust_allows(min_trust: StringName) -> bool:
	if min_trust == &"":
		return true
	var trust := get_tree().root.get_node_or_null("Trust")
	if trust == null or not trust.has_method("get_standing_ladder"):
		return true
	var ladder: Array[Dictionary] = trust.get_standing_ladder()
	var current: StringName = trust.get_trust()
	var current_rank := -1
	var needed_rank := -1
	for i in range(ladder.size()):
		if ladder[i]["id"] == current:
			current_rank = i
		if ladder[i]["id"] == min_trust:
			needed_rank = i
	if needed_rank < 0:
		return true  # an unknown standing id gates nothing rather than everything
	return current_rank >= needed_rank


## A district in Shortage or worse is keeping every unit for essential
## demand; below that it serves orders from what it actually has.
func _district_refuses(district: Node, district_id: StringName) -> bool:
	return float(district.get_health(district_id)) < 0.0


# --- Debug -----------------------------------------------------------------------------------

func _debug_orders(_args: Array[String]) -> String:
	var rig := get_tree().root.get_node_or_null("Rig")
	var lines: PackedStringArray = []
	for id: StringName in get_orderable_gear_ids():
		var terms := get_order_terms(id)
		var check := can_order(id)
		lines.append("  %s — %d Tallies + %.1f %s output%s: %s" % [
			rig.get_gear_display_name(id), int(terms["tallies"]), float(terms["output"]), terms["district"],
			"" if terms["min_trust"] == &"" else " (needs %s)" % terms["min_trust"],
			"orderable" if bool(check["ok"]) else str(check["reason"]),
		])
	return "No orderable Approved Gear." if lines.is_empty() else "\n".join(lines)


func _debug_order(args: Array[String]) -> String:
	if args.is_empty():
		return "Usage: order <gear_id>"
	var result := order(StringName(args[0]))
	if not bool(result["success"]):
		return "Order refused: %s" % result["reason"]
	return "Ordered %s — %d Tallies, %.1f output drawn; it's owned, not equipped (equip at a station)." % [args[0], int(result["tallies_spent"]), float(result["output_drawn"])]
