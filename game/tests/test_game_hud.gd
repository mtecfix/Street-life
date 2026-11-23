extends SceneTree

# Headless regression test for the additive gameplay HUD.
# The HUD must instantiate independently and display real autoload state.
# This test intentionally does not require the whole neighborhood to be
# rewritten or mock the gameplay managers.

var _failures: Array[String] = []

func _initialize() -> void:
    call_deferred("_run")

func _run() -> void:
    var packed: PackedScene = load("res://scenes/ui/GameHUD.tscn")
    _check(packed != null, "GameHUD.tscn should load.")
    if packed == null:
        quit(1)
        return

    var hud := packed.instantiate()
    root.add_child(hud)
    await process_frame
    await process_frame

    _check(hud is CanvasLayer, "Gameplay HUD should be a CanvasLayer.")
    _check(hud.get_node_or_null("PanelContainer") == null, "HUD builds its panels dynamically; no required hard-coded panel node.")
    _check(hud.get_child_count() >= 4, "HUD should build status, objective, district, map and controls panels.")

    var labels := hud.find_children("*", "Label", true, false)
    var has_objective := false
    var has_clock := false
    for label in labels:
        if label.text.contains("Meet Rico"):
            has_objective = true
        if label.text.contains("DAY"):
            has_clock = true
    _check(has_objective, "Fresh-game objective should direct the player to meet Rico without activating the mission.")
    _check(has_clock, "HUD should display the existing world day and clock.")

    hud.queue_free()
    if _failures.is_empty():
        print("PASS: additive gameplay HUD loads and reflects initial game state.")
        quit(0)
    else:
        for failure in _failures:
            push_error(failure)
        quit(1)

func _check(condition: bool, message: String) -> void:
    if not condition:
        _failures.append(message)
