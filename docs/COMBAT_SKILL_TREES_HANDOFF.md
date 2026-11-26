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
2. Check class registration for `CombatSkillTrees`, `MeleeCombatController`, `FirearmCombatController`, and `EnemyCombatController`.
3. Run combat/progression integration tests, `test_weapon_inventory.gd`, and `test_enemy_combat_controller.gd`.
4. Verify each skill node's effect and prerequisite path, including respec and save/load migration.
5. Exercise each firearm at minimum/maximum range, with and without cover, while moving and aiming.
6. Verify purchased weapons and ammo persist after closing/reopening the game; confirm G cycles only owned firearms and interrupted reloads do not transfer ammo.
7. Verify the melee input buffer only queues one action and cannot trigger after encounter completion.
8. Play each encounter in both styles and check health, rewards, XP, mission flags, and return-to-neighborhood behavior.
9. Test mouse/controller accessibility and remappable controls as a follow-up.

## Known intentional prototype limits

- Combat actors remain polygon placeholders; animation, sound, recoil, hit-stop, and projectile visuals are not included.
- Firearm hits are deterministic range/line-of-sight resolutions, not simulated projectiles.
- Cover geometry is a small set of arena rectangles, not a full physics/collision cover system.
- Three melee enemy archetypes now have distinct movement/recovery: pressure fighter, counter guard, and skirmisher. Enemy firearm behavior is not included.
- Melee and firearm controllers are reusable rules modules, while the current arena script still coordinates input, actors, encounter state, and presentation.

Please treat this as a feature branch requiring normal code review and runtime validation before merge.


## Latest feature slice

- Permanent weapon purchasing is integrated into Maya's Market: **4** buys the Compact SMG ($180), **5** buys the Street Carbine ($320). The sidearm remains the starter weapon.
- Save format is now **v7** and persists ownership, equipped weapon, and per-weapon magazine/reserve ammo. Older v1–v6 saves migrate with only the starter sidearm.
- Enemy behavior is no longer one generic chase loop: the corner challenger pressures directly, the shopfront guard holds distance and punishes mistakes, and the alley runner circles and repositions.
- New test scripts cover weapon inventory persistence and enemy archetype movement. The CI workflow includes both.
