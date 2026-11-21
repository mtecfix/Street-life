extends Node

const SAVE_PATH := "user://savegame.json"
const SAVE_VERSION := 2

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
        "inventory": GameState.inventory
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
    if version > SAVE_VERSION or version < 1:
        return ERR_INVALID_DATA

    GameState.player_cash = int(data.get("player_cash", 25))
    GameState.player_health = int(data.get("player_health", 100))
    GameState.encounters_won = int(data.get("encounters_won", 0))
    WorldClock.total_minutes = maxi(0, int(data.get("world_minutes", 480)))
    GameState.current_day = int(WorldClock.total_minutes / 1440) + 1
    GameState.mission_active = bool(data.get("mission_active", false))
    GameState.mission_completed = bool(data.get("mission_completed", false))

    var saved_position: Variant = data.get("previous_world_position", [480.0, 270.0])
    if saved_position is Array and saved_position.size() == 2:
        GameState.previous_world_position = Vector2(float(saved_position[0]), float(saved_position[1]))

    var saved_inventory: Variant = data.get("inventory", {})
    if saved_inventory is Dictionary:
        GameState.inventory.clear()
        for item_id in saved_inventory:
            var count := int(saved_inventory[item_id])
            if count > 0:
                GameState.inventory[str(item_id)] = count
    return OK
