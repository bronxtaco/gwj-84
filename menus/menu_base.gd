class_name BaseMenu
extends MarginContainer

@export var pause_game := true
@export var disable_input := true
@export var dismissable := true

var _dismissed := false
var _first_ignored := false
var default_focused_node

func _on_dismiss():
	pass

func setup_menu(_data: Dictionary):
	pass

func _process(_delta):
	if _dismissed:
		return

	reset_default_focused_node()

	if dismissable and Input.is_action_just_pressed("ui_cancel"):
		Audio.play_menu_back()
		Events.menu_pop.emit()
		_on_dismiss()


func connect_vertical_nodes(nodes):
	if nodes.size() <= 1:
		return

	var idx := 0
	for node in nodes:
		node.focus_neighbor_top = nodes[wrap(idx - 1, 0, nodes.size())].get_path()
		node.focus_neighbor_bottom = nodes[wrap(idx + 1, 0, nodes.size())].get_path()
		idx += 1


func connect_horizontal_nodes(nodes):
	if nodes.size() <= 1:
		return

	var idx := 0
	for node in nodes:
		node.focus_neighbor_left = nodes[wrap(idx - 1, 0, nodes.size())].get_path()
		node.focus_neighbor_right = nodes[wrap(idx + 1, 0, nodes.size())].get_path()
		idx += 1

func connect_default_signals(nodes):
	for node in nodes:
		node.focus_entered.connect(default_focus_entered.bind(node))
		node.mouse_entered.connect(default_mouse_entered.bind(node))


func default_focus_entered(_node):
	if !_first_ignored:
		_first_ignored = true
		return
	
	Audio.play_menu_scroll()


func default_mouse_entered(node):
	node.grab_focus()


func reset_default_focused_node():
	if !default_focused_node:
		return

	var current_focus = get_viewport().gui_get_focus_owner()
	if current_focus == null:
		grab_focus_(default_focused_node, true)

func grab_focus_(node, silent=false):
	if silent:
		_first_ignored = false
	node.grab_focus()
	if silent:
		_first_ignored = true
