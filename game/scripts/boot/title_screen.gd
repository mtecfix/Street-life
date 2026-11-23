extends Control

const WORLD_SCENE := "res://scenes/world/Neighborhood.tscn"

var _continue_button: Button

func _ready() -> void:
    _build_menu()
    queue_redraw()

func _draw() -> void:
    var size := get_viewport_rect().size
    draw_rect(Rect2(Vector2.ZERO, size), Color("#080d12"))
    # Original pixel-art skyline: Bronx-inspired silhouettes, not copied artwork.
    draw_rect(Rect2(0, size.y * 0.60, size.x, size.y * 0.40), Color("#111b20"))
    for i in range(12):
        var building_width := 42.0 + float((i * 17) % 35)
        var building_height := 95.0 + float((i * 31) % 125)
        var x := float(i) * size.x / 11.0 - 20.0
        var y := size.y * 0.60 - building_height
        draw_rect(Rect2(x, y, building_width, building_height), Color("#14232a"))
        for row in range(3):
            for col in range(2):
                var wx := x + 10.0 + float(col) * 18.0
                var wy := y + 14.0 + float(row) * 24.0
                draw_rect(Rect2(wx, wy, 6, 9), Color("#b58b45", 0.55))
    draw_rect(Rect2(0, size.y * 0.60, size.x, 3), Color("#39e66b", 0.8))
    draw_rect(Rect2(0, size.y * 0.60 + 5, size.x, 1), Color("#39e66b", 0.22))
    # Soft vignette bands keep the menu legible over the skyline.
    draw_rect(Rect2(0, 0, size.x, size.y), Color(0.01, 0.025, 0.035, 0.35))

func _build_menu() -> void:
    var center := CenterContainer.new()
    center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    add_child(center)

    var panel := PanelContainer.new()
    panel.custom_minimum_size = Vector2(430, 0)
    center.add_child(panel)
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

    var stack := VBoxContainer.new()
    stack.add_theme_constant_override("separation", 12)
    panel.add_child(stack)

    var eyebrow := Label.new()
    eyebrow.text = "A NEIGHBORHOOD STORY"
    eyebrow.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    eyebrow.add_theme_color_override("font_color", Color("#8da49a"))
    eyebrow.add_theme_font_size_override("font_size", 12)
    stack.add_child(eyebrow)

    var title := Label.new()
    title.text = "STREET HUSTLER"
    title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    title.add_theme_color_override("font_color", Color("#55f17d"))
    title.add_theme_font_size_override("font_size", 38)
    stack.add_child(title)

    var subtitle := Label.new()
    subtitle.text = "THE BLOCK IS YOURS TO BUILD."
    subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    subtitle.add_theme_color_override("font_color", Color("#d2b879"))
    subtitle.add_theme_font_size_override("font_size", 12)
    stack.add_child(subtitle)

    var spacer := Control.new()
    spacer.custom_minimum_size.y = 12
    stack.add_child(spacer)

    var start_button := _make_button("NEW GAME")
    start_button.pressed.connect(_start_new_game)
    stack.add_child(start_button)

    _continue_button = _make_button("CONTINUE")
    _continue_button.disabled = not FileAccess.file_exists("user://savegame.json")
    _continue_button.pressed.connect(_continue_game)
    stack.add_child(_continue_button)

    var footer := Label.new()
    footer.text = "WASD / ARROWS  MOVE     •     E  INTERACT"
    footer.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    footer.add_theme_color_override("font_color", Color("#74847e"))
    footer.add_theme_font_size_override("font_size", 10)
    stack.add_child(footer)

func _make_button(label_text: String) -> Button:
    var button := Button.new()
    button.text = label_text
    button.custom_minimum_size = Vector2(0, 48)
    button.add_theme_font_size_override("font_size", 16)
    button.add_theme_color_override("font_color", Color("#55f17d"))
    button.add_theme_color_override("font_hover_color", Color("#08110b"))
    var normal := StyleBoxFlat.new()
    normal.bg_color = Color("#101d19")
    normal.border_color = Color("#315d40")
    normal.set_border_width_all(1)
    var hover := StyleBoxFlat.new()
    hover.bg_color = Color("#55f17d")
    hover.border_color = Color("#55f17d")
    hover.set_border_width_all(1)
    button.add_theme_stylebox_override("normal", normal)
    button.add_theme_stylebox_override("hover", hover)
    button.add_theme_stylebox_override("pressed", hover)
    return button

func _start_new_game() -> void:
    SceneManager.change_to(WORLD_SCENE)

func _continue_game() -> void:
    SaveManager.load_game()
    SceneManager.change_to(WORLD_SCENE)
