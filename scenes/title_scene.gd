extends Node2D

func _process(_delta: float) -> void:
	if Input.is_action_just_pressed("ui_accept"):
		Global.reset_game()
		Global.game_active = true
		Audio.play_overworld()
		Scenes.change(Scenes.Enum.Overworld)
