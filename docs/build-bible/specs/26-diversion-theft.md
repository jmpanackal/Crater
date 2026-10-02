# Build Bible Spec 26 — Diversion / Theft + Concealed Storage

**Status:** 🟡 AI-DRAFTED (Fable, 2026-09-18) from canon §25, §30, §47, §62 and the already-locked G4 (A+C), G5 (B+C), G8 (resolved by §67) and G9 (A) — **pending USER review.** Implemented as drafted so the contract is real; anything marked *choice* below is the draft's call, not canon. Build-order #26 in [`../00-dependency-map.md`](../00-dependency-map.md). Thin slice: Wickwork's rack is the one authored store; the other districts use the same store node.

**Depends on:** Spec 22 (Districts), Spec 17 (Perception), Spec 11 (Storage).

---

## Purpose

The common forbidden-economy mechanic (canon §30): systemic diversion of real District Output from a district's physical storage into the player's concealed stolen-goods stockpile, with the two independent risks canon locks — civic/economic harm and social/detection risk.

## Already locked (canon §25, §30, §47, §62, G4, G5, G9 — not new)

- Diversion removes goods from a district's **Reserves** into **concealed personal storage**; it never lowers Capacity; its harm is the missing buffer (§25).
- Diversion happens at believable physical storage areas, "not purely a menu button"; schedules, sight, sound, access matter (§30).
- **G9 (A):** a hold-to-take at a physical storage object; each take removes one unit, takes time, emits noise, is cancellable; witness danger is diegetic.
- **G4 (A+C):** every diversion writes an unexplained-loss fact regardless of Reserves; the district's own accounting check (Spec 22 step 6) is the other half.
- **G5 (C):** the player can return diverted output or donate personal stores to Reserves, openly or anonymously.
- **G8 (resolved by §67):** every home has a crude concealed workspace from day one to hold diverted output; stockpiles accumulate across cycles toward a Forbidden build (§47, §62).
- Undetected theft does not lower Trust simply because the game knows (§30); being caught can, regardless of surplus.

## Draft choices (Fable, pending USER)

- **Taken units ride on the player until stashed** (*choice*, straight from G9-A's "concealed on the player"). `Diversion` tracks carried stolen units per district; `stash_at_workspace()` moves them into `Storage`'s concealed pool and only works at a workspace station (Spec 14's live station list). Carried stolen goods are what a rescue or search on the person finds (Spec 30).
- **Concealed storage is `Storage`'s** (the state-ownership table already says so): `deposit_concealed / withdraw_concealed / get_concealed(district)`, integer units per district, no cap yet (canon: exact capacity open).
- **Each take is one unrecorded withdrawal** through Spec 22's generic `request_withdrawal(..., {"recorded": false})` — District serves it identically to an Order; the missing record is what its step-6 check later notices.
- **The hold re-checks witnesses at intervals** (Spec 17's already-locked pattern): every noise tick calls `Perception.flag_witnessable("theft:<district>", …, "theft_witnessed")`, so starting in a quiet moment is genuinely safe and someone wandering in mid-hold can still catch it.
- **G9's "above a threshold becomes a physical haul load"** is deferred: units stay abstract on the person for the slice (*choice*; note the threshold in tuning as OPEN).

## State it owns

Carried (unstashed) stolen units per district. Concealed stockpile lives in `Storage`.

## API surface

- `DistrictStore` node (`district_store.gd`): a Spec 10 Interactable at a district's storage; hold-to-take.
- `Diversion.begin_take(district_id)` / hold driven by the store node; `complete_take(district_id) -> {success, reason}`.
- `Diversion.get_carried(district_id)`, `stash_at_workspace() -> int`, `return_output(district_id, amount, anonymous) -> float`.
- `Storage.deposit_concealed / withdraw_concealed / get_concealed / get_concealed_total`.

## Failure / edge cases

- A store whose district has no Reserves refuses the take (`nothing_to_take`) — you can't steal what isn't there.
- Cancelling the hold leaves everything untouched.
- Stashing away from a workspace refuses; the units stay on the person.

## Acceptance tests

- A completed take removes one unit from the district unrecorded, puts one carried unit on the player, and logs one `unexplained_loss` fact; the district's next resolution sees unexplained loss.
- A take begun with nobody nearby stays unwitnessed; an NPC arriving mid-hold is caught by the next tick.
- Cancelling mid-hold changes nothing; stashing only works at a workspace; returning anonymously reduces the district's unexplained loss, returning openly is on the books.
