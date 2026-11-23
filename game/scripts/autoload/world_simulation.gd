extends Node

## Time-driven city simulation. Residents and business activity advance from the
## world clock, independent of which gameplay scene is currently loaded.
signal neighborhood_activity_changed(activity_level: int)

const RESIDENTS := {
    "rico": {"home": Vector2(590, 270), "routine": [
        {"start": 480, "end": 720, "from": Vector2(590, 270), "to": Vector2(300, 220), "activity": "Working the corner"},
        {"start": 720, "end": 1020, "from": Vector2(300, 220), "to": Vector2(590, 270), "activity": "Making rounds"},
        {"start": 1020, "end": 1320, "from": Vector2(590, 270), "to": Vector2(700, 370), "activity": "At the court"}
    ]},
    "maya": {"home": Vector2(565, 390), "routine": [
        {"start": 360, "end": 540, "from": Vector2(565, 390), "to": Vector2(170, 174), "activity": "Opening the market"},
        {"start": 540, "end": 1020, "from": Vector2(170, 174), "to": Vector2(170, 174), "activity": "Running the market"},
        {"start": 1020, "end": 1200, "from": Vector2(170, 174), "to": Vector2(565, 390), "activity": "Heading home"}
    ]},
    "dre": {"home": Vector2(700, 370), "routine": [
        {"start": 840, "end": 1080, "from": Vector2(700, 370), "to": Vector2(825, 350), "activity": "At the court"},
        {"start": 1080, "end": 1380, "from": Vector2(825, 350), "to": Vector2(700, 370), "activity": "Hanging on the block"}
    ]},
    "nia": {"home": Vector2(320, 390), "routine": [
        {"start": 420, "end": 600, "from": Vector2(320, 390), "to": Vector2(170, 174), "activity": "Picking up deliveries"},
        {"start": 600, "end": 960, "from": Vector2(170, 174), "to": Vector2(300, 220), "activity": "Running deliveries"},
        {"start": 960, "end": 1140, "from": Vector2(300, 220), "to": Vector2(320, 390), "activity": "Wrapping up routes"}
    ]},
    "coach": {"home": Vector2(825, 350), "routine": [
        {"start": 360, "end": 660, "from": Vector2(825, 350), "to": Vector2(700, 370), "activity": "Coaching at the court"},
        {"start": 960, "end": 1200, "from": Vector2(700, 370), "to": Vector2(825, 350), "activity": "Evening training"}
    ]}
}

const BUSINESSES := {
    "mayas_market": {"open": 360, "close": 1260}
}

var _last_activity_level := -1

func _ready() -> void:
    EventBus.world_time_advanced.connect(_on_world_time_advanced)
    _refresh_business_simulation()

func get_resident_snapshot(resident_id: String) -> Dictionary:
    if not RESIDENTS.has(resident_id):
        return {}
    var profile: Dictionary = RESIDENTS[resident_id]
    var minute_of_day := WorldClock.total_minutes % 1440
    for segment in profile["routine"]:
        var start := int(segment["start"])
        var finish := int(segment["end"])
        if minute_of_day >= start and minute_of_day < finish:
            var progress := float(minute_of_day - start) / float(maxi(1, finish - start))
            var origin: Vector2 = segment["from"]
            var destination: Vector2 = segment["to"]
            return {"active": true, "position": origin.lerp(destination, progress), "activity": str(segment["activity"]), "progress": progress}
    return {"active": false, "position": profile["home"], "activity": "At home", "progress": 0.0}

func get_business_snapshot(business_id: String) -> Dictionary:
    if not BUSINESSES.has(business_id):
        return {}
    var business: Dictionary = BUSINESSES[business_id]
    var minute_of_day := WorldClock.total_minutes % 1440
    var state: Dictionary = GameState.world_flags.get("city_simulation", {}).get(business_id, {})
    return {
        "open": minute_of_day >= int(business["open"]) and minute_of_day < int(business["close"]),
        "customers_today": int(state.get("customers_today", 0)),
        "last_simulated_hour": int(state.get("last_simulated_hour", -1))
    }

func get_city_activity_level() -> int:
    var hour := WorldClock.get_hour()
    if hour >= 16 and hour < 21:
        return 4
    if hour >= 7 and hour < 10:
        return 3
    if hour >= 10 and hour < 16:
        return 2
    if hour >= 21 or hour < 5:
        return 1
    return 2

func _on_world_time_advanced(_day: int, _hour: int, _minute: int) -> void:
    _refresh_business_simulation()

func _refresh_business_simulation() -> void:
    var city_state: Dictionary = GameState.world_flags.get("city_simulation", {}).duplicate(true)
    var business_state: Dictionary = city_state.get("mayas_market", {})
    var current_day := GameState.current_day
    var current_hour_stamp := int(WorldClock.total_minutes / 60)
    var stored_day := int(business_state.get("day", current_day))
    var last_hour := int(business_state.get("last_simulated_hour", -1))
    if stored_day != current_day:
        business_state = {"day": current_day, "customers_today": 0, "last_simulated_hour": -1}
        last_hour = -1
    if last_hour < 0:
        last_hour = current_hour_stamp - 1
    for hour_stamp in range(last_hour + 1, current_hour_stamp + 1):
        var hour_of_day := hour_stamp % 24
        if hour_of_day >= 6 and hour_of_day < 21:
            var hourly_customers := 4 if hour_of_day >= 16 and hour_of_day < 20 else (2 if hour_of_day >= 7 and hour_of_day < 10 else 1)
            business_state["customers_today"] = int(business_state.get("customers_today", 0)) + hourly_customers
    business_state["day"] = current_day
    business_state["last_simulated_hour"] = current_hour_stamp
    city_state["mayas_market"] = business_state
    GameState.world_flags["city_simulation"] = city_state
    var activity := get_city_activity_level()
    if activity != _last_activity_level:
        _last_activity_level = activity
        neighborhood_activity_changed.emit(activity)
