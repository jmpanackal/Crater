extends Resource
## Build Bible Spec 18 tuning domain — loaded by TuningRegistry as
## "evidence_tuning" (res://tuning/evidence_tuning.tres). The spec locks
## the shape (material-gated, tiered, hold-to-seal) and leaves the numbers
## open; these are playtesting starting points.

## How long the seal hold-to-interact takes.
@export var seal_hold_seconds: float = 1.5

## Radius (world px) a position-based resolve_search() covers.
@export var search_radius: float = 96.0
