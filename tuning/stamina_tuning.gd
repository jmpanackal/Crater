extends Resource
## Build Bible Spec 08 tuning domain — loaded by TuningRegistry as
## "stamina_tuning" (res://tuning/stamina_tuning.tres). Exact values are
## OPEN per mechanics-canon.md — this is a reasonable playtesting starting
## point, not a design lock. (Spec 01 itself anticipated this exact
## resource by name as its worked example for a tuning domain.)

@export var max_stamina: float = 100.0

## Stamina regenerated per second while not actively suppressed (walking
## doesn't block regen; a sustained strenuous action like sprinting does,
## via Stamina.pause_regen()).
@export var regen_rate: float = 20.0
