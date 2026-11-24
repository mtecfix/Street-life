extends SceneTree

# Regression test for Neighborhood.tscn / neighborhood.gd.
#
# This exists because neighborhood.gd previously had a syntax error (a block
# of `elif` clauses left dangling after an already-closed nested if/else in
# _refresh_hud()) that caused the entire script to fail to parse. No existing
# test loaded this scene directly, so the break went undetected on `main`.
#
# This test loads the real scene, confirms it parses and instantiates, and
# exercises _refresh_hud()'s hint-priority logic across its branches by
# toggling the underlying GameState/HustleManager/EventManager state the
# function actually reads, restoring everything afterward.
#
# Run: godot --headless --path game --script res://tests/test_neighborhood_hud.gd

var _failures: Array[String] = []

func _initialize() -> void:
    call_deferred("_run_tests")

func _run_tests() -> void:
    var scene_resource: Variant = load("res://scenes/world/Neighborhood.tscn")
    if scene_resource == null:
        push_error("Failed to load Neighborhood.tscn — scene or script failed to parse.")
        quit(1)
        return

    var state: Variant = root.get_node_or_null("GameState")
    var clock: Variant = root.get_node_or_null("WorldClock")
    if state == null or clock == null:
        push_error("Neighborhood HUD test could not find required autoloads.")
        quit(1)
        return

    var snapshot := _snapshot(state, clock)

    var instance: Node = scene_resource.instantiate()
    root.add_child(instance)
    await process_frame
    await process_frame

    _check(instance.has_method("_refresh_hud"), "Neighborhood scene should expose _refresh_hud().")

    # Park the clock at 23:00, outside every daily event window (7-10, 14-17,
    # 19-22) and clear any in-progress courier hustle, so only mission state
    # drives the hint text in the cases below.
    clock.total_minutes = 23 * 60
    state.world_flags["active_side_hustle"] = ""

    # Default state: no hustle, no event, mission not started.
    state.mission_active = false
    state.mission_completed = false
    instance._refresh_hud()
    _check(instance.hint_label.text.contains("Meet Rico"),
        "With no hustle, event, or mission, the hint should prompt meeting the neighborhood NPCs.")

    # Active mission, no choice made yet.
    state.mission_active = true
    instance._refresh_hud()
    _check(instance.hint_label.text.contains("ACTIVE JOB"),
        "An active mission should surface the active-job hint.")

    # Mission completed, alley follow-up not yet done.
    state.mission_active = false
    state.mission_completed = true
    state.world_flags["alley_encounter_completed"] = false
    instance._refresh_hud()
    _check(instance.hint_label.text.contains("JOB COMPLETE"),
        "A completed mission with the alley follow-up pending should prompt talking to Dre.")

    # Mission completed, alley follow-up also done.
    state.world_flags["alley_encounter_completed"] = true
    instance._refresh_hud()
    _check(instance.hint_label.text.contains("BLOCK SECURED"),
        "A fully completed mission should surface the block-secured hint.")

    instance.queue_free()
    _restore(state, clock, snapshot)

    if _failures.is_empty():
        print("PASS: Neighborhood scene parses and _refresh_hud() reports the correct hint at each mission stage.")
        quit(0)
    else:
        for message in _failures:
            push_error(message)
        quit(1)

func _check(condition: bool, message: String) -> void:
    if not condition:
        _failures.append(message)

func _snapshot(state: Variant, clock: Variant) -> Dictionary:
    return {
        "mission_active": state.mission_active,
        "mission_completed": state.mission_completed,
        "world_flags": state.world_flags.duplicate(true),
        "total_minutes": clock.total_minutes,
    }

func _restore(state: Variant, clock: Variant, snapshot: Dictionary) -> void:
    state.mission_active = snapshot["mission_active"]
    state.mission_completed = snapshot["mission_completed"]
    state.world_flags = snapshot["world_flags"]
    clock.total_minutes = snapshot["total_minutes"]
