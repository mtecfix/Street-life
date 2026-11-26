# Street Hustler — Player Movement Research and Combat-Type Audit

**Repository:** `mtecfix/Street-life`  
**Project:** Street Hustler  
**Engine:** Godot 4.3  
**Research date:** November 26, 2026  
**Scope:** Static review of the player movement implementation, combat movement, progression integration, and whether the code distinguishes fist fights from gun fights.

> This is a source-code and design-pattern review. It is not a live playthrough, a Godot runtime test, or a benchmark of the commercial games discussed below. Commercial-game comparisons use public product/developer information; they do not imply access to proprietary source code.

## 1. Executive findings

Street Hustler has a sound minimal foundation for top-down movement, but movement is implemented differently in the neighborhood and combat scenes. The neighborhood player is a `CharacterBody2D` moved through Godot's physics API. The combat player is currently a `Polygon2D` whose position is changed directly. That split will make collision behavior, movement tuning, animation, and future combat mechanics harder to keep consistent.

A second important finding: **the current code does not implement a distinction between fist fights and gun fights.** The combat currently present is a melee/fist-fighting prototype. It has combo attacks, heavy attacks, stamina, dodge/invulnerability, enemy windups, and close-range damage. A repository search for `gun`, `firearm`, `weapon`, `shoot`, `bullet`, and `melee` did not find firearm or ranged-combat implementation. There is no weapon inventory, ammunition, projectile, aiming, firing, reload, or firearm damage pipeline in the inspected code.

This is an implementation gap, not merely a naming problem. It should be addressed explicitly in the combat architecture before gun fights are added.

## 2. Current player movement implementation

### 2.1 Neighborhood movement

File: `game/scripts/player/player_controller.gd`

The current development-branch implementation is:

```gdscript
extends CharacterBody2D

func get_current_move_speed() -> float:
    # Keep exploration movement in sync with skill progression and combat stats.
    return GameState.get_player_speed()

func _physics_process(_delta: float) -> void:
    var direction := Input.get_vector("move_left", "move_right", "move_up", "move_down")
    velocity = direction * get_current_move_speed()
    move_and_slide()
```

Strengths:
- Uses `CharacterBody2D`, the Godot body intended for script-controlled character movement.
- Uses `Input.get_vector()`, which provides a normalized directional vector and avoids faster diagonal movement.
- Moves during `_physics_process()`.
- Uses `move_and_slide()` so the physics engine can resolve collisions and sliding.
- Reads speed from `GameState.get_player_speed()`, connecting exploration movement to progression.

Current limitations:
- Movement changes instantly to full speed and instantly stops; there is no acceleration or deceleration curve.
- The controller does not expose a movement state or facing direction for animation and other systems.
- The player scene has a collision shape, but its controller does not explicitly set top-down `motion_mode`.
- The project Input Map inspected currently defines keyboard movement; gamepad bindings are not present in the inspected configuration.

### 2.2 Progression integration

File: `game/scripts/autoload/game_state.gd`

`get_player_speed()` returns a base speed of 225 and adds 12 per Footwork rank.

| Footwork rank | Speed (pixels/second) |
|---:|---:|
| 0 | 225 |
| 1 | 237 |
| 2 | 249 |
| 3 | 261 |

This is a good progression pattern: one authoritative stat function supplies the speed value. Keep this as the source of truth rather than duplicating formulas in individual scenes.

### 2.3 Combat movement

File: `game/scripts/combat/combat_arena.gd`

Combat creates the player as a `Polygon2D` and updates its position in `_process(delta)`:

```gdscript
var direction := Input.get_vector("move_left", "move_right", "move_up", "move_down")
player.position += direction * GameState.get_player_speed() * delta
```

Dodge movement also directly adds a displacement to `player.position`. The combat arena then clamps the player's coordinates to hard-coded bounds.

Consequences:
- Combat movement bypasses `CharacterBody2D` collision handling.
- Combat and neighborhood movement do not share the same movement implementation.
- Arena boundaries are manual clamps rather than world collision geometry.
- Future cover, obstacles, moving hazards, and character-to-character collision will need additional custom logic.
- Dodge is a separate displacement mechanism rather than a movement mode integrated with a physics body.

The two scenes currently share the speed statistic, but they do not share a movement controller.

## 3. Published Godot-game comparisons

The purpose of these comparisons is to identify transferable design patterns, not to copy another game's proprietary implementation.

### 3.1 Brotato

Blobfish's `Brotato` is featured by Godot. Its public feature description highlights many playable character builds, hundreds of items and weapons, and enemy difficulty options. This is relevant because movement speed can be part of a wider build/stat ecosystem rather than a standalone constant.

Potential lessons for Street Hustler:
- Keep movement speed as a data-driven character statistic.
- Ensure upgrades and equipment feed through a consistent stat pipeline.
- Make stat effects legible to players.
- Balance movement alongside combat, enemy pressure, and other character attributes.

Source: https://godotengine.org/showcase/brotato/

### 3.2 Dome Keeper

Bippinbits' `Dome Keeper` is also featured by Godot. Its public showcase specifically describes upgrades that increase the jetpack's maximum speed, alongside other upgrade paths.

Potential lessons for Street Hustler:
- Movement upgrades should produce a noticeable gameplay difference.
- Movement can have multiple upgrade dimensions; speed need not be the only mobility property.
- The player should understand what an upgrade changes and feel that change during play.

Source: https://godotengine.org/showcase/dome-keeper/

### 3.3 What to borrow—not what to copy

For Street Hustler, the most transferable ideas are:
1. One authoritative set of movement-related stats.
2. Clear and perceptible movement upgrades.
3. Consistent movement behavior across game modes.
4. A movement model that supports future abilities without hard-coded special cases.
5. Player feedback that communicates acceleration, speed, dodge, and damage states.

Neither comparison justifies adding complexity for its own sake. The controller should remain simple until the game needs additional movement states.

## 4. Godot technical guidance

Godot's official documentation advises against directly setting the position of a `CharacterBody2D` to move it. It recommends `move_and_collide()` or `move_and_slide()`, with movement handled during `_physics_process()`. The documentation specifically identifies these APIs as suitable for top-down games.

For a top-down character, `CharacterBody2D.MOTION_MODE_FLOATING` is the relevant mode: Godot treats all collisions as walls, rather than applying floor/ceiling semantics intended for platformers.

Recommended references:
- CharacterBody2D movement and collision: https://docs.godotengine.org/en/stable/tutorials/physics/using_character_body_2d.html
- CharacterBody2D API and `MOTION_MODE_FLOATING`: https://docs.godotengine.org/en/stable/classes/class_characterbody2d.html
- 2D movement patterns and `Input.get_vector()`: https://docs.godotengine.org/en/stable/tutorials/2d/2d_movement.html

Recommended technical changes:
- Use a `CharacterBody2D` for the player in both neighborhood and combat scenes.
- Move the player through a shared controller or reusable movement component.
- Use `MOTION_MODE_FLOATING` for top-down collision behavior.
- Keep velocity in pixels per second; let `move_and_slide()` apply the physics timestep.
- Implement acceleration/deceleration with `velocity.move_toward()` or an equivalent controlled interpolation, then tune the response through playtesting.
- Treat dodge as a timed movement state with its own speed, duration, and invulnerability rules; do not simply teleport the character.
- Add facing direction and movement-state signals/properties so animation and sound can respond without duplicating input logic.
- Add gamepad actions to the Input Map and continue using `Input.get_vector()` so keyboard and analog input share one path.

## 5. Combat-type audit: fist fights versus gun fights

### 5.1 What the code currently implements

The current combat arena implements **melee/fist combat only**:

- Space triggers a three-hit combo.
- Q triggers a heavy melee strike.
- Both attacks require the enemy to be within `PLAYER_ATTACK_RANGE`.
- Attacks consume stamina.
- The enemy closes distance, enters attack range, telegraphs a strike, and resolves a close-range hit.
- Shift triggers a dodge with a short invulnerability window.
- Power increases the damage used by the melee combo and heavy attack.

The enemy configurations `corner_brawler`, `shop_guard`, and `alley_ambush` change enemy health, speed, attack range, damage, windup, color, and reward. They do not select a weapon type or combat style.

### 5.2 What is not implemented

The inspected code does not currently contain:
- Firearm definitions or a weapon/equipment model.
- A gun inventory or equipped-weapon slot.
- Aiming direction or target acquisition for ranged weapons.
- Shooting input or firing cadence.
- Ammunition, magazines, reloads, or reserve ammo.
- Projectile spawning, hitscan/raycast shooting, bullet collision, or muzzle effects.
- Firearm-specific damage, recoil, spread, range, penetration, or sound.
- A combat encounter type that identifies an encounter as a gun fight.
- Separate melee and ranged enemy behavior.

Therefore, the distinction between fist fights and gun fights is **not currently clear or implemented in the code**. The present system should be described as a melee combat prototype, not a general combat system that already supports both.

### 5.3 Recommended explicit distinction

Introduce an explicit combat-style identifier, for example:

```gdscript
enum CombatStyle {
    MELEE,
    FIREARMS
}
```

Each encounter should declare its combat style in encounter data rather than infer it from a scene name or enemy label.

Keep shared encounter responsibilities separate from style-specific mechanics:

**Shared combat layer**
- Player health and defeat/victory resolution.
- Encounter start/end and rewards.
- Enemy health and status.
- Arena bounds, cover, and scene lifecycle.
- Save and progression integration.

**Melee combat layer**
- Combo chains and heavy strikes.
- Attack range and hitboxes.
- Stamina costs and recovery windows.
- Blocking, parrying, dodging, and melee enemy telegraphs.

**Firearms combat layer**
- Equipped firearm and weapon stats.
- Aim direction and firing input.
- Ammo, reload, fire rate, recoil, and spread.
- Projectile or hitscan resolution.
- Range, cover, line-of-sight, and weapon-specific feedback.

Do not make firearm attacks call the existing fist-combo functions. They should share the encounter framework but use distinct attack systems and weapon data.

### 5.4 Suggested data model

A future encounter resource could include:
- `encounter_id`
- `combat_style` (`MELEE` or `FIREARMS`)
- `enemy_archetypes`
- `arena_scene`
- `difficulty`
- `rewards`
- `allowed_player_equipment`

A firearm resource could include:
- `weapon_id`
- `display_name`
- `damage`
- `fire_rate`
- `magazine_capacity`
- `reload_duration`
- `effective_range`
- `spread`
- `recoil`
- `ammo_type`

A melee weapon or unarmed combat resource should have its own appropriate fields, such as damage, reach, stamina cost, attack cadence, combo behavior, and recovery. Avoid forcing both categories into one data structure full of irrelevant fields.

## 6. Recommended implementation order

### Phase 1 — Movement foundation
1. Convert the combat player from `Polygon2D` to `CharacterBody2D`.
2. Reuse the same player movement controller in neighborhood and combat.
3. Set top-down floating collision mode.
4. Integrate dodge as a movement state.
5. Add automated tests for speed, diagonal normalization, collision, and dodge boundaries.

### Phase 2 — Movement feel
1. Add acceleration and deceleration.
2. Add facing direction and movement states.
3. Add walking/idle animations and footstep feedback.
4. Add keyboard and gamepad input support.
5. Playtest Footwork rank differences and tune them based on measured feel.

### Phase 3 — Combat architecture
1. Label the existing combat as melee.
2. Add an explicit encounter combat-style field.
3. Separate shared encounter lifecycle from melee attack logic.
4. Design firearm resources and a distinct ranged-combat controller.
5. Add gun fights only after aiming, ammunition, hit detection, cover, enemy response, and balance can be tested independently.

## 7. Acceptance criteria

The movement work should not be considered complete until:
- The same movement speed and acceleration rules apply in neighborhood and combat.
- Footwork ranks change movement speed in both environments.
- The player collides correctly with walls and arena obstacles.
- Dodge does not bypass intended collision constraints.
- Keyboard and gamepad input produce consistent directional movement.
- Automated tests cover movement calculations and key state transitions.

The combat-type distinction should not be considered complete until:
- Every encounter declares whether it is melee or firearms.
- Melee attacks cannot accidentally invoke firearm logic, and firearm attacks cannot invoke fist-combo logic.
- Firearms have functioning aim, firing, ammunition, reload, and hit resolution.
- Encounter UI and controls clearly communicate which combat style is active.
- Both combat styles have separate balance and regression tests.

## 8. Final conclusion

The Footwork integration is a useful first correction, but Street Hustler needs one consistent movement system across exploration and combat. The highest-value next engineering step is to unify the player body and movement behavior before adding more movement features.

Separately, the code currently supports fist fights, not gun fights. That distinction is not represented as a formal gameplay concept yet. The right solution is to build a shared encounter framework with distinct melee and firearms systems, rather than stretching the current fist-combat script to handle guns.

This document records findings and recommendations only. It does not claim that the proposed movement refactor or firearm system has been implemented or runtime-tested.
