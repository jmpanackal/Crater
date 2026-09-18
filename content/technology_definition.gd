extends Resource
## Build Bible Spec 25 Content Definition — one technology in the
## discovered capability web (canon §40–§42). Loaded by the CapabilityWeb
## autoload from res://content/technologies/*.tres.
##
## Functional families are TAGS here (Spec 25, confirmed option A) — a
## technology can carry several at once (Excavation, Survey, Hauling,
## Mobility, Light, Secrecy, Rig Core), never a single exclusive branch.
## Known/Understood come only from submitted discovery events; the
## `*_from_*` lists below are what wires the real sources (a Record read,
## a Component recovered, Gear owned) to those events without any system
## deciding on its own. Available is derived live from the requirements.

## Stable id, matches this resource's filename (no extension) by convention.
@export var tech_id: StringName = &""

@export var display_name: String = ""

@export_multiline var description: String = ""

## CapabilityWeb.KIND_APPROVED_GEAR / KIND_FORBIDDEN_DESIGN / KIND_CORE_IMPROVEMENT.
@export var kind: StringName = &"approved_gear"

## Family tags (CapabilityWeb.FAMILY_*). Several allowed.
@export var families: Array[StringName] = []

## The Gear / Core Improvement this technology is (Spec 14 ids), if any.
@export var gear_id: StringName = &""

## Openly sanctioned, ordinary technology starts Known + Understood —
## the public catalog (canon §28). Forbidden technology never does.
@export var starts_known: bool = false
@export var starts_understood: bool = false

## Discovery wiring (each entry raises the tech to that level when the
## source event happens): Records (Journal), Components (Storage), Gear
## owned (Rig).
@export var known_from_records: Array[StringName] = []
@export var understood_from_records: Array[StringName] = []
@export var known_from_components: Array[StringName] = []

## Availability requirements (checked live). For an Approved Gear tech
## the order terms on its GearDefinition (Orders.can_order) are the
## requirement; these fields are for Forbidden designs / Core Improvements.
@export var requires_materials: Dictionary = {}  # material_id -> amount
@export var requires_components: Array[StringName] = []
@export var requires_tallies: int = 0
## Minimum residence tier (Rig.RESIDENCE_*), "" = none.
@export var requires_residence: StringName = &""
## Minimum Trust standing id, "" = none.
@export var requires_trust: StringName = &""
