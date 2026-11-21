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
        total_minutes += 1
        var day := int(total_minutes / 1440) + 1
        var minute_of_day := total_minutes % 1440
        GameState.current_day = day
        time_changed.emit(day, int(minute_of_day / 60), minute_of_day % 60)
        EventBus.world_time_advanced.emit(day, int(minute_of_day / 60), minute_of_day % 60)

func _sync_game_day() -> void:
    GameState.current_day = int(total_minutes / 1440) + 1
