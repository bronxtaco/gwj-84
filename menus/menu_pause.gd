extends BaseMenu

func _ready():
	var focus_nodes = [
		%SettingsButton,
		%CreditsButton,
	]

	default_focused_node = focus_nodes[0]
	connect_vertical_nodes(focus_nodes)
	connect_default_signals(focus_nodes)
	grab_focus_(default_focused_node, true)
	Audio.play_menu_pause()


func _on_settings_button_pressed():
	Audio.play_menu_select()
	Events.menu_push.emit(Global.MENU_TYPE.SETTINGS)


func _on_credits_button_pressed():
	Audio.play_menu_select()
	Events.menu_push.emit(Global.MENU_TYPE.CREDITS)
