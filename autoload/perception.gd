extends Node
## Krater Perception (sight + noise) + Witness (autoload: Perception).
## Build Bible Spec 17 (docs/build-bible/specs/17-perception-witness.md).
##
## Turns a witnessable player action into a FACT, per canon §19's
## detection model and the dependency map's contract: "perception and
## witness systems only write facts." This is the sight/sound half;
## persistent evidence is Spec 18's.
##
## Confirmed choices, implemented literally:
## - Action-triggered, never a per-frame scan (option A): the OWNING system
##   calls flag_witnessable() at the moment something witnessable happens
##   (Terrain for a restricted dig; later Diversion for a theft hold,
##   Access for a restricted entry). Perception is agnostic to WHY — it
##   only answers "did anyone loaded nearby see or hear this." Deciding
##   whether an action qualifies is the caller's job; a call for something
##   that shouldn't be witnessable is a caller bug, not guarded here.
##   Sustained actions re-call this at intervals (once per noise tick);
##   the cooldown below is what keeps that from spamming facts.
## - Sight = radius + line-of-sight raycast + facing (option A).
## - Sound = radius + one coarse enclosed/open flag on the NPC's zone, no
##   obstruction geometry (option A; canon §19: not an acoustics sim).
##   Facing never blocks sound.
## - One fact per witnessing NPC (option A): `witnesses: [npc_id]`, so a
##   specific NPC can later be asked what THEY saw (Spec 21).
## - Per-(NPC, source) cooldown (option A): continuous restricted mining
##   witnessed by the same NPC logs one fact, not one per tick.
##
## Only LOADED NPCs perceive (G14 / Spec 16): candidates come from
## Npcs.is_agent_loaded(); off-screen scheduled presence never runs a
## live check. Forbidden Gear is a hard exclusion (Spec 20): nothing here
## is ever called for a graft — there is no code path for it by design.
##
## Owns only transient cooldown timestamps — not saved, re-derives itself
## as actions occur.
##
## Access via get_tree().root.get_node("Perception") (no class_name,
## matching the existing project convention — see resources.gd).

const TUNING_DOMAIN := "perception_tuning"
const WORLD_COLLISION_MASK := 1

const SENSE_SIGHT := &"sight"
const SENSE_SOUND := &"sound"

## Fact type Terrain uses for a restricted (Firmament) dig — canon §19's
## "excavated restricted wall" example.
const FACT_EXCAVATED_RESTRICTED_WALL := &"excavated_restricted_wall"

## (source_id -> (npc_id -> msec last logged)).
var _cooldowns: Dictionary = {}


func _ready() -> void:
	var console := get_tree().root.get_node_or_null("DebugConsole")
	if console == null:
		return
	console.register_command("perception", "perception — loaded NPCs and their distance/sight/hearing to the player.", _debug_perception)
	console.register_command("witness_test", "witness_test [x y] — flag a test witnessable action at the player (or x y) and report who caught it.", _debug_witness_test)


# --- Tuning ---------------------------------------------------------------------

func get_sight_radius() -> float:
	var tuning := _tuning()
	return float(tuning.sight_radius) if tuning != null else 176.0


func get_hearing_radius() -> float:
	var tuning := _tuning()
	return float(tuning.hearing_radius) if tuning != null else 240.0


func get_enclosed_hearing_multiplier() -> float:
	var tuning := _tuning()
	return float(tuning.enclosed_hearing_multiplier) if tuning != null else 0.5


func get_witness_cooldown_seconds() -> float:
	var tuning := _tuning()
	return float(tuning.witness_cooldown_seconds) if tuning != null else 8.0


func _tuning() -> Resource:
	var registry := get_tree().root.get_node_or_null("TuningRegistry")
	if registry == null:
		return null
	return registry.get_domain(TUNING_DOMAIN)


# --- The contract --------------------------------------------------------------------

## The one entry point. Runs the sight and sound checks for every loaded
## NPC against `position`; on a hit with a clear cooldown, appends one
## fact per witnessing NPC to the Fact Log. Returns the ids that
## witnessed it THIS call (empty = nobody; not an error).
##
## context is merged into the fact's context (e.g. {"cell": ...}) so the
## fact stands on its own later without re-querying anyone's live state.
func flag_witnessable(source_id: String, position: Vector2, fact_type: StringName, context: Dictionary = {}) -> Array[StringName]:
	var caught: Array[StringName] = []
	var npcs := get_tree().root.get_node_or_null("Npcs")
	if npcs == null:
		return caught
	for npc_id: StringName in npcs.get_npc_ids():
		if not bool(npcs.is_agent_loaded(npc_id)):
			continue
		var body := npcs.get_agent(npc_id) as Node2D
		if body == null:
			continue
		var sense := _perceive(npc_id, body, position)
		if sense == &"":
			continue
		if _on_cooldown(source_id, npc_id):
			continue
		_mark(source_id, npc_id)
		_record(npc_id, body, sense, source_id, position, fact_type, context)
		caught.append(npc_id)
	return caught


## Which sense (if any) lets this body perceive `position`: sight first,
## then sound. &"" = neither.
func _perceive(npc_id: StringName, body: Node2D, position: Vector2) -> StringName:
	if can_see(body, position):
		return SENSE_SIGHT
	if can_hear(npc_id, body, position):
		return SENSE_SOUND
	return &""


## Sight: within sight radius, roughly facing it, and a clear raycast to
## it through world collision (layer 1). The player body is on layer 1
## too but is never "in the way" of seeing what the player is doing.
func can_see(body: Node2D, position: Vector2) -> bool:
	var eye := _eye_of(body)
	if eye.distance_to(position) > get_sight_radius():
		return false
	if not _is_facing(body, eye, position):
		return false
	return has_line_of_sight(eye, position)


## Sound: within the hearing radius, shrunk by the tuned multiplier when
## the NPC's current zone is authored enclosed. Facing is irrelevant.
func can_hear(npc_id: StringName, body: Node2D, position: Vector2) -> bool:
	return _eye_of(body).distance_to(position) <= get_effective_hearing_radius(npc_id)


func get_effective_hearing_radius(npc_id: StringName) -> float:
	var radius := get_hearing_radius()
	var npcs := get_tree().root.get_node_or_null("Npcs")
	var zones := get_tree().root.get_node_or_null("Zones")
	if npcs != null and zones != null:
		var zone_id := str(npcs.get_current_zone(npc_id))
		if zone_id != "" and bool(zones.is_zone_enclosed(zone_id)):
			radius *= get_enclosed_hearing_multiplier()
	return radius


## Facing cone: the body's get_facing_sign() (-1 left / +1 right) must
## point toward the target horizontally. Straight above/below (|dx| tiny)
## counts as visible from either facing. A body with no facing method is
## treated as facing everything.
func _is_facing(body: Node2D, eye: Vector2, position: Vector2) -> bool:
	if not body.has_method("get_facing_sign"):
		return true
	var dx := position.x - eye.x
	if absf(dx) <= 8.0:
		return true
	return signf(dx) == signf(float(body.get_facing_sign()))


func has_line_of_sight(from: Vector2, to: Vector2) -> bool:
	if not is_inside_tree():
		return true
	var space := get_viewport().get_world_2d().direct_space_state if get_viewport() != null else null
	if space == null:
		return true
	var query := PhysicsRayQueryParameters2D.create(from, to, WORLD_COLLISION_MASK)
	query.collide_with_areas = false
	query.collide_with_bodies = true
	var hit := space.intersect_ray(query)
	if hit.is_empty():
		return true
	var collider: Variant = hit.get("collider", null)
	if collider is Node and ((collider as Node).is_in_group("player") or (collider as Node).name == "Player"):
		return true
	# Hitting exactly at the target (the dug cell's own neighbor rock,
	# say) is still a sight of the spot; only something clearly BEFORE the
	# target blocks.
	var hit_pos: Vector2 = hit.get("position", to)
	return hit_pos.distance_to(to) <= 4.0


## NPC bodies have their origin at the feet; look from roughly head height.
func _eye_of(body: Node2D) -> Vector2:
	return body.global_position + Vector2(0, -24)


# --- Cooldowns ------------------------------------------------------------------------

func _on_cooldown(source_id: String, npc_id: StringName) -> bool:
	var per_npc: Variant = _cooldowns.get(source_id, null)
	if per_npc == null:
		return false
	var last: Variant = (per_npc as Dictionary).get(npc_id, null)
	if last == null:
		return false
	return float(Time.get_ticks_msec() - int(last)) / 1000.0 < get_witness_cooldown_seconds()


func _mark(source_id: String, npc_id: StringName) -> void:
	if not _cooldowns.has(source_id):
		_cooldowns[source_id] = {}
	(_cooldowns[source_id] as Dictionary)[npc_id] = Time.get_ticks_msec()


## Forget a source's cooldowns — e.g. when the NPC loses and regains
## sight/hearing of it, or when the sustained action ends for good.
func clear_cooldowns(source_id: String = "") -> void:
	if source_id == "":
		_cooldowns.clear()
	else:
		_cooldowns.erase(source_id)


# --- Facts ------------------------------------------------------------------------------

func _record(npc_id: StringName, body: Node2D, sense: StringName, source_id: String, position: Vector2, fact_type: StringName, context: Dictionary) -> void:
	var fact_log := get_tree().root.get_node_or_null("FactLog")
	if fact_log == null or not fact_log.has_method("record"):
		return
	var npcs := get_tree().root.get_node_or_null("Npcs")
	var clock := get_tree().root.get_node_or_null("Clock")
	var location := StringName(str(npcs.get_current_zone(npc_id))) if npcs != null else StringName()
	var cycle := int(clock.get_cycles_elapsed()) if clock != null else -1
	var witnesses: Array[String] = [str(npc_id)]
	var full_context := context.duplicate(true)
	full_context["npc_id"] = str(npc_id)
	full_context["sense"] = str(sense)
	full_context["source_id"] = source_id
	full_context["position"] = [position.x, position.y]
	full_context["witness_position"] = [body.global_position.x, body.global_position.y]
	if clock != null:
		full_context["phase"] = str(clock.get_phase())
	fact_log.record(fact_type, fact_log.SUBJECT_PLAYER, location, witnesses, full_context, cycle)


# --- Debug -------------------------------------------------------------------------------

func _debug_perception(_args: Array[String]) -> String:
	var npcs := get_tree().root.get_node_or_null("Npcs")
	var player := get_tree().get_first_node_in_group("player") as Node2D
	if npcs == null:
		return "Npcs autoload missing."
	var lines: PackedStringArray = []
	lines.append("sight %.0f, hearing %.0f (enclosed x%.2f), cooldown %.1fs" % [get_sight_radius(), get_hearing_radius(), get_enclosed_hearing_multiplier(), get_witness_cooldown_seconds()])
	for npc_id: StringName in npcs.get_npc_ids():
		if not bool(npcs.is_agent_loaded(npc_id)):
			lines.append("  %s: off-screen" % npc_id)
			continue
		var body := npcs.get_agent(npc_id) as Node2D
		if player == null:
			lines.append("  %s: loaded at %s" % [npc_id, body.global_position])
			continue
		var target := player.global_position
		lines.append("  %s: %.0fpx — sees %s, hears %s (hearing radius %.0f)" % [
			npc_id, _eye_of(body).distance_to(target), can_see(body, target), can_hear(npc_id, body, target), get_effective_hearing_radius(npc_id),
		])
	return "\n".join(lines)


func _debug_witness_test(args: Array[String]) -> String:
	var position := Vector2.ZERO
	if args.size() >= 2:
		position = Vector2(float(args[0]), float(args[1]))
	else:
		var player := get_tree().get_first_node_in_group("player") as Node2D
		if player == null:
			return "No player in the scene — pass x y."
		position = player.global_position
	var caught := flag_witnessable("debug_witness_test_%d" % Time.get_ticks_msec(), position, &"debug_witnessed", {"debug": true})
	if caught.is_empty():
		return "Nobody loaded saw or heard %s." % position
	return "Witnessed at %s by: %s (one fact each)" % [position, ", ".join(PackedStringArray(caught))]
