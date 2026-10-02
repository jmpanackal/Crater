# Hollow chunk map — Opening route

Player-scale spatial specification for the Hollow. This is the next level below the approved macro layout in [`refs/hollow-layout-act1-approved-2026-09-11.png`](refs/hollow-layout-act1-approved-2026-09-11.png): it describes what a player can actually see, traverse, and understand in normal side-view play.

**Approved `H-4-11` visual reference:** [`refs/hollow-opening-home-court-approved-2026-09-11.png`](refs/hollow-opening-home-court-approved-2026-09-11.png). It is a Home Court visual reference, not yet a seam-qualified implementation asset. Use it for player-scale composition, weathered crater material palette, and the bioluminescent Wicklamp family—not as a literal final asset or complete collision layout.

**Full-Hollow atlas:** [`hollow-chunk-atlas.md`](hollow-chunk-atlas.md) and its interactive board, [`refs/hollow-chunk-atlas.html`](refs/hollow-chunk-atlas.html). It reserves every chunk slot in the city and is the visual-to-implementation handoff surface; only user-approved images appear in the board.

**Scope:** the opening civic-work route only. It begins at the player’s Lower-terrace home and ends at their first arrival in Mid Heart. It is a continuous world, not a succession of loading-screen rooms.

**Read with:** [`mechanics-canon.md`](mechanics-canon.md) (§15 opening civic-excavation scenario, §52 opening route), [`story.md`](story.md), [`art-direction.md`](art-direction.md), [`materials.md`](materials.md), and [`hollow-build-brief.md`](hollow-build-brief.md).

## Opening-route contract

- Teach a lived-in home, sideways civic travel, sanctioned lateral excavation, a first ambiguous contradiction, and public vertical transport—in that order.
- The first trip goes **west and outward**, away from Devil’s Mouth. The player must never mistake Bottom-West for a routine descent into the crater.
- No ordinary camera frame reveals the whole Hollow. Every chunk may imply nearby vertical life through balconies, windows, distant rails, sound, foreground rock, or a partial lift shaft, but should show only a local section of the city.
- The opening route must feel occupied: residents use shared spaces, crews handle carts and tools, and work continues around the player. Ambient façades, doors, and sound imply many more homes than are entered.
- Use walkable ramps, short stepped rises, and overlapped rooms/terraces. Avoid flat decks whose only purpose is to connect two labels.

## Route map

```text
[H-4-11 Home Court]
      ↓ / westward route
[H-3-11 Lower Switchback] ── local doors + enclosed switchback toward the worker band
      ↓ / westward route
[H-2-11 West Dispatch Yard] ── First Steward's public-work assignment
      ↓ / outward worker corridor
[Bottom-West Approach] ── Mouth no longer visible
      ↓
[Bottom-West Threshold] ── checkpoint and crew staging
      ↓
[First Expansion Gallery] ── starter public Materials
      └── [Collapsed Side Chamber] ── optional clue; deeper route locked
      ↓ / return with completed task
[Lower Switchback / Mid Landing] ── broad worker stairs and ramps → West Exchange / Mid Heart
```

## Chunks

### H-4-11 — Home Court

**Purpose:** establish that the player belongs to the Hollow before they are asked to change it.

- Small, private Lower-terrace unit opening to a communal wash/cook court. The player can see bed/rest point, lockbox storage, work surface, delivery hook, and one or two personal details without the interior becoming a tutorial warehouse. Its carved/plastered thresholds, stepped stoop, simple geometric relief, pottery, woven Sutral fibre, and household markings carry the Hollow’s local ancient/ritual craft language without copying a real-world sacred site.
- The court has a visible shared stove, pipe-fed ration-conscious wash basin, neighbour doors, hanging laundry, small fungal food/insulation mats, and a modest vertical back stair/landing. It is warm, occupied, and protected from the void by surrounding wall rock. Its plaster is uneven, soot- and moisture-stained, and broken at edges to reveal slate-brown crater rock, oxidized repairs, mineral seepage, and patchwork maintenance. Light comes from varied ceramic/copper Wicklamp niches, mineral-glass glow bowls, and bioluminescent wick cores—not generic identical lanterns or leafy surface plants.
- **Traversal:** one shallow westward ramp into `H-3-11`; a short local back stair to an enclosed shared landing. No large lift or long void view yet.
- **Camera read:** intimate; show other dwellings above/below only in fragments. The city should feel bigger than the home without turning the first frame into an overview.
- **State change:** none at first. This remains the player’s reliable return point after the job begins, holds personal Material storage and rest, and later hosts the crude concealed workspace once forbidden progression starts.

### H-3-11 — Lower Switchback

**Purpose:** introduce the lower worker band as uneven, inhabited horizontal space.

- A broad, irregular terrace that slopes down and back up around a carved support mass. Foreground railings, a projecting room, and a recessed maker nook create layers rather than a single line.
- A narrow protected sightline through a rock fracture may give the first partial view of Devil’s Mouth, but the route itself stays rock-backed and enclosed; it is not a pit balcony and never frames Mid Heart in full.
- **Traversal:** main westward route; a short optional loop under an overhang returns to the route and teaches that vertical offsets can create shortcuts later.
- **Life:** shift workers, food delivery, repair chatter, a family doorway, and an ambient craftsperson. No first-use shop interface is required here.
- **Camera read:** player-scale worker quarter, not a central plaza.

### H-2-11 — West Dispatch Yard

**Purpose:** make public work legible and give the first official excavation its social stakes.

- A wider stepped civic terrace with crew board, tool racks, cart turntable, materials scales, support-beam stacks, and waiting crews. It should feel busy enough to support a real district-expansion project.
- The First Steward gives the player a brief direct assignment here during Rousing/early Working. The fiction is clear: Bottom-West is a sanctioned new district expansion; a foreman and crew then handle ordinary shift logistics. The objective is environmental (help open the gallery), not a checklist UI.
- **Traversal:** long lateral apron with a raised foreman platform and a lower cart lane; west exit continues to Bottom-West Approach. An east return route leads toward `H-3-11`, not directly to Mid Heart.
- **Camera read:** spacious enough for a small crowd but still embedded in wall construction. Distant pipes/rails suggest work continues above and behind the visible tier.
- **State change:** accepts the first work order and opens Bottom-West threshold access.

### Bottom-West Approach

**Purpose:** make distance and direction unmistakable.

- A long, lived-in outward corridor threaded through older worker homes, bracing, supply racks, and occasional small terraces. It moves laterally away from the Mouth; the central void is no longer visible.
- Rock thickens around the route. The visual language shifts from civic timber/decking to patched braces, impact-fill stone, cart grooves, and work lamps.
- **Traversal:** two or three shallow elevation changes, one bypass under a residence extension, and a cart-side service ledge. No deep vertical traversal gate.
- **Camera read:** the city recedes behind the player; this is an edge-of-town journey, not a work wall placed beside the market.

### Bottom-West Threshold

**Purpose:** establish that excavation is regulated community labor.

- Braced lateral tunnel mouth with shift board, Warden/foreman presence, warning lamps, tool check, material crates, crew queue, and a visible deeper tunnel receding sideways.
- The Warden is a civic-safety presence, not an enemy encounter. Their role is to make rules and restricted behaviour understandable before later secrecy systems matter.
- **Traversal:** a broad, safe entry into First Expansion Gallery plus an optional raised observation nook. The player does not enter Devil’s Mouth from here.
- **Camera read:** lateral depth is conveyed with repeating braces, lamps, and carts vanishing into the wall.

### First Expansion Gallery

**Purpose:** teach sanctioned digging and the first Material return.

- A roomy, stable side gallery cut through ordinary impact-fill and crater-wall rock. Crew members visibly dig, brace, sort, and cart common finds; the player is part of an existing shift.
- Most rock is worthless obstruction. Useful starter Material deposits (e.g. Ravelstone, Sutral) are exposed naturally without revealing obvious ship identity, and the player decides whether job-relevant Material goes to the worksite collection. Hauling it teaches the tether and stamina reservation. The initial player dig space has clear seam readability, safe headroom, and a distinct return route.
- **Traversal:** one broad work floor broken by small ramps and material piles; a side branch leads to Collapsed Side Chamber. Do not make it a rectangular mine tunnel.
- **Camera read:** hard lateral rock volume, busy foreground work, blocked deeper route beyond a marked unstable/unfinished continuation.
- **State change:** completing the assigned extraction/brace task changes the dispatch yard and unlocks the return-ascent/switchback prompt.

### Collapsed Side Chamber

**Purpose:** introduce optional discovery without derailing the public-work loop.

- A short, partially collapsed branch off First Expansion Gallery. It asks for a simple spatial read—crawl/step/short climb around fallen supports or a cart obstruction—not a generic key puzzle.
- Contains one ambiguous old-metal fragment, work record, or inconsistency that foreshadows the service-spine mystery without saying “spaceship.”
- A sealed/deeper continuation is visibly present but inaccessible. It teaches that exploration will later outgrow the first civic job and creates the first **responsibility vs curiosity** decision.
- **State change:** optional knowledge or future lead only; it must not block the public return.

### Return and Lower Switchback

**Purpose:** convert the completed outward trip into the first upward civic transition without pretending the west lift runs from the bottom.

- On return, West Dispatch Yard and Lower Switchback gain small state changes: crew acknowledgement, carts moving, a posted update, or a new conversation. The player feels they have materially helped rather than merely cleared a tutorial cave.
- A broad worker switchback is a substantial, safe civic transfer route—not a ladder tacked onto a platform. It has rails, rest landings, delivery hooks, and glimpses of the higher west lift’s gauge and warning bell along the wall.
- **Traversal:** the player climbs from the lower worker band toward West Exchange/Mid Heart through shallow ramps, steps, and transfer terraces. The west civic lift begins at the Wickwork/Mid band and is first ridden later toward High-West; the camera still prioritizes the player and nearby structure.
- **State change:** arrival unlocks the first Mid Heart chunk-map pass; Bottom-West remains revisitable as a working public site.

## Opening-slice verification

- A new player can identify their home, the sanctioned work route, the lateral dig destination, and the return ascent without relying on a minimap.
- The route has at least three meaningful horizontal stretches and several small elevation changes before the player's later first public lift ride.
- The player sees Devil’s Mouth briefly in `H-3-11` and much more strongly only during the worker-switchback transition; it is not visible from Bottom-West.
- Bottom-West reads as a real expanding district with workers and unfinished depth, not a disposable tutorial cave.
- The optional Collapsed Side Chamber clue is ambiguous, contextual, and non-blocking.
- No required route relies on a main ladder or asks the player to descend Devil’s Mouth.

## Next slice

Map the first Mid Heart arrival at player scale: West Exchange, the first view of the Ritual Raft and the Pulse, Lower Freight connection, and the east Cistern-freight approach. Do not map the entire Heart in one camera diagram.
