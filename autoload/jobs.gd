extends Node
## Krater Jobs + Commitments (autoload: Jobs).
## Build Bible Spec 24 (docs/build-bible/specs/24-jobs-commitments.md).
##
## Canon §13–§14's five work types and graded outcomes as real state, and
## the concrete site where Jobs calls into Wallet (Spec 23) and Trust
## (Spec 19). Thin slice: the opening job (§15) is the one fully authored
## piece of content; the rest is the contract later jobs plug into.
##
## Locked and confirmed, implemented literally:
## - Five work types; "not helping is not the same as promising and
##   failing". Only Commitment and Duty pass through a real Accepted
##   stage (option A) — Available, Emergency and Personal go Offered ->
##   In Progress -> Settled with no promise ever made.
## - Only Commitment/Duty can ever produce a NEGATIVE Trust event on
##   failure (option A); an exceptional outcome can produce a positive one
##   on any type. Ordinary completion earns Tallies, never Trust.
## - settle() is the single resolution point and Jobs is the explicit
##   caller into Wallet.earn() and Trust.submit_trust_event() (option A) —
##   Trust never infers anything from the log by itself.
## - Deadlines are named shapes read from the job's own definition (option
##   A): this_cycle / during_working / before_gathering / during_gathering
##   / multi_cycle / none — checked on the Clock's phase events.
## - A job can require a minimum Trust standing to be OFFERED, and higher
##   tiers pay more (option A); breaking a higher-tier commitment costs
##   more Trust (option A). Tier numbers live in tuning.
## - G5-B: a district resolving with Unmet Demand spawns its Emergency
##   job; completing it lends the district temporary Capacity.
##
## Progress is physical: a job wants `required_amount` of `material_id`
## delivered to its worksite — deliver_from_bundle() takes the towed
## bundle (Spec 13) and counts it. Jobs never touches terrain, the bundle
## or the district's numbers except through their own contracts.
##
## Access via get_tree().root.get_node("Jobs") (no class_name, matching
## the existing project convention — see resources.gd).

const JOBS_DIR := "res://content/jobs/"
const TUNING_DOMAIN := "jobs_tuning"

const TYPE_AVAILABLE := &"available"
const TYPE_COMMITMENT := &"commitment"
const TYPE_DUTY := &"duty"
const TYPE_EMERGENCY := &"emergency"
const TYPE_PERSONAL := &"personal"
const WORK_TYPES: Array[StringName] = [TYPE_AVAILABLE, TYPE_COMMITMENT, TYPE_DUTY, TYPE_EMERGENCY, TYPE_PERSONAL]
## The two that carry a promise.
const PROMISE_TYPES: Array[StringName] = [TYPE_COMMITMENT, TYPE_DUTY]

const DEADLINE_THIS_CYCLE := &"this_cycle"
const DEADLINE_DURING_WORKING := &"during_working"
const DEADLINE_BEFORE_GATHERING := &"before_gathering"
const DEADLINE_DURING_GATHERING := &"during_gathering"
const DEADLINE_MULTI_CYCLE := &"multi_cycle"
const DEADLINE_NONE := &"none"

const STAGE_OFFERED := &"offered"
const STAGE_ACCEPTED := &"accepted"
const STAGE_IN_PROGRESS := &"in_progress"
const STAGE_SETTLED := &"settled"

const GRADE_POOR := &"poor"
const GRADE_ADEQUATE := &"adequate"
const GRADE_STRONG := &"strong"
const GRADE_EXCEPTIONAL := &"exceptional"
## Not a grade of the work — the promise was broken (accepted, then
## abandoned or missed).
const OUTCOME_BROKEN := &"broken_commitment"
## Nothing happened and nothing was promised.
const OUTCOME_UNENGAGED := &"unengaged"

const FACT_JOB_SETTLED := &"job_settled"

var _defs: Dictionary = {}  # def id -> Resource
## job_id -> instance:
## {"job_id","def_id","work_type","stage","delivered","offered_cycle",
##  "offered_phase_index","accepted","grade","tier","district_id",
##  "material_id","required","tallies_reward","deadline_shape","deadline_cycles"}
var _jobs: Dictionary = {}
var _next_instance: int = 1


func _ready() -> void:
	reload_definitions()
	var bus := get_tree().root.get_node_or_null("EventBus")
	if bus != null:
		if not bus.phase_changed.is_connected(_on_phase_changed):
			bus.phase_changed.connect(_on_phase_changed)
		if bus.has_signal("district_resolved") and not bus.district_resolved.is_connected(_on_district_resolved):
			bus.district_resolved.connect(_on_district_resolved)
	var console := get_tree().root.get_node_or_null("DebugConsole")
	if console == null:
		return
	console.register_command("jobs", "jobs — every job instance: type, stage, progress, deadline status.", _debug_jobs)
	console.register_command("offer_job", "offer_job <def_id> — offer a job from content (refused below its Trust tier).", _debug_offer)
	console.register_command("accept_job", "accept_job <job_id> — accept a Commitment/Duty.", _debug_accept)
	console.register_command("deliver_job", "deliver_job <job_id> <amount> — count Material delivered (bypasses the bundle).", _debug_deliver)
	console.register_command("settle_job", "settle_job <job_id> — settle now.", _debug_settle)
	console.register_command("abandon_job", "abandon_job <job_id> — walk away from an accepted job.", _debug_abandon)


# --- Content -----------------------------------------------------------------------------

func reload_definitions() -> void:
	_defs.clear()
	var dir := DirAccess.open(JOBS_DIR)
	if dir == null:
		push_warning("Jobs: %s does not exist (no jobs authored)" % JOBS_DIR)
		return
	dir.list_dir_begin()
	var file_name := dir.get_next()
	while file_name != "":
		if not dir.current_is_dir() and file_name.ends_with(".tres"):
			var path := JOBS_DIR + file_name
			var res: Resource = ResourceLoader.load(path, "", ResourceLoader.CACHE_MODE_REPLACE)
			if res == null:
				push_warning("Jobs: failed to load %s — skipped" % path)
			else:
				var id := StringName(str(res.get("job_id")))
				if id == &"":
					push_warning("Jobs: %s has no job_id — skipped" % path)
				else:
					_defs[id] = res
		file_name = dir.get_next()
	dir.list_dir_end()


func is_known_definition(def_id: StringName) -> bool:
	return _defs.has(def_id)


func get_definition_ids() -> Array[StringName]:
	var names: Array[String] = []
	for key: Variant in _defs.keys():
		names.append(str(key))
	names.sort()
	var out: Array[StringName] = []
	for n: String in names:
		out.append(StringName(n))
	return out


# --- Tuning -------------------------------------------------------------------------------

func _tuning() -> Resource:
	var registry := get_tree().root.get_node_or_null("TuningRegistry")
	if registry == null:
		return null
	return registry.get_domain(TUNING_DOMAIN)


func _tune(name: String, fallback: float) -> float:
	var tuning := _tuning()
	return float(tuning.get(name)) if tuning != null else fallback


## Tallies an ordinary completion of a job at `tier` pays.
func get_pay(def_or_job_id: StringName) -> int:
	var job := _job_or_def(def_or_job_id)
	if job.is_empty():
		return 0
	return int(round(float(job["tallies_reward"]) * (1.0 + float(job["tier"]) * _tune("tier_pay_multiplier", 0.5))))


## Trust delta for breaking this job's promise (negative), scaled by tier.
func get_broken_commitment_delta(def_or_job_id: StringName) -> float:
	var job := _job_or_def(def_or_job_id)
	if job.is_empty():
		return 0.0
	return _tune("broken_commitment_trust_delta", -6.0) * (1.0 + float(job["tier"]) * _tune("tier_penalty_multiplier", 0.5))


# --- Reads ----------------------------------------------------------------------------------

func has_job(job_id: StringName) -> bool:
	return _jobs.has(job_id)


## A copy of the instance, or {}.
func get_job(job_id: StringName) -> Dictionary:
	var job: Variant = _jobs.get(job_id, null)
	return (job as Dictionary).duplicate() if job != null else {}


func get_stage(job_id: StringName) -> StringName:
	return StringName(str(get_job(job_id).get("stage", "")))


## Every unsettled instance, oldest first.
func get_active_jobs() -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	for job_id: StringName in _ordered_ids():
		if _jobs[job_id]["stage"] != STAGE_SETTLED:
			out.append((_jobs[job_id] as Dictionary).duplicate())
	return out


func get_all_jobs() -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	for job_id: StringName in _ordered_ids():
		out.append((_jobs[job_id] as Dictionary).duplicate())
	return out


## "open" while the job's own deadline shape hasn't passed, "passed"
## once it has, "none" for a job with no deadline, "" for no such job.
func get_deadline_status(job_id: StringName) -> StringName:
	var job: Variant = _jobs.get(job_id, null)
	if job == null:
		return &""
	if job["deadline_shape"] == DEADLINE_NONE:
		return &"none"
	return &"passed" if _deadline_passed(job) else &"open"


func _deadline_passed(job: Dictionary) -> bool:
	var clock := get_tree().root.get_node_or_null("Clock")
	if clock == null:
		return false
	var cycle := int(clock.get_cycles_elapsed())
	var phase_index: int = clock.PHASE_ORDER.find(clock.get_phase())
	var offered_cycle := int(job["offered_cycle"])
	var working: int = clock.PHASE_ORDER.find(clock.PHASE_WORKING)
	var gathering: int = clock.PHASE_ORDER.find(clock.PHASE_GATHERING)
	match StringName(str(job["deadline_shape"])):
		DEADLINE_THIS_CYCLE:
			return cycle > offered_cycle
		DEADLINE_DURING_WORKING:
			return cycle > offered_cycle or phase_index > working
		DEADLINE_BEFORE_GATHERING:
			return cycle > offered_cycle or phase_index >= gathering
		DEADLINE_DURING_GATHERING:
			return cycle > offered_cycle or phase_index > gathering
		DEADLINE_MULTI_CYCLE:
			return cycle > offered_cycle + int(job["deadline_cycles"])
	return false


# --- Lifecycle ----------------------------------------------------------------------------------

## Makes a job from content visible/available. Refused (empty id) below
## the job's Trust-tier requirement (option A) — "better assignments" are
## simply never on offer — or for an unknown definition. Returns the new
## instance's job_id (definitions may be offered more than once; ids are
## suffixed after the first).
func offer(def_id: StringName) -> StringName:
	var def: Resource = _defs.get(def_id, null)
	if def == null:
		return &""
	if not _trust_allows(StringName(str(def.get("min_trust")))):
		return &""
	var clock := get_tree().root.get_node_or_null("Clock")
	var job_id := def_id
	if _jobs.has(job_id):
		job_id = StringName("%s_%d" % [def_id, _next_instance])
	_next_instance += 1
	var work_type := StringName(str(def.get("work_type")))
	if not WORK_TYPES.has(work_type):
		push_warning("Jobs: %s has unknown work_type '%s' — treated as available" % [def_id, work_type])
		work_type = TYPE_AVAILABLE
	_jobs[job_id] = {
		"job_id": job_id, "def_id": def_id, "title": str(def.get("title")),
		"work_type": work_type, "stage": STAGE_OFFERED, "delivered": 0, "accepted": false,
		"offered_cycle": int(clock.get_cycles_elapsed()) if clock != null else 0,
		"offered_phase_index": int(clock.PHASE_ORDER.find(clock.get_phase())) if clock != null else 0,
		"grade": &"", "tier": maxi(0, int(def.get("tier"))),
		"district_id": StringName(str(def.get("district_id"))), "material_id": StringName(str(def.get("material_id"))),
		"required": maxi(1, int(def.get("required_amount"))), "tallies_reward": maxi(0, int(def.get("tallies_reward"))),
		"deadline_shape": StringName(str(def.get("deadline_shape"))), "deadline_cycles": maxi(1, int(def.get("deadline_cycles"))),
	}
	_emit_changed(job_id)
	return job_id


## Valid only for Commitment/Duty (option A) and only from Offered — the
## moment a real expectation comes into being.
func accept(job_id: StringName) -> bool:
	var job: Variant = _jobs.get(job_id, null)
	if job == null or job["stage"] != STAGE_OFFERED or not PROMISE_TYPES.has(job["work_type"]):
		return false
	job["stage"] = STAGE_ACCEPTED
	job["accepted"] = true
	_emit_changed(job_id)
	return true


## Progress driven by a world action: `amount` units of `material_id`
## delivered to the worksite. Counts only the job's own Material, only
## while the job is live (offered/accepted/in progress) and — for a
## promise type — only once accepted. Returns the units counted.
func progress(job_id: StringName, material_id: StringName, amount: int) -> int:
	var job: Variant = _jobs.get(job_id, null)
	if job == null or amount <= 0 or job["stage"] == STAGE_SETTLED:
		return 0
	if PROMISE_TYPES.has(job["work_type"]) and not bool(job["accepted"]):
		return 0
	if material_id != job["material_id"]:
		return 0
	job["delivered"] = int(job["delivered"]) + amount
	job["stage"] = STAGE_IN_PROGRESS
	_emit_changed(job_id)
	return amount


## The physical delivery: hands the towed bundle (Spec 13) to the job.
## Refused if nothing is towed or the bundle isn't the job's Material —
## the bundle stays exactly as it was. Returns the units counted.
func deliver_from_bundle(job_id: StringName) -> int:
	var hauling := get_tree().root.get_node_or_null("Hauling")
	var job: Variant = _jobs.get(job_id, null)
	if hauling == null or job == null or not bool(hauling.is_loaded()) or not hauling.has_method("hand_over_load"):
		return 0
	var load: Dictionary = hauling.get_load()
	if load["material_id"] != job["material_id"] or job["stage"] == STAGE_SETTLED:
		return 0
	if PROMISE_TYPES.has(job["work_type"]) and not bool(job["accepted"]):
		return 0
	var handed: Dictionary = hauling.hand_over_load()
	return progress(job_id, handed["material_id"], int(handed["amount"]))


## Walking away from an accepted promise before it's done — settles as a
## broken commitment (Trust-relevant), never a silent disappearance. For
## a job with no promise, abandoning is just leaving it unengaged.
func abandon(job_id: StringName) -> Dictionary:
	var job: Variant = _jobs.get(job_id, null)
	if job == null or job["stage"] == STAGE_SETTLED:
		return {}
	return settle(job_id, true)


## The single resolution point. Grades the outcome against the job's own
## requirement, ALWAYS pays Tallies for an ordinary (adequate-or-better)
## completion, and submits a Trust event only for the categories §17
## names: a broken Commitment/Duty (negative, scaled by tier) or an
## exceptional outcome (positive, any type). Unengaged non-promise work
## settles with nothing at all. Returns the settlement record.
func settle(job_id: StringName, abandoned: bool = false) -> Dictionary:
	var job: Variant = _jobs.get(job_id, null)
	if job == null or job["stage"] == STAGE_SETTLED:
		return {}
	var delivered := int(job["delivered"])
	var required := int(job["required"])
	var ratio := float(delivered) / float(maxi(required, 1))
	var promise := PROMISE_TYPES.has(job["work_type"]) and bool(job["accepted"])
	var outcome: StringName
	if ratio >= _tune("exceptional_ratio", 1.5):
		outcome = GRADE_EXCEPTIONAL
	elif ratio >= 1.0:
		outcome = GRADE_STRONG
	elif ratio >= _tune("adequate_ratio", 0.5):
		outcome = GRADE_ADEQUATE
	elif promise:
		outcome = OUTCOME_BROKEN  # promised, then didn't (abandoned or missed)
	elif delivered > 0:
		outcome = GRADE_POOR
	else:
		outcome = OUTCOME_UNENGAGED
	if abandoned and promise:
		outcome = OUTCOME_BROKEN
	var tallies := 0
	var trust_delta := 0.0
	var wallet := get_tree().root.get_node_or_null("Wallet")
	var trust := get_tree().root.get_node_or_null("Trust")
	var title := str(job["title"])
	match outcome:
		GRADE_ADEQUATE, GRADE_STRONG, GRADE_EXCEPTIONAL:
			tallies = get_pay(job_id) if outcome != GRADE_ADEQUATE else int(ceil(float(get_pay(job_id)) * 0.5))
			if wallet != null and tallies > 0:
				wallet.earn(tallies, "Work settled: %s (%s)" % [title, outcome])
			if outcome == GRADE_EXCEPTIONAL and trust != null:
				trust_delta = _tune("exceptional_trust_delta", 3.0)
				trust.submit_trust_event(&"above_and_beyond", trust_delta, "Went beyond what was asked on \"%s\"" % title)
			if job["work_type"] == TYPE_EMERGENCY and outcome != GRADE_ADEQUATE:
				_grant_emergency_capacity(job)
		OUTCOME_BROKEN:
			if trust != null:
				trust_delta = get_broken_commitment_delta(job_id)
				trust.submit_trust_event(&"broken_commitment", trust_delta, "Took on \"%s\" and didn't see it through" % title)
		_:
			pass  # poor / unengaged: nothing promised, nothing owed either way
	job["stage"] = STAGE_SETTLED
	job["grade"] = outcome
	var record := {
		"job_id": job_id, "def_id": job["def_id"], "work_type": job["work_type"], "outcome": outcome,
		"delivered": delivered, "required": required, "tallies": tallies, "trust_delta": trust_delta,
		"abandoned": abandoned, "tier": int(job["tier"]),
	}
	_record_settlement(record)
	var bus := get_tree().root.get_node_or_null("EventBus")
	if bus != null and bus.has_signal("job_settled"):
		bus.job_settled.emit(job_id, record.duplicate())
	_emit_changed(job_id)
	return record


# --- Deadlines and emergencies (Clock / District events) -------------------------------------------

## On every phase transition, settle whatever's past its own deadline.
## An unengaged non-promise job settles silently; a missed promise
## settles as broken.
func _on_phase_changed(_old_phase: StringName, _new_phase: StringName) -> void:
	_settle_expired()


func _settle_expired() -> void:
	for job_id: StringName in _ordered_ids():
		var job: Dictionary = _jobs[job_id]
		if job["stage"] == STAGE_SETTLED or job["deadline_shape"] == DEADLINE_NONE:
			continue
		if _deadline_passed(job):
			settle(job_id, false)


## G5-B: a district resolving with Unmet Demand spawns its Emergency job
## (if content authors one for it and none is already open).
func _on_district_resolved(district_id: StringName, summary: Dictionary) -> void:
	if float(summary.get("unmet", 0.0)) <= 0.0:
		return
	# District resolves on the same Ritual -> Rousing event this system's
	# own deadline sweep listens to, and CivicCycle's handler runs first —
	# so sweep here too, or last cycle's expired emergency still looks open.
	_settle_expired()
	for def_id: StringName in get_definition_ids():
		var def: Resource = _defs[def_id]
		if not bool(def.get("spawn_on_unmet_demand")) or StringName(str(def.get("district_id"))) != district_id:
			continue
		var already_open := false
		for job: Dictionary in get_active_jobs():
			if job["def_id"] == def_id:
				already_open = true
				break
		if not already_open:
			offer(def_id)


func _grant_emergency_capacity(job: Dictionary) -> void:
	var district := get_tree().root.get_node_or_null("District")
	if district == null or not district.has_method("register_capacity_contributor"):
		return
	district.register_capacity_contributor(
		job["district_id"], "emergency_%s" % str(job["job_id"]), "Emergency work: %s" % str(job["title"]),
		_tune("emergency_capacity_amount", 2.0), int(_tune("emergency_capacity_cycles", 2.0))
	)


# --- Internals -------------------------------------------------------------------------------------

func _trust_allows(min_trust: StringName) -> bool:
	if min_trust == &"":
		return true
	var trust := get_tree().root.get_node_or_null("Trust")
	if trust == null or not trust.has_method("get_standing_ladder"):
		return true
	var ladder: Array[Dictionary] = trust.get_standing_ladder()
	var current: StringName = trust.get_trust()
	var current_rank := -1
	var needed_rank := -1
	for i in range(ladder.size()):
		if ladder[i]["id"] == current:
			current_rank = i
		if ladder[i]["id"] == min_trust:
			needed_rank = i
	return needed_rank < 0 or current_rank >= needed_rank


func _job_or_def(id: StringName) -> Dictionary:
	if _jobs.has(id):
		return _jobs[id]
	var def: Resource = _defs.get(id, null)
	if def == null:
		return {}
	return {"tier": maxi(0, int(def.get("tier"))), "tallies_reward": maxi(0, int(def.get("tallies_reward")))}


func _ordered_ids() -> Array[StringName]:
	var out: Array[StringName] = []
	for key: Variant in _jobs.keys():
		out.append(key)
	return out


func _record_settlement(record: Dictionary) -> void:
	var fact_log := get_tree().root.get_node_or_null("FactLog")
	var clock := get_tree().root.get_node_or_null("Clock")
	if fact_log == null:
		return
	var witnesses: Array[String] = []
	var ctx := record.duplicate(true)
	ctx["job_id"] = str(record["job_id"])
	ctx["def_id"] = str(record["def_id"])
	ctx["work_type"] = str(record["work_type"])
	ctx["outcome"] = str(record["outcome"])
	fact_log.record(FACT_JOB_SETTLED, fact_log.SUBJECT_PLAYER, StringName(), witnesses, ctx, int(clock.get_cycles_elapsed()) if clock != null else -1)


func _emit_changed(job_id: StringName) -> void:
	var bus := get_tree().root.get_node_or_null("EventBus") if is_inside_tree() else null
	if bus != null and bus.has_signal("job_changed"):
		bus.job_changed.emit(job_id, get_stage(job_id))


# --- Build Bible Spec 02 uniform SaveLoad contract --------------------------------------------------

func save_state() -> Dictionary:
	var jobs: Dictionary = {}
	for job_id: StringName in _ordered_ids():
		var job: Dictionary = _jobs[job_id]
		var saved := job.duplicate()
		for key in ["job_id", "def_id", "work_type", "stage", "grade", "district_id", "material_id", "deadline_shape"]:
			saved[key] = str(saved[key])
		jobs[str(job_id)] = saved
	return {"jobs": jobs, "next_instance": _next_instance}


func load_state(data: Dictionary) -> void:
	_jobs.clear()
	var jobs: Variant = data.get("jobs", {})
	if typeof(jobs) == TYPE_DICTIONARY:
		for key: Variant in (jobs as Dictionary).keys():
			var saved: Variant = (jobs as Dictionary)[key]
			if typeof(saved) != TYPE_DICTIONARY:
				continue
			var s: Dictionary = saved
			var job := s.duplicate()
			for name in ["job_id", "def_id", "work_type", "stage", "grade", "district_id", "material_id", "deadline_shape"]:
				job[name] = StringName(str(s.get(name, "")))
			for name in ["delivered", "offered_cycle", "offered_phase_index", "tier", "required", "tallies_reward", "deadline_cycles"]:
				job[name] = int(s.get(name, 0))
			job["accepted"] = bool(s.get("accepted", false))
			job["title"] = str(s.get("title", ""))
			_jobs[StringName(str(key))] = job
	_next_instance = maxi(1, int(data.get("next_instance", 1)))


func reset_all() -> void:
	_jobs.clear()
	_next_instance = 1


# --- Debug -------------------------------------------------------------------------------------------

func _debug_jobs(_args: Array[String]) -> String:
	if _jobs.is_empty():
		return "No jobs. Definitions: %s" % [", ".join(PackedStringArray(get_definition_ids()))]
	var lines: PackedStringArray = []
	for job: Dictionary in get_all_jobs():
		lines.append("  %s [%s, tier %d] %s — %d/%d %s, deadline %s%s" % [
			job["job_id"], job["work_type"], int(job["tier"]), job["stage"], int(job["delivered"]), int(job["required"]),
			job["material_id"], get_deadline_status(job["job_id"]), "" if job["grade"] == &"" else " -> %s" % job["grade"],
		])
	return "\n".join(lines)


func _debug_offer(args: Array[String]) -> String:
	if args.is_empty():
		return "Usage: offer_job <def_id>"
	var id := offer(StringName(args[0]))
	return "Offered %s" % id if id != &"" else "Not offered (unknown definition or Trust standing too low)"


func _debug_accept(args: Array[String]) -> String:
	if args.is_empty():
		return "Usage: accept_job <job_id>"
	return "Accepted" if accept(StringName(args[0])) else "Refused (not offered, or not a Commitment/Duty)"


func _debug_deliver(args: Array[String]) -> String:
	if args.size() < 2:
		return "Usage: deliver_job <job_id> <amount>"
	var job := get_job(StringName(args[0]))
	if job.is_empty():
		return "No such job"
	var counted := progress(StringName(args[0]), job["material_id"], int(args[1]))
	return "Counted %d (now %d/%d)" % [counted, int(get_job(StringName(args[0]))["delivered"]), int(job["required"])]


func _debug_settle(args: Array[String]) -> String:
	if args.is_empty():
		return "Usage: settle_job <job_id>"
	var record := settle(StringName(args[0]))
	return "Settled: %s" % [record] if not record.is_empty() else "No such open job"


func _debug_abandon(args: Array[String]) -> String:
	if args.is_empty():
		return "Usage: abandon_job <job_id>"
	var record := abandon(StringName(args[0]))
	return "Abandoned: %s" % [record] if not record.is_empty() else "No such open job"
