extends SceneTree

# Regression test: exploration movement must use the authoritative progression stat.
# Run: godot --headless --path game --script res://tests/test_player_movement.gd

const PLAYER_SCENE := "res://scenes/characters/Player.tscn"

var _failures: Array[String] = []

func _initialize() -> void:
    call_deferred("_run_tests")

func _run_tests() -> void:
    var state: Variant = root.get_node_or_null("GameState")
    if state == null:
        push_error("Player movement test could not find GameState autoload.")
        quit(1)
        return

    var original_levels: Dictionary = state.skill_levels.duplicate(true)
    var packed_scene := load(PLAYER_SCENE) as PackedScene
    if packed_scene == null:
        push_error("Could not load Player scene: %s" % PLAYER_SCENE)
        quit(1)
        return

    var player := packed_scene.instantiate()
    root.add_child(player)

    state.skill_levels = {"power": 0, "endurance": 0, "footwork": 0}
    _check(is_equal_approx(player.get_current_move_speed(), 225.0),
        "Base exploration speed should match GameState base speed.")

    state.skill_levels["footwork"] = 1
    _check(is_equal_approx(player.get_current_move_speed(), 237.0),
        "Footwork rank 1 should increase exploration speed to 237.")

    state.skill_levels["footwork"] = 2
    _check(is_equal_approx(player.get_current_move_speed(), 249.0),
        "Footwork rank 2 should increase exploration speed to 249.")

    state.skill_levels["footwork"] = 3
    _check(is_equal_approx(player.get_current_move_speed(), 261.0),
        "Footwork rank 3 should increase exploration speed to 261.")

    state.skill_levels = original_levels
    player.queue_free()

    if _failures.is_empty():
        print("PASS: exploration movement speed follows Footwork progression.")
        quit(0)
    else:
        for message in _failures:
            push_error(message)
        quit(1)

func _check(condition: bool, message: String) -> void:
    if not condition:
        _failures.append(message)
