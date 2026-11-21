extends Node

const SAVE_PATH := "user://savegame.json"
const SAVE_VERSION := 1

func save_game() -> Error:
    var payload := {
        "version": SAVE_VERSION,
        "player_cash": GameState.player_cash,
        "player_health": GameState.player_health,
        "encounters_won": GameState.encounters_won,
        "world_day": GameState.current_day,
        "world_minutes": WorldClock.total_minutes
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
    GameState.current_day = int(data.get("world_day", 1))
    WorldClock.total_minutes = int(data.get("world_minutes", 480))
    return OK
