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
