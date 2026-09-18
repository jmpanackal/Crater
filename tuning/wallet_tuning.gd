extends Resource
## Build Bible Spec 23 tuning domain — loaded by TuningRegistry as
## "wallet_tuning" (res://tuning/wallet_tuning.tres).

## Tallies a new game starts with.
@export var starting_tallies: int = 0

## How many recent earn/spend reasons the display log keeps (mirrors
## Trust's reasons window; the permanent record is the Fact Log).
@export var reasons_capacity: int = 8
