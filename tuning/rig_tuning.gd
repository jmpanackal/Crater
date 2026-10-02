extends Resource
## Build Bible Spec 14 tuning domain — loaded by TuningRegistry as
## "rig_tuning" (res://tuning/rig_tuning.tres). Canon §35/§36 leave exact
## capacity values, the strain formula, threshold behavior, and any
## absolute limit OPEN; these are playtesting starting points.

## Configurable Gear slots before any Core Improvement (canon §36
## DIRECTION: 3 -> 4 -> 5 through Act 1; the steps are Core Improvements).
@export var base_slots: int = 3

## Rig Capacity before any Core Improvement (canon §36 DIRECTION:
## 3 -> 5 -> 8 through Act 1).
@export var base_capacity: int = 3

## Stamina blocked per point of overcapacity (Spec 08 "rig_strain" block
## source). Linear: strain = overcapacity * this. §35 lists linear vs.
## stepped as its own OPEN question — this is the simplest contract that
## satisfies "greater overcapacity creates greater strain", not a claim
## that the question is settled.
@export var strain_block_per_overcapacity: float = 15.0
