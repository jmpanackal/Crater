extends Resource
## Build Bible Spec 26 tuning domain — loaded by TuningRegistry as
## "diversion_tuning" (res://tuning/diversion_tuning.tres).

## Hold-to-take duration for ONE unit (G9-A: each take takes time).
@export var take_hold_seconds: float = 1.6

## How often, during the hold, the take re-checks for witnesses (a noise
## tick — Spec 17's interval re-check).
@export var noise_tick_seconds: float = 0.5

## OPEN (G9-A): carried stolen units above this would become a physical
## haul load. Not enforced in the thin slice; recorded here so the number
## has a home.
@export var carry_threshold_open: int = 4
