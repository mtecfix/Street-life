extends Node

var player_cash: int = 25
var player_health: int = 100
var encounters_won: int = 0
var previous_world_position: Vector2 = Vector2(480, 270)
var current_day: int = 1

# First-mission progression.
var mission_active: bool = false
var mission_completed: bool = false
var mission_reward: int = 50
var last_combat_won: bool = false
