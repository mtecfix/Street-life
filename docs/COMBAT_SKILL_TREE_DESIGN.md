# Street Hustler — Melee and Firearms Combat Skill Trees

**Branch:** `feature/melee-firearms-skill-trees`  
**Design goal:** Make combat progression expressive, readable, fair, and fun. The player should feel stronger because they learned a style, not because every upgrade merely adds damage.

> This document is a design specification. The skill-tree data is added separately as a foundation, but purchase UI, persistence, and combat effects must be integrated and playtested before these upgrades are considered playable.

## 1. Player-experience principles

1. **Two real playstyles:** fist fighting and firearms must have separate attacks, controls, feedback, upgrade paths, and encounter rules.
2. **Choice over raw stats:** prioritize new moves, counters, mobility, tactical options, and reliability over stacks of percentage damage.
3. **Readable combat:** telegraph enemy intent, show hit confirmation, communicate stamina/ammo state, and make successful dodges/counters feel rewarding.
4. **Short feedback loops:** award XP for participation and varied play, not only kills. Let players try a new skill soon after earning a point.
5. **No mandatory hybrid build:** a player can specialize in unarmed melee or firearms without being forced to spend points in the other tree.
6. **Avoid dominant upgrades:** use diminishing returns, clear trade-offs, and separate balance tests.
7. **Respect player agency:** allow a reasonably priced respec at a safe hub, ideally free during early onboarding.
8. **Accessibility:** remappable controls, aim assist options, hold/toggle settings, readable telegraphs, and difficulty options.

## 2. Tree structure

Use one shared combat-progression point pool initially, earned from character levels and selected combat challenges. Each node has a point cost and explicit prerequisites. Keep the existing general Power, Endurance, and Footwork skills separate until migration and balance are deliberately designed.

The two trees are independent:

- **Fist Fighting / Melee:** combo flow, defense and counters, movement and control.
- **Firearms:** handling and accuracy, reload and ammo economy, tactical movement and awareness.

A player may invest in both, but the strongest nodes require specialization. Do not gate basic ability to defend oneself behind progression.

## 3. Fist-fighting tree

### Foundation — available early
- **Street Fundamentals (1):** unlock a reliable three-hit light combo and clear hit-confirm feedback. This formalizes the current prototype.
- **Guard Up (1):** unlock a timed block that reduces frontal melee damage; a mistimed block still costs stamina.
- **Quick Step (1):** reduce dodge recovery slightly. It must not grant permanent invulnerability.

### Technique branch
- **Combination Flow (2):** widen the combo input window modestly; successful full combos build a small focus meter.
- **Body Shot (2):** alternate heavy strike that briefly disrupts an enemy windup; higher stamina cost and shorter reach.
- **Counter Window (3):** a well-timed block creates a brief counter opportunity, rewarding timing rather than button mashing.

### Footwork branch
- **Angle Change (2):** a directional dodge creates a short flank opportunity.
- **Ring Control (2):** improve movement control while locked on / near an opponent; no unconditional speed inflation.
- **Slip and Return (3):** a perfectly timed dodge grants one empowered follow-up, with an internal cooldown.

### Mastery choice — choose one
- **Pressure Fighter (4):** maintain combo momentum; stronger sustained offense, but stamina recovery is slower while attacking.
- **Counter Specialist (4):** stronger counter opportunities and safer defense, but lower heavy-strike damage.

## 4. Firearms tree

Firearms are a distinct fictional game system. This tree concerns game feel, readability, and balance—not real-world weapon instruction.

### Foundation — available when the firearms system is introduced
- **Steady Hands (1):** reduce aim reticle drift while stationary.
- **Fast Hands (1):** modestly shorten reload time; reload remains interruptible.
- **Combat Awareness (1):** clearer enemy threat indicators and feedback when an opponent enters the player's flank.

### Handling branch
- **Controlled Burst (2):** improve consistency during short firing bursts; sustained fire still becomes less accurate.
- **Snap Aim (2):** faster transition into aiming, with a small accuracy trade-off while moving.
- **Composure (3):** recover aim stability sooner after taking a hit.

### Readiness branch
- **Quick Reload (2):** shorten reload duration further, with no free ammunition.
- **Ammo Discipline (2):** small chance to retain a portion of unused magazine capacity on a tactical reload; never creates ammunition.
- **Last Round Focus (3):** improved feedback and a modest handling bonus near magazine depletion, not a damage multiplier.

### Mobility and awareness branch
- **Move and Aim (2):** reduce the movement penalty while aiming.
- **Cover Awareness (2):** clearer cover/line-of-sight feedback; cover remains a world mechanic, not a passive damage shield.
- **Reposition (3):** faster recovery after leaving aim mode, enabling deliberate movement between firing windows.

### Mastery choice — choose one
- **Precision Specialist (4):** steadier deliberate shots and faster target acquisition; slower movement while aiming.
- **Mobile Operator (4):** better movement and aim transitions; less stability when firing continuously.

## 5. Shared non-tree fundamentals

Do not bury essential combat readability or accessibility in upgrades:
- Enemy attacks need distinct telegraphs, windup, impact, and recovery.
- Player attacks need hit-stop / hit flash, sound, animation, and clear hit confirmation.
- Stamina and ammunition must be legible before the player commits to an action.
- Encounters must declare `MELEE` or `FIREARMS`; a scene name must not determine combat type.
- Shared encounter lifecycle (health, victory, defeat, rewards, save integration) must be separate from melee and firearms attack controllers.
- Firearms need aim, firing cadence, ammo, reload, projectile/hitscan resolution, range/cover rules, and separate enemy responses before firearm upgrades can have real effects.

## 6. Suggested progression pacing

- Award one point at a predictable level interval, retaining the project's existing one-point-per-level behavior until balance testing says otherwise.
- Early nodes cost 1 point and provide a noticeable quality-of-life or new-action benefit.
- Mid-tier nodes cost 2–3 points and require a meaningful playstyle choice.
- Mastery nodes cost 4 points and require a complete branch investment or equivalent milestone.
- Avoid upgrades that are mandatory to make baseline controls responsive.
- Offer a respec at the Coach / safe hub. Early-game respec should be free; later respec can cost in-game currency, never premium currency.

## 7. Recommended combat feel improvements

### Melee
- Add a short, responsive input buffer so combos feel deliberate rather than brittle.
- Make the third combo hit distinct and satisfying, with a clear recovery window.
- Give blocks, perfect dodges, and counters strong visual/audio confirmation.
- Avoid unavoidable enemy damage; telegraphs must be readable and dodge/block windows fair.
- Give enemy archetypes different rhythms rather than only different health and speed.

### Firearms
- Make aiming and firing responsive, with visible reticle feedback.
- Give each weapon archetype a distinct game feel without relying on excessive damage.
- Make reload decisions meaningful and readable.
- Make cover, range, and line of sight understandable.
- Keep ammunition plentiful enough for experimentation in normal play; scarcity can be a deliberate difficulty/story mode, not a constant frustration.
- Do not let aim assist remove player agency; make it configurable.

## 8. UI and interaction

The tree screen should show:
- Two tabs: **Fist Fighting** and **Firearms**.
- A connected node graph with locked, available, purchased, and mastery states.
- Point balance and each node's cost.
- Prerequisite links and concise descriptions.
- A preview of the actual gameplay change before purchase.
- A confirmation step for irreversible purchases.
- A respec summary showing what will be refunded.

The HUD should only show style-relevant resources during an encounter: stamina and combo state for melee; ammo, reload state, and aim feedback for firearms. Do not clutter the screen with inactive-system information.

## 9. Technical architecture

Recommended components:
- `CombatStyle`: explicit `MELEE` / `FIREARMS` encounter identity.
- `CombatEncounterDefinition`: style, enemy roster, arena, difficulty, rewards.
- `CombatProgression`: owns unlocked node IDs, point balance, prerequisites, purchase and respec rules.
- `MeleeCombatController`: combos, guard, counters, stamina, melee hit detection.
- `FirearmsCombatController`: aim, fire cadence, ammo, reload, ranged hit resolution.
- `CombatSkillTrees`: static node definitions and prerequisite graph.
- `SaveManager`: versioned persistence of purchased node IDs and points.

Keep the combat-style controllers separate. Share only encounter lifecycle and genuinely common services. Do not let firearm attacks call melee combo methods.

## 10. Acceptance criteria and playtest metrics

A first implementation is ready for wider playtesting when:
- Both trees render and show prerequisites correctly.
- Purchases reject missing points, unknown nodes, duplicate purchases, and unmet prerequisites.
- Purchased nodes persist through save/reload.
- Respec restores the correct points and removes the corresponding effects.
- Each purchased node changes a real gameplay behavior; no placeholder-only upgrades.
- A player can complete the current melee content without needing a high-tier upgrade.
- Firearms are not presented as playable until the core firearm loop exists.
- Testers can explain the difference between the two styles and identify why they chose their build.

Track:
- Time from earning a point to spending it.
- Node pick rates and respec rates.
- Deaths / damage taken by encounter and build.
- Combo completion and counter success rates.
- Aim / reload / hit-confirm failure rates.
- Player-reported fun, frustration, and perceived fairness.

Tune around player enjoyment and build variety, not maximum damage output.


---

## 11. Implemented prototype — November 26, 2026

The first playable integration now builds on the design above. The current branch contains:

- An in-game **Combat Training** panel opened with **K** from the neighborhood HUD, with separate Fist Fighting and Firearms tabs, point costs, prerequisite-aware locked/available/unlocked states, and a confirmation before respec.
- Purchases, unlock IDs, and respec refunds owned by `GameState`; the existing level-up skill-point pool is shared, while each discipline has independent unlocks.
- Save format version 6 stores the two unlock lists. Older v1–v5 saves remain loadable and simply start with empty combat trees.
- A playable arena prototype with **TAB** switching between fist fighting and firearms. Firearms include aim mode (**Z**), firing (**F**), an on-screen aim line, magazine/reserve ammunition, reload timing (**R**), hit confirmation, and distinct handling bonuses. Melee includes the existing combo/heavy/dodge loop plus unlockable guard (**C**), body shot (**R**), counter, combo, and dodge-follow-up effects.
- A focused Godot 4.3 GitHub Actions workflow and a regression test for purchases, prerequisites, independent trees, persistence, and respec.

### Prototype boundaries

This is a functional first pass, not the final combat presentation. The arena still uses its existing polygon actors and simplified enemy behavior. Melee input has a short buffer near the end of attack recovery to make combo inputs less brittle. Firearms currently use deterministic hit resolution rather than projectile physics, but shots now respect simple line-of-sight checks against the arena's cover props. The `Cover Awareness` upgrade extends acquisition range; it does not let shots pass through obstacles. Weapon-specific animations, audio, recoil, enemy firearm behavior, and a persistent equipment inventory are not included. The combat encounter now offers three temporary weapon loadouts (9mm Sidearm, Compact SMG, Street Carbine), each with its own magazine, reserve pool, range, damage, cadence, and reload profile. The arena delegates reusable melee calculations to `MeleeCombatController` and firearm profiles/handling to `FirearmCombatController`; encounter lifecycle and presentation remain in the arena. This is an incremental controller boundary, not a full scene-level actor/controller rewrite.

### Controls

| Input | Action |
|---|---|
| WASD / arrows | Move |
| TAB | Switch fist fighting / firearms |
| SPACE | Melee combo |
| Q | Heavy strike |
| C | Guard (requires Guard Up) |
| R | Body Shot (requires unlock) / reload |
| SHIFT | Dodge |
| Z | Aim toggle (firearms) |
| F | Fire (firearms) |
| K | Open/close Combat Training in the neighborhood |

### Effect mapping

All currently purchasable nodes have a gameplay effect in the prototype: melee upgrades change combo timing/output, dodge cost/follow-up, attack range, body-shot access, guard/counter behavior, or stamina recovery; firearm upgrades change aim stability, firing cadence, reload duration, threat warning time, moving-shot penalty, recovery after being hit, target range, movement, or mastery handling. Balance values are initial tuning values and should be revisited after playtests.

The focused CI workflow is the authoritative next validation step. Do not mark the PR ready to merge until Godot 4.3 import and headless tests pass.


### Design research applied

A second design pass used these principles to shape the playable implementation:

- **Choices must be distinct, legible, balanced, and limited.** A node should communicate its real gameplay outcome, not hide behind vague stat labels. The shared point pool makes investment an opportunity-cost decision; independent trees preserve separate playstyle identity.
- **Knowledge and execution must grow together.** A new defensive action such as guard/counter should be introduced with a readable threat window, then tested in encounters that reward timing rather than raw stats.
- **Give the player an active defensive verb.** Guard and counter turn enemy windups into decisions instead of passive damage waiting; dodge remains a universal fallback.
- **Favor meaningful mechanics over node count.** Numerical bonuses are kept modest and attached to a concrete action or tradeoff. Mastery nodes intentionally define a playstyle rather than simply being the largest damage upgrade.

References:
- [Upgrades, Equipment, and Skill Trees — Game Developer](https://www.gamedeveloper.com/design/upgrades-equipment-and-skill-trees)
- [The Logic Behind Violence: A Primer on Combat System Design — Game Developer](https://www.gamedeveloper.com/design/the-logic-behind-violence-a-primer-on-combat-system-design)
- [Godot 4.3: Saving games](https://docs.godotengine.org/en/4.3/tutorials/io/saving_games.html)
- [Godot 4.3: Using CharacterBody2D](https://docs.godotengine.org/en/4.3/tutorials/physics/using_character_body_2d.html)


### Additional implementation — controller separation and loadouts

- `MeleeCombatController` centralizes combo, heavy-strike, dodge, and counter calculations. The arena remains responsible for stamina consumption, hit presentation, enemy state, and encounter rewards.
- `FirearmCombatController` owns three distinct weapon profiles and the calculations for shot damage, cadence, and reload timing. Press **G** during a firearms encounter to cycle between the sidearm, SMG, and carbine. Each weapon retains its own loaded and reserve ammunition for the duration of that encounter.
- Ranged shots are checked against the visible arena cover props. A blocked shot produces explicit line-of-sight feedback; players must reposition rather than shoot through obstacles.
- Melee light/heavy inputs have a short late-recovery buffer. **Composure** now shortens post-hit aim recovery rather than adding unrelated damage.


## 12. Persistent equipment and enemy archetypes — November 26, 2026

The next gameplay slice replaces encounter-only firearm access with permanent ownership and makes the three current encounters behave differently.

### Persistent firearm ownership
- The sidearm is the starter weapon. The Compact SMG costs $180 and the Street Carbine costs $320 at Maya's Market.
- Market inputs **4** and **5** purchase the SMG and carbine. A successful purchase automatically equips the new weapon.
- Owned weapons and equipped weapon ID persist in save format **v7**. Existing v1–v6 saves migrate with the starter sidearm.
- Each owned weapon retains its magazine and reserve ammunition across encounters and application saves. Firing and completed reloads update the persistent ammunition state.
- **G** cycles only through firearms the player owns. Purchasing/equipping is separate from firearm skill-tree unlocks.

### Enemy archetypes
- **Pressure Fighter** (corner challenger): advances directly and keeps close pressure; average recovery.
- **Counter Guard** (shopfront agitator): controls a preferred distance, has a longer readable windup, hits harder, and offers a longer punish window.
- **Skirmisher** (alley runner): circles and repositions, attacks from a longer reach, deals lighter damage, and recovers faster.
- Archetype movement and recovery rules live in `EnemyCombatController`; the arena retains health, telegraphs, and encounter lifecycle.

### New validation coverage
- `test_weapon_inventory.gd` covers purchase costs, duplicate/unknown rejection, equip rules, ammo persistence, and save/load.
- `test_enemy_combat_controller.gd` covers the three distinct movement profiles and recovery windows.
- The focused CI workflow now runs both tests. Runtime status remains for the developer to verify.
