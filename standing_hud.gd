extends Label
## Always-visible Social Standing readout (tension follows you to the Dig Site too).

var _community: Node


func _ready() -> void:
	_community = get_tree().root.get_node_or_null("Community")
	if _community == null:
		text = "Standing: ?"
		return
	_community.social_standing_changed.connect(_on_standing_changed)
	_refresh(_community.get_social_standing())


func _on_standing_changed(new_standing: int) -> void:
	_refresh(new_standing)


func _refresh(standing: int) -> void:
	if _community == null:
		text = "Standing: ?"
		return
	text = "Standing: %d/%d" % [standing, _community.SOCIAL_STANDING_MAX]
