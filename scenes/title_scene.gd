extends Node2D

func _ready() -> void:
	%StandardButton.grab_focus()

func fade_buttons() -> void:
	create_tween().tween_property(%Buttons, "modulate:a", 0.0, 0.2)
	
	
func _on_standard_button_pressed() -> void:
	fade_buttons()
	Global.reset_game()
	Global.game_active = true
	Audio.play_overworld()
	Scenes.change(Scenes.Enum.Overworld)
