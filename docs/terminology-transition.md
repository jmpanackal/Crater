# Terminology transition

Current canonical terms:

| Use now | Retired term | Meaning |
| --- | --- | --- |
| **Trust** | Social Standing / Standing | The Hollow's measure of how much people trust the player. It is affected by attendance, lies, forbidden work, and public help. Gates favors, alibis, watched/delayed upper access, and later recruitment. |
| **Steal** / **theft** | Siphon / siphoning | The forbidden diversion of named District production for a personal work-rig upgrade. **Shortage Risk** is the measure of how likely missing production is to be noticed later. |
| **Tallies** | (keep) | Personal work pay from public Material turn-ins; used for openly requisitioned, sanctioned gear. |
| **Materials** | Salvage (as category) | Dig finds you carry and turn in. Transitional dig-haul id `salvage` may remain in code until Tallies UI fully lands. |
| **District production** | stocks / stock (player-facing) | Named communal goods (Glowrations, Presswater, etc.). |
| **Firmament** | Vault / roof (formal) | Sacred ceiling; natural crash-sealed strata. |
| **Devil’s Mouth** | Cap / Pit (as place names) | Central impact crater void. Code may still use `PIT_*` layout constants. |

**Do not reintroduce** a separate **Contribution** meter or currency. Residence and band advancement are driven by **Trust** plus Tallies / relocation cost / story gates — not a second progress bar.

The retired terms are retained only in this reference and legacy save migration notes. New player-facing copy, specs, APIs, tests, and implementation work must use the **Use now** column.
