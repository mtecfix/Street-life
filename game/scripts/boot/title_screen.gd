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
# full-screen behind the menu. A translucent overlay is layered on top so the
# foreground menu remains the clearest visual and interactive focal point.
# The menu itself is made from native Godot Controls. Keeping the buttons as
# real Controls preserves keyboard/controller focus, accessibility, and
# reliable input.
#
# IMPORTANT: This screen does not implement save serialization or world
# initialization itself. It delegates those responsibilities to SaveManager
# and SceneManager, respectively.

# The first playable world scene entered by both menu actions.
const WORLD_SCENE := "res://scenes/world/Neighborhood.tscn"

# Original title-screen artwork. Kept as a constant path so the single
# background asset is easy to locate and swap without touching layout logic.
const BACKGROUND_IMAGE := "res://assets/sprites/title_screen_bg.png"

# Retain the Continue button so its initial state can be set from save-file
# availability when the menu is assembled.
var _continue_button: Button

# Called by Godot when the title-screen Control enters the scene tree.
# Build the background first so the menu layers on top of it, then build
# the interactive menu itself.
func _ready() -> void:
    _build_background()
    _build_menu()

# Construct the full-screen artwork backdrop behind the menu.
# A TextureRect keeps the image as a real, inspectable scene node rather than
# a hand-drawn canvas, and STRETCH_KEEP_ASPECT_COVERED fills the viewport at
# any window size without distorting the artwork's original proportions.
func _build_background() -> void:
    var background := TextureRect.new()
    background.texture = load(BACKGROUND_IMAGE)
    background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    background.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
    background.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
    add_child(background)

    # Dark translucent overlay reduces background contrast so the foreground
    # menu remains legible and the clearest visual and interactive focal point.
    var overlay := ColorRect.new()
    overlay.color = Color(0.01, 0.025, 0.035, 0.45)
    overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    add_child(overlay)

# Construct the complete menu hierarchy in code.
# The hierarchy is CenterContainer > PanelContainer > VBoxContainer. This keeps
# the panel centered and the labels/buttons vertically aligned without needing
# a separate static node for every element in the .tscn scene.
func _build_menu() -> void:
    # Fill the viewport and center the menu panel within it.
    var center := CenterContainer.new()
    center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    add_child(center)

    # The panel provides a distinct readable surface for menu content.
    var panel := PanelContainer.new()
    panel.custom_minimum_size = Vector2(430, 0)
    center.add_child(panel)

    # Define the panel's dark fill, green border, square corners, and internal
    # padding. These values are presentation-only; they do not affect gameplay.
    var panel_style := StyleBoxFlat.new()
    panel_style.bg_color = Color("#0b1216")
    panel_style.border_color = Color("#39e66b")
    panel_style.set_border_width_all(2)
    panel_style.set_corner_radius_all(2)
    panel_style.content_margin_left = 38
    panel_style.content_margin_right = 38
    panel_style.content_margin_top = 30
    panel_style.content_margin_bottom = 28
    panel.add_theme_stylebox_override("panel", panel_style)

    # A vertical stack provides consistent spacing and predictable layout as
    # labels or menu actions are added in future iterations.
    var stack := VBoxContainer.new()
    stack.add_theme_constant_override("separation", 12)
    panel.add_child(stack)

    # Small eyebrow copy establishes the narrative framing above the title.
    var eyebrow := Label.new()
    eyebrow.text = "A NEIGHBORHOOD STORY"
    eyebrow.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    eyebrow.add_theme_color_override("font_color", Color("#8da49a"))
    eyebrow.add_theme_font_size_override("font_size", 12)
    stack.add_child(eyebrow)

    # Primary game identity. Keep this as live text rather than baking it into
    # the background so it remains crisp and easy to localize or restyle.
    var title := Label.new()
    title.text = "STREET HUSTLER"
    title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    title.add_theme_color_override("font_color", Color("#55f17d"))
    title.add_theme_font_size_override("font_size", 38)
    stack.add_child(title)

    # Short tagline reinforces the player's role and the neighborhood theme.
    var subtitle := Label.new()
    subtitle.text = "THE BLOCK IS YOURS TO BUILD."
    subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    subtitle.add_theme_color_override("font_color", Color("#d2b879"))
    subtitle.add_theme_font_size_override("font_size", 12)
    stack.add_child(subtitle)

    # Add breathing room between the title copy and the primary actions.
    var spacer := Control.new()
    spacer.custom_minimum_size.y = 12
    stack.add_child(spacer)

    # NEW GAME always begins a new world session by entering the neighborhood.
    # Any new-game reset/initialization policy belongs to the world/save systems,
    # not to this presentation script.
    var start_button := _make_button("NEW GAME")
    start_button.pressed.connect(_start_new_game)
    stack.add_child(start_button)

    # CONTINUE is available only when a local save file exists. This is a
    # lightweight availability check, not validation of the save's contents;
    # SaveManager remains responsible for parsing and applying saved data.
    _continue_button = _make_button("CONTINUE")
    _continue_button.disabled = not FileAccess.file_exists("user://savegame.json")
    _continue_button.pressed.connect(_continue_game)
    stack.add_child(_continue_button)

    # Display the basic keyboard controls as a reminder for first-time players.
    var footer := Label.new()
    footer.text = "WASD / ARROWS  MOVE     •     E  INTERACT"
    footer.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    footer.add_theme_color_override("font_color", Color("#74847e"))
    footer.add_theme_font_size_override("font_size", 10)
    stack.add_child(footer)

# Create a consistently styled menu button and return it to the caller.
# The caller owns placement and signal wiring so this helper can be reused
# for additional menu actions without coupling it to a particular behavior.
func _make_button(label_text: String) -> Button:
    var button := Button.new()
    button.text = label_text
    button.custom_minimum_size = Vector2(0, 48)
    button.add_theme_font_size_override("font_size", 16)
    button.add_theme_color_override("font_color", Color("#55f17d"))
    button.add_theme_color_override("font_hover_color", Color("#08110b"))

    # Normal state: dark button face with a subtle green border.
    var normal := StyleBoxFlat.new()
    normal.bg_color = Color("#101d19")
    normal.border_color = Color("#315d40")
    normal.set_border_width_all(1)

    # Hover/pressed state: brighter fill provides immediate pointer/focus
    # feedback. Godot's Button continues to handle input and focus behavior.
    var hover := StyleBoxFlat.new()
    hover.bg_color = Color("#55f17d")
    hover.border_color = Color("#55f17d")
    hover.set_border_width_all(1)

    button.add_theme_stylebox_override("normal", normal)
    button.add_theme_stylebox_override("hover", hover)
    button.add_theme_stylebox_override("pressed", hover)
    return button

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
