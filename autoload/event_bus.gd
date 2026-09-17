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

## SaveLoad lifecycle — cross-cutting because UI, debug tools, and future
## systems may all want to react to a save/load without depending on
## SaveLoad directly.
signal save_completed()
signal load_completed()
