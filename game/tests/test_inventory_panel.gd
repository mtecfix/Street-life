extends SceneTree

# Headless smoke coverage for the inventory panel's visibility and item actions.
# Run with Godot 4.3:
# godot --headless --path game --script res://tests/test_inventory_panel.gd

var _failures: Array[String] = []

func _initialize() -> void:
    call_deferred("_run")

func _run() -> void:
    # Autoloads are resolved from the tree at runtime. A script launched with
    # --script is compiled before autoloads are registered, so referring to
    # GameState by bare name fails with "Identifier not found".
    var state: Variant = root.get_node_or_null("GameState")
    if state == null:
        push_error("Inventory panel test could not find the GameState autoload.")
        quit(1)
        return

    state.inventory.clear()
    state.player_cash = 25
    state.player_health = 70
    state.add_item("snack", 1)

    var panel_script = load("res://scripts/ui/inventory_panel.gd")
    var inventory_panel = panel_script.new()
    root.add_child(inventory_panel)
    await process_frame

    _check(not inventory_panel.panel.visible, "Inventory panel should start closed.")
    inventory_panel.toggle()
    _check(inventory_panel.panel.visible, "Toggle should open the inventory panel.")
    _check(inventory_panel._item_labels.size() == state.ITEM_DEFINITIONS.size(), "Every defined item should have a visible row.")
    _check(not inventory_panel._use_buttons["snack"].disabled, "Owned healing items should be usable when health is below maximum.")
    _check(inventory_panel._use_buttons["medkit"].disabled, "Items with zero quantity should be disabled.")

    inventory_panel._use_item("snack")
    _check(state.player_health == 85, "Using a snack from the panel should restore health.")
    _check(state.get_inventory_count() == 0, "Using the snack should consume one inventory item.")
    _check(inventory_panel._use_buttons["snack"].disabled, "The use button should disable when quantity reaches zero.")

    state.player_health = 100
    inventory_panel.refresh()
    _check(inventory_panel._use_buttons["snack"].disabled, "Healing items should be disabled at full health.")

    root.remove_child(inventory_panel)
    inventory_panel.free()

    if _failures.is_empty():
        print("PASS: inventory panel visibility and item-use behavior.")
        quit(0)
    else:
        for failure in _failures:
            push_error(failure)
        quit(1)

func _check(condition: bool, message: String) -> void:
    if not condition:
        _failures.append(message)
