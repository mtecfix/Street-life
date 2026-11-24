extends Control

# -----------------------------------------------------------------------------
# TITLE SCREEN — DEVELOPER OVERVIEW
# -----------------------------------------------------------------------------
# This script builds the game's front-end title screen at runtime. It is kept
# separate from the world scene so that the player can choose whether to start
# a fresh session or resume a locally saved one before entering the neighborhood.
#
# The visual background is the original title-screen artwork documented in
# "IMAGES DOWNLOAD.md" (res://assets/sprites/title_screen_bg.png), displayed
# full-screen behind the menu. The artwork already contains the game's logo
# and two metal-plate button graphics reading "NEW GAME" and "CONTINUE".
# Rather than drawing a separate text panel on top of the art, this script
# places two transparent, real Godot Button controls directly over those
# plates, so the artwork itself is the visible button and Godot only needs
# to detect input in that exact region. Keeping them as real Controls
# preserves keyboard/controller focus, accessibility, and reliable input.
#
# IMPORTANT: This screen does not implement save serialization or world
# initialization itself. It delegates those responsibilities to SaveManager
# and SceneManager, respectively.

# The first playable world scene entered by both menu actions.
const WORLD_SCENE := "res://scenes/world/Neighborhood.tscn"

# Original title-screen artwork. Kept as a constant path so the single
# background asset is easy to locate and swap without touching layout logic.
const BACKGROUND_IMAGE := "res://assets/sprites/title_screen_bg.png"

# Pixel rectangles of the "NEW GAME" and "CONTINUE" metal-plate graphics,
# measured directly against the source artwork (1671x941). These are kept
# in the image's native pixel space; _position_hotspots() converts them into
# viewport-space rectangles that track the background's on-screen crop and
# scale at any window size.
const NEW_GAME_SOURCE_RECT := Rect2(495, 592, 615, 85)
const CONTINUE_SOURCE_RECT := Rect2(495, 665, 615, 85)

# Retain the background TextureRect and both buttons so their layout can be
# recalculated whenever the viewport is resized.
var _background: TextureRect
var _new_game_button: Button
var _continue_button: Button

# Called by Godot when the title-screen Control enters the scene tree.
# Build the background first, then the two artwork-aligned button hotspots.
func _ready() -> void:
    _build_background()
    _build_hotspots()
    _position_hotspots()

# Recalculate hotspot placement whenever the window/viewport size changes so
# the invisible buttons keep tracking the artwork's button graphics.
func _notification(what: int) -> void:
    if what == NOTIFICATION_RESIZED and is_instance_valid(_background):
        _position_hotspots()

# Construct the full-screen artwork backdrop.
# A TextureRect keeps the image as a real, inspectable scene node rather than
# a hand-drawn canvas, and STRETCH_KEEP_ASPECT_COVERED fills the viewport at
# any window size without distorting the artwork's original proportions.
func _build_background() -> void:
    _background = TextureRect.new()
    _background.texture = load(BACKGROUND_IMAGE)
    _background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    _background.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
    _background.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
    add_child(_background)

# Create the two transparent button hotspots. Size/position is set later by
# _position_hotspots() once the background texture and viewport are known;
# this only creates the controls and wires their behavior/signals.
func _build_hotspots() -> void:
    _new_game_button = _make_hotspot_button()
    _new_game_button.pressed.connect(_start_new_game)
    add_child(_new_game_button)

    _continue_button = _make_hotspot_button()
    _continue_button.disabled = not FileAccess.file_exists("user://savegame.json")
    _continue_button.pressed.connect(_continue_game)
    add_child(_continue_button)

# Create a single invisible, borderless Button used as a clickable hotspot
# over an existing piece of artwork. No text or StyleBox is drawn; the art
# underneath is the only visible button graphic. A faint focus outline is
# kept so keyboard/controller navigation remains visible without altering
# the artwork itself.
func _make_hotspot_button() -> Button:
    var button := Button.new()
    button.flat = true
    button.focus_mode = Control.FOCUS_ALL

    var transparent := StyleBoxEmpty.new()
    button.add_theme_stylebox_override("normal", transparent)
    button.add_theme_stylebox_override("hover", transparent)
    button.add_theme_stylebox_override("pressed", transparent)
    button.add_theme_stylebox_override("disabled", transparent)

    var focus_outline := StyleBoxFlat.new()
    focus_outline.draw_center = false
    focus_outline.border_color = Color("#55f17d", 0.85)
    focus_outline.set_border_width_all(2)
    focus_outline.set_corner_radius_all(4)
    button.add_theme_stylebox_override("focus", focus_outline)

    return button

# Map both button hotspots onto the artwork's own "NEW GAME"/"CONTINUE"
# plates, in current viewport coordinates. This replicates the same
# scale-and-crop math STRETCH_KEEP_ASPECT_COVERED applies to the background,
# so the invisible hitboxes stay aligned with the visible art at any aspect
# ratio or window size.
func _position_hotspots() -> void:
    var texture: Texture2D = _background.texture
    if texture == null:
        return

    var viewport_size := get_viewport_rect().size
    var texture_size := texture.get_size()

    # STRETCH_KEEP_ASPECT_COVERED scales the texture so it fully covers the
    # viewport on whichever axis would otherwise leave a gap, then centers
    # and crops the overflow on the other axis.
    var scale := maxf(viewport_size.x / texture_size.x, viewport_size.y / texture_size.y)
    var displayed_size := texture_size * scale
    var offset := (viewport_size - displayed_size) * 0.5

    _new_game_button.position = offset + NEW_GAME_SOURCE_RECT.position * scale
    _new_game_button.size = NEW_GAME_SOURCE_RECT.size * scale

    _continue_button.position = offset + CONTINUE_SOURCE_RECT.position * scale
    _continue_button.size = CONTINUE_SOURCE_RECT.size * scale

# Start a fresh session by asking the central scene manager to load the world.
# SceneManager owns the transition mechanics; this keeps scene changes
# consistent with transitions initiated elsewhere in the game.
func _start_new_game() -> void:
    SceneManager.change_to(WORLD_SCENE)

# Resume the local session: first delegate save loading to SaveManager, then
# enter the world scene. The Continue button is disabled when no save file is
# present, but SaveManager remains the authority for save parsing/migration.
func _continue_game() -> void:
    SaveManager.load_game()
    SceneManager.change_to(WORLD_SCENE)
