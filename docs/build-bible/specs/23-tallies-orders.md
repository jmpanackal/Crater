# Build Bible Spec 23 — Tallies + Approved Gear Orders

**Status:** ✅ CONFIRMED (USER, 2026-09-17) — all design choices reviewed in chat and accepted. Build-order #23 in [`../00-dependency-map.md`](../00-dependency-map.md). Proposed as a **thin** slice.

**Depends on:** Spec 22 (Districts), Spec 14 (Rig/Gear), Spec 19 (Trust).

---

## Purpose

The legitimate public-progression currency and its spend path, per canon §16/§28: **work/contribution → Tallies → Order Approved Gear using Tallies + authorized District Output.**

## Already locked (canon §16, §25, §28 — not new)

- Tallies are transactional compensation for useful civic work/contribution — explicitly **not** Trust.
- Public progression: work → Tallies → Order Approved Gear using Tallies + authorized District Output.
- Tallies should stay understandable and simple; exact prices are open.
- **Terminology is locked**: "Approved Gear" is the category, "Order" is the acquisition action — never "Requisition" as the player-facing umbrella term.
- Typical cost structure is Tallies + authorized District Output; Access/Trust may also matter.
- Approved Gear is openly produced by Hollow districts/facilities.
- Districts may refuse an otherwise-affordable order when available output is needed for essential demand or committed work — a believable civic constraint, not an arbitrary shop lock (§25).
- Rig/Gear already locks that equipping only happens at a valid station (Spec 14, choice 36) — this spec's Order flow has to respect that boundary rather than quietly bypassing it.

## Design choices (✅ Confirmed, USER, 2026-09-17)

- **Tallies get their own small Wallet autoload, separate from Trust** (option A), even though both are "you did something good" currencies. §16/§17 already draw a hard line between them (transactional/spendable vs. social/not-spendable) — folding Tallies into Trust or another existing system would blur a distinction canon goes out of its way to state explicitly.
- **Wallet reuses Trust's exact contract shape** (option A): `earn(amount, reason)` / `spend(amount, reason) -> bool`, called by whichever system determined Tallies should move (primarily Jobs, Spec 24, at settlement) — Wallet never computes its own amounts or reaches into Jobs' data itself. Same one-directional push pattern as everywhere else in this Build Bible, for the same reason: keeps "why did my Tallies change" always traceable to one explicit call site.
- **Ordering acquires ownership; it does not auto-equip** (option A). `order(gear_id)` spends Tallies, draws the required amount from the relevant district via `District.request_withdrawal` (Spec 22) as "authorized District Output," checks any Access/Trust gate, and on success adds the item to Rig's existing owned-Gear list (Spec 14) — a small, forward-compatible extension of what Spec 14 already tracks, not a second competing ownership list. Actually fitting the new Gear to a slot still requires a separate `Rig.equip()` call at a valid station, exactly as Spec 14 already locked. Rejected: auto-equipping on order, which would quietly bypass the already-locked "major Rig changes only at proper stations" rule — an order counter isn't necessarily a valid station.
- **A failed order is atomic and cleanly reasoned** (option A). Insufficient Tallies, insufficient District Output, and a district refusing for demand reasons are three distinct, explainable failure reasons — nothing is spent or partially deducted on failure.

## State it owns

Tallies balance and a capped recent-earn/spend reasons list (Wallet) — mirrors Trust's own reasons-list shape and rationale (the permanent record lives in the Fact Log; this list only serves the "why do I have this many Tallies" UI view).

## API surface

- `Wallet.earn(amount, reason)`, `Wallet.spend(amount, reason) -> bool`, `Wallet.get_balance()`, `Wallet.get_reasons() -> [recent entries]`.
- `Orders.order(gear_id) -> result` — validates Tallies, District Output, and Access/Trust; on success, spends Tallies, withdraws District Output, and adds the item to Rig's (Spec 14) owned-Gear list.

## Failure / edge cases

- A `Wallet.earn`/`spend` call missing a reason fails loudly in debug, matching Trust's established discipline — "Tallies should remain understandable" supports carrying the same rule over even though canon doesn't state it as explicitly for Tallies as it does for Trust.
- A district refusing an order for demand reasons surfaces distinctly from "you can't afford this," matching the already-locked "believable civic constraint, not an arbitrary shop lock."

## Acceptance tests

- A successful order spends the correct Tallies, withdraws the correct District Output, and adds the item to Rig's owned list without equipping it.
- Insufficient Tallies, insufficient District Output, and a district's demand-based refusal each fail cleanly with a distinct reason and no partial spend.
- Ordinary Tallies-earning (a routine job settlement) never itself calls a Trust event — consistent with Spec 19's own acceptance test for the same boundary.
