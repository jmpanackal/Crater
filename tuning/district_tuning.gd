extends Resource
## Build Bible Spec 22 tuning domain — loaded by TuningRegistry as
## "district_tuning" (res://tuning/district_tuning.tres). Canon §24–§26
## leave the numeric scale and condition thresholds open; these are
## playtesting starting points.

## Condition ladder, DESCENDING by health, where health =
## (Capacity + Reserves - Demand) / max(Demand, 1): the district's whole
## buffer beyond one cycle's need, in cycles of demand. A district whose
## Capacity + Reserves can't meet Demand (health < 0) is in Shortage;
## deep below is Critical. Canon §26 DIRECTION names; exact tunable.
@export var condition_ids: Array[StringName] = [&"comfortable", &"stable", &"strained", &"shortage", &"critical"]
@export var condition_labels: Array[String] = ["Comfortable", "Stable", "Strained", "Shortage", "Critical"]
@export var condition_min_health: Array[float] = [1.0, 0.25, 0.0, -0.5, -1000000.0]

## G4-C: unexplained loss (units) since the last check that a
## COMFORTABLE district notices. Multiplied per condition below — a
## strained district notices smaller losses sooner ("storage checks
## increase").
@export var discrepancy_threshold: float = 3.0
@export var discrepancy_multiplier_by_condition: Dictionary = {
	"comfortable": 1.0, "stable": 0.8, "strained": 0.5, "shortage": 0.34, "critical": 0.25,
}
