# Art Direction

## Visual target
A cohesive geometric, block-built 2D art style. Construct characters, props, vehicles, buildings, interiors, and interface illustrations from deliberate combinations of rectangles, trapezoids, and custom polygons. The result should feel like finished stylized game art, not debug geometry.

Use silhouette, proportion, layered planes, and controlled color blocking to make each object immediately recognizable. Add detail through secondary shapes, edge highlights, shadow planes, and selective outlines rather than texture noise.

## Shape language
- **Rectangles and squares:** doors, windows, wall sections, counters, shelves, pavement slabs, signs, and other orthogonal structures.
- **Trapezoids and quadrilaterals:** roofs, awnings, angled facades, tabletops, vehicle bodies, ramps, and surfaces that need a clear sense of perspective.
- **Custom polygons:** irregular architecture, character silhouettes and clothing, foliage, debris, street fixtures, and any form that cannot be expressed cleanly with basic blocks.
- **Layered geometry:** combine a base silhouette with inset planes, highlights, shadows, trim, and small accents to establish volume and material.
- **Circles and ellipses:** reserve for forms that genuinely need them, such as wheels, heads, lamps, and rounded fixtures; they should complement the block language rather than dominate it.

## Construction rules
1. Start every asset with a strong, readable outer silhouette.
2. Build the main mass from a small number of large shapes before adding detail.
3. Use trapezoids and polygons intentionally to communicate angle, depth, and form; avoid arbitrary distortion.
4. Separate planes with value contrast. A typical object should have a base tone, a shadow tone, and a highlight tone, with extra colors used only where they add material or identity.
5. Keep outlines, edge thickness, and corner treatment consistent across assets of similar scale.
6. Use overlapping shapes and deliberate draw order to create depth. Do not rely on gradients or texture to do the work of form.
7. Keep small-scale details sparse enough to remain legible at the game's camera zoom.
8. Reuse the same visual construction language in exploration, interiors, combat environments, shops, and UI illustrations so an object remains recognizable across contexts.

## Runtime asset standard
Gameplay objects should be represented consistently across their data and presentation:
- A canonical gameplay definition supplies the object's identity and properties.
- An inventory icon uses the same silhouette and key colors as its world representation.
- A world sprite is built from layered block shapes or a matching authored image.
- Pickups have a visible world representation and a clear interaction/collision area.
- Shop stock uses the same recognizable object representation as the inventory and pickup.
- Environmental props retain consistent appearance and collision/interaction behavior across neighborhood and combat scenes.

When an object is currently represented only by text or debug geometry, treat that as an integration task—not as evidence that its visual implementation is complete.

## Technical guidance
- Establish a consistent logical resolution and pixel scale before producing final raster art.
- Use nearest-neighbor filtering for raster textures unless an effect explicitly requires otherwise.
- Keep authored sprites aligned to the chosen pixel grid where practical.
- Prefer native 2D polygon/primitive drawing for block-built objects when it improves reuse, scaling, or runtime variation.
- Keep geometry data, palette choices, and draw order organized so assets can be adjusted consistently.
- Use original artwork or assets with compatible documented licenses.
- Avoid mixing unrelated proportions, outline weights, or visual styles.

## Prototype and migration
Existing scenes contain a mixture of geometric placeholders, procedural shapes, and raster assets. Refine those representations into intentional block-built art incrementally; do not replace functioning gameplay systems or redesign whole scenes in one pass. New and revised assets must follow the shape language above.
