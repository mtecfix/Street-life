extends SceneTree

# Shop UI regression coverage for mouse/touch purchase controls and affordability.
# Run with Godot 4.3:
# godot --headless --path game --script res://tests/test_shop_checkout.gd

var _failures: Array[String] = []

func _initialize() -> void:
    call_deferred("_run")

func _run() -> void:
    GameState.inventory.clear()
    GameState.player_cash = 25
    var shop_scene: PackedScene = load("res://scenes/interiors/ShopInterior.tscn")
    var shop = shop_scene.instantiate()
    root.add_child(shop)
    await process_frame

    _check(shop.shop_buttons.size() == 3, "The checkout should expose all three defined products.")
    _check(not shop.shop_buttons["snack"].disabled, "A product should be enabled when affordable and bag space exists.")
    _check(shop.shop_buttons["medkit"].disabled, "A product should be disabled when the player cannot afford it.")

    shop.shop_buttons["snack"].pressed.emit()
    _check(GameState.player_cash == 20, "Buying a snack should deduct its listed price.")
    _check(int(GameState.inventory.get("snack", 0)) == 1, "Buying a snack should add one to the inventory.")
    _check(shop.shop_summary.text.contains("CASH  $20"), "Checkout summary should refresh after purchase.")

    GameState.player_cash = 0
    shop._refresh_shop_interface()
    _check(shop.shop_buttons["snack"].disabled, "Products should disable when cash is insufficient.")

    GameState.player_cash = 100
    GameState.inventory.clear()
    GameState.add_item("snack", GameState.INVENTORY_CAPACITY)
    shop._refresh_shop_interface()
    _check(shop.shop_buttons["snack"].disabled, "Products should disable when the bag is full.")
    var cash_before := GameState.player_cash
    shop._purchase("soda")
    _check(GameState.player_cash == cash_before, "A full-bag purchase attempt must not deduct cash.")

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
