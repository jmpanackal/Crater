extends Resource
## Build Bible Spec 09 tuning domain — loaded by TuningRegistry as
## "fatigue_tuning" (res://tuning/fatigue_tuning.tres). Exact value is
## OPEN per mechanics-canon.md — a reasonable playtesting starting point,
## not a design lock.

## Fixed fatigue added per Overexertion instance (Spec 09, confirmed
## option A) — NOT scaled to how far past zero the triggering action went.
@export var overexertion_fatigue_cost: float = 15.0
