extends Resource
## Build Bible Spec 11 Content Definition — one bulk Material (canon §3–§8,
## docs/materials.md). Loaded by the Storage autoload from
## res://content/materials/*.tres.
##
## The Act 1 roster is LOCKED (Sutral, Ravelstone, Brinecrystal, Verdigris,
## Hullbit) and lives here as data so a Material is added or reworded by
## editing a file, never a script — and so retired names (Sporemeal,
## Lampwick, ...) simply don't exist as far as Storage is concerned.

## Stable id, matches this resource's filename (no extension) by convention.
@export var material_id: StringName = &""

@export var display_name: String = ""

## What it physically is.
@export_multiline var description: String = ""

## What finding it implies about the surrounding geology — canon's "clue
## value" column. Materials are clues as well as stock.
@export_multiline var clue_hint: String = ""
