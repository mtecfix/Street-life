extends Node

func _ready() -> void:
    SaveManager.load_game()
    # SceneManager defers the swap itself, so the boot scene is not removed
    # while the tree is still finishing its own setup.
    SceneManager.change_to("res://scenes/world/Neighborhood.tscn")
