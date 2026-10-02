extends Resource
## Build Bible Spec 27 tuning domain — loaded by TuningRegistry as
## "homes_tuning" (res://tuning/homes_tuning.tres). Canon leaves residence
## requirements and concealment capacities OPEN; playtesting starts.

## Trust standing id required to acquire each tier ("" = none).
@export var mid_reach_min_trust: StringName = &"relied_on"
@export var ashram_min_trust: StringName = &"esteemed"

## Tallies price of each tier.
@export var mid_reach_tallies: int = 30
@export var ashram_tallies: int = 80

## Story flags required (Story autoload) — "story clearance".
@export var mid_reach_flag: StringName = &"mid_reach_clearance"
@export var ashram_flag: StringName = &"ashram_clearance"

## Tallies to improve workspace concealment one tier.
@export var improve_concealment_tallies: int = 15

## Trust delta when a home search finds the workspace with contraband,
## per unit found (capped).
@export var discovered_trust_delta_per_unit: float = -3.0
@export var discovered_trust_delta_cap: float = -18.0
