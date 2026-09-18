extends Resource
## Build Bible Spec 22 Content Definition — one production district's
## baseline (canon §24–§26, §43–§45). Loaded by the District autoload from
## res://content/districts/*.tres.
##
## Capacity and Demand are both sums of NAMED contributors (Spec 22,
## confirmed option A) — the breakdown the player sees IS the data. The
## entries authored here are the permanent baseline; runtime systems
## (Projects, Jobs' emergency grants, civic construction) register their
## own on top and take them away again.

## Stable id, matches this resource's filename (no extension) by convention.
@export var district_id: StringName = &""

@export var display_name: String = ""

## Baseline District Capacity contributors: [{"id": String, "name": String,
## "amount": float}]. Capacity grows only through lasting investment.
@export var capacity_contributors: Array[Dictionary] = []

## Baseline Civic Demand contributors, same shape ("basic Hollow needs",
## "lift maintenance", ...). Never per-NPC consumption (canon §24).
@export var demand_contributors: Array[Dictionary] = []

## District Reserve Cap: how much banked surplus the district can hold.
@export var reserve_cap: float = 6.0

## Reserves the district starts with.
@export var starting_reserves: float = 0.0
