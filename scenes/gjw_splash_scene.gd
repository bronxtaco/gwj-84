extends Node2D

func _ready() -> void:
	await get_tree().create_timer(1.0).timeout
	Scenes.change(Scenes.Enum.Title)
