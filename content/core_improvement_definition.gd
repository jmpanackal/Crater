extends Resource
## Build Bible Spec 14 Content Definition — one Core Improvement (canon
## §34: "foundational permanent improvements" that raise dependable baseline
## capability and do NOT consume a configurable Gear slot). Loaded by the
## Rig autoload from res://content/core_improvements/*.tres.
##
## This is how the Act 1 slot (3 -> 4 -> 5) and Capacity (3 -> 5 -> 8)
## progression canon §36 describes actually happens: each improvement adds
## to the tuned base. WHERE an improvement comes from is G6 (locked: mixed
## — some ordered, some restored from ship Components, some Forbidden) and
## belongs to those later specs; Rig only installs what it is told to.

## Stable id, matches this resource's filename (no extension) by convention.
@export var improvement_id: StringName = &""

@export var display_name: String = ""

@export_multiline var description: String = ""

## Extra configurable Gear slots this permanently adds.
@export var slot_bonus: int = 0

## Extra Rig Capacity this permanently adds.
@export var capacity_bonus: int = 0
