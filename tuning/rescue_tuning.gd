extends Resource
## Build Bible Spec 30 tuning domain — loaded by TuningRegistry as
## "rescue_tuning" (res://tuning/rescue_tuning.tres). Canon §54 leaves
## exact costs open; playtesting starts.

## Fatigue added by a severe fall (G22-B).
@export var fall_fatigue: float = 20.0

## Civic phases of lost time a severe fall costs (0 = none).
@export var fall_lost_phases: int = 1

## Seconds of being stranded (Exhausted outside the Hollow) before a
## rescue becomes mandatory.
@export var stranded_grace_seconds: float = 45.0

## Fatigue left after a rescue (partial recovery: rescuers get you home,
## they don't rest you).
@export var fatigue_after_rescue: float = 30.0

## Trust delta when rescuers find stolen output on the player.
@export var contraband_found_trust_delta: float = -8.0
