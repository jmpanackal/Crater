# UI reference: what similar games do, and what Krater took (AI, 2026-10-04)

The user asked (2026-10-04) for Krater's UI to copy what is considered best in similar games instead of reskinning the prototype HUD. This is the research and the decisions it produced. The canon still governs: [`mechanics-canon.md`](mechanics-canon.md) section 55 (the world speaks first, UI confirms) and the UI restraint rules in [`art-direction.md`](art-direction.md).

## Conventions the sources agree on

- **Persistent information lives in the corners; momentary information appears in the centre or beside its subject; narrative UI sits bottom-centre** (Stray Spark, "The Invisible Interface"). Hollow Knight keeps its masks and Soul vessel top-left and out of the way; Terraria puts the minimap in a square frame in the upper-right with the clock beside it; Core Keeper keeps its bars and hotbar along the bottom of the screen.
- **Show less by default.** Start with nothing and add an element only when you can justify its constant presence; contextual elements (interaction prompts, status effects, damage indicators) appear when relevant; full map, inventory, stats and quest log are on demand.
- **Menus are 3 to 7 tabs, or a full-screen overlay for complex systems**; feedback animations are 100 to 300 ms and never block input; high contrast and readable at the smallest scale.
- **Pixel-art layouts snap to an integer pixel grid and scale in whole numbers.**
- Hollow Knight (health as a row of masks, soul as a vessel, currency as a separate counter, a minimal bottom/corner HUD that matches the art) and SteamWorld Dig (a digging game whose HUD is a few meters and a loot count, with upgrades in a menu) are the closest genre matches.

## What Krater took

| Pattern | Source games | In Krater |
| --- | --- | --- |
| Vital top-left as a gauge with an emblem, segmented, with a trailing "ghost" that shows what an action cost and a red flash when it runs dry; stamina is green (the convention) with a bolt emblem, never a dial that could be mistaken for a clock | Hollow Knight, Dead Cells | `ui_stamina_bar.gd`: green, segmented in tenths at a fixed full width (canon), blocked segments hatched by hauling, Rig Strain and Fatigue, a ghost trail, a flash on Overexertion |
| Minimap small in the top-right corner | Terraria | `hollow_minimap.gd` scaled small top-right |
| The time of day as a small marked indicator, never a bar next to a vital | Terraria, Dead Cells | top-centre: a tiny Pulse mark, its four lamps and the phase name; time left on hover (`hud.gd`) |
| What you carry as a numbered hotbar at the bottom-centre | Terraria, Core Keeper, Minecraft | `ui_hotbar.gd`: one socket per Rig Gear slot with its number, capacity pips under it (read-only: refits happen at a station). PLACEHOLDER: while nothing is mounted the sockets preview the Approved Gear that exists (pick, harness, wrap, frame), dimmed; the real starting loadout is not decided |
| Interaction prompt as a small bubble over the thing, with a key cap, only when Interact does something | Hollow Knight, Ori, Hades | `hud.gd`: a compact "E verb" bubble with a pointer above the interactable, hidden while a panel is open; a lift that is already here, locked or parked offers no prompt |
| Everything else on demand | all | Standing [T], the Rig [G] or station Interact, Approved Gear [Q], Journal [J], map [M] |
| A load/currency chip only when relevant | Hollow Knight (geo), SteamWorld Dig (loot) | a load chip under the gauge only while hauling |

## Not taken, on purpose

- Hearts or masks for health: Krater has no health bar in the canon; stamina is the vital.
- A permanent numeric Trust or Tallies readout: canon shows Trust as a qualitative standing you open, and Tallies live in the orders panel.
- An always-on controls cheat sheet: it fades after the first seconds (`H` brings it back).

## Next steps (not built)

- One tabbed "ledger" screen (Rig, Standing, Orders, Journal, Map; 5 tabs) with the current hotkeys as shortcuts to a tab, instead of separate modals.
- Real UI art in place of the code-drawn plates, icons and emblem.
- Gear icons: the hotbar shows the first letter of each Gear's name until there is art.

## Sources

- Stray Spark, [The Invisible Interface](https://www.strayspark.studio/blog/game-ui-ux-design-principles)
- Inlingo Games, [How to Create a HUD to Strengthen Your Game's Design](https://inlingogames.com/blog/how-to-create-a-hud/)
- Mechanics of Magic, [Hollow Knight: Mechanics and Dynamics](https://mechanicsofmagic.com/2021/04/08/hollow-knight-mechanics-and-dynamics/)
- Terraria Wiki, [Minimap](https://terraria.fandom.com/wiki/Minimap)
- Core Keeper Wiki, [Controls](https://core-keeper.fandom.com/wiki/Controls)
