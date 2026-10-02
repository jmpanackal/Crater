extends Resource
## Build Bible Spec 29 Content Definition — one district or civic project
## (canon §26). Loaded by the Projects autoload from
## res://content/projects/*.tres.

@export var project_id: StringName = &""
@export var display_name: String = ""
@export_multiline var description: String = ""

## Projects.KIND_CAPACITY (lasting district Capacity) or KIND_CIVIC
## (world-facing infrastructure with maintenance after).
@export var kind: StringName = &"capacity"

@export var district_id: StringName = &"wickwork"

## Knowledge: a technology the player must Understand (CapabilityWeb),
## "" = none.
@export var requires_tech: StringName = &""

## Physical resources: material_id -> units the player must contribute.
@export var requires_materials: Dictionary = {}

## Demand the district carries while the project is being built.
@export var demand_while_building: float = 2.0

## KIND_CAPACITY: permanent Capacity added on completion.
@export var capacity_gain: float = 0.0

## KIND_CIVIC: smaller continuing maintenance Demand after completion.
@export var maintenance_demand: float = 0.0

## Story flag set on completion (Access/Gates and world dressing key off it).
@export var completion_flag: StringName = &""
