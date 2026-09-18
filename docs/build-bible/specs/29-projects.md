# Build Bible Spec 29 — Projects

**Status:** 🟡 AI-DRAFTED (Fable, 2026-09-18) from canon §24, §26, §27 and the locked G5 — **pending USER review.** Implemented as drafted; anything marked *choice* is the draft's call. Build-order #29 in [`../00-dependency-map.md`](../00-dependency-map.md). Thin slice: one Capacity project and one Civic project, both Wickwork.

**Depends on:** Spec 22 (Districts), Spec 11 (Storage), Spec 25 (Capability Web).

---

## Purpose

Canon §26's two project categories as real state: **Capacity projects** (lasting district improvements that permanently raise Capacity) and **Civic projects** (world-facing work — lifts, frontier stations, utilities — that temporarily raise Demand while being built and may leave a smaller maintenance Demand after). The player *influences and enables* projects; this is not a city-builder construction menu.

## Already locked (canon §24, §26, §27 — not new)

- Capacity grows only through lasting investment (equipment, workspace, techniques, Records, infrastructure, Materials/Components, projects).
- Projects can require **knowledge + physical resources + production capacity**.
- Civic projects can temporarily increase Demand while being built and may create smaller continuing maintenance Demand after completion; completed infrastructure/improvements should visibly change the district/world where practical.
- District improvements should visibly affect the Hollow (§27) — better workspaces, repaired routes, new lifts, platforms.

## Draft choices (Fable, pending USER)

- **Projects are content** (`content/projects/*.tres`): kind, district, required Materials, required technology (CapabilityWeb Understood), Demand while building, Capacity gain (capacity kind) or maintenance Demand (civic kind), and a story flag set on completion (what Access/Gates and world dressing key off).
- **Starting a project** requires the knowledge and a district that isn't in shortage (*choice*: "production capacity" = `District.get_health() >= 0`); starting registers the building Demand contributor.
- **Contributing Materials** is the player's lever: from Storage (`contribute`) or straight from the towed bundle at a worksite (`contribute_from_bundle`, Spec 13's hand-over). Progress is the delivered count against the requirement; nothing else is simulated.
- **Completion** unregisters the building Demand and registers the lasting effect: a permanent Capacity contributor (capacity kind) or a maintenance Demand contributor (civic kind), logs a `project_completed` fact, sets the project's story flag, emits `project_completed`.

## State it owns

Per project: status (not started / in progress / complete) and delivered Materials.

## API surface

- `Projects.can_start(project_id) -> {ok, reason}`, `start(project_id) -> {success, reason}`, `contribute(project_id, material_id, amount) -> int`, `contribute_from_bundle(project_id) -> int`, `get_progress(project_id)`, `get_status(project_id)`.

## Acceptance tests

- A project can't start without its knowledge or while its district is in shortage; starting registers Demand while building.
- Contributions withdraw exactly what Storage has; completion removes the building Demand and adds a permanent Capacity contributor (capacity kind) or a maintenance Demand (civic kind), plus the story flag.
- Project state persists.
