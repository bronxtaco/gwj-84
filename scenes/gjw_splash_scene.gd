extends Node2D

func _ready() -> void:
	await get_tree().create_timer(1.5).timeout
	Scenes.change(Scenes.Enum.Title)
