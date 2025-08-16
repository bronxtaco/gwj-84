extends BaseMenu

func _ready():
	var focus_nodes = [
		%MasterSlider,
		%MusicSlider,
		%SfxSlider,
	]

	default_focused_node = focus_nodes[0]
	connect_vertical_nodes(focus_nodes)
	connect_default_signals(focus_nodes)
	grab_focus_(default_focused_node, true)


func _on_master_slider_value_changed(value: float) -> void:
	AudioServer.set_bus_volume_db(AudioServer.get_bus_index("Master"), linear_to_db(value))


func _on_music_slider_value_changed(value: float) -> void:
	AudioServer.set_bus_volume_db(AudioServer.get_bus_index("Music"), linear_to_db(value))


func _on_sfx_slider_value_changed(value: float) -> void:
	AudioServer.set_bus_volume_db(AudioServer.get_bus_index("SFX"), linear_to_db(value))
