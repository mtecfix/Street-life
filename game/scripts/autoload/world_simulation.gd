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


## Ambient residents are lightweight background agents. Their positions are a
## pure function of world time, so they remain consistent across scene changes.
const AMBIENT_PEDESTRIANS := [
    {"id": "walker_01", "sprite": 1, "start": 420, "end": 1260, "from": Vector2(40, 260), "to": Vector2(330, 260), "phase": 0.08},
    {"id": "walker_02", "sprite": 3, "start": 420, "end": 1260, "from": Vector2(330, 285), "to": Vector2(40, 285), "phase": 0.34},
    {"id": "walker_03", "sprite": 2, "start": 480, "end": 1200, "from": Vector2(535, 250), "to": Vector2(920, 250), "phase": 0.16},
    {"id": "walker_04", "sprite": 4, "start": 480, "end": 1200, "from": Vector2(920, 300), "to": Vector2(535, 300), "phase": 0.52},
    {"id": "walker_05", "sprite": 0, "start": 600, "end": 1320, "from": Vector2(380, 365), "to": Vector2(610, 365), "phase": 0.22},
    {"id": "walker_06", "sprite": 2, "start": 600, "end": 1320, "from": Vector2(610, 390), "to": Vector2(380, 390), "phase": 0.68},
    {"id": "walker_07", "sprite": 3, "start": 900, "end": 1380, "from": Vector2(60, 180), "to": Vector2(330, 180), "phase": 0.41},
    {"id": "walker_08", "sprite": 1, "start": 900, "end": 1380, "from": Vector2(900, 350), "to": Vector2(540, 350), "phase": 0.76}
]

func get_ambient_pedestrians() -> Array[Dictionary]:
    var pedestrians: Array[Dictionary] = []
    var minute_of_day := WorldClock.total_minutes % 1440
    for profile in AMBIENT_PEDESTRIANS:
        var start := int(profile["start"])
        var finish := int(profile["end"])
        if minute_of_day < start or minute_of_day >= finish:
            continue
        var duration := float(finish - start)
        var progress := fposmod((float(minute_of_day - start) / duration) + float(profile["phase"]), 1.0)
        var origin: Vector2 = profile["from"]
        var destination: Vector2 = profile["to"]
        pedestrians.append({
            "id": str(profile["id"]),
            "sprite": int(profile["sprite"]),
            "position": origin.lerp(destination, progress)
        })
    return pedestrians


## Lightweight traffic agents advance continuously in this autoload, including
## while the neighborhood scene is not loaded. Positions are reconstructed from
## elapsed simulation time, so scene reloads do not reset vehicle movement.
const TRAFFIC_VEHICLES := [
    {"id": "cab_east", "axis": "horizontal", "lane": 225.0, "start": -80.0, "speed": 46.0, "length": 31.0, "color": Color("#d8b23e"), "active_start": 360, "active_end": 1380},
    {"id": "sedan_west", "axis": "horizontal", "lane": 315.0, "start": 1020.0, "speed": -39.0, "length": 29.0, "color": Color("#477c9b"), "active_start": 360, "active_end": 1380},
    {"id": "delivery_east", "axis": "horizontal", "lane": 245.0, "start": -420.0, "speed": 34.0, "length": 38.0, "color": Color("#a9a69a"), "active_start": 420, "active_end": 1260},
    {"id": "van_west", "axis": "horizontal", "lane": 295.0, "start": 1280.0, "speed": -31.0, "length": 40.0, "color": Color("#6d8a68"), "active_start": 420, "active_end": 1260},
    {"id": "compact_south", "axis": "vertical", "lane": 385.0, "start": -180.0, "speed": 35.0, "length": 28.0, "color": Color("#9b6470"), "active_start": 420, "active_end": 1320},
    {"id": "taxi_north", "axis": "vertical", "lane": 485.0, "start": 760.0, "speed": -43.0, "length": 31.0, "color": Color("#d8b23e"), "active_start": 420, "active_end": 1320}
]

var _traffic_elapsed_seconds := 0.0

func get_traffic_signal_state() -> String:
    var phase := fposmod(_traffic_elapsed_seconds, 24.0)
    return "horizontal" if phase < 13.0 else "vertical"

func get_traffic_snapshot() -> Array[Dictionary]:
    var vehicles: Array[Dictionary] = []
    var minute_of_day := WorldClock.total_minutes % 1440
    var signal_state := get_traffic_signal_state()
    for profile in TRAFFIC_VEHICLES:
        if minute_of_day < int(profile["active_start"]) or minute_of_day >= int(profile["active_end"]):
            continue
        var axis := str(profile["axis"])
        var lane := float(profile["lane"])
        var speed := float(profile["speed"])
        var start := float(profile["start"])
        var position: Vector2
        var stopped := false
        if axis == "horizontal":
            var x := fposmod(start + speed * _traffic_elapsed_seconds + 80.0, 1120.0) - 80.0
            var approaches_intersection := (speed > 0.0 and x >= 397.0) or (speed < 0.0 and x <= 473.0)
            stopped = approaches_intersection and signal_state != "horizontal"
            if stopped:
                x = 397.0 if speed > 0.0 else 473.0
            position = Vector2(x, lane)
        else:
            var y := fposmod(start + speed * _traffic_elapsed_seconds + 80.0, 700.0) - 80.0
            var approaches_intersection := (speed > 0.0 and y >= 232.0) or (speed < 0.0 and y <= 308.0)
            stopped = approaches_intersection and signal_state != "vertical"
            if stopped:
                y = 232.0 if speed > 0.0 else 308.0
            position = Vector2(lane, y)
        vehicles.append({
            "id": str(profile["id"]),
            "position": position,
            "axis": axis,
            "length": float(profile["length"]),
            "color": profile["color"],
            "stopped": stopped
        })
    return vehicles

var _last_activity_level := -1

func _ready() -> void:
    EventBus.world_time_advanced.connect(_on_world_time_advanced)
    _refresh_business_simulation()

func _process(delta: float) -> void:
    _traffic_elapsed_seconds += delta

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
