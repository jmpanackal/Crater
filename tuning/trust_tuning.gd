extends Resource
## Build Bible Spec 19 tuning domain — loaded by TuningRegistry as
## "trust_tuning" (res://tuning/trust_tuning.tres). Standing-state
## thresholds live HERE, not in trust.gd (Spec 19, confirmed option A).
## Canon §17: roughly 4–5 qualitative standing states, exact names and
## internal values tunable; these are playtesting starting points.

@export var default_trust: float = 50.0
@export var min_trust: float = 0.0
@export var max_trust: float = 100.0

## How many recent reasons the display log keeps (§17: "surface recent
## important events", not dozens of permanent modifiers — the permanent
## record is the Fact Log).
@export var reasons_capacity: int = 8

## Standing states, ascending: standing_ids[i] applies when the internal
## value is >= standing_thresholds[i] (and below the next threshold).
## Both arrays must be the same length; the first threshold should be
## min_trust so every value maps to a state.
@export var standing_ids: Array[StringName] = [&"distrusted", &"doubted", &"accepted", &"relied_on", &"esteemed"]
@export var standing_labels: Array[String] = ["Distrusted", "Doubted", "Accepted", "Relied on", "Esteemed"]
@export var standing_thresholds: Array[float] = [0.0, 25.0, 45.0, 70.0, 90.0]
