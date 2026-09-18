extends Node
## Krater Hauling + Tether + Caches (autoload: Hauling).
## Build Bible Spec 13 (docs/build-bible/specs/13-hauling.md).
##
## Bulk Materials as something physically carried (canon §7). Owns the
## one towed bundle and the player's caches — the dependency map's
## "Hauled loads, tether attachments" row.
##
## Locked rules this implements literally:
## - One bundle, one Material type, up to a tuned capacity (G13, option A);
##   more capacity is Hauling-dimension Gear's job (Spec 14), not this file's.
## - Hauling BLOCKS stamina (Spec 08): attaching requests the "hauling"
##   block sized by units carried; depositing, delivering or caching
##   releases exactly that block and no other.
## - Loaded movement is slower, scaled by load (G1 option C); jumps and
##   ladder grabs become strenuous while loaded (G1 option A) — the player
##   controller reads get_movement_speed_multiplier()/
##   get_strenuous_action_cost() and applies them itself (Spec 07, option A:
##   Hauling never reaches into the controller).
## - Caches are optional, local, player-created stashes — never a global
##   inventory. Created anywhere in a dig front's frontier (its envelope or
##   approach corridor), never inside the Hollow's civic geography; an
##   invalid spot fails cleanly with a reason, same shape as an invalid dig.
##
## Spec 12 seam: Terrain.complete_extraction() hands extracted Material to
## attach() now that this exists (and refuses to deplete a deposit the
## player can't carry). deposit_at_storage() is what finally turns the
## physical load into Storage's abstract count (Spec 11).
##
## Tether PHYSICS is spike-owned per the spec — the trailing bundle here is
## a readable placeholder stand-in that satisfies the contract (reads as
## towed, works through this API), not the spike's answer.
##
## Access via get_tree().root.get_node("Hauling") (no class_name, matching
## the existing project convention — see resources.gd).

const TUNING_DOMAIN := "hauling_tuning"
const CacheNodeScript := preload("res://cache_node.gd")

var _material_id: StringName = &""
var _amount: int = 0

## Each entry: {"uid": int, "position": Vector2, "material_id": StringName, "amount": int}.
var _caches: Array[Dictionary] = []
var _next_cache_uid: int = 1
var _cache_nodes: Dictionary = {}  # uid -> CacheNode

var _bundle: Node2D
var _bundle_side := 1.0


func _ready() -> void:
	var console := get_tree().root.get_node_or_null("DebugConsole")
	if console == null:
		return
	console.register_command("haul", "haul <material_id> <amount> — attach a bundle directly.", _debug_haul)
	console.register_command("cache_here", "cache_here — cache the current bundle at the player's position.", _debug_cache_here)
	console.register_command("caches", "caches — list every cache and the current load.", _debug_caches)


## Build Bible Spec 14: Hauling-dimension Gear changes the bundle capacity
## and the block per unit (see get_bundle_capacity/get_block_per_unit), so
## the block on a load already in tow must be re-derived whenever the Rig
## changes — the hauling block is still Hauling's own request, sized by
## Hauling; Rig never touches Stamina's "hauling" slot.
func _on_rig_changed(_change: StringName, _id: StringName) -> void:
	if is_loaded():
		_apply_block()


func _enter_tree() -> void:
	var bus := get_tree().root.get_node_or_null("EventBus")
	if bus != null and bus.has_signal("rig_changed") and not bus.rig_changed.is_connected(_on_rig_changed):
		bus.rig_changed.connect(_on_rig_changed)


func _process(delta: float) -> void:
	_ensure_cache_nodes()
	_update_bundle_visual(delta)


# --- Tuning -----------------------------------------------------------------

## Tuned base, plus whatever Hauling-dimension Gear adds (Build Bible Spec
## 14: Rig.EFFECT_HAULING_CAPACITY — e.g. the Counterweight Frame). Reads
## the Rig's effect total through its API; never Rig's block state.
func get_bundle_capacity() -> int:
	var tuning := _tuning()
	var base := int(tuning.bundle_capacity) if tuning != null else 4
	return maxi(1, base + int(round(_rig_effect(&"hauling_capacity_bonus"))))


## Tuned base per unit, reduced by Gear that "reduces the severity of the
## hauling stamina block" (canon §65 Load Harness; Spec 14
## Rig.EFFECT_HAULING_BLOCK_REDUCTION, a fraction, clamped so the block can
## never go negative — no Gear raises maximum stamina).
func get_block_per_unit() -> float:
	var tuning := _tuning()
	var base := float(tuning.stamina_block_per_unit) if tuning != null else 8.0
	return base * clampf(1.0 - _rig_effect(&"hauling_block_reduction"), 0.0, 1.0)


func _rig_effect(effect_id: StringName) -> float:
	var rig := get_tree().root.get_node_or_null("Rig") if is_inside_tree() else null
	if rig == null or not rig.has_method("get_effect_sum"):
		return 0.0
	return float(rig.get_effect_sum(effect_id))


func get_loaded_speed_min_multiplier() -> float:
	var tuning := _tuning()
	return float(tuning.loaded_speed_min_multiplier) if tuning != null else 0.55


func get_strenuous_action_cost() -> float:
	var tuning := _tuning()
	return float(tuning.strenuous_action_cost) if tuning != null else 10.0


func _tuning() -> Resource:
	var registry := get_tree().root.get_node_or_null("TuningRegistry")
	if registry == null:
		return null
	return registry.get_domain(TUNING_DOMAIN)


# --- The bundle --------------------------------------------------------------

func is_loaded() -> bool:
	return _amount > 0


## {"material_id": StringName, "amount": int} — amount 0 when unloaded.
func get_load() -> Dictionary:
	return {"material_id": _material_id, "amount": _amount}


## One bundle, one type, up to capacity — and only known Materials.
func can_attach(material_id: StringName, amount: int) -> bool:
	if amount <= 0:
		return false
	var storage := get_tree().root.get_node_or_null("Storage")
	if storage != null and not bool(storage.is_known_material(material_id)):
		return false
	if is_loaded() and _material_id != material_id:
		return false
	return _amount + amount <= get_bundle_capacity()


## Begins (or adds to) towing. Requests the stamina block. False, no
## mutation, if the bundle can't take it.
func attach(material_id: StringName, amount: int) -> bool:
	if not can_attach(material_id, amount):
		return false
	_material_id = material_id
	_amount += amount
	_apply_block()
	_emit_haul_changed()
	return true


## The load becomes an abstract stored count (Spec 11) and the block is
## released. Position is not checked here — the world-side trigger is a
## StorageAccess interactable (Spec 10), which is what gates "at storage".
func deposit_at_storage() -> bool:
	if not is_loaded():
		return false
	var storage := get_tree().root.get_node_or_null("Storage")
	if storage == null or not bool(storage.deposit_material(_material_id, _amount)):
		return false
	var id := _material_id
	_clear_load()
	_emit_haul_changed_for(id)
	return true


## Movement speed multiplier for the player controller: 1.0 empty, down to
## the tuned minimum at a full bundle.
func get_movement_speed_multiplier() -> float:
	if not is_loaded():
		return 1.0
	var t := clampf(float(_amount) / float(maxi(1, get_bundle_capacity())), 0.0, 1.0)
	return lerpf(1.0, get_loaded_speed_min_multiplier(), t)


# --- Caches -------------------------------------------------------------------

## Spec 13 boundary check. Until Spec 05's zone data is authored (it is
## what will eventually distinguish frontier from Hollow-interior zones),
## the frontier is: the dig envelope's open (already dug) cells, plus the
## approach corridor between the Hollow's right cliff and the envelope.
## Anything west of that — the Hollow's civic geography — is invalid, as
## is un-dug rock (a cache needs a non-blocking spot).
## Returns {"valid": bool, "reason": String}.
func is_valid_cache_position(world_pos: Vector2) -> Dictionary:
	var terrain := _terrain()
	if terrain == null:
		return {"valid": false, "reason": "no_frontier_here"}
	var cell: Vector2i = terrain.world_to_cell(world_pos)
	if bool(terrain.is_within_dig_envelope(cell)):
		if bool(terrain.has_tile(cell)):
			return {"valid": false, "reason": "blocked_by_rock"}
		return {"valid": true, "reason": ""}
	var approach_start: float = HollowLayout.HOLLOW_RIGHT
	var envelope_start := float(terrain.DIG_START_X) * float(terrain.TILE_SIZE)
	if world_pos.x >= approach_start and world_pos.x < envelope_start:
		return {"valid": true, "reason": ""}
	return {"valid": false, "reason": "hollow_civic_space"}


## Drops the current bundle as a cache at a player-chosen spot. Same
## result shape as Terrain.dig(): {"success": bool, "reason": String,
## "uid": int}. Fails cleanly for an invalid spot or an empty bundle.
func cache_at(world_pos: Vector2) -> Dictionary:
	if not is_loaded():
		return {"success": false, "reason": "nothing_to_cache", "uid": -1}
	var check := is_valid_cache_position(world_pos)
	if not bool(check["valid"]):
		return {"success": false, "reason": str(check["reason"]), "uid": -1}
	var uid := _next_cache_uid
	_next_cache_uid += 1
	var record := {"uid": uid, "position": world_pos, "material_id": _material_id, "amount": _amount}
	_caches.append(record)
	var id := _material_id
	var amount := _amount
	_clear_load()
	_ensure_cache_nodes()
	_emit_haul_changed_for(id)
	_emit_cache_changed(world_pos, id, amount, true)
	return {"success": true, "reason": "", "uid": uid}


## Picks a cache back up into the bundle. Fails if the bundle can't take it
## (wrong type loaded / no room) — the cache stays exactly where it was.
func retrieve_cache(uid: int) -> Dictionary:
	var index := _cache_index(uid)
	if index < 0:
		return {"success": false, "reason": "no_such_cache"}
	var record: Dictionary = _caches[index]
	var id: StringName = record["material_id"]
	var amount: int = int(record["amount"])
	if not attach(id, amount):
		return {"success": false, "reason": "cannot_carry"}
	_caches.remove_at(index)
	_free_cache_node(uid)
	_emit_cache_changed(record["position"], id, amount, false)
	return {"success": true, "reason": ""}


func get_caches() -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	for record: Dictionary in _caches:
		out.append(record.duplicate())
	return out


func get_cache_node(uid: int) -> Node:
	var node: Variant = _cache_nodes.get(uid, null)
	if node == null or not is_instance_valid(node):
		return null
	return node


func _cache_index(uid: int) -> int:
	for i in range(_caches.size()):
		if int(_caches[i]["uid"]) == uid:
			return i
	return -1


## Cache markers live in the play scene (under the Terrain node), which
## doesn't exist yet when a save loads at startup — so markers are spawned
## lazily whenever a record has no live node and a world parent exists.
func _ensure_cache_nodes() -> void:
	if _caches.is_empty():
		return
	var parent := _terrain()
	if parent == null:
		return
	for record: Dictionary in _caches:
		var uid := int(record["uid"])
		if get_cache_node(uid) != null:
			continue
		var node: Area2D = CacheNodeScript.new()
		node.setup(self, uid, record["material_id"], int(record["amount"]))
		parent.add_child(node)
		node.global_position = record["position"]
		_cache_nodes[uid] = node


func _free_cache_node(uid: int) -> void:
	var node: Variant = _cache_nodes.get(uid, null)
	_cache_nodes.erase(uid)
	if node != null and is_instance_valid(node):
		(node as Node).queue_free()


func _free_all_cache_nodes() -> void:
	for key: Variant in _cache_nodes.keys():
		var node: Variant = _cache_nodes[key]
		if node != null and is_instance_valid(node):
			(node as Node).queue_free()
	_cache_nodes.clear()


# --- Internals ----------------------------------------------------------------

func _clear_load() -> void:
	_material_id = &""
	_amount = 0
	_apply_block()
	if _bundle != null and is_instance_valid(_bundle):
		_bundle.visible = false


func _apply_block() -> void:
	var stamina := get_tree().root.get_node_or_null("Stamina")
	if stamina == null:
		return
	if is_loaded():
		stamina.request_block(stamina.SOURCE_HAULING, float(_amount) * get_block_per_unit())
	else:
		stamina.release_block(stamina.SOURCE_HAULING)


func _terrain() -> Node:
	return get_tree().get_first_node_in_group("terrain")


func _player() -> Node2D:
	return get_tree().get_first_node_in_group("player") as Node2D


func _emit_haul_changed() -> void:
	_emit_haul_changed_for(_material_id)


func _emit_haul_changed_for(material_id: StringName) -> void:
	var bus := get_tree().root.get_node_or_null("EventBus")
	if bus != null:
		bus.haul_changed.emit(material_id, _amount)


func _emit_cache_changed(position: Vector2, material_id: StringName, amount: int, exists: bool) -> void:
	var bus := get_tree().root.get_node_or_null("EventBus")
	if bus != null:
		bus.cache_changed.emit(position, material_id, amount, exists)


## Readable towed-bundle stand-in: a small load that trails the player on
## the side they're moving away from, lerped so it drags rather than snaps.
func _update_bundle_visual(delta: float) -> void:
	var player := _player()
	if player == null:
		return
	if _bundle == null or not is_instance_valid(_bundle):
		_bundle = Node2D.new()
		_bundle.name = "HaulBundle"
		_bundle.z_index = 2
		var load_rect := ColorRect.new()
		load_rect.name = "Load"
		load_rect.size = Vector2(12, 9)
		load_rect.position = Vector2(-6, -9)
		load_rect.color = Color(0.62, 0.46, 0.28, 0.95)
		load_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_bundle.add_child(load_rect)
		var tether := ColorRect.new()
		tether.name = "Tether"
		tether.size = Vector2(1.0, 1.0)
		tether.color = Color(0.5, 0.42, 0.3, 0.7)
		tether.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_bundle.add_child(tether)
		player.add_child(_bundle)
		_bundle.position = Vector2(16, 30)
	_bundle.visible = is_loaded()
	if not is_loaded():
		return
	if player is CharacterBody2D:
		var vx := (player as CharacterBody2D).velocity.x
		if absf(vx) > 5.0:
			_bundle_side = -signf(vx)
	var target := Vector2(16.0 + 18.0 * _bundle_side, 30.0)
	_bundle.position = _bundle.position.lerp(target, clampf(8.0 * delta, 0.0, 1.0))
	var tether := _bundle.get_node_or_null("Tether") as ColorRect
	if tether != null:
		var anchor := Vector2(16.0, 24.0) - _bundle.position
		tether.position = Vector2(0, -6)
		tether.size = Vector2(maxf(1.0, anchor.length()), 1.0)
		tether.rotation = anchor.angle()


# --- Build Bible Spec 02 uniform SaveLoad contract ----------------------------

func save_state() -> Dictionary:
	var caches: Array = []
	for record: Dictionary in _caches:
		var p: Vector2 = record["position"]
		caches.append({
			"uid": int(record["uid"]),
			"position": [p.x, p.y],
			"material_id": str(record["material_id"]),
			"amount": int(record["amount"]),
		})
	return {
		"load": {"material_id": str(_material_id), "amount": _amount},
		"caches": caches,
		"next_cache_uid": _next_cache_uid,
	}


func load_state(data: Dictionary) -> void:
	_free_all_cache_nodes()
	_caches.clear()
	var load: Variant = data.get("load", {})
	_material_id = &""
	_amount = 0
	if typeof(load) == TYPE_DICTIONARY:
		var amount := int((load as Dictionary).get("amount", 0))
		var id := StringName(str((load as Dictionary).get("material_id", "")))
		if amount > 0 and id != &"":
			_material_id = id
			_amount = amount
	_apply_block()
	var caches: Variant = data.get("caches", [])
	var highest := 0
	if typeof(caches) == TYPE_ARRAY:
		for entry: Variant in (caches as Array):
			if typeof(entry) != TYPE_DICTIONARY:
				continue
			var e: Dictionary = entry
			var pos_arr: Variant = e.get("position", null)
			if typeof(pos_arr) != TYPE_ARRAY or (pos_arr as Array).size() != 2:
				continue
			var uid := int(e.get("uid", 0))
			highest = maxi(highest, uid)
			_caches.append({
				"uid": uid,
				"position": Vector2(float(pos_arr[0]), float(pos_arr[1])),
				"material_id": StringName(str(e.get("material_id", ""))),
				"amount": int(e.get("amount", 0)),
			})
	_next_cache_uid = maxi(int(data.get("next_cache_uid", 1)), highest + 1)
	if _bundle != null and is_instance_valid(_bundle):
		_bundle.visible = is_loaded()
	_ensure_cache_nodes()


func reset_all() -> void:
	_free_all_cache_nodes()
	_caches.clear()
	_next_cache_uid = 1
	_clear_load()


func _debug_haul(args: Array[String]) -> String:
	if args.size() < 2:
		return "Usage: haul <material_id> <amount>"
	var id := StringName(args[0])
	var amount := int(args[1])
	if not attach(id, amount):
		return "Can't attach %d %s — bundle holds %s x%d, capacity %d, one type at a time." % [amount, id, _material_id, _amount, get_bundle_capacity()]
	return "Hauling %s x%d" % [_material_id, _amount]


func _debug_cache_here(_args: Array[String]) -> String:
	var player := _player()
	if player == null:
		return "No player in the scene."
	var result := cache_at(player.global_position + Vector2(16, 32))
	if not bool(result["success"]):
		return "Can't cache here: %s" % result["reason"]
	return "Cached as #%d" % int(result["uid"])


func _debug_caches(_args: Array[String]) -> String:
	var lines: PackedStringArray = []
	lines.append("Load: %s x%d" % [_material_id if is_loaded() else &"(empty)", _amount])
	for record: Dictionary in _caches:
		lines.append("#%d  %s x%d  at %s" % [int(record["uid"]), record["material_id"], int(record["amount"]), record["position"]])
	return "\n".join(lines)
