extends Node2D
## Dig-site threshold marker — walkable geometry stays on Hollow Floor / Terrain.
## Props, soft labels, and black shaft leftovers stripped for a clean greybox base.


func _ready() -> void:
	_strip_legacy_dressing()


func _strip_legacy_dressing() -> void:
	## Remove any saved/runtime children from older prop-heavy builds.
	for child in get_children():
		child.queue_free()


## Clean base: no leftover props, soft labels, or black shaft dressing.
func entry_reads_as_threshold() -> bool:
	return (
		get_node_or_null("ThresholdLabel") == null
		and get_node_or_null("ThresholdChasm") == null
		and get_node_or_null("TunnelMouth") == null
		and get_node_or_null("RailCart") == null
		and get_node_or_null("ExcavationBraceL") == null
	)
