extends SceneTree

# Headless test for DebugBridge snapshot content and read-only behavior.
# JavaScriptBridge publishing needs a web build and is not covered here.
# Run: godot --headless --path game --script res://tests/test_debug_bridge.gd

var _failures: Array[String] = []

func _initialize() -> void:
    call_deferred("_run_tests")

func _run_tests() -> void:
    var bridge: Variant = root.get_node_or_null("DebugBridge")
    var state: Variant = root.get_node_or_null("GameState")
    if bridge == null or state == null:
        push_error("Debug bridge test could not find required autoloads.")
        quit(1)
        return

    _check(not bridge.is_processing(), "Bridge must be inert on non-web platforms.")

    state.player_cash = 77
    state.reputation = {"locals": 4, "rivals": -3}
    state.world_flags = {"probe": {"nested": 1}}
    var before := JSON.stringify([state.player_cash, state.reputation, state.world_flags, state.npc_relationships, state.inventory])

    var snapshot: Dictionary = bridge._snapshot()
    for key in ["scene", "cash", "health", "day", "total_minutes", "clock", "encounters_won", "encounter_id", "mission_active", "mission_completed", "mission_choice", "mission_outcome", "inventory", "reputation", "relationships", "flags", "previous_position"]:
        _check(snapshot.has(key), "Snapshot is missing '%s'." % key)
    for key in ["level", "xp", "skill_points", "skill_levels"]:
        _check(snapshot.has(key), "Snapshot is missing progression field '%s'." % key)

    _check(int(snapshot.get("cash", -1)) == 77, "Snapshot cash should match GameState.")
    snapshot["reputation"]["locals"] = 99
    snapshot["flags"]["probe"] = "mutated"
    var after := JSON.stringify([state.player_cash, state.reputation, state.world_flags, state.npc_relationships, state.inventory])
    _check(before == after, "Mutating a snapshot must not change GameState.")

    var literal := JSON.stringify(JSON.stringify(snapshot))
    var round_trip: Variant = JSON.parse_string(JSON.parse_string(literal))
    _check(round_trip is Dictionary and int(round_trip.get("cash", -1)) == 77, "Double-encoded snapshot should decode back to the same data.")

    if _failures.is_empty():
        print("PASS: debug bridge snapshot is complete, read-only, and round-trips.")
        quit(0)
    else:
        for message in _failures:
            push_error(message)
        quit(1)

func _check(condition: bool, message: String) -> void:
    if not condition:
        _failures.append(message)
