extends Node

enum Enum {
	Splash,
	Title,
	Overworld,
	Combat,
}

var scenes_preload = {
	Enum.Splash: preload("res://scenes/gjw_splash_scene.tscn"),
	Enum.Title: preload("res://scenes/title_scene.tscn"),
	Enum.Overworld: preload("res://scenes/overworld_scene.tscn"),
	Enum.Combat: preload("res://scenes/combat_scene.tscn"),
}

func change(scene: Enum):
	Events.change_scene.emit(scenes_preload[scene])
