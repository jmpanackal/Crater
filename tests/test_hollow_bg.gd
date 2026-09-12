extends SceneTree
## Hollow backdrop: readable cliffs + pit void (no fake city panels).


func _init() -> void:
	call_deferred("_run_tests")


func _run_tests() -> void:
	var scene: Node = (load("res://main.tscn") as PackedScene).instantiate()
	root.add_child(scene)
	await process_frame
	await process_frame

	# City concept panels must not fight walkable geometry.
	if scene.get_node_or_null("Hollow/BackdropLeft") != null:
		push_error("FAIL city BackdropLeft still present")
		quit(1)
		return
	if scene.get_node_or_null("Hollow/BackdropRight") != null:
		push_error("FAIL city BackdropRight still present")
		quit(1)
		return
	if scene.get_node_or_null("Hollow/Backdrop") != null:
		push_error("FAIL city Backdrop still present")
		quit(1)
		return
	print("PASS no hollow_bg city panels in scene")

	var cliff_l: ColorRect = scene.get_node_or_null("Hollow/CliffLeft") as ColorRect
	var cliff_r: ColorRect = scene.get_node_or_null("Hollow/CliffRight") as ColorRect
	if cliff_l == null or cliff_r == null:
		push_error("FAIL cliff silhouettes missing")
		quit(1)
		return
	if cliff_l.color.a < 0.95 or cliff_r.color.a < 0.95:
		push_error("FAIL cliffs must be solid ambient (not transparent zones)")
		quit(1)
		return
	print("PASS solid cliff silhouettes")

	if scene.get_node_or_null("Hollow/PitVoid") == null:
		push_error("FAIL PitVoid missing")
		quit(1)
		return
	print("PASS pit void present")

	# Bug-like decorative rects removed.
	for bad in ["LanternFarms", "LanternWick", "LanternBridge", "LanternCistern", "WarmFarms", "WarmWick", "WarmCistern", "BridgePlanks", "LadderFarmsVisual", "LadderCisternVisual"]:
		if scene.get_node_or_null("Hollow/%s" % bad) != null:
			push_error("FAIL decorative bug-rect still present: %s" % bad)
			quit(1)
			return
	print("PASS lantern/warm/plank bug-rects removed")

	# Production stubs sit on decks (opaque); bottoms must meet deck_y (FloorVisual lip).
	var prop_decks := {
		"PropFarms": HollowLayout.FARMS_Y,
		"PropWick": HollowLayout.WICK_Y,
		"PropCistern": HollowLayout.CISTERN_Y,
	}
	for prop_name in prop_decks.keys():
		var prop: ColorRect = scene.get_node_or_null("Hollow/%s" % prop_name) as ColorRect
		if prop == null:
			push_error("FAIL %s missing" % prop_name)
			quit(1)
			return
		if prop.color.a < 0.95:
			push_error("FAIL %s must be solid stub, got a=%s" % [prop_name, prop.color.a])
			quit(1)
			return
		var deck_y: float = prop_decks[prop_name]
		var bottom := prop.position.y + prop.size.y
		if absf(bottom - deck_y) > 1.0:
			push_error("FAIL %s bottom %s != deck %s" % [prop_name, bottom, deck_y])
			quit(1)
			return
		if prop.get_node_or_null("Building") == null:
			push_error("FAIL %s missing building silhouette" % prop_name)
			quit(1)
			return
	print("PASS solid district props on decks")

	# Building silhouettes / district kits are kind-specific.
	var farms_b := scene.get_node_or_null("Hollow/PropFarms/Building")
	var wick_b := scene.get_node_or_null("Hollow/PropWick/Building")
	var cistern_b := scene.get_node_or_null("Hollow/PropCistern/Building")
	if farms_b == null or farms_b.get_node_or_null("Roof") == null:
		push_error("FAIL Farms building roof missing")
		quit(1)
		return
	if farms_b.get_node_or_null("../DistrictExtras/FiberRack") == null \
			and scene.get_node_or_null("Hollow/PropFarms/DistrictExtras/FiberRack") == null:
		push_error("FAIL Glowbeds fiber rack missing")
		quit(1)
		return
	if wick_b == null or wick_b.get_node_or_null("Chimney") == null:
		push_error("FAIL Wick chimney silhouette missing")
		quit(1)
		return
	if cistern_b == null or cistern_b.get_node_or_null("Dome") == null:
		push_error("FAIL Cistern dome silhouette missing")
		quit(1)
		return
	if scene.get_node_or_null("Hollow/PropCistern/DistrictExtras/FreightPlatform") == null:
		push_error("FAIL Cistern freight platform missing")
		quit(1)
		return
	print("PASS district props building-like silhouettes")

	if scene.get_node_or_null("Hollow/CarvedRooms/GlowbedsGallery") == null:
		push_error("FAIL Glowbeds carved gallery missing")
		quit(1)
		return
	if scene.get_node_or_null("Hollow/HeartStructure/UpperHeartDeck") == null:
		push_error("FAIL Upper Heart silhouette missing")
		quit(1)
		return
	if scene.get_node_or_null("Hollow/DistrictMidHeart") == null:
		push_error("FAIL Mid Heart label missing")
		quit(1)
		return
	print("PASS carved rooms + Heart structure")

	var ladder_f: Area2D = scene.get_node_or_null("Hollow/LadderFarms") as Area2D
	var ladder_c: Area2D = scene.get_node_or_null("Hollow/LadderCistern") as Area2D
	var lift: Node = scene.get_node_or_null("Hollow/CivicLift")
	if ladder_f != null:
		push_error("FAIL primary Farms ladder still present")
		quit(1)
		return
	if ladder_c == null or lift == null:
		push_error("FAIL civic lift or local Cistern ladder missing")
		quit(1)
		return
	if ladder_c.get_script() == null or lift.get_script() == null:
		push_error("FAIL climb/lift script missing")
		quit(1)
		return
	if ladder_c.get_node_or_null("WoodBack") == null:
		push_error("FAIL woodier ladder backboard missing")
		quit(1)
		return
	print("PASS civic lift + local climb ladder present")

	if scene.get_node_or_null("Hollow/NPCs/Pell") == null:
		push_error("FAIL Hollow NPCs missing")
		quit(1)
		return
	if scene.get_node_or_null("Hollow/DistrictFarms") == null:
		push_error("FAIL district labels missing")
		quit(1)
		return
	print("PASS Hollow districts + NPCs present")

	if scene.get_node_or_null("Hollow/HollowZone") == null:
		push_error("FAIL HollowZone missing")
		quit(1)
		return
	if scene.get_node_or_null("Hollow/Floor/WickLeftEast") == null \
			and scene.get_node_or_null("Hollow/Floor/FarmsDeckMid") == null:
		push_error("FAIL Hollow floor collision missing")
		quit(1)
		return
	if scene.get_node_or_null("Hollow/FloorVisual") == null:
		push_error("FAIL FloorVisual missing")
		quit(1)
		return
	print("PASS Hollow zone + collision + floor tiles still present")

	if scene.get_node_or_null("Hollow/LeftServiceLift") == null \
			or scene.get_node_or_null("Hollow/FreightLift") == null:
		push_error("FAIL secondary lifts missing")
		quit(1)
		return
	if scene.get_node_or_null("Hollow/VaultwardGate") == null:
		push_error("FAIL Vaultward gate missing")
		quit(1)
		return
	if scene.get_node_or_null("Hollow/SocietyLife/Window0") == null:
		push_error("FAIL society life cues missing")
		quit(1)
		return
	print("PASS lift network + Vaultward + society life")

	if scene.get_node_or_null("Hollow/PitFogHigh") == null and scene.get_node_or_null("Hollow/AmbianceLights") == null:
		push_error("FAIL hollow ambiance (fog/lights) missing")
		quit(1)
		return
	if scene.get_node_or_null("Hollow/TerraceBandFarmsL") == null:
		push_error("FAIL terrace cliff bands missing")
		quit(1)
		return
	if scene.get_node_or_null("Hollow/PitShaftVeil") == null:
		push_error("FAIL PitShaftVeil parallax missing")
		quit(1)
		return
	print("PASS hollow ambiance livability nodes")

	# Setting craft: rope crossing, deck supports/rails, pit spores, district extras.
	var hollow: Node = scene.get_node_or_null("Hollow")
	if hollow == null or not hollow.has_method("setting_reads_as_place") or not hollow.setting_reads_as_place():
		push_error("FAIL Hollow setting craft (crossing/decks/spores/district extras)")
		quit(1)
		return
	if scene.get_node_or_null("Hollow/RopeCrossing/Plank0") == null:
		push_error("FAIL RopeCrossing planks missing")
		quit(1)
		return
	if scene.get_node_or_null("Hollow/DeckArchitecture/WickLeftUnder/LedgeArt") == null \
			and scene.get_node_or_null("Hollow/DeckArchitecture/WickLeftUnder/Joist") == null:
		push_error("FAIL deck underside ledge markers missing")
		quit(1)
		return
	if scene.get_node_or_null("Hollow/DeckArchitecture/RailWickL") == null:
		push_error("FAIL deck pit-lip railings missing")
		quit(1)
		return
	if scene.get_node_or_null("Hollow/AmbianceLights/LampPostFarms") == null:
		push_error("FAIL lamp posts missing")
		quit(1)
		return
	print("PASS Hollow setting craft (place read)")

	if scene.get_node_or_null("Hollow/ImpactStrata/HullPlateFar") == null:
		push_error("FAIL Devil's Mouth impact strata / hull remnants missing")
		quit(1)
		return
	if scene.get_node_or_null("Hollow/TerracePunctuation/FarmsLookout") == null:
		push_error("FAIL terrace lookout bay missing")
		quit(1)
		return
	if scene.get_node_or_null("Hollow/CarvedRooms/GlowbedsGallery/Overhang") == null:
		push_error("FAIL carved room overhang missing")
		quit(1)
		return
	if scene.get_node_or_null("Hollow/AmbianceLights/LightDeepSparseA") == null:
		push_error("FAIL sparse deep Mouth lights missing")
		quit(1)
		return
	var farms_label: Label = scene.get_node("Hollow/DistrictFarms") as Label
	if farms_label.get_theme_constant("outline_size") < 2:
		push_error("FAIL district labels lack outline contrast")
		quit(1)
		return
	# Diegetic signage — no large flat translucent placard behind the whole name.
	if farms_label.get_node_or_null("SignPlate") != null:
		push_error("FAIL DistrictFarms still uses flat SignPlate rectangle")
		quit(1)
		return
	if farms_label.get_node_or_null("SignPost") == null and farms_label.get_node_or_null("PaintMark") == null:
		push_error("FAIL district labels lack diegetic signpost/paint mark")
		quit(1)
		return
	if scene.get_node_or_null("Hollow/MidHeartProps/TallyBooth") == null:
		push_error("FAIL Mid Heart tally booth missing")
		quit(1)
		return
	if scene.get_node_or_null("Hollow/MidHeartProps/TallyBoard") == null:
		push_error("FAIL Mid Heart tally board missing")
		quit(1)
		return
	if scene.get_node_or_null("Hollow/MidHeartProps/BoothCanopy") == null:
		push_error("FAIL Mid Heart canopy missing")
		quit(1)
		return
	# Carved-in facades (overhang / inset), not props only on flat decks.
	if scene.get_node_or_null("Hollow/PropFarms/Building/RockOverhang") == null:
		push_error("FAIL Glowbeds facade overhang missing")
		quit(1)
		return
	if scene.get_node_or_null("Hollow/PropWick/Building/InsetDoor") == null:
		push_error("FAIL Wickwork inset doorway missing")
		quit(1)
		return
	if scene.get_node_or_null("Hollow/PropCistern/Building/WallPipe") == null:
		push_error("FAIL Cistern wall pipe missing")
		quit(1)
		return
	if scene.get_node_or_null("Hollow/PropCistern/DistrictExtras/SeepMark") == null:
		push_error("FAIL Cistern wet-rock seep mark missing")
		quit(1)
		return
	if scene.get_node_or_null("Hollow/PropCistern/DistrictExtras/FreightLift") == null:
		push_error("FAIL Cistern public freight-lift prop missing")
		quit(1)
		return
	if scene.get_node_or_null("Hollow/ImpactStrata/DistantHazeBand") == null:
		push_error("FAIL Devil's Mouth distant haze band missing")
		quit(1)
		return
	print("PASS habitation readability (strata / rooms / labels / facades)")

	print("HOLLOW_BG_TESTS_PASSED")
	quit(0)
