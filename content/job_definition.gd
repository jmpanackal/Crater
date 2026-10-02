extends Resource
## Build Bible Spec 24 Content Definition — one kind of civic work (canon
## §13–§15). Loaded by the Jobs autoload from res://content/jobs/*.tres.
##
## A job is a physical civic situation built from the normal systems
## (digging, hauling, delivery) — its progress here is "job-relevant
## Material delivered to the worksite", never a checklist. Which of the
## five work types it is decides whether a promise exists at all.

## Stable id, matches this resource's filename (no extension) by convention.
@export var job_id: StringName = &""

@export var title: String = ""

@export_multiline var description: String = ""

## Jobs.TYPE_AVAILABLE / TYPE_COMMITMENT / TYPE_DUTY / TYPE_EMERGENCY /
## TYPE_PERSONAL (canon §13's five kinds).
@export var work_type: StringName = &"available"

## Jobs.DEADLINE_* — one of canon §14's named shapes, not a generic timer.
@export var deadline_shape: StringName = &"none"

## For DEADLINE_MULTI_CYCLE: how many full cycles after the offer.
@export var deadline_cycles: int = 2

## Tier: 0 routine, higher = a better assignment (Spec 24, option A).
## Pay and broken-commitment cost scale with it (tuning).
@export var tier: int = 0

## Minimum Trust standing id needed for offer() to succeed ("" = any).
@export var min_trust: StringName = &""

## The district the delivered Material is for (its worksite / stores).
@export var district_id: StringName = &""

## What progress means: `required_amount` units of `material_id`
## delivered to the worksite's delivery point.
@export var material_id: StringName = &""
@export var required_amount: int = 1

## Base Tallies for an ordinary (adequate-or-better) completion.
@export var tallies_reward: int = 4

## For TYPE_EMERGENCY templates: Jobs spawns an instance of this job when
## `district_id` resolves a cycle with Unmet Demand (G5-B); completing it
## grants that district temporary Capacity.
@export var spawn_on_unmet_demand: bool = false
