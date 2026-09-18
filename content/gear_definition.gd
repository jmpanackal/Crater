extends Resource
## Build Bible Spec 14 Content Definition — one piece of Gear (canon §34–§36,
## §65, §67). Loaded by the Rig autoload from res://content/gear/*.tres, so
## adding Gear is adding a file, never editing a script (Spec 01's own
## acceptance test for Content Definitions names Gear specifically).
##
## Two kinds share this one schema, because canon says there is no separate
## mechanical Forbidden category (§67): an "approved" definition is worn
## equipment that fills a configurable Gear slot; a "graft" is Forbidden
## Gear fused into the body — it uses NO slot and draws only on Rig
## Capacity. Both pay capacity_cost into the same soft-limit pool.

## Stable id, matches this resource's filename (no extension) by convention.
@export var gear_id: StringName = &""

@export var display_name: String = ""

@export_multiline var description: String = ""

## "approved" (worn, fills a slot) or "graft" (bio-fusion, no slot). See
## Rig.KIND_APPROVED / Rig.KIND_GRAFT.
@export var kind: StringName = &"approved"

## Functional category — canon §36 DIRECTION only (Tool / Rig / Utility).
## Informational for now: hard category-to-slot restrictions are explicitly
## "not yet locked", so Spec 14 treats slots as generic and never enforces
## this field. Kept so the data is already there when that lock lands.
@export var category: StringName = &"tool"

## How much Rig Capacity this draws while equipped/grafted (§35). Exceeding
## Capacity is legal and creates Rig Strain — a soft limit, never a refusal.
@export var capacity_cost: int = 1

## What it does, as effect_id -> number, summed across everything active by
## Rig.get_effect_sum(). Consumers read the ids Rig declares as EFFECT_*
## constants; an id nothing consumes yet is simply inert data.
@export var effects: Dictionary = {}
