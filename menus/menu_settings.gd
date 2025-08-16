extends BaseMenu

func _ready():
	var focus_nodes = [
		%AudioButton,
	]

	default_focused_node = focus_nodes[0]
	connect_vertical_nodes(focus_nodes)
	connect_default_signals(focus_nodes)
	grab_focus_(default_focused_node, true)

func _on_audio_button_pressed() -> void:
	Audio.play_menu_select()
	Events.menu_push.emit(Global.MENU_TYPE.AUDIO)
