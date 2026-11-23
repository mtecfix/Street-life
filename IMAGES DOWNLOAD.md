# Title Screen Image — Download Required

## Source image

Download the original Street Hustler title-screen artwork from Google Drive:

[Download the title-screen image](https://drive.google.com/file/d/1OVyBRgO7GatSh0aGy1CSa3sz9vU3eNCV/view)

## Why this image needs to be downloaded

This artwork is intended to be the full-screen background shown when Street Hustler first launches. It establishes the game's visual identity before the player enters the Bronx neighborhood.

The image must be downloaded and added to the game project because the running game needs a local, version-controlled asset. A Google Drive sharing URL is a source location for people to retrieve the image; it is not itself an image file that Godot can reliably load as a project resource.

Keeping the original image in the repository will:

- Make the title-screen artwork available to Godot during development and export.
- Ensure the image is included with the game build instead of depending on a live Google Drive connection.
- Preserve a consistent title screen for everyone working on the project.
- Allow the artwork to be versioned alongside the title-screen scene and its menu controls.

## Intended use

Use the downloaded image as the title-screen background. Keep **NEW GAME** and **CONTINUE** as functional Godot UI controls layered over the artwork; do not bake the button behavior into the background image.

The title screen should appear at game launch. Selecting **NEW GAME** should transition into the playable Bronx neighborhood. **CONTINUE** should remain connected to the game's save/load flow.

## Download and integration notes

1. Open the Google Drive link above and download the original image file.
2. Preserve the original image quality and file format; avoid screenshots or recompressed copies.
3. Add the downloaded image to the game's assets directory.
4. Update the title-screen scene/script to load the local asset as its background.
5. Verify the title screen in the Godot project and in the browser export.

This document explains the source and required use of the artwork. It does not mean the image has already been downloaded or integrated into the game.
