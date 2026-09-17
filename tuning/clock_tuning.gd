extends Resource
## Build Bible Spec 04 tuning domain — loaded by TuningRegistry as
## "clock_tuning" (res://tuning/clock_tuning.tres). Exact values are OPEN
## per mechanics-canon.md — G11 only locks "~30-40 real minutes, Working
## about half" as a DIRECTION. These are a reasonable playtesting starting
## point, not a design lock.

## Real-world minutes for one full civic cycle (all four phases combined).
@export var cycle_length_minutes: float = 35.0

## Fraction of the cycle spent in each phase. Should sum to 1.0 — Clock
## doesn't enforce that itself, but a mis-tuned split just makes phases
## the wrong relative length rather than breaking anything structurally.
@export var rousing_proportion: float = 0.15
@export var working_proportion: float = 0.5
@export var gathering_proportion: float = 0.2
@export var ritual_proportion: float = 0.15
