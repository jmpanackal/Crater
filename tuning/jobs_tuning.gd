extends Resource
## Build Bible Spec 24 tuning domain — loaded by TuningRegistry as
## "jobs_tuning" (res://tuning/jobs_tuning.tres). Tier scaling, grade
## thresholds and Trust deltas are all playtesting starting points.

## Tallies multiplier per tier: reward * (1 + tier * this).
@export var tier_pay_multiplier: float = 0.5

## Trust delta for a broken Commitment/Duty at tier 0; scaled by
## (1 + tier * tier_penalty_multiplier). Negative.
@export var broken_commitment_trust_delta: float = -6.0
@export var tier_penalty_multiplier: float = 0.5

## Trust delta for an exceptional (above-and-beyond) outcome, any type.
@export var exceptional_trust_delta: float = 3.0

## Grade thresholds on delivered / required: >= exceptional_ratio ->
## exceptional; >= 1.0 -> strong; >= adequate_ratio -> adequate; else poor.
@export var exceptional_ratio: float = 1.5
@export var adequate_ratio: float = 0.5

## G5-B: temporary Capacity an emergency job grants its district on a
## strong-or-better completion, and for how many resolutions.
@export var emergency_capacity_amount: float = 2.0
@export var emergency_capacity_cycles: int = 2
