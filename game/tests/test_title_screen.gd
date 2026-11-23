extends SceneTree

# Headless test for the TitleScreen scene: confirms the scene resource parses,
# the background artwork loads as a real texture, and the two artwork-aligned
# button hotspots (NEW GAME, CONTINUE) exist, are positioned over their source
# plate rectangles, and respond to the viewport's current scale.
#
# This exists because TitleScreen.tscn is never exercised by the other test
# scripts (they only test autoload singletons), so a scene-level parse error
# or a missing/renamed asset would otherwise go undetected until manual or
# browser testing.
#
# Run: godot --headless --path game --script res://tests/test_title_screen.gd

var _failures: Array[String] = []

func _initialize() -> void:
    call_deferred("_run_tests")

func _run_tests() -> void:
    var scene_resource: Variant = load("res://scenes/boot/TitleScreen.tscn")
    if scene_resource == null:
        push_error("Failed to load TitleScreen.tscn.")
        quit(1)
        return

    var instance: Control = scene_resource.instantiate()
    root.add_child(instance)
    await process_frame
    await process_frame

    var background: Variant = _check_background(instance)
    _check_hotspot_buttons(instance, background)

    instance.queue_free()

    if _failures.is_empty():
        print("PASS: title screen scene parses, loads background art, and aligns button hotspots to it.")
        quit(0)
    else:
        for message in _failures:
            push_error(message)
        quit(1)

func _check(condition: bool, message: String) -> void:
    if not condition:
        _failures.append(message)

func _check_background(instance: Control) -> Variant:
    var background: Variant = instance.get_child(0)
    _check(background is TextureRect, "First child should be the background TextureRect.")
    if background is TextureRect:
        _check(background.texture != null, "Background TextureRect must have a loaded texture.")
        if background.texture != null:
            var size: Vector2 = background.texture.get_size()
            _check(size.x > 0 and size.y > 0, "Background texture should have non-zero dimensions.")
    return background

func _check_hotspot_buttons(instance: Control, background: Variant) -> void:
    var buttons: Array = instance.find_children("*", "Button", true, false)
    _check(buttons.size() == 2, "Title screen should have exactly two button hotspots, found %d." % buttons.size())
    if buttons.size() != 2:
        return

    for button in buttons:
        # The artwork itself carries the button's visible label; these
        # controls must stay invisible so the art is the only thing seen.
        _check(button.text == "", "Hotspot buttons should have no text; the artwork provides the label.")
        _check(button.flat, "Hotspot buttons should be flat so no default button chrome is drawn.")
        _check(button.size.x > 0 and button.size.y > 0, "Hotspot button should have a non-zero size.")

    if background is TextureRect and background.texture != null:
        var viewport_size: Vector2 = instance.get_viewport_rect().size
        var texture_size: Vector2 = background.texture.get_size()
        var scale: float = maxf(viewport_size.x / texture_size.x, viewport_size.y / texture_size.y)
        var displayed_size: Vector2 = texture_size * scale
        var offset: Vector2 = (viewport_size - displayed_size) * 0.5

        var expected_new_game_pos: Vector2 = offset + Vector2(495, 592) * scale
        var expected_continue_pos: Vector2 = offset + Vector2(495, 665) * scale

        var new_game: Variant = buttons[0] if buttons[0].position.y < buttons[1].position.y else buttons[1]
        var continue_button: Variant = buttons[1] if buttons[0].position.y < buttons[1].position.y else buttons[0]

        _check(new_game.position.distance_to(expected_new_game_pos) < 1.0,
            "NEW GAME hotspot should align with its source plate rectangle.")
        _check(continue_button.position.distance_to(expected_continue_pos) < 1.0,
            "CONTINUE hotspot should align with its source plate rectangle.")
        _check(new_game.position.y < continue_button.position.y,
            "NEW GAME hotspot should sit above the CONTINUE hotspot, matching the artwork.")

    # The Continue hotspot must disable itself when no save file exists, same
    # behavior as before; SaveManager remains the authority on save content.
    var has_disabled := false
    for button in buttons:
        if button.disabled:
            has_disabled = true
    _check(has_disabled == (not FileAccess.file_exists("user://savegame.json")),
        "Continue hotspot's disabled state should match save-file availability.")
