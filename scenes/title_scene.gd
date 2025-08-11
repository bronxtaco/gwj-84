extends Node2D

func _process(delta: float) -> void:
	if Input.is_action_just_pressed("ui_accept"):
		Events.change_scene.emit(load("res://scenes/overworld.tscn"))
