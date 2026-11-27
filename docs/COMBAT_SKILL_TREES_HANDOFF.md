# Combat Skill Trees — Developer Handoff

**Branch:** `feature/melee-firearms-skill-trees`  
**Pull request:** https://github.com/mtecfix/Street-life/pull/21  
**Purpose:** Feature implementation handoff. This document is not a claim that Godot runtime validation has passed.

## Delivered in this branch

### Progression
- Independent `melee` and `firearms` unlock lists.
- Shared level-up skill-point pool.
- Prerequisite and duplicate-purchase checks.
- Per-discipline respec and point refunds.
- Combat Training UI with tabs, confirmation prompts, and unlock states.
- Versioned save/load support for both trees.

### Melee
- Three-hit combo and heavy strike.
- Timed frontal guard, body shot, counter opportunity, dodge follow-up.
- Short input buffer for light/heavy attacks near the end of recovery.
- `MeleeCombatController` centralizes reusable melee calculations.

### Firearms
- Aim, fire, reload, and weapon cycling controls.
- Permanent ownership: sidearm starter, SMG ($180), carbine ($320); purchases are available at Maya's Market with keys 4 and 5.
- Save v7 stores owned weapons, equipped weapon, and each weapon's magazine/reserve ammunition; v1–v6 saves migrate with the starter sidearm.
- Weapon-specific damage, range, firing cadence, and reload duration.
- Simple line-of-sight blocking against arena cover props.
- `FirearmCombatController` owns weapon profiles and handling calculations.
- Ammunition persists between encounters; G cycles only owned firearms.

### Enemy behavior and feedback
- Pressure fighter, counter guard, and skirmisher movement/recovery profiles.
- Corner Set, Market Crew, and Alley Runners faction modifiers.
- Floating damage callouts, hit flashes, and pulsing archetype telegraphs.

### Sequential encounters
- Corner Set and Market Crew encounters contain two sequential opponents; Alley Runners escalate through three.
- Each wave defines its own name, archetype, faction, health, movement speed, attack range, damage, and windup.
- Player health, stamina, and ammunition carry through waves; rewards and mission completion occur only after the final opponent.

### Gang-combat coordination foundation
- `GangCombatController` is a data-only coordinator for a future simultaneous-enemy arena implementation.
- It supports independent combatant health/alive state, living-target cycling, explicit target selection, defensive roster snapshots, crowd-slot offsets, and round-robin attack scheduling with a minimum interval.
- `test_gang_combat_controller.gd` exercises these rules; the Godot 4.3 CI workflow now runs it.
- **Important boundary:** the arena has not yet been refactored to spawn or render multiple active combatants. The controller is groundwork, not a claim that simultaneous gang combat is playable.

## Controls

| Input | Action |
|---|---|
| TAB | Switch fist fighting / firearms |
| SPACE | Melee combo |
| Q | Heavy strike |
| C | Guard (requires Guard Up) |
| R | Body Shot (requires unlock) / reload |
| SHIFT | Dodge |
| Z | Aim |
| F | Fire |
| G | Cycle firearm |
| K | Combat Training in neighborhood |

## Suggested developer validation

1. Open `game/project.godot` with Godot 4.3 and run a full project import.
2. Check class registration for `CombatSkillTrees`, `MeleeCombatController`, `FirearmCombatController`, `EnemyCombatController`, and `GangCombatController`.
3. Run combat/progression integration tests, weapon inventory, enemy archetype/faction, encounter wave, and gang coordination tests.
4. Verify each skill node's effect and prerequisite path, including respec and save/load migration.
5. Exercise each firearm at minimum/maximum range, with and without cover, while moving and aiming.
6. Verify purchased weapons and ammo persist after closing/reopening the game; confirm G cycles only owned firearms and interrupted reloads do not transfer ammo.
7. Verify the melee input buffer only queues one action and cannot trigger after encounter completion.
8. Play each encounter in both styles and check health, rewards, XP, mission flags, and return-to-neighborhood behavior.
9. Verify pressure/counter/skirmisher movement patterns, telegraph colors, damage callouts, and hit flashes feel readable.
10. When the arena integration is implemented, verify simultaneous enemy spawning, target cycling, defeated-member removal, crowd spacing, staggered telegraphs, and final-only rewards.
11. Test mouse/controller accessibility and remappable controls as a follow-up.

## Known intentional prototype limits

- Combat actors remain polygon placeholders; animation, sound, recoil, hit-stop, and projectile visuals are not included.
- Firearm hits are deterministic range/line-of-sight resolutions, not simulated projectiles.
- Cover geometry is a small set of arena rectangles, not a full physics/collision cover system.
- Enemy firearm behavior is not included.
- The current arena still coordinates a single active opponent. The new gang controller is not yet connected to arena actor nodes, player attacks, or enemy attack resolution.

Please treat this as a feature branch requiring normal code review and runtime validation before merge.
