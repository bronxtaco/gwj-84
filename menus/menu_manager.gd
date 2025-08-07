class_name MenuManager
extends Node2D

@onready var menus := {
	#Global.MENU_TYPE.PAUSE: preload("res://menus/pause_menu.tscn"),
	#Global.MENU_TYPE.SETTINGS: preload("res://menus/settings_menu.tscn"),
	#Global.MENU_TYPE.CREDITS: preload("res://menus/credits_menu.tscn"),
}

# ColorRect used for fading behind menus
@export var fade_rect: Node

# Node that contains the active scene for pausing and disabling input
@export var scene_container: Node

var menu_stack := []

func _ready():
	Events.menu_push.connect(_on_menu_push)
	Events.menu_pop.connect(_on_menu_pop)
	Events.menu_pop_all.connect(_on_menu_pop_all)


func _on_menu_push(menu_type: Global.MENU_TYPE, data: Dictionary = {}):
	var current_focus = get_viewport().gui_get_focus_owner()
	if current_focus:
		current_focus.release_focus()
	
	var menu = menus[menu_type].instantiate()
	menu.hide()
	menu.process_mode = PROCESS_MODE_DISABLED
	menu.setup_menu(data)
	add_child(menu)
	menu.global_position = Vector2(0, 180)
	menu.set_deferred("size", Vector2(320, 180))

	if menu_stack.is_empty():
		if menu.pause_game:
			Global.paused = true
			scene_container.process_mode = PROCESS_MODE_DISABLED
	else:
		menu_stack[-1].process_mode = PROCESS_MODE_DISABLED
		await tween_out_menu(menu_stack[-1]).finished
		menu_stack[-1].hide()
	
	menu_stack.append(menu)
	menu.show()
	
	await tween_in_menu(menu).finished
	menu.process_mode = PROCESS_MODE_INHERIT


func _on_menu_pop():
	if menu_stack.is_empty():
		return
	
	var menu = menu_stack.pop_back()
	menu.process_mode = PROCESS_MODE_DISABLED
	await tween_out_menu(menu).finished
	menu.queue_free()
	
	if menu_stack.is_empty():
		Global.paused = false
		scene_container.process_mode = PROCESS_MODE_INHERIT
		Events.menu_empty.emit()
		return

	menu_stack[-1].show()

	if menu_stack[-1].has_method("on_resume"):
		menu_stack[-1].on_resume()

	await tween_in_menu(menu_stack[-1]).finished
	menu_stack[-1].process_mode = PROCESS_MODE_INHERIT


func _on_menu_pop_all():
	Global.paused = false
	if menu_stack.is_empty():
		Events.menu_empty.emit()
		return
	
	# Tween out first menu normally
	var menu = menu_stack.pop_back()
	menu.process_mode = PROCESS_MODE_DISABLED
	await tween_out_menu(menu).finished
	menu.queue_free()
	
	while !menu_stack.is_empty():
		menu = menu_stack.pop_back()
		menu.queue_free()
	
	Events.menu_empty.emit()


func tween_in_menu(menu) -> Tween:
	var tween = create_tween()
	tween.set_parallel()
	tween.tween_property(fade_rect, "color:a", 0.8, 0.2)
	tween.tween_property(menu, "global_position", Vector2(menu.global_position.x, 0), 0.25).set_trans(Tween.TRANS_BACK)
	return tween


func tween_out_menu(menu) -> Tween:
	var tween = create_tween()
	tween.set_parallel()
	if menu_stack.is_empty():
		tween.tween_property(fade_rect, "color:a", 0, 0.2)
	tween.tween_property(menu, "global_position", Vector2(menu.global_position.x, 180), 0.0).set_trans(Tween.TRANS_BACK) 
	return tween
