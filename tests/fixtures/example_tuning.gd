extends Resource
## Test fixture only — a minimal Resource subclass used purely to exercise
## TuningRegistry's file-scanning/reload mechanism end-to-end (see
## test_core_infrastructure.gd) without inventing a "real" gameplay tuning
## domain before any system actually needs one. Not gameplay content.

@export var test_value: int = 1
