extends Node

const SAVE_PATH := "user://savegame.json"
const SAVE_VERSION := 3

func _notification(what: int) -> void:
    if what == NOTIFICATION_WM_CLOSE_REQUEST or what == NOTIFICATION_APPLICATION_FOCUS_OUT:
        save_game()

func save_game() -> Error:
    var payload := {
        "version": SAVE_VERSION,
        "player_cash": GameState.player_cash,
        "player_health": GameState.player_health,
        "encounters_won": GameState.encounters_won,
        "world_day": GameState.current_day,
        "world_minutes": WorldClock.total_minutes,
        "mission_active": GameState.mission_active,
        "mission_completed": GameState.mission_completed,
        "previous_world_position": [GameState.previous_world_position.x, GameState.previous_world_position.y],
        "inventory": GameState.inventory.duplicate(true),
        "reputation": GameState.reputation.duplicate(true),
        "npc_relationships": GameState.npc_relationships.duplicate(true),
        "world_flags": GameState.world_flags.duplicate(true)
    }
    var file := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
    if file == null:
        return FileAccess.get_open_error()
    file.store_string(JSON.stringify(payload))
    return OK

func load_game() -> Error:
    if not FileAccess.file_exists(SAVE_PATH):
        return ERR_FILE_NOT_FOUND
    var file := FileAccess.open(SAVE_PATH, FileAccess.READ)
    if file == null:
        return FileAccess.get_open_error()

    var parsed: Variant = JSON.parse_string(file.get_as_text())
    if typeof(parsed) != TYPE_DICTIONARY:
        return ERR_PARSE_ERROR

    var data: Dictionary = parsed
    var version := int(data.get("version", 0))
    if version < 1 or version > SAVE_VERSION:
        return ERR_INVALID_DATA

    GameState.player_cash = maxi(0, int(data.get("player_cash", 25)))
    GameState.player_health = clampi(int(data.get("player_health", 100)), 0, 100)
    GameState.encounters_won = maxi(0, int(data.get("encounters_won", 0)))
    WorldClock.total_minutes = maxi(0, int(data.get("world_minutes", 480)))
    GameState.current_day = int(WorldClock.total_minutes / 1440) + 1
    GameState.mission_active = bool(data.get("mission_active", false))
    GameState.mission_completed = bool(data.get("mission_completed", false))

    var saved_position: Variant = data.get("previous_world_position", [480.0, 270.0])
    if saved_position is Array and saved_position.size() == 2:
        GameState.previous_world_position = Vector2(float(saved_position[0]), float(saved_position[1]))

    _restore_integer_dictionary(GameState.inventory, data.get("inventory", {}), true)
    _restore_integer_dictionary(GameState.reputation, data.get("reputation", {"locals": 0}), false)
    _restore_integer_dictionary(GameState.npc_relationships, data.get("npc_relationships", {}), false)
    var saved_flags: Variant = data.get("world_flags", {})
    if saved_flags is Dictionary:
        GameState.world_flags = saved_flags.duplicate(true)
    return OK

func _restore_integer_dictionary(target: Dictionary, source: Variant, positive_only: bool) -> void:
    target.clear()
    if not source is Dictionary:
        return
    for key in source:
        var value := int(source[key])
        if not positive_only or value > 0:
            target[str(key)] = value
