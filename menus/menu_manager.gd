class_name MenuManager
extends Node2D

@onready var menus := {
	Global.MENU_TYPE.PAUSE: preload("res://menus/menu_pause.tscn"),
	Global.MENU_TYPE.SETTINGS: preload("res://menus/menu_settings.tscn"),
	Global.MENU_TYPE.AUDIO: preload("res://menus/menu_audio.tscn"),
	Global.MENU_TYPE.CREDITS: preload("res://menus/menu_credits.tscn"),
	Global.MENU_TYPE.QUIT_CONFIRM: preload("res://menus/menu_quit.tscn"),
	Global.MENU_TYPE.RELIC_PICKUP: preload("res://menus/relic_pickup_notification.tscn"),
	Global.MENU_TYPE.DEBUG_RELIC: preload("res://menus/menu_debug_relic.tscn"),
}

# ColorRect used for fading behind menus
@export var fade_rect: Node

# Node that contains the active scene for pausing and disabling input
@export var scene_container: Node

var menus_enabled := false
var menu_stack := []

func _ready():
	Events.menu_push.connect(_on_menu_push)
	Events.menu_pop.connect(_on_menu_pop)
	Events.menu_pop_all.connect(_on_menu_pop_all)
	Events.menu_enable.connect(_on_menu_enable)
	Events.menu_disable.connect(_on_menu_disable)


func _on_menu_enable():
	menus_enabled = true

func _on_menu_disable():
	_on_menu_pop_all()
	menus_enabled = false
	
	
func _on_menu_push(menu_type: Global.MENU_TYPE, data: Dictionary = {}):
	if !menus_enabled:
		return
		
	var current_focus = get_viewport().gui_get_focus_owner()
	if current_focus:
		current_focus.release_focus()
	
	var menu = menus[menu_type].instantiate()
	menu.hide()
	menu.process_mode = PROCESS_MODE_DISABLED
	menu.setup_menu(data)
	add_child(menu)
	menu.global_position = Vector2(0, get_viewport().get_visible_rect().size.y)
	menu.set_deferred("size", get_viewport().get_visible_rect().size)

	if menu_stack.is_empty():
		if menu.pause_game:
			Global.paused = true
			var pause_deferred = func():
				scene_container.process_mode = PROCESS_MODE_DISABLED
			pause_deferred.call_deferred()
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
	tween.tween_property(fade_rect, "color:a", 0.8, 0.3)
	tween.tween_property(menu, "global_position", Vector2(menu.global_position.x, 0), 0.25).set_trans(Tween.TRANS_QUAD)
	return tween


func tween_out_menu(menu) -> Tween:
	var tween = create_tween()
	tween.set_parallel()
	if menu_stack.is_empty():
		tween.tween_property(fade_rect, "color:a", 0, 0.3)
	tween.tween_property(menu, "global_position", Vector2(menu.global_position.x, get_viewport().get_visible_rect().size.y), 0.25).set_trans(Tween.TRANS_QUAD) 
	return tween
