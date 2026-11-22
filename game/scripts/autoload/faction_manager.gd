extends Node

const LOCAL_STANDING_THRESHOLDS := [
    {"minimum": 60, "label": "PILLAR", "cash_bonus": 8},
    {"minimum": 30, "label": "TRUSTED", "cash_bonus": 5},
    {"minimum": 10, "label": "KNOWN", "cash_bonus": 2},
    {"minimum": -24, "label": "UNKNOWN", "cash_bonus": 0},
    {"minimum": -100, "label": "UNWELCOME", "cash_bonus": 0}
]

func get_standing_label(faction_id: String) -> String:
    var score := int(GameState.reputation.get(faction_id, 0))
    if faction_id == "locals":
        for tier in LOCAL_STANDING_THRESHOLDS:
            if score >= int(tier["minimum"]):
                return str(tier["label"])
        return "UNWELCOME"
    if faction_id == "rivals":
        if score <= -25:
            return "HUNTED"
        if score < -10:
            return "WARY"
        if score < 10:
            return "NEUTRAL"
        if score < 30:
            return "CONNECTED"
        return "INSIDER"
    return "UNKNOWN"

func get_side_hustle_cash_bonus() -> int:
    var score := int(GameState.reputation.get("locals", 0))
    for tier in LOCAL_STANDING_THRESHOLDS:
        if score >= int(tier["minimum"]):
            return int(tier["cash_bonus"])
    return 0
