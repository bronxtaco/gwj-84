extends BaseMenu

var focused_node

func _ready():
	default_focused_node = %SettingsButton
	Audio.play_menu_pause()


func _on_settings_button_pressed():
	Audio.play_menu_select()
	focused_node = get_viewport().gui_get_focus_owner()
	Events.menu_push.emit(Global.MENU_TYPE.SETTINGS)


func _on_credits_button_pressed():
	Audio.play_menu_select()
	focused_node = get_viewport().gui_get_focus_owner()
	Events.menu_push.emit(Global.MENU_TYPE.CREDITS)
