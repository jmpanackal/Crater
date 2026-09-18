extends Resource
## Build Bible Spec 28 tuning domain — loaded by TuningRegistry as
## "forbidden_tuning" (res://tuning/forbidden_tuning.tres).

## Civic cycles a major fabrication should consume (canon §47: no
## real-time timers; major illegal fabrication may consume civic time).
## 0 = immediate — the thin slice's setting.
@export var fabrication_cycles: int = 0

## Tallies to improve a graft's concealment one tier at the workspace.
@export var conceal_graft_tallies: int = 12

## Trust delta when an authority's examination exposes a graft.
@export var graft_exposed_trust_delta: float = -20.0
