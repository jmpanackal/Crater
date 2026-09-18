extends Resource
## Build Bible Spec 21 tuning domain — loaded by TuningRegistry as
## "dialogue_tuning" (res://tuning/dialogue_tuning.tres).

## Trust delta submitted when a trust-relevant claim is exposed as a lie.
## Canon §18: "exposed lies can damage Trust more than simply admitting
## the truth" — so this is meant to sit below the honest-admission cost
## of the same incident (tuned elsewhere as those incidents land).
@export var exposed_lie_trust_delta: float = -12.0
