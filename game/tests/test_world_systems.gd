extends SceneTree

# Headless test for WorldClock, EventManager (Sprint 6) and HustleManager (Sprint 7).
# Run: godot --headless --path game --script res://tests/test_world_systems.gd

const SAVE_PATH := "user://savegame.json"

var _failures: Array[String] = []

func _initialize() -> void:
    call_deferred("_run_tests")

func _run_tests() -> void:
    var state: Variant = root.get_node_or_null("GameState")
    var clock: Variant = root.get_node_or_null("WorldClock")
    var events: Variant = root.get_node_or_null("EventManager")
    var hustles: Variant = root.get_node_or_null("HustleManager")
    if state == null or clock == null or events == null or hustles == null:
        push_error("World systems test could not find required autoloads.")
        quit(1)
        return

    clock.set_process(false)
    var snapshot := _snapshot(state, clock)
    var original_save := _read_save()

    _test_clock_advance_and_format(state, clock)
    _test_clock_day_rollover(state, clock)
    _test_event_windows(state, clock, events)
    _test_event_completion(state, clock, events)
    _test_event_daily_reset(state, clock, events)
    _test_hustle_lifecycle(state, clock, hustles)
    _test_hustle_standing_bonus(state, clock, hustles)

    _restore(state, clock, snapshot)
    _write_save(original_save)
    clock.set_process(true)

    if _failures.is_empty():
        print("PASS: world clock, daily events, and side hustle rules.")
        quit(0)
    else:
        for message in _failures:
            push_error(message)
        quit(1)

func _check(condition: bool, message: String) -> void:
    if not condition:
        _failures.append(message)

func _reset(state: Variant, clock: Variant, minutes: int) -> void:
    clock.total_minutes = minutes
    state.current_day = int(minutes / 1440) + 1
    state.player_cash = 0
    state.player_xp = 0
    state.player_level = 1
    state.skill_points = 0
    state.reputation = {"locals": 0, "rivals": 0}
    state.npc_relationships = {}
    state.world_flags = {}

func _test_clock_advance_and_format(state: Variant, clock: Variant) -> void:
    _reset(state, clock, 480)
    _check(clock.get_time_string() == "8:00 AM", "Start time should read 8:00 AM.")
    clock.advance_minutes(0)
    clock.advance_minutes(-30)
    _check(clock.total_minutes == 480, "Zero or negative advance should change nothing.")
    clock.advance_minutes(65)
    _check(clock.total_minutes == 545 and clock.get_time_string() == "9:05 AM", "Advancing 65 minutes should read 9:05 AM.")

    var cases := {0: "12:00 AM", 59: "12:59 AM", 720: "12:00 PM", 785: "1:05 PM", 1439: "11:59 PM"}
    for minutes in cases:
        _reset(state, clock, int(minutes))
        _check(clock.get_time_string() == str(cases[minutes]), "Minute %d should read %s but read %s." % [int(minutes), str(cases[minutes]), clock.get_time_string()])

func _test_clock_day_rollover(state: Variant, clock: Variant) -> void:
    _reset(state, clock, 1430)
    var new_days: Array[int] = []
    var on_new_day := func(day: int) -> void: new_days.append(day)
    var bus: Node = root.get_node("EventBus")
    bus.new_day_started.connect(on_new_day)

    clock.advance_minutes(5)
    _check(state.current_day == 1 and new_days.is_empty(), "Day should not roll over before midnight.")
    clock.advance_minutes(5)
    _check(state.current_day == 2, "Day should become 2 after midnight.")
    _check(new_days == [2], "new_day_started should fire once with day 2.")
    _check(clock.get_time_string() == "12:00 AM", "Time just after rollover should be 12:00 AM.")

    clock.advance_minutes(1440)
    _check(state.current_day == 3 and new_days == [2, 3], "A full-day advance should roll over once.")
    bus.new_day_started.disconnect(on_new_day)

func _test_event_windows(state: Variant, clock: Variant, events: Variant) -> void:
    var expected := {
        6: "", 7: "market_delivery", 9: "market_delivery", 10: "",
        13: "", 14: "court_pickup", 16: "court_pickup", 17: "",
        18: "", 19: "rival_watch", 21: "rival_watch", 22: ""
    }
    for hour in expected:
        _reset(state, clock, int(hour) * 60 + 30)
        var active: Dictionary = events.get_active_event()
        var active_id := "" if active.is_empty() else str(active["id"])
        _check(active_id == str(expected[hour]), "Hour %d should have event '%s' but had '%s'." % [int(hour), str(expected[hour]), active_id])

func _test_event_completion(state: Variant, clock: Variant, events: Variant) -> void:
    _reset(state, clock, 8 * 60)
    _check(not events.complete_active_event("court_pickup"), "Completing an event outside its window should fail.")
    _check(state.player_cash == 0, "A failed completion must not pay out.")

    _check(events.complete_active_event("market_delivery"), "Completing the active event should succeed.")
    _check(state.player_cash == 12 and state.player_xp == 15, "Market delivery should pay $12 and 15 XP.")
    _check(int(state.reputation["locals"]) == 2 and int(state.reputation["rivals"]) == 0, "Market delivery should add 2 local rep.")
    _check(int(state.npc_relationships.get("maya", 0)) == 2, "Market delivery should add 2 Maya relationship.")
    _check(events.get_active_event().is_empty(), "A completed event should no longer be active that day.")
    _check(not events.complete_active_event("market_delivery"), "The same event cannot be completed twice in a day.")
    _check(state.player_cash == 12, "A repeated completion must not pay out again.")

    _reset(state, clock, 20 * 60)
    _check(events.complete_active_event("rival_watch"), "Rival watch should complete in its window.")
    _check(int(state.reputation["locals"]) == 2 and int(state.reputation["rivals"]) == -2, "Rival watch should give +2 locals and -2 rivals.")
    _check(not state.npc_relationships.has("maya"), "Rival watch should not touch Maya relationship.")

func _test_event_daily_reset(state: Variant, clock: Variant, events: Variant) -> void:
    _reset(state, clock, 8 * 60)
    events.complete_active_event("market_delivery")
    clock.advance_minutes(1440)
    _check(state.current_day == 2, "Test setup should be on day 2.")
    _check(str(events.get_active_event().get("id", "")) == "market_delivery", "The same event should be available again the next day.")
    _check(events.complete_active_event("market_delivery"), "Next-day completion should succeed.")

func _test_hustle_lifecycle(state: Variant, clock: Variant, hustles: Variant) -> void:
    _reset(state, clock, 480)
    _check(hustles.can_start_hustle(), "A hustle should be startable on a fresh day.")
    _check(hustles.get_active_hustle().is_empty(), "No hustle should be active initially.")
    _check(not hustles.complete_active_hustle(), "Completing with no active hustle should fail.")
    _check(not hustles.start_hustle("not_a_hustle"), "Starting an unknown hustle should fail.")

    _check(hustles.start_hustle("market_delivery"), "Starting market_delivery should succeed.")
    _check(str(hustles.get_active_hustle().get("title", "")) == "Market supply run", "Active hustle should be the market supply run.")
    _check(not hustles.can_start_hustle(), "Cannot start a hustle while one is active.")
    _check(not hustles.start_hustle("apartment_drop"), "Cannot start a second hustle while one is active.")

    _check(hustles.complete_active_hustle(), "Completing the active hustle should succeed.")
    _check(state.player_cash == 30 and state.player_xp == 30, "Market supply run should pay $30 and 30 XP at neutral standing.")
    _check(int(state.reputation["locals"]) == 2, "Hustle should add 2 local rep.")
    _check(int(state.npc_relationships.get("nia", 0)) == 2, "Hustle should add 2 Nia relationship.")
    _check(hustles.get_active_hustle().is_empty(), "Hustle should clear after completion.")
    _check(not hustles.can_start_hustle(), "Only one hustle may be completed per day.")
    _check(not hustles.start_hustle("apartment_drop"), "Starting a second hustle the same day should fail.")

    clock.advance_minutes(1440)
    _check(hustles.can_start_hustle(), "A hustle should be startable again the next day.")
    _check(hustles.start_hustle("apartment_drop") and hustles.complete_active_hustle(), "Apartment drop should run on day 2.")
    _check(state.player_cash == 65 and state.player_xp == 65, "Apartment drop should add $35 and 35 XP.")

func _test_hustle_standing_bonus(state: Variant, clock: Variant, hustles: Variant) -> void:
    _reset(state, clock, 480)
    state.reputation["locals"] = 10
    hustles.start_hustle("market_delivery")
    hustles.complete_active_hustle()
    _check(state.player_cash == 32, "KNOWN standing should add a $2 bonus to the $30 reward.")
    _check(int(state.world_flags.get("last_hustle_bonus", -1)) == 2, "last_hustle_bonus should record the $2 bonus.")
    _check("includes +$2" in hustles.get_completion_message(), "Completion message should mention the standing bonus.")

    _reset(state, clock, 480)
    hustles.start_hustle("market_delivery")
    hustles.complete_active_hustle()
    _check(not "includes" in hustles.get_completion_message(), "Completion message should omit the bonus text at neutral standing.")

func _snapshot(state: Variant, clock: Variant) -> Dictionary:
    return {
        "minutes": clock.total_minutes,
        "day": state.current_day,
        "cash": state.player_cash,
        "xp": state.player_xp,
        "level": state.player_level,
        "skill_points": state.skill_points,
        "reputation": state.reputation.duplicate(true),
        "relationships": state.npc_relationships.duplicate(true),
        "flags": state.world_flags.duplicate(true)
    }

func _restore(state: Variant, clock: Variant, snapshot: Dictionary) -> void:
    clock.total_minutes = snapshot["minutes"]
    state.current_day = snapshot["day"]
    state.player_cash = snapshot["cash"]
    state.player_xp = snapshot["xp"]
    state.player_level = snapshot["level"]
    state.skill_points = snapshot["skill_points"]
    state.reputation = snapshot["reputation"]
    state.npc_relationships = snapshot["relationships"]
    state.world_flags = snapshot["flags"]

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
