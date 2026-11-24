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
    # Autoloads are resolved from the tree at runtime. A script launched with
    # --script is compiled before autoloads are registered, so referring to
    # GameState / EventBus by bare name fails with "Identifier not found".
    var state: Variant = root.get_node_or_null("GameState")
    var bus: Variant = root.get_node_or_null("EventBus")
    if state == null or bus == null:
        push_error("Inventory signal test could not find required autoloads.")
        quit(1)
        return

    state.inventory.clear()
    state.player_cash = 25
    state.player_health = 100
    bus.inventory_changed.connect(_on_inventory_changed)

    _check(state.add_item("snack", 2), "Adding valid items should succeed.")
    _check(_signal_count == 1, "Adding items should emit exactly one inventory signal.")
    _check(_last_item_id == "snack" and _last_count == 2, "Add signal should include the item ID and updated count.")

    _check(state.remove_item("snack", 1), "Removing an owned item should succeed.")
    _check(_signal_count == 2 and _last_count == 1, "Remove signal should report the remaining count.")

    _check(state.purchase_item("soda"), "A valid purchase should succeed.")
    _check(state.player_cash == 17, "A successful purchase should deduct its price.")
    _check(_signal_count == 3 and _last_item_id == "soda" and _last_count == 1, "Purchase should emit the inventory update through add_item.")

    state.player_health = 70
    _check(state.use_item("snack"), "A healing item should be usable when health is below maximum.")
    _check(state.player_health == 85, "Using a snack should restore its configured health amount.")
    _check(_signal_count == 4 and _last_item_id == "snack" and _last_count == 0, "Using the last item should emit a zero count.")

    var count_before_invalid := _signal_count
    _check(not state.add_item("not_a_real_item"), "Unknown item IDs should be rejected.")
    _check(not state.remove_item("medkit"), "Removing an item the player does not own should fail.")
    _check(_signal_count == count_before_invalid, "Rejected inventory operations must not emit change signals.")

    # Capacity rejection must be atomic: no cash deduction and no signal.
    state.inventory.clear()
    _signal_count = 0
    _check(state.add_item("snack", state.INVENTORY_CAPACITY), "A full inventory can be populated up to its cap.")
    var cash_before_full_bag_purchase: int = state.player_cash
    var signals_before_full_bag_purchase := _signal_count
    _check(not state.purchase_item("soda"), "Purchases should fail when the bag is full.")
    _check(state.player_cash == cash_before_full_bag_purchase, "A rejected full-bag purchase must not deduct cash.")
    _check(_signal_count == signals_before_full_bag_purchase, "A rejected full-bag purchase must not emit an inventory signal.")

    bus.inventory_changed.disconnect(_on_inventory_changed)
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
