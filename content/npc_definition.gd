extends Resource
## Build Bible Spec 16 Content Definition — one NPC agent and its schedule
## (G14, locked option A: abstract off-screen schedules — one location per
## civic phase; off-screen the NPC simply "is" there). Loaded by the Npcs
## autoload from res://content/npcs/*.tres.
##
## Schedule entries name ZONES, never coordinates (Spec 16, confirmed
## option A): "at glowbeds during working". The exact spot inside the zone
## comes from that zone's marked idle points (zone_anchor.gd in the scene),
## so reshaping a zone never silently breaks every NPC scheduled there.

## Stable id, matches this resource's filename (no extension) by convention.
@export var npc_id: StringName = &""

@export var display_name: String = ""

## Which district this person works for (flavor / later Jobs + Trust use).
@export var district_id: StringName = &""

## Fallback zone for any phase the schedule doesn't list.
@export var home_zone: String = ""

## Phase name (Clock.PHASE_* as a String key: "rousing" / "working" /
## "gathering" / "ritual") -> zone_id. Four slots per G14.
@export var schedule: Dictionary = {}
