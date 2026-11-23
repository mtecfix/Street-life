extends SceneTree

# Regression coverage for the inventory event contract.
# Run with Godot 4.3:
# godot --headless --path game --script res://tests/test_inventory_signals.gd

var _failures: Array[String] = []
var _signal_count := 0
var _last_item_id := ""
var _last_count := -1

func _initialize() -> void:
    call_deferred("_run")

func _run() -> void:
    GameState.inventory.clear()
    GameState.player_cash = 25
    GameState.player_health = 100
    EventBus.inventory_changed.connect(_on_inventory_changed)

    _check(GameState.add_item("snack", 2), "Adding valid items should succeed.")
    _check(_signal_count == 1, "Adding items should emit exactly one inventory signal.")
    _check(_last_item_id == "snack" and _last_count == 2, "Add signal should include the item ID and updated count.")

    _check(GameState.remove_item("snack", 1), "Removing an owned item should succeed.")
    _check(_signal_count == 2 and _last_count == 1, "Remove signal should report the remaining count.")

    _check(GameState.purchase_item("soda"), "A valid purchase should succeed.")
    _check(GameState.player_cash == 17, "A successful purchase should deduct its price.")
    _check(_signal_count == 3 and _last_item_id == "soda" and _last_count == 1, "Purchase should emit the inventory update through add_item.")

    GameState.player_health = 70
    _check(GameState.use_item("snack"), "A healing item should be usable when health is below maximum.")
    _check(GameState.player_health == 85, "Using a snack should restore its configured health amount.")
    _check(_signal_count == 4 and _last_item_id == "snack" and _last_count == 0, "Using the last item should emit a zero count.")

    var count_before_invalid := _signal_count
    _check(not GameState.add_item("not_a_real_item"), "Unknown item IDs should be rejected.")
    _check(not GameState.remove_item("medkit"), "Removing an item the player does not own should fail.")
    _check(_signal_count == count_before_invalid, "Rejected inventory operations must not emit change signals.")

    EventBus.inventory_changed.disconnect(_on_inventory_changed)
    if _failures.is_empty():
        print("PASS: inventory mutations emit accurate change signals.")
        quit(0)
    else:
        for failure in _failures:
            push_error(failure)
        quit(1)

func _on_inventory_changed(item_id: String, new_count: int) -> void:
    _signal_count += 1
    _last_item_id = item_id
    _last_count = new_count

func _check(condition: bool, message: String) -> void:
    if not condition:
        _failures.append(message)
