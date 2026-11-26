# Street Hustler

An original 2D urban action-adventure game built with Godot 4.x and targeted at desktop browsers.

## Locked project direction

- **Perspective:** hybrid — top-down neighborhood exploration with dedicated combat arena scenes.
- **Visual direction:** enhanced 16-bit pixel art, with modern lighting and effects.
- **Deployment:** web (HTML5/WebAssembly).
- **Engine:** Godot 4.x / GDScript.
- **Controls:** keyboard first.
- **Saves:** local browser persistence first; cloud synchronization through a future adapter.

## Current prototype

The first implementation sprint provides:
- A Godot project with a main scene and explorable test block.
- Keyboard movement and collision.
- Separate combat arenas with fist-fighting and firearm systems, persistent weapon ownership, and distinct pressure-fighter, counter-guard, and skirmisher enemy behaviors.
- Scene transitions through an autoloaded scene manager.
- Local save/load scaffolding.
- Global game state, world clock, and event bus.
- A web export preset and CI workflow starter.

The prototype uses simple geometric placeholder art. Replace it with original licensed pixel art as the art pipeline is established.

## Run locally

1. Install Godot 4.x (use the latest stable 4.x release compatible with the project).
2. Open `game/project.godot` in Godot.
3. Run the project (F6/F5).

## Web export

Open **Project → Export**, install the matching export templates, and export the `Web` preset to `game/build/web/index.html`. The `.github/workflows/web-build.yml` workflow is a starter and may require adjustment to the exact Godot version and export-template setup used by the runner.

For browser deployment, serve the exported directory over HTTP(S); do not open `index.html` directly from the filesystem.

## Controls

- WASD / Arrow keys: move
- E: interact with the marked encounter/exit
- TAB: switch fist fighting / firearms in combat
- SPACE: melee combo; Q: heavy strike; C: guard; SHIFT: dodge
- Z: aim; F: fire; R: reload (firearms) / body shot (melee); G: cycle firearm
- Maya's Market: press 4 for the Compact SMG ($180) or 5 for the Street Carbine ($320); ownership and ammunition persist
- K: open Combat Training in the neighborhood
- Escape: return from arena to neighborhood

## Repository layout

- `game/`: Godot scenes, scripts, resources and export configuration.
- `systems/`: engine-independent gameplay system specifications and future modules.
- `docs/`: design, architecture, deployment and roadmap.
- `tests/`: automated test plan and future tests.
- `tools/`: asset pipeline and development utilities.

## IP and asset policy

Street Hustler uses original characters, dialogue, maps, art, music, names and code. Genre-level inspiration is acceptable; copyrighted game assets, maps, music, dialogue or source code from other titles must not be copied. Any reused material from prior projects must be reviewed for provenance and license compatibility before importing.
