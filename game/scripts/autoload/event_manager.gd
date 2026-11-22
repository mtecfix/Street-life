extends Node

const DAILY_EVENTS := [
    {
        "id": "market_delivery",
        "title": "Market delivery",
        "hours": "7 AM–10 AM",
        "start_hour": 7,
        "end_hour": 10,
        "position": Vector2(310, 178),
        "cash": 12,
        "xp": 15,
        "locals_rep": 2,
        "rivals_rep": 0,
        "maya_relationship": 2
    },
    {
        "id": "court_pickup",
        "title": "Community court",
        "hours": "2 PM–5 PM",
        "start_hour": 14,
        "end_hour": 17,
        "position": Vector2(755, 450),
        "cash": 18,
        "xp": 20,
        "locals_rep": 2,
        "rivals_rep": 0,
        "maya_relationship": 0
    },
    {
        "id": "rival_watch",
        "title": "Rival watch",
        "hours": "7 PM–10 PM",
        "start_hour": 19,
        "end_hour": 22,
        "position": Vector2(735, 355),
        "cash": 10,
        "xp": 20,
        "locals_rep": 2,
        "rivals_rep": -2,
        "maya_relationship": 0
    }
]

func get_active_event() -> Dictionary:
    var hour := WorldClock.get_hour()
    var day_key := str(GameState.current_day)
    var daily_completions: Dictionary = GameState.world_flags.get("daily_event_completions", {})
    var completed_today: Array = daily_completions.get(day_key, [])
    for event in DAILY_EVENTS:
        if hour >= int(event["start_hour"]) and hour < int(event["end_hour"]):
            if completed_today.has(str(event["id"])):
                return {}
            return event
    return {}

func complete_active_event(event_id: String) -> bool:
    var active_event := get_active_event()
    if active_event.is_empty() or str(active_event["id"]) != event_id:
        return false

    var day_key := str(GameState.current_day)
    var daily_completions: Dictionary = GameState.world_flags.get("daily_event_completions", {}).duplicate(true)
    var completed_today: Array = daily_completions.get(day_key, []).duplicate()
    if completed_today.has(event_id):
        return false
    completed_today.append(event_id)
    daily_completions[day_key] = completed_today
    GameState.world_flags["daily_event_completions"] = daily_completions

    GameState.player_cash += int(active_event["cash"])
    GameState.award_experience(int(active_event["xp"]))
    GameState.adjust_reputation("locals", int(active_event["locals_rep"]))
    GameState.adjust_reputation("rivals", int(active_event["rivals_rep"]))
    if int(active_event["maya_relationship"]) != 0:
        GameState.adjust_relationship("maya", int(active_event["maya_relationship"]))
    EventBus.world_event_completed.emit(event_id, GameState.current_day)
    SaveManager.save_game()
    return true

func get_completion_message(event_id: String) -> String:
    match event_id:
        "market_delivery":
            return "Maya: Appreciate the help. +$12, +15 XP, and the neighbors noticed."
        "court_pickup":
            return "The court's with you. +$18, +20 XP, and local respect increased."
        "rival_watch":
            return "Dre: Good looking out. +$10, +20 XP; rival pressure eased a little."
    return "Neighborhood event completed."
