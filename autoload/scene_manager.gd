extends Node

enum Enum {
	Splash,
	Title,
	Overworld,
	Combat,
}

var current_scene: Enum = Enum.Splash

var scenes_preload = {
	Enum.Splash: preload("res://scenes/gjw_splash_scene.tscn"),
	Enum.Title: preload("res://scenes/title_scene.tscn"),
	Enum.Overworld: preload("res://scenes/overworld_scene.tscn"),
	Enum.Combat: preload("res://scenes/combat_scene.tscn"),
}

func is_pause_enabled():
	return current_scene != Enum.Splash
	
func is_hud_enabled(scene_enum: Enum):
	match(scene_enum):
		Enum.Splash, Enum.Title:
			return false
		Enum.Overworld, Enum.Combat:
			return true

func change(scene: Enum):
	Events.menu_disable.emit()
	Global.hud_enabled = is_hud_enabled(scene)
	Events.change_scene.emit(scenes_preload[scene])
	current_scene = scene

func is_current_scene_gameplay() -> bool:
	return current_scene == Enum.Overworld or current_scene == Enum.Combat
