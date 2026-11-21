extends Node

signal time_changed(day: int, hour: int, minute: int)

@export var game_minutes_per_real_second: float = 1.0
var total_minutes: int = 8 * 60
var _accumulator: float = 0.0

func _ready() -> void:
    _sync_game_day()

func _process(delta: float) -> void:
    _accumulator += delta * game_minutes_per_real_second
    while _accumulator >= 1.0:
        _accumulator -= 1.0
        advance_minutes(1)

func advance_minutes(amount: int) -> void:
    if amount <= 0:
        return
    var previous_day := int(total_minutes / 1440) + 1
    total_minutes += amount
    _sync_game_day()
    var minute_of_day := total_minutes % 1440
    var hour := int(minute_of_day / 60)
    var minute := minute_of_day % 60
    time_changed.emit(GameState.current_day, hour, minute)
    EventBus.world_time_advanced.emit(GameState.current_day, hour, minute)
    if GameState.current_day != previous_day:
        EventBus.new_day_started.emit(GameState.current_day)

func get_hour() -> int:
    return int((total_minutes % 1440) / 60)

func get_minute() -> int:
    return total_minutes % 60

func get_time_string() -> String:
    var hour := get_hour()
    var suffix := "AM" if hour < 12 else "PM"
    var display_hour := hour % 12
    if display_hour == 0:
        display_hour = 12
    return "%d:%02d %s" % [display_hour, get_minute(), suffix]

func _sync_game_day() -> void:
    GameState.current_day = int(total_minutes / 1440) + 1
