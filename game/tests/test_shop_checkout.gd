extends SceneTree

# Shop UI regression coverage for mouse/touch purchase controls and affordability.
# Run with Godot 4.3:
# godot --headless --path game --script res://tests/test_shop_checkout.gd

var _failures: Array[String] = []

func _initialize() -> void:
    call_deferred("_run")

func _run() -> void:
    # Autoloads are resolved from the tree at runtime. A script launched with
    # --script is compiled before autoloads are registered, so referring to
    # GameState by bare name fails with "Identifier not found".
    var state: Variant = root.get_node_or_null("GameState")
    if state == null:
        push_error("Shop checkout test could not find the GameState autoload.")
        quit(1)
        return

    state.inventory.clear()
    # $12 covers the $5 snack and $8 soda but not the $18 medkit, so the
    # affordability assertions below exercise both enabled and disabled.
    state.player_cash = 12
    var shop_scene: PackedScene = load("res://scenes/interiors/ShopInterior.tscn")
    var shop = shop_scene.instantiate()
    root.add_child(shop)
    await process_frame

    _check(shop.shop_buttons.size() == 3, "The checkout should expose all three defined products.")
    _check(not shop.shop_buttons["snack"].disabled, "A product should be enabled when affordable and bag space exists.")
    _check(shop.shop_buttons["medkit"].disabled, "A product should be disabled when the player cannot afford it.")

    shop.shop_buttons["snack"].pressed.emit()
    _check(state.player_cash == 7, "Buying a snack should deduct its listed price.")
    _check(int(state.inventory.get("snack", 0)) == 1, "Buying a snack should add one to the inventory.")
    _check(shop.shop_summary.text.contains("CASH  $7"), "Checkout summary should refresh after purchase.")

    state.player_cash = 0
    shop._refresh_shop_interface()
    _check(shop.shop_buttons["snack"].disabled, "Products should disable when cash is insufficient.")

    state.player_cash = 100
    state.inventory.clear()
    state.add_item("snack", state.INVENTORY_CAPACITY)
    shop._refresh_shop_interface()
    _check(shop.shop_buttons["snack"].disabled, "Products should disable when the bag is full.")
    var cash_before: int = state.player_cash
    shop._purchase("soda")
    _check(state.player_cash == cash_before, "A full-bag purchase attempt must not deduct cash.")

    root.remove_child(shop)
    shop.free()
    if _failures.is_empty():
        print("PASS: shop checkout controls, purchases, and rejection states.")
        quit(0)
    else:
        for failure in _failures:
            push_error(failure)
        quit(1)

func _check(condition: bool, message: String) -> void:
    if not condition:
        _failures.append(message)
