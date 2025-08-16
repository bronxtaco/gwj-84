extends Node2D

var first_time := true

func _ready() -> void:
	Events.menu_unpaused.connect(_on_menu_unpaused)
	%StandardButton.grab_focus()
	Audio.play_overworld()

func fade_buttons() -> void:
	create_tween().tween_property(%Buttons, "modulate:a", 0.0, 0.2)
	
func _on_menu_unpaused():
	%StandardButton.grab_focus()
	
func _on_standard_button_pressed() -> void:
	Audio.play_menu_select()
	fade_buttons()
	Global.reset_game()
	Global.game_active = true
	Audio.play_overworld()
	Scenes.change(Scenes.Enum.Overworld)


func _on_button_focus_entered() -> void:
	if !first_time:
		Audio.play_menu_scroll()
	first_time = false
