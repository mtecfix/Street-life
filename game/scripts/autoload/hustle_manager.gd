extends Node

const HUSTLES := {
    "market_delivery": {
        "title": "Market supply run",
        "destination": "Maya's Market",
        "target_position": Vector2(310, 178),
        "cash": 30,
        "xp": 30,
        "locals_rep": 2
    },
    "apartment_drop": {
        "title": "Apartment package",
        "destination": "The Walk-Ups",
        "target_position": Vector2(765, 178),
        "cash": 35,
        "xp": 35,
        "locals_rep": 2
    }
}

func can_start_hustle() -> bool:
    if not get_active_hustle().is_empty():
        return false
    return int(GameState.world_flags.get("hustle_completed_day", 0)) != GameState.current_day

func start_hustle(hustle_id: String) -> bool:
    if not HUSTLES.has(hustle_id) or not can_start_hustle():
        return false
    GameState.world_flags["active_side_hustle"] = hustle_id
    EventBus.side_hustle_started.emit(hustle_id, GameState.current_day)
    SaveManager.save_game()
    return true

func get_active_hustle() -> Dictionary:
    var hustle_id := str(GameState.world_flags.get("active_side_hustle", ""))
    if not HUSTLES.has(hustle_id):
        return {}
    return HUSTLES[hustle_id]

func complete_active_hustle() -> bool:
    var hustle_id := str(GameState.world_flags.get("active_side_hustle", ""))
    if not HUSTLES.has(hustle_id):
        return false
    var hustle: Dictionary = HUSTLES[hustle_id]
    GameState.player_cash += int(hustle["cash"])
    GameState.world_flags["last_hustle_cash"] = int(hustle["cash"])
    GameState.world_flags["last_hustle_xp"] = int(hustle["xp"])
    GameState.award_experience(int(hustle["xp"]))
    GameState.adjust_reputation("locals", int(hustle["locals_rep"]))
    GameState.adjust_relationship("nia", 2)
    GameState.world_flags["active_side_hustle"] = ""
    GameState.world_flags["hustle_completed_day"] = GameState.current_day
    EventBus.side_hustle_completed.emit(hustle_id, GameState.current_day, int(hustle["cash"]), int(hustle["xp"]))
    SaveManager.save_game()
    return true

func get_completion_message() -> String:
    return "Nia: Clean delivery. +$%d, +%d XP, +2 local rep, and +2 relationship." % [
        int(GameState.world_flags.get("last_hustle_cash", 0)),
        int(GameState.world_flags.get("last_hustle_xp", 0))
    ]
