extends Resource
## Build Bible Spec 20 tuning domain — loaded by TuningRegistry as
## "suspicion_tuning" (res://tuning/suspicion_tuning.tres). Suspicion is
## derived, never stored; these numbers shape the derivation. Exact
## thresholds/weights are open per canon — playtesting starting points.

## Facts older than this many civic cycles age out of the suspicion
## window (the free, natural cooldown the spec describes — no decay timer).
@export var window_cycles: int = 3

## Fact weights. A sight witness is worth more than a sound one; a search
## that actually found evidence keeps a context hot; a district
## discrepancy (Spec 22, G4-C) counts on its own.
@export var weight_witness_sight: float = 2.0
@export var weight_witness_sound: float = 1.0
@export var weight_found_evidence: float = 3.0
@export var weight_district_discrepancy: float = 2.0

## Auto-investigation threshold = threshold_base + Trust internal value *
## threshold_per_trust_point (Spec 20, option A: Trust modulates the
## THRESHOLD only, never the score). At default Trust 50 that's 4 + 2.5.
@export var threshold_base: float = 4.0
@export var threshold_per_trust_point: float = 0.05

## The concealment tier a routine search beats (Evidence.TIER_*). A
## Basic search finds exposed evidence and nothing sealed.
@export var default_search_tier: StringName = &"basic"

## Trust delta submitted when a search finds real, unconcealed evidence
## tying the incident to the player (the reason text is built from the
## resolved facts).
@export var found_evidence_trust_delta: float = -10.0
