# Street Hustler — Code and Gameplay Audit

**Repository:** `mtecfix/Street-life`  
**Project:** Godot 4.3 — Street Hustler  
**Audit date:** November 26, 2026  
**Audit type:** Source-code, design-document, roadmap, and automated-test review

> **Scope and limitation:** This document records a static review of the repository. It is not a live playthrough or a fresh Godot editor/runtime test. Findings describe the code inspected at the time of the audit; confirm behavior in the Godot editor and target browser before release.

## 1. Executive assessment

Street Hustler has a meaningful playable foundation, but it remains an engineering prototype rather than a complete, content-rich game. Core systems exist—movement, interaction, a small neighborhood, combat, inventory, local persistence, progression, schedules, events, courier side hustles, and faction standing—but several systems are shallow, tightly coupled, or not yet validated end to end.

The main development need is not to replace the existing project. It is to strengthen its architecture, connect existing mechanics consistently, and expand the simulation and content built on top of them.

### Current system assessment

| System | Assessment | Notes |
|---|---|---|
| Player movement | Implemented; integration issue | Exploration controller uses a fixed speed instead of the progression-derived speed |
| NPC interaction | Basic | Five named NPCs with scripted interaction branches |
| NPC schedules | Basic | Availability windows; NPC positions are effectively static |
| Combat | Basic | Combos, heavy strike, dodge, telegraphs, stamina, and three encounter configurations |
| Inventory | Basic | Three consumables and a 20-item stack-count capacity |
| Economy | Incomplete | Cash, shop purchases, and activity rewards; no broader economic simulation |
| Missions | Incomplete | One primary mission with two approaches and a follow-up encounter; no reusable quest framework |
| Progression | Basic | XP, levels, skill points, and three skills capped at rank three |
| Factions | Basic | Local/rival reputation scores and standing tiers |
| World events | Basic | Three scheduled repeatable events |
| Side hustles | Basic | Two courier routes with one completion per day |
| Local saving | Implemented | Versioned JSON save system and migration support are present |
| Cloud saving | Not implemented | Cloud provider is a stub |
| World and interiors | Prototype | One block, two functional interiors, and largely procedural/hard-coded geometry |
| Art and animation | Incomplete | Placeholder geometry and limited sprite presentation |
| Automated validation | Partial | Headless tests and web-export workflow exist; interactive runtime validation remains outstanding |

These labels are qualitative engineering judgments, not a measured completion percentage.

## 2. Highest-priority findings

### 2.1 Player progression does not consistently affect exploration movement

**Priority: Critical**

`game/scripts/autoload/game_state.gd` defines `get_player_speed()`, which increases movement speed based on Footwork skill level. Combat uses progression-derived movement speed, but `game/scripts/player/player_controller.gd` assigns velocity using its fixed exported `move_speed` value.

As a result, Footwork upgrades do not affect normal neighborhood movement.

**Recommended fix**
- Use `GameState.get_player_speed()` in the exploration player controller.
- Decide whether the exported base speed remains configurable; if so, centralize the base value so progression and inspector configuration cannot diverge.
- Add a test verifying that each Footwork rank changes exploration movement speed as intended.

### 2.2 NPCs have schedules but not autonomous routines

**Priority: High**

The neighborhood defines five NPCs: Rico, Maya, Dre, Nia, and Coach. Their schedule windows toggle whether they are active/available. Their positions are fixed in the neighborhood data; the inspected implementation does not provide a full autonomous daily routine or navigation simulation.

**Missing or underdeveloped**
- Navigation and movement between locations.
- Multi-step daily routines.
- NPC-to-NPC interactions.
- Character-specific goals and needs.
- Memory of player choices and past interactions.
- Reactions to neighborhood conditions and faction standing.
- Ambient behaviors and unscripted encounters.

**Recommended fix**
Build a data-driven NPC system with character definitions, schedule activities, behavior states, NavigationAgent2D movement, relationship state, and bounded interaction memory. Keep dialogue and routine data outside the main neighborhood script.

### 2.3 Mission logic is hard-coded rather than reusable

**Priority: High**

The current primary mission is initiated through Rico and offers two approaches: stand your ground or protect the shop. These approaches route to different combat encounters and outcomes. A subsequent alley encounter is unlocked after the mission.

This is a useful vertical-slice mission, but the inspected code does not establish a reusable quest framework.

**Missing or underdeveloped**
- Multiple simultaneous missions.
- Main-story chapters and side quests.
- Mission prerequisites and chains.
- Multi-stage objectives and objective tracking.
- Timed objectives and failure conditions.
- Reusable branching choices and consequence rules.
- Mission definitions stored as resources/data rather than embedded in scene scripts.
- A mission journal and clear objective presentation.

**Recommended fix**
Introduce a MissionManager with data-driven mission definitions, objective state, prerequisites, branching outcomes, rewards, and persistence. Keep mission content separate from mission execution logic.

### 2.4 Economy is limited to basic transactions and rewards

**Priority: High**

The current item catalog contains three consumables:

| Item | Price | Effect |
|---|---:|---:|
| Snack | $5 | Restores 15 health |
| First-aid kit | $18 | Restores 45 health |
| Soda | $8 | Restores 5 health |

The game also has cash rewards for combat, daily events, and courier deliveries. This is a functional starting economy, not a broader street/business simulation.

**Missing or underdeveloped**
- Multiple shops and business types.
- Employment and varied income activities.
- Business ownership and upgrades.
- Supply, demand, and price variation.
- Recurring costs such as rent and upkeep.
- Equipment, property, storage, and larger purchases.
- Market events and economic consequences.
- Multiple money sinks and meaningful financial tradeoffs.

**Recommended fix**
Create an EconomyManager responsible for transactions, pricing, business state, recurring costs, and economic events. Keep player cash as state, but avoid placing all economic rules in GameState.

### 2.5 Combat is a one-opponent prototype

**Priority: High**

The combat implementation includes:
- Three-hit light-attack combo.
- Stamina-intensive heavy attack.
- Dodge and temporary invulnerability.
- Enemy attack telegraphs and recovery windows.
- Skill-based damage scaling.
- Three encounter configurations: corner challenger, shopfront agitator, and alley runner.

However, the inspected encounter controller creates one enemy that pursues and attacks the player. The alley encounter dialogue describes two attackers, but the current implementation configures one enemy.

**Missing or underdeveloped**
- Multiple simultaneous opponents.
- Distinct enemy archetypes and AI states.
- Blocking and parrying.
- Weapons and weapon-specific move sets.
- Hit reactions, knockback, and animation-driven timing.
- Environmental combat interactions.
- Boss encounters and difficulty progression.
- More meaningful encounter rewards and loot.

**Recommended fix**
Refactor combat around encounter definitions and an enemy roster. Add enemy archetypes and group encounters before increasing the number of combat scenes. Align encounter dialogue and presentation with the actual enemy count.

### 2.6 World and interiors are still a small prototype

**Priority: High**

The design document describes an initial vertical slice with one fictional block and three planned enterable locations. The inspected repository has two functional interior scenes: Maya's Market and the apartment.

The neighborhood is substantially drawn procedurally in `neighborhood.gd`, with collision geometry created in code. This is workable for a prototype but will become difficult to author and maintain as the world expands.

**Missing or underdeveloped**
- Third and additional enterable locations.
- More districts and neighborhood layouts.
- Reusable building and interior templates.
- Interactive environmental objects and furniture.
- Location-specific activities and services.
- Scalable map authoring and world navigation.

**Recommended fix**
Move authored level layout toward TileMap/TileMapLayer or LDtk integration, while retaining procedural systems where they add value. Build reusable location scenes and an explicit location/transition registry.

## 3. Additional gameplay gaps

### 3.1 Progression

Current progression includes XP, levels, one skill point per level gained, and three skills—Power, Endurance, and Footwork—each capped at rank three.

Potential expansions:
- Broader character attributes.
- Perks and branching skill trees.
- Equipment-based bonuses.
- Unlockable abilities and activities.
- Reputation-gated opportunities.
- Non-combat progression paths.

### 3.2 Daily activities and side hustles

There are three scheduled neighborhood events and two courier routes. Activities generally resolve by reaching a marked position and interacting.

Potential expansions:
- Multi-stop deliveries and deadlines.
- Route selection and navigation challenges.
- Interactive community events and competitions.
- Multi-stage neighborhood activities.
- Risk/reward decisions and changing event conditions.
- A daily activity planner that makes time allocation meaningful.

### 3.3 Interiors and interaction

The shop provides simple item purchases. The apartment allows the player to rest and restore health. Environmental interactions are limited.

Potential expansions:
- Interactive objects and furniture.
- More shop services.
- Location-specific activities.
- Storage and equipment management.
- Persistent changes to owned or visited locations.

### 3.4 Persistence and online services

The local JSON save system has versioning and migration support. The cloud save provider is currently a stub: its upload operation returns `ERR_UNAVAILABLE`, and its download operation returns an empty dictionary.

Not implemented:
- Cloud synchronization.
- User authentication.
- Conflict resolution.
- Multiple cloud save slots.
- Cross-device progression.

Cloud saving should be deferred until the single-player save lifecycle and schema are stable. Multiplayer is not implemented and should remain out of scope until the single-player simulation is mature.

## 4. Specific implementation issues observed

| Priority | Finding | Recommended action |
|---|---|---|
| Critical | Footwork progression does not affect normal exploration movement | Connect player controller to GameState progression speed and test it |
| High | NPC schedules toggle availability but do not implement autonomous routines | Add navigation and behavior states |
| High | Mission flow is embedded in neighborhood interaction code | Build a reusable MissionManager |
| High | Economy rules are concentrated in GameState and activity scripts | Introduce EconomyManager and transaction boundaries |
| High | Alley dialogue describes two attackers, while combat creates one enemy | Implement group encounters or correct the dialogue |
| Medium | Apartment records `rested_today` but does not check it before allowing another rest | Define and enforce rest eligibility, if repeated resting is not intentional |
| Medium | Neighborhood geometry and collision are largely hard-coded | Adopt reusable authored map/location resources |
| Medium | Combat characters and effects rely on placeholder visuals | Move toward animated character scenes and readable combat feedback |

## 5. Testing and release-readiness gaps

The repository contains headless GDScript tests and a GitHub Actions workflow. The workflow imports the Godot project, runs tests for faction standing, combat scenes and rules, progression and save migration, world systems, debug bridge, HUD, title screen, and inventory signals, then exports the web build.

The roadmap still lists interactive validation as outstanding in several areas.

**Validation still needed**
- Godot editor import and interactive runtime checks.
- Browser gameplay validation on target browsers.
- Full mission branch and consequence verification.
- Real save migration fixtures for older schema versions.
- Save/reload testing for events and side hustles.
- Interactive combat timing, balance, and transition testing.
- Browser performance, input, audio, storage, and refresh behavior.
- Complete start-to-finish playthrough of the current vertical slice.

The combined status information available during the audit did not report any status checks for the inspected commit. This does not prove the workflow is failing; it means a passing build could not be certified from that status response.

## 6. Recommended development roadmap

### Sprint 11 — Architecture and integration cleanup
1. Fix Footwork movement integration.
2. Separate economy, mission, and NPC responsibilities from neighborhood presentation logic.
3. Introduce reusable interaction and location components.
4. Add regression tests for the identified issues.
5. Run a fresh Godot import and interactive smoke test.

### Sprint 12 — Living neighborhood
1. Add NPC navigation and autonomous routines.
2. Add data-driven character profiles and behavior states.
3. Expand relationship and memory behavior.
4. Add ambient neighborhood activity.
5. Validate schedules and navigation across a full in-game day.

### Sprint 13 — Reusable mission engine
1. Create MissionManager and mission data resources.
2. Add objective tracking and prerequisites.
3. Add multi-stage mission chains.
4. Add branching outcomes and persistent consequences.
5. Add a mission journal and objective UI.

### Sprint 14 — Economy and business simulation
1. Create EconomyManager.
2. Add multiple shops and business categories.
3. Add employment and varied income activities.
4. Add recurring expenses and meaningful purchases.
5. Add business ownership and upgrade progression.

### Sprint 15 — Combat and character progression
1. Add group encounters and enemy archetypes.
2. Add blocking/parrying and weapon support.
3. Improve hit reactions and combat feedback.
4. Expand skills, perks, and equipment.
5. Validate balance and difficulty progression.

### Sprint 16 — World expansion and presentation
1. Add more districts and enterable locations.
2. Adopt a scalable map-authoring pipeline.
3. Replace placeholder characters with animated assets.
4. Add sound, music, and environmental feedback.
5. Run full browser playtesting and performance checks.

## 7. Recommended architecture direction

Use focused managers and data resources rather than growing a few large scripts:

- **NPCManager:** character definitions, schedules, navigation, behavior, relationships.
- **MissionManager:** mission definitions, objectives, prerequisites, branches, rewards.
- **EconomyManager:** transactions, pricing, businesses, costs, market state.
- **CombatManager:** encounter definitions, enemy rosters, combat lifecycle.
- **WorldManager:** locations, district transitions, world events, time-based activity.
- **ProgressionManager:** XP, levels, skills, perks, unlocks.
- **GameState:** authoritative player/session state.
- **EventBus:** decoupled cross-system notifications.
- **SaveManager:** versioned persistence and future provider integration.

This separation should make it easier to add content and use AI-assisted development without repeatedly modifying the same large scripts.

## 8. Final recommendation

Do not rewrite the project. Preserve the current foundation and make the next development phase an architecture and gameplay-foundation sprint.

The best immediate sequence is:

1. Fix the Footwork movement inconsistency and rest eligibility behavior.
2. Refactor mission, economy, and NPC responsibilities into reusable systems.
3. Implement autonomous NPC movement and routines.
4. Build a data-driven mission framework.
5. Expand the economy and combat only after the foundations are testable.

The project already has enough core mechanics to support a stronger vertical slice. The next milestone should be a complete, validated gameplay loop—not simply a larger list of features.
