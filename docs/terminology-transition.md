# Terminology transition

Current canonical terms:

| Use now | Retired term | Meaning |
| --- | --- | --- |
| **Trust** | Social Standing / Standing | The Hollow's measure of how much people trust the player. It is affected by attendance, lies, forbidden work, and public help. Gates favors, alibis, watched/delayed upper access, and later recruitment. |
| **Steal** / **theft** | Siphon / siphoning | The forbidden diversion of named District production for a personal work-rig upgrade. **Shortage Risk** is the measure of how likely missing production is to be noticed later — code still calls this **Cover** throughout (`districts.gd`'s `cover_changed`/`get_cover_health()`/`get_cover_for_good()`, `upgrade_hud.gd`'s Cover label/tooltips); see "Known follow-ups" below, this was not renamed in the 2026-09-13 pass. |
| **Tallies** | (keep) | Personal work pay from public Material turn-ins; used for openly requisitioned, sanctioned gear. |
| **Materials** | Salvage (as category) | Dig finds you carry and turn in. Transitional dig-haul id `salvage` may remain in code until Tallies UI fully lands. |
| **District production** | stocks / stock (player-facing) | Named communal goods (Glowrations, Presswater, etc.). |
| **Firmament** | Vault / roof (formal); also **Cap** in `cap_*` test-variable naming | Sacred ceiling; natural crash-sealed strata. Correction (2026-09-13): this row previously listed "Cap" under Devil's Mouth below, but the actual `cap_*` identifiers in `test_feel_feedback.gd`/`test_feel_polish.gd` consistently meant the Firmament case (paired against `pit_*` for Devil's Mouth) — renamed to `firmament_*` accordingly. |
| **Devil’s Mouth** | Pit (as a place name) | Central impact crater void. Code may still use `PIT_*` layout constants (`hollow_layout.gd`) and `hollow_ambiance.gd`'s decorative `Pit*` node names — both explicitly allowed to remain. |

**Do not reintroduce** a separate **Contribution** meter or currency. Residence and band advancement are driven by **Trust** plus Tallies / relocation cost / story gates — not a second progress bar.

The retired terms are retained only in this reference and legacy save migration notes. New player-facing copy, specs, APIs, tests, and implementation work must use the **Use now** column.

## Known follow-ups (not done in the 2026-09-13 pass)

Recorded here so they aren't silently lost — each needs its own scoped pass, not a blind find/replace:

- **Cover → Shortage Risk.** Deep and genuinely ambiguous, not just stale naming: `districts.gd`'s `cover_changed` signal, `get_cover_health()`, `get_cover_for_good()`; `upgrade_hud.gd`'s `CoverLabel`/`ShopCover` nodes and live tooltip/notice text ("How hidden your theft is. Higher Cover = safer diversion..."); `upgrades.gd`'s comments. The open question before renaming: "Cover" reads as *good* (higher = safer), while "Shortage Risk" as described above reads as a *risk* (higher = more likely noticed) — these may be the same value under different polarity, or two different framings of the mechanic. Needs a design decision, not a mechanical rename.
- **`hollow_ambiance.gd` split** (~1859 lines). Bolts together ~12 responsibilities: cliff/backdrop painting, carved rooms, deck architecture, the Vaultward gate, NPC life dressing, bridge visuals, three separate per-district prop kits (Farms/Wick/Cistern), mid-Heart clutter, the lighting system, district ambience animation, camera vignette, and the fog/atmosphere system. The district kits, lighting, and fog read as the cleanest extraction candidates.
- **`upgrade_hud.gd` split** (~700 lines). Mixes shop-modal UI, HUD stat-label refresh, a notice/toast queue, the lie-prompt flow, district production display, and the Materials turn-in transaction path — six largely-independent concerns in one controller.
