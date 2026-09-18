extends Node
## Krater core infrastructure — EventBus (autoload: EventBus).
## Build Bible Spec 01 (docs/build-bible/specs/01-core-infrastructure.md).
##
## Cross-cutting signals only; the bus holds no state of its own — if
## something needs to know "what's the current phase," it asks the Clock,
## not the bus. Local/tightly-coupled relationships (a UI panel listening to
## the district it displays, a player node listening to its own Rig) should
## use direct Godot signals instead. This bus is only for events genuinely
## cross-cutting enough that many unrelated systems need to observe them
## without a hard reference to the emitter.
##
## Typed signals, not one generic emit(name, payload) — Godot's own signal
## system already gives type safety and autocomplete for free.
##
## Signals are added incrementally as the systems that need them get built
## (see docs/build-bible/00-dependency-map.md build order). This file is
## deliberately not pre-declaring signals for systems that don't exist yet.
##
## Access via get_tree().root.get_node("EventBus") (no class_name on this
## autoload, matching the existing project convention — see resources.gd).

## A fact was appended to FactLog. Payload matches FactLog's record shape.
## Emitted by FactLog itself, not by whatever called FactLog.record().
signal fact_recorded(fact: Dictionary)

## The Clock (Build Bible Spec 04) advanced from one civic phase to the
## next. Fires exactly once per actual transition — a sleep-style advance
## spanning multiple phases fires this once per phase crossed, not once per
## request. old_phase/new_phase are Clock's PHASE_* StringName constants.
signal phase_changed(old_phase: StringName, new_phase: StringName)

## Terrain (Build Bible Spec 06) removed a tile. Push, not pull (Spec 06's
## own confirmed design choice): this is what future systems that don't
## exist yet (Perception's noise, Material extraction, the Fact Log) react
## to without Terrain needing to know who's listening. cell/direction are
## the dug cell and the cardinal direction it was dug from.
signal terrain_dug(cell: Vector2i, direction: Vector2i, is_firmament: bool, is_mouth: bool)

## SaveLoad lifecycle — cross-cutting because UI, debug tools, and future
## systems may all want to react to a save/load without depending on
## SaveLoad directly.
signal save_completed()
signal load_completed()

## Terrain (Build Bible Spec 12) exposed a deposit: digging opened a pocket
## and the Material is now visible and interactable, but NOT yet the
## player's (exposing and extracting are two distinct steps). Not emitted
## when a save restores an already-exposed deposit — that's restoration,
## not a new event.
signal deposit_exposed(cell: Vector2i, material_id: StringName)

## Terrain (Build Bible Spec 12) completed an extraction: the deposit is
## now depleted (finite, never regenerates) and `amount` of the Material
## has been handed to the player — through Hauling (Spec 13) once it
## exists, straight into Storage (Spec 11) until then.
signal material_extracted(material_id: StringName, amount: int, cell: Vector2i)

## Storage (Build Bible Spec 11) changed what the player holds. kind is
## Storage.KIND_MATERIAL or Storage.KIND_COMPONENT; new_count is the
## resulting total for that id (a Material's stored count, or how many
## instances of that Component are now owned). Cross-cutting because HUDs,
## Jobs settling a delivery, and the Capability Web all care without
## needing a reference to Storage.
signal storage_changed(kind: StringName, id: StringName, new_count: int)

## Hauling (Build Bible Spec 13): the towed bundle changed. amount is the
## bundle's new total for material_id; 0 means it was just released
## (deposited or cached) and material_id says what it held.
signal haul_changed(material_id: StringName, amount: int)

## Hauling (Build Bible Spec 13): a cache was created (exists = true) or
## picked back up (exists = false) at position.
signal cache_changed(position: Vector2, material_id: StringName, amount: int, exists: bool)

## Rig (Build Bible Spec 14): the loadout changed. change is one of Rig's
## CHANGE_* constants (equipped / unequipped / grafted / ungrafted / owned /
## core_installed / loaded) and id the Gear or Core Improvement involved
## (empty for a whole-state load). Cross-cutting because the systems that
## consume Gear effects (Hauling's bundle capacity/block, Terrain's quiet
## dig) need to re-derive without a reference to Rig.
signal rig_changed(change: StringName, id: StringName)

## CivicCycle (Build Bible Spec 15): a civic cycle just ended — fired
## exactly once per cycle, on the Clock's Ritual -> Rousing transition.
## `cycle` is the 0-based index of the cycle that ENDED. This is the
## district-resolution moment (canon §24); Districts (Spec 22) hang the
## actual economics off it.
signal cycle_resolved(cycle: int)

## CivicCycle (Build Bible Spec 15): the automatic Ritual attendance check
## ran for `cycle` as Ritual began. attended = false also means one
## `ritual_missed` fact was just logged.
signal ritual_checked(attended: bool, cycle: int)

## Terrain (Build Bible Spec 18): a dug cell's evidence state changed.
## exists = true when a restricted dig just left evidence (sealed_tier
## empty) or a seal completed (sealed_tier = the tier achieved);
## exists = false when the delta was reset. Purely informational — nothing
## is discovered by this event; discovery is a search (Evidence.resolve_search).
signal evidence_changed(cell: Vector2i, sealed_tier: StringName, exists: bool)

## Trust (Build Bible Spec 19): a reasoned Trust event was applied.
## standing is the resulting qualitative state id (never a raw number —
## that's what UI shows), delta the applied change, reason the required
## human-readable explanation to surface (§17: reasons, never "+3 Trust").
signal trust_changed(standing: StringName, delta: float, reason: String)

## Investigation (Build Bible Spec 20): a search was requested for a
## context (an NPC id, zone id, district id or incident id) — by the
## generic suspicion threshold or an authored trigger. Investigation
## resolves the WORLD half itself (Evidence.resolve_search); Homes (Spec
## 27) listens here to resolve a residence/workspace search.
signal search_requested(context: StringName, reason: String)

## Investigation (Build Bible Spec 20): the search for `context` resolved;
## found_count = how many pieces of real evidence it turned up (0 =
## found_nothing).
signal investigation_resolved(context: StringName, found_count: int)

## District (Build Bible Spec 22): a district's cycle resolution ran —
## once per district per civic cycle, on cycle_resolved. summary is the
## resolution record (output / served / surplus_banked /
## drawn_from_reserves / unmet / reserves_after / unexplained_loss /
## discrepancy_logged). Jobs (Spec 24) spawn emergency work off unmet > 0.
signal district_resolved(district_id: StringName, summary: Dictionary)

## District (Build Bible Spec 22): Capacity/Demand contributors, Reserves
## or the derived condition changed (a withdrawal, deposit, registration
## or resolution). condition is the live derived label id.
signal district_changed(district_id: StringName, condition: StringName)

## Wallet (Build Bible Spec 23): Tallies moved. balance is the new total,
## delta the change (negative for a spend), reason the required
## explanation — canon §16: Tallies stay understandable.
signal tallies_changed(balance: int, delta: int, reason: String)

## Orders (Build Bible Spec 23): an Approved Gear order succeeded — the
## Gear is now OWNED (Rig's list), not equipped.
signal gear_ordered(gear_id: StringName, district_id: StringName, tallies_spent: int, output_drawn: float)

## Jobs (Build Bible Spec 24): a job instance changed stage (offered /
## accepted / in_progress / settled).
signal job_changed(job_id: StringName, stage: StringName)

## Jobs (Build Bible Spec 24): a job settled — the single resolution
## point. record: outcome (poor/adequate/strong/exceptional/
## broken_commitment/unengaged), delivered/required, tallies paid,
## trust_delta submitted (0 if none), tier, work_type.
signal job_settled(job_id: StringName, record: Dictionary)

## CapabilityWeb (Build Bible Spec 25): a technology rose to a new level
## (known / understood) because a submitted discovery justified it.
## Available is derived and never announced — ask get_state().
signal technology_discovered(tech_id: StringName, level: StringName)

## Diversion (Build Bible Spec 26): one unit of a district's output was
## taken unrecorded and now rides on the player. Purely informational —
## Trust never moves from this; being seen is a witness fact.
signal diversion_taken(district_id: StringName, amount: int)

## Investigation (Build Bible Spec 27 fair warning): a context reached a
## tuned fraction of its search threshold — the "someone is asking
## questions" channel the world/UI should surface before any search.
signal investigation_warning(context: StringName, ratio: float)

## Homes (Build Bible Spec 27): the player moved into a residence tier.
signal residence_changed(tier: StringName)

## Homes (Build Bible Spec 27): a residence search found the concealed
## workspace's contraband (units confiscated). Serious, not game over.
signal workspace_discovered(units: int)

## Story (Build Bible Spec 27/31): an authored event set a story flag.
signal story_flag_set(flag_id: StringName)

## ForbiddenBuilds (Build Bible Spec 28): a Forbidden design was built and
## grafted at the workspace.
signal forbidden_built(design_id: StringName)

## ForbiddenBuilds (Build Bible Spec 28): an authority's examination
## exposed a graft. Serious; Trust already moved once.
signal graft_exposed(design_id: StringName)

## Projects (Build Bible Spec 29): a project's status or progress changed.
signal project_changed(project_id: StringName, status: StringName)

## Projects (Build Bible Spec 29): a project completed - its lasting
## effect (Capacity, maintenance Demand, story flag) is now in place. The
## world-facing change (a repaired lift, a new rope walk) keys off this.
signal project_completed(project_id: StringName, district_id: StringName)

## Rescue (Build Bible Spec 30): the derived failure state changed
## (none / strained / exhausted / stranded) — the telegraphing hook for
## breathing audio, warnings, the exhausted animation.
signal strain_state_changed(state: StringName)

## Rescue (Build Bible Spec 30): a severe fall happened (G22-B); the
## player woke at safe_pos with fatigue, lost time, and the haul cached.
signal severe_fall(fall_pos: Vector2, safe_pos: Vector2)

## Rescue (Build Bible Spec 30): the player was rescued. restricted =
## from a restricted zone; contraband_units = stolen output found on them.
signal rescued(forced: bool, restricted: bool, contraband_units: int)
