extends Node2D

const CUTSCENE_TIME := 3.0

var remaining_time := CUTSCENE_TIME
var active_path: PathFollow2D

func _ready() -> void:
	var level_path_map = {
		1: %LevelPath01,
		2: %LevelPath02,
		3: %LevelPath03,
		4: %LevelPath04,
		5: %LevelPath05,
	}
	active_path = level_path_map[Global.current_level]
	for child in $PathChildren.get_children():
		child.reparent(active_path, false)
	%HeroSprite.position = Vector2(5.5, -5.5)
	%CameraLevel.make_current()
	active_path.visible = true


func _process(delta: float) -> void:
	remaining_time = max(remaining_time - delta, 0)
	active_path.progress_ratio = 1 - (remaining_time / CUTSCENE_TIME)
	if remaining_time == 0 or Input.is_action_pressed("skip"):
		Events.change_scene.emit(load("res://scenes/game_scene.tscn"))
