# Sprint 4 — Vertical Slice

## Implemented in this increment
- Five scheduled residents with distinct roles, dialogue, and daily availability: Rico, Maya, Dre, Nia, and Coach.
- Original five-character pixel-style resident sprite strip, used by the neighborhood renderer.
- Branching corner mission: choose to stand your ground or protect the shop.
- Branch consequences persist in save schema v4: mission choice/outcome, cash reward, local/rival reputation, and Maya relationship changes.
- Three combat profiles: corner challenger, faster shopfront agitator, and tougher alley runner.
- Post-mission alley encounter unlocked through Dre; completion is persisted in world flags.
- Save loader remains backward compatible with v1-v3.

## Controls and flow
- E: interact with residents, doors, mission marker.
- At the mission marker: press 1 to stand your ground or 2 to protect the shop.
- WASD / arrows: move; Space: attack; Shift: dodge; Esc: retreat.
- Talk to Dre after completing the corner mission to unlock the alley encounter.

## Validation checklist
- [ ] Godot 4.3 import and parser validation.
- [ ] Verify all five NPC schedule windows.
- [ ] Verify both mission choices, rewards, reputation and relationship consequences.
- [ ] Verify alley encounter unlock, victory persistence and defeat behavior.
- [ ] Verify save schema v4 and v1-v3 migration.
- [ ] Browser performance and usability checks.

Runtime/browser validation remains required; a successful export alone does not prove gameplay correctness.
