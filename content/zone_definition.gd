extends Resource
## Build Bible Spec 05 Content Definition — one authored zone (Home Court,
## Lower Switchback, West Dispatch Yard, Bottom-West, Mid Heart, ...).
## Loaded by the Zones autoload from res://content/zones/*.tres.
##
## Granularity is locked (Spec 05, option C): one zone per
## player-recognizable named location from the opening route, not the
## chunk-atlas's 2x2 composition-slot grid — that grid stays a design/art
## reference tool, not a runtime loading boundary.

## Stable id, matches this resource's filename (no extension) by convention
## — the same convention TuningRegistry and Content Definitions generally
## use, so a zone can be added by adding a file, not editing a script.
@export var zone_id: StringName = &""

@export var display_name: String = ""

## This zone's origin in shared Hollow world space.
@export var world_origin: Vector2 = Vector2.ZERO

## This zone's shared edges with other zones. Each entry: {"edge": "north"|
## "south"|"east"|"west", "neighbor": <zone_id>, "position": <float>} —
## position is the shared coordinate along that edge (world-space x for a
## vertical north/south-facing seam... concretely, an x position for an
## east/west seam, a y position for a north/south seam). Both zones on a
## seam must list each other with a matching position — that reciprocity
## is what Zones.validate_seams() checks (Spec 05: "a validated contract,
## not manual alignment").
@export var seams: Array[Dictionary] = []

## Build Bible Spec 17's coarse sound model: an enclosed/interior zone
## (a bay cut into rock, a workshop, a basin) dampens hearing — its
## effective hearing radius shrinks by the tuned multiplier. An open zone
## (a deck across the Mouth) doesn't. Deliberately a single flag, not
## obstruction geometry — canon §19: "not intended to become an acoustics
## simulation."
@export var enclosed: bool = false
