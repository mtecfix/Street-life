extends SceneTree

# Headless test for Sprint 5 progression, training and save migration.
# Run: godot --headless --path game --script res://tests/test_progression.gd

const SAVE_PATH := "user://savegame.json"

var _failures: Array[String] = []

func _initialize() -> void:
    call_deferred("_run_tests")

func _run_tests() -> void:
    var state: Variant = root.get_node_or_null("GameState")
    var saves: Variant = root.get_node_or_null("SaveManager")
    if state == null or saves == null:
        push_error("Progression test could not find required autoloads.")
        quit(1)
        return

    var snapshot := _snapshot(state)
    var original_save := _read_save()

    _test_xp_thresholds(state)
    _test_level_ups(state)
    _test_training_rules(state)
    _test_stat_scaling(state)
    _test_save_round_trip(state, saves)
    _test_legacy_save_migration(state, saves)
    _test_save_clamping(state, saves)

    _restore(state, snapshot)
    _write_save(original_save)

    if _failures.is_empty():
        print("PASS: progression levels, training caps, stat scaling, and save migration.")
        quit(0)
    else:
        for message in _failures:
            push_error(message)
        quit(1)

func _check(condition: bool, message: String) -> void:
    if not condition:
        _failures.append(message)

func _reset(state: Variant) -> void:
    state.player_xp = 0
    state.player_level = 1
    state.skill_points = 0
    state.skill_levels = {"power": 0, "endurance": 0, "footwork": 0}

func _test_xp_thresholds(state: Variant) -> void:
    _reset(state)
    _check(state.xp_required_for_next_level() == 100, "Level 1 should require 100 XP.")
    state.player_level = 2
    _check(state.xp_required_for_next_level() == 150, "Level 2 should require 150 XP.")
    state.player_level = 5
    _check(state.xp_required_for_next_level() == 300, "Level 5 should require 300 XP.")

func _test_level_ups(state: Variant) -> void:
    _reset(state)
    _check(state.award_experience(0) == 0 and state.player_xp == 0, "Zero XP award should change nothing.")
    _check(state.award_experience(-10) == 0 and state.player_xp == 0, "Negative XP award should change nothing.")

    _check(state.award_experience(99) == 0, "99 XP should not level up.")
    _check(state.player_level == 1 and state.player_xp == 99 and state.skill_points == 0, "State after 99 XP is wrong.")

    _check(state.award_experience(1) == 1, "Reaching 100 XP should gain one level.")
    _check(state.player_level == 2 and state.player_xp == 0 and state.skill_points == 1, "State after first level-up is wrong.")

    _reset(state)
    _check(state.award_experience(250) == 2, "250 XP from level 1 should gain two levels.")
    _check(state.player_level == 3 and state.player_xp == 0 and state.skill_points == 2, "State after multi-level award is wrong.")

    _reset(state)
    state.award_experience(120)
    _check(state.player_level == 2 and state.player_xp == 20, "Leftover XP should carry into the next level.")

func _test_training_rules(state: Variant) -> void:
    _reset(state)
    _check(not state.train_skill("power"), "Training with zero skill points should fail.")
    state.skill_points = 10
    _check(not state.train_skill("not_a_skill"), "Training an unknown skill should fail.")
    _check(state.skill_points == 10, "Failed training must not spend points.")

    for rank in range(1, 4):
        _check(state.train_skill("power"), "Power rank %d should succeed." % rank)
    _check(int(state.skill_levels["power"]) == 3 and state.skill_points == 7, "Power should be rank 3 with 7 points left.")
    _check(not state.train_skill("power"), "Power rank 4 should be refused.")
    _check(state.skill_points == 7, "Refused rank 4 must not spend a point.")
    _check(state.train_skill("endurance") and state.train_skill("footwork"), "Other disciplines should still train.")

func _test_stat_scaling(state: Variant) -> void:
    _reset(state)
    _check(state.get_attack_damage() == 25, "Base attack damage should be 25.")
    _check(is_equal_approx(state.get_max_stamina(), 100.0), "Base max stamina should be 100.")
    _check(is_equal_approx(state.get_stamina_regen(), 14.0), "Base stamina regen should be 14.")
    _check(is_equal_approx(state.get_dodge_cost(), 30.0), "Base dodge cost should be 30.")
    _check(is_equal_approx(state.get_player_speed(), 225.0), "Base speed should be 225.")

    state.skill_levels = {"power": 3, "endurance": 3, "footwork": 3}
    _check(state.get_attack_damage() == 40, "Max Power attack damage should be 40.")
    _check(is_equal_approx(state.get_max_stamina(), 145.0), "Max Endurance stamina should be 145.")
    _check(is_equal_approx(state.get_stamina_regen(), 20.0), "Max Endurance regen should be 20.")
    _check(is_equal_approx(state.get_dodge_cost(), 18.0), "Max Footwork dodge cost should be 18.")
    _check(is_equal_approx(state.get_player_speed(), 261.0), "Max Footwork speed should be 261.")

    state.skill_levels = {"power": 0, "endurance": 0, "footwork": 10}
    _check(state.get_dodge_cost() >= 18.0, "Dodge cost must never drop below its 18 floor.")

func _test_save_round_trip(state: Variant, saves: Variant) -> void:
    _reset(state)
    state.player_xp = 40
    state.player_level = 4
    state.skill_points = 2
    state.skill_levels = {"power": 1, "endurance": 2, "footwork": 3}
    _check(saves.save_game() == OK, "Saving should succeed.")
    _reset(state)
    _check(saves.load_game() == OK, "Loading a v5 save should succeed.")
    _check(state.player_xp == 40 and state.player_level == 4 and state.skill_points == 2, "XP, level, or skill points did not round-trip.")
    _check(int(state.skill_levels["power"]) == 1 and int(state.skill_levels["endurance"]) == 2 and int(state.skill_levels["footwork"]) == 3, "Skill ranks did not round-trip.")

func _test_legacy_save_migration(state: Variant, saves: Variant) -> void:
    for legacy_version in [1, 2, 3, 4]:
        state.player_xp = 77
        state.player_level = 9
        state.skill_points = 5
        state.skill_levels = {"power": 2, "endurance": 2, "footwork": 2}
        _write_save(JSON.stringify({"version": legacy_version, "player_cash": 123, "encounters_won": 3}))
        _check(saves.load_game() == OK, "Loading a v%d save should succeed." % legacy_version)
        _check(state.player_level == 1 and state.player_xp == 0 and state.skill_points == 0, "v%d save should default progression to level 1, 0 XP, 0 points." % legacy_version)
        _check(int(state.skill_levels.get("power", -1)) == 0 and int(state.skill_levels.get("endurance", -1)) == 0 and int(state.skill_levels.get("footwork", -1)) == 0, "v%d save should default all skill ranks to 0." % legacy_version)
        _check(state.player_cash == 123 and state.encounters_won == 3, "v%d save should keep existing progress." % legacy_version)

    _write_save(JSON.stringify({"version": 7}))
    _check(saves.load_game() == ERR_INVALID_DATA, "A save from a newer version should be rejected.")

func _test_save_clamping(state: Variant, saves: Variant) -> void:
    _write_save(JSON.stringify({
        "version": 5,
        "player_xp": -50,
        "player_level": 0,
        "skill_points": -3,
        "skill_levels": {"power": 9, "endurance": -2}
    }))
    _check(saves.load_game() == OK, "Loading an out-of-range save should succeed.")
    _check(state.player_xp == 0 and state.player_level == 1 and state.skill_points == 0, "Negative progression values should be clamped.")
    _check(int(state.skill_levels["power"]) == 3, "Skill rank above 3 should clamp to 3.")
    _check(int(state.skill_levels["endurance"]) == 0, "Negative skill rank should clamp to 0.")
    _check(int(state.skill_levels["footwork"]) == 0, "Missing skill rank should default to 0.")

func _snapshot(state: Variant) -> Dictionary:
    return {
        "player_xp": state.player_xp,
        "player_level": state.player_level,
        "skill_points": state.skill_points,
        "skill_levels": state.skill_levels.duplicate(true),
        "player_cash": state.player_cash,
        "encounters_won": state.encounters_won
    }

func _restore(state: Variant, snapshot: Dictionary) -> void:
    state.player_xp = snapshot["player_xp"]
    state.player_level = snapshot["player_level"]
    state.skill_points = snapshot["skill_points"]
    state.skill_levels = snapshot["skill_levels"]
    state.player_cash = snapshot["player_cash"]
    state.encounters_won = snapshot["encounters_won"]

func _read_save() -> String:
    if not FileAccess.file_exists(SAVE_PATH):
        return ""
    return FileAccess.get_file_as_string(SAVE_PATH)

func _write_save(content: String) -> void:
    if content.is_empty():
        if FileAccess.file_exists(SAVE_PATH):
            DirAccess.remove_absolute(ProjectSettings.globalize_path(SAVE_PATH))
        return
    var file := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
    if file != null:
        file.store_string(content)
