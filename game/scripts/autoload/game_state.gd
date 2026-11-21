extends Node

const BUILD_MILESTONE := "Sprint 4 — Vertical Slice"

const INVENTORY_CAPACITY := 20
const ITEM_DEFINITIONS := {
    "snack": {"name": "Corner-store snack", "price": 5, "heal": 15, "description": "A quick bite. Restores 15 health."},
    "medkit": {"name": "First-aid kit", "price": 18, "heal": 45, "description": "Restores 45 health."},
    "soda": {"name": "Energy soda", "price": 8, "heal": 5, "description": "A small pick-me-up. Restores 5 health."}
}

var player_cash: int = 25
var player_health: int = 100
var encounters_won: int = 0
var previous_world_position: Vector2 = Vector2(480, 270)
var current_day: int = 1
var mission_active: bool = false
var mission_completed: bool = false
var mission_reward: int = 50
var mission_choice: String = ""
var mission_outcome: String = ""
var current_encounter_id: String = "corner_brawler"
var last_combat_won: bool = false
var inventory: Dictionary = {}
var reputation: Dictionary = {"locals": 0, "rivals": 0}
var npc_relationships: Dictionary = {}
var world_flags: Dictionary = {}

func add_item(item_id: String, amount: int = 1) -> bool:
    if not ITEM_DEFINITIONS.has(item_id) or amount <= 0:
        return false
    if get_inventory_count() + amount > INVENTORY_CAPACITY:
        return false
    inventory[item_id] = int(inventory.get(item_id, 0)) + amount
    return true

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

func purchase_item(item_id: String) -> bool:
    if not ITEM_DEFINITIONS.has(item_id):
        return false
    var item: Dictionary = ITEM_DEFINITIONS[item_id]
    var price := int(item["price"])
    if player_cash < price or get_inventory_count() >= INVENTORY_CAPACITY:
        return false
    player_cash -= price
    return add_item(item_id, 1)

func use_item(item_id: String) -> bool:
    if not ITEM_DEFINITIONS.has(item_id):
        return false
    var item: Dictionary = ITEM_DEFINITIONS[item_id]
    if int(item["heal"]) <= 0 or player_health >= 100 or not remove_item(item_id, 1):
        return false
    player_health = mini(100, player_health + int(item["heal"]))
    return true

func adjust_reputation(faction_id: String, amount: int) -> void:
    reputation[faction_id] = clampi(int(reputation.get(faction_id, 0)) + amount, -100, 100)
    EventBus.reputation_changed.emit(faction_id, int(reputation[faction_id]))

func adjust_relationship(npc_id: String, amount: int) -> void:
    npc_relationships[npc_id] = clampi(int(npc_relationships.get(npc_id, 0)) + amount, -100, 100)
