extends Resource
## Build Bible Spec 32 tuning domain — loaded by TuningRegistry as
## "firmament_tuning" (res://tuning/firmament_tuning.tres). Canon: the
## Firmament is a sustained multi-session problem; exact numbers open.

## Firmament cells dug for Partial breach.
@export var partial_breach_cells: int = 24

## Firmament cells dug for Breached.
@export var breach_cells: int = 64

## Story flag an authored moment sets to foreshadow the Firmament.
@export var foreshadow_flag: StringName = &"firmament_foreshadowed"

## Story flag set on Breached (the Act 1 ending beat's hook).
@export var breached_flag: StringName = &"firmament_breached"
