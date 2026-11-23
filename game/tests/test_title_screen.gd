extends SceneTree

# Headless test for the TitleScreen scene: confirms the scene resource parses,
# the background artwork loads as a real texture, and the core menu actions
# (NEW GAME, CONTINUE) are present as actual Button nodes.
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

    _check_background(instance)
    _check_overlay(instance)
    _check_menu_buttons(instance)

    instance.queue_free()

    if _failures.is_empty():
        print("PASS: title screen scene parses, loads background art, and builds its menu.")
        quit(0)
    else:
        for message in _failures:
            push_error(message)
        quit(1)

func _check(condition: bool, message: String) -> void:
    if not condition:
        _failures.append(message)

func _check_background(instance: Control) -> void:
    var background: Variant = instance.get_child(0)
    _check(background is TextureRect, "First child should be the background TextureRect.")
    if background is TextureRect:
        _check(background.texture != null, "Background TextureRect must have a loaded texture.")
        if background.texture != null:
            var size: Vector2 = background.texture.get_size()
            _check(size.x > 0 and size.y > 0, "Background texture should have non-zero dimensions.")

func _check_overlay(instance: Control) -> void:
    var overlay: Variant = instance.get_child(1)
    _check(overlay is ColorRect, "Second child should be the legibility overlay ColorRect.")

func _check_menu_buttons(instance: Control) -> void:
    var found_new_game := false
    var found_continue := false
    for node in instance.find_children("*", "Button", true, false):
        if node.text == "NEW GAME":
            found_new_game = true
        if node.text == "CONTINUE":
            found_continue = true
    _check(found_new_game, "Menu should contain a NEW GAME button.")
    _check(found_continue, "Menu should contain a CONTINUE button.")
