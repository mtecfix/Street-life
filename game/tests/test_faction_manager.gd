extends SceneTree

func _initialize() -> void:
    call_deferred("_run_tests")

func _run_tests() -> void:
    var manager: Variant = root.get_node_or_null("FactionManager")
    var state: Variant = root.get_node_or_null("GameState")
    if manager == null or state == null:
        push_error("Faction standing test could not find required autoloads.")
        quit(1)
        return

    var original_reputation: Dictionary = state.reputation.duplicate(true)
    var local_cases := [
        {"score": -25, "label": "UNWELCOME", "bonus": 0},
        {"score": 0, "label": "UNKNOWN", "bonus": 0},
        {"score": 10, "label": "KNOWN", "bonus": 2},
        {"score": 30, "label": "TRUSTED", "bonus": 5},
        {"score": 60, "label": "PILLAR", "bonus": 8}
    ]
    for test_case in local_cases:
        state.reputation["locals"] = int(test_case["score"])
        if manager.get_standing_label("locals") != str(test_case["label"]) or manager.get_side_hustle_cash_bonus() != int(test_case["bonus"]):
            push_error("Local standing boundary failed at reputation %d." % int(test_case["score"]))
            state.reputation = original_reputation
            quit(1)
            return

    var rival_cases := [
        {"score": -25, "label": "HUNTED"},
        {"score": -11, "label": "WARY"},
        {"score": -10, "label": "NEUTRAL"},
        {"score": 9, "label": "NEUTRAL"},
        {"score": 10, "label": "CONNECTED"},
        {"score": 30, "label": "INSIDER"}
    ]
    for test_case in rival_cases:
        state.reputation["rivals"] = int(test_case["score"])
        if manager.get_standing_label("rivals") != str(test_case["label"]):
            push_error("Rival standing boundary failed at reputation %d." % int(test_case["score"]))
            state.reputation = original_reputation
            quit(1)
            return

    state.reputation = original_reputation
    print("PASS: faction standing tiers and local courier bonus thresholds.")
    quit(0)
