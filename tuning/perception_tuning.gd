extends Resource
## Build Bible Spec 17 tuning domain — loaded by TuningRegistry as
## "perception_tuning" (res://tuning/perception_tuning.tres). Canon §19
## keeps noise as DIRECTION and gives no numbers; these are playtesting
## starting points, in world pixels (16px tiles, 32px character).

## How far a loaded NPC can see a witnessable action (before line-of-sight
## and facing are also checked).
@export var sight_radius: float = 176.0

## How far a loaded NPC can hear one in an open zone.
@export var hearing_radius: float = 240.0

## Effective hearing radius multiplier when the NPC stands in a zone
## authored `enclosed = true` (the coarse interior/open flag — no
## obstruction geometry, per canon §19).
@export var enclosed_hearing_multiplier: float = 0.5

## Seconds during which the same NPC won't log a second fact for the same
## witnessable source — one fact per sustained action, not one per tick.
@export var witness_cooldown_seconds: float = 8.0
