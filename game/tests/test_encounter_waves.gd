extends SceneTree

# Run: godot --headless --path game --script res://tests/test_encounter_waves.gd

var _failures: Array[String] = []

func _initialize() -> void:
    call_deferred("_run_tests")

func _run_tests() -> void:
    var corner := EncounterWaveController.get_waves("corner_brawler")
    var shop := EncounterWaveController.get_waves("shop_guard")
    var alley := EncounterWaveController.get_waves("alley_ambush")
    _check(corner.size() == 2, "Corner encounter should contain two opponents.")
    _check(shop.size() == 2, "Market encounter should contain two opponents.")
    _check(alley.size() == 3, "Alley ambush should escalate through three opponents.")
    _check(str(alley[0]["archetype"]) == "skirmisher", "Alley wave one should open with a mobile skirmisher.")
    _check(str(alley[2]["archetype"]) == "counter_guard", "Alley wave three should finish with a counter guard.")
    _check(EncounterWaveController.has_following_wave("alley_ambush", 0), "First alley opponent should have backup.")
    _check(not EncounterWaveController.has_following_wave("alley_ambush", 2), "Final alley opponent should end the encounter.")
    _check(EncounterWaveController.get_wave_count("unknown") == 2, "Unknown encounters should safely use the corner wave roster.")
    corner[0]["name"] = "Mutated test name"
    _check(str(EncounterWaveController.get_waves("corner_brawler")[0]["name"]) == "Corner challenger", "Returned wave data must not mutate the shared roster.")

    if _failures.is_empty():
        print("PASS: encounter wave rosters, escalation, and defensive data copies.")
        quit(0)
    else:
        for failure in _failures:
            push_error(failure)
        quit(1)

func _check(condition: bool, message: String) -> void:
    if not condition:
        _failures.append(message)
