extends Resource
## Build Bible Spec 12 tuning domain — loaded by TuningRegistry as
## "extraction_tuning" (res://tuning/extraction_tuning.tres).
##
## Per-Material extraction differentiation (timing, effort, flavor) is
## canon-OPEN and Spec 12 explicitly says it belongs here once playtested,
## not in the spec. One shared hold time for now; when a Material needs
## its own, add a per-id override field here, not a constant in code.

## Seconds the Interact input must be held to finish extracting a deposit.
## Releasing earlier cancels with no partial state (Spec 12 failure case).
@export var hold_seconds: float = 1.2
