extends Resource
## Build Bible Spec 12 Content Definition — the authored deposit pockets of
## one dig envelope. Loaded by TerrainLayer from
## res://content/deposits/*.tres.
##
## Canon (§5, materials.md): most broken rock yields nothing; Materials
## come from finite, environmentally-logical resource pockets that never
## regenerate. Pocket placement is level content, so it lives here as data
## — a pocket is added or moved by editing a file, never terrain.gd.

## Which dig envelope these pockets belong to. Only "east" exists today
## (the west site is deferred — see CONTEXT.md's macro-layout entry).
@export var envelope_id: StringName = &"east"

## Each entry: {"cell": Vector2i, "material_id": StringName, "amount": int,
## "note": String}. cell is a TerrainLayer map cell inside the envelope;
## note is the environmental logic (damp cavity, impact strata, ship
## fracture...) — documentation for authors, never read by code.
@export var pockets: Array[Dictionary] = []
