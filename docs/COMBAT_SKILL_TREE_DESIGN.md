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
