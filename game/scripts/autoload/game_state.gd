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

# Inventory stores item IDs mapped to stack counts.
var inventory: Dictionary = {}

func add_item(item_id: String, amount: int = 1) -> void:
    if item_id.is_empty() or amount <= 0:
        return
    inventory[item_id] = int(inventory.get(item_id, 0)) + amount

func remove_item(item_id: String, amount: int = 1) -> bool:
    if amount <= 0 or int(inventory.get(item_id, 0)) < amount:
        return false
    var remaining := int(inventory[item_id]) - amount
    if remaining == 0:
        inventory.erase(item_id)
    else:
        inventory[item_id] = remaining
    return true

func get_inventory_count() -> int:
    var total := 0
    for amount in inventory.values():
        total += int(amount)
    return total
