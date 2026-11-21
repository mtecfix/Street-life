extends Node

func _ready() -> void:
    SaveManager.load_game()
    SceneManager.change_to("res://scenes/world/Neighborhood.tscn")
