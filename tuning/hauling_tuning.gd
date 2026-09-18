extends Resource
## Build Bible Spec 13 tuning domain — loaded by TuningRegistry as
## "hauling_tuning" (res://tuning/hauling_tuning.tres). Exact numbers are
## OPEN per mechanics-canon.md; these are playtesting starting points.

## Units of a single Material one bundle can hold (G13: one bundle, one
## type). More simultaneous capacity comes from Hauling-dimension Gear
## (Spec 14), not from raising this.
@export var bundle_capacity: int = 4

## Stamina blocked per unit carried (Spec 08 "hauling" block source).
@export var stamina_block_per_unit: float = 8.0

## Loaded-movement speed multiplier at a FULL bundle; scales linearly from
## 1.0 (empty) to this (full) — G1 option C: distance costs civic time.
@export var loaded_speed_min_multiplier: float = 0.55

## Stamina spent by each strenuous traversal while loaded — a jump or a
## ladder grab (G1 option A). Unloaded, those stay free.
@export var strenuous_action_cost: float = 10.0
