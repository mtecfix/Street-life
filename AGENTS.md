# AI Agent Instructions — Street Hustler

## Mission
Build an original, browser-playable 2D action-adventure game with hybrid top-down exploration and dedicated combat arena scenes.

## Locked decisions
- Engine: Godot 4.x, GDScript.
- Perspective: top-down exploration; separate combat arena scenes.
- Visuals: enhanced 16-bit pixel art, original assets.
- Target: desktop web browsers first.
- Input: keyboard first.
- Persistence: local browser save first; cloud sync is a future adapter.

## Roles
- **Game Director:** protect the game vision, scope and design consistency.
- **Game Architect:** maintain scene boundaries, interfaces and technical standards.
- **Gameplay Developer:** implement player, combat and interaction mechanics.
- **World Designer:** create original maps, NPCs, missions and events.
- **Pixel Artist:** produce original art, animation and effects.
- **QA Engineer:** validate gameplay, regression and browser exports.

## Engineering rules
1. Prefer small, cohesive scenes and scripts over monolithic managers.
2. Keep reusable game rules separate from scene presentation where practical.
3. Use typed GDScript, explicit signal contracts and descriptive names.
4. Avoid hard-coded scene paths when an exported NodePath or signal is more robust.
5. Global state belongs in autoloads only when it must persist across scene changes.
6. Do not add third-party dependencies without documenting the reason and license.
7. Test both the editor/runtime path and the web export path.
8. Keep keyboard bindings centralized in `project.godot`.
9. Treat save data as versioned data; handle missing or old fields safely.
10. Do not claim a build or test passed unless it was actually run.

## Content and IP rules
- Create original characters, dialogue, names, maps, artwork, music and code.
- Do not copy protected assets, maps, dialogue, music or source code from other games.
- Review provenance and licensing before importing assets or code from prior projects.
- Keep asset credits and licenses in `game/assets/ASSET_CREDITS.md`.

## Feature workflow
For each feature:
1. Write a concise specification and acceptance criteria.
2. Identify affected scenes, scripts and systems.
3. Implement the smallest complete vertical slice.
4. Add or update tests.
5. Verify desktop runtime and web export where relevant.
6. Update documentation and note limitations.

## Naming
- Files and folders: `snake_case`.
- GDScript classes: `PascalCase`.
- Variables and functions: `snake_case`.
- Signals: past-tense or event-oriented names, e.g. `health_changed`, `encounter_started`.
- Scene files: descriptive `PascalCase.tscn`.

## Definition of done
A feature is not complete until it is implemented, integrated, tested against its acceptance criteria, documented, and free of known regressions.
