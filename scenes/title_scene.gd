extends Node2D

var game_scene = preload("res://scenes/game_scene.tscn")

func _process(delta: float) -> void:
	if Input.is_action_just_pressed("ui_accept"):
		Events.change_scene.emit(game_scene)
