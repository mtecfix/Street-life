extends Node

const BUILD_MILESTONE := "Sprint 5 — Player Progression & Training"

const INVENTORY_CAPACITY := 20
const ITEM_DEFINITIONS := {
    "snack": {"name": "Corner-store snack", "price": 5, "heal": 15, "description": "A quick bite. Restores 15 health."},
    "medkit": {"name": "First-aid kit", "price": 18, "heal": 45, "description": "Restores 45 health."},
    "soda": {"name": "Energy soda", "price": 8, "heal": 5, "description": "A small pick-me-up. Restores 5 health."}
}

var player_cash: int = 25
var player_health: int = 100
var encounters_won: int = 0
var player_xp: int = 0
var player_level: int = 1
var skill_points: int = 0
var skill_levels: Dictionary = {"power": 0, "endurance": 0, "footwork": 0}
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
    # Inventory listeners (HUD, shop UI, future equipment screens) receive the
    # authoritative post-change count; callers never need to maintain a copy.
    EventBus.inventory_changed.emit(item_id, int(inventory[item_id]))
    return true

func remove_item(item_id: String, amount: int = 1) -> bool:
    if amount <= 0 or int(inventory.get(item_id, 0)) < amount:
        return false
    var remaining := int(inventory[item_id]) - amount
    if remaining == 0:
        inventory.erase(item_id)
    else:
        inventory[item_id] = remaining
    # Emit zero when the last copy is removed so UI can clear stale entries.
    EventBus.inventory_changed.emit(item_id, remaining)
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


func xp_required_for_next_level() -> int:
    return 100 + (player_level - 1) * 50

func award_experience(amount: int) -> int:
    if amount <= 0:
        return 0
    player_xp += amount
    var levels_gained := 0
    while player_xp >= xp_required_for_next_level():
        player_xp -= xp_required_for_next_level()
        player_level += 1
        skill_points += 1
        levels_gained += 1
    EventBus.progression_changed.emit(player_level, player_xp, skill_points)
    return levels_gained

func train_skill(skill_id: String) -> bool:
    if not skill_levels.has(skill_id) or skill_points <= 0:
        return false
    if int(skill_levels[skill_id]) >= 3:
        return false
    skill_levels[skill_id] = int(skill_levels[skill_id]) + 1
    skill_points -= 1
    EventBus.progression_changed.emit(player_level, player_xp, skill_points)
    return true

func get_attack_damage() -> int:
    return 25 + int(skill_levels.get("power", 0)) * 5

func get_max_stamina() -> float:
    return 100.0 + float(skill_levels.get("endurance", 0)) * 15.0

func get_stamina_regen() -> float:
    return 14.0 + float(skill_levels.get("endurance", 0)) * 2.0

func get_dodge_cost() -> float:
    return maxf(18.0, 30.0 - float(skill_levels.get("footwork", 0)) * 4.0)

func get_player_speed() -> float:
    return 225.0 + float(skill_levels.get("footwork", 0)) * 12.0
