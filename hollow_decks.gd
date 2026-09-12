extends StaticBody2D
## Builds Hollow walk collision from HollowLayout — multi-band terraces, Mid Heart,
## lower freight span, shallow ramps, three lift openings, local ladder openings.


func _ready() -> void:
	_rebuild()


func _rebuild() -> void:
	for child in get_children():
		remove_child(child)
		child.free()

	var t := HollowLayout.FLOOR_THICKNESS
	var bt := HollowLayout.BRIDGE_THICKNESS

	# Upper residences around short residence climb.
	_add_deck(
		"UpperResWest",
		HollowLayout.HOLLOW_LEFT,
		HollowLayout.LADDER_UPPER_OPEN_X,
		HollowLayout.UPPER_RES_Y,
		t
	)
	_add_deck(
		"UpperResEast",
		HollowLayout.ladder_upper_open_end(),
		HollowLayout.LIFT_OPEN_X,
		HollowLayout.UPPER_RES_Y,
		t
	)

	# --- Glowbeds main: gallery + terrace around left service lift ---
	_add_deck(
		"FarmsDeckWest",
		HollowLayout.HOLLOW_LEFT,
		HollowLayout.LEFT_LIFT_OPEN_X,
		HollowLayout.FARMS_Y,
		t
	)
	_add_deck(
		"FarmsDeckMid",
		HollowLayout.left_lift_open_end(),
		HollowLayout.LIFT_OPEN_X,
		HollowLayout.FARMS_Y,
		t
	)

	# Glowbeds hang / fiber racks (sub-level).
	_add_deck(
		"GlowSubWest",
		HollowLayout.HOLLOW_LEFT,
		HollowLayout.LEFT_LIFT_OPEN_X,
		HollowLayout.GLOW_SUB_Y,
		t
	)
	_add_deck(
		"GlowSubEast",
		HollowLayout.left_lift_open_end(),
		HollowLayout.LIFT_OPEN_X - 32.0,
		HollowLayout.GLOW_SUB_Y,
		t
	)
	_add_ramp(
		"GlowbedsHangRamp",
		HollowLayout.LIFT_OPEN_X - 96.0,
		HollowLayout.LIFT_OPEN_X - 32.0,
		HollowLayout.GLOW_SUB_Y,
		HollowLayout.FARMS_Y,
		16.0
	)

	# --- Wickwork bay + street (Heart hoist + left service openings) ---
	_add_deck(
		"WickLeftWest",
		HollowLayout.HOLLOW_LEFT,
		HollowLayout.LADDER_MID_OPEN_X,
		HollowLayout.WICK_Y,
		t
	)
	_add_deck(
		"WickLeftMid",
		HollowLayout.ladder_mid_open_end(),
		HollowLayout.LEFT_LIFT_OPEN_X,
		HollowLayout.WICK_Y,
		t
	)
	_add_deck(
		"WickLeftEast",
		HollowLayout.left_lift_open_end(),
		HollowLayout.LIFT_OPEN_X,
		HollowLayout.WICK_Y,
		t
	)

	# Mid allotment / residential street under Wickwork (solid under LadderMid).
	_add_deck(
		"MidAllotWest",
		HollowLayout.HOLLOW_LEFT,
		HollowLayout.LIFT_OPEN_X - 48.0,
		HollowLayout.MID_ALLOT_Y,
		t
	)

	# Heart hoist east lip → Mid Heart approach (same top Y — continuous walk).
	_add_deck_v4("LiftLipMid", HollowLayout.LIFT_LIP_MID)

	# Mid Heart — compact suspended decks + short links (flat tops, no snag bumps).
	_add_deck_v4("HeartWest", HollowLayout.HEART_WEST)
	_add_deck_v4("HeartLinkAB", HollowLayout.HEART_LINK_AB)
	_add_deck_v4("HeartMid", HollowLayout.HEART_MID)
	_add_deck_v4("HeartLinkBC", HollowLayout.HEART_LINK_BC)
	_add_deck_v4("HeartEast", HollowLayout.HEART_EAST)

	# Right mid terrace around freight lift only (Cistern ladder is Lower↔Cistern).
	_add_deck(
		"WickRightWest",
		HollowLayout.PIT_RIGHT,
		HollowLayout.FREIGHT_LIFT_OPEN_X,
		HollowLayout.WICK_Y,
		t
	)
	_add_deck(
		"WickRightEast",
		HollowLayout.freight_lift_open_end(),
		HollowLayout.EXIT_RIGHT,
		HollowLayout.WICK_Y,
		t
	)

	# --- Lower working terraces (spawn band) ---
	_add_deck(
		"LowerWorkWest",
		HollowLayout.HOLLOW_LEFT + 64.0,
		HollowLayout.LIFT_OPEN_X,
		HollowLayout.LOWER_WORK_Y,
		t
	)
	_add_deck(
		"LowerSpan",
		HollowLayout.LOWER_SPAN_LEFT,
		HollowLayout.LOWER_SPAN_RIGHT,
		HollowLayout.LOWER_WORK_Y,
		bt
	)
	_add_deck(
		"LowerWorkRight",
		HollowLayout.PIT_RIGHT,
		HollowLayout.LADDER_CISTERN_OPEN_X,
		HollowLayout.LOWER_WORK_Y,
		t
	)
	_add_deck(
		"LowerWorkRightEast",
		HollowLayout.ladder_cistern_open_end(),
		HollowLayout.FREIGHT_LIFT_OPEN_X,
		HollowLayout.LOWER_WORK_Y,
		t
	)
	_add_deck(
		"LowerWorkExit",
		HollowLayout.freight_lift_open_end(),
		HollowLayout.HOLLOW_RIGHT,
		HollowLayout.LOWER_WORK_Y,
		t
	)

	# Cistern band — solid under emergency ladder; open only for freight lift.
	_add_deck(
		"CisternRight",
		HollowLayout.CISTERN_DECK_LEFT,
		HollowLayout.FREIGHT_LIFT_OPEN_X,
		HollowLayout.CISTERN_Y,
		t
	)
	_add_deck(
		"CisternEast",
		HollowLayout.freight_lift_open_end(),
		HollowLayout.EXIT_RIGHT,
		HollowLayout.CISTERN_Y,
		t
	)

	# Seep / service gallery approach (lower-right threshold; not into the Mouth).
	_add_deck(
		"SeepApproach",
		HollowLayout.FREIGHT_LIFT_OPEN_X - 32.0,
		HollowLayout.FREIGHT_LIFT_OPEN_X,
		HollowLayout.SEEP_Y,
		t
	)
	_add_deck(
		"SeepGallery",
		HollowLayout.freight_lift_open_end(),
		HollowLayout.EXIT_RIGHT,
		HollowLayout.SEEP_Y,
		t
	)

	# Vaultward gate lip — visual/locked; short stub so the route reads without free access.
	_add_deck(
		"VaultwardStub",
		HollowLayout.HOLLOW_LEFT + 128.0,
		HollowLayout.HOLLOW_LEFT + 256.0,
		HollowLayout.VAULTWARD_Y,
		t
	)


func _add_deck_v4(deck_name: String, r: Vector4) -> void:
	_add_deck(deck_name, r.x, r.y, r.z, r.w)


func _add_deck(deck_name: String, x0: float, x1: float, top_y: float, thickness: float) -> void:
	var width := x1 - x0
	if width < 4.0:
		return
	var col := CollisionShape2D.new()
	col.name = deck_name
	var shape := RectangleShape2D.new()
	shape.size = Vector2(width, thickness)
	col.shape = shape
	col.position = Vector2(x0 + width * 0.5, top_y + thickness * 0.5)
	add_child(col)


func _add_ramp(
	ramp_name: String,
	x0: float,
	x1: float,
	y0: float,
	y1: float,
	thickness: float
) -> void:
	## Convex quad ramp — gentle slope for CharacterBody2D (keep under ~25°).
	var width := x1 - x0
	if width < 8.0:
		return
	var col := CollisionPolygon2D.new()
	col.name = ramp_name
	col.polygon = PackedVector2Array(
		[
			Vector2(x0, y0),
			Vector2(x1, y1),
			Vector2(x1, y1 + thickness),
			Vector2(x0, y0 + thickness),
		]
	)
	add_child(col)
