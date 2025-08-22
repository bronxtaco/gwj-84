extends BaseMenu

func _ready():
	var focus_nodes = [
		%YesButton,
		%NoButton,
	]

	default_focused_node = focus_nodes[1]
	connect_horizontal_nodes(focus_nodes)
	connect_default_signals(focus_nodes)
	grab_focus_(default_focused_node, true)


func _on_yes_button_pressed() -> void:
	Scenes.change(Scenes.Enum.Title)
	Events.menu_pop_all.emit()


func _on_no_button_pressed() -> void:
	Events.menu_pop.emit()
