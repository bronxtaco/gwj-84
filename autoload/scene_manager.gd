extends Node

enum Enum {
	Title,
	Overworld,
	Combat,
}

var scenes_preload = {
	Enum.Title: preload("res://scenes/title_scene.tscn"),
	Enum.Overworld: preload("res://scenes/overworld_scene.tscn"),
	Enum.Combat: preload("res://scenes/combat_scene.tscn"),
}

func change(scene: Enum):
	Events.change_scene.emit(scenes_preload[scene])
