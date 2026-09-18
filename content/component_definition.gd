extends Resource
## Build Bible Spec 11 Content Definition — one Component: a smaller
## manufactured/specialized object, usually ship-derived ("we have the
## part"), as opposed to bulk Materials ("we have the stuff") or Records
## ("we know how"). Loaded by the Storage autoload from
## res://content/components/*.tres.
##
## Unlike the Material roster, WHICH Components exist is not canon-locked —
## the thin vertical slice ships one placeholder so the contract is real.

## Stable id, matches this resource's filename (no extension) by convention.
@export var component_id: StringName = &""

@export var display_name: String = ""

@export_multiline var description: String = ""

## Build Bible Spec 18: if this Component is a seal kit, the concealment
## tier it achieves when used to seal evidence — Evidence.TIER_BASIC /
## TIER_IMPROVED / TIER_ADVANCED (canon §62's qualitative tiers). Empty
## for anything that isn't a seal kit.
@export var seal_tier: StringName = &""
