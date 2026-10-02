extends Node
## Krater Physical Evidence (autoload: Evidence).
## Build Bible Spec 18 (docs/build-bible/specs/18-physical-evidence.md).
##
## The "cold case" half of detection (canon §19): a persistent trace of
## restricted excavation that stays discoverable after the fact, whether or
## not anyone was there to see it (Spec 17 handles that half; the same dig
## can produce both).
##
## This autoload OWNS NO STATE. Confirmed option A: evidence is a flag on
## Terrain's own dug-cell delta, not a second registry — Terrain tags a
## restricted dig `evidence` at dig time, persists it with its other
## deltas, and resolves seals/searches against it. This file is the
## stable entry point Investigation (Spec 20), the seal interactable and
## the debug console use so none of them has to find the Terrain node:
## every call forwards to the live TerrainLayer (group "terrain").
##
## Confirmed choices, implemented literally:
## - Discovery is investigation-triggered, never ambient (option A):
##   evidence alerts nobody by existing. resolve_search() is called by an
##   investigation/scripted search and returns what it actually finds;
##   logging `found_evidence` facts from that is Investigation's job.
## - Concealment is material-gated, a real action, and tiered (option B):
##   seal(position, kit_id) is a hold-to-interact (Spec 10 shape, same as
##   extraction) that CONSUMES a seal-kit Component (Spec 11) and records
##   the tier it achieved — canon §62's qualitative Basic / Improved /
##   Advanced, reused, not a fourth model. A search must BEAT the tier
##   (strictly stronger) to find sealed evidence. Which tier a kit gives is
##   authored on the Component (`seal_tier`); Secrecy Gear can raise it
##   (Rig.EFFECT_SEAL_TIER_BONUS).
##
## Access via get_tree().root.get_node("Evidence") (no class_name,
## matching the existing project convention — see resources.gd).

const TUNING_DOMAIN := "evidence_tuning"

## Concealment tiers, ascending. TIER_NONE = exposed (unsealed) evidence.
const TIER_NONE := &""
const TIER_BASIC := &"basic"
const TIER_IMPROVED := &"improved"
const TIER_ADVANCED := &"advanced"
const TIER_ORDER: Array[StringName] = [TIER_NONE, TIER_BASIC, TIER_IMPROVED, TIER_ADVANCED]


func _ready() -> void:
	var console := get_tree().root.get_node_or_null("DebugConsole")
	if console == null:
		return
	console.register_command("evidence", "evidence — every flagged dig delta and its concealment tier.", _debug_evidence)
	console.register_command("search_here", "search_here [tier] — resolve a search around the player at the given search tier (default basic).", _debug_search_here)
	console.register_command("seal_here", "seal_here — instantly seal the nearest exposed evidence with the best kit owned (skips the hold).", _debug_seal_here)


# --- Tiers ------------------------------------------------------------------------------

## 0 = exposed, 1 = Basic, 2 = Improved, 3 = Advanced; unknown = 0.
func tier_rank(tier: StringName) -> int:
	return maxi(0, TIER_ORDER.find(tier))


func tier_from_rank(rank: int) -> StringName:
	return TIER_ORDER[clampi(rank, 0, TIER_ORDER.size() - 1)]


## Does a search of `search_tier` find evidence sealed at `sealed_tier`?
## Exposed evidence is always found; sealed evidence only by a strictly
## stronger search.
func search_beats(search_tier: StringName, sealed_tier: StringName) -> bool:
	if sealed_tier == TIER_NONE:
		return true
	return tier_rank(search_tier) > tier_rank(sealed_tier)


## The tier a seal-kit Component achieves before Gear — authored on the
## Component definition (Spec 11); &"" if it isn't a seal kit.
func kit_tier(component_id: StringName) -> StringName:
	var storage := get_tree().root.get_node_or_null("Storage")
	if storage == null or not storage.has_method("get_component_field"):
		return TIER_NONE
	var tier := StringName(str(storage.get_component_field(component_id, "seal_tier", "")))
	return tier if TIER_ORDER.has(tier) and tier != TIER_NONE else TIER_NONE


func is_seal_kit(component_id: StringName) -> bool:
	return kit_tier(component_id) != TIER_NONE


## The tier a seal with this kit would actually achieve right now: the
## kit's tier plus any Secrecy Gear bonus, capped at Advanced.
func achievable_tier(component_id: StringName) -> StringName:
	var base := kit_tier(component_id)
	if base == TIER_NONE:
		return TIER_NONE
	var bonus := 0
	var rig := get_tree().root.get_node_or_null("Rig")
	if rig != null and rig.has_method("get_effect_sum"):
		bonus = int(round(float(rig.get_effect_sum(&"seal_tier_bonus"))))
	return tier_from_rank(tier_rank(base) + maxi(0, bonus))


## Owned seal kits, best tier first (ids, one entry per owned instance).
func get_owned_kits() -> Array[StringName]:
	var out: Array[StringName] = []
	var storage := get_tree().root.get_node_or_null("Storage")
	if storage == null:
		return out
	for id: StringName in storage.get_component_ids():
		if not is_seal_kit(id):
			continue
		for _i in range(int(storage.count_components(id))):
			out.append(id)
	out.sort_custom(func(a: StringName, b: StringName) -> bool: return tier_rank(achievable_tier(a)) > tier_rank(achievable_tier(b)))
	return out


# --- Tuning -------------------------------------------------------------------------------

func get_seal_hold_seconds() -> float:
	var tuning := _tuning()
	return float(tuning.seal_hold_seconds) if tuning != null else 1.5


func get_search_radius() -> float:
	var tuning := _tuning()
	return float(tuning.search_radius) if tuning != null else 96.0


func _tuning() -> Resource:
	var registry := get_tree().root.get_node_or_null("TuningRegistry")
	if registry == null:
		return null
	return registry.get_domain(TUNING_DOMAIN)


# --- Forwarded contract (Terrain owns the data) ----------------------------------------------

func _terrain() -> Node:
	return get_tree().get_first_node_in_group("terrain")


## Everything currently flagged: [{"cell": Vector2i, "position": Vector2,
## "sealed_tier": StringName, "zone_id": String}].
func get_all_evidence() -> Array[Dictionary]:
	var terrain := _terrain()
	if terrain == null or not terrain.has_method("get_evidence_records"):
		return []
	return terrain.get_evidence_records()


## The flagged delta at a world position, or {} if that cell holds none.
func get_evidence_at(world_pos: Vector2) -> Dictionary:
	var terrain := _terrain()
	if terrain == null or not terrain.has_method("get_evidence_info"):
		return {}
	return terrain.get_evidence_info(terrain.world_to_cell(world_pos))


## Called by Investigation (Spec 20) in response to a search-requested
## event. `target` is a zone_id (String) — every flagged cell inside that
## zone's footprint — or a world position (Vector2) — every flagged cell
## within the tuned search radius. Returns only what the search actually
## finds: exposed evidence, plus sealed evidence whose tier it beats. A
## clean or well-concealed area returns [] — not an error.
func resolve_search(target: Variant, search_tier: StringName = TIER_BASIC) -> Array[Dictionary]:
	var found: Array[Dictionary] = []
	var zones := get_tree().root.get_node_or_null("Zones")
	for record: Dictionary in get_all_evidence():
		var in_scope := false
		if typeof(target) == TYPE_STRING or typeof(target) == TYPE_STRING_NAME:
			in_scope = zones != null and str(zones.get_zone_at(record["position"])) == str(target)
		elif typeof(target) == TYPE_VECTOR2:
			in_scope = (record["position"] as Vector2).distance_to(target) <= get_search_radius()
		if in_scope and search_beats(search_tier, record["sealed_tier"]):
			found.append(record)
	return found


## Completes a seal at a world position with a specific kit — the hold
## itself is seal_node.gd's; this is the state change. Result shape
## matches the rest of the Build Bible: {"success", "reason", "tier"}.
func seal(world_pos: Vector2, kit_id: StringName) -> Dictionary:
	var terrain := _terrain()
	if terrain == null or not terrain.has_method("complete_seal"):
		return {"success": false, "reason": "no_terrain", "tier": TIER_NONE}
	return terrain.complete_seal(terrain.world_to_cell(world_pos), kit_id)


# --- Debug -----------------------------------------------------------------------------------

func _debug_evidence(_args: Array[String]) -> String:
	var records := get_all_evidence()
	if records.is_empty():
		return "No flagged evidence."
	var lines: PackedStringArray = []
	for r: Dictionary in records:
		var tier: StringName = r["sealed_tier"]
		lines.append("  %s at %s in '%s' — %s" % [r["cell"], r["position"], r["zone_id"], "EXPOSED" if tier == TIER_NONE else "sealed (%s)" % tier])
	return "%d flagged:\n%s" % [records.size(), "\n".join(lines)]


func _debug_search_here(args: Array[String]) -> String:
	var player := get_tree().get_first_node_in_group("player") as Node2D
	if player == null:
		return "No player in the scene."
	var tier := TIER_BASIC
	if not args.is_empty():
		tier = StringName(args[0].to_lower())
		if not TIER_ORDER.has(tier) or tier == TIER_NONE:
			return "Unknown tier '%s' — expected basic, improved or advanced" % args[0]
	var found := resolve_search(player.global_position, tier)
	if found.is_empty():
		return "A %s search around %s finds nothing." % [tier, player.global_position]
	var cells: PackedStringArray = []
	for r: Dictionary in found:
		cells.append(str(r["cell"]))
	return "A %s search finds %d: %s" % [tier, found.size(), ", ".join(cells)]


func _debug_seal_here(_args: Array[String]) -> String:
	var player := get_tree().get_first_node_in_group("player") as Node2D
	if player == null:
		return "No player in the scene."
	var kits := get_owned_kits()
	if kits.is_empty():
		return "No seal kit owned (add_component seal_kit)."
	var nearest: Dictionary = {}
	var best := INF
	for r: Dictionary in get_all_evidence():
		if r["sealed_tier"] != TIER_NONE:
			continue
		var d := (r["position"] as Vector2).distance_to(player.global_position)
		if d < best:
			best = d
			nearest = r
	if nearest.is_empty():
		return "No exposed evidence anywhere."
	var result := seal(nearest["position"], kits[0])
	if not bool(result["success"]):
		return "Seal refused: %s" % result["reason"]
	return "Sealed %s with %s at tier %s" % [nearest["cell"], kits[0], result["tier"]]
