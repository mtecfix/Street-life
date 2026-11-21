# Sprint 3 — Living Neighborhood

## Implemented
- Scheduled neighborhood residents: Rico, Maya and Dre.
- Day/time HUD driven by WorldClock.
- Storefront and apartment entrance interactions.
- Maya's Market interior with three purchasable consumables.
- Inventory capacity, prices, item counts and health restoration.
- Apartment interior with an eight-hour rest action.
- Reputation and NPC relationship tracking.
- Save schema v3 with backward-compatible v1/v2 loading.
- Combat now starts from saved health, writes damage back to player state, and saves encounter outcomes.

## Controls
- WASD / arrow keys: move.
- E: interact with people, job site, doors, bed and exit.
- I: inspect inventory.
- F: use a snack.
- H: use a first-aid kit.
- In Maya's Market: 1 buys a snack ($5), 2 buys a first-aid kit ($18), 3 buys soda ($8).
- Space: attack in combat.
- Shift: dodge in combat.
- Esc: retreat from combat or leave an interior.

## Validation checklist
- [ ] Open the project in Godot 4.3 and confirm there are no parser/import errors.
- [ ] Verify NPC availability at different game hours and across midnight.
- [ ] Enter and exit both interiors; confirm neighborhood position is restored.
- [ ] Purchase all three items and verify cash, capacity and item counts.
- [ ] Use snack and first-aid kit; verify health restoration and inventory decrement.
- [ ] Rest in the apartment; verify health restoration and an eight-hour clock advance.
- [ ] Load an existing v1 save and a v2 save; verify defaults and preserved progress.
- [ ] Save and reload a v3 game; verify inventory, reputation and relationships.
- [ ] Complete and lose the first combat encounter; verify health and mission state.
- [ ] Export and play the web build in target browsers.

Runtime validation is still required. CI Web export success is not equivalent to gameplay validation.
