extends Node
@warning_ignore_start("unused_signal")

signal change_scene(new_scene:PackedScene)

signal menu_push(menu: Global.MENU_TYPE, data: Dictionary)
signal menu_pop
signal menu_pop_all
signal menu_empty
